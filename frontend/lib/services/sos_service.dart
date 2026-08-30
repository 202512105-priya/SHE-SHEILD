// lib/services/sos_service.dart
import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import '../services/database_service.dart';

class SosService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final DatabaseService _dbService = DatabaseService();

  // Speech recognizer for secret phrase detection
  final stt.SpeechToText _speech = stt.SpeechToText();

  // Initialize speech recognizer
  Future<bool> initSpeech() async {
    return await _speech.initialize();
  }

  // Listen for secret phrase, trigger SOS when detected
  Future<void> startListening(String secretPhrase) async {
    if (!_speech.isAvailable) await initSpeech();
    await _speech.listen(
      onResult: (result) async {
        if (result.recognizedWords.toLowerCase().contains(secretPhrase.toLowerCase())) {
          await triggerSos();
        }
      },
      listenMode: stt.ListenMode.confirmation,
    );
  }

  // Stop listening
  Future<void> stopListening() async {
    await _speech.stop();
  }

  // Core SOS trigger – creates emergency session, starts recordings, captures GPS
  Future<void> triggerSos() asy
<truncated 413 bytes>
e ?? 0.0,
        'longitude': location?.longitude ?? 0.0,
      },
      'status': 'active',
    };
    await _firestore.collection('EmergencySessions').doc(sessionId).set(sessionData);

    // 2. Start audio/video recording (placeholder – actual implementation needs UI permissions)
    await _startAudioRecording(sessionId);
    await _startVideoRecording(sessionId);

    // 3. Save evidence reference entries
    await _dbService.addDocument('EmergencyEvidenceLocker', sessionId, {
      'sessionId': sessionId,
      'audioPath': 'audio_$sessionId.m4a',
      'videoPath': 'video_$sessionId.mp4',
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  // Helper to get GPS location
  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;
    return await Geolocator.getCurrentPosition();
  }

  // Placeholder audio recording – store dummy file to storage
  Future<void> _startAudioRecording(String sessionId) async {
    // In a real app, use flutter_sound or similar. Here we upload an empty file.
    final ref = _storage.ref().child('audio_$sessionId.m4a');
    await ref.putData(Uint8List(0));
  }

  // Placeholder video recording – store dummy file to storage
  Future<void> _startVideoRecording(String sessionId) async {
    final ref = _storage.ref().child('video_$sessionId.mp4');
    await ref.putData(Uint8List(0));
  }
}
