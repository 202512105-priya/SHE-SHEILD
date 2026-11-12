import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'local_http_io.dart';

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

const MethodChannel _channel = MethodChannel('com.sheshield.she_shield/voice');
bool _handlerInstalled = false;
Function(String)? _onTextCb;
Function(double)? _onLevelCb;
Function(String)? _onStatusCb;
Function(String)? _onErrCb;
Function(String)? _onInterruptedCb;
Function(double, double)? _onProgressCb;
VoidCallback? _onEndedCb;
Function(String)? _onPlaybackErrCb;

void _ensureChannelHandler() {
  if (_handlerInstalled) return;
  _handlerInstalled = true;
  _channel.setMethodCallHandler((MethodCall call) async {
    switch (call.method) {
      case 'onSpeechResult':
      case 'onSpeechPartial':
        _onTextCb?.call(call.arguments?.toString() ?? '');
        break;
      case 'onAudioLevel':
        final lvl = (call.arguments is num) ? (call.arguments as num).toDouble() : 0.0;
        _onLevelCb?.call(lvl);
        break;
      case 'onSpeechStatus':
        _onStatusCb?.call(call.arguments?.toString() ?? '');
        break;
      case 'onSpeechError':
        _onErrCb?.call(call.arguments?.toString() ?? '');
        break;
      case 'onRecordingInterrupted':
        _onInterruptedCb?.call(call.arguments?.toString() ?? 'system_interrupted');
        break;
      case 'onPlaybackProgress':
        if (call.arguments is Map) {
          final m = call.arguments as Map;
          final pos = (m['position'] is num) ? (m['position'] as num).toDouble() : 0.0;
          final dur = (m['duration'] is num) ? (m['duration'] as num).toDouble() : 0.0;
          _onProgressCb?.call(pos, dur);
        }
        break;
      case 'onPlaybackEnded':
        _onEndedCb?.call();
        break;
      case 'onPlaybackError':
        _onPlaybackErrCb?.call(call.arguments?.toString() ?? 'Playback error');
        break;
    }
  });
}

Future<bool> platformCheckMicPermission() async {
  try {
    _ensureChannelHandler();
    final granted = await _channel.invokeMethod<bool>('checkMicPermission');
    return granted ?? false;
  } catch (_) {
    return false;
  }
}

Future<({bool granted, String? error})> platformRequestMicPermission() async {
  try {
    _ensureChannelHandler();
    final granted = await _channel.invokeMethod<bool>('requestMicPermission');
    return (granted: granted ?? false, error: (granted ?? false) ? null : 'Microphone permission denied');
  } catch (e) {
    return (granted: false, error: e.toString());
  }
}

Future<bool> platformStartListening({
  required String langTag,
  required Function(String text) onText,
  required Function(double level) onLevel,
  required Function(String status) onStatus,
  required Function(String err) onError,
}) async {
  _ensureChannelHandler();
  _onTextCb = onText;
  _onLevelCb = onLevel;
  _onStatusCb = onStatus;
  _onErrCb = onError;
  try {
    await _channel.invokeMethod('startListening', {'language': langTag});
    return true;
  } catch (e) {
    onError(e.toString());
    return false;
  }
}

Future<void> platformStopListening() async {
  try {
    _ensureChannelHandler();
    await _channel.invokeMethod('stopListening');
  } catch (_) {}
}

Future<({bool ok, String? mimeType, String? error})> platformStartRecording({
  required String fileName,
  required Function(String reason) onInterrupted,
  required Function(double level) onLevel,
}) async {
  _ensureChannelHandler();
  _onInterruptedCb = onInterrupted;
  _onLevelCb = onLevel;
  try {
    final res = await _channel.invokeMethod<Map>('startRecording', {'fileName': fileName});
    return (
      ok: true,
      mimeType: res?['mimeType']?.toString() ?? 'audio/mp4',
      error: null,
    );
  } catch (e) {
    return (ok: false, mimeType: null, error: e.toString());
  }
}

Future<RecordedAudioOutput> platformStopRecording() async {
  _ensureChannelHandler();
  try {
    final res = await _channel.invokeMethod<Map>('stopRecording');
    if (res == null) {
      return (
        ok: false,
        bytes: null,
        filePath: null,
        mimeType: 'audio/mp4',
        durationSeconds: 0,
        fileSize: 0,
        sha256: '',
        error: 'Recording stop returned empty result',
      );
    }
    final filePath = res['filePath']?.toString();
    Uint8List? bytes;
    if (filePath != null && filePath.isNotEmpty) {
      bytes = await _channel.invokeMethod<Uint8List>('readFileBytes', {'filePath': filePath});
    }
    return (
      ok: bytes != null && bytes.isNotEmpty,
      bytes: bytes,
      filePath: filePath,
      mimeType: res['mimeType']?.toString() ?? 'audio/mp4',
      durationSeconds: (res['durationSeconds'] is int)
          ? res['durationSeconds'] as int
          : int.tryParse(res['durationSeconds']?.toString() ?? '1') ?? 1,
      fileSize: (res['fileSizeBytes'] is int)
          ? res['fileSizeBytes'] as int
          : bytes?.length ?? 0,
      sha256: res['sha256']?.toString() ?? '',
      error: (bytes == null || bytes.isEmpty) ? 'Failed to read audio bytes' : null,
    );
  } catch (e) {
    return (
      ok: false,
      bytes: null,
      filePath: null,
      mimeType: 'audio/mp4',
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
  required Function(double pos, double dur) onProgress,
  required VoidCallback onEnded,
  required Function(String err) onError,
}) async {
  _ensureChannelHandler();
  _onProgressCb = onProgress;
  _onEndedCb = onEnded;
  _onPlaybackErrCb = onError;
  try {
    final ok = await _channel.invokeMethod<bool>('playAuthAudio', {'url': streamUrl, 'token': token});
    return ok ?? false;
  } catch (e) {
    onError(e.toString());
    return false;
  }
}

Future<void> platformPauseAudio() async {
  try {
    await _channel.invokeMethod('pauseAudio');
  } catch (_) {}
}

Future<bool> platformResumeAudio() async {
  try {
    return (await _channel.invokeMethod<bool>('resumeAudio')) ?? false;
  } catch (_) {
    return false;
  }
}

Future<void> platformStopPlayback() async {
  try {
    await _channel.invokeMethod('stopPlayback');
  } catch (_) {}
}

Future<({bool ok, String? savedPath, String? error})> platformDownloadAuthAudio({
  required String downloadUrl,
  required String token,
  required String filename,
}) async {
  try {
    final res = await platformDownloadBytes(
      url: downloadUrl,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200 || res.bytes.isEmpty) {
      return (ok: false, savedPath: null, error: 'HTTP ${res.statusCode}');
    }
    final savedPath = await _channel.invokeMethod<String>('savePrivateFileBytes', {
      'fileName': filename,
      'bytes': res.bytes,
    });
    return (ok: true, savedPath: savedPath, error: null);
  } catch (e) {
    return (ok: false, savedPath: null, error: e.toString());
  }
}

Future<Directory> _getOfflineDir() async {
  try {
    final dirPath = await _channel.invokeMethod<String>('getOfflineDirPath');
    if (dirPath != null && dirPath.isNotEmpty) {
      final d = Directory(dirPath);
      if (!await d.exists()) await d.create(recursive: true);
      return d;
    }
  } catch (_) {}
  final fallback = Directory('${Directory.systemTemp.path}/she_shield_offline_queue');
  if (!await fallback.exists()) await fallback.create(recursive: true);
  return fallback;
}

Future<bool> platformOfflineSave(Map<String, dynamic> meta, Uint8List bytes) async {
  try {
    final dir = await _getOfflineDir();
    final id = meta['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
    final binFile = File('${dir.path}/$id.bin');
    final metaFile = File('${dir.path}/$id.json');
    await binFile.writeAsBytes(bytes, flush: true);
    await metaFile.writeAsString(jsonEncode(meta), flush: true);
    return true;
  } catch (_) {
    return false;
  }
}

Future<List<Map<String, dynamic>>> platformOfflineList(String userId) async {
  try {
    final dir = await _getOfflineDir();
    final files = await dir.list().toList();
    final items = <Map<String, dynamic>>[];
    for (final f in files) {
      if (f is File && f.path.endsWith('.json')) {
        try {
          final parsed = jsonDecode(await f.readAsString());
          if (parsed is Map) {
            final map = Map<String, dynamic>.from(parsed);
            if (userId.isEmpty || map['userId'] == userId) {
              items.add(map);
            }
          }
        } catch (_) {}
      }
    }
    return items;
  } catch (_) {
    return [];
  }
}

Future<Uint8List?> platformOfflineGetBytes(String id, String userId) async {
  try {
    final dir = await _getOfflineDir();
    final metaFile = File('${dir.path}/$id.json');
    final binFile = File('${dir.path}/$id.bin');
    if (!await metaFile.exists() || !await binFile.exists()) return null;
    final parsed = jsonDecode(await metaFile.readAsString());
    if (parsed is Map && userId.isNotEmpty && parsed['userId'] != userId) {
      return null;
    }
    return await binFile.readAsBytes();
  } catch (_) {
    return null;
  }
}

Future<bool> platformOfflineDelete(String id, String userId) async {
  try {
    final dir = await _getOfflineDir();
    final metaFile = File('${dir.path}/$id.json');
    final binFile = File('${dir.path}/$id.bin');
    if (await metaFile.exists()) await metaFile.delete();
    if (await binFile.exists()) await binFile.delete();
    return true;
  } catch (_) {
    return false;
  }
}
