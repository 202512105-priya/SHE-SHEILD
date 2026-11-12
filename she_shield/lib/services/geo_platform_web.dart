import 'dart:convert';
import 'dart:js_interop';

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

@JS('SheShieldGeoBridge.isSupported')
external JSBoolean _jsGeoIsSupported();

@JS('SheShieldGeoBridge.checkPermission')
external JSPromise<JSString> _jsGeoCheckPermission();

@JS('SheShieldGeoBridge.getCurrentPosition')
external JSPromise<JSString> _jsGeoGetCurrentPosition();

@JS('SheShieldGeoBridge.startWatch')
external JSBoolean _jsGeoStartWatch(JSFunction onPosition, JSFunction onError);

@JS('SheShieldGeoBridge.stopWatch')
external void _jsGeoStopWatch();

@JS('window.open')
external JSAny? _jsWindowOpen(JSString url, JSString target);

GeoPositionSample _decodeGeoSample(String jsonStr) {
  try {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    final ok = map['ok'] == true;
    final lat = (map['latitude'] as num?)?.toDouble();
    final lng = (map['longitude'] as num?)?.toDouble();
    if (!ok || lat == null || lng == null) {
      return (
        ok: false,
        latitude: null,
        longitude: null,
        accuracy: 0.0,
        speed: 0.0,
        heading: 0.0,
        timestamp: DateTime.now().toUtc().toIso8601String(),
        error: map['error']?.toString() ?? 'Location unavailable.',
      );
    }
    return (
      ok: true,
      latitude: lat,
      longitude: lng,
      accuracy: (map['accuracy'] as num?)?.toDouble() ?? 0.0,
      speed: (map['speed'] as num?)?.toDouble() ?? 0.0,
      heading: (map['heading'] as num?)?.toDouble() ?? 0.0,
      timestamp: map['timestamp']?.toString() ?? DateTime.now().toUtc().toIso8601String(),
      error: null,
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

Future<bool> platformCheckLocationPermission() async {
  try {
    if (!_jsGeoIsSupported().toDart) return false;
    final state = (await _jsGeoCheckPermission().toDart).toDart;
    return state == 'granted';
  } catch (_) {
    return false;
  }
}

Future<bool> platformRequestLocationPermission() async {
  final sample = await platformGetCurrentPosition();
  return sample.ok;
}

Future<GeoPositionSample> platformGetCurrentPosition() async {
  try {
    if (!_jsGeoIsSupported().toDart) {
      return (
        ok: false,
        latitude: null,
        longitude: null,
        accuracy: 0.0,
        speed: 0.0,
        heading: 0.0,
        timestamp: DateTime.now().toUtc().toIso8601String(),
        error: 'Browser Geolocation API is not supported.',
      );
    }
    final raw = (await _jsGeoGetCurrentPosition().toDart).toDart;
    return _decodeGeoSample(raw);
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
  try {
    if (!_jsGeoIsSupported().toDart) {
      onError('Browser Geolocation API is not supported.');
      return false;
    }
    final ok = _jsGeoStartWatch(
      ((JSString payload) {
        final sample = _decodeGeoSample(payload.toDart);
        if (sample.ok) {
          onPosition(sample);
        } else {
          onError(sample.error ?? 'GPS signal lost.');
        }
      }).toJS,
      ((JSString err) {
        onError(err.toDart);
      }).toJS,
    ).toDart;
    return ok;
  } catch (e) {
    onError(e.toString());
    return false;
  }
}

Future<void> platformStopLocationWatch() async {
  try {
    _jsGeoStopWatch();
  } catch (_) {}
}

Future<bool> platformOpenExternalUrl(String url) async {
  try {
    _jsWindowOpen(url.toJS, '_blank'.toJS);
    return true;
  } catch (_) {
    return false;
  }
}

Future<bool> platformRequestNotificationPermission() async => true;
