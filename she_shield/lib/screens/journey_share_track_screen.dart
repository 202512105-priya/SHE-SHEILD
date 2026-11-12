import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/local_database_service.dart';
import '../services/travel_journey_service.dart';
import '../widgets/live_google_map_view.dart';

class JourneyShareTrackScreen extends StatefulWidget {
  final String token;

  const JourneyShareTrackScreen({super.key, required this.token});

  @override
  State<JourneyShareTrackScreen> createState() => _JourneyShareTrackScreenState();
}

class _JourneyShareTrackScreenState extends State<JourneyShareTrackScreen> {
  final LocalDatabaseService _api = LocalDatabaseService();
  Timer? _pollTimer;

  bool _loading = true;
  String? _errorText;
  String? _errorCode;
  Map<String, dynamic>? _payload;
  DateTime? _lastPollAt;

  @override
  void initState() {
    super.initState();
    _fetchLive();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchLive(silent: true));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLive({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _errorText = null;
      });
    }
    final res = await _api.fetchSharedJourneyByToken(widget.token);
    if (!mounted) return;

    if (!res.success || res.data == null) {
      final code = res.data?['code']?.toString();
      if (code == 'SHARE_REVOKED' || code == 'SHARE_EXPIRED' || code == 'SHARE_NOT_FOUND') {
        _pollTimer?.cancel();
      }
      setState(() {
        _loading = false;
        _errorText = res.error ?? 'Unable to load shared tracking session.';
        _errorCode = code;
      });
      return;
    }

    final status = (res.data!['journey'] is Map)
        ? (res.data!['journey'] as Map)['status']?.toString() ?? 'ACTIVE'
        : 'ACTIVE';
    if (status == 'COMPLETED') {
      _pollTimer?.cancel();
    }

    setState(() {
      _loading = false;
      _errorText = null;
      _errorCode = null;
      _payload = res.data;
      _lastPollAt = DateTime.now();
    });
  }

  Color _statusColor(String status, bool deviation) {
    if (status == 'EMERGENCY') return Colors.red.shade700;
    if (status == 'COMPLETED') return Colors.green.shade700;
    if (status == 'OVERDUE' || deviation) return Colors.orange.shade800;
    return Colors.teal.shade700;
  }

  String _statusHeadline(String status, bool deviation) {
    switch (status) {
      case 'EMERGENCY':
        return 'EMERGENCY SOS TRIGGERED';
      case 'COMPLETED':
        return 'REACHED DESTINATION SAFELY';
      case 'OVERDUE':
        return 'ETA OVERDUE - CHECK IN NEEDED';
      default:
        return deviation ? 'ROUTE DEVIATION DETECTED' : 'LIVE JOURNEY ACTIVE';
    }
  }

  String _formatLocalTime(String? iso) {
    if (iso == null || iso.isEmpty) return '--';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return iso;
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final ss = dt.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F6),
      appBar: AppBar(
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Row(
          children: [
            Icon(Icons.shield_rounded, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'SHE SHIELD — Guardian Live Track',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Live Location',
            onPressed: _fetchLive,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading && _payload == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.teal),
            SizedBox(height: 12),
            Text('Connecting to secure Guardian tracking feed...'),
          ],
        ),
      );
    }

    if (_errorText != null && _payload == null) {
      final isRevoked = _errorCode == 'SHARE_REVOKED';
      final isExpired = _errorCode == 'SHARE_EXPIRED';
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Card(
            margin: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isRevoked || isExpired ? Icons.link_off_rounded : Icons.error_outline,
                    size: 56,
                    color: isRevoked ? Colors.orange.shade800 : Colors.red.shade600,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    isRevoked
                        ? 'Tracking Link Stopped'
                        : isExpired
                            ? 'Tracking Link Expired'
                            : 'Invalid Tracking Link',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorText!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/welcome'),
                    icon: const Icon(Icons.home_outlined),
                    label: const Text('Return to SHE SHIELD Portal'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final payload = _payload!;
    final journey = Map<String, dynamic>.from(payload['journey'] as Map? ?? {});
    final travelerName = payload['travelerName']?.toString() ?? 'Traveler';
    final guardianName = payload['guardianName']?.toString() ?? 'Guardian';
    final status = journey['status']?.toString() ?? 'ACTIVE';
    final deviation = journey['deviationWarning'] == true;
    final deviationM = (journey['deviationMeters'] as num?)?.toDouble() ?? 0.0;
    final remainingM = (payload['remainingMeters'] as num?)?.toDouble() ?? 0.0;

    final startLat = (journey['startLatitude'] as num?)?.toDouble();
    final startLng = (journey['startLongitude'] as num?)?.toDouble();
    final destLat = (journey['destinationLatitude'] as num?)?.toDouble();
    final destLng = (journey['destinationLongitude'] as num?)?.toDouble();
    final lastLat = (journey['lastLatitude'] as num?)?.toDouble() ?? startLat;
    final lastLng = (journey['lastLongitude'] as num?)?.toDouble() ?? startLng;
    final lastAcc = (journey['lastAccuracy'] as num?)?.toDouble() ?? 0.0;

    final startPt = (startLat != null && startLng != null) ? LatLng(startLat, startLng) : null;
    final destPt = (destLat != null && destLng != null) ? LatLng(destLat, destLng) : null;
    final curPt = (lastLat != null && lastLng != null) ? LatLng(lastLat, lastLng) : destPt;

    final plannedPts = <LatLng>[];
    if (journey['routePolyline'] is List) {
      for (final item in journey['routePolyline'] as List) {
        if (item is List && item.length >= 2) {
          final a = (item[0] as num?)?.toDouble();
          final b = (item[1] as num?)?.toDouble();
          if (a != null && b != null) plannedPts.add(LatLng(a, b));
        }
      }
    }

    final trailPts = <LatLng>[];
    if (journey['locations'] is List) {
      for (final loc in journey['locations'] as List) {
        if (loc is Map) {
          final a = (loc['latitude'] as num?)?.toDouble();
          final b = (loc['longitude'] as num?)?.toDouble();
          if (a != null && b != null) trailPts.add(LatLng(a, b));
        }
      }
    }

    final statusClr = _statusColor(status, deviation);
    final markers = <Marker>[
      if (startPt != null)
        Marker(
          point: startPt,
          width: 34,
          height: 34,
          child: const CircleAvatar(
            backgroundColor: Colors.teal,
            child: Icon(Icons.trip_origin, size: 18, color: Colors.white),
          ),
        ),
      if (destPt != null)
        Marker(
          point: destPt,
          width: 38,
          height: 38,
          child: Icon(Icons.location_on, size: 36, color: Colors.red.shade700),
        ),
      if (curPt != null)
        Marker(
          point: curPt,
          width: 42,
          height: 42,
          child: Container(
            decoration: BoxDecoration(
              color: status == 'EMERGENCY' ? Colors.red.shade700 : Colors.blue.shade700,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
            ),
            child: const Icon(Icons.person_pin_circle, color: Colors.white, size: 22),
          ),
        ),
    ];

    final polylines = <Polyline>[
      if (plannedPts.length >= 2)
        Polyline(
          points: plannedPts,
          color: Colors.indigo.withValues(alpha: 0.45),
          strokeWidth: 4.5,
        ),
      if (trailPts.length >= 2)
        Polyline(
          points: trailPts,
          color: status == 'EMERGENCY' ? Colors.red.shade700 : Colors.teal.shade700,
          strokeWidth: 5.5,
        ),
    ];

    final fitList = <LatLng>[
      ...plannedPts,
      if (curPt != null) curPt,
      if (destPt != null) destPt,
    ];

    final eventsList = (journey['events'] is List)
        ? (journey['events'] as List).whereType<Map>().toList()
        : const <Map>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status Hero Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: statusClr.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: statusClr, width: 1.5),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: statusClr,
                      child: Icon(
                        status == 'COMPLETED'
                            ? Icons.check_rounded
                            : status == 'EMERGENCY'
                                ? Icons.sos
                                : Icons.shield_outlined,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _statusHeadline(status, deviation),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: statusClr,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Monitoring $travelerName • Shared for $guardianName',
                            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade800),
                          ),
                        ],
                      ),
                    ),
                    if (_lastPollAt != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Synced ${_formatLocalTime(_lastPollAt!.toIso8601String())}',
                          style: TextStyle(fontSize: 11, color: Colors.teal.shade900, fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Live Map
              if (curPt != null)
                LiveGoogleMapView(
                  center: curPt,
                  height: 360,
                  zoom: 14.5,
                  markers: markers,
                  polylines: polylines,
                  fitPoints: fitList,
                  fitBoundsKey: '${journey['id']}_${plannedPts.length}',
                  autoFollow: false,
                  title: 'Live Guardian Map',
                ),
              const SizedBox(height: 14),

              // Telemetry Grid
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Journey Telemetry',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      _infoRow('Destination', journey['destinationName']?.toString() ?? '--'),
                      _infoRow('Origin', journey['startLocationName']?.toString() ?? '--'),
                      _infoRow('Distance Remaining', TravelJourneyService.formatDistance(remainingM)),
                      _infoRow('Estimated Arrival', _formatLocalTime(journey['estimatedArrivalTime']?.toString())),
                      _infoRow(
                        'Last GPS Fix',
                        lastLat != null && lastLng != null
                            ? '${lastLat.toStringAsFixed(5)}, ${lastLng.toStringAsFixed(5)} (±${lastAcc.round()}m) at ${_formatLocalTime(journey['lastGpsAt']?.toString())}'
                            : 'No GPS coordinates yet',
                      ),
                      if (deviation)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.orange.shade400),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.alt_route, color: Colors.orange.shade800),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Current GPS position is ${deviationM.round()}m from the planned route corridor.',
                                  style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.w600, fontSize: 12.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Activity Timeline
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Live Journey Timeline',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      if (eventsList.isEmpty)
                        const Text('No timeline events recorded yet.')
                      else
                        ...eventsList.take(10).map((ev) {
                          final type = ev['eventType']?.toString() ?? '';
                          final details = ev['details']?.toString() ?? '';
                          final time = _formatLocalTime(ev['createdAt']?.toString());
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  type.contains('SOS')
                                      ? Icons.warning_rounded
                                      : Icons.fiber_manual_record,
                                  size: type.contains('SOS') ? 16 : 10,
                                  color: type.contains('SOS') ? Colors.red : Colors.teal,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '[$time] $details',
                                    style: const TextStyle(fontSize: 12.5),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildGuardianPortalActionCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuardianPortalActionCard(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    if (db.isAuthenticated && db.currentRole == 'guardian') {
      return Card(
        color: Colors.teal.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.teal.shade300),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.shield, color: Colors.teal.shade800),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Signed in as Guardian. Pin this shared journey to your Guardian Dashboard?',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white),
                onPressed: () async {
                  final res = await _api.claimGuardianShare(widget.token);
                  if (!context.mounted) return;
                  if (res.success) {
                    Navigator.pushNamedAndRemoveUntil(context, '/guardian_dashboard', (_) => false);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(res.error ?? 'Could not link share.'), backgroundColor: Colors.red.shade700),
                    );
                  }
                },
                child: const Text('Pin to Portal'),
              ),
            ],
          ),
        ),
      );
    }

    if (!db.isAuthenticated) {
      return Card(
        color: Colors.teal.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.teal.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you the invited Guardian?',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
              ),
              const SizedBox(height: 4),
              const Text(
                'Register as a Guardian to accept this tracking link inside your Guardian Dashboard, or sign in with your Guardian account.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white),
                    onPressed: () => Navigator.pushNamed(
                      context,
                      '/register_user?share=${Uri.encodeComponent(widget.token)}',
                    ),
                    icon: const Icon(Icons.person_add_alt_1, size: 16),
                    label: const Text('Register as Guardian'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    icon: const Icon(Icons.login, size: 16),
                    label: const Text('Guardian Sign In'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
