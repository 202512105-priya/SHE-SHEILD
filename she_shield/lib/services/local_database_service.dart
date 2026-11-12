import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'local_http_stub.dart'
    if (dart.library.io) 'local_http_io.dart'
    if (dart.library.js_interop) 'local_http_web.dart';

class ApiResult<T> {
  final bool success;
  final int statusCode;
  final String? error;
  final T? data;

  const ApiResult({
    required this.success,
    required this.statusCode,
    this.error,
    this.data,
  });
}

class LocalDatabaseService {
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._internal() {
    _authToken = loadSessionTokenStorage();
    final savedHost = loadServerHostStorage();
    if (savedHost != null && savedHost.isNotEmpty) {
      customServerHost = savedHost;
    }
  }

  Future<void> hydratePersistedSettings() async {
    final saved = await initPersistentStorage();
    if (_authToken == null || _authToken!.isEmpty) {
      _authToken = saved.authToken;
    }
    if (customServerHost.isEmpty && saved.serverHost != null && saved.serverHost!.isNotEmpty) {
      customServerHost = saved.serverHost!;
    }
  }

  static const String defaultLanHost = '172.24.75.79:8080';

  bool _isConnected = false;
  String _activeServerUrl = '';
  String _lastError = '';
  String? _authToken;
  static String customServerHost = '';

  VoidCallback? onUnauthorized;

  bool get isConnected => _isConnected;
  String get activeServerUrl => _activeServerUrl;
  String get lastError => _lastError;
  String? get authToken => _authToken;

  void setAuthToken(String? token) {
    _authToken = (token == null || token.trim().isEmpty) ? null : token.trim();
    saveSessionTokenStorage(_authToken);
  }

  String _normalizeBaseUrl(String raw) {
    var h = raw.trim().replaceAll(RegExp(r'/+$'), '');
    if (h.isEmpty) return '';
    if (!h.startsWith('http://') && !h.startsWith('https://')) {
      h = 'http://$h';
    }
    final parsed = Uri.tryParse(h);
    if (parsed != null && parsed.host.isNotEmpty && !parsed.hasPort) {
      final port = parsed.scheme == 'https' ? 443 : 8080;
      return '${parsed.scheme}://${parsed.host}:$port';
    }
    return h;
  }

  /// List of candidate server URLs to discover the local SQLite server
  List<String> get candidateUrls {
    final list = <String>[];
    final custom = _normalizeBaseUrl(customServerHost);
    if (custom.isNotEmpty) {
      list.add(custom);
      return list;
    }

    if (kIsWeb) {
      final origin = Uri.base.origin;
      final isHttpsRemote = Uri.base.scheme == 'https' &&
          Uri.base.host != 'localhost' &&
          Uri.base.host != '127.0.0.1';
      if ((Uri.base.scheme == 'http' || Uri.base.scheme == 'https') &&
          origin.isNotEmpty) {
        list.add(origin);
      }
      if (!isHttpsRemote) {
        final webHost = getWebOriginHost();
        if (webHost != null && webHost.isNotEmpty) {
          final localOrigin = 'http://$webHost:8080';
          if (!list.contains(localOrigin)) {
            list.add(localOrigin);
          }
        }
        if (!list.contains('http://localhost:8080')) {
          list.add('http://localhost:8080');
        }
        if (!list.contains('http://127.0.0.1:8080')) {
          list.add('http://127.0.0.1:8080');
        }
      }
      return list;
    }

    // 1. Android Emulator loopback to host Mac
    list.add('http://10.0.2.2:8080');
    // 2. Localhost (when using 'adb reverse tcp:8080 tcp:8080')
    list.add('http://127.0.0.1:8080');
    list.add('http://localhost:8080');
    // 3. Primary LAN Wi-Fi IP of host Mac (for physical Android devices on Wi-Fi)
    list.add('http://$defaultLanHost');
    return list;
  }

  void setCustomServerHost(String host) {
    customServerHost = host.trim();
    saveServerHostStorage(customServerHost);
    _isConnected = false;
    _activeServerUrl = '';
    _lastError = '';
  }

  Future<bool> _probeUrl(String baseUrl) async {
    try {
      debugPrint('[LocalDB] Probing local SQLite server at $baseUrl/health...');
      final res = await platformHttpRequest(
        method: 'GET',
        url: '$baseUrl/health',
        timeout: const Duration(milliseconds: 6500),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['status'] == 'ok') {
          debugPrint('[LocalDB] Health OK at $baseUrl (${data['database']})');
          return true;
        }
      }
    } catch (e) {
      _lastError = '$baseUrl -> $e';
      debugPrint('[LocalDB] Probe failed for $baseUrl: $e');
    }
    return false;
  }

  Future<bool> connect({bool forceReprobe = false}) async {
    if (!forceReprobe && _isConnected && _activeServerUrl.isNotEmpty) {
      return true;
    }

    final candidates = candidateUrls;
    if (candidates.isEmpty) {
      _isConnected = false;
      _activeServerUrl = '';
      return false;
    }

    if (candidates.length == 1) {
      final ok = await _probeUrl(candidates.first);
      _isConnected = ok;
      _activeServerUrl = ok ? candidates.first : '';
      return ok;
    }

    final completer = Completer<String?>();
    var remaining = candidates.length;

    for (final baseUrl in candidates) {
      _probeUrl(baseUrl).then((ok) {
        if (ok && !completer.isCompleted) {
          completer.complete(baseUrl);
        } else {
          remaining--;
          if (remaining == 0 && !completer.isCompleted) {
            completer.complete(null);
          }
        }
      });
    }

    final winningUrl = await completer.future;
    if (winningUrl != null) {
      _activeServerUrl = winningUrl;
      _isConnected = true;
      debugPrint('[LocalDB] Connected to Local SQLite Server at $_activeServerUrl');
      return true;
    }

    _isConnected = false;
    _activeServerUrl = '';
    return false;
  }

  Map<String, String> _authHeaders({bool requireAuth = true}) {
    final headers = <String, String>{};
    if (requireAuth && _authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  String _extractError(String body, int statusCode) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['error'] != null) {
        return decoded['error'].toString();
      }
    } catch (_) {}
    return 'Request failed (HTTP $statusCode)';
  }

  Future<ApiResult<dynamic>> _requestJson({
    required String method,
    required String endpoint,
    Map<String, dynamic>? payload,
    bool requireAuth = true,
    Duration timeout = const Duration(seconds: 6),
  }) async {
    if (!await connect()) {
      return const ApiResult(
        success: false,
        statusCode: 0,
        error: 'Unable to reach Local SQLite Server. Check connection settings.',
      );
    }
    try {
      final res = await platformHttpRequest(
        method: method,
        url: '$_activeServerUrl$endpoint',
        headers: _authHeaders(requireAuth: requireAuth),
        jsonBody: payload != null ? jsonEncode(payload) : null,
        timeout: timeout,
      );
      dynamic parsed;
      if (res.body.isNotEmpty) {
        try {
          parsed = jsonDecode(res.body);
        } catch (_) {}
      }
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return ApiResult(success: true, statusCode: res.statusCode, data: parsed);
      }
      if (requireAuth && res.statusCode == 401) {
        setAuthToken(null);
        onUnauthorized?.call();
      }
      return ApiResult(
        success: false,
        statusCode: res.statusCode,
        error: _extractError(res.body, res.statusCode),
        data: parsed,
      );
    } catch (e) {
      debugPrint('[LocalDB] $method $endpoint failed: $e');
      _lastError = e.toString();
      _isConnected = false;
      return ApiResult(
        success: false,
        statusCode: 0,
        error: 'Network error communicating with Local SQLite Server.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // AUTHENTICATION & SESSION APIS
  // ---------------------------------------------------------------------------

  Future<ApiResult<Map<String, dynamic>>> registerUser({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    String accountType = 'registered_user',
    String? aadhaarNumber,
    String? inviteToken,
    String? shareToken,
  }) async {
    final res = await _requestJson(
      method: 'POST',
      endpoint: '/api/auth/register',
      requireAuth: false,
      payload: {
        'fullName': fullName.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'password': password,
        'accountType': accountType,
        if (aadhaarNumber != null && aadhaarNumber.trim().isNotEmpty) 'aadhaarNumber': aadhaarNumber.trim(),
        if (inviteToken != null && inviteToken.trim().isNotEmpty) 'inviteToken': inviteToken.trim(),
        if (shareToken != null && shareToken.trim().isNotEmpty) 'shareToken': shareToken.trim(),
      },
    );
    if (res.success && res.data is Map) {
      final map = Map<String, dynamic>.from(res.data as Map);
      final token = map['token']?.toString();
      if (token != null && token.isNotEmpty) {
        setAuthToken(token);
      }
      return ApiResult(success: true, statusCode: res.statusCode, data: map);
    }
    return ApiResult(success: false, statusCode: res.statusCode, error: res.error);
  }

  Future<ApiResult<Map<String, dynamic>>> loginWithCredentials({
    required String email,
    required String password,
  }) async {
    final res = await _requestJson(
      method: 'POST',
      endpoint: '/api/auth/login',
      requireAuth: false,
      payload: {
        'email': email.trim(),
        'password': password,
      },
    );
    if (res.success && res.data is Map) {
      final map = Map<String, dynamic>.from(res.data as Map);
      final token = map['token']?.toString();
      if (token != null && token.isNotEmpty) {
        setAuthToken(token);
      }
      return ApiResult(success: true, statusCode: res.statusCode, data: map);
    }
    return ApiResult(success: false, statusCode: res.statusCode, error: res.error);
  }

  Future<ApiResult<Map<String, dynamic>>> fetchCurrentUser() async {
    if (_authToken == null || _authToken!.isEmpty) {
      return const ApiResult(success: false, statusCode: 401, error: 'Not authenticated.');
    }
    final res = await _requestJson(method: 'GET', endpoint: '/api/auth/me');
    if (res.success && res.data is Map) {
      return ApiResult(
        success: true,
        statusCode: res.statusCode,
        data: Map<String, dynamic>.from(res.data as Map),
      );
    }
    return ApiResult(success: false, statusCode: res.statusCode, error: res.error);
  }

  Future<ApiResult<Map<String, dynamic>>> updateUserProfile({
    required String fullName,
    required String phone,
  }) {
    return _requestMap(
      method: 'POST',
      endpoint: '/api/auth/profile',
      payload: {'fullName': fullName.trim(), 'phone': phone.trim()},
    );
  }

  Future<bool> logout() async {
    try {
      if (_authToken != null && _authToken!.isNotEmpty) {
        await _requestJson(method: 'POST', endpoint: '/api/auth/logout', payload: {});
      }
    } finally {
      setAuthToken(null);
    }
    return true;
  }

  // ---------------------------------------------------------------------------
  // ADMIN USER & RBAC MANAGEMENT APIS
  // ---------------------------------------------------------------------------

  Future<ApiResult<List<Map<String, dynamic>>>> adminListUsers({String query = ''}) async {
    final encoded = query.trim().isNotEmpty ? '?q=${Uri.encodeQueryComponent(query.trim())}' : '';
    final res = await _requestJson(method: 'GET', endpoint: '/api/admin/users$encoded');
    if (res.success && res.data is List) {
      final list = (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      return ApiResult(success: true, statusCode: res.statusCode, data: list);
    }
    return ApiResult(success: false, statusCode: res.statusCode, error: res.error);
  }

  Future<ApiResult<List<Map<String, dynamic>>>> adminListRoles() async {
    final res = await _requestJson(method: 'GET', endpoint: '/api/admin/roles');
    if (res.success && res.data is List) {
      final list = (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      return ApiResult(success: true, statusCode: res.statusCode, data: list);
    }
    return ApiResult(success: false, statusCode: res.statusCode, error: res.error);
  }

  Future<ApiResult<Map<String, dynamic>>> adminCreateOfficer({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    String badgeId = '',
    String station = '',
  }) async {
    final res = await _requestJson(
      method: 'POST',
      endpoint: '/api/admin/users/create_officer',
      payload: {
        'fullName': fullName.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'password': password,
        'badgeId': badgeId.trim(),
        'station': station.trim(),
      },
    );
    if (res.success && res.data is Map) {
      return ApiResult(
        success: true,
        statusCode: res.statusCode,
        data: Map<String, dynamic>.from(res.data as Map),
      );
    }
    return ApiResult(success: false, statusCode: res.statusCode, error: res.error);
  }

  Future<ApiResult<Map<String, dynamic>>> adminAssignRole({
    required String userId,
    required String roleId,
  }) async {
    final res = await _requestJson(
      method: 'POST',
      endpoint: '/api/admin/users/assign_role',
      payload: {'userId': userId, 'roleId': roleId},
    );
    if (res.success && res.data is Map) {
      return ApiResult(
        success: true,
        statusCode: res.statusCode,
        data: Map<String, dynamic>.from(res.data as Map),
      );
    }
    return ApiResult(success: false, statusCode: res.statusCode, error: res.error);
  }

  Future<ApiResult<Map<String, dynamic>>> adminUpdateAccountStatus({
    required String userId,
    required String accountStatus,
  }) async {
    final res = await _requestJson(
      method: 'POST',
      endpoint: '/api/admin/users/update_status',
      payload: {'userId': userId, 'accountStatus': accountStatus},
    );
    if (res.success && res.data is Map) {
      return ApiResult(
        success: true,
        statusCode: res.statusCode,
        data: Map<String, dynamic>.from(res.data as Map),
      );
    }
    return ApiResult(success: false, statusCode: res.statusCode, error: res.error);
  }

  Future<ApiResult<List<Map<String, dynamic>>>> adminFetchAuditLogs() async {
    final res = await _requestJson(method: 'GET', endpoint: '/api/admin/audit_logs');
    if (res.success && res.data is List) {
      final list = (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      return ApiResult(success: true, statusCode: res.statusCode, data: list);
    }
    return ApiResult(success: false, statusCode: res.statusCode, error: res.error);
  }

  // ---------------------------------------------------------------------------
  // PROTECTED DOMAIN DATA APIS
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>?> getSosCases() async {
    final res = await _requestJson(method: 'GET', endpoint: '/api/sos_cases');
    if (res.success && res.data is List) {
      return (res.data as List).map((item) => Map<String, dynamic>.from(item as Map)).toList();
    }
    return null;
  }

  Future<bool> addSosCase({
    required String id,
    required String userName,
    required String userPhone,
    required String priority,
    required String status,
    required String gps,
    required String deviceType,
    required String locationName,
    String userEmail = '',
    int age = 22,
    String bloodGroup = 'O+',
    int evidenceCount = 1,
  }) async {
    final res = await _requestJson(
      method: 'POST',
      endpoint: '/api/sos_cases',
      payload: {
        'id': id,
        'userName': userName,
        'userEmail': userEmail,
        'userPhone': userPhone,
        'age': age,
        'bloodGroup': bloodGroup,
        'priority': priority,
        'status': status.toLowerCase(),
        'gps': gps,
        'timestamp': DateTime.now().toIso8601String(),
        'deviceType': deviceType,
        'evidenceCount': evidenceCount,
        'locationName': locationName,
      },
    );
    return res.success;
  }

  Future<bool> updateCaseStatus(String caseId, String newStatus) async {
    final res = await _requestJson(
      method: 'POST',
      endpoint: '/api/sos_cases/update_status',
      payload: {'id': caseId, 'status': newStatus.toLowerCase()},
    );
    return res.success;
  }

  Future<List<Map<String, dynamic>>?> getCyberComplaints() async {
    final res = await _requestJson(method: 'GET', endpoint: '/api/cyber_complaints');
    if (res.success && res.data is List) {
      return (res.data as List).map((item) => Map<String, dynamic>.from(item as Map)).toList();
    }
    return null;
  }

  Future<bool> addCyberComplaint({
    required String id,
    required String category,
    required String description,
    required String threatScore,
    required String status,
    required String userName,
    required String userPhone,
    String? offenderLink,
    String? attachedEvidence,
    int evidenceCount = 1,
  }) async {
    final res = await _requestJson(
      method: 'POST',
      endpoint: '/api/cyber_complaints',
      payload: {
        'id': id,
        'category': category,
        'description': description,
        'threatScore': threatScore,
        'status': status,
        'timestamp': DateTime.now().toIso8601String(),
        'userName': userName,
        'userPhone': userPhone,
        'offenderLink': offenderLink ?? '',
        'evidenceCount': evidenceCount,
        'attachedEvidence': attachedEvidence ?? '',
      },
    );
    return res.success;
  }

  Future<bool> updateCyberComplaintStatus(String complaintId, String newStatus) async {
    final res = await _requestJson(
      method: 'POST',
      endpoint: '/api/cyber_complaints/update_status',
      payload: {'id': complaintId, 'status': newStatus.toUpperCase()},
    );
    return res.success;
  }

  Future<List<Map<String, dynamic>>?> getVaultAssets() async {
    final res = await _requestJson(method: 'GET', endpoint: '/api/vault_assets');
    if (res.success && res.data is List) {
      return (res.data as List).map((item) => Map<String, dynamic>.from(item as Map)).toList();
    }
    return null;
  }

  Future<bool> addVaultAsset({
    required String id,
    required String name,
    required String fileType,
    required String hashSha256,
    required String tamperCheck,
    required String status,
    required String sizeMb,
    required String chainOfCustody,
  }) async {
    final res = await _requestJson(
      method: 'POST',
      endpoint: '/api/vault_assets',
      payload: {
        'id': id,
        'name': name,
        'fileType': fileType,
        'hash': hashSha256,
        'tamperCheck': tamperCheck,
        'status': status,
        'timestamp': DateTime.now().toIso8601String(),
        'sizeMb': sizeMb,
        'chainOfCustody': chainOfCustody,
      },
    );
    return res.success;
  }

  Future<List<Map<String, dynamic>>?> getGuardians() async {
    final res = await _requestJson(method: 'GET', endpoint: '/api/guardians');
    if (res.success && res.data is List) {
      return (res.data as List).map((item) => Map<String, dynamic>.from(item as Map)).toList();
    }
    return null;
  }

  Future<bool> addGuardian({
    required String id,
    required String wardName,
    required String guardianName,
    required String email,
    required String phone,
    required String relation,
    String status = 'PENDING',
  }) async {
    final res = await _requestJson(
      method: 'POST',
      endpoint: '/api/guardians',
      payload: {
        'id': id,
        'wardName': wardName,
        'guardianName': guardianName,
        'email': email,
        'phone': phone,
        'relation': relation,
        'status': status,
      },
    );
    return res.success;
  }

  Future<List<Map<String, dynamic>>?> getCabTrips() async {
    final res = await _requestJson(method: 'GET', endpoint: '/api/cab_trips');
    if (res.success && res.data is List) {
      return (res.data as List).map((item) => Map<String, dynamic>.from(item as Map)).toList();
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // WOMEN ROLE: VOICE SOS SETTINGS & AUDIO EVIDENCE APIS
  // ---------------------------------------------------------------------------

  Future<ApiResult<Map<String, dynamic>>> getVoiceSettings() async {
    final res = await _requestJson(method: 'GET', endpoint: '/api/user/voice_settings');
    if (res.success && res.data is Map) {
      return ApiResult(
        success: true,
        statusCode: res.statusCode,
        data: Map<String, dynamic>.from(res.data as Map),
      );
    }
    return ApiResult(success: false, statusCode: res.statusCode, error: res.error);
  }

  Future<ApiResult<Map<String, dynamic>>> saveVoiceSettings({
    required String voicePhrase,
    required String language,
    required bool voiceSosEnabled,
    required int maxDurationSeconds,
    required bool silentSosMode,
  }) async {
    final res = await _requestJson(
      method: 'POST',
      endpoint: '/api/user/voice_settings',
      payload: {
        'voicePhrase': voicePhrase.trim(),
        'language': language,
        'voiceSosEnabled': voiceSosEnabled,
        'maxDurationSeconds': maxDurationSeconds,
        'silentSosMode': silentSosMode,
      },
    );
    if (res.success && res.data is Map) {
      return ApiResult(
        success: true,
        statusCode: res.statusCode,
        data: Map<String, dynamic>.from(res.data as Map),
      );
    }
    return ApiResult(success: false, statusCode: res.statusCode, error: res.error);
  }

  Future<ApiResult<List<Map<String, dynamic>>>> getAudioEvidence() async {
    final res = await _requestJson(method: 'GET', endpoint: '/api/audio_evidence');
    if (res.success && res.data is List) {
      final list = (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      return ApiResult(success: true, statusCode: res.statusCode, data: list);
    }
    return ApiResult(success: false, statusCode: res.statusCode, error: res.error);
  }

  Future<ApiResult<Map<String, dynamic>>> uploadAudioEvidence({
    required String recordingId,
    required String sosEventId,
    required String filename,
    required String mimeType,
    required Uint8List bytes,
    required int durationSeconds,
    required String startedAt,
    required String endedAt,
    required String clientSha256,
    String triggerPhrase = '',
    String gps = '23.0225, 72.5714',
    String locationName = 'Live Protected Zone',
  }) async {
    if (!await connect()) {
      return const ApiResult(
        success: false,
        statusCode: 0,
        error: 'Offline: Local SQLite Server unreachable.',
      );
    }
    try {
      final metaHeader = jsonEncode({
        'recordingId': recordingId,
        'sosEventId': sosEventId,
        'filename': filename,
        'mimeType': mimeType,
        'durationSeconds': durationSeconds,
        'startedAt': startedAt,
        'endedAt': endedAt,
        'clientSha256': clientSha256,
        'triggerPhrase': triggerPhrase,
        'gps': gps,
        'locationName': locationName,
      });

      final headers = <String, String>{
        'Content-Type': mimeType,
        'X-Evidence-Meta': metaHeader,
        if (_authToken != null && _authToken!.isNotEmpty) 'Authorization': 'Bearer $_authToken',
      };

      final res = await platformUploadBinary(
        url: '$_activeServerUrl/api/audio_evidence',
        bytes: bytes,
        headers: headers,
      );

      dynamic parsed;
      if (res.body.isNotEmpty) {
        try {
          parsed = jsonDecode(res.body);
        } catch (_) {}
      }

      if (res.statusCode >= 200 && res.statusCode < 300 && parsed is Map) {
        return ApiResult(
          success: true,
          statusCode: res.statusCode,
          data: Map<String, dynamic>.from(parsed),
        );
      }
      if (res.statusCode == 401) {
        setAuthToken(null);
        onUnauthorized?.call();
      }
      return ApiResult(
        success: false,
        statusCode: res.statusCode,
        error: _extractError(res.body, res.statusCode),
      );
    } catch (e) {
      debugPrint('[LocalDB] Audio upload failed: $e');
      _isConnected = false;
      return const ApiResult(
        success: false,
        statusCode: 0,
        error: 'Network error uploading audio recording.',
      );
    }
  }

  Future<ApiResult<Map<String, dynamic>>> verifyAudioEvidence(String recordingId) async {
    final res = await _requestJson(
      method: 'POST',
      endpoint: '/api/audio_evidence/$recordingId/verify',
      payload: {},
    );
    if (res.success && res.data is Map) {
      return ApiResult(
        success: true,
        statusCode: res.statusCode,
        data: Map<String, dynamic>.from(res.data as Map),
      );
    }
    return ApiResult(success: false, statusCode: res.statusCode, error: res.error);
  }

  Future<ApiResult<Map<String, dynamic>>> deleteAudioEvidence(String recordingId) async {
    final res = await _requestJson(
      method: 'POST',
      endpoint: '/api/audio_evidence/$recordingId/delete',
      payload: {},
    );
    if (res.success && res.data is Map) {
      return ApiResult(
        success: true,
        statusCode: res.statusCode,
        data: Map<String, dynamic>.from(res.data as Map),
      );
    }
    return ApiResult(success: false, statusCode: res.statusCode, error: res.error);
  }

  String audioStreamUrl(String recordingId) => '$_activeServerUrl/api/audio_evidence/$recordingId/stream';
  String audioDownloadUrl(String recordingId) => '$_activeServerUrl/api/audio_evidence/$recordingId/download';

  // ---------------------------------------------------------------------------
  // SAFE ARRIVAL TRAVEL MODE & GEOLOCATION PROXY APIS
  // ---------------------------------------------------------------------------

  Future<ApiResult<Map<String, dynamic>>> _requestMap({
    required String method,
    required String endpoint,
    Map<String, dynamic>? payload,
    bool requireAuth = true,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final res = await _requestJson(
      method: method,
      endpoint: endpoint,
      payload: payload,
      requireAuth: requireAuth,
      timeout: timeout,
    );
    final mapData = res.data is Map ? Map<String, dynamic>.from(res.data as Map) : null;
    if (res.success && mapData != null) {
      return ApiResult(success: true, statusCode: res.statusCode, data: mapData);
    }
    return ApiResult(
      success: false,
      statusCode: res.statusCode,
      error: res.error ?? 'Unexpected server response.',
      data: mapData,
    );
  }

  Future<ApiResult<Map<String, dynamic>>> searchPlaces({
    required String query,
    double? lat,
    double? lng,
  }) {
    final params = <String, String>{'q': query.trim()};
    if (lat != null && lng != null) {
      params['lat'] = lat.toStringAsFixed(6);
      params['lng'] = lng.toStringAsFixed(6);
    }
    final qs = Uri(queryParameters: params).query;
    return _requestMap(
      method: 'GET',
      endpoint: '/api/geo/search?$qs',
      timeout: const Duration(seconds: 12),
    );
  }

  Future<ApiResult<Map<String, dynamic>>> computeRoutes({
    required double startLat,
    required double startLng,
    required double destLat,
    required double destLng,
    String mode = 'driving',
  }) {
    final qs = Uri(
      queryParameters: {
        'startLat': startLat.toStringAsFixed(6),
        'startLng': startLng.toStringAsFixed(6),
        'destLat': destLat.toStringAsFixed(6),
        'destLng': destLng.toStringAsFixed(6),
        'mode': mode,
      },
    ).query;
    return _requestMap(
      method: 'GET',
      endpoint: '/api/geo/route?$qs',
      timeout: const Duration(seconds: 14),
    );
  }

  Future<ApiResult<Map<String, dynamic>>> startJourney(Map<String, dynamic> payload) {
    return _requestMap(method: 'POST', endpoint: '/api/journeys/start', payload: payload);
  }

  Future<ApiResult<Map<String, dynamic>>> getActiveJourney() {
    return _requestMap(method: 'GET', endpoint: '/api/journeys/active');
  }

  Future<ApiResult<Map<String, dynamic>>> postJourneyLocations({
    required String journeyId,
    required List<Map<String, dynamic>> points,
  }) {
    return _requestMap(
      method: 'POST',
      endpoint: '/api/journeys/location',
      payload: {'journeyId': journeyId, 'points': points},
    );
  }

  Future<ApiResult<Map<String, dynamic>>> shareJourney(Map<String, dynamic> payload) {
    return _requestMap(
      method: 'POST',
      endpoint: '/api/journeys/share',
      payload: payload,
      timeout: const Duration(seconds: 12),
    );
  }

  Future<ApiResult<Map<String, dynamic>>> revokeJourneyShare(String shareId) {
    return _requestMap(
      method: 'POST',
      endpoint: '/api/journeys/share/$shareId/revoke',
      payload: {},
    );
  }

  Future<ApiResult<Map<String, dynamic>>> fetchSharedJourneyByToken(String rawToken) {
    return _requestMap(
      method: 'GET',
      endpoint: '/api/journeys/share/$rawToken',
      requireAuth: false,
      timeout: const Duration(seconds: 10),
    );
  }

  Future<ApiResult<Map<String, dynamic>>> extendJourneyEta({
    required String journeyId,
    required int additionalMinutes,
  }) {
    return _requestMap(
      method: 'POST',
      endpoint: '/api/journeys/extend-eta',
      payload: {'journeyId': journeyId, 'additionalMinutes': additionalMinutes},
    );
  }

  Future<ApiResult<Map<String, dynamic>>> completeJourney({
    required String journeyId,
    double? latitude,
    double? longitude,
    double? accuracy,
  }) {
    return _requestMap(
      method: 'POST',
      endpoint: '/api/journeys/complete',
      payload: {
        'journeyId': journeyId,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (accuracy != null) 'accuracy': accuracy,
      },
    );
  }

  Future<ApiResult<Map<String, dynamic>>> triggerJourneySos({
    required String journeyId,
    double? latitude,
    double? longitude,
    double? accuracy,
    String? message,
  }) {
    return _requestMap(
      method: 'POST',
      endpoint: '/api/journeys/sos',
      payload: {
        'journeyId': journeyId,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (accuracy != null) 'accuracy': accuracy,
        if (message != null) 'message': message,
      },
      timeout: const Duration(seconds: 12),
    );
  }

  Future<ApiResult<List<Map<String, dynamic>>>> getJourneyHistory() async {
    final res = await _requestJson(method: 'GET', endpoint: '/api/journeys/history');
    if (res.success && res.data is List) {
      return ApiResult(
        success: true,
        statusCode: res.statusCode,
        data: (res.data as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList(),
      );
    }
    return ApiResult(success: false, statusCode: res.statusCode, error: res.error);
  }

  // ---------------------------------------------------------------------------
  // GUARDIAN PORTAL, CONNECTIONS & INVITATION APIS
  // ---------------------------------------------------------------------------

  Future<ApiResult<Map<String, dynamic>>> getGuardianNetwork() {
    return _requestMap(method: 'GET', endpoint: '/api/guardians/network');
  }

  Future<ApiResult<Map<String, dynamic>>> requestGuardianConnection({
    String email = '',
    String phone = '',
    String guardianName = '',
    String relationship = 'Guardian',
  }) {
    return _requestMap(
      method: 'POST',
      endpoint: '/api/guardians/request',
      payload: {
        'email': email.trim(),
        'phone': phone.trim(),
        'guardianName': guardianName.trim(),
        'relationship': relationship.trim(),
      },
    );
  }

  Future<ApiResult<Map<String, dynamic>>> revokeGuardianConnection(String connectionId) {
    return _requestMap(
      method: 'POST',
      endpoint: '/api/guardians/connections/$connectionId/revoke',
      payload: {},
    );
  }

  Future<ApiResult<Map<String, dynamic>>> getGuardianDashboard() {
    return _requestMap(
      method: 'GET',
      endpoint: '/api/guardian/dashboard',
      timeout: const Duration(seconds: 10),
    );
  }

  Future<ApiResult<Map<String, dynamic>>> getGuardianJourneyDetail(String journeyId) {
    return _requestMap(
      method: 'GET',
      endpoint: '/api/guardian/journeys/$journeyId',
      timeout: const Duration(seconds: 10),
    );
  }

  Future<ApiResult<Map<String, dynamic>>> respondGuardianInvitation({
    required String itemId,
    required String action,
    required String inviteKind,
  }) {
    return _requestMap(
      method: 'POST',
      endpoint: '/api/guardian/invitations/$itemId/respond',
      payload: {'action': action, 'inviteKind': inviteKind},
    );
  }

  Future<ApiResult<Map<String, dynamic>>> claimGuardianShare(String rawToken) {
    return _requestMap(
      method: 'POST',
      endpoint: '/api/guardian/shares/claim',
      payload: {'token': rawToken.trim()},
    );
  }

  Future<ApiResult<Map<String, dynamic>>> markGuardianNotificationsRead() {
    return _requestMap(
      method: 'POST',
      endpoint: '/api/guardian/notifications/mark-read',
      payload: {},
    );
  }
}
