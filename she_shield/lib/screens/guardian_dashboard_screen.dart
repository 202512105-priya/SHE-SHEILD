import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/local_database_service.dart';
import '../services/travel_journey_service.dart';
import '../widgets/live_google_map_view.dart';
import '../services/geo_platform_stub.dart'
    if (dart.library.io) '../services/geo_platform_io.dart'
    if (dart.library.js_interop) '../services/geo_platform_web.dart';

class GuardianDashboardScreen extends StatefulWidget {
  const GuardianDashboardScreen({super.key});

  @override
  State<GuardianDashboardScreen> createState() => _GuardianDashboardScreenState();
}

class _GuardianDashboardScreenState extends State<GuardianDashboardScreen> {
  final LocalDatabaseService _api = LocalDatabaseService();
  Timer? _pollTimer;

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _dashboard;
  DateTime? _lastSyncedAt;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadDashboard(silent: true));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboard({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    final res = await _api.getGuardianDashboard();
    if (!mounted) return;
    if (!res.success || res.data == null) {
      setState(() {
        _loading = false;
        _error = res.error ?? 'Failed to load Guardian Portal data.';
      });
      return;
    }
    setState(() {
      _loading = false;
      _error = null;
      _dashboard = res.data;
      _lastSyncedAt = DateTime.now();
    });
  }

  Color _statusLabelColor(String label) {
    if (label.startsWith('RED')) return Colors.red.shade700;
    if (label.startsWith('ORANGE')) return Colors.orange.shade800;
    if (label.startsWith('GREEN')) return Colors.teal.shade700;
    if (label.startsWith('BLUE')) return Colors.blue.shade700;
    return Colors.blueGrey.shade600;
  }

  String _formatTs(String? iso) {
    if (iso == null || iso.isEmpty) return '--';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return iso;
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final ss = dt.second.toString().padLeft(2, '0');
    return '${dt.month}/${dt.day} $hh:$mm:$ss';
  }

  Future<void> _respondToInvite(Map<String, dynamic> inv, String action) async {
    final res = await _api.respondGuardianInvitation(
      itemId: inv['id'].toString(),
      action: action,
      inviteKind: inv['inviteKind']?.toString() ?? '',
    );
    if (!mounted) return;
    if (res.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action == 'accept'
                ? 'Accepted connection with ${inv['senderName']}!'
                : 'Invitation declined.',
          ),
          backgroundColor: action == 'accept' ? Colors.teal.shade700 : Colors.grey.shade800,
        ),
      );
      await _loadDashboard();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.error ?? 'Failed to process response.'), backgroundColor: Colors.red.shade700),
      );
    }
  }

  Future<void> _openGoogleMaps(double? lat, double? lng) async {
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No GPS coordinates available for Maps launch.')),
      );
      return;
    }
    final url = 'https://www.google.com/maps/search/?api=1&query=${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';
    final opened = await platformOpenExternalUrl(url);
    if (!opened && mounted) {
      await Clipboard.setData(ClipboardData(text: url));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Maps URL copied to clipboard.')),
      );
    }
  }

  Future<void> _contactUser(String name, String phone) async {
    final cleaned = phone.trim();
    if (cleaned.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No phone number available for $name.')),
      );
      return;
    }
    final launched = await platformOpenExternalUrl('tel:$cleaned');
    if (!launched && mounted) {
      await Clipboard.setData(ClipboardData(text: cleaned));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Call $name: $cleaned (copied to clipboard)')),
      );
    }
  }

  Future<void> _showNotificationsSheet(List<Map<String, dynamic>> notifications) async {
    await _api.markGuardianNotificationsRead();
    await _loadDashboard(silent: true);
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Guardian Alerts & Notifications', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            if (notifications.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('No notifications recorded yet.'),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final n = notifications[i];
                    final type = n['notificationType']?.toString() ?? '';
                    final isSos = type.contains('SOS') || type.contains('EMERGENCY');
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        isSos ? Icons.sos : (type.contains('OVERDUE') ? Icons.schedule : Icons.notifications),
                        color: isSos ? Colors.red.shade700 : (type.contains('OVERDUE') ? Colors.orange.shade800 : Colors.teal),
                      ),
                      title: Text(n['message']?.toString() ?? '', style: const TextStyle(fontSize: 13)),
                      subtitle: Text(
                        '${_formatTs(n['createdAt']?.toString())} • Delivery: ${n['deliveryStatus'] ?? 'IN_APP'}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    final dash = _dashboard ?? const <String, dynamic>{};
    final guardianInfo = (dash['guardian'] is Map)
        ? Map<String, dynamic>.from(dash['guardian'] as Map)
        : <String, dynamic>{};
    final stats = (dash['stats'] is Map)
        ? Map<String, dynamic>.from(dash['stats'] as Map)
        : <String, dynamic>{};

    final connectedUsers = _toMapList(dash['connectedUsers']);
    final pendingInvitations = _toMapList(dash['pendingInvitations']);
    final activeJourneys = _toMapList(dash['activeJourneys']);
    final completedJourneys = _toMapList(dash['completedJourneys']);
    final emergencyAlerts = _toMapList(dash['emergencyAlerts']);
    final notifications = _toMapList(dash['notifications']);

    final guardianName = guardianInfo['fullName']?.toString() ?? (db.userName.isNotEmpty ? db.userName : 'Guardian');
    final accountStatus = guardianInfo['accountStatus']?.toString() ?? (db.accountStatus.isNotEmpty ? db.accountStatus : 'ACTIVE');
    final unreadCount = (stats['unreadNotificationsCount'] as num?)?.toInt() ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F6),
      appBar: AppBar(
        title: const Text('Guardian Protection Portal'),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                tooltip: 'Notifications',
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => _showNotificationsSheet(notifications),
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            tooltip: 'Refresh Live Data',
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboard,
          ),
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await db.logout();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(context, '/welcome', (_) => false);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: _loading && _dashboard == null
            ? const Center(child: CircularProgressIndicator(color: Colors.teal))
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_error != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.shade300),
                            ),
                            child: Text(_error!, style: TextStyle(color: Colors.red.shade900)),
                          ),

                        // 1. Dashboard Header Card
                        _buildHeaderCard(
                          guardianName: guardianName,
                          accountStatus: accountStatus,
                          stats: stats,
                        ),
                        const SizedBox(height: 16),

                        // 2. Emergency Alerts Section (highlighted when open or historical alerts exist)
                        if (emergencyAlerts.isNotEmpty) ...[
                          _buildEmergencyAlertsSection(emergencyAlerts),
                          const SizedBox(height: 16),
                        ],

                        // 3. Pending Invitations Section
                        _buildPendingInvitationsSection(pendingInvitations),
                        const SizedBox(height: 16),

                        // 4. Live Active Journeys Monitoring Section
                        _buildActiveJourneysSection(activeJourneys),
                        const SizedBox(height: 16),

                        // 5. Connected Users Section
                        _buildConnectedUsersSection(connectedUsers),
                        const SizedBox(height: 16),

                        // 6. Recently Completed Journeys Section
                        _buildCompletedJourneysSection(completedJourneys),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  List<Map<String, dynamic>> _toMapList(dynamic raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Widget _buildHeaderCard({
    required String guardianName,
    required String accountStatus,
    required Map<String, dynamic> stats,
  }) {
    final isActive = accountStatus.toUpperCase() == 'ACTIVE';
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.teal.shade100,
                  child: Icon(Icons.shield_rounded, color: Colors.teal.shade800, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, $guardianName',
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Colors.teal.shade900),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.green.shade100 : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Guardian Account Status: ${isActive ? 'Active' : accountStatus}',
                              style: TextStyle(
                                color: isActive ? Colors.green.shade800 : Colors.red.shade800,
                                fontWeight: FontWeight.w700,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                          if (_lastSyncedAt != null)
                            Text(
                              'Live Sync: ${_formatTs(_lastSyncedAt!.toIso8601String())}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _statBox(
                  label: 'Connected Users',
                  value: '${stats['connectedUsersCount'] ?? 0}',
                  icon: Icons.people_outline,
                  color: Colors.teal.shade700,
                ),
                _statBox(
                  label: 'Active Journeys',
                  value: '${stats['activeJourneysCount'] ?? 0}',
                  icon: Icons.directions_car_outlined,
                  color: Colors.green.shade700,
                ),
                _statBox(
                  label: 'Pending Invitations',
                  value: '${stats['pendingInvitationsCount'] ?? 0}',
                  icon: Icons.mark_email_unread_outlined,
                  color: Colors.orange.shade800,
                ),
                _statBox(
                  label: 'Emergency Alerts',
                  value: '${stats['emergencyAlertsCount'] ?? 0}',
                  icon: Icons.sos_outlined,
                  color: ((stats['emergencyAlertsCount'] as num?)?.toInt() ?? 0) > 0
                      ? Colors.red.shade700
                      : Colors.blueGrey.shade600,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBox({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 210,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
                Text(label, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyAlertsSection(List<Map<String, dynamic>> alerts) {
    final openCount = alerts.where((a) => a['resolved'] != true).length;
    return Card(
      color: openCount > 0 ? Colors.red.shade50 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: openCount > 0 ? Colors.red.shade600 : Colors.grey.shade300, width: openCount > 0 ? 1.8 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emergency_share, color: openCount > 0 ? Colors.red.shade700 : Colors.grey.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    openCount > 0
                        ? 'EMERGENCY ALERTS ($openCount ACTIVE SOS)'
                        : 'Emergency Alert History',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: openCount > 0 ? Colors.red.shade900 : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...alerts.map((a) {
              final resolved = a['resolved'] == true;
              final lat = (a['latitude'] as num?)?.toDouble();
              final lng = (a['longitude'] as num?)?.toDouble();
              final phone = a['userPhone']?.toString() ?? '';
              final uName = a['userName']?.toString() ?? 'Connected User';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: resolved ? Colors.grey.shade300 : Colors.red.shade400),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '$uName • SOS ${a['sosId']}',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                              color: resolved ? Colors.black87 : Colors.red.shade800,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: resolved ? Colors.green.shade100 : Colors.red.shade700,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            resolved ? 'RESOLVED' : (a['status']?.toString() ?? 'OPEN'),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: resolved ? Colors.green.shade900 : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Time: ${_formatTs(a['timestamp']?.toString())}', style: const TextStyle(fontSize: 12.5)),
                    Text('Last GPS: ${a['gps'] ?? 'Unavailable'}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                    if (a['destinationName'] != null)
                      Text(
                        'Journey: ${a['startLocationName'] ?? 'Origin'} -> ${a['destinationName']}',
                        style: const TextStyle(fontSize: 12.5),
                      )
                    else if (a['locationName'] != null)
                      Text('Location Info: ${a['locationName']}', style: const TextStyle(fontSize: 12.5)),
                    if (!resolved && lat != null && lng != null) ...[
                      const SizedBox(height: 10),
                      LiveGoogleMapView(
                        center: LatLng(lat, lng),
                        height: 170,
                        zoom: 15.0,
                        markers: [
                          Marker(
                            point: LatLng(lat, lng),
                            width: 40,
                            height: 40,
                            child: Icon(Icons.sos, color: Colors.red.shade700, size: 32),
                          ),
                        ],
                        title: 'SOS Pin: $uName',
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white),
                          onPressed: () => _contactUser(uName, phone),
                          icon: const Icon(Icons.call, size: 16),
                          label: Text(phone.isNotEmpty ? 'Contact ($phone)' : 'Contact User'),
                        ),
                        if (lat != null && lng != null)
                          OutlinedButton.icon(
                            onPressed: () => _openGoogleMaps(lat, lng),
                            icon: const Icon(Icons.map_outlined, size: 16),
                            label: const Text('Open in Google Maps'),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingInvitationsSection(List<Map<String, dynamic>> pendingInvitations) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.mail_outline, color: Colors.teal.shade800),
                const SizedBox(width: 8),
                Text(
                  'Pending Invitations (${pendingInvitations.length})',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.teal.shade900),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (pendingInvitations.isEmpty)
              Text(
                'No pending guardian connection requests right now.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              )
            else
              ...pendingInvitations.map((inv) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.teal.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          inv['senderName']?.toString() ?? 'SHE SHIELD User',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Relationship: ${inv['relationship'] ?? 'Guardian'} • Type: ${inv['invitationType'] ?? 'Request'}',
                          style: const TextStyle(fontSize: 12.5),
                        ),
                        Text(
                          'Invited: ${_formatTs(inv['createdAt']?.toString())}',
                          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white),
                              onPressed: () => _respondToInvite(inv, 'accept'),
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text('Accept'),
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700),
                              onPressed: () => _respondToInvite(inv, 'decline'),
                              icon: const Icon(Icons.close, size: 16),
                              label: const Text('Decline'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveJourneysSection(List<Map<String, dynamic>> activeJourneys) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.route, color: Colors.teal.shade800),
                const SizedBox(width: 8),
                Text(
                  'Live Shared Journeys (${activeJourneys.length})',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.teal.shade900),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (activeJourneys.isEmpty)
              Text(
                'No connected user currently has an active Safe Arrival journey.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              )
            else
              ...activeJourneys.map((j) {
                final badge = j['statusBadge']?.toString() ?? 'GREEN – Journey Active';
                final badgeClr = _statusLabelColor(badge);
                final destLat = (j['destinationLatitude'] as num?)?.toDouble();
                final destLng = (j['destinationLongitude'] as num?)?.toDouble();
                final curLat = (j['lastLatitude'] as num?)?.toDouble() ?? (j['startLatitude'] as num?)?.toDouble();
                final curLng = (j['lastLongitude'] as num?)?.toDouble() ?? (j['startLongitude'] as num?)?.toDouble();
                final plannedPts = _extractPolyline(j['routePolyline']);
                final trailPts = _extractTrail(j['locations']);
                final remM = (j['remainingMeters'] as num?)?.toDouble() ?? 0.0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: badgeClr.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: badgeClr, width: 1.4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${j['userName'] ?? 'User'} • ${j['relationship'] ?? 'Connected'}',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: badgeClr,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Destination: ${j['destinationName'] ?? '--'}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(
                        'Remaining: ${TravelJourneyService.formatDistance(remM)} • ETA: ${_formatTs(j['estimatedArrivalTime']?.toString())} • Last GPS: ${_formatTs(j['lastGpsAt']?.toString())}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                      ),
                      if (curLat != null && curLng != null) ...[
                        const SizedBox(height: 10),
                        LiveGoogleMapView(
                          center: LatLng(curLat, curLng),
                          height: 190,
                          zoom: 14.0,
                          markers: [
                            if (destLat != null && destLng != null)
                              Marker(
                                point: LatLng(destLat, destLng),
                                width: 34,
                                height: 34,
                                child: Icon(Icons.location_on, color: Colors.red.shade700, size: 32),
                              ),
                            Marker(
                              point: LatLng(curLat, curLng),
                              width: 36,
                              height: 36,
                              child: Icon(Icons.person_pin_circle, color: badgeClr, size: 32),
                            ),
                          ],
                          polylines: [
                            if (plannedPts.length >= 2)
                              Polyline(points: plannedPts, color: Colors.indigo.withValues(alpha: 0.45), strokeWidth: 4),
                            if (trailPts.length >= 2)
                              Polyline(points: trailPts, color: badgeClr, strokeWidth: 5),
                          ],
                          fitPoints: [...plannedPts, LatLng(curLat, curLng), if (destLat != null && destLng != null) LatLng(destLat, destLng)],
                          fitBoundsKey: '${j['id']}_${plannedPts.length}',
                          autoFollow: false,
                        ),
                      ],
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 44),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => _GuardianLiveJourneyDetailScreen(
                                journeyId: j['id'].toString(),
                                initialJourney: j,
                              ),
                            ),
                          ).then((_) => _loadDashboard());
                        },
                        icon: const Icon(Icons.visibility_outlined),
                        label: const Text('VIEW LIVE JOURNEY', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectedUsersSection(List<Map<String, dynamic>> users) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.group_outlined, color: Colors.teal.shade800),
                const SizedBox(width: 8),
                Text(
                  'Connected Users (${users.length})',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.teal.shade900),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (users.isEmpty)
              Text(
                'No connected users yet. When a user connects with your Guardian account or shares a journey link, they will appear here.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              )
            else
              ...users.map((u) {
                final statusLabel = u['statusLabel']?.toString() ?? 'GREY – No Active Journey';
                final clr = _statusLabelColor(statusLabel);
                final latest = u['latestJourney'] is Map ? Map<String, dynamic>.from(u['latestJourney'] as Map) : null;
                final isEmergency = u['hasOpenEmergency'] == true || statusLabel.startsWith('RED');

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isEmergency ? Colors.red.shade50 : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isEmergency ? Colors.red.shade600 : clr.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: clr.withValues(alpha: 0.16),
                            child: Text(
                              (u['fullName']?.toString() ?? 'U').substring(0, 1).toUpperCase(),
                              style: TextStyle(color: clr, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(u['fullName']?.toString() ?? 'User', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                                Text(
                                  '${u['relationship'] ?? 'Guardian'} • Tracking: ${u['trackingStatus'] ?? 'Idle'}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: clr.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: clr),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(color: clr, fontWeight: FontWeight.w800, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (latest == null)
                        Text(
                          'Connection Active (${u['connectionStatus'] == 'SHARED_JOURNEY_ONLY' ? 'Temporary Share' : 'Accepted Guardian'}) • No active Safe Arrival journey.',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        )
                      else ...[
                        Text('Destination: ${latest['destinationName'] ?? '--'}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                        Text(
                          'Start: ${_formatTs(latest['startTime']?.toString())} • ETA: ${_formatTs(latest['estimatedArrivalTime']?.toString())} • Last GPS: ${_formatTs(latest['lastGpsAt']?.toString())}',
                          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                        ),
                      ],
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedJourneysSection(List<Map<String, dynamic>> completed) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified_outlined, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Recently Completed Journeys (${completed.length})',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.teal.shade900),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (completed.isEmpty)
              Text(
                'Completed Safe Arrival trips will appear here once connected users confirm safe arrival.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              )
            else
              ...completed.map((j) {
                final verified = j['arrivalVerified'] == true;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(Icons.check_rounded, color: Colors.blue.shade800),
                  ),
                  title: Text('${j['userName'] ?? 'User'} -> ${j['destinationName'] ?? '--'}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  subtitle: Text(
                    'BLUE – Safely Arrived • Arrived: ${_formatTs(j['actualArrivalTime']?.toString())}'
                    '${verified ? ' • GPS Verified' : ' • Manual Confirmation'}',
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  static List<LatLng> _extractPolyline(dynamic raw) {
    final pts = <LatLng>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is List && item.length >= 2) {
          final lat = (item[0] as num?)?.toDouble();
          final lng = (item[1] as num?)?.toDouble();
          if (lat != null && lng != null) pts.add(LatLng(lat, lng));
        }
      }
    }
    return pts;
  }

  static List<LatLng> _extractTrail(dynamic raw) {
    final pts = <LatLng>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          final lat = (item['latitude'] as num?)?.toDouble();
          final lng = (item['longitude'] as num?)?.toDouble();
          if (lat != null && lng != null) pts.add(LatLng(lat, lng));
        }
      }
    }
    return pts;
  }
}

// =============================================================================
// DETAILED LIVE JOURNEY TRACKING SCREEN FOR GUARDIAN
// =============================================================================
class _GuardianLiveJourneyDetailScreen extends StatefulWidget {
  final String journeyId;
  final Map<String, dynamic> initialJourney;

  const _GuardianLiveJourneyDetailScreen({
    required this.journeyId,
    required this.initialJourney,
  });

  @override
  State<_GuardianLiveJourneyDetailScreen> createState() => _GuardianLiveJourneyDetailScreenState();
}

class _GuardianLiveJourneyDetailScreenState extends State<_GuardianLiveJourneyDetailScreen> {
  final LocalDatabaseService _api = LocalDatabaseService();
  Timer? _pollTimer;
  Timer? _clockTimer;
  late Map<String, dynamic> _journey;
  String? _error;

  @override
  void initState() {
    super.initState();
    _journey = widget.initialJourney;
    _fetchDetail();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _fetchDetail());
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchDetail() async {
    final res = await _api.getGuardianJourneyDetail(widget.journeyId);
    if (!mounted) return;
    if (res.success && res.data != null && res.data!['journey'] is Map) {
      setState(() {
        _error = null;
        _journey = Map<String, dynamic>.from(res.data!['journey'] as Map);
      });
    } else if (!res.success) {
      setState(() => _error = res.error ?? 'Access revoked or journey unavailable.');
      if (res.statusCode == 403 || res.statusCode == 404) {
        _pollTimer?.cancel();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final j = _journey;
    final st = j['status']?.toString() ?? 'ACTIVE';
    final isEmergency = st == 'EMERGENCY';
    final isCompleted = st == 'COMPLETED';
    final isOverdue = st == 'OVERDUE' || j['deviationWarning'] == true;
    final statusClr = isEmergency
        ? Colors.red.shade700
        : (isCompleted ? Colors.blue.shade700 : (isOverdue ? Colors.orange.shade800 : Colors.teal.shade700));

    final etaDt = DateTime.tryParse(j['estimatedArrivalTime']?.toString() ?? '')?.toUtc();
    final remainingDur = etaDt != null ? etaDt.difference(DateTime.now().toUtc()) : Duration.zero;
    final countdownStr = isCompleted ? 'SAFELY ARRIVED' : TravelJourneyService.formatCountdown(remainingDur);

    final startLat = (j['startLatitude'] as num?)?.toDouble();
    final startLng = (j['startLongitude'] as num?)?.toDouble();
    final destLat = (j['destinationLatitude'] as num?)?.toDouble();
    final destLng = (j['destinationLongitude'] as num?)?.toDouble();
    final curLat = (j['lastLatitude'] as num?)?.toDouble() ?? startLat;
    final curLng = (j['lastLongitude'] as num?)?.toDouble() ?? startLng;
    final curPt = (curLat != null && curLng != null) ? LatLng(curLat, curLng) : const LatLng(23.0225, 72.5714);
    final plannedPts = _GuardianDashboardScreenState._extractPolyline(j['routePolyline']);
    final trailPts = _GuardianDashboardScreenState._extractTrail(j['locations']);

    final remM = (j['remainingMeters'] as num?)?.toDouble() ?? 0.0;
    final travM = (j['traveledMeters'] as num?)?.toDouble() ?? 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F6),
      appBar: AppBar(
        title: Text('Live Monitor: ${j['userName'] ?? 'User'}'),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _fetchDetail, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade400),
                    ),
                    child: Text(_error!, style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.w700)),
                  ),

                // Countdown & Status Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: statusClr,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Text(
                        countdownStr,
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$st • Destination: ${j['destinationName'] ?? '--'}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Large Interactive Live Map
                LiveGoogleMapView(
                  center: curPt,
                  height: 360,
                  zoom: 14.5,
                  markers: [
                    if (startLat != null && startLng != null)
                      Marker(
                        point: LatLng(startLat, startLng),
                        width: 34,
                        height: 34,
                        child: const CircleAvatar(backgroundColor: Colors.teal, child: Icon(Icons.trip_origin, size: 18, color: Colors.white)),
                      ),
                    if (destLat != null && destLng != null)
                      Marker(
                        point: LatLng(destLat, destLng),
                        width: 38,
                        height: 38,
                        child: Icon(Icons.location_on, color: Colors.red.shade700, size: 36),
                      ),
                    Marker(
                      point: curPt,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: statusClr,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(Icons.navigation, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                  polylines: [
                    if (plannedPts.length >= 2)
                      Polyline(points: plannedPts, color: Colors.indigo.withValues(alpha: 0.45), strokeWidth: 4.5),
                    if (trailPts.length >= 2)
                      Polyline(points: trailPts, color: statusClr, strokeWidth: 5.5),
                  ],
                  fitPoints: [...plannedPts, curPt, if (destLat != null && destLng != null) LatLng(destLat, destLng)],
                  fitBoundsKey: '${j['id']}_${plannedPts.length}',
                  autoFollow: false,
                ),
                const SizedBox(height: 14),

                // Metrics Card
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Live Journey Telemetry', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 10),
                        _detailRow('Current Status', st),
                        _detailRow('Distance Travelled', TravelJourneyService.formatDistance(travM)),
                        _detailRow('Distance Remaining', TravelJourneyService.formatDistance(remM)),
                        _detailRow('Origin', j['startLocationName']?.toString() ?? '--'),
                        _detailRow('Destination', j['destinationName']?.toString() ?? '--'),
                        _detailRow('Last GPS Sync', j['lastGpsAt']?.toString() ?? 'Unavailable'),
                        if (j['lastLatitude'] != null && j['lastLongitude'] != null)
                          _detailRow(
                            'Last Coordinates',
                            '${(j['lastLatitude'] as num).toStringAsFixed(5)}, ${(j['lastLongitude'] as num).toStringAsFixed(5)} (±${(j['lastAccuracy'] as num? ?? 0).round()}m)',
                          ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            if ((j['userPhone']?.toString() ?? '').isNotEmpty)
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white),
                                onPressed: () => platformOpenExternalUrl('tel:${j['userPhone']}'),
                                icon: const Icon(Icons.call, size: 16),
                                label: Text('Call ${j['userName'] ?? 'User'}'),
                              ),
                            if (curLat != null && curLng != null)
                              OutlinedButton.icon(
                                onPressed: () => platformOpenExternalUrl(
                                  'https://www.google.com/maps/search/?api=1&query=${curLat.toStringAsFixed(6)},${curLng.toStringAsFixed(6)}',
                                ),
                                icon: const Icon(Icons.map_outlined, size: 16),
                                label: const Text('Open in Google Maps'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 150, child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }
}
