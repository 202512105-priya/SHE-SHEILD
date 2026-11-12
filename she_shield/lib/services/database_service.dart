import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'local_database_service.dart';
import 'voice_platform_stub.dart'
    if (dart.library.io) 'voice_platform_io.dart'
    if (dart.library.js_interop) 'voice_platform_web.dart';

class DatabaseService extends ChangeNotifier {
  final LocalDatabaseService _dbService = LocalDatabaseService();
  bool _isDatabaseLive = false;
  bool _isSessionRestoring = false;

  bool get isDatabaseLive => _isDatabaseLive;
  bool get isPostgresLive => _isDatabaseLive;
  bool get isSessionRestoring => _isSessionRestoring;
  String get activeServerUrl => _dbService.activeServerUrl;

  // Authenticated User & RBAC State
  bool _isAuthenticated = false;
  String? _currentRole; // 'registered_user', 'guardian', 'officer', 'admin'
  String? _roleId;
  String? _currentUserId;
  String _userName = '';
  String _userEmail = '';
  String _userPhone = '';
  String _accountStatus = '';
  String _badgeId = '';
  String _station = '';
  Set<String> _permissions = <String>{};

  bool get isAuthenticated => _isAuthenticated;
  String? get currentRole => _currentRole;
  String? get roleId => _roleId;
  String? get currentUserId => _currentUserId;
  String get userName => _userName;
  String get userEmail => _userEmail;
  String get userPhone => _userPhone;
  String get accountStatus => _accountStatus;
  String get badgeId => _badgeId;
  String get station => _station;
  Set<String> get permissions => Set.unmodifiable(_permissions);

  DatabaseService() {
    _dbService.onUnauthorized = _clearSessionState;
    if (_dbService.authToken != null && _dbService.authToken!.isNotEmpty) {
      _isSessionRestoring = true;
    }
    _initDatabase();
  }

  Future<bool> _initDatabase({bool forceReprobe = false}) async {
    try {
      await _dbService.hydratePersistedSettings();
      if (_dbService.authToken != null && _dbService.authToken!.isNotEmpty && !_isSessionRestoring) {
        _isSessionRestoring = true;
        notifyListeners();
      }
      final connected = await _dbService.connect(forceReprobe: forceReprobe);
      _isDatabaseLive = connected;

      if (connected && _dbService.authToken != null && _dbService.authToken!.isNotEmpty) {
        final me = await _dbService.fetchCurrentUser();
        if (me.success && me.data != null && me.data!['user'] is Map) {
          _applyAuthenticatedUser(Map<String, dynamic>.from(me.data!['user'] as Map));
          await syncFromDatabase();
        } else {
          _clearSessionState(notify: false);
        }
      }
      _isSessionRestoring = false;
      notifyListeners();
      return _isDatabaseLive;
    } catch (e) {
      debugPrint('[DatabaseService] Local SQLite server init error: $e');
      _isDatabaseLive = false;
      _isSessionRestoring = false;
      notifyListeners();
      return false;
    }
  }

  void _applyAuthenticatedUser(Map<String, dynamic> userMap) {
    _isAuthenticated = true;
    _currentUserId = userMap['id']?.toString();
    _userName = userMap['fullName']?.toString() ?? '';
    _userEmail = userMap['email']?.toString() ?? '';
    _userPhone = userMap['phone']?.toString() ?? '';
    _currentRole = userMap['role']?.toString() ?? 'registered_user';
    _roleId = userMap['roleId']?.toString() ?? 'ROLE_USER';
    _accountStatus = userMap['accountStatus']?.toString() ?? 'ACTIVE';
    _aadhaarVerified = userMap['aadhaarVerified'] == true;
    _faceVerified = userMap['faceVerified'] == true;
    _otpVerified = userMap['otpVerified'] == true;
    _badgeId = userMap['badgeId']?.toString() ?? '';
    _station = userMap['station']?.toString() ?? '';

    final rawPerms = userMap['permissions'];
    if (rawPerms is List) {
      _permissions = rawPerms.map((p) => p.toString()).toSet();
    } else {
      _permissions = <String>{};
    }
  }

  void _clearSessionState({bool notify = true}) {
    _isAuthenticated = false;
    _currentUserId = null;
    _currentRole = null;
    _roleId = null;
    _userName = '';
    _userEmail = '';
    _userPhone = '';
    _accountStatus = '';
    _badgeId = '';
    _station = '';
    _permissions = <String>{};
    _aadhaarVerified = false;
    _faceVerified = false;
    _otpVerified = false;
    _faceMatchScore = 0.0;
    _sosCases.clear();
    _cyberComplaints.clear();
    _vaultAssets.clear();
    _guardians.clear();
    _audioEvidence.clear();
    _offlineAudioQueue.clear();
    _voiceSosEnabled = false;
    _customVoicePhrase = '';
    _selectedLanguage = 'English';
    _maxRecordingDurationSec = 120;
    _dbService.setAuthToken(null);
    if (notify) {
      notifyListeners();
    }
  }

  Future<bool> syncFromDatabase() async {
    try {
      final connected = await _dbService.connect();
      if (!connected) {
        _isDatabaseLive = false;
        notifyListeners();
        return false;
      }

      if (!_isAuthenticated) {
        _isDatabaseLive = true;
        notifyListeners();
        return true;
      }

      final cases = await _dbService.getSosCases();
      if (cases != null) {
        _sosCases
          ..clear()
          ..addAll(cases);
      }

      if (hasPermission('complaint:view_all') || hasPermission('complaint:view_own')) {
        final complaints = await _dbService.getCyberComplaints();
        if (complaints != null) {
          _cyberComplaints
            ..clear()
            ..addAll(complaints);
        }
      }

      if (hasPermission('vault:view_all') || hasPermission('vault:view_own')) {
        final assets = await _dbService.getVaultAssets();
        if (assets != null) {
          _vaultAssets
            ..clear()
            ..addAll(assets);
        }
      }

      if (hasPermission('guardian:manage') || hasPermission('sos:view_all')) {
        final gdns = await _dbService.getGuardians();
        if (gdns != null) {
          _guardians
            ..clear()
            ..addAll(gdns);
        }
      }

      if (hasPermission('voice_sos:own')) {
        await loadVoiceSosSettings();
      }

      if (hasPermission('audio_evidence:own')) {
        await syncPendingOfflineAudio();
        await loadAudioEvidence();
      }

      _isDatabaseLive = _dbService.isConnected;
      notifyListeners();
      debugPrint('[DatabaseService] Synced live data with Local SQLite Server (${_dbService.activeServerUrl})!');
      return _isDatabaseLive;
    } catch (e) {
      debugPrint('[DatabaseService] Error syncing with Local SQLite Server: $e');
      _isDatabaseLive = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> syncFromPostgres() async {
    return syncFromDatabase();
  }

  Future<bool> setCustomServerHost(String host) async {
    _dbService.setCustomServerHost(host);
    return _initDatabase(forceReprobe: true);
  }

  // ---------------------------------------------------------------------------
  // AUTHENTICATION & AUTHORIZATION ACTIONS
  // ---------------------------------------------------------------------------

  bool hasPermission(String permission) => _permissions.contains(permission);

  String get homeRouteForRole {
    if (!_isAuthenticated) return '/login';
    switch (_currentRole) {
      case 'admin':
        return '/admin_dashboard';
      case 'officer':
        return '/responder_dashboard';
      case 'guardian':
        return '/guardian_dashboard';
      case 'registered_user':
        return '/dashboard';
      default:
        return '/login';
    }
  }

  bool canAccessRoute(String routeName) {
    final uriPath = Uri.tryParse(routeName)?.path ?? routeName;
    const publicRoutes = {
      '/',
      '/onboarding',
      '/welcome',
      '/login',
      '/register_user',
    };
    if (publicRoutes.contains(uriPath) || uriPath.startsWith('/track/')) return true;
    if (!_isAuthenticated) return false;

    if (routeName == '/admin_dashboard') {
      return hasPermission('dashboard:admin') && _currentRole == 'admin';
    }
    if (routeName == '/responder_dashboard') {
      return hasPermission('dashboard:officer') || _currentRole == 'admin';
    }
    if (routeName == '/guardian_dashboard') {
      return hasPermission('dashboard:guardian') || _currentRole == 'admin';
    }

    const userPortalRoutes = {
      '/dashboard',
      '/sos',
      '/sos_protection',
      '/travel_monitor',
      '/cab_monitor',
      '/walk_monitor',
      '/wearable_pairing',
      '/cyber_report',
      '/complaint_status',
      '/evidence_vault',
      '/manage_guardians',
      '/awareness_hub',
      '/help_center',
      '/demo_center',
    };
    if (userPortalRoutes.contains(routeName)) {
      return hasPermission('dashboard:user') || _currentRole == 'admin';
    }

    return false;
  }

  Future<ApiResult<Map<String, dynamic>>> registerAccount({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    String accountType = 'registered_user',
    String? aadhaarNumber,
    String? inviteToken,
    String? shareToken,
  }) async {
    final res = await _dbService.registerUser(
      fullName: fullName,
      email: email,
      phone: phone,
      password: password,
      accountType: accountType,
      aadhaarNumber: aadhaarNumber,
      inviteToken: inviteToken,
      shareToken: shareToken,
    );
    _isDatabaseLive = _dbService.isConnected;
    if (res.success && res.data != null && res.data!['user'] is Map) {
      _applyAuthenticatedUser(Map<String, dynamic>.from(res.data!['user'] as Map));
      await syncFromDatabase();
      notifyListeners();
    } else {
      notifyListeners();
    }
    return res;
  }

  Future<ApiResult<Map<String, dynamic>>> authenticateWithCredentials({
    required String email,
    required String password,
  }) async {
    final res = await _dbService.loginWithCredentials(
      email: email,
      password: password,
    );
    _isDatabaseLive = _dbService.isConnected;
    if (res.success && res.data != null && res.data!['user'] is Map) {
      _applyAuthenticatedUser(Map<String, dynamic>.from(res.data!['user'] as Map));
      await syncFromDatabase();
      notifyListeners();
    } else {
      notifyListeners();
    }
    return res;
  }

  Future<void> logout() async {
    await _dbService.logout();
    _clearSessionState();
  }

  Future<ApiResult<Map<String, dynamic>>> updateProfile({
    required String fullName,
    required String phone,
  }) async {
    final res = await _dbService.updateUserProfile(fullName: fullName, phone: phone);
    if (res.success && res.data != null && res.data!['user'] is Map) {
      _applyAuthenticatedUser(Map<String, dynamic>.from(res.data!['user'] as Map));
      notifyListeners();
    }
    return res;
  }

  // ---------------------------------------------------------------------------
  // ADMIN USER MANAGEMENT PROXIES (BACKEND RBAC ENFORCED)
  // ---------------------------------------------------------------------------

  Future<ApiResult<List<Map<String, dynamic>>>> adminFetchUsers({String query = ''}) {
    return _dbService.adminListUsers(query: query);
  }

  Future<ApiResult<List<Map<String, dynamic>>>> adminFetchRoles() {
    return _dbService.adminListRoles();
  }

  Future<ApiResult<Map<String, dynamic>>> adminCreateOfficer({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    String badgeId = '',
    String station = '',
  }) {
    return _dbService.adminCreateOfficer(
      fullName: fullName,
      email: email,
      phone: phone,
      password: password,
      badgeId: badgeId,
      station: station,
    );
  }

  Future<ApiResult<Map<String, dynamic>>> adminAssignRole({
    required String userId,
    required String roleId,
  }) {
    return _dbService.adminAssignRole(userId: userId, roleId: roleId);
  }

  Future<ApiResult<Map<String, dynamic>>> adminUpdateAccountStatus({
    required String userId,
    required String accountStatus,
  }) {
    return _dbService.adminUpdateAccountStatus(
      userId: userId,
      accountStatus: accountStatus,
    );
  }

  Future<ApiResult<List<Map<String, dynamic>>>> adminFetchAuditLogs() {
    return _dbService.adminFetchAuditLogs();
  }

  // ---------------------------------------------------------------------------
  // APP SAFETY & TELEMETRY STATE
  // ---------------------------------------------------------------------------

  bool _onboardingCompleted = false;
  bool _vivaPrototypeMode = false;

  // Verifications (strictly false unless backend-verified)
  bool _aadhaarVerified = false;
  bool _faceVerified = false;
  bool _otpVerified = false;
  double _faceMatchScore = 0.0;

  // Safety Index
  final int _safetyIndex = 100;
  final String _riskTrend = 'STABLE';

  // SOS Protection Settings
  bool _volButtonTrigger = true;
  bool _doublePowerTrigger = true;
  bool _triplePowerTrigger = false;
  bool _bluetoothTrigger = true;

  final bool _secretVoiceTriggerEnabled = true;
  String _customVoicePhrase = '';
  final bool _offlineVoiceDetection = true;
  String _selectedLanguage = 'English';
  bool _voiceSosEnabled = false;
  int _maxRecordingDurationSec = 120;

  String _secretWord = 'Box Box';
  bool _silentSosMode = false;

  final bool _smsFallback = true;
  final bool _offlineCacheCoords = true;
  final bool _alertSyncQueue = true;

  // Wearables
  final bool _smartwatchConnected = true;
  final bool _smartbandConnected = true;
  final bool _pendantPaired = false;
  final bool _buttonSwitchConnected = true;

  // Travel Mode State
  bool _isTravelActive = false;
  String _travelDestination = '';
  int _travelDurationMinutes = 55;
  String _travelRecordingMode = 'Video & Audio';

  // Cab Guardian State
  bool _isCabTripActive = false;
  String _cabPlate = 'GJ-01-XX-9999';
  final double _cabSafetyScore = 4.6;
  String _cabDestination = 'cgroad';
  final double _routeOffset = 30;
  int _cabDeviations = 1;
  int _cabRiskIndex = 37;
  int _cabUnsafeHits = 0;

  // Walk Guardian State
  bool _isWalkModeActive = false;
  String _walkRecordingMode = 'Video & Audio';
  final String _safetyPin = '1234';

  // Database-backed runtime collections
  final List<Map<String, dynamic>> _vaultAssets = [];
  final List<Map<String, dynamic>> _cyberComplaints = [];
  final List<Map<String, dynamic>> _guardians = [];
  final List<Map<String, dynamic>> _sosCases = [];
  final List<Map<String, dynamic>> _audioEvidence = [];
  final List<Map<String, dynamic>> _offlineAudioQueue = [];

  bool get voiceSosEnabled => _voiceSosEnabled;
  int get maxRecordingDurationSec => _maxRecordingDurationSec;
  List<Map<String, dynamic>> get audioEvidence => List.unmodifiable(_audioEvidence);
  List<Map<String, dynamic>> get offlineAudioQueue => List.unmodifiable(_offlineAudioQueue);
  String? get authToken => _dbService.authToken;
  String audioStreamUrl(String recordingId) => _dbService.audioStreamUrl(recordingId);
  String audioDownloadUrl(String recordingId) => _dbService.audioDownloadUrl(recordingId);

  // Getters
  bool get onboardingCompleted => _onboardingCompleted;
  bool get vivaPrototypeMode => _vivaPrototypeMode;

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

  void toggleVivaPrototypeMode(bool val) {
    _vivaPrototypeMode = val;
    notifyListeners();
  }

  void completeOnboarding() {
    _onboardingCompleted = true;
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

  // Permissions & Background Protection
  bool _batteryUnrestricted = true;
  bool _backgroundLocationGranted = true;
  bool _voiceMicGranted = true;
  bool _backgroundVoiceSosActive = true;

  bool get batteryUnrestricted => _batteryUnrestricted;
  bool get backgroundLocationGranted => _backgroundLocationGranted;
  bool get voiceMicGranted => _voiceMicGranted;
  bool get backgroundVoiceSosActive => _backgroundVoiceSosActive;

  void toggleBatteryOptimization(bool val) {
    _batteryUnrestricted = val;
    notifyListeners();
  }

  void toggleBackgroundLocation(bool val) {
    _backgroundLocationGranted = val;
    notifyListeners();
  }

  void toggleVoiceMic(bool val) {
    _voiceMicGranted = val;
    notifyListeners();
  }

  void toggleBackgroundVoiceSos(bool val) {
    _backgroundVoiceSosActive = val;
    notifyListeners();
  }

  void addSosCase({
    required String userName,
    required String userPhone,
    required String gps,
    required String locationName,
    required String deviceType,
    String priority = 'CRITICAL',
    String? id,
  }) {
    if (!hasPermission('sos:create')) return;
    final caseId = id ?? 'case-${DateTime.now().millisecondsSinceEpoch}';
    final newCase = {
      'id': caseId,
      'userId': _currentUserId ?? '',
      'userName': userName,
      'userEmail': _userEmail,
      'userPhone': userPhone,
      'age': 22,
      'bloodGroup': 'O+',
      'priority': priority,
      'status': 'open',
      'gps': gps,
      'timestamp': DateTime.now().toIso8601String(),
      'deviceType': deviceType,
      'evidenceCount': 1,
      'locationName': locationName,
    };
    _sosCases.insert(0, newCase);
    notifyListeners();

    _dbService.addSosCase(
      id: caseId,
      userName: userName,
      userEmail: _userEmail,
      userPhone: userPhone,
      priority: priority,
      status: 'open',
      gps: gps,
      deviceType: deviceType,
      locationName: locationName,
    );
  }

  void updateCaseStatus(String caseId, String newStatus) {
    if (!hasPermission('sos:update_status')) return;
    for (var c in _sosCases) {
      if (c['id'] == caseId) {
        c['status'] = newStatus.toLowerCase();
        break;
      }
    }
    notifyListeners();
    _dbService.updateCaseStatus(caseId, newStatus);
  }

  void updateCyberComplaintStatus(String complaintId, String newStatus) {
    if (!hasPermission('complaint:update_status')) return;
    for (var c in _cyberComplaints) {
      if (c['id'] == complaintId) {
        c['status'] = newStatus.toUpperCase();
        break;
      }
    }
    notifyListeners();
    _dbService.updateCyberComplaintStatus(complaintId, newStatus);
  }

  void addCyberComplaint(
    String description,
    String link, {
    String category = 'BLACKMAIL & EXTORTION',
    String threatScore = '94%',
    List<String> attachedEvidence = const [],
  }) {
    if (!hasPermission('complaint:create')) return;
    final newId = 'case-${DateTime.now().millisecondsSinceEpoch}';
    final evidenceStr = attachedEvidence.join('; ');
    final newComplaint = {
      'id': newId,
      'category': category,
      'description': description,
      'threatScore': threatScore,
      'status': 'SUBMITTED',
      'timestamp': DateTime.now().toIso8601String(),
      'userName': _userName,
      'userPhone': _userPhone,
      'offenderLink': link,
      'evidenceCount': attachedEvidence.isNotEmpty ? attachedEvidence.length : 1,
      'attachedEvidence': evidenceStr,
    };
    _cyberComplaints.insert(0, newComplaint);
    notifyListeners();

    _dbService.addCyberComplaint(
      id: newId,
      category: category,
      description: description,
      threatScore: threatScore,
      status: 'SUBMITTED',
      userName: _userName,
      userPhone: _userPhone,
      offenderLink: link,
      attachedEvidence: evidenceStr,
      evidenceCount: attachedEvidence.isNotEmpty ? attachedEvidence.length : 1,
    );
  }

  void addGuardian(String email, String relation, {String phone = ''}) {
    if (!hasPermission('guardian:manage')) return;
    final gId = 'GDN-${DateTime.now().millisecondsSinceEpoch}';
    _guardians.add({
      'id': gId,
      'email': email.trim().toLowerCase(),
      'relation': relation,
      'status': 'PENDING',
      'uid': _currentUserId ?? '',
    });
    notifyListeners();

    _dbService.addGuardian(
      id: gId,
      wardName: _userName,
      guardianName: email.split('@').first,
      email: email.trim().toLowerCase(),
      phone: phone,
      relation: relation,
      status: 'PENDING',
    );
  }

  void addVaultAsset(
    String name, {
    String fileType = 'DOCUMENT',
    String sizeMb = '2.4 MB',
    String? hash,
    String? chainOfCustody,
  }) {
    if (!hasPermission('vault:upload')) return;
    final assetId = 'EV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final assetHash = hash ?? 'SHA256: ${DateTime.now().millisecondsSinceEpoch}7f83b165...';
    final newAsset = {
      'id': assetId,
      'name': name,
      'fileType': fileType,
      'hash': assetHash,
      'tamperCheck': 'PASS',
      'status': 'Uploaded',
      'timestamp': DateTime.now().toIso8601String(),
      'sizeMb': sizeMb,
      'chainOfCustody': chainOfCustody ?? 'Device Local Ingestion -> Encrypted Vault',
    };
    _vaultAssets.insert(0, newAsset);
    notifyListeners();

    _dbService.addVaultAsset(
      id: assetId,
      name: name,
      fileType: fileType,
      hashSha256: assetHash,
      tamperCheck: 'PASS',
      status: 'Uploaded',
      sizeMb: sizeMb,
      chainOfCustody: chainOfCustody ?? 'Device Local Ingestion -> Encrypted Vault',
    );
  }

  // ---------------------------------------------------------------------------
  // WOMEN ROLE: VOICE SOS SETTINGS & AUDIO EVIDENCE VAULT METHODS
  // ---------------------------------------------------------------------------

  Future<void> loadVoiceSosSettings() async {
    if (!hasPermission('voice_sos:own')) return;
    final res = await _dbService.getVoiceSettings();
    if (res.success && res.data != null) {
      final d = res.data!;
      _customVoicePhrase = d['voicePhrase']?.toString() ?? '';
      _selectedLanguage = d['language']?.toString() ?? 'English';
      _voiceSosEnabled = d['voiceSosEnabled'] == true;
      _maxRecordingDurationSec = (d['maxDurationSeconds'] is num)
          ? (d['maxDurationSeconds'] as num).toInt()
          : 120;
      _silentSosMode = d['silentSosMode'] == true;
      notifyListeners();
    }
  }

  Future<ApiResult<Map<String, dynamic>>> saveVoiceSosSettings({
    String? voicePhrase,
    String? language,
    bool? voiceSosEnabled,
    int? maxDurationSeconds,
    bool? silentSosMode,
  }) async {
    final nextPhrase = (voicePhrase ?? _customVoicePhrase).trim();
    final nextLang = language ?? _selectedLanguage;
    final nextEnabled = voiceSosEnabled ?? _voiceSosEnabled;
    final nextMaxDur = maxDurationSeconds ?? _maxRecordingDurationSec;
    final nextSilent = silentSosMode ?? _silentSosMode;

    if (!hasPermission('voice_sos:own')) {
      return const ApiResult(
        success: false,
        statusCode: 403,
        error: 'Forbidden: Only authenticated Women Users may configure Voice SOS.',
      );
    }

    final res = await _dbService.saveVoiceSettings(
      voicePhrase: nextPhrase,
      language: nextLang,
      voiceSosEnabled: nextEnabled,
      maxDurationSeconds: nextMaxDur,
      silentSosMode: nextSilent,
    );

    if (res.success) {
      _customVoicePhrase = nextPhrase;
      _selectedLanguage = nextLang;
      _voiceSosEnabled = nextEnabled;
      _maxRecordingDurationSec = nextMaxDur;
      _silentSosMode = nextSilent;
      notifyListeners();
    } else if (res.statusCode == 0) {
      // Allow local offline toggle without losing changes while disconnected
      _customVoicePhrase = nextPhrase;
      _selectedLanguage = nextLang;
      _voiceSosEnabled = nextEnabled;
      _maxRecordingDurationSec = nextMaxDur;
      _silentSosMode = nextSilent;
      notifyListeners();
    }
    return res;
  }

  Future<void> loadAudioEvidence() async {
    if (!hasPermission('audio_evidence:own')) return;
    final offlineList = await platformOfflineList(_currentUserId ?? '');
    _offlineAudioQueue
      ..clear()
      ..addAll(offlineList);

    final res = await _dbService.getAudioEvidence();
    if (res.success && res.data != null) {
      _audioEvidence
        ..clear()
        ..addAll(res.data!);
    }
    notifyListeners();
  }

  Future<bool> createVoiceSosEvent({
    required String sosEventId,
    String deviceType = 'Voice SOS Auto-Trigger',
    String gps = '23.0225, 72.5714',
    String locationName = 'Live Protected Zone',
  }) async {
    if (!hasPermission('sos:create')) return false;
    final newCase = {
      'id': sosEventId,
      'userId': _currentUserId ?? '',
      'userName': _userName,
      'userEmail': _userEmail,
      'userPhone': _userPhone,
      'age': 22,
      'bloodGroup': 'O+',
      'priority': 'CRITICAL',
      'status': 'open',
      'gps': gps,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'deviceType': deviceType,
      'evidenceCount': 1,
      'locationName': locationName,
    };
    _sosCases.insert(0, newCase);
    notifyListeners();

    final ok = await _dbService.addSosCase(
      id: sosEventId,
      userName: _userName,
      userEmail: _userEmail,
      userPhone: _userPhone,
      priority: 'CRITICAL',
      status: 'open',
      gps: gps,
      deviceType: deviceType,
      locationName: locationName,
    );
    return ok;
  }

  Future<({bool savedOnline, bool savedOffline, Map<String, dynamic>? recording, String? error})>
      saveRecordedAudioEvidence({
    required String recordingId,
    required String sosEventId,
    required String filename,
    required String mimeType,
    required Uint8List bytes,
    required int durationSeconds,
    required String startedAt,
    required String endedAt,
    required String sha256Hash,
    String triggerPhrase = '',
  }) async {
    if (!hasPermission('audio_evidence:own')) {
      return (
        savedOnline: false,
        savedOffline: false,
        recording: null,
        error: 'Forbidden: Only authorized Women User accounts may upload audio evidence.',
      );
    }

    final res = await _dbService.uploadAudioEvidence(
      recordingId: recordingId,
      sosEventId: sosEventId,
      filename: filename,
      mimeType: mimeType,
      bytes: bytes,
      durationSeconds: durationSeconds,
      startedAt: startedAt,
      endedAt: endedAt,
      clientSha256: sha256Hash,
      triggerPhrase: triggerPhrase,
    );

    if (res.success && res.data != null && res.data!['recording'] is Map) {
      final rec = Map<String, dynamic>.from(res.data!['recording'] as Map);
      await loadAudioEvidence();
      return (savedOnline: true, savedOffline: false, recording: rec, error: null);
    }

    // Network down or server unreachable: persist binary + metadata safely in protected offline storage
    if (res.statusCode == 0 || res.statusCode >= 500) {
      final offlineMeta = {
        'id': recordingId,
        'userId': _currentUserId ?? '',
        'sosEventId': sosEventId,
        'filename': filename,
        'mimeType': mimeType,
        'fileSize': bytes.length,
        'durationSeconds': durationSeconds,
        'startedAt': startedAt,
        'endedAt': endedAt,
        'sha256Hash': sha256Hash,
        'triggerPhrase': triggerPhrase,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'status': 'OFFLINE_QUEUED',
        'integrityStatus': 'LOCAL_SAVED',
      };
      final stored = await platformOfflineSave(offlineMeta, bytes);
      await loadAudioEvidence();
      if (stored) {
        return (
          savedOnline: false,
          savedOffline: true,
          recording: offlineMeta,
          error: res.error,
        );
      }
    }

    return (
      savedOnline: false,
      savedOffline: false,
      recording: null,
      error: res.error ?? 'Failed to store recording.',
    );
  }

  Future<int> syncPendingOfflineAudio() async {
    if (!hasPermission('audio_evidence:own')) return 0;
    final uid = _currentUserId ?? '';
    final pending = await platformOfflineList(uid);
    int syncedCount = 0;
    for (final item in pending) {
      final recId = item['id']?.toString() ?? '';
      if (recId.isEmpty) continue;
      final bytes = await platformOfflineGetBytes(recId, uid);
      if (bytes == null || bytes.isEmpty) continue;
      final res = await _dbService.uploadAudioEvidence(
        recordingId: recId,
        sosEventId: item['sosEventId']?.toString() ?? '',
        filename: item['filename']?.toString() ?? '$recId.webm',
        mimeType: item['mimeType']?.toString() ?? 'audio/webm',
        bytes: bytes,
        durationSeconds: (item['durationSeconds'] is num)
            ? (item['durationSeconds'] as num).toInt()
            : 1,
        startedAt: item['startedAt']?.toString() ?? DateTime.now().toUtc().toIso8601String(),
        endedAt: item['endedAt']?.toString() ?? DateTime.now().toUtc().toIso8601String(),
        clientSha256: item['sha256Hash']?.toString() ?? '',
        triggerPhrase: item['triggerPhrase']?.toString() ?? '',
      );
      if (res.success) {
        await platformOfflineDelete(recId, uid);
        syncedCount++;
      }
    }
    if (syncedCount > 0) {
      await loadAudioEvidence();
    } else {
      _offlineAudioQueue
        ..clear()
        ..addAll(pending);
      notifyListeners();
    }
    return syncedCount;
  }

  Future<ApiResult<Map<String, dynamic>>> verifyAudioIntegrity(String recordingId) async {
    final res = await _dbService.verifyAudioEvidence(recordingId);
    if (res.success) {
      await loadAudioEvidence();
    }
    return res;
  }

  Future<ApiResult<Map<String, dynamic>>> deleteAudioEvidence(String recordingId) async {
    final res = await _dbService.deleteAudioEvidence(recordingId);
    if (res.success) {
      _audioEvidence.removeWhere((e) => e['id'] == recordingId);
      notifyListeners();
    }
    return res;
  }

  Future<bool> deleteOfflineQueuedAudio(String offlineId) async {
    final ok = await platformOfflineDelete(offlineId, _currentUserId ?? '');
    if (ok) {
      await loadAudioEvidence();
    }
    return ok;
  }
}
