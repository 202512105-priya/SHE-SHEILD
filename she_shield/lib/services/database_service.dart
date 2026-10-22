import 'package:flutter/material.dart';

class DatabaseService extends ChangeNotifier {
  bool _onboardingCompleted = false;
  bool _vivaPrototypeMode = true; // Set to true for Viva Prototype Demo
  String? _currentRole; // 'user', 'guardian', 'responder', 'admin'
  String? _currentUserId;
  String _userName = 'tisha';
  String _userEmail = 'tisha@gmail.com';
  String _userPhone = '12435578494630';

  // Verifications
  bool _aadhaarVerified = false;
  bool _faceVerified = false;
  bool _otpVerified = false;
  double _faceMatchScore = 94.6;

  // Safety Index
  int _safetyIndex = 100;
  String _riskTrend = 'STABLE';

  // SOS Protection Settings
  bool _volButtonTrigger = true;
  bool _doublePowerTrigger = true;
  bool _triplePowerTrigger = false;
  bool _bluetoothTrigger = true;

  bool _secretVoiceTriggerEnabled = true;
  String _customVoicePhrase = 'capcap';
  bool _offlineVoiceDetection = true;
  String _selectedLanguage = 'Hindi';

  String _secretWord = 'Box Box';
  bool _silentSosMode = false;

  bool _smsFallback = true;
  bool _offlineCacheCoords = true;
  bool _alertSyncQueue = true;

  // Wearables
  bool _smartwatchConnected = true;
  bool _smartbandConnected = true;
  bool _pendantPaired = false;
  bool _buttonSwitchConnected = true;

  // Travel Mode State
  bool _isTravelActive = false;
  String _travelDestination = '';
  int _travelDurationMinutes = 55;
  String _travelRecordingMode = 'Video & Audio';

  // Cab Guardian State
  bool _isCabTripActive = false;
  String _cabPlate = 'GJ-01-XX-9999';
  double _cabSafetyScore = 4.6;
  String _cabDestination = 'cgroad';
  double _routeOffset = 30;
  int _cabDeviations = 1;
  int _cabRiskIndex = 37;
  int _cabUnsafeHits = 0;

  // Walk Guardian State
  bool _isWalkModeActive = false;
  String _walkRecordingMode = 'Video & Audio';
  String _safetyPin = '1234';

  // Evidence Locker
  final List<Map<String, dynamic>> _vaultAssets = [
    {
      'name': 'Travel_Trip_Audio_Evidence.mp4',
      'hash': 'SHA256: 643199974ac7064...',
      'tamperCheck': 'PASS',
      'status': 'Uploaded',
      'timestamp': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
    }
  ];

  // Cyber Crime Reports
  final List<Map<String, dynamic>> _cyberComplaints = [
    {
      'id': 'case-1780512594344',
      'category': 'BLACKMAIL',
      'description': 'blackmail with photoes',
      'threatScore': '92%',
      'status': 'SUBMITTED',
      'timestamp': DateTime.now().toIso8601String(),
    }
  ];

  // Guardian Network
  final List<Map<String, dynamic>> _guardians = [
    {
      'email': 'abc@gmail.com',
      'relation': 'mother',
      'status': 'PENDING',
      'uid': 'user-1780512130238',
    }
  ];

  // Responder SOS Cases
  final List<Map<String, dynamic>> _sosCases = [
    {
      'id': 'case-178051265857',
      'userName': 'ooo',
      'userEmail': 'ooen',
      'userPhone': '949494',
      'age': 24,
      'bloodGroup': 'O+',
      'priority': 'CRITICAL',
      'status': 'open',
      'gps': '23.023403, 72.572400',
      'timestamp': '2026-05-04T00:20:25.857918',
      'deviceType': 'Smart Watch / BLE Beacon Relay',
      'evidenceCount': 2,
    },
    {
      'id': 'case-1780512510342',
      'userName': 'Priya Sharma',
      'userPhone': '9876543210',
      'priority': 'CRITICAL',
      'status': 'open',
      'gps': '23.0245, 72.5710',
      'timestamp': '2026-05-04T00:15:10',
      'deviceType': 'SOS Hold Trigger',
      'evidenceCount': 1,
    }
  ];

  // Getters
  bool get onboardingCompleted => _onboardingCompleted;
  bool get vivaPrototypeMode => _vivaPrototypeMode;
  String? get currentRole => _currentRole;
  String? get currentUserId => _currentUserId;
  String get userName => _userName;
  String get userEmail => _userEmail;
  String get userPhone => _userPhone;

  bool get aadhaarVerified => _aadhaarVerified;
  bool get faceVerified => _faceVerified;
  bool get otpVerified => _otpVerified;
  double get faceMatchScore => _faceMatchScore;

  int get safetyIndex => _safetyIndex;
  String get riskTrend => _riskTrend;

  bool get volButtonTrigger => _volButtonTrigger;
  bool get doublePowerTrigger => _doublePowerTrigger;
  bool get triplePowerTrigger => _triplePowerTrigger;
  bool get bluetoothTrigger => _bluetoothTrigger;

  bool get secretVoiceTriggerEnabled => _secretVoiceTriggerEnabled;
  String get customVoicePhrase => _customVoicePhrase;
  bool get offlineVoiceDetection => _offlineVoiceDetection;
  String get selectedLanguage => _selectedLanguage;

  String get secretWord => _secretWord;
  bool get silentSosMode => _silentSosMode;

  bool get smsFallback => _smsFallback;
  bool get offlineCacheCoords => _offlineCacheCoords;
  bool get alertSyncQueue => _alertSyncQueue;

  bool get smartwatchConnected => _smartwatchConnected;
  bool get smartbandConnected => _smartbandConnected;
  bool get pendantPaired => _pendantPaired;
  bool get buttonSwitchConnected => _buttonSwitchConnected;

  bool get isTravelActive => _isTravelActive;
  String get travelDestination => _travelDestination;
  int get travelDurationMinutes => _travelDurationMinutes;
  String get travelRecordingMode => _travelRecordingMode;

  bool get isCabTripActive => _isCabTripActive;
  String get cabPlate => _cabPlate;
  double get cabSafetyScore => _cabSafetyScore;
  String get cabDestination => _cabDestination;
  double get routeOffset => _routeOffset;
  int get cabDeviations => _cabDeviations;
  int get cabRiskIndex => _cabRiskIndex;
  int get cabUnsafeHits => _cabUnsafeHits;

  bool get isWalkModeActive => _isWalkModeActive;
  String get walkRecordingMode => _walkRecordingMode;
  String get safetyPin => _safetyPin;

  List<Map<String, dynamic>> get vaultAssets => List.unmodifiable(_vaultAssets);
  List<Map<String, dynamic>> get cyberComplaints => List.unmodifiable(_cyberComplaints);
  List<Map<String, dynamic>> get guardians => List.unmodifiable(_guardians);
  List<Map<String, dynamic>> get sosCases => List.unmodifiable(_sosCases);

  // Setters / Actions
  void toggleVivaPrototypeMode(bool val) {
    _vivaPrototypeMode = val;
    notifyListeners();
  }

  void completeOnboarding() {
    _onboardingCompleted = true;
    notifyListeners();
  }

  void setRole(String role) {
    _currentRole = role;
    notifyListeners();
  }

  void loginUser(String email, String name) {
    _currentUserId = 'user-${DateTime.now().millisecondsSinceEpoch}';
    _userEmail = email;
    _userName = name;
    notifyListeners();
  }

  void verifyAadhaar() {
    _aadhaarVerified = true;
    notifyListeners();
  }

  void verifyFace() {
    _faceVerified = true;
    notifyListeners();
  }

  void verifyOtp() {
    _otpVerified = true;
    notifyListeners();
  }

  void toggleVolTrigger(bool val) {
    _volButtonTrigger = val;
    notifyListeners();
  }

  void toggleDoublePower(bool val) {
    _doublePowerTrigger = val;
    notifyListeners();
  }

  void toggleTriplePower(bool val) {
    _triplePowerTrigger = val;
    notifyListeners();
  }

  void toggleBluetooth(bool val) {
    _bluetoothTrigger = val;
    notifyListeners();
  }

  void setCustomVoicePhrase(String phrase) {
    _customVoicePhrase = phrase;
    notifyListeners();
  }

  void setSelectedLanguage(String lang) {
    _selectedLanguage = lang;
    notifyListeners();
  }

  void setSecretWord(String word) {
    _secretWord = word;
    notifyListeners();
  }

  void toggleSilentSos(bool val) {
    _silentSosMode = val;
    notifyListeners();
  }

  void startTravel({required String destination, required int duration, required String mode}) {
    _isTravelActive = true;
    _travelDestination = destination;
    _travelDurationMinutes = duration;
    _travelRecordingMode = mode;
    notifyListeners();
  }

  void endTravel() {
    _isTravelActive = false;
    notifyListeners();
  }

  void startCabTrip({required String plate, required String destination, required String mode}) {
    _isCabTripActive = true;
    _cabPlate = plate;
    _cabDestination = destination;
    notifyListeners();
  }

  void updateCabMetrics({required int riskIndex, required int deviations, required int unsafeHits}) {
    _cabRiskIndex = riskIndex;
    _cabDeviations = deviations;
    _cabUnsafeHits = unsafeHits;
    notifyListeners();
  }

  void endCabTrip() {
    _isCabTripActive = false;
    notifyListeners();
  }

  void startWalkMode(String mode) {
    _isWalkModeActive = true;
    _walkRecordingMode = mode;
    notifyListeners();
  }

  void endWalkMode() {
    _isWalkModeActive = false;
    notifyListeners();
  }

  void addCyberComplaint(String description, String link) {
    _cyberComplaints.add({
      'id': 'case-${DateTime.now().millisecondsSinceEpoch}',
      'category': 'BLACKMAIL',
      'description': description,
      'threatScore': '92%',
      'status': 'SUBMITTED',
      'timestamp': DateTime.now().toIso8601String(),
    });
    notifyListeners();
  }

  void addGuardian(String email, String relation) {
    _guardians.add({
      'email': email,
      'relation': relation,
      'status': 'PENDING',
      'uid': 'user-${DateTime.now().millisecondsSinceEpoch}',
    });
    notifyListeners();
  }

  void addVaultAsset(String name) {
    _vaultAssets.add({
      'name': name,
      'hash': 'SHA256: ${DateTime.now().millisecondsSinceEpoch}ac7064...',
      'tamperCheck': 'PASS',
      'status': 'Uploaded',
      'timestamp': DateTime.now().toIso8601String(),
    });
    notifyListeners();
  }
}
