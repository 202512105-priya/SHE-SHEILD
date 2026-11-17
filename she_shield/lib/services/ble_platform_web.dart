import 'dart:convert';
import 'dart:js_interop';
import 'ble_platform_stub.dart';

export 'ble_platform_stub.dart' show BleDeviceState, disconnectedBleState;

@JS('SheShieldBleBridge.isSupported')
external JSBoolean _jsBleIsSupported();

@JS('SheShieldBleBridge.getAvailability')
external JSPromise<JSBoolean> _jsBleGetAvailability();

@JS('SheShieldBleBridge.requestAndConnectDevice')
external JSPromise<JSString> _jsBleRequestAndConnect(JSString category);

@JS('SheShieldBleBridge.playSound')
external JSPromise<JSString> _jsBlePlaySound();

@JS('SheShieldBleBridge.disconnect')
external JSPromise<JSString> _jsBleDisconnect();

@JS('SheShieldBleBridge.registerCallbacks')
external void _jsBleRegisterCallbacks(JSFunction onState, JSFunction onSos);

@JS('SheShieldBleBridge.triggerSimulatedPhysicalButtonPress')
external JSString _jsBleTriggerSimulatedButton();

BleDeviceState _parseStateJson(String jsonStr) {
  try {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    final srvRaw = map['discoveredServices'];
    final services = (srvRaw is List) ? srvRaw.map((e) => e.toString()).toList() : <String>[];

    return (
      connected: map['connected'] == true,
      isConnecting: map['isConnecting'] == true,
      deviceId: map['deviceId']?.toString() ?? '',
      deviceName: map['deviceName']?.toString() ?? '',
      deviceCategory: map['deviceCategory']?.toString() ?? 'Smart Ring',
      batteryLevel: map['batteryLevel'] != null ? (map['batteryLevel'] as num).toInt() : null,
      signalStrength: map['signalStrength']?.toString() ?? 'Offline',
      macAddress: map['macAddress']?.toString() ?? 'Not Connected',
      soundSupported: map['soundSupported'] == true,
      discoveredServices: services,
      error: map['error']?.toString(),
    );
  } catch (e) {
    return disconnectedBleState(error: e.toString());
  }
}

Future<bool> platformCheckBleSupport() async {
  try {
    return _jsBleIsSupported().toDart;
  } catch (_) {
    return false;
  }
}

Future<bool> platformCheckBleAvailability() async {
  try {
    final res = await _jsBleGetAvailability().toDart;
    return res.toDart;
  } catch (_) {
    return false;
  }
}

Future<BleDeviceState> platformScanAndConnect({String? category}) async {
  try {
    final catJs = (category ?? 'Smart Ring').toJS;
    final resJs = await _jsBleRequestAndConnect(catJs).toDart;
    return _parseStateJson(resJs.toDart);
  } catch (e) {
    return disconnectedBleState(error: e.toString());
  }
}

Future<bool> platformDisconnectBle() async {
  try {
    final resJs = await _jsBleDisconnect().toDart;
    final map = jsonDecode(resJs.toDart) as Map<String, dynamic>;
    return map['ok'] == true;
  } catch (_) {
    return false;
  }
}

Future<({bool supported, String message, String? error})> platformPlayBleSound() async {
  try {
    final resJs = await _jsBlePlaySound().toDart;
    final map = jsonDecode(resJs.toDart) as Map<String, dynamic>;
    return (
      supported: map['supported'] == true,
      message: map['message']?.toString() ?? '',
      error: map['error']?.toString(),
    );
  } catch (e) {
    return (
      supported: false,
      message: '',
      error: e.toString(),
    );
  }
}

void platformSetBleCallbacks({
  required void Function(BleDeviceState state) onStateChanged,
  required void Function(Map<String, dynamic> event) onSosTriggered,
}) {
  try {
    _jsBleRegisterCallbacks(
      ((JSString stateJson) {
        onStateChanged(_parseStateJson(stateJson.toDart));
      }).toJS,
      ((JSString sosJson) {
        try {
          final event = jsonDecode(sosJson.toDart) as Map<String, dynamic>;
          onSosTriggered(event);
        } catch (_) {}
      }).toJS,
    );
  } catch (e) {
    // Graceful fallback if bridge is missing
  }
}

void platformTriggerSimulatedBleButton() {
  try {
    _jsBleTriggerSimulatedButton();
  } catch (_) {}
}
