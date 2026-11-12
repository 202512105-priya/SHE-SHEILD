import 'dart:async';
import 'package:flutter/foundation.dart';
import 'database_service.dart';
import 'voice_platform_stub.dart'
    if (dart.library.io) 'voice_platform_io.dart'
    if (dart.library.js_interop) 'voice_platform_web.dart';

enum VoiceSosState {
  IDLE,
  LISTENING,
  SOS_TRIGGERED,
  RECORDING,
  STOPPING,
  SAVING_TO_VAULT,
  SAVED,
  FAILED,
}

class VoiceEngineService extends ChangeNotifier {
  static final VoiceEngineService _instance = VoiceEngineService._internal();
  factory VoiceEngineService() => _instance;
  VoiceEngineService._internal();

  VoiceSosState _state = VoiceSosState.IDLE;
  bool _micPermissionGranted = false;
  bool _triggerLock = false;
  bool _phraseMatched = false;

  String? _activeSosEventId;
  String? _activeRecordingId;
  DateTime? _recordingStartedAt;
  int _elapsedSeconds = 0;
  int _maxDurationSeconds = 120;
  double _uploadProgress = 0.0;
  double _audioLevel = 0.0;
  String _recognizedTranscript = '';
  String _statusDetail = 'Voice SOS Idle';
  String? _errorMessage;
  Map<String, dynamic>? _lastSavedRecording;
  bool _lastSavedOffline = false;

  Timer? _recordTimer;
  DatabaseService? _boundDb;

  // Audio playback state
  String? _playingRecordingId;
  bool _isPlaybackPaused = false;
  double _playbackPositionSec = 0.0;
  double _playbackDurationSec = 0.0;
  String? _playbackError;

  // Legacy callback hooks if needed by modal listeners
  Function(String text, bool isMatch)? _onSpeechCallback;

  // Getters
  VoiceSosState get state => _state;
  String get stateName => _state.name;
  bool get micPermissionGranted => _micPermissionGranted;
  bool get isListening => _state == VoiceSosState.LISTENING;
  bool get isRecording => _state == VoiceSosState.RECORDING;
  bool get isBusy =>
      _state == VoiceSosState.SOS_TRIGGERED ||
      _state == VoiceSosState.RECORDING ||
      _state == VoiceSosState.STOPPING ||
      _state == VoiceSosState.SAVING_TO_VAULT;
  bool get phraseMatched => _phraseMatched;

  String? get activeSosEventId => _activeSosEventId;
  String? get activeRecordingId => _activeRecordingId;
  DateTime? get recordingStartedAt => _recordingStartedAt;
  int get elapsedSeconds => _elapsedSeconds;
  int get maxDurationSeconds => _maxDurationSeconds;
  double get uploadProgress => _uploadProgress;
  double get audioLevel => _audioLevel;
  double get currentAudioLevel => _audioLevel;
  String get recognizedTranscript => _recognizedTranscript;
  String get currentSpeechText => _recognizedTranscript;
  String get statusDetail => _statusDetail;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get lastSavedRecording => _lastSavedRecording;
  bool get lastSavedOffline => _lastSavedOffline;

  String? get playingRecordingId => _playingRecordingId;
  bool get isPlaybackPaused => _isPlaybackPaused;
  double get playbackPositionSec => _playbackPositionSec;
  double get playbackDurationSec => _playbackDurationSec;
  String? get playbackError => _playbackError;

  static String languageToBcp47(String lang) {
    switch (lang.trim()) {
      case 'Hindi':
        return 'hi-IN';
      case 'Gujarati':
        return 'gu-IN';
      case 'Marathi':
        return 'mr-IN';
      default:
        return 'en-US';
    }
  }

  Future<bool> checkMicPermission() async {
    _micPermissionGranted = await platformCheckMicPermission();
    notifyListeners();
    return _micPermissionGranted;
  }

  Future<bool> requestMicPermission() async {
    final res = await platformRequestMicPermission();
    _micPermissionGranted = res.granted;
    if (!res.granted) {
      _errorMessage = res.error ?? 'Microphone permission denied by user.';
    } else {
      _errorMessage = null;
    }
    notifyListeners();
    return res.granted;
  }

  /// Enables continuous Voice SOS detection strictly for authenticated Women Users.
  Future<bool> enableVoiceSos(
    DatabaseService db, {
    Function(String text, bool isMatch)? onSpeechCallback,
  }) async {
    _boundDb = db;
    _onSpeechCallback = onSpeechCallback;

    if (!db.isAuthenticated || !db.hasPermission('voice_sos:own')) {
      _setState(
        VoiceSosState.FAILED,
        detail: 'Unauthorized: Voice SOS requires an authenticated Women User account.',
        error: 'Role missing voice_sos:own permission.',
      );
      return false;
    }

    final phrase = db.customVoicePhrase.trim();
    if (phrase.length < 2) {
      _setState(
        VoiceSosState.FAILED,
        detail: 'Configure a custom voice activation phrase (at least 2 characters) first.',
        error: 'Voice SOS phrase is not configured.',
      );
      return false;
    }

    if (isBusy) {
      return false;
    }

    final granted = await requestMicPermission();
    if (!granted) {
      _setState(
        VoiceSosState.FAILED,
        detail: 'Microphone permission denied. Voice SOS cannot listen.',
        error: _errorMessage ?? 'Microphone permission denied.',
      );
      return false;
    }

    _triggerLock = false;
    _phraseMatched = false;
    _errorMessage = null;
    _recognizedTranscript = '';
    _maxDurationSeconds = db.maxRecordingDurationSec;

    final langTag = languageToBcp47(db.selectedLanguage);
    final started = await platformStartListening(
      langTag: langTag,
      onText: (text) => _handleSpeechTranscript(text),
      onLevel: (level) {
        _audioLevel = level;
        notifyListeners();
      },
      onStatus: (status) {
        if (_state == VoiceSosState.LISTENING) {
          _statusDetail = status == 'speech_api_unavailable'
              ? 'Browser SpeechRecognition unavailable (use Chrome/Android or manual SOS test)'
              : 'Listening ($langTag) for "$phrase"...';
          notifyListeners();
        }
      },
      onError: (err) {
        if (_state == VoiceSosState.LISTENING) {
          _setState(
            VoiceSosState.FAILED,
            detail: 'Voice recognition error: $err',
            error: err,
          );
        }
      },
    );

    if (started) {
      _setState(
        VoiceSosState.LISTENING,
        detail: kIsWeb
            ? 'Listening in active browser tab ($langTag) for "$phrase"...'
            : 'Listening continuously ($langTag) for "$phrase"...',
      );
      return true;
    }

    return false;
  }

  Future<void> disableVoiceSos() async {
    _triggerLock = false;
    await platformStopListening();
    if (_state == VoiceSosState.LISTENING || _state == VoiceSosState.IDLE) {
      _setState(VoiceSosState.IDLE, detail: 'Voice SOS Disabled');
    }
  }

  void _handleSpeechTranscript(String rawText) {
    final db = _boundDb;
    if (db == null || _state != VoiceSosState.LISTENING || _triggerLock) {
      return;
    }

    _recognizedTranscript = rawText;
    final cleanSpoken = rawText.toLowerCase().trim();
    final configuredPhrase = db.customVoicePhrase.toLowerCase().trim();

    final isMatch = configuredPhrase.isNotEmpty && _phraseMatches(cleanSpoken, configuredPhrase);
    _onSpeechCallback?.call(rawText, isMatch);

    if (isMatch) {
      triggerVoiceSosAndRecord(db, detectedPhrase: db.customVoicePhrase.trim());
    } else {
      notifyListeners();
    }
  }

  bool _phraseMatches(String spokenLower, String targetLower) {
    if (spokenLower == targetLower) return true;
    final wordsOnly = spokenLower.replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    final targetWords = targetLower.replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (targetWords.isEmpty) return false;
    return wordsOnly.contains(targetWords);
  }

  /// Triggered automatically when the custom SOS phrase is spoken (or test-triggered cleanly with duplicate lock).
  Future<bool> triggerVoiceSosAndRecord(
    DatabaseService db, {
    String? detectedPhrase,
  }) async {
    if (_triggerLock || isBusy) {
      debugPrint('[VoiceEngine] Duplicate trigger ignored (state=${_state.name}, lock=$_triggerLock)');
      return false;
    }

    if (!db.isAuthenticated || !db.hasPermission('voice_sos:own')) {
      _setState(
        VoiceSosState.FAILED,
        detail: 'Unauthorized: Must be signed in as Women User.',
        error: 'Missing voice_sos:own permission.',
      );
      return false;
    }

    _triggerLock = true;
    _boundDb = db;
    _phraseMatched = true;
    _errorMessage = null;
    _lastSavedRecording = null;
    _lastSavedOffline = false;
    _uploadProgress = 0.0;

    await platformStopListening();

    final sosId = 'SOS-VOICE-${DateTime.now().millisecondsSinceEpoch}';
    final recId = 'AUD-${DateTime.now().millisecondsSinceEpoch}';
    _activeSosEventId = sosId;
    _activeRecordingId = recId;

    _setState(
      VoiceSosState.SOS_TRIGGERED,
      detail: 'Voice phrase detected! Creating SOS $sosId & notifying network...',
    );

    // Create & persist SOS event in SQLite (or queue locally if offline)
    await db.createVoiceSosEvent(
      sosEventId: sosId,
      deviceType: 'Voice SOS Phrase Trigger (Auto-Recording)',
    );

    // Transition immediately into real microphone audio recording
    final granted = await requestMicPermission();
    if (!granted) {
      _triggerLock = false;
      _setState(
        VoiceSosState.FAILED,
        detail: 'SOS sent, but microphone permission denied for audio recording.',
        error: _errorMessage ?? 'Microphone permission denied.',
      );
      return false;
    }

    final fileName = 'sos_${sosId}_$recId.m4a';
    final recStart = await platformStartRecording(
      fileName: fileName,
      onInterrupted: (reason) {
        if (_state == VoiceSosState.RECORDING) {
          stopRecordingAndSave(db, reason: 'System interrupted ($reason)');
        }
      },
      onLevel: (level) {
        _audioLevel = level;
        notifyListeners();
      },
    );

    if (!recStart.ok) {
      _triggerLock = false;
      _setState(
        VoiceSosState.FAILED,
        detail: 'Failed to start microphone recorder: ${recStart.error}',
        error: recStart.error ?? 'Recorder error',
      );
      return false;
    }

    _recordingStartedAt = DateTime.now().toUtc();
    _elapsedSeconds = 0;
    _maxDurationSeconds = db.maxRecordingDurationSec;

    _setState(
      VoiceSosState.RECORDING,
      detail: 'Recording emergency audio for SOS $sosId (Max ${_maxDurationSeconds}s)',
    );

    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_state != VoiceSosState.RECORDING) {
        t.cancel();
        return;
      }
      _elapsedSeconds++;
      if (_elapsedSeconds >= _maxDurationSeconds) {
        t.cancel();
        stopRecordingAndSave(db, reason: 'Maximum recording duration reached');
      } else {
        notifyListeners();
      }
    });

    return true;
  }

  /// Stops active microphone recording, verifies playable audio & SHA-256, and saves to SQLite Vault (or Offline Store).
  Future<bool> stopRecordingAndSave(
    DatabaseService db, {
    String reason = 'Stopped by user',
  }) async {
    if (_state != VoiceSosState.RECORDING) {
      return false;
    }

    _recordTimer?.cancel();
    _setState(VoiceSosState.STOPPING, detail: 'Finalizing & validating audio ($reason)...');

    final stopped = await platformStopRecording();
    final endedAt = DateTime.now().toUtc();
    final startedAt = _recordingStartedAt ?? endedAt.subtract(Duration(seconds: _elapsedSeconds > 0 ? _elapsedSeconds : 1));

    if (!stopped.ok || stopped.bytes == null || stopped.bytes!.isEmpty) {
      _triggerLock = false;
      _setState(
        VoiceSosState.FAILED,
        detail: 'Audio recording invalid or empty.',
        error: stopped.error ?? 'Audio validation failed.',
      );
      return false;
    }

    _uploadProgress = 0.35;
    _setState(VoiceSosState.SAVING_TO_VAULT, detail: 'Encrypting & saving to Evidence Vault...');

    final ext = stopped.mimeType.contains('webm')
        ? '.webm'
        : (stopped.mimeType.contains('ogg') ? '.ogg' : '.m4a');
    final sosId = _activeSosEventId ?? 'SOS-VOICE-${DateTime.now().millisecondsSinceEpoch}';
    final recId = _activeRecordingId ?? 'AUD-${DateTime.now().millisecondsSinceEpoch}';
    final fileName = 'Voice_SOS_${sosId.replaceFirst('SOS-', '')}$ext';
    final duration = stopped.durationSeconds > 0 ? stopped.durationSeconds : (_elapsedSeconds > 0 ? _elapsedSeconds : 1);

    _uploadProgress = 0.7;
    notifyListeners();

    final saveRes = await db.saveRecordedAudioEvidence(
      recordingId: recId,
      sosEventId: sosId,
      filename: fileName,
      mimeType: stopped.mimeType,
      bytes: stopped.bytes!,
      durationSeconds: duration,
      startedAt: startedAt.toIso8601String(),
      endedAt: endedAt.toIso8601String(),
      sha256Hash: stopped.sha256,
      triggerPhrase: db.customVoicePhrase,
    );

    _triggerLock = false;

    if (saveRes.savedOnline) {
      _uploadProgress = 1.0;
      _lastSavedRecording = saveRes.recording;
      _lastSavedOffline = false;
      _setState(
        VoiceSosState.SAVED,
        detail: 'Saved to SQLite Evidence Vault ($recId • ${(stopped.fileSize / 1024).toStringAsFixed(1)} KB).',
      );
      return true;
    }

    if (saveRes.savedOffline) {
      _uploadProgress = 1.0;
      _lastSavedRecording = saveRes.recording;
      _lastSavedOffline = true;
      _setState(
        VoiceSosState.SAVED,
        detail: 'Network offline: Saved safely in protected local storage (Pending Sync).',
      );
      return true;
    }

    _uploadProgress = 0.0;
    _setState(
      VoiceSosState.FAILED,
      detail: 'Failed to save recording to vault.',
      error: saveRes.error ?? 'Unknown storage failure.',
    );
    return false;
  }

  void resetToIdle() {
    _triggerLock = false;
    _phraseMatched = false;
    _errorMessage = null;
    _uploadProgress = 0.0;
    _setState(VoiceSosState.IDLE, detail: 'Ready');
  }

  // ---------------------------------------------------------------------------
  // AUTHENTICATED AUDIO PLAYBACK & DOWNLOAD
  // ---------------------------------------------------------------------------

  Future<bool> playRecording(DatabaseService db, String recordingId) async {
    final token = db.authToken;
    if (token == null || token.isEmpty || !db.hasPermission('audio_evidence:own')) {
      _playbackError = 'Unauthorized playback attempt.';
      notifyListeners();
      return false;
    }

    if (_playingRecordingId == recordingId && _isPlaybackPaused) {
      final resumed = await platformResumeAudio();
      if (resumed) {
        _isPlaybackPaused = false;
        notifyListeners();
      }
      return resumed;
    }

    _playbackError = null;
    _playingRecordingId = recordingId;
    _isPlaybackPaused = false;
    _playbackPositionSec = 0;
    _playbackDurationSec = 0;
    notifyListeners();

    final ok = await platformPlayAuthAudio(
      streamUrl: db.audioStreamUrl(recordingId),
      token: token,
      onProgress: (pos, dur) {
        _playbackPositionSec = pos;
        _playbackDurationSec = dur;
        notifyListeners();
      },
      onEnded: () {
        _playingRecordingId = null;
        _isPlaybackPaused = false;
        _playbackPositionSec = 0;
        notifyListeners();
      },
      onError: (err) {
        _playbackError = err;
        _playingRecordingId = null;
        _isPlaybackPaused = false;
        notifyListeners();
      },
    );

    if (!ok) {
      _playingRecordingId = null;
      notifyListeners();
    }
    return ok;
  }

  Future<void> pausePlayback() async {
    await platformPauseAudio();
    _isPlaybackPaused = true;
    notifyListeners();
  }

  Future<void> stopPlayback() async {
    await platformStopPlayback();
    _playingRecordingId = null;
    _isPlaybackPaused = false;
    _playbackPositionSec = 0;
    _playbackDurationSec = 0;
    notifyListeners();
  }

  Future<({bool ok, String? savedPath, String? error})> downloadRecording(
    DatabaseService db,
    String recordingId,
    String filename,
  ) async {
    final token = db.authToken;
    if (token == null || token.isEmpty || !db.hasPermission('audio_evidence:own')) {
      return (ok: false, savedPath: null, error: 'Unauthorized download.');
    }
    return platformDownloadAuthAudio(
      downloadUrl: db.audioDownloadUrl(recordingId),
      token: token,
      filename: filename,
    );
  }

  void _setState(VoiceSosState next, {required String detail, String? error}) {
    _state = next;
    _statusDetail = detail;
    _errorMessage = error;
    notifyListeners();
  }
}
