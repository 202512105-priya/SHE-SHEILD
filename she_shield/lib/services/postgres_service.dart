import 'package:flutter/foundation.dart';
import 'package:postgres/postgres.dart';

class PostgresService {
  static final PostgresService _instance = PostgresService._internal();
  factory PostgresService() => _instance;
  PostgresService._internal();

  Connection? _connection;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  /// Render Cloud Database URL (Disconnected per user request)
  static String renderDbUrl = "";

  void setRenderDbUrl(String url) {
    renderDbUrl = url.trim();
    _isConnected = false;
    _connection = null;
  }

  /// Attempts to establish a connection to the PostgreSQL database.
  /// 1. Tries Render Cloud PostgreSQL first (if renderDbUrl is provided).
  /// 2. Falls back to local/emulator host candidates (10.0.2.2:5433, localhost:5433).
  Future<bool> connect() async {
    if (_isConnected && _connection != null) {
      return true;
    }

    // 1. Try Render Cloud PostgreSQL if configured
    if (renderDbUrl.isNotEmpty) {
      try {
        final uri = Uri.parse(renderDbUrl);
        final host = uri.host;
        final port = uri.hasPort ? uri.port : 5432;
        final dbName = uri.path.replaceAll('/', '');
        final userInfo = uri.userInfo.split(':');
        final user = userInfo.isNotEmpty ? userInfo[0] : '';
        final pass = userInfo.length > 1 ? userInfo[1] : '';

        debugPrint('[PostgreSQL Cloud] Attempting Render connection to $host:$port/$dbName...');
        _connection = await Connection.open(
          Endpoint(
            host: host,
            port: port,
            database: dbName,
            username: user,
            password: pass.isNotEmpty ? pass : null,
          ),
          settings: const ConnectionSettings(
            sslMode: SslMode.require,
            connectTimeout: Duration(seconds: 8),
          ),
        );
        _isConnected = true;
        debugPrint('[PostgreSQL Cloud] Connected successfully to Render database ($host)!');
        return true;
      } catch (e) {
        debugPrint('[PostgreSQL Cloud] Render connection failed: $e. Falling back to local...');
      }
    }

    // 2. Fallback to Local Host Candidates (for emulator or adb reverse)
    final List<String> hostCandidates = ['10.0.2.2', '127.0.0.1', 'localhost'];

    for (final host in hostCandidates) {
      try {
        debugPrint('[PostgreSQL Local] Attempting connection to $host:5433/she_shield...');
        _connection = await Connection.open(
          Endpoint(
            host: host,
            port: 5433,
            database: 'she_shield',
            username: 'priyashah',
          ),
          settings: const ConnectionSettings(
            sslMode: SslMode.disable,
            connectTimeout: Duration(seconds: 3),
          ),
        );
        _isConnected = true;
        debugPrint('[PostgreSQL Local] Connected successfully to $host:5433/she_shield!');
        return true;
      } catch (e) {
        debugPrint('[PostgreSQL Local] Connection failed to $host: $e');
      }
    }

    _isConnected = false;
    return false;
  }

  /// Fetch all real SOS Emergency Cases from PostgreSQL
  Future<List<Map<String, dynamic>>> getSosCases() async {
    try {
      if (!await connect()) return [];
      final result = await _connection!.execute(
        'SELECT id, user_name, user_email, user_phone, age, blood_group, priority, status, gps, timestamp, device_type, evidence_count, location_name FROM sos_cases ORDER BY timestamp DESC;'
      );

      final List<Map<String, dynamic>> cases = [];
      for (final row in result) {
        cases.add({
          'id': row[0]?.toString() ?? '',
          'userName': row[1]?.toString() ?? '',
          'userEmail': row[2]?.toString() ?? '',
          'userPhone': row[3]?.toString() ?? '',
          'age': row[4] is int ? row[4] : int.tryParse(row[4]?.toString() ?? '24') ?? 24,
          'bloodGroup': row[5]?.toString() ?? 'O+',
          'priority': row[6]?.toString() ?? 'CRITICAL',
          'status': row[7]?.toString() ?? 'open',
          'gps': row[8]?.toString() ?? '23.0312, 72.5801',
          'timestamp': row[9]?.toString() ?? DateTime.now().toIso8601String(),
          'deviceType': row[10]?.toString() ?? 'Smart Watch Relay',
          'evidenceCount': row[11] is int ? row[11] : int.tryParse(row[11]?.toString() ?? '1') ?? 1,
          'locationName': row[12]?.toString() ?? 'Ahmedabad Safe Zone',
        });
      }
      return cases;
    } catch (e) {
      debugPrint('[PostgreSQL] Error fetching SOS cases: $e');
      return [];
    }
  }

  /// Insert new SOS Case into PostgreSQL
  Future<bool> addSosCase({
    required String id,
    required String userName,
    required String userPhone,
    required String priority,
    required String status,
    required String gps,
    required String deviceType,
    required String locationName,
    String userEmail = 'ward@sheshield.org',
    int age = 22,
    String bloodGroup = 'O+',
    int evidenceCount = 1,
  }) async {
    try {
      if (!await connect()) return false;
      await _connection!.execute(
        Sql.named('''
          INSERT INTO sos_cases (id, user_name, user_email, user_phone, age, blood_group, priority, status, gps, timestamp, device_type, evidence_count, location_name)
          VALUES (@id, @name, @email, @phone, @age, @blood, @priority, @status, @gps, @ts, @device, @count, @loc);
        '''),
        parameters: {
          'id': id,
          'name': userName,
          'email': userEmail,
          'phone': userPhone,
          'age': age,
          'blood': bloodGroup,
          'priority': priority,
          'status': status.toLowerCase(),
          'gps': gps,
          'ts': DateTime.now().toIso8601String(),
          'device': deviceType,
          'count': evidenceCount,
          'loc': locationName,
        },
      );
      debugPrint('[PostgreSQL] Successfully added new SOS case $id to PostgreSQL');
      return true;
    } catch (e) {
      debugPrint('[PostgreSQL] Error adding SOS case: $e');
      return false;
    }
  }

  /// Update Case Status in PostgreSQL
  Future<bool> updateCaseStatus(String caseId, String newStatus) async {
    try {
      if (!await connect()) return false;
      await _connection!.execute(
        Sql.named('UPDATE sos_cases SET status = @status WHERE id = @id;'),
        parameters: {'status': newStatus.toLowerCase(), 'id': caseId},
      );
      debugPrint('[PostgreSQL] Updated status of case $caseId to $newStatus in PostgreSQL');
      return true;
    } catch (e) {
      debugPrint('[PostgreSQL] Error updating case status: $e');
      return false;
    }
  }

  /// Update Cyber Complaint Status in PostgreSQL
  Future<bool> updateCyberComplaintStatus(String complaintId, String newStatus) async {
    try {
      if (!await connect()) return false;
      await _connection!.execute(
        Sql.named('UPDATE cyber_complaints SET status = @status WHERE id = @id;'),
        parameters: {'status': newStatus.toUpperCase(), 'id': complaintId},
      );
      debugPrint('[PostgreSQL] Updated status of cyber complaint $complaintId to $newStatus in PostgreSQL');
      return true;
    } catch (e) {
      debugPrint('[PostgreSQL] Error updating cyber complaint status: $e');
      return false;
    }
  }

  /// Fetch all real Cyber Complaints from PostgreSQL
  Future<List<Map<String, dynamic>>> getCyberComplaints() async {
    try {
      if (!await connect()) return [];
      final result = await _connection!.execute(
        'SELECT id, category, description, threat_score, status, timestamp, user_name, user_phone, offender_link, evidence_count, attached_evidence FROM cyber_complaints ORDER BY timestamp DESC;'
      );

      final List<Map<String, dynamic>> complaints = [];
      for (final row in result) {
        complaints.add({
          'id': row[0]?.toString() ?? '',
          'category': row[1]?.toString() ?? 'BLACKMAIL',
          'description': row[2]?.toString() ?? '',
          'threatScore': row[3]?.toString() ?? '90%',
          'status': row[4]?.toString() ?? 'SUBMITTED',
          'timestamp': row[5]?.toString() ?? DateTime.now().toIso8601String(),
          'userName': row[6]?.toString() ?? 'Tisha Patel',
          'userPhone': row[7]?.toString() ?? '+91 98765 43210',
          'offenderLink': row[8]?.toString() ?? '',
          'evidenceCount': row[9] is int ? row[9] : int.tryParse(row[9]?.toString() ?? '1') ?? 1,
          'attachedEvidence': row[10]?.toString() ?? '',
        });
      }
      return complaints;
    } catch (e) {
      debugPrint('[PostgreSQL] Error fetching cyber complaints: $e');
      return [];
    }
  }

  /// Insert Cyber Complaint into PostgreSQL
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
    try {
      if (!await connect()) return false;
      await _connection!.execute(
        Sql.named('''
          INSERT INTO cyber_complaints (id, category, description, threat_score, status, timestamp, user_name, user_phone, offender_link, evidence_count, attached_evidence)
          VALUES (@id, @cat, @desc, @score, @status, @ts, @name, @phone, @link, @count, @evidence);
        '''),
        parameters: {
          'id': id,
          'cat': category,
          'desc': description,
          'score': threatScore,
          'status': status,
          'ts': DateTime.now().toIso8601String(),
          'name': userName,
          'phone': userPhone,
          'link': offenderLink ?? '',
          'count': evidenceCount,
          'evidence': attachedEvidence ?? '',
        },
      );
      return true;
    } catch (e) {
      debugPrint('[PostgreSQL] Error adding cyber complaint: $e');
      return false;
    }
  }

  /// Insert Vault Asset into PostgreSQL
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
    try {
      if (!await connect()) return false;
      await _connection!.execute(
        Sql.named('''
          INSERT INTO vault_assets (id, name, file_type, hash_sha256, tamper_check, status, timestamp, size_mb, chain_of_custody)
          VALUES (@id, @name, @type, @hash, @tamper, @status, @ts, @size, @custody);
        '''),
        parameters: {
          'id': id,
          'name': name,
          'type': fileType,
          'hash': hashSha256,
          'tamper': tamperCheck,
          'status': status,
          'ts': DateTime.now().toIso8601String(),
          'size': sizeMb,
          'custody': chainOfCustody,
        },
      );
      return true;
    } catch (e) {
      debugPrint('[PostgreSQL] Error inserting vault asset: $e');
      return false;
    }
  }

  /// Fetch all real Vault Assets from PostgreSQL
  Future<List<Map<String, dynamic>>> getVaultAssets() async {
    try {
      if (!await connect()) return [];
      final result = await _connection!.execute(
        'SELECT id, name, file_type, hash_sha256, tamper_check, status, timestamp, size_mb, chain_of_custody FROM vault_assets ORDER BY timestamp DESC;'
      );

      final List<Map<String, dynamic>> assets = [];
      for (final row in result) {
        assets.add({
          'id': row[0]?.toString() ?? '',
          'name': row[1]?.toString() ?? '',
          'fileType': row[2]?.toString() ?? 'DOCUMENT',
          'hash': row[3]?.toString() ?? 'SHA256: ...',
          'tamperCheck': row[4]?.toString() ?? 'PASS',
          'status': row[5]?.toString() ?? 'Uploaded',
          'timestamp': row[6]?.toString() ?? DateTime.now().toIso8601String(),
          'sizeMb': row[7]?.toString() ?? '1.2 MB',
          'chainOfCustody': row[8]?.toString() ?? 'Forensic Locked',
        });
      }
      return assets;
    } catch (e) {
      debugPrint('[PostgreSQL] Error fetching vault assets: $e');
      return [];
    }
  }

  /// Fetch all real Guardians from PostgreSQL
  Future<List<Map<String, dynamic>>> getGuardians() async {
    try {
      if (!await connect()) return [];
      final result = await _connection!.execute(
        'SELECT id, ward_name, guardian_name, email, phone, relation, status, safety_score, risk_status, battery_level, device_state, location_text, gps FROM guardians;'
      );

      final List<Map<String, dynamic>> list = [];
      for (final row in result) {
        list.add({
          'id': row[0]?.toString() ?? '',
          'wardName': row[1]?.toString() ?? 'Priya Sharma',
          'guardianName': row[2]?.toString() ?? 'Sunita Sharma',
          'email': row[3]?.toString() ?? '',
          'phone': row[4]?.toString() ?? '',
          'relation': row[5]?.toString() ?? 'mother',
          'status': row[6]?.toString() ?? 'ACTIVE',
          'safetyScore': row[7]?.toString() ?? '95% Safety',
          'riskStatus': row[8]?.toString() ?? 'SAFE',
          'batteryLevel': row[9]?.toString() ?? '88%',
          'deviceState': row[10]?.toString() ?? 'Active',
          'locationText': row[11]?.toString() ?? 'Safe Zone',
          'gps': row[12]?.toString() ?? '23.0225, 72.5714',
        });
      }
      return list;
    } catch (e) {
      debugPrint('[PostgreSQL] Error fetching guardians: $e');
      return [];
    }
  }

  /// Fetch all real Smart Cab Trips from PostgreSQL
  Future<List<Map<String, dynamic>>> getCabTrips() async {
    try {
      if (!await connect()) return [];
      final result = await _connection!.execute(
        'SELECT id, plate_number, driver_name, provider, destination, origin, speed_kmh, deviation_meters, safety_score, status, timestamp FROM cab_trips ORDER BY timestamp DESC;'
      );

      final List<Map<String, dynamic>> trips = [];
      for (final row in result) {
        trips.add({
          'id': row[0]?.toString() ?? '',
          'plateNumber': row[1]?.toString() ?? '',
          'driverName': row[2]?.toString() ?? '',
          'provider': row[3]?.toString() ?? 'Uber',
          'destination': row[4]?.toString() ?? '',
          'origin': row[5]?.toString() ?? '',
          'speedKmh': row[6] is int ? row[6] : int.tryParse(row[6]?.toString() ?? '38') ?? 38,
          'deviationMeters': row[7] is num ? (row[7] as num).toDouble() : double.tryParse(row[7]?.toString() ?? '28.0') ?? 28.0,
          'safetyScore': row[8]?.toString() ?? '98%',
          'status': row[9]?.toString() ?? 'ACTIVE',
          'timestamp': row[10]?.toString() ?? DateTime.now().toIso8601String(),
        });
      }
      return trips;
    } catch (e) {
      debugPrint('[PostgreSQL] Error fetching cab trips: $e');
      return [];
    }
  }

  /// Close connection when app terminates
  Future<void> dispose() async {
    if (_connection != null) {
      await _connection!.close();
      _isConnected = false;
    }
  }
}
