import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'database_service.dart';
import 'local_database_service.dart';
import 'voice_engine_service.dart';
import 'geo_platform_stub.dart'
    if (dart.library.io) 'geo_platform_io.dart'
    if (dart.library.js_interop) 'geo_platform_web.dart';
import 'voice_platform_stub.dart'
    if (dart.library.io) 'voice_platform_io.dart'
    if (dart.library.js_interop) 'voice_platform_web.dart';

class PlaceSuggestion {
  final String placeId;
  final String name;
  final String displayName;
  final String category;
  final LatLng location;

  const PlaceSuggestion({
    required this.placeId,
    required this.name,
    required this.displayName,
    required this.category,
    required this.location,
  });

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    final lat = (json['latitude'] as num?)?.toDouble() ?? 0.0;
    final lng = (json['longitude'] as num?)?.toDouble() ?? 0.0;
    return PlaceSuggestion(
      placeId: json['placeId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Location',
      displayName: json['displayName']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Place',
      location: LatLng(lat, lng),
    );
  }
}

class TravelRouteOption {
  final String routeId;
  final String label;
  final String summary;
  final double distanceMeters;
  final int durationSeconds;
  final int durationMinutes;
  final List<LatLng> polyline;

  const TravelRouteOption({
    required this.routeId,
    required this.label,
    required this.summary,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.durationMinutes,
    required this.polyline,
  });

  factory TravelRouteOption.fromJson(Map<String, dynamic> json) {
    final rawPoly = json['polyline'];
    final pts = <LatLng>[];
    if (rawPoly is List) {
      for (final item in rawPoly) {
        if (item is List && item.length >= 2) {
          final lat = (item[0] as num?)?.toDouble();
          final lng = (item[1] as num?)?.toDouble();
          if (lat != null && lng != null) {
            pts.add(LatLng(lat, lng));
          }
        }
      }
    }
    return TravelRouteOption(
      routeId: json['routeId']?.toString() ?? 'route-0',
      label: json['label']?.toString() ?? 'Route',
      summary: json['summary']?.toString() ?? 'Road corridor',
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 1,
      polyline: pts,
    );
  }
}

class GuardianContact {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String relationship;

  const GuardianContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.relationship,
  });

  factory GuardianContact.fromJson(Map<String, dynamic> json) {
    return GuardianContact(
      id: json['id']?.toString() ?? '',
      name: json['guardianName']?.toString() ?? 'Guardian',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      relationship: json['relationship']?.toString() ?? json['relation']?.toString() ?? 'Guardian',
    );
  }
}

class ShareRecordInfo {
  final String id;
  final String guardianName;
  final String guardianPhone;
  final String guardianEmail;
  final String deliveryStatus;
  final String deliveryMessage;
  final String expiresAt;
  final String? revokedAt;
  final String? sharePath;

  const ShareRecordInfo({
    required this.id,
    required this.guardianName,
    required this.guardianPhone,
    required this.guardianEmail,
    required this.deliveryStatus,
    required this.deliveryMessage,
    required this.expiresAt,
    this.revokedAt,
    this.sharePath,
  });

  bool get isActive => revokedAt == null;

  factory ShareRecordInfo.fromJson(Map<String, dynamic> json, {String? explicitPath}) {
    return ShareRecordInfo(
      id: json['id']?.toString() ?? json['shareId']?.toString() ?? '',
      guardianName: json['guardianName']?.toString() ?? 'Guardian',
      guardianPhone: json['guardianPhone']?.toString() ?? '',
      guardianEmail: json['guardianEmail']?.toString() ?? '',
      deliveryStatus: json['deliveryStatus']?.toString() ?? 'NOT_CONFIGURED',
      deliveryMessage: json['deliveryMessage']?.toString() ?? '',
      expiresAt: json['expiresAt']?.toString() ?? '',
      revokedAt: json['revokedAt']?.toString(),
      sharePath: explicitPath ?? json['sharePath']?.toString(),
    );
  }
}

class JourneyEventInfo {
  final String id;
  final String eventType;
  final String details;
  final String createdAt;

  const JourneyEventInfo({
    required this.id,
    required this.eventType,
    required this.details,
    required this.createdAt,
  });

  factory JourneyEventInfo.fromJson(Map<String, dynamic> json) {
    return JourneyEventInfo(
      id: json['id']?.toString() ?? '',
      eventType: json['eventType']?.toString() ?? '',
      details: json['details']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

enum JourneyDisplayStatus {
  notStarted,
  active,
  warning,
  emergency,
  completed,
}

class TravelJourneyService extends ChangeNotifier {
  static const double routeDeviationThresholdMeters = 350.0;
  static const int gpsGapWarningSeconds = 90;
  static const int etaGracePeriodMinutes = 5;

  final LocalDatabaseService _api = LocalDatabaseService();

  // Origin & destination planning state
  bool _useCurrentGpsOrigin = true;
  PlaceSuggestion? _manualOrigin;
  PlaceSuggestion? _selectedDestination;
  LatLng? _currentGps;
  double _gpsAccuracyMeters = 0.0;
  double _currentSpeedMps = 0.0;
  DateTime? _lastGpsAt;
  String? _gpsError;
  bool _gpsPermissionGranted = false;
  bool _gpsWatchRunning = false;

  String _travelMode = 'driving'; // 'driving' | 'walking'
  List<TravelRouteOption> _routeOptions = <TravelRouteOption>[];
  int _selectedRouteIndex = 0;
  bool _isCalculatingRoute = false;
  String? _routeError;

  // Active journey state (mirrored with SQLite)
  String? _activeJourneyId;
  String _serverStatus = 'NOT_STARTED';
  LatLng? _journeyStartPoint;
  String _journeyStartName = 'Current GPS Location';
  LatLng? _journeyDestPoint;
  String _journeyDestName = '';
  List<LatLng> _plannedPolyline = <LatLng>[];
  List<LatLng> _traveledTrail = <LatLng>[];
  double _plannedDistanceMeters = 0.0;
  int _estimatedDurationMinutes = 0;
  String _recordingMode = 'Audio Only';
  DateTime? _journeyStartTime;
  DateTime? _estimatedArrivalTime;
  double _deviationMeters = 0.0;
  bool _deviationWarning = false;

  // Evidence blackbox recording state during active trip
  bool _blackboxRecordingActive = false;
  DateTime? _blackboxStartedAt;
  String _blackboxStatusText = 'Inactive';

  // Sync, guardians, shares, and summary state
  final List<Map<String, dynamic>> _pendingGpsQueue = <Map<String, dynamic>>[];
  DateTime? _lastSyncSuccessAt;
  String? _syncError;
  List<GuardianContact> _guardians = <GuardianContact>[];
  List<ShareRecordInfo> _shares = <ShareRecordInfo>[];
  String? _lastCreatedSharePath;
  List<JourneyEventInfo> _events = <JourneyEventInfo>[];
  List<Map<String, dynamic>> _history = <Map<String, dynamic>>[];
  Map<String, dynamic>? _completedSummary;
  bool _isBusy = false;

  Timer? _monitorTimer;
  Timer? _syncTimer;

  // ---------------------------------------------------------------------------
  // Pure Geodesic Math (Unit Testable)
  // ---------------------------------------------------------------------------

  static double haversineMeters(LatLng a, LatLng b) {
    const double r = 6371000.0;
    final p1 = a.latitude * math.pi / 180.0;
    final p2 = b.latitude * math.pi / 180.0;
    final dp = (b.latitude - a.latitude) * math.pi / 180.0;
    final dl = (b.longitude - a.longitude) * math.pi / 180.0;
    final ha = math.sin(dp / 2.0) * math.sin(dp / 2.0) +
        math.cos(p1) * math.cos(p2) * math.sin(dl / 2.0) * math.sin(dl / 2.0);
    return 2.0 * r * math.atan2(math.sqrt(ha), math.sqrt(math.max(0.0, 1.0 - ha)));
  }

  static double distanceToPolylineMeters(LatLng p, List<LatLng> polyline) {
    if (polyline.isEmpty) return 0.0;
    if (polyline.length == 1) return haversineMeters(p, polyline.first);

    final mPerLat = 111320.0;
    final mPerLng = math.max(1e-6, 111320.0 * math.cos(p.latitude * math.pi / 180.0));
    double best = double.infinity;

    for (var i = 0; i < polyline.length - 1; i++) {
      final a = polyline[i];
      final b = polyline[i + 1];
      final ax = (a.longitude - p.longitude) * mPerLng;
      final ay = (a.latitude - p.latitude) * mPerLat;
      final bx = (b.longitude - p.longitude) * mPerLng;
      final by = (b.latitude - p.latitude) * mPerLat;
      final dx = bx - ax;
      final dy = by - ay;
      final lenSq = dx * dx + dy * dy;
      if (lenSq <= 1e-9) {
        best = math.min(best, math.sqrt(ax * ax + ay * ay));
      } else {
        final t = ((-ax * dx - ay * dy) / lenSq).clamp(0.0, 1.0);
        final projX = ax + t * dx;
        final projY = ay + t * dy;
        best = math.min(best, math.sqrt(projX * projX + projY * projY));
      }
    }
    return best.isFinite ? best : 0.0;
  }

  static double computeTraveledMeters(List<LatLng> trail) {
    if (trail.length < 2) return 0.0;
    var sum = 0.0;
    for (var i = 1; i < trail.length; i++) {
      sum += haversineMeters(trail[i - 1], trail[i]);
    }
    return sum;
  }

  static String formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000.0).toStringAsFixed(2)} km';
  }

  static String formatCountdown(Duration remaining) {
    final isNeg = remaining.isNegative;
    final abs = remaining.abs();
    final h = abs.inHours.toString().padLeft(2, '0');
    final m = (abs.inMinutes % 60).toString().padLeft(2, '0');
    final s = (abs.inSeconds % 60).toString().padLeft(2, '0');
    return isNeg ? '+$h:$m:$s OVERDUE' : '$h:$m:$s';
  }

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  bool get hasActiveJourney => _activeJourneyId != null;
  String? get activeJourneyId => _activeJourneyId;
  bool get useCurrentGpsOrigin => _useCurrentGpsOrigin;
  PlaceSuggestion? get manualOrigin => _manualOrigin;
  PlaceSuggestion? get selectedDestination => _selectedDestination;
  LatLng? get currentGps => _currentGps;
  double get gpsAccuracyMeters => _gpsAccuracyMeters;
  DateTime? get lastGpsAt => _lastGpsAt;
  String? get gpsError => _gpsError;
  bool get gpsPermissionGranted => _gpsPermissionGranted;
  bool get gpsWatchRunning => _gpsWatchRunning;
  String get travelMode => _travelMode;
  List<TravelRouteOption> get routeOptions => List.unmodifiable(_routeOptions);
  int get selectedRouteIndex => _selectedRouteIndex;
  TravelRouteOption? get selectedRoute =>
      (_routeOptions.isNotEmpty && _selectedRouteIndex < _routeOptions.length)
          ? _routeOptions[_selectedRouteIndex]
          : null;
  bool get isCalculatingRoute => _isCalculatingRoute;
  String? get routeError => _routeError;
  bool get isBusy => _isBusy;

  LatLng? get effectiveOriginPoint =>
      _useCurrentGpsOrigin ? _currentGps : _manualOrigin?.location;
  String get effectiveOriginName =>
      _useCurrentGpsOrigin ? 'Current GPS Location' : (_manualOrigin?.name ?? 'Select Origin');

  LatLng? get displayOriginPoint =>
      hasActiveJourney ? _journeyStartPoint : effectiveOriginPoint;
  String get displayOriginName =>
      hasActiveJourney ? _journeyStartName : effectiveOriginName;
  LatLng? get displayDestPoint =>
      hasActiveJourney ? _journeyDestPoint : _selectedDestination?.location;
  String get displayDestName =>
      hasActiveJourney ? _journeyDestName : (_selectedDestination?.name ?? '');
  List<LatLng> get displayPlannedPolyline =>
      hasActiveJourney ? _plannedPolyline : (selectedRoute?.polyline ?? const <LatLng>[]);
  List<LatLng> get traveledTrail => List.unmodifiable(_traveledTrail);

  double get traveledDistanceMeters => computeTraveledMeters(_traveledTrail);
  double get remainingDistanceMeters {
    final dest = displayDestPoint;
    if (dest == null) return 0.0;
    final cur = _currentGps ?? (_traveledTrail.isNotEmpty ? _traveledTrail.last : displayOriginPoint);
    if (cur == null) return _plannedDistanceMeters;
    return haversineMeters(cur, dest);
  }

  double get plannedDistanceMeters =>
      hasActiveJourney ? _plannedDistanceMeters : (selectedRoute?.distanceMeters ?? 0.0);
  double get currentSpeedKmh => (_currentSpeedMps * 3.6).clamp(0.0, 180.0);
  String get dynamicEtaDisplay {
    if (_estimatedArrivalTime == null) return '--';
    if (_currentSpeedMps > 1.2 && remainingDistanceMeters > 20) {
      final mins = math.max(1, (remainingDistanceMeters / _currentSpeedMps / 60.0).round());
      return '~$mins min (live speed ${currentSpeedKmh.toStringAsFixed(0)} km/h)';
    }
    final localEta = _estimatedArrivalTime!.toLocal();
    final hh = localEta.hour.toString().padLeft(2, '0');
    final mm = localEta.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
  int get estimatedDurationMinutes => _estimatedDurationMinutes;
  String get recordingMode => _recordingMode;
  DateTime? get journeyStartTime => _journeyStartTime;
  DateTime? get estimatedArrivalTime => _estimatedArrivalTime;
  Duration get timeRemaining {
    if (_estimatedArrivalTime == null) return Duration.zero;
    return _estimatedArrivalTime!.difference(DateTime.now().toUtc());
  }

  bool get isOverdue =>
      hasActiveJourney &&
      _estimatedArrivalTime != null &&
      DateTime.now().toUtc().isAfter(_estimatedArrivalTime!);

  bool get isGracePeriodExceeded =>
      hasActiveJourney &&
      _estimatedArrivalTime != null &&
      DateTime.now().toUtc().isAfter(
            _estimatedArrivalTime!.add(const Duration(minutes: etaGracePeriodMinutes)),
          );

  bool get isGpsGapWarning {
    if (!hasActiveJourney || _lastGpsAt == null) return false;
    return DateTime.now().toUtc().difference(_lastGpsAt!).inSeconds >= gpsGapWarningSeconds;
  }

  bool get deviationWarning => _deviationWarning;
  double get deviationMeters => _deviationMeters;
  int get pendingOfflineCount => _pendingGpsQueue.length;
  DateTime? get lastSyncSuccessAt => _lastSyncSuccessAt;
  String? get syncError => _syncError;

  bool get blackboxRecordingActive => _blackboxRecordingActive;
  String get blackboxStatusText => _blackboxStatusText;

  List<GuardianContact> get guardians => List.unmodifiable(_guardians);
  List<ShareRecordInfo> get shares => List.unmodifiable(_shares);
  String? get lastCreatedSharePath => _lastCreatedSharePath;
  List<JourneyEventInfo> get events => List.unmodifiable(_events);
  List<Map<String, dynamic>> get history => List.unmodifiable(_history);
  Map<String, dynamic>? get completedSummary => _completedSummary;
  String get serverStatus => _serverStatus;

  String get platformTrackingNotice => kIsWeb
      ? 'Web tracking runs continuously while this browser tab stays open. Lock-screen background GPS is limited on web browsers.'
      : 'Android GPS tracking runs through native LocationManager while the app has location permission.';

  JourneyDisplayStatus get displayStatus {
    if (_completedSummary != null && !hasActiveJourney) {
      return JourneyDisplayStatus.completed;
    }
    if (!hasActiveJourney) {
      return JourneyDisplayStatus.notStarted;
    }
    if (_serverStatus == 'EMERGENCY') {
      return JourneyDisplayStatus.emergency;
    }
    if (isOverdue || _deviationWarning || isGpsGapWarning) {
      return JourneyDisplayStatus.warning;
    }
    return JourneyDisplayStatus.active;
  }

  String get statusBadgeText {
    switch (displayStatus) {
      case JourneyDisplayStatus.notStarted:
        return 'NOT STARTED';
      case JourneyDisplayStatus.active:
        return 'LIVE JOURNEY ACTIVE';
      case JourneyDisplayStatus.warning:
        if (isOverdue) return 'ETA OVERDUE WARNING';
        if (_deviationWarning) return 'ROUTE DEVIATION WARNING';
        return 'GPS SIGNAL DELAY WARNING';
      case JourneyDisplayStatus.emergency:
        return 'EMERGENCY SOS ACTIVE';
      case JourneyDisplayStatus.completed:
        return 'SAFE ARRIVAL COMPLETED';
    }
  }

  // ---------------------------------------------------------------------------
  // Initialization & Restore
  // ---------------------------------------------------------------------------

  Future<void> initializeAndRestore() async {
    _gpsPermissionGranted = await platformCheckLocationPermission();
    final activeRes = await _api.getActiveJourney();
    if (activeRes.success && activeRes.data != null) {
      _parseGuardians(activeRes.data!['guardians']);
      final activeJson = activeRes.data!['journey'];
      if (activeRes.data!['active'] == true && activeJson is Map) {
        _hydrateFromJourneyJson(Map<String, dynamic>.from(activeJson));
        _startTimers();
        if (_gpsPermissionGranted) {
          await resumeLiveGpsWatch();
        }
      }
    }
    await refreshHistory();
    notifyListeners();
  }

  void _parseGuardians(dynamic raw) {
    if (raw is List) {
      _guardians = raw
          .whereType<Map>()
          .map((e) => GuardianContact.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
  }

  Future<void> refreshHistory() async {
    final hist = await _api.getJourneyHistory();
    if (hist.success && hist.data != null) {
      _history = hist.data!;
      notifyListeners();
    }
  }

  Future<void> refreshGuardians() async {
    final res = await _api.getActiveJourney();
    if (res.success && res.data != null) {
      _parseGuardians(res.data!['guardians']);
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Search & Route Calculation
  // ---------------------------------------------------------------------------

  Future<({List<PlaceSuggestion> results, String? error})> searchLocations(String query) async {
    if (query.trim().length < 2) {
      return (results: const <PlaceSuggestion>[], error: null);
    }
    final res = await _api.searchPlaces(
      query: query,
      lat: _currentGps?.latitude ?? _manualOrigin?.location.latitude,
      lng: _currentGps?.longitude ?? _manualOrigin?.location.longitude,
    );
    if (!res.success || res.data == null) {
      return (results: const <PlaceSuggestion>[], error: res.error ?? 'Search failed');
    }
    final raw = res.data!['results'];
    final out = (raw is List)
        ? raw
            .whereType<Map>()
            .map((e) => PlaceSuggestion.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <PlaceSuggestion>[];
    return (results: out, error: null);
  }

  Future<({bool ok, String? error})> captureCurrentLocation() async {
    _gpsError = null;
    notifyListeners();
    final sample = await platformGetCurrentPosition();
    if (!sample.ok || sample.latitude == null || sample.longitude == null) {
      _gpsError = sample.error ?? 'Unable to acquire GPS fix.';
      _gpsPermissionGranted = false;
      notifyListeners();
      return (ok: false, error: _gpsError);
    }
    _gpsPermissionGranted = true;
    _currentGps = LatLng(sample.latitude!, sample.longitude!);
    _gpsAccuracyMeters = sample.accuracy;
    _currentSpeedMps = sample.speed;
    _lastGpsAt = DateTime.tryParse(sample.timestamp)?.toUtc() ?? DateTime.now().toUtc();
    _useCurrentGpsOrigin = true;
    notifyListeners();

    if (_selectedDestination != null) {
      await recalculateRoutes();
    }
    return (ok: true, error: null);
  }

  Future<void> setManualOrigin(PlaceSuggestion origin) async {
    _manualOrigin = origin;
    _useCurrentGpsOrigin = false;
    notifyListeners();
    if (_selectedDestination != null) {
      await recalculateRoutes();
    }
  }

  Future<void> setUseCurrentGpsOrigin(bool useCurrent) async {
    _useCurrentGpsOrigin = useCurrent;
    notifyListeners();
    if (useCurrent && _currentGps == null) {
      await captureCurrentLocation();
    } else if (_selectedDestination != null) {
      await recalculateRoutes();
    }
  }

  Future<void> selectDestination(PlaceSuggestion dest) async {
    _selectedDestination = dest;
    _completedSummary = null;
    notifyListeners();
    if (effectiveOriginPoint == null && _useCurrentGpsOrigin) {
      await captureCurrentLocation();
    }
    await recalculateRoutes();
  }

  Future<void> setTravelMode(String mode) async {
    if (mode != 'driving' && mode != 'walking') return;
    _travelMode = mode;
    notifyListeners();
    if (effectiveOriginPoint != null && _selectedDestination != null) {
      await recalculateRoutes();
    }
  }

  void selectRouteIndex(int idx) {
    if (idx < 0 || idx >= _routeOptions.length) return;
    _selectedRouteIndex = idx;
    _estimatedDurationMinutes = _routeOptions[idx].durationMinutes;
    notifyListeners();
  }

  Future<void> recalculateRoutes() async {
    final origin = effectiveOriginPoint;
    final dest = _selectedDestination?.location;
    if (origin == null || dest == null) {
      _routeError = origin == null ? 'Acquiring starting GPS location first...' : null;
      notifyListeners();
      return;
    }
    _isCalculatingRoute = true;
    _routeError = null;
    notifyListeners();

    final res = await _api.computeRoutes(
      startLat: origin.latitude,
      startLng: origin.longitude,
      destLat: dest.latitude,
      destLng: dest.longitude,
      mode: _travelMode,
    );
    _isCalculatingRoute = false;

    if (!res.success || res.data == null) {
      _routeOptions = <TravelRouteOption>[];
      _routeError = res.error ?? 'Unable to compute real route corridor.';
      notifyListeners();
      return;
    }

    final rawRoutes = res.data!['routes'];
    if (rawRoutes is List && rawRoutes.isNotEmpty) {
      _routeOptions = rawRoutes
          .whereType<Map>()
          .map((e) => TravelRouteOption.fromJson(Map<String, dynamic>.from(e)))
          .where((r) => r.polyline.length >= 2)
          .toList();
      _selectedRouteIndex = 0;
      if (_routeOptions.isNotEmpty) {
        _estimatedDurationMinutes = _routeOptions.first.durationMinutes;
      } else {
        _routeError = 'No valid road polyline returned for this pair of coordinates.';
      }
    } else {
      _routeOptions = <TravelRouteOption>[];
      _routeError = 'No routes found between origin and destination.';
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Start Journey
  // ---------------------------------------------------------------------------

  Future<({bool ok, String? error})> startJourney({
    required int durationMinutes,
    required String recordingMode,
    required DatabaseService db,
  }) async {
    if (_selectedDestination == null) {
      return (ok: false, error: 'Search and select a real destination from the suggestions list first.');
    }
    final route = selectedRoute;
    if (route == null || route.polyline.length < 2) {
      return (ok: false, error: 'Calculate a real route between start and destination before starting.');
    }
    if (durationMinutes < 1 || durationMinutes > 1440) {
      return (ok: false, error: 'Estimated travel duration must be between 1 and 1440 minutes.');
    }

    _isBusy = true;
    _completedSummary = null;
    notifyListeners();

    try {
      // 1. Require real Location permission & capture starting GPS fix
      final gpsCheck = await captureCurrentLocation();
      if (_useCurrentGpsOrigin && !gpsCheck.ok) {
        _isBusy = false;
        notifyListeners();
        return (ok: false, error: gpsCheck.error ?? 'Location permission is required to start Safe Arrival.');
      }
      final originPt = _useCurrentGpsOrigin
          ? _currentGps
          : (_manualOrigin?.location ?? _currentGps);
      if (originPt == null) {
        _isBusy = false;
        notifyListeners();
        return (ok: false, error: 'Starting coordinates unavailable.');
      }

      // 2. Request explicit Mic permission ONLY if configured evidence mode requires recording
      var micPermGranted = false;
      if (recordingMode != 'None') {
        micPermGranted = await VoiceEngineService().requestMicPermission();
        if (!micPermGranted) {
          _isBusy = false;
          notifyListeners();
          return (
            ok: false,
            error:
                'Microphone permission is required for "$recordingMode" mode. Allow microphone access or choose "None".',
          );
        }
      }

      // 3. Persist journey in SQLite backend
      final res = await _api.startJourney({
        'startLocationName': effectiveOriginName,
        'startLatitude': originPt.latitude,
        'startLongitude': originPt.longitude,
        'startAccuracy': _gpsAccuracyMeters,
        'destinationName': _selectedDestination!.displayName,
        'destinationLatitude': _selectedDestination!.location.latitude,
        'destinationLongitude': _selectedDestination!.location.longitude,
        'distanceMeters': route.distanceMeters,
        'estimatedDuration': durationMinutes,
        'recordingMode': recordingMode,
        'routePolyline': route.polyline.map((p) => [p.latitude, p.longitude]).toList(),
        'routeSummary': route.summary,
      });

      if (!res.success || res.data == null || res.data!['journey'] is! Map) {
        _isBusy = false;
        notifyListeners();
        return (ok: false, error: res.error ?? 'Unable to save journey in SQLite.');
      }

      _hydrateFromJourneyJson(Map<String, dynamic>.from(res.data!['journey'] as Map));
      _startTimers();
      await resumeLiveGpsWatch();

      // 4. Start real evidence blackbox ONLY after explicit permission check
      if (recordingMode != 'None' && micPermGranted) {
        await _startBlackboxAudio(recordingMode);
      } else {
        _blackboxRecordingActive = false;
        _blackboxStatusText = 'GPS Monitoring Only';
      }

      _isBusy = false;
      notifyListeners();
      return (ok: true, error: null);
    } catch (e) {
      _isBusy = false;
      notifyListeners();
      return (ok: false, error: e.toString());
    }
  }

  Future<void> _startBlackboxAudio(String recordingMode) async {
    final started = await platformStartRecording(
      fileName: 'travel_${_activeJourneyId ?? 'trip'}.m4a',
      onInterrupted: (reason) {
        _blackboxRecordingActive = false;
        _blackboxStatusText = 'Recording interrupted ($reason)';
        notifyListeners();
      },
      onLevel: (_) {},
    );
    if (started.ok) {
      _blackboxRecordingActive = true;
      _blackboxStartedAt = DateTime.now().toUtc();
      _blackboxStatusText = recordingMode == 'Video & Audio'
          ? 'Audio Blackbox Active (camera video stream unavailable on this view)'
          : 'Audio Blackbox Recording Live';
    } else {
      _blackboxRecordingActive = false;
      _blackboxStatusText = 'Recorder unavailable: ${started.error ?? 'Error'}';
    }
  }

  Future<void> _stopAndSaveBlackbox(DatabaseService db) async {
    if (!_blackboxRecordingActive) return;
    _blackboxRecordingActive = false;
    try {
      final stopped = await platformStopRecording();
      final endedAt = DateTime.now().toUtc();
      final startedAt = _blackboxStartedAt ?? endedAt.subtract(const Duration(seconds: 2));
      if (stopped.ok && stopped.bytes != null && stopped.bytes!.isNotEmpty && db.hasPermission('audio_evidence:own')) {
        final gpsStr = _currentGps != null
            ? '${_currentGps!.latitude.toStringAsFixed(5)}, ${_currentGps!.longitude.toStringAsFixed(5)}'
            : 'GPS Unavailable';
        await _api.uploadAudioEvidence(
          recordingId: 'AUD-TRV-${endedAt.millisecondsSinceEpoch}',
          sosEventId: '',
          filename: 'travel_${_activeJourneyId ?? 'trip'}_${endedAt.millisecondsSinceEpoch}.webm',
          mimeType: stopped.mimeType,
          bytes: stopped.bytes!,
          durationSeconds: stopped.durationSeconds,
          startedAt: startedAt.toIso8601String(),
          endedAt: endedAt.toIso8601String(),
          clientSha256: stopped.sha256,
          triggerPhrase: 'safe_arrival_blackbox',
          gps: gpsStr,
          locationName: _journeyDestName.isNotEmpty ? 'Travel -> $_journeyDestName' : 'Safe Arrival Blackbox',
        );
        _blackboxStatusText = 'Blackbox Saved to Vault (${stopped.durationSeconds}s)';
      } else {
        _blackboxStatusText = 'Blackbox Stopped (${stopped.durationSeconds}s)';
      }
    } catch (e) {
      _blackboxStatusText = 'Blackbox Stop Error: $e';
    }
  }

  // ---------------------------------------------------------------------------
  // Continuous Live GPS Watch, Queue & Monitoring
  // ---------------------------------------------------------------------------

  Future<void> resumeLiveGpsWatch() async {
    if (!hasActiveJourney) return;
    final ok = await platformStartLocationWatch(
      onPosition: _handleLiveGpsSample,
      onError: (err) {
        _gpsError = err;
        _gpsWatchRunning = false;
        notifyListeners();
      },
    );
    _gpsWatchRunning = ok;
    if (ok) {
      _gpsPermissionGranted = true;
      _gpsError = null;
    }
    notifyListeners();
  }

  void _handleLiveGpsSample(GeoPositionSample sample) {
    if (!sample.ok || sample.latitude == null || sample.longitude == null) return;
    final pt = LatLng(sample.latitude!, sample.longitude!);
    final nowTs = DateTime.tryParse(sample.timestamp)?.toUtc() ?? DateTime.now().toUtc();

    _currentGps = pt;
    _gpsAccuracyMeters = sample.accuracy;
    _currentSpeedMps = sample.speed;
    _lastGpsAt = nowTs;
    _gpsError = null;
    _gpsWatchRunning = true;

    if (!hasActiveJourney) {
      notifyListeners();
      return;
    }

    // Filter ultra-dense duplicate coordinates (< 1m within 2s)
    var shouldAppend = true;
    if (_traveledTrail.isNotEmpty) {
      final last = _traveledTrail.last;
      if (haversineMeters(last, pt) < 1.0 && _pendingGpsQueue.isNotEmpty) {
        shouldAppend = false;
      }
    }

    if (shouldAppend) {
      _traveledTrail.add(pt);
      _pendingGpsQueue.add({
        'latitude': pt.latitude,
        'longitude': pt.longitude,
        'accuracy': sample.accuracy,
        'speed': sample.speed,
        'heading': sample.heading,
        'recordedAt': sample.timestamp,
      });
    }

    if (_plannedPolyline.length >= 2) {
      _deviationMeters = distanceToPolylineMeters(pt, _plannedPolyline);
      _deviationWarning = _deviationMeters > routeDeviationThresholdMeters;
    }
    notifyListeners();
  }

  Future<void> flushPendingLocations() async {
    if (!hasActiveJourney || _pendingGpsQueue.isEmpty) return;
    final batch = List<Map<String, dynamic>>.from(_pendingGpsQueue);
    final res = await _api.postJourneyLocations(journeyId: _activeJourneyId!, points: batch);
    if (res.success && res.data != null) {
      _pendingGpsQueue.removeRange(0, batch.length);
      _lastSyncSuccessAt = DateTime.now().toUtc();
      _syncError = null;
      final j = res.data!['journey'];
      if (j is Map) {
        _syncMetadataFromJourneyJson(Map<String, dynamic>.from(j));
      }
    } else {
      _syncError = res.error ?? 'Offline: buffering ${ _pendingGpsQueue.length } GPS point(s)';
    }
    notifyListeners();
  }

  void _startTimers() {
    _monitorTimer?.cancel();
    _syncTimer?.cancel();
    _monitorTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!hasActiveJourney) return;
      notifyListeners();
    });
    _syncTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!hasActiveJourney) return;
      flushPendingLocations();
    });
  }

  void _stopTimers() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  // ---------------------------------------------------------------------------
  // Guardian Share, Revoke, Extend ETA, Safe Arrival Complete, SOS
  // ---------------------------------------------------------------------------

  Future<({bool ok, ShareRecordInfo? share, String? rawSharePath, String? error})> shareWithGuardians({
    required List<String> guardianIds,
    String? inlineName,
    String? inlinePhone,
    String? inlineEmail,
    String? inlineRelationship,
    bool saveGuardian = true,
  }) async {
    if (!hasActiveJourney) {
      return (ok: false, share: null, rawSharePath: null, error: 'Start a journey before sharing.');
    }
    _isBusy = true;
    notifyListeners();

    final res = await _api.shareJourney({
      'journeyId': _activeJourneyId,
      'guardianIds': guardianIds,
      if (inlineName != null && inlineName.trim().isNotEmpty) 'guardianName': inlineName.trim(),
      if (inlinePhone != null && inlinePhone.trim().isNotEmpty) 'guardianPhone': inlinePhone.trim(),
      if (inlineEmail != null && inlineEmail.trim().isNotEmpty) 'guardianEmail': inlineEmail.trim(),
      if (inlineRelationship != null && inlineRelationship.trim().isNotEmpty)
        'relationship': inlineRelationship.trim(),
      'saveGuardian': saveGuardian,
    });
    _isBusy = false;

    if (!res.success || res.data == null) {
      notifyListeners();
      return (ok: false, share: null, rawSharePath: null, error: res.error ?? 'Share creation failed.');
    }

    final sharePath = res.data!['sharePath']?.toString();
    _lastCreatedSharePath = sharePath;
    await refreshGuardians();
    final activeRes = await _api.getActiveJourney();
    if (activeRes.success && activeRes.data != null && activeRes.data!['journey'] is Map) {
      _hydrateFromJourneyJson(Map<String, dynamic>.from(activeRes.data!['journey'] as Map));
    }

    final shareInfo = ShareRecordInfo.fromJson(res.data!, explicitPath: sharePath);
    notifyListeners();
    return (ok: true, share: shareInfo, rawSharePath: sharePath, error: null);
  }

  Future<bool> revokeShare(String shareId) async {
    final res = await _api.revokeJourneyShare(shareId);
    if (res.success && hasActiveJourney) {
      final activeRes = await _api.getActiveJourney();
      if (activeRes.success && activeRes.data != null && activeRes.data!['journey'] is Map) {
        _hydrateFromJourneyJson(Map<String, dynamic>.from(activeRes.data!['journey'] as Map));
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<({bool ok, String? error})> extendEta(int additionalMinutes) async {
    if (!hasActiveJourney) return (ok: false, error: 'No active journey.');
    final res = await _api.extendJourneyEta(
      journeyId: _activeJourneyId!,
      additionalMinutes: additionalMinutes,
    );
    if (!res.success || res.data == null || res.data!['journey'] is! Map) {
      return (ok: false, error: res.error ?? 'Could not extend ETA.');
    }
    _hydrateFromJourneyJson(Map<String, dynamic>.from(res.data!['journey'] as Map));
    notifyListeners();
    return (ok: true, error: null);
  }

  Future<({bool ok, Map<String, dynamic>? summary, String? error})> completeSafeArrival(
    DatabaseService db,
  ) async {
    if (!hasActiveJourney) return (ok: false, summary: null, error: 'No active journey.');
    _isBusy = true;
    notifyListeners();

    await flushPendingLocations();

    // Try a quick fresh final GPS reading for arrival verification
    try {
      final finalFix = await platformGetCurrentPosition().timeout(const Duration(seconds: 4));
      if (finalFix.ok && finalFix.latitude != null && finalFix.longitude != null) {
        _currentGps = LatLng(finalFix.latitude!, finalFix.longitude!);
        _gpsAccuracyMeters = finalFix.accuracy;
      }
    } catch (_) {}

    await platformStopLocationWatch();
    _gpsWatchRunning = false;
    _stopTimers();
    await _stopAndSaveBlackbox(db);

    final res = await _api.completeJourney(
      journeyId: _activeJourneyId!,
      latitude: _currentGps?.latitude,
      longitude: _currentGps?.longitude,
      accuracy: _gpsAccuracyMeters,
    );

    _isBusy = false;
    if (!res.success || res.data == null) {
      notifyListeners();
      return (ok: false, summary: null, error: res.error ?? 'Failed to complete journey.');
    }

    final summary = {
      'journey': res.data!['journey'],
      'arrivalVerified': res.data!['arrivalVerified'] == true,
      'arrivalDistanceMeters': res.data!['arrivalDistanceMeters'],
      'guardianNotification': res.data!['guardianNotification'],
      'traveledMeters': traveledDistanceMeters,
      'blackboxStatus': _blackboxStatusText,
    };
    _completedSummary = summary;
    _clearActiveFields();
    await refreshHistory();
    notifyListeners();
    return (ok: true, summary: summary, error: null);
  }

  Future<({bool ok, Map<String, dynamic>? data, String? error})> triggerEmergencySos({
    String? customMessage,
  }) async {
    if (!hasActiveJourney) {
      return (ok: false, data: null, error: 'No active journey.');
    }
    _isBusy = true;
    notifyListeners();
    await flushPendingLocations();

    final res = await _api.triggerJourneySos(
      journeyId: _activeJourneyId!,
      latitude: _currentGps?.latitude,
      longitude: _currentGps?.longitude,
      accuracy: _gpsAccuracyMeters,
      message: customMessage,
    );
    _isBusy = false;
    if (!res.success || res.data == null) {
      notifyListeners();
      return (ok: false, data: null, error: res.error ?? 'Failed to trigger Travel SOS.');
    }
    if (res.data!['journey'] is Map) {
      _hydrateFromJourneyJson(Map<String, dynamic>.from(res.data!['journey'] as Map));
    }
    notifyListeners();
    return (ok: true, data: res.data, error: null);
  }

  void dismissCompletedSummary() {
    _completedSummary = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Internal Hydration Helpers
  // ---------------------------------------------------------------------------

  void _hydrateFromJourneyJson(Map<String, dynamic> j) {
    _activeJourneyId = j['id']?.toString();
    _serverStatus = j['status']?.toString() ?? 'ACTIVE';
    _journeyStartName = j['startLocationName']?.toString() ?? 'Current GPS Location';
    final sLat = (j['startLatitude'] as num?)?.toDouble();
    final sLng = (j['startLongitude'] as num?)?.toDouble();
    _journeyStartPoint = (sLat != null && sLng != null) ? LatLng(sLat, sLng) : null;

    _journeyDestName = j['destinationName']?.toString() ?? '';
    final dLat = (j['destinationLatitude'] as num?)?.toDouble();
    final dLng = (j['destinationLongitude'] as num?)?.toDouble();
    _journeyDestPoint = (dLat != null && dLng != null) ? LatLng(dLat, dLng) : null;

    _plannedDistanceMeters = (j['distanceMeters'] as num?)?.toDouble() ?? 0.0;
    _estimatedDurationMinutes = (j['estimatedDuration'] as num?)?.toInt() ?? 0;
    _recordingMode = j['recordingMode']?.toString() ?? 'None';

    final rawPoly = j['routePolyline'];
    _plannedPolyline = <LatLng>[];
    if (rawPoly is List) {
      for (final pt in rawPoly) {
        if (pt is List && pt.length >= 2) {
          final plat = (pt[0] as num?)?.toDouble();
          final plng = (pt[1] as num?)?.toDouble();
          if (plat != null && plng != null) {
            _plannedPolyline.add(LatLng(plat, plng));
          }
        }
      }
    }

    final rawLocs = j['locations'];
    _traveledTrail = <LatLng>[];
    if (rawLocs is List) {
      for (final item in rawLocs) {
        if (item is Map) {
          final lat = (item['latitude'] as num?)?.toDouble();
          final lng = (item['longitude'] as num?)?.toDouble();
          if (lat != null && lng != null) {
            _traveledTrail.add(LatLng(lat, lng));
          }
        }
      }
    }

    final lLat = (j['lastLatitude'] as num?)?.toDouble();
    final lLng = (j['lastLongitude'] as num?)?.toDouble();
    if (lLat != null && lLng != null) {
      _currentGps = LatLng(lLat, lLng);
    } else if (_traveledTrail.isNotEmpty) {
      _currentGps = _traveledTrail.last;
    }
    _gpsAccuracyMeters = (j['lastAccuracy'] as num?)?.toDouble() ?? _gpsAccuracyMeters;
    final lastAtRaw = j['lastGpsAt']?.toString();
    if (lastAtRaw != null) {
      _lastGpsAt = DateTime.tryParse(lastAtRaw)?.toUtc();
    }

    _journeyStartTime = DateTime.tryParse(j['startTime']?.toString() ?? '')?.toUtc();
    _estimatedArrivalTime = DateTime.tryParse(j['estimatedArrivalTime']?.toString() ?? '')?.toUtc();
    _syncMetadataFromJourneyJson(j);
  }

  void _syncMetadataFromJourneyJson(Map<String, dynamic> j) {
    _serverStatus = j['status']?.toString() ?? _serverStatus;
    _deviationMeters = (j['deviationMeters'] as num?)?.toDouble() ?? _deviationMeters;
    _deviationWarning = j['deviationWarning'] == true;
    _estimatedDurationMinutes = (j['estimatedDuration'] as num?)?.toInt() ?? _estimatedDurationMinutes;
    final etaStr = j['estimatedArrivalTime']?.toString();
    if (etaStr != null) {
      _estimatedArrivalTime = DateTime.tryParse(etaStr)?.toUtc() ?? _estimatedArrivalTime;
    }
    final rawShares = j['shares'];
    if (rawShares is List) {
      _shares = rawShares
          .whereType<Map>()
          .map((e) => ShareRecordInfo.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    final rawEvents = j['events'];
    if (rawEvents is List) {
      _events = rawEvents
          .whereType<Map>()
          .map((e) => JourneyEventInfo.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
  }

  void _clearActiveFields() {
    _activeJourneyId = null;
    _serverStatus = 'NOT_STARTED';
    _journeyStartPoint = null;
    _journeyDestPoint = null;
    _plannedPolyline = <LatLng>[];
    _traveledTrail = <LatLng>[];
    _pendingGpsQueue.clear();
    _deviationWarning = false;
    _deviationMeters = 0.0;
    _shares = <ShareRecordInfo>[];
    _lastCreatedSharePath = null;
    _events = <JourneyEventInfo>[];
  }

  @override
  void dispose() {
    _stopTimers();
    platformStopLocationWatch();
    super.dispose();
  }
}
