import 'dart:convert';
import 'package:flutter/services.dart';
import 'ble_platform_stub.dart';

export 'ble_platform_stub.dart' show BleDeviceState, disconnectedBleState;

const MethodChannel _bleChannel = MethodChannel('com.sheshield.she_shield/ble');
bool _handlerInitialized = false;
void Function(BleDeviceState state)? _onStateChanged;
void Function(Map<String, dynamic> event)? _onSosTriggered;

void _ensureChannelHandler() {
  if (_handlerInitialized) return;
  _handlerInitialized = true;
  _bleChannel.setMethodCallHandler((call) async {
    if (call.method == 'onBleStateChanged' && call.arguments != null) {
      if (_onStateChanged != null) {
        final raw = Map<String, dynamic>.from(call.arguments as Map);
        _onStateChanged!(_mapToState(raw));
      }
    } else if (call.method == 'onBleSosTriggered' && call.arguments != null) {
      if (_onSosTriggered != null) {
        final raw = Map<String, dynamic>.from(call.arguments as Map);
        _onSosTriggered!(raw);
      }
    }
  });
}

BleDeviceState _mapToState(Map<dynamic, dynamic>? raw) {
  if (raw == null) return disconnectedBleState();
  final srvRaw = raw['discoveredServices'];
  final services = (srvRaw is List) ? srvRaw.map((e) => e.toString()).toList() : <String>[];

  return (
    connected: raw['connected'] == true,
    isConnecting: raw['isConnecting'] == true,
    deviceId: raw['deviceId']?.toString() ?? '',
    deviceName: raw['deviceName']?.toString() ?? '',
    deviceCategory: raw['deviceCategory']?.toString() ?? 'Smart Ring',
    batteryLevel: raw['batteryLevel'] != null ? (raw['batteryLevel'] as num).toInt() : null,
    signalStrength: raw['signalStrength']?.toString() ?? 'Offline',
    macAddress: raw['macAddress']?.toString() ?? 'Not Connected',
    soundSupported: raw['soundSupported'] == true,
    discoveredServices: services,
    error: raw['error']?.toString(),
  );
}

Future<bool> platformCheckBleSupport() async {
  try {
    final res = await _bleChannel.invokeMethod<bool>('isSupported');
    return res == true;
  } catch (_) {
    return false;
  }
}

Future<bool> platformCheckBleAvailability() async {
  try {
    final res = await _bleChannel.invokeMethod<bool>('getAvailability');
    return res == true;
  } catch (_) {
    return false;
  }
}

Future<BleDeviceState> platformScanAndConnect({String? category}) async {
  _ensureChannelHandler();
  try {
    final res = await _bleChannel.invokeMethod<Map>('scanAndConnect', {'category': category ?? 'Smart Ring'});
    return _mapToState(res);
  } catch (e) {
    return disconnectedBleState(error: e.toString());
  }
}

Future<bool> platformDisconnectBle() async {
  try {
    final res = await _bleChannel.invokeMethod<bool>('disconnect');
    return res == true;
  } catch (_) {
    return false;
  }
}

Future<({bool supported, String message, String? error})> platformPlayBleSound() async {
  try {
    final res = await _bleChannel.invokeMethod<Map>('playSound');
    if (res != null) {
      return (
        supported: res['supported'] == true,
        message: res['message']?.toString() ?? '',
        error: res['error']?.toString(),
      );
    }
    return (supported: false, message: '', error: 'Unsupported native response.');
  } catch (e) {
    return (supported: false, message: '', error: e.toString());
  }
}

void platformSetBleCallbacks({
  required void Function(BleDeviceState state) onStateChanged,
  required void Function(Map<String, dynamic> event) onSosTriggered,
}) {
  _onStateChanged = onStateChanged;
  _onSosTriggered = onSosTriggered;
  _ensureChannelHandler();
}

void platformTriggerSimulatedBleButton() {
  if (_onSosTriggered != null) {
    _onSosTriggered!({
      'ok': true,
      'deviceId': 'TEST-NATIVE-BLE',
      'deviceName': 'Native Test Wearable Button',
      'deviceCategory': 'Bluetooth SOS Button',
      'triggerSource': 'WEARABLE_BLE',
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
