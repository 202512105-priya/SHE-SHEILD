import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
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

@JS('SheShieldVoiceBridge.checkMicPermission')
external JSPromise<JSBoolean> _jsCheckMicPermission();

@JS('SheShieldVoiceBridge.requestMicPermission')
external JSPromise<JSString> _jsRequestMicPermission();

@JS('SheShieldVoiceBridge.startListening')
external JSPromise<JSBoolean> _jsStartListening(
  JSString langTag,
  JSFunction onResult,
  JSFunction onLevel,
  JSFunction onStatus,
  JSFunction onError,
);

@JS('SheShieldVoiceBridge.stopListening')
external void _jsStopListening();

@JS('SheShieldVoiceBridge.startRecording')
external JSPromise<JSString> _jsStartRecording(JSFunction onSystemStop, JSFunction onLevel);

@JS('SheShieldVoiceBridge.stopRecording')
external JSPromise<JSString> _jsStopRecording();

@JS('SheShieldVoiceBridge.getLastRecordedBytes')
external JSUint8Array? _jsGetLastRecordedBytes();

@JS('SheShieldVoiceBridge.playAuthAudio')
external JSPromise<JSBoolean> _jsPlayAuthAudio(
  JSString url,
  JSString token,
  JSFunction onTimeUpdate,
  JSFunction onEnded,
  JSFunction onError,
);

@JS('SheShieldVoiceBridge.pausePlayback')
external void _jsPausePlayback();

@JS('SheShieldVoiceBridge.resumePlayback')
external JSPromise<JSBoolean> _jsResumePlayback();

@JS('SheShieldVoiceBridge.stopPlayback')
external void _jsStopPlayback();

@JS('SheShieldVoiceBridge.downloadAuthAudio')
external JSPromise<JSString> _jsDownloadAuthAudio(JSString url, JSString token, JSString filename);

@JS('SheShieldVoiceBridge.offlineSave')
external JSPromise<JSBoolean> _jsOfflineSave(JSString metaJson, JSUint8Array bytes);

@JS('SheShieldVoiceBridge.offlineList')
external JSPromise<JSString> _jsOfflineList(JSString userId);

@JS('SheShieldVoiceBridge.offlineGetBytes')
external JSPromise<JSUint8Array?> _jsOfflineGetBytes(JSString id);

@JS('SheShieldVoiceBridge.offlineDelete')
external JSPromise<JSBoolean> _jsOfflineDelete(JSString id);

Future<bool> platformCheckMicPermission() async {
  try {
    return (await _jsCheckMicPermission().toDart).toDart;
  } catch (_) {
    return false;
  }
}

Future<({bool granted, String? error})> platformRequestMicPermission() async {
  try {
    final raw = (await _jsRequestMicPermission().toDart).toDart;
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return (
      granted: decoded['granted'] == true,
      error: decoded['error']?.toString(),
    );
  } catch (e) {
    return (granted: false, error: e.toString());
  }
}

Future<bool> platformStartListening({
  required String langTag,
  required void Function(String text) onText,
  required void Function(double level) onLevel,
  required void Function(String status) onStatus,
  required void Function(String err) onError,
}) async {
  try {
    final ok = await _jsStartListening(
      langTag.toJS,
      ((JSString s) {
        onText(s.toDart);
      }).toJS,
      ((JSNumber n) {
        onLevel(n.toDartDouble);
      }).toJS,
      ((JSString st) {
        onStatus(st.toDart);
      }).toJS,
      ((JSString err) {
        onError(err.toDart);
      }).toJS,
    ).toDart;
    return ok.toDart;
  } catch (e) {
    onError(e.toString());
    return false;
  }
}

Future<void> platformStopListening() async {
  try {
    _jsStopListening();
  } catch (_) {}
}

Future<({bool ok, String? mimeType, String? error})> platformStartRecording({
  required String fileName,
  required void Function(String reason) onInterrupted,
  required void Function(double level) onLevel,
}) async {
  try {
    final raw = (await _jsStartRecording(
      ((JSString reason) {
        onInterrupted(reason.toDart);
      }).toJS,
      ((JSNumber n) {
        onLevel(n.toDartDouble);
      }).toJS,
    ).toDart)
        .toDart;
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return (
      ok: decoded['ok'] == true,
      mimeType: decoded['mimeType']?.toString(),
      error: decoded['error']?.toString(),
    );
  } catch (e) {
    return (ok: false, mimeType: null, error: e.toString());
  }
}

Future<RecordedAudioOutput> platformStopRecording() async {
  try {
    final raw = (await _jsStopRecording().toDart).toDart;
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    if (decoded['ok'] != true) {
      return (
        ok: false,
        bytes: null,
        filePath: null,
        mimeType: 'audio/webm',
        durationSeconds: 0,
        fileSize: 0,
        sha256: '',
        error: decoded['error']?.toString() ?? 'Recording stop failed',
      );
    }
    final jsBytes = _jsGetLastRecordedBytes();
    final bytes = jsBytes?.toDart;
    return (
      ok: bytes != null && bytes.isNotEmpty,
      bytes: bytes,
      filePath: null,
      mimeType: decoded['mimeType']?.toString() ?? 'audio/webm',
      durationSeconds: (decoded['durationSeconds'] is num)
          ? (decoded['durationSeconds'] as num).toInt()
          : 1,
      fileSize: (decoded['fileSize'] is num)
          ? (decoded['fileSize'] as num).toInt()
          : (bytes?.length ?? 0),
      sha256: decoded['sha256']?.toString() ?? '',
      error: (bytes == null || bytes.isEmpty) ? 'No recorded audio bytes produced' : null,
    );
  } catch (e) {
    return (
      ok: false,
      bytes: null,
      filePath: null,
      mimeType: 'audio/webm',
      durationSeconds: 0,
      fileSize: 0,
      sha256: '',
      error: e.toString(),
    );
  }
}

Future<bool> platformPlayAuthAudio({
  required String streamUrl,
  required String token,
  required void Function(double pos, double dur) onProgress,
  required VoidCallback onEnded,
  required void Function(String err) onError,
}) async {
  try {
    final ok = await _jsPlayAuthAudio(
      streamUrl.toJS,
      token.toJS,
      ((JSNumber p, JSNumber d) {
        onProgress(p.toDartDouble, d.toDartDouble);
      }).toJS,
      (() {
        onEnded();
      }).toJS,
      ((JSString err) {
        onError(err.toDart);
      }).toJS,
    ).toDart;
    return ok.toDart;
  } catch (e) {
    onError(e.toString());
    return false;
  }
}

Future<void> platformPauseAudio() async {
  try {
    _jsPausePlayback();
  } catch (_) {}
}

Future<bool> platformResumeAudio() async {
  try {
    return (await _jsResumePlayback().toDart).toDart;
  } catch (_) {
    return false;
  }
}

Future<void> platformStopPlayback() async {
  try {
    _jsStopPlayback();
  } catch (_) {}
}

Future<({bool ok, String? savedPath, String? error})> platformDownloadAuthAudio({
  required String downloadUrl,
  required String token,
  required String filename,
}) async {
  try {
    final raw = (await _jsDownloadAuthAudio(downloadUrl.toJS, token.toJS, filename.toJS).toDart).toDart;
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return (
      ok: decoded['ok'] == true,
      savedPath: null,
      error: decoded['error']?.toString(),
    );
  } catch (e) {
    return (ok: false, savedPath: null, error: e.toString());
  }
}

Future<bool> platformOfflineSave(Map<String, dynamic> meta, Uint8List bytes) async {
  try {
    return (await _jsOfflineSave(jsonEncode(meta).toJS, bytes.toJS).toDart).toDart;
  } catch (_) {
    return false;
  }
}

Future<List<Map<String, dynamic>>> platformOfflineList(String userId) async {
  try {
    final raw = (await _jsOfflineList(userId.toJS).toDart).toDart;
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  } catch (_) {
    return [];
  }
}

Future<Uint8List?> platformOfflineGetBytes(String id, String userId) async {
  try {
    final jsBytes = await _jsOfflineGetBytes(id.toJS).toDart;
    return jsBytes?.toDart;
  } catch (_) {
    return null;
  }
}

Future<bool> platformOfflineDelete(String id, String userId) async {
  try {
    return (await _jsOfflineDelete(id.toJS).toDart).toDart;
  } catch (_) {
    return false;
  }
}
