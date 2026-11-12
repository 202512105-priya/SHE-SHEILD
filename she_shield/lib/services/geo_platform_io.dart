import 'package:flutter/services.dart';

typedef GeoPositionSample = ({
  bool ok,
  double? latitude,
  double? longitude,
  double accuracy,
  double speed,
  double heading,
  String timestamp,
  String? error,
});

const MethodChannel _locationChannel = MethodChannel('com.sheshield.she_shield/location');
bool _handlerInitialized = false;
void Function(GeoPositionSample sample)? _watchOnPosition;
void Function(String error)? _watchOnError;

GeoPositionSample _mapToSample(Map<dynamic, dynamic>? raw) {
  if (raw == null || raw['ok'] != true) {
    return (
      ok: false,
      latitude: null,
      longitude: null,
      accuracy: 0.0,
      speed: 0.0,
      heading: 0.0,
      timestamp: DateTime.now().toUtc().toIso8601String(),
      error: raw?['error']?.toString() ?? 'Location unavailable.',
    );
  }
  final lat = (raw['latitude'] as num?)?.toDouble();
  final lng = (raw['longitude'] as num?)?.toDouble();
  if (lat == null || lng == null) {
    return (
      ok: false,
      latitude: null,
      longitude: null,
      accuracy: 0.0,
      speed: 0.0,
      heading: 0.0,
      timestamp: DateTime.now().toUtc().toIso8601String(),
      error: 'Invalid GPS coordinate payload.',
    );
  }
  return (
    ok: true,
    latitude: lat,
    longitude: lng,
    accuracy: (raw['accuracy'] as num?)?.toDouble() ?? 0.0,
    speed: (raw['speed'] as num?)?.toDouble() ?? 0.0,
    heading: (raw['heading'] as num?)?.toDouble() ?? 0.0,
    timestamp: raw['timestamp']?.toString() ?? DateTime.now().toUtc().toIso8601String(),
    error: null,
  );
}

void _ensureChannelHandler() {
  if (_handlerInitialized) return;
  _handlerInitialized = true;
  _locationChannel.setMethodCallHandler((call) async {
    if (call.method == 'onLocationUpdate' && call.arguments is Map) {
      final sample = _mapToSample(call.arguments as Map<dynamic, dynamic>);
      if (sample.ok) {
        _watchOnPosition?.call(sample);
      } else {
        _watchOnError?.call(sample.error ?? 'Location update invalid.');
      }
    } else if (call.method == 'onLocationError') {
      _watchOnError?.call(call.arguments?.toString() ?? 'GPS stream error.');
    }
  });
}

Future<bool> platformCheckLocationPermission() async {
  try {
    final res = await _locationChannel.invokeMethod<bool>('checkLocationPermission');
    return res == true;
  } catch (_) {
    return false;
  }
}

Future<bool> platformRequestLocationPermission() async {
  try {
    final res = await _locationChannel.invokeMethod<bool>('requestLocationPermission');
    return res == true;
  } catch (_) {
    return false;
  }
}

Future<GeoPositionSample> platformGetCurrentPosition() async {
  try {
    final res = await _locationChannel.invokeMethod<Map<dynamic, dynamic>>('getCurrentPosition');
    return _mapToSample(res);
  } on MissingPluginException {
    return (
      ok: false,
      latitude: null,
      longitude: null,
      accuracy: 0.0,
      speed: 0.0,
      heading: 0.0,
      timestamp: DateTime.now().toUtc().toIso8601String(),
      error: 'Native GPS channel unavailable on this desktop test runner.',
    );
  } catch (e) {
    return (
      ok: false,
      latitude: null,
      longitude: null,
      accuracy: 0.0,
      speed: 0.0,
      heading: 0.0,
      timestamp: DateTime.now().toUtc().toIso8601String(),
      error: e.toString(),
    );
  }
}

Future<bool> platformStartLocationWatch({
  required void Function(GeoPositionSample sample) onPosition,
  required void Function(String error) onError,
}) async {
  _ensureChannelHandler();
  _watchOnPosition = onPosition;
  _watchOnError = onError;
  try {
    final res = await _locationChannel.invokeMethod<bool>('startWatch');
    return res == true;
  } catch (e) {
    onError(e.toString());
    return false;
  }
}

Future<void> platformStopLocationWatch() async {
  _watchOnPosition = null;
  _watchOnError = null;
  try {
    await _locationChannel.invokeMethod('stopWatch');
  } catch (_) {}
}

Future<bool> platformOpenExternalUrl(String url) async {
  try {
    final res = await _locationChannel.invokeMethod<bool>('openExternalUrl', {'url': url});
    return res == true;
  } catch (_) {
    return false;
  }
}

Future<bool> platformRequestNotificationPermission() async {
  try {
    final res = await _locationChannel.invokeMethod<bool>('requestNotificationPermission');
    return res == true;
  } catch (_) {
    return true;
  }
}
