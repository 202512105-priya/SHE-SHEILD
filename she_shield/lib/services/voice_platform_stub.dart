import 'dart:async';
import 'package:flutter/foundation.dart';

typedef RecordedAudioOutput = ({
  bool ok,
  Uint8List? bytes,
  String? filePath,
  String mimeType,
  int durationSeconds,
  int fileSize,
  String sha256,
  String? error,
});

Future<bool> platformCheckMicPermission() async => false;

Future<({bool granted, String? error})> platformRequestMicPermission() async =>
    (granted: false, error: 'Unsupported platform');

Future<bool> platformStartListening({
  required String langTag,
  required Function(String text) onText,
  required Function(double level) onLevel,
  required Function(String status) onStatus,
  required Function(String err) onError,
}) async =>
    false;

Future<void> platformStopListening() async {}

Future<({bool ok, String? mimeType, String? error})> platformStartRecording({
  required String fileName,
  required Function(String reason) onInterrupted,
  required Function(double level) onLevel,
}) async =>
    (ok: false, mimeType: null, error: 'Unsupported platform');

Future<RecordedAudioOutput> platformStopRecording() async => (
      ok: false,
      bytes: null,
      filePath: null,
      mimeType: 'audio/mp4',
      durationSeconds: 0,
      fileSize: 0,
      sha256: '',
      error: 'Unsupported platform',
    );

Future<bool> platformPlayAuthAudio({
  required String streamUrl,
  required String token,
  required Function(double pos, double dur) onProgress,
  required VoidCallback onEnded,
  required Function(String err) onError,
}) async =>
    false;

Future<void> platformPauseAudio() async {}
Future<bool> platformResumeAudio() async => false;
Future<void> platformStopPlayback() async {}

Future<({bool ok, String? savedPath, String? error})> platformDownloadAuthAudio({
  required String downloadUrl,
  required String token,
  required String filename,
}) async =>
    (ok: false, savedPath: null, error: 'Unsupported platform');

Future<bool> platformOfflineSave(Map<String, dynamic> meta, Uint8List bytes) async => false;
Future<List<Map<String, dynamic>>> platformOfflineList(String userId) async => [];
Future<Uint8List?> platformOfflineGetBytes(String id, String userId) async => null;
Future<bool> platformOfflineDelete(String id, String userId) async => false;
