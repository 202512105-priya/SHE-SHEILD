package com.sheshield.she_shield

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.media.AudioAttributes
import android.media.MediaMetadataRetriever
import android.media.MediaPlayer
import android.media.MediaRecorder
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException
import java.security.MessageDigest
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.sheshield.she_shield/voice"
    private val LOCATION_CHANNEL = "com.sheshield.she_shield/location"
    private val STORAGE_CHANNEL = "com.sheshield.she_shield/storage"
    private val PERMISSION_REQUEST_CODE = 2001
    private val LOCATION_PERMISSION_REQUEST_CODE = 2002
    private val BG_LOCATION_PERMISSION_REQUEST_CODE = 2003
    private val NOTIF_PERMISSION_REQUEST_CODE = 2004

    private var permissionResult: MethodChannel.Result? = null
    private var locationPermissionResult: MethodChannel.Result? = null
    private var bgLocationPermissionResult: MethodChannel.Result? = null
    private var notifPermissionResult: MethodChannel.Result? = null
    private var methodChannel: MethodChannel? = null
    private var locationChannel: MethodChannel? = null
    private var storageChannel: MethodChannel? = null
    private var locationManager: LocationManager? = null
    private var activeLocationListener: LocationListener? = null
    private var speechRecognizer: SpeechRecognizer? = null
    private var continuousSpeechEnabled = false
    private var currentLanguageTag = "en-US"

    private var mediaRecorder: MediaRecorder? = null
    private var currentRecordingPath: String? = null
    private var recordingStartTime: Long = 0L

    private var mediaPlayer: MediaPlayer? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private var playbackTicker: Runnable? = null

    private fun getAudioVaultDir(): File {
        val dir = File(filesDir, "she_shield_audio")
        if (!dir.exists()) dir.mkdirs()
        return dir
    }

    private fun getOfflineQueueDir(): File {
        val dir = File(filesDir, "she_shield_offline_queue")
        if (!dir.exists()) dir.mkdirs()
        return dir
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
            when (call.method) {
                "checkMicPermission" -> {
                    val granted = ContextCompat.checkSelfPermission(
                        this,
                        Manifest.permission.RECORD_AUDIO
                    ) == PackageManager.PERMISSION_GRANTED
                    result.success(granted)
                }

                "requestMicPermission" -> {
                    if (ContextCompat.checkSelfPermission(
                            this,
                            Manifest.permission.RECORD_AUDIO
                        ) == PackageManager.PERMISSION_GRANTED
                    ) {
                        result.success(true)
                    } else {
                        permissionResult = result
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(Manifest.permission.RECORD_AUDIO),
                            PERMISSION_REQUEST_CODE
                        )
                    }
                }

                "startListening" -> {
                    val language = call.argument<String>("language") ?: "en-US"
                    continuousSpeechEnabled = true
                    currentLanguageTag = language
                    startSpeechRecognition(language, result)
                }

                "stopListening" -> {
                    continuousSpeechEnabled = false
                    stopSpeechRecognition(result)
                }

                "startRecording" -> {
                    continuousSpeechEnabled = false
                    val fileName = call.argument<String>("fileName") ?: "sos_audio_${System.currentTimeMillis()}.m4a"
                    startAudioRecording(fileName, result)
                }

                "stopRecording" -> {
                    stopAudioRecording(result)
                }

                "readFileBytes" -> {
                    val path = call.argument<String>("filePath")
                    if (path == null) {
                        result.error("ARG_ERROR", "Missing filePath", null)
                    } else {
                        val file = File(path)
                        if (file.exists() && file.canRead()) {
                            result.success(file.readBytes())
                        } else {
                            result.error("FILE_NOT_FOUND", "Audio file not found", null)
                        }
                    }
                }

                "savePrivateFileBytes" -> {
                    val fileName = call.argument<String>("fileName")
                    val bytes = call.argument<ByteArray>("bytes")
                    if (fileName == null || bytes == null) {
                        result.error("ARG_ERROR", "Missing fileName or bytes", null)
                    } else {
                        val safeName = fileName.replace(Regex("[^A-Za-z0-9._-]"), "_")
                        val outFile = File(getOfflineQueueDir(), safeName)
                        outFile.writeBytes(bytes)
                        result.success(outFile.absolutePath)
                    }
                }

                "deletePrivateFile" -> {
                    val path = call.argument<String>("filePath")
                    if (path != null) {
                        val f = File(path)
                        if (f.exists()) f.delete()
                    }
                    result.success(true)
                }

                "getOfflineDirPath" -> {
                    result.success(getOfflineQueueDir().absolutePath)
                }

                "playAuthAudio" -> {
                    val url = call.argument<String>("url") ?: ""
                    val token = call.argument<String>("token") ?: ""
                    playAuthenticatedAudio(url, token, result)
                }

                "pauseAudio" -> {
                    try {
                        mediaPlayer?.pause()
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }

                "resumeAudio" -> {
                    try {
                        mediaPlayer?.start()
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }

                "stopPlayback" -> {
                    stopAudioPlayback()
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }

        locationManager = getSystemService(Context.LOCATION_SERVICE) as? LocationManager
        locationChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LOCATION_CHANNEL)
        locationChannel?.setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
            when (call.method) {
                "checkLocationPermission" -> {
                    result.success(hasLocationPermission())
                }

                "requestLocationPermission" -> {
                    if (hasLocationPermission()) {
                        result.success(true)
                    } else {
                        locationPermissionResult = result
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(
                                Manifest.permission.ACCESS_FINE_LOCATION,
                                Manifest.permission.ACCESS_COARSE_LOCATION
                            ),
                            LOCATION_PERMISSION_REQUEST_CODE
                        )
                    }
                }

                "requestBackgroundLocationPermission" -> {
                    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                        result.success(hasLocationPermission())
                    } else if (!hasLocationPermission()) {
                        result.success(false)
                    } else if (ContextCompat.checkSelfPermission(
                            this,
                            Manifest.permission.ACCESS_BACKGROUND_LOCATION
                        ) == PackageManager.PERMISSION_GRANTED
                    ) {
                        result.success(true)
                    } else {
                        bgLocationPermissionResult = result
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(Manifest.permission.ACCESS_BACKGROUND_LOCATION),
                            BG_LOCATION_PERMISSION_REQUEST_CODE
                        )
                    }
                }

                "requestNotificationPermission" -> {
                    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
                        result.success(true)
                    } else if (ContextCompat.checkSelfPermission(
                            this,
                            Manifest.permission.POST_NOTIFICATIONS
                        ) == PackageManager.PERMISSION_GRANTED
                    ) {
                        result.success(true)
                    } else {
                        notifPermissionResult = result
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                            NOTIF_PERMISSION_REQUEST_CODE
                        )
                    }
                }

                "getCurrentPosition" -> {
                    fetchCurrentAndroidLocation(result)
                }

                "startWatch" -> {
                    startAndroidLocationWatch(result)
                }

                "stopWatch" -> {
                    stopAndroidLocationWatch()
                    result.success(true)
                }

                "openExternalUrl" -> {
                    val url = call.argument<String>("url") ?: ""
                    if (url.isBlank()) {
                        result.success(false)
                    } else {
                        try {
                            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                            startActivity(intent)
                            result.success(true)
                        } catch (_: Exception) {
                            result.success(false)
                        }
                    }
                }

                else -> result.notImplemented()
            }
        }

        storageChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, STORAGE_CHANNEL)
        storageChannel?.setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
            val prefs = getSharedPreferences("she_shield_prefs", Context.MODE_PRIVATE)
            when (call.method) {
                "loadState" -> {
                    result.success(
                        mapOf(
                            "authToken" to (prefs.getString("authToken", null) ?: ""),
                            "customServerHost" to (prefs.getString("customServerHost", null) ?: "")
                        )
                    )
                }

                "saveAuthToken" -> {
                    val token = call.argument<String>("token")?.trim()
                    prefs.edit().apply {
                        if (token.isNullOrEmpty()) remove("authToken") else putString("authToken", token)
                    }.apply()
                    result.success(true)
                }

                "saveServerHost" -> {
                    val host = call.argument<String>("host")?.trim()
                    prefs.edit().apply {
                        if (host.isNullOrEmpty()) remove("customServerHost") else putString("customServerHost", host)
                    }.apply()
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun hasLocationPermission(): Boolean {
        val fine = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
        val coarse = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.ACCESS_COARSE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
        return fine || coarse
    }

    private fun locationToMap(loc: Location): Map<String, Any> {
        val fmt = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US).apply {
            timeZone = TimeZone.getTimeZone("UTC")
        }
        return mapOf(
            "ok" to true,
            "latitude" to loc.latitude,
            "longitude" to loc.longitude,
            "accuracy" to (if (loc.hasAccuracy()) loc.accuracy.toDouble() else 0.0),
            "speed" to (if (loc.hasSpeed()) loc.speed.toDouble() else 0.0),
            "heading" to (if (loc.hasBearing()) loc.bearing.toDouble() else 0.0),
            "timestamp" to fmt.format(Date(loc.time))
        )
    }

    private fun fetchCurrentAndroidLocation(result: MethodChannel.Result) {
        if (!hasLocationPermission()) {
            result.success(mapOf("ok" to false, "error" to "Location permission denied."))
            return
        }
        val lm = locationManager ?: run {
            result.success(mapOf("ok" to false, "error" to "LocationManager unavailable."))
            return
        }
        try {
            val providers = listOf(LocationManager.GPS_PROVIDER, LocationManager.NETWORK_PROVIDER)
            var best: Location? = null
            for (p in providers) {
                if (lm.isProviderEnabled(p)) {
                    val last = lm.getLastKnownLocation(p)
                    if (last != null && (best == null || last.time > best.time)) {
                        best = last
                    }
                }
            }
            if (best != null && (System.currentTimeMillis() - best.time) < 60_000L) {
                result.success(locationToMap(best))
                return
            }
            var replied = false
            val singleListener = object : LocationListener {
                override fun onLocationChanged(location: Location) {
                    if (replied) return
                    replied = true
                    try { lm.removeUpdates(this) } catch (_: Exception) {}
                    result.success(locationToMap(location))
                }
            }
            val enabled = providers.filter { lm.isProviderEnabled(it) }
            if (enabled.isEmpty()) {
                result.success(mapOf("ok" to false, "error" to "Device GPS / Location services are disabled."))
                return
            }
            for (p in enabled) {
                lm.requestLocationUpdates(p, 500L, 0f, singleListener, Looper.getMainLooper())
            }
            mainHandler.postDelayed({
                if (!replied) {
                    replied = true
                    try { lm.removeUpdates(singleListener) } catch (_: Exception) {}
                    if (best != null) {
                        result.success(locationToMap(best))
                    } else {
                        result.success(mapOf("ok" to false, "error" to "GPS signal timed out. Try outdoors."))
                    }
                }
            }, 10_000L)
        } catch (se: SecurityException) {
            result.success(mapOf("ok" to false, "error" to (se.message ?: "Location security exception")))
        } catch (e: Exception) {
            result.success(mapOf("ok" to false, "error" to (e.message ?: "Location fetch failed")))
        }
    }

    private fun startAndroidLocationWatch(result: MethodChannel.Result) {
        if (!hasLocationPermission()) {
            result.success(false)
            locationChannel?.invokeMethod("onLocationError", "Location permission denied.")
            return
        }
        val lm = locationManager ?: run {
            result.success(false)
            return
        }
        stopAndroidLocationWatch()
        val enabled = listOf(LocationManager.GPS_PROVIDER, LocationManager.NETWORK_PROVIDER)
            .filter { lm.isProviderEnabled(it) }
        if (enabled.isEmpty()) {
            result.success(false)
            locationChannel?.invokeMethod("onLocationError", "Device GPS / Location providers are disabled.")
            return
        }
        val listener = object : LocationListener {
            override fun onLocationChanged(location: Location) {
                locationChannel?.invokeMethod("onLocationUpdate", locationToMap(location))
            }

            override fun onProviderDisabled(provider: String) {
                locationChannel?.invokeMethod("onLocationError", "Location provider '$provider' disabled.")
            }
        }
        activeLocationListener = listener
        try {
            for (p in enabled) {
                lm.requestLocationUpdates(p, 4000L, 3f, listener, Looper.getMainLooper())
            }
            result.success(true)
        } catch (se: SecurityException) {
            result.success(false)
            locationChannel?.invokeMethod("onLocationError", se.message ?: "Location permission missing")
        }
    }

    private fun stopAndroidLocationWatch() {
        val listener = activeLocationListener ?: return
        try {
            locationManager?.removeUpdates(listener)
        } catch (_: Exception) {}
        activeLocationListener = null
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            permissionResult?.success(granted)
            permissionResult = null
        } else if (requestCode == LOCATION_PERMISSION_REQUEST_CODE) {
            val granted = grantResults.any { it == PackageManager.PERMISSION_GRANTED }
            locationPermissionResult?.success(granted)
            locationPermissionResult = null
        } else if (requestCode == BG_LOCATION_PERMISSION_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            bgLocationPermissionResult?.success(granted)
            bgLocationPermissionResult = null
        } else if (requestCode == NOTIF_PERMISSION_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            notifPermissionResult?.success(granted)
            notifPermissionResult = null
        }
    }

    private fun restartSpeechIfEnabled() {
        if (!continuousSpeechEnabled) return
        mainHandler.postDelayed({
            if (continuousSpeechEnabled) {
                startSpeechRecognition(currentLanguageTag, null)
            }
        }, 450)
    }

    private fun startSpeechRecognition(language: String, result: MethodChannel.Result?) {
        runOnUiThread {
            if (!SpeechRecognizer.isRecognitionAvailable(this)) {
                result?.success(mapOf("status" to "unavailable", "message" to "Speech recognition not available on device"))
                return@runOnUiThread
            }

            try {
                speechRecognizer?.destroy()
                speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this)

                val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                    putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                    putExtra(RecognizerIntent.EXTRA_LANGUAGE, language)
                    putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
                    putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 3)
                }

                speechRecognizer?.setRecognitionListener(object : RecognitionListener {
                    override fun onReadyForSpeech(params: Bundle?) {
                        methodChannel?.invokeMethod("onSpeechStatus", "listening")
                    }

                    override fun onBeginningOfSpeech() {
                        methodChannel?.invokeMethod("onSpeechStatus", "listening")
                    }

                    override fun onRmsChanged(rmsdB: Float) {
                        methodChannel?.invokeMethod("onAudioLevel", rmsdB.toDouble())
                    }

                    override fun onBufferReceived(buffer: ByteArray?) {}

                    override fun onEndOfSpeech() {
                        methodChannel?.invokeMethod("onSpeechStatus", "processing")
                    }

                    override fun onError(error: Int) {
                        if (error == SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS) {
                            continuousSpeechEnabled = false
                            methodChannel?.invokeMethod("onSpeechError", "Microphone permission denied")
                        } else {
                            methodChannel?.invokeMethod("onSpeechStatus", "listening")
                            restartSpeechIfEnabled()
                        }
                    }

                    override fun onResults(results: Bundle?) {
                        val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                        val text = matches?.firstOrNull() ?: ""
                        if (text.isNotEmpty()) {
                            methodChannel?.invokeMethod("onSpeechResult", text)
                        }
                        restartSpeechIfEnabled()
                    }

                    override fun onPartialResults(partialResults: Bundle?) {
                        val matches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                        val text = matches?.firstOrNull() ?: ""
                        if (text.isNotEmpty()) {
                            methodChannel?.invokeMethod("onSpeechPartial", text)
                        }
                    }

                    override fun onEvent(eventType: Int, params: Bundle?) {}
                })

                speechRecognizer?.startListening(intent)
                result?.success(mapOf("status" to "started"))
            } catch (e: Exception) {
                result?.error("SPEECH_ERROR", e.message, null)
            }
        }
    }

    private fun stopSpeechRecognition(result: MethodChannel.Result) {
        runOnUiThread {
            try {
                speechRecognizer?.stopListening()
                speechRecognizer?.destroy()
                speechRecognizer = null
                result.success(true)
            } catch (e: Exception) {
                result.success(false)
            }
        }
    }

    private fun startAudioRecording(fileName: String, result: MethodChannel.Result) {
        try {
            speechRecognizer?.destroy()
            speechRecognizer = null

            val safeName = fileName.replace(Regex("[^A-Za-z0-9._-]"), "_")
            val outputFile = File(getAudioVaultDir(), safeName)
            currentRecordingPath = outputFile.absolutePath
            recordingStartTime = System.currentTimeMillis()

            mediaRecorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                MediaRecorder(this)
            } else {
                @Suppress("DEPRECATION")
                MediaRecorder()
            }.apply {
                setAudioSource(MediaRecorder.AudioSource.MIC)
                setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
                setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
                setAudioSamplingRate(44100)
                setAudioEncodingBitRate(128000)
                setOutputFile(currentRecordingPath)
                setOnErrorListener { _, _, _ ->
                    methodChannel?.invokeMethod("onRecordingInterrupted", "system_recorder_error")
                }
                prepare()
                start()
            }

            result.success(
                mapOf(
                    "status" to "recording",
                    "filePath" to currentRecordingPath,
                    "mimeType" to "audio/mp4"
                )
            )
        } catch (e: IOException) {
            result.error("RECORD_ERROR", "Failed to start recording: ${e.message}", null)
        } catch (e: Exception) {
            result.error("RECORD_ERROR", e.message, null)
        }
    }

    private fun stopAudioRecording(result: MethodChannel.Result) {
        try {
            mediaRecorder?.apply {
                stop()
                reset()
                release()
            }
            mediaRecorder = null

            val elapsedSec = ((System.currentTimeMillis() - recordingStartTime) / 1000).toInt().coerceAtLeast(1)
            val file = currentRecordingPath?.let { File(it) }
            if (file == null || !file.exists() || file.length() < 64L) {
                result.error("EMPTY_FILE", "Audio recording produced no data.", null)
                return
            }

            // Validate audio file is playable via MediaMetadataRetriever and extract actual duration
            var validatedDuration = elapsedSec
            var playable = false
            val retriever = MediaMetadataRetriever()
            try {
                retriever.setDataSource(file.absolutePath)
                val hasAudio = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_HAS_AUDIO)
                val durStr = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
                val durMs = durStr?.toLongOrNull() ?: 0L
                playable = (hasAudio == "yes" || durMs > 0L)
                if (durMs > 0L) {
                    validatedDuration = (durMs / 1000L).toInt().coerceAtLeast(1)
                }
            } catch (_: Exception) {
                playable = false
            } finally {
                retriever.release()
            }

            if (!playable) {
                result.error("UNPLAYABLE_AUDIO", "Finalized audio file failed playability verification.", null)
                return
            }

            val bytes = file.readBytes()
            val sha256Hex = MessageDigest.getInstance("SHA-256")
                .digest(bytes)
                .joinToString("") { "%02x".format(it) }

            result.success(
                mapOf(
                    "status" to "stopped",
                    "filePath" to file.absolutePath,
                    "mimeType" to "audio/mp4",
                    "durationSeconds" to validatedDuration,
                    "fileSizeBytes" to bytes.size,
                    "sha256" to sha256Hex
                )
            )
        } catch (e: Exception) {
            result.error("STOP_ERROR", "Failed to stop recording: ${e.message}", null)
        }
    }

    private fun playAuthenticatedAudio(url: String, token: String, result: MethodChannel.Result) {
        stopAudioPlayback()
        try {
            val mp = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .build()
                )
                setDataSource(this@MainActivity, Uri.parse(url), mapOf("Authorization" to "Bearer $token"))
                setOnPreparedListener { player ->
                    player.start()
                    result.success(true)
                    startPlaybackTicker()
                }
                setOnCompletionListener {
                    stopAudioPlayback()
                    methodChannel?.invokeMethod("onPlaybackEnded", null)
                }
                setOnErrorListener { _, what, extra ->
                    stopAudioPlayback()
                    methodChannel?.invokeMethod("onPlaybackError", "Playback error ($what/$extra)")
                    true
                }
                prepareAsync()
            }
            mediaPlayer = mp
        } catch (e: Exception) {
            result.error("PLAYBACK_ERROR", e.message, null)
        }
    }

    private fun startPlaybackTicker() {
        playbackTicker?.let { mainHandler.removeCallbacks(it) }
        val r = object : Runnable {
            override fun run() {
                val mp = mediaPlayer ?: return
                if (mp.isPlaying) {
                    val pos = mp.currentPosition / 1000.0
                    val dur = mp.duration / 1000.0
                    methodChannel?.invokeMethod("onPlaybackProgress", mapOf("position" to pos, "duration" to dur))
                    mainHandler.postDelayed(this, 250)
                }
            }
        }
        playbackTicker = r
        mainHandler.post(r)
    }

    private fun stopAudioPlayback() {
        playbackTicker?.let { mainHandler.removeCallbacks(it) }
        playbackTicker = null
        try {
            mediaPlayer?.apply {
                if (isPlaying) stop()
                reset()
                release()
            }
        } catch (_: Exception) {}
        mediaPlayer = null
    }

    override fun onDestroy() {
        continuousSpeechEnabled = false
        speechRecognizer?.destroy()
        speechRecognizer = null
        mediaRecorder?.release()
        mediaRecorder = null
        stopAndroidLocationWatch()
        stopAudioPlayback()
        super.onDestroy()
    }
}
