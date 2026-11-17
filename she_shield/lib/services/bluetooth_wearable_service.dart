import 'dart:async';
import 'package:flutter/material.dart';
import 'database_service.dart';
import 'local_database_service.dart';
import 'voice_engine_service.dart';
import 'geo_platform_stub.dart'
    if (dart.library.io) 'geo_platform_io.dart'
    if (dart.library.js_interop) 'geo_platform_web.dart';
import 'ble_platform_stub.dart'
    if (dart.library.io) 'ble_platform_io.dart'
    if (dart.library.js_interop) 'ble_platform_web.dart';

class BluetoothWearableService extends ChangeNotifier {
  static final BluetoothWearableService _instance = BluetoothWearableService._internal();
  factory BluetoothWearableService() => _instance;

  BluetoothWearableService._internal() {
    _initCallbacks();
  }

  BleDeviceState _currentDevice = disconnectedBleState();
  bool _bluetoothEnabled = true;
  bool _isScanning = false;
  String _selectedCategory = 'Smart Ring';
  String? _lastError;
  bool _isSosActive = false;
  String? _lastSosIncidentId;
  DateTime? _lastSosTriggerTime;

  DatabaseService? _boundDb;
  final LocalDatabaseService _localDb = LocalDatabaseService();

  final List<String> _deviceCategories = [
    'Smart Ring',
    'Smart Watch',
    'Smart Band',
    'Smart Pendant',
    'Bluetooth SOS Button',
    'Other compatible BLE device',
  ];

  // Getters
  BleDeviceState get currentDevice => _currentDevice;
  bool get bluetoothEnabled => _bluetoothEnabled;
  bool get isScanning => _isScanning;
  bool get isConnected => _currentDevice.connected;
  String get selectedCategory => _selectedCategory;
  List<String> get availableCategories => List.unmodifiable(_deviceCategories);
  String? get lastError => _lastError;
  bool get isSosActive => _isSosActive;
  String? get lastSosIncidentId => _lastSosIncidentId;

  void bindDatabase(DatabaseService db) {
    _boundDb = db;
  }

  void setSelectedCategory(String category) {
    if (_deviceCategories.contains(category)) {
      _selectedCategory = category;
      notifyListeners();
    }
  }

  void setBluetoothEnabled(bool enabled) {
    _bluetoothEnabled = enabled;
    if (!enabled && isConnected) {
      disconnect();
    }
    notifyListeners();
  }

  void _initCallbacks() {
    platformSetBleCallbacks(
      onStateChanged: (state) {
        _currentDevice = state;
        _lastError = state.error;
        if (state.connected) {
          _persistWearableState();
        }
        notifyListeners();
      },
      onSosTriggered: (event) {
        _handlePhysicalSosTrigger(event);
      },
    );
  }

  Future<bool> checkAvailability() async {
    final supported = await platformCheckBleSupport();
    if (!supported) {
      _lastError = 'Web Bluetooth API is unsupported on this browser.';
      notifyListeners();
      return false;
    }
    final available = await platformCheckBleAvailability();
    _bluetoothEnabled = available;
    notifyListeners();
    return available;
  }

  /// Scans for real nearby BLE devices and pairs with the selected hardware
  Future<BleDeviceState> scanAndConnect({String? category}) async {
    _isScanning = true;
    _lastError = null;
    notifyListeners();

    final targetCat = category ?? _selectedCategory;
    final state = await platformScanAndConnect(category: targetCat);

    _isScanning = false;
    _currentDevice = state;
    _lastError = state.error;

    if (state.connected) {
      _selectedCategory = state.deviceCategory;
      await _persistWearableState();
      await _localDb.logWearableEvent({
        'eventType': 'CONNECTED',
        'wearableId': state.deviceId,
        'deviceName': state.deviceName,
        'deviceCategory': state.deviceCategory,
        'details': {
          'batteryLevel': state.batteryLevel,
          'signalStrength': state.signalStrength,
          'macAddress': state.macAddress,
          'servicesCount': state.discoveredServices.length,
        },
      });
    }

    notifyListeners();
    return state;
  }

  /// Disconnects active BLE wearable
  Future<void> disconnect() async {
    if (_currentDevice.connected) {
      final oldId = _currentDevice.deviceId;
      final oldName = _currentDevice.deviceName;
      final oldCat = _currentDevice.deviceCategory;

      await platformDisconnectBle();
      _currentDevice = disconnectedBleState();

      await _localDb.logWearableEvent({
        'eventType': 'DISCONNECTED',
        'wearableId': oldId,
        'deviceName': oldName,
        'deviceCategory': oldCat,
        'details': {'reason': 'User requested disconnect'},
      });
      notifyListeners();
    }
  }

  /// Transmits acoustic alert command to wearable hardware buzzer if supported
  Future<({bool supported, String message, String? error})> playSound() async {
    if (!_currentDevice.connected) {
      return (
        supported: false,
        message: '',
        error: 'No wearable device is currently connected.',
      );
    }

    final res = await platformPlayBleSound();
    if (res.supported) {
      await _localDb.logWearableEvent({
        'eventType': 'SOUND_TEST',
        'wearableId': _currentDevice.deviceId,
        'deviceName': _currentDevice.deviceName,
        'deviceCategory': _currentDevice.deviceCategory,
        'details': {'result': 'Acoustic pulse transmitted to hardware buzzer'},
      });
    }
    return res;
  }

  /// Persists wearable state in backend database
  Future<void> _persistWearableState() async {
    if (!_currentDevice.connected || _currentDevice.deviceId.isEmpty) return;
    try {
      await _localDb.syncWearableDevice({
        'deviceId': _currentDevice.deviceId,
        'deviceName': _currentDevice.deviceName,
        'deviceCategory': _currentDevice.deviceCategory,
        'macAddress': _currentDevice.macAddress,
        'batteryLevel': _currentDevice.batteryLevel,
        'signalStrength': _currentDevice.signalStrength,
        'status': 'CONNECTED',
        'services': _currentDevice.discoveredServices,
      });
    } catch (_) {}
  }

  /// Primary handler for physical external button press on connected BLE wearable
  Future<void> _handlePhysicalSosTrigger(Map<String, dynamic> event) async {
    final now = DateTime.now();
    // Debounce to prevent repeated triggers
    if (_lastSosTriggerTime != null && now.difference(_lastSosTriggerTime!).inSeconds < 3) {
      return;
    }
    _lastSosTriggerTime = now;

    final incidentId = 'SOS-BLE-${now.millisecondsSinceEpoch}';
    _lastSosIncidentId = incidentId;
    _isSosActive = true;
    notifyListeners();

    // 1. Capture user's live GPS coordinates
    final gpsSample = await platformGetCurrentPosition();
    final gpsStr = (gpsSample.ok && gpsSample.latitude != null && gpsSample.longitude != null)
        ? '${gpsSample.latitude!.toStringAsFixed(5)}, ${gpsSample.longitude!.toStringAsFixed(5)}'
        : 'GPS Signal Unavailable';
    final locationName = gpsSample.ok ? 'Live Wearable GPS Zone' : 'GPS Unavailable';

    final devType = 'WEARABLE_BLE: ${_currentDevice.deviceCategory} (${_currentDevice.deviceName.isNotEmpty ? _currentDevice.deviceName : "Hardware Device"})';

    // 2. Persist SOS Incident in Neon PostgreSQL / Cloud Database
    if (_boundDb != null) {
      _boundDb!.addSosCase(
        id: incidentId,
        userName: _boundDb!.userName.isNotEmpty ? _boundDb!.userName : 'SHE SHIELD User',
        userPhone: _boundDb!.userPhone,
        gps: gpsStr,
        locationName: locationName,
        deviceType: devType,
        priority: 'CRITICAL',
      );
    } else {
      await _localDb.addSosCase(
        id: incidentId,
        userName: 'SHE SHIELD Wearable User',
        userPhone: '',
        priority: 'CRITICAL',
        status: 'open',
        gps: gpsStr,
        deviceType: devType,
        locationName: locationName,
      );
    }

    // 3. Log Wearable SOS Trigger Event
    await _localDb.logWearableEvent({
      'eventType': 'SOS_TRIGGERED',
      'wearableId': _currentDevice.deviceId.isNotEmpty ? _currentDevice.deviceId : event['deviceId'] ?? 'BLE_BUTTON',
      'deviceName': _currentDevice.deviceName.isNotEmpty ? _currentDevice.deviceName : event['deviceName'] ?? 'BLE SOS Button',
      'deviceCategory': _currentDevice.deviceCategory,
      'details': {
        'incidentId': incidentId,
        'gps': gpsStr,
        'characteristicUuid': event['characteristicUuid'] ?? '0xFFE1',
        'rawHex': event['rawHex'] ?? '01',
      },
    });

    // 4. Start automatic audio recording (after mic permission check)
    if (_boundDb != null) {
      await VoiceEngineService().triggerWearableAudioRecording(_boundDb!, sosId: incidentId);
    }

    notifyListeners();
  }

  /// Triggers a safe test SOS workflow to verify end-to-end integration
  Future<void> triggerSafeTestSos({required DatabaseService db}) async {
    _boundDb = db;
    final testEvent = {
      'ok': true,
      'deviceId': _currentDevice.deviceId.isNotEmpty ? _currentDevice.deviceId : 'TEST-SIM-BLE',
      'deviceName': _currentDevice.deviceName.isNotEmpty ? _currentDevice.deviceName : 'Test BLE Wearable Button',
      'deviceCategory': _selectedCategory,
      'triggerSource': 'WEARABLE_BLE',
      'characteristicUuid': '0000ffe1-0000-1000-8000-00805f9b34fb',
      'rawHex': '01',
      'simulated': true,
    };
    await _handlePhysicalSosTrigger(testEvent);
  }

  /// Resolves or disarms active SOS incident
  Future<void> resolveActiveSos() async {
    _isSosActive = false;
    if (_boundDb != null && VoiceEngineService().isRecording) {
      await VoiceEngineService().stopRecordingAndSave(_boundDb!, reason: 'Resolved by user PIN');
    }
    if (_lastSosIncidentId != null) {
      await _localDb.updateCaseStatus(_lastSosIncidentId!, 'resolved');
    }
    notifyListeners();
  }
}
