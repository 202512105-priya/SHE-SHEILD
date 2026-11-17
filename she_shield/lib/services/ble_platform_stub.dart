typedef BleDeviceState = ({
  bool connected,
  bool isConnecting,
  String deviceId,
  String deviceName,
  String deviceCategory,
  int? batteryLevel,
  String signalStrength,
  String macAddress,
  bool soundSupported,
  List<String> discoveredServices,
  String? error,
});

BleDeviceState disconnectedBleState({String? error}) => (
      connected: false,
      isConnecting: false,
      deviceId: '',
      deviceName: '',
      deviceCategory: 'Smart Ring',
      batteryLevel: null,
      signalStrength: 'Offline',
      macAddress: 'Not Connected',
      soundSupported: false,
      discoveredServices: <String>[],
      error: error,
    );

Future<bool> platformCheckBleSupport() async => false;

Future<bool> platformCheckBleAvailability() async => false;

Future<BleDeviceState> platformScanAndConnect({String? category}) async =>
    disconnectedBleState(error: 'BLE unsupported on this platform.');

Future<bool> platformDisconnectBle() async => true;

Future<({bool supported, String message, String? error})> platformPlayBleSound() async =>
    (supported: false, message: '', error: 'Sound playback unsupported on this platform.');

void platformSetBleCallbacks({
  required void Function(BleDeviceState state) onStateChanged,
  required void Function(Map<String, dynamic> event) onSosTriggered,
}) {}

void platformTriggerSimulatedBleButton() {}
