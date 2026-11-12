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

Future<bool> platformCheckLocationPermission() async => false;

Future<bool> platformRequestLocationPermission() async => false;

Future<GeoPositionSample> platformGetCurrentPosition() async {
  return (
    ok: false,
    latitude: null,
    longitude: null,
    accuracy: 0.0,
    speed: 0.0,
    heading: 0.0,
    timestamp: DateTime.now().toUtc().toIso8601String(),
    error: 'Geolocation unavailable on this platform.',
  );
}

Future<bool> platformStartLocationWatch({
  required void Function(GeoPositionSample sample) onPosition,
  required void Function(String error) onError,
}) async {
  onError('Geolocation stream unsupported on this platform.');
  return false;
}

Future<void> platformStopLocationWatch() async {}

Future<bool> platformOpenExternalUrl(String url) async => false;

Future<bool> platformRequestNotificationPermission() async => true;
