import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/travel_journey_service.dart';
import '../widgets/live_google_map_view.dart';

// ==========================================
// 1. SAFE ARRIVAL TRAVEL MODE SCREEN
// ==========================================
class TravelMonitorScreen extends StatefulWidget {
  const TravelMonitorScreen({super.key});

  @override
  State<TravelMonitorScreen> createState() => _TravelMonitorScreenState();
}

class _TravelMonitorScreenState extends State<TravelMonitorScreen> {
  final TravelJourneyService _journeyService = TravelJourneyService();
  final TextEditingController _originSearchController = TextEditingController();
  final TextEditingController _destSearchController = TextEditingController();
  final TextEditingController _durationController = TextEditingController(text: '30');

  Timer? _originDebounce;
  Timer? _destDebounce;
  List<PlaceSuggestion> _originSuggestions = <PlaceSuggestion>[];
  List<PlaceSuggestion> _destSuggestions = <PlaceSuggestion>[];
  bool _searchingOrigin = false;
  bool _searchingDest = false;
  String? _originSearchError;
  String? _destSearchError;

  String _selectedRecordingMode = 'Audio Only';
  bool _autoFollowMap = true;
  bool _showOriginSearchField = false;

  @override
  void initState() {
    super.initState();
    _initTravel();
  }

  Future<void> _initTravel() async {
    await _journeyService.initializeAndRestore();
    if (!mounted) return;
    if (!_journeyService.hasActiveJourney && !_journeyService.gpsPermissionGranted) {
      await _journeyService.captureCurrentLocation();
    } else if (_journeyService.estimatedDurationMinutes > 0) {
      _durationController.text = _journeyService.estimatedDurationMinutes.toString();
    }
    if (_journeyService.hasActiveJourney) {
      _selectedRecordingMode = _journeyService.recordingMode;
      _durationController.text = _journeyService.estimatedDurationMinutes.toString();
    }
  }

  @override
  void dispose() {
    _originDebounce?.cancel();
    _destDebounce?.cancel();
    _originSearchController.dispose();
    _destSearchController.dispose();
    _durationController.dispose();
    _journeyService.dispose();
    super.dispose();
  }

  void _onOriginSearchChanged(String val) {
    _originDebounce?.cancel();
    final trimmed = val.trim();
    if (trimmed.length < 2) {
      setState(() {
        _originSuggestions = <PlaceSuggestion>[];
        _originSearchError = null;
        _searchingOrigin = false;
      });
      return;
    }
    setState(() {
      _searchingOrigin = true;
      _originSearchError = null;
    });
    _originDebounce = Timer(const Duration(milliseconds: 400), () async {
      final res = await _journeyService.searchLocations(trimmed);
      if (!mounted) return;
      setState(() {
        _searchingOrigin = false;
        _originSuggestions = res.results;
        _originSearchError = res.error ?? (res.results.isEmpty ? 'No matching starting location found.' : null);
      });
    });
  }

  void _onDestSearchChanged(String val) {
    _destDebounce?.cancel();
    final trimmed = val.trim();
    if (trimmed.length < 2) {
      setState(() {
        _destSuggestions = <PlaceSuggestion>[];
        _destSearchError = null;
        _searchingDest = false;
      });
      return;
    }
    setState(() {
      _searchingDest = true;
      _destSearchError = null;
    });
    _destDebounce = Timer(const Duration(milliseconds: 400), () async {
      final res = await _journeyService.searchLocations(trimmed);
      if (!mounted) return;
      setState(() {
        _searchingDest = false;
        _destSuggestions = res.results;
        _destSearchError = res.error ?? (res.results.isEmpty ? 'No matching destination found.' : null);
      });
    });
  }

  void _showRecordingModeModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Blackbox Evidence Mode',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Permission is explicitly requested before any recording starts.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            _recordingOptionTile(
              ctx: ctx,
              value: 'Audio Only',
              icon: Icons.mic,
              color: Colors.teal,
              title: 'Audio Only (Verified Microphone)',
              subtitle: 'Records encrypted ambient audio & saves SHA-256 evidence to Vault',
            ),
            const Divider(),
            _recordingOptionTile(
              ctx: ctx,
              value: 'Video & Audio',
              icon: Icons.videocam,
              color: Colors.purple,
              title: 'Video & Audio',
              subtitle: 'Requests microphone permission (audio blackbox on Web)',
            ),
            const Divider(),
            _recordingOptionTile(
              ctx: ctx,
              value: 'None',
              icon: Icons.location_searching,
              color: Colors.blueGrey,
              title: 'None (GPS Telemetry Only)',
              subtitle: 'Live GPS tracking, countdown, and guardian alerts without audio capture',
            ),
          ],
        ),
      ),
    );
  }

  Widget _recordingOptionTile({
    required BuildContext ctx,
    required String value,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    final selected = _selectedRecordingMode == value;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: selected ? Icon(Icons.check_circle, color: color) : null,
      onTap: () {
        setState(() => _selectedRecordingMode = value);
        Navigator.pop(ctx);
      },
    );
  }

  Future<void> _handleStartJourney(DatabaseService db) async {
    final estMins = int.tryParse(_durationController.text.trim()) ??
        _journeyService.selectedRoute?.durationMinutes ??
        0;
    final res = await _journeyService.startJourney(
      durationMinutes: estMins,
      recordingMode: _selectedRecordingMode,
      db: db,
    );
    if (!mounted) return;
    if (!res.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.error ?? 'Could not start journey.'), backgroundColor: Colors.red.shade700),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Safe Arrival tracking is now LIVE!'),
        backgroundColor: Colors.teal.shade700,
      ),
    );
  }

  String _fullShareUrl(String sharePath) {
    final cleanPath = sharePath.startsWith('#') ? sharePath : '#$sharePath';
    try {
      final base = Uri.base;
      if (base.scheme == 'http' || base.scheme == 'https') {
        return '${base.origin}/$cleanPath';
      }
    } catch (_) {}
    return cleanPath;
  }

  Future<void> _openShareJourneySheet() async {
    await _journeyService.refreshGuardians();
    if (!mounted) return;
    final selectedIds = <String>{};
    if (_journeyService.guardians.isNotEmpty) {
      selectedIds.add(_journeyService.guardians.first.id);
    }
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final relCtrl = TextEditingController(text: 'Family');
    bool showAddForm = _journeyService.guardians.isEmpty;
    ShareRecordInfo? latestShare;
    String? latestError;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.share_location, color: Colors.teal.shade800),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Share Live Journey with Guardian',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Creates an unguessable expiring tracking link stored in Cloud Database.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),

                  if (_journeyService.guardians.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Select Linked Guardians', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        TextButton.icon(
                          onPressed: () => setSheetState(() => showAddForm = !showAddForm),
                          icon: Icon(showAddForm ? Icons.remove : Icons.person_add_alt, size: 16),
                          label: Text(showAddForm ? 'Hide New Contact' : 'Add New Guardian'),
                        ),
                      ],
                    ),
                    ..._journeyService.guardians.map((g) {
                      final checked = selectedIds.contains(g.id);
                      return CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        activeColor: Colors.teal.shade700,
                        value: checked,
                        title: Text(g.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${g.relationship} • ${g.phone.isNotEmpty ? g.phone : g.email}'),
                        onChanged: (v) {
                          setSheetState(() {
                            if (v == true) {
                              selectedIds.add(g.id);
                            } else {
                              selectedIds.remove(g.id);
                            }
                          });
                        },
                      );
                    }),
                  ],

                  if (showAddForm) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.teal.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Guardian Contact Details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Guardian Name',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    labelText: 'Email (optional)',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 110,
                                child: TextField(
                                  controller: relCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Relation',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (latestError != null) ...[
                    const SizedBox(height: 10),
                    Text(latestError!, style: TextStyle(color: Colors.red.shade700, fontSize: 12.5)),
                  ],

                  if (latestShare != null && latestShare!.sharePath != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: latestShare!.deliveryStatus == 'SENT' ? Colors.green.shade50 : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: latestShare!.deliveryStatus == 'SENT' ? Colors.green : Colors.orange.shade400,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            latestShare!.deliveryStatus == 'SENT'
                                ? 'Guardian Link Sent & Active'
                                : 'Secure Link Ready (Manual Share Required)',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(latestShare!.deliveryMessage, style: const TextStyle(fontSize: 12)),
                          const SizedBox(height: 8),
                          SelectableText(
                            _fullShareUrl(latestShare!.sharePath!),
                            style: TextStyle(fontSize: 12, color: Colors.teal.shade900, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white),
                                onPressed: () async {
                                  await Clipboard.setData(ClipboardData(text: _fullShareUrl(latestShare!.sharePath!)));
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      const SnackBar(content: Text('Tracking link copied to clipboard')),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.copy, size: 16),
                                label: const Text('Copy Link'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () {
                                  final routeTarget = latestShare!.sharePath!.replaceFirst('#', '');
                                  Navigator.pop(ctx);
                                  Navigator.pushNamed(context, routeTarget);
                                },
                                icon: const Icon(Icons.open_in_new, size: 16),
                                label: const Text('Open Guardian View'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    onPressed: _journeyService.isBusy
                        ? null
                        : () async {
                            final res = await _journeyService.shareWithGuardians(
                              guardianIds: selectedIds.toList(),
                              inlineName: showAddForm ? nameCtrl.text : null,
                              inlinePhone: showAddForm ? phoneCtrl.text : null,
                              inlineEmail: showAddForm ? emailCtrl.text : null,
                              inlineRelationship: showAddForm ? relCtrl.text : null,
                            );
                            if (!ctx.mounted) return;
                            setSheetState(() {
                              latestShare = res.share;
                              latestError = res.error;
                            });
                          },
                    icon: const Icon(Icons.link),
                    label: Text(_journeyService.isBusy ? 'Generating Secure Share...' : 'Generate Secure Share Link'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmEmergencySos() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Icon(Icons.sos_rounded, color: Colors.red.shade700, size: 30),
            const SizedBox(width: 8),
            const Expanded(child: Text('Trigger Travel SOS Emergency?')),
          ],
        ),
        content: Text(
          'This immediately creates an active CRITICAL SOS incident in the police responder console with your latest real GPS coordinates '
          '(${_journeyService.currentGps != null ? '${_journeyService.currentGps!.latitude.toStringAsFixed(5)}, ${_journeyService.currentGps!.longitude.toStringAsFixed(5)}' : 'Unavailable'}) '
          'and your destination (${_journeyService.displayDestName}).',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('CONFIRM SOS'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    final res = await _journeyService.triggerEmergencySos();
    if (!mounted) return;

    if (!res.ok || res.data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.error ?? 'SOS trigger failed.'), backgroundColor: Colors.red.shade800),
      );
      return;
    }

    final sosId = res.data!['sosCaseId']?.toString() ?? 'SOS';
    final notif = (res.data!['guardianNotification'] is Map)
        ? Map<String, dynamic>.from(res.data!['guardianNotification'] as Map)
        : <String, dynamic>{};
    final contacts = (res.data!['guardianContacts'] is List)
        ? (res.data!['guardianContacts'] as List).whereType<Map>().toList()
        : const <Map>[];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Icon(Icons.emergency, color: Colors.red.shade700),
            const SizedBox(width: 8),
            Expanded(child: Text('SOS Dispatched ($sosId)')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Coordinates sent: ${res.data!['gps'] ?? 'Unavailable'}'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: notif['deliveryConfigured'] == true ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: notif['deliveryConfigured'] == true ? Colors.green : Colors.orange.shade400,
                ),
              ),
              child: Text(
                notif['deliveryMessage']?.toString() ?? 'Emergency alert saved in Cloud Database.',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            if (contacts.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text('Emergency Contacts to Call Directly:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
              ...contacts.map((c) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('• ${c['guardianName']}: ${c['phone']}'),
                  )),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSafeArrival(DatabaseService db) async {
    final rem = TravelJourneyService.formatDistance(_journeyService.remainingDistanceMeters);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.verified_user, color: Colors.teal),
            SizedBox(width: 8),
            Expanded(child: Text('Confirm Safe Arrival?')),
          ],
        ),
        content: Text(
          'Current GPS distance to ${_journeyService.displayDestName} is $rem.\n\n'
          'Confirming will stop live GPS tracking, stop active evidence recording, and mark your journey COMPLETED in Cloud Database.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Stay Active')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('YES, I REACHED SAFELY'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;
    final res = await _journeyService.completeSafeArrival(db);
    if (!mounted) return;
    if (!res.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.error ?? 'Failed to complete journey.'), backgroundColor: Colors.red.shade700),
      );
    }
  }

  Future<void> _showTripHistorySheet() async {
    await _journeyService.refreshHistory();
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
            const Text('Recent Safe Arrival Journeys', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            if (_journeyService.history.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('No recorded journeys yet in Cloud Database.'),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _journeyService.history.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, idx) {
                    final item = _journeyService.history[idx];
                    final st = item['status']?.toString() ?? 'ACTIVE';
                    final ver = item['arrivalVerified'] == true;
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        st == 'COMPLETED' ? Icons.check_circle : (st == 'EMERGENCY' ? Icons.sos : Icons.directions),
                        color: st == 'COMPLETED' ? Colors.green : (st == 'EMERGENCY' ? Colors.red : Colors.teal),
                      ),
                      title: Text(item['destinationName']?.toString() ?? 'Destination', maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        '$st • ${TravelJourneyService.formatDistance((item['distanceMeters'] as num?)?.toDouble() ?? 0.0)}'
                        '${st == 'COMPLETED' ? (ver ? ' • GPS Verified' : ' • Manual Confirmation') : ''}',
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

  Color _badgeColor(JourneyDisplayStatus st) {
    switch (st) {
      case JourneyDisplayStatus.notStarted:
        return Colors.blueGrey.shade700;
      case JourneyDisplayStatus.active:
        return Colors.teal.shade700;
      case JourneyDisplayStatus.warning:
        return Colors.orange.shade800;
      case JourneyDisplayStatus.emergency:
        return Colors.red.shade700;
      case JourneyDisplayStatus.completed:
        return Colors.green.shade700;
    }
  }

  IconData _categoryIcon(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('hospital') || c.contains('clinic')) return Icons.local_hospital;
    if (c.contains('rail') || c.contains('station') || c.contains('subway')) return Icons.train;
    if (c.contains('bus')) return Icons.directions_bus;
    if (c.contains('restaurant') || c.contains('cafe') || c.contains('food')) return Icons.restaurant;
    if (c.contains('school') || c.contains('college') || c.contains('university')) return Icons.school;
    return Icons.place;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TravelJourneyService>.value(
      value: _journeyService,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F7F6),
        appBar: AppBar(
          title: const Text('Safe Arrival Travel Mode'),
          backgroundColor: Colors.teal.shade800,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              tooltip: 'Journey History',
              onPressed: _showTripHistorySheet,
              icon: const Icon(Icons.history),
            ),
          ],
        ),
        body: Consumer2<DatabaseService, TravelJourneyService>(
          builder: (context, db, svc, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildStatusHeader(svc),
                      const SizedBox(height: 12),

                      if (svc.completedSummary != null && !svc.hasActiveJourney) ...[
                        _buildCompletedSummaryCard(svc),
                        const SizedBox(height: 14),
                      ],

                      if (!svc.hasActiveJourney) ...[
                        _buildPlanningSearchCard(svc),
                        const SizedBox(height: 14),
                      ] else ...[
                        _buildActiveCountdownBanner(svc),
                        const SizedBox(height: 12),
                      ],

                      if (svc.hasActiveJourney && (svc.isOverdue || svc.deviationWarning || svc.isGpsGapWarning || !svc.gpsWatchRunning)) ...[
                        _buildMonitoringAlertBanner(svc),
                        const SizedBox(height: 12),
                      ],

                      _buildInteractiveMapCard(svc),
                      const SizedBox(height: 14),

                      _buildJourneyTelemetryCard(svc),
                      const SizedBox(height: 14),

                      if (svc.shares.isNotEmpty) ...[
                        _buildActiveSharesCard(svc),
                        const SizedBox(height: 14),
                      ],

                      _buildActionButtonsSection(db, svc),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusHeader(TravelJourneyService svc) {
    final color = _badgeColor(svc.displayStatus);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1.4),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color,
            child: Icon(
              svc.displayStatus == JourneyDisplayStatus.emergency
                  ? Icons.sos
                  : svc.displayStatus == JourneyDisplayStatus.active
                      ? Icons.my_location
                      : svc.displayStatus == JourneyDisplayStatus.completed
                          ? Icons.verified
                          : Icons.shield_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  svc.statusBadgeText,
                  style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 13.5, letterSpacing: 0.5),
                ),
                const SizedBox(height: 2),
                Text(
                  svc.platformTrackingNotice,
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedSummaryCard(TravelJourneyService svc) {
    final s = svc.completedSummary!;
    final verified = s['arrivalVerified'] == true;
    final arrDist = s['arrivalDistanceMeters'];
    final notif = (s['guardianNotification'] is Map)
        ? Map<String, dynamic>.from(s['guardianNotification'] as Map)
        : <String, dynamic>{};

    return Card(
      color: Colors.green.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.green.shade400),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified_rounded, color: Colors.green.shade700, size: 28),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Safe Arrival Recorded in Cloud Database',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
                TextButton(
                  onPressed: svc.dismissCompletedSummary,
                  child: const Text('New Trip'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              verified
                  ? 'Arrival Verification: GPS Verified (${(arrDist as num?)?.round() ?? 0}m from destination)'
                  : 'Arrival Verification: Manual Confirmation${arrDist != null ? ' (${(arrDist as num).round()}m from destination)' : ''}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            Text(
              'Distance Logged: ${TravelJourneyService.formatDistance((s['traveledMeters'] as num?)?.toDouble() ?? 0.0)}',
              style: const TextStyle(fontSize: 12.5),
            ),
            Text('Evidence Status: ${s['blackboxStatus'] ?? 'Stopped'}', style: const TextStyle(fontSize: 12.5)),
            if (notif['deliveryMessage'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  notif['deliveryMessage'].toString(),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanningSearchCard(TravelJourneyService svc) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Destination & Route Planner',
              style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),

            // Origin Picker (Current GPS vs Manual Start)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  selectedColor: Colors.teal.shade100,
                  selected: svc.useCurrentGpsOrigin,
                  avatar: const Icon(Icons.my_location, size: 16, color: Colors.teal),
                  label: Text(
                    svc.currentGps != null
                        ? 'Current GPS (±${svc.gpsAccuracyMeters.round()}m)'
                        : 'Use Current GPS',
                    style: const TextStyle(fontSize: 12.5),
                  ),
                  onSelected: (_) {
                    setState(() => _showOriginSearchField = false);
                    svc.setUseCurrentGpsOrigin(true);
                  },
                ),
                ChoiceChip(
                  selectedColor: Colors.teal.shade100,
                  selected: !svc.useCurrentGpsOrigin || _showOriginSearchField,
                  avatar: const Icon(Icons.edit_location_alt, size: 16, color: Colors.teal),
                  label: Text(
                    svc.manualOrigin != null && !svc.useCurrentGpsOrigin
                        ? 'Start: ${svc.manualOrigin!.name}'
                        : 'Choose Start Location',
                    style: const TextStyle(fontSize: 12.5),
                  ),
                  onSelected: (_) {
                    setState(() => _showOriginSearchField = true);
                  },
                ),
                TextButton.icon(
                  onPressed: svc.captureCurrentLocation,
                  icon: const Icon(Icons.gps_fixed, size: 16),
                  label: const Text('Refresh GPS'),
                ),
              ],
            ),

            if (svc.gpsError != null && svc.useCurrentGpsOrigin)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_off, color: Colors.orange.shade800, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(svc.gpsError!, style: TextStyle(fontSize: 12, color: Colors.orange.shade900)),
                    ),
                  ],
                ),
              ),

            if (_showOriginSearchField) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _originSearchController,
                onChanged: _onOriginSearchChanged,
                decoration: InputDecoration(
                  labelText: 'Search Starting Location',
                  hintText: 'Address, station, college, landmark...',
                  prefixIcon: const Icon(Icons.trip_origin, color: Colors.teal),
                  suffixIcon: _searchingOrigin
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : null,
                  border: const OutlineInputBorder(),
                ),
              ),
              if (_originSearchError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(_originSearchError!, style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
                ),
              if (_originSuggestions.isNotEmpty)
                _buildSuggestionList(
                  suggestions: _originSuggestions,
                  onPick: (p) {
                    _originSearchController.text = p.displayName;
                    setState(() {
                      _originSuggestions = <PlaceSuggestion>[];
                      _showOriginSearchField = false;
                    });
                    svc.setManualOrigin(p);
                  },
                ),
            ],

            const SizedBox(height: 12),

            // Google Maps-Style Destination Search
            TextField(
              controller: _destSearchController,
              onChanged: _onDestSearchChanged,
              decoration: InputDecoration(
                labelText: 'Search Destination (Google Places / OSM)',
                hintText: 'Restaurants, colleges, hospitals, stations, addresses...',
                prefixIcon: const Icon(Icons.search, color: Colors.teal),
                suffixIcon: _searchingDest
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : (_destSearchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _destSearchController.clear();
                              setState(() {
                                _destSuggestions = <PlaceSuggestion>[];
                                _destSearchError = null;
                              });
                            },
                            icon: const Icon(Icons.clear),
                          )
                        : null),
                border: const OutlineInputBorder(),
              ),
            ),
            if (_destSearchError != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(_destSearchError!, style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
              ),
            if (_destSuggestions.isNotEmpty)
              _buildSuggestionList(
                suggestions: _destSuggestions,
                onPick: (place) async {
                  _destSearchController.text = place.displayName;
                  setState(() {
                    _destSuggestions = <PlaceSuggestion>[];
                    _destSearchError = null;
                  });
                  await svc.selectDestination(place);
                  if (mounted && svc.selectedRoute != null) {
                    _durationController.text = svc.selectedRoute!.durationMinutes.toString();
                  }
                },
              ),

            if (svc.selectedDestination != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.teal.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified_outlined, color: Colors.teal.shade700, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Verified Destination: ${svc.selectedDestination!.name} '
                        '(${svc.selectedDestination!.location.latitude.toStringAsFixed(4)}, '
                        '${svc.selectedDestination!.location.longitude.toStringAsFixed(4)})',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.teal.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Travel Mode + Route Alternatives
            Row(
              children: [
                ChoiceChip(
                  selected: svc.travelMode == 'driving',
                  selectedColor: Colors.teal.shade100,
                  avatar: const Icon(Icons.directions_car, size: 16),
                  label: const Text('Vehicle'),
                  onSelected: (_) async {
                    await svc.setTravelMode('driving');
                    if (mounted && svc.selectedRoute != null) {
                      _durationController.text = svc.selectedRoute!.durationMinutes.toString();
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  selected: svc.travelMode == 'walking',
                  selectedColor: Colors.teal.shade100,
                  avatar: const Icon(Icons.directions_walk, size: 16),
                  label: const Text('Walking'),
                  onSelected: (_) async {
                    await svc.setTravelMode('walking');
                    if (mounted && svc.selectedRoute != null) {
                      _durationController.text = svc.selectedRoute!.durationMinutes.toString();
                    }
                  },
                ),
                if (svc.isCalculatingRoute) ...[
                  const SizedBox(width: 12),
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 6),
                  const Text('Calculating route...', style: TextStyle(fontSize: 12)),
                ],
              ],
            ),

            if (svc.routeError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(svc.routeError!, style: TextStyle(color: Colors.red.shade700, fontSize: 12.5)),
              ),

            if (svc.routeOptions.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text('Select Route Corridor', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(svc.routeOptions.length, (i) {
                  final r = svc.routeOptions[i];
                  final active = i == svc.selectedRouteIndex;
                  return ChoiceChip(
                    selected: active,
                    selectedColor: Colors.teal.shade700,
                    labelStyle: TextStyle(color: active ? Colors.white : Colors.black87, fontSize: 12),
                    label: Text(
                      '${r.label}: ${TravelJourneyService.formatDistance(r.distanceMeters)} • ${r.durationMinutes} min',
                    ),
                    onSelected: (_) {
                      svc.selectRouteIndex(i);
                      _durationController.text = r.durationMinutes.toString();
                    },
                  );
                }),
              ),
            ],

            const SizedBox(height: 14),

            // Duration & Evidence Mode Row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _durationController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'ETA Duration (min)',
                      prefixIcon: Icon(Icons.timer_outlined, color: Colors.teal),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: InkWell(
                    onTap: _showRecordingModeModal,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _selectedRecordingMode == 'None' ? Icons.location_searching : Icons.mic,
                            color: Colors.teal.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Evidence', style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600)),
                                Text(
                                  _selectedRecordingMode,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionList({
    required List<PlaceSuggestion> suggestions,
    required void Function(PlaceSuggestion) onPick,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      constraints: const BoxConstraints(maxHeight: 240),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade200),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, idx) {
          final item = suggestions[idx];
          return ListTile(
            dense: true,
            leading: Icon(_categoryIcon(item.category), color: Colors.teal.shade700),
            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            subtitle: Text(
              '${item.category} • ${item.displayName}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5),
            ),
            onTap: () => onPick(item),
          );
        },
      ),
    );
  }

  Widget _buildActiveCountdownBanner(TravelJourneyService svc) {
    final isEmergency = svc.displayStatus == JourneyDisplayStatus.emergency;
    final isWarn = svc.displayStatus == JourneyDisplayStatus.warning;
    final gradColors = isEmergency
        ? [Colors.red.shade900, Colors.red.shade700]
        : (isWarn ? [Colors.orange.shade900, Colors.orange.shade700] : [Colors.teal.shade900, Colors.teal.shade700]);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(colors: gradColors),
        boxShadow: [BoxShadow(color: gradColors.first.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Text(
            TravelJourneyService.formatCountdown(svc.timeRemaining),
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Destination: ${svc.displayDestName}',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Blackbox: ${svc.blackboxStatusText}',
            style: const TextStyle(color: Colors.white70, fontSize: 11.5),
          ),
        ],
      ),
    );
  }

  Widget _buildMonitoringAlertBanner(TravelJourneyService svc) {
    final alerts = <String>[
      if (svc.isOverdue)
        svc.isGracePeriodExceeded
            ? 'ETA exceeded grace period (${TravelJourneyService.etaGracePeriodMinutes}m). Please confirm Safe Arrival or extend ETA.'
            : 'Estimated arrival time has elapsed. Are you delayed safely?',
      if (svc.deviationWarning)
        'Current location is ${svc.deviationMeters.round()}m off your planned safe route corridor.',
      if (svc.isGpsGapWarning)
        'No fresh GPS fix received in the last ${TravelJourneyService.gpsGapWarningSeconds} seconds.',
      if (!svc.gpsWatchRunning)
        'Live GPS watch stopped or needs permission refresh after reload.',
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade600, width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
              const SizedBox(width: 8),
              Text(
                'Journey Safety Check-In',
                style: TextStyle(fontWeight: FontWeight.w800, color: Colors.orange.shade900),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...alerts.map((msg) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text('• $msg', style: TextStyle(fontSize: 12.5, color: Colors.orange.shade900)),
              )),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (svc.isOverdue)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white),
                  onPressed: () => svc.extendEta(15),
                  icon: const Icon(Icons.more_time, size: 16),
                  label: const Text('Extend ETA +15 min'),
                ),
              if (!svc.gpsWatchRunning)
                OutlinedButton.icon(
                  onPressed: svc.resumeLiveGpsWatch,
                  icon: const Icon(Icons.gps_fixed, size: 16),
                  label: const Text('Resume Live GPS'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveMapCard(TravelJourneyService svc) {
    final originPt = svc.displayOriginPoint;
    final destPt = svc.displayDestPoint;
    final currentPt = svc.currentGps;
    final mapCenter = currentPt ?? destPt ?? originPt ?? const LatLng(23.0225, 72.5714);

    final polylines = <Polyline>[];
    if (!svc.hasActiveJourney) {
      for (var i = 0; i < svc.routeOptions.length; i++) {
        if (i != svc.selectedRouteIndex && svc.routeOptions[i].polyline.length >= 2) {
          polylines.add(
            Polyline(
              points: svc.routeOptions[i].polyline,
              color: Colors.grey.shade500.withValues(alpha: 0.55),
              strokeWidth: 3.5,
            ),
          );
        }
      }
    }
    if (svc.displayPlannedPolyline.length >= 2) {
      polylines.add(
        Polyline(
          points: svc.displayPlannedPolyline,
          color: Colors.indigo.shade600,
          strokeWidth: 4.5,
        ),
      );
    }
    if (svc.traveledTrail.length >= 2) {
      polylines.add(
        Polyline(
          points: svc.traveledTrail,
          color: Colors.teal.shade700,
          strokeWidth: 5.5,
        ),
      );
    }

    final markers = <Marker>[
      if (originPt != null)
        Marker(
          point: originPt,
          width: 34,
          height: 34,
          child: const CircleAvatar(
            backgroundColor: Colors.teal,
            child: Icon(Icons.trip_origin, color: Colors.white, size: 18),
          ),
        ),
      if (destPt != null)
        Marker(
          point: destPt,
          width: 40,
          height: 40,
          child: Icon(Icons.location_on, color: Colors.red.shade700, size: 38),
        ),
      if (currentPt != null)
        Marker(
          point: currentPt,
          width: 38,
          height: 38,
          child: Container(
            decoration: BoxDecoration(
              color: svc.displayStatus == JourneyDisplayStatus.emergency ? Colors.red.shade700 : Colors.blue.shade700,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
            ),
            child: const Icon(Icons.navigation, color: Colors.white, size: 20),
          ),
        ),
    ];

    final circles = <CircleMarker>[
      if (currentPt != null && svc.gpsAccuracyMeters > 0)
        CircleMarker(
          point: currentPt,
          radius: svc.gpsAccuracyMeters.clamp(12.0, 250.0),
          useRadiusInMeter: true,
          color: Colors.blue.withValues(alpha: 0.14),
          borderColor: Colors.blue.withValues(alpha: 0.5),
          borderStrokeWidth: 1.5,
        ),
    ];

    final fitList = <LatLng>[
      ...svc.displayPlannedPolyline,
      if (originPt != null) originPt,
      if (destPt != null) destPt,
      if (currentPt != null) currentPt,
    ];

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.map_rounded, color: Colors.teal.shade800),
                    const SizedBox(width: 6),
                    Text(
                      svc.hasActiveJourney ? 'Live Navigation Map' : 'Route Preview Map',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.teal.shade900),
                    ),
                  ],
                ),
                FilterChip(
                  selected: _autoFollowMap,
                  selectedColor: Colors.teal.shade100,
                  label: Text(_autoFollowMap ? 'Auto-Center ON' : 'Free Pan', style: const TextStyle(fontSize: 11.5)),
                  avatar: Icon(_autoFollowMap ? Icons.gps_fixed : Icons.pan_tool_alt, size: 15),
                  onSelected: (v) => setState(() => _autoFollowMap = v),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LiveGoogleMapView(
              center: mapCenter,
              height: svc.hasActiveJourney ? 350 : 280,
              zoom: 14.5,
              markers: markers,
              polylines: polylines,
              circles: circles,
              autoFollow: _autoFollowMap,
              fitPoints: fitList,
              fitBoundsKey:
                  '${svc.selectedRoute?.routeId ?? ''}_${svc.selectedDestination?.placeId ?? ''}_${svc.activeJourneyId ?? ''}',
              onMyLocationPressed: () {
                setState(() => _autoFollowMap = true);
                svc.captureCurrentLocation();
              },
              title: svc.displayDestName.isNotEmpty ? svc.displayDestName : 'Live GPS Map',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJourneyTelemetryCard(TravelJourneyService svc) {
    final lastGpsLabel = svc.lastGpsAt != null
        ? '${svc.lastGpsAt!.toLocal().hour.toString().padLeft(2, '0')}:${svc.lastGpsAt!.toLocal().minute.toString().padLeft(2, '0')}:${svc.lastGpsAt!.toLocal().second.toString().padLeft(2, '0')} (±${svc.gpsAccuracyMeters.round()}m)'
        : (svc.gpsError ?? 'Waiting for real GPS fix');

    final syncLabel = svc.pendingOfflineCount > 0
        ? 'Offline queue: ${svc.pendingOfflineCount} GPS pt(s)'
        : (svc.lastSyncSuccessAt != null
            ? 'Synced ${svc.lastSyncSuccessAt!.toLocal().hour.toString().padLeft(2, '0')}:${svc.lastSyncSuccessAt!.toLocal().minute.toString().padLeft(2, '0')}:${svc.lastSyncSuccessAt!.toLocal().second.toString().padLeft(2, '0')}'
            : (svc.hasActiveJourney ? 'Initializing Cloud Database sync...' : 'Ready to start'));

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Journey Telemetry', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                _metricTile(
                  icon: Icons.route,
                  label: 'Planned Route',
                  value: svc.plannedDistanceMeters > 0
                      ? TravelJourneyService.formatDistance(svc.plannedDistanceMeters)
                      : '--',
                ),
                _metricTile(
                  icon: Icons.directions_run,
                  label: 'Traveled',
                  value: TravelJourneyService.formatDistance(svc.traveledDistanceMeters),
                ),
                _metricTile(
                  icon: Icons.flag_outlined,
                  label: 'Remaining',
                  value: svc.displayDestPoint != null
                      ? TravelJourneyService.formatDistance(svc.remainingDistanceMeters)
                      : '--',
                ),
                _metricTile(
                  icon: Icons.schedule,
                  label: 'Dynamic ETA',
                  value: svc.hasActiveJourney
                      ? svc.dynamicEtaDisplay
                      : (svc.selectedRoute != null ? '${svc.selectedRoute!.durationMinutes} min' : '--'),
                ),
              ],
            ),
            const Divider(height: 22),
            Text('GPS Signal: $lastGpsLabel', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Backend Sync: $syncLabel${svc.syncError != null ? ' • ${svc.syncError}' : ''}',
              style: TextStyle(fontSize: 12, color: svc.pendingOfflineCount > 0 ? Colors.orange.shade800 : Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricTile({required IconData icon, required String label, required String value}) {
    return Container(
      width: 195,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.shade50.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal.shade800, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSharesCard(TravelJourneyService svc) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Guardian Live Shares', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 8),
            ...svc.shares.map((s) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    s.isActive ? Icons.visibility : Icons.visibility_off,
                    color: s.isActive ? Colors.teal.shade700 : Colors.grey,
                  ),
                  title: Text(s.guardianName, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                    s.isActive
                        ? 'Gateway: ${s.deliveryStatus} • Active until ${s.expiresAt.split('T').last.split('.').first}'
                        : 'Revoked',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: s.isActive
                      ? TextButton(
                          onPressed: () => svc.revokeShare(s.id),
                          child: Text('Revoke', style: TextStyle(color: Colors.red.shade700)),
                        )
                      : null,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtonsSection(DatabaseService db, TravelJourneyService svc) {
    if (!svc.hasActiveJourney) {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal.shade700,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 3,
        ),
        icon: svc.isBusy
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : const Icon(Icons.play_arrow_rounded, size: 28),
        label: Text(
          svc.isBusy ? 'INITIALIZING GPS & ROUTE...' : 'START JOURNEY',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 0.6),
        ),
        onPressed: svc.isBusy ? null : () => _handleStartJourney(db),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 440,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.teal.shade800,
                  side: BorderSide(color: Colors.teal.shade700, width: 1.5),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: svc.isBusy ? null : _openShareJourneySheet,
                icon: const Icon(Icons.share_location),
                label: const Text('SHARE JOURNEY WITH GUARDIAN', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
            SizedBox(
              width: 440,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: svc.isBusy ? null : _confirmEmergencySos,
                icon: const Icon(Icons.sos_rounded),
                label: const Text('SOS - EMERGENCY', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 3,
          ),
          onPressed: svc.isBusy ? null : () => _confirmSafeArrival(db),
          icon: const Icon(Icons.check_circle_outline, size: 26),
          label: const Text(
            'I HAVE REACHED SAFELY',
            style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, letterSpacing: 0.4),
          ),
        ),
      ],
    );
  }
}


// ==========================================
// 2. CAB MONITOR SCREEN (SMART CAB GUARDIAN)
// ==========================================
class CabMonitorScreen extends StatefulWidget {
  const CabMonitorScreen({super.key});

  @override
  State<CabMonitorScreen> createState() => _CabMonitorScreenState();
}

class _CabMonitorScreenState extends State<CabMonitorScreen> {
  final TextEditingController _plateController = TextEditingController(text: "GJ-01-XX-9999");
  final TextEditingController _destinationController = TextEditingController(text: "CG Road, Ahmedabad");
  final TextEditingController _driverNameController = TextEditingController(text: "Ramesh Patel (Rating: 4.9★)");
  String _selectedProvider = "Uber Premier";
  bool _tripStarted = true; // Started by default for instant live demonstration!
  double _routeDeviationMeters = 28.0;
  bool _audioBlackboxActive = true;

  @override
  void dispose() {
    _plateController.dispose();
    _destinationController.dispose();
    _driverNameController.dispose();
    super.dispose();
  }

  void _showSafeArrivalDialog() {
    int rating = 5;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.verified, color: Colors.green, size: 28),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Safe Arrival Confirmed!",
                    style: TextStyle(fontSize: 18),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("You have reached your destination securely. Live cab monitoring session closed."),
                const SizedBox(height: 16),
                const Text("Rate Trip & Driver Safety:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          rating = index + 1;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Colors.purple),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          "Driver adhered to route corridor • 0 safety breaches recorded",
                          style: TextStyle(fontSize: 11, color: Colors.purple, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade700,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _tripStarted = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Cab monitoring completed. Guardians notified of safe arrival!"),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Text("Submit & End Trip"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _triggerPanicAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.white, size: 32),
            SizedBox(width: 10),
            Text("CAB SOS DISPATCHED", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          "Emergency signal sent to Police PCR Van, nearest police station, and linked guardians with live vehicle GPS coordinates & cab number GJ-01-XX-9999.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red.shade900),
            onPressed: () => Navigator.pop(context),
            child: const Text("Acknowledge"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart Cab Guardian"),
        backgroundColor: Colors.purple.shade800,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _tripStarted ? _buildActiveTripView() : _buildStartTripView(),
      ),
    );
  }

  // Active Live Cab Monitoring with Live Google Map
  Widget _buildActiveTripView() {
    final bool isOffCorridor = _routeDeviationMeters > 80;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Live Cab Header Banner
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          color: Colors.purple.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.local_taxi, color: Colors.purple, size: 24),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _plateController.text,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.purple),
                            ),
                            Text(
                              "$_selectedProvider • ${_driverNameController.text.split('(').first.trim()}",
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isOffCorridor ? Colors.red.shade100 : Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 4,
                            backgroundColor: isOffCorridor ? Colors.red : Colors.green,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isOffCorridor ? "DEVIATION ALERT" : "SAFE CORRIDOR",
                            style: TextStyle(
                              color: isOffCorridor ? Colors.red.shade800 : Colors.green.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.speed, size: 16, color: Colors.purple),
                        const SizedBox(width: 4),
                        const Text("Speed: 38 km/h", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.near_me, size: 16, color: isOffCorridor ? Colors.red : Colors.teal),
                        const SizedBox(width: 4),
                        Text(
                          "Deviation: ${_routeDeviationMeters.toInt()}m",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: isOffCorridor ? Colors.red : Colors.teal,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.verified_user, size: 16, color: Colors.green),
                        const SizedBox(width: 4),
                        const Text("Safety 98%", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Live Google Map with Route, Cab Marker, Destination, and Police Station
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.map, color: Colors.purple),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Live Cab Tracking Map",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.purple),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "23.0310° N, 72.5590° E",
                      style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.purple.shade900),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LiveGoogleMapView(
                  height: 250,
                  center: const LatLng(23.0310, 72.5590),
                  zoom: 14.8,
                  showControls: true,
                  interactive: true,
                  title: "Cab Route: ${_plateController.text}",
                  polylines: [
                    // Approved route corridor polyline
                    Polyline(
                      points: const [
                        LatLng(23.0400, 72.5530), // Start point
                        LatLng(23.0360, 72.5560),
                        LatLng(23.0310, 72.5590), // Current cab position
                        LatLng(23.0260, 72.5620),
                        LatLng(23.0220, 72.5650), // Destination (CG Road)
                      ],
                      strokeWidth: 5.0,
                      color: isOffCorridor ? Colors.red.shade400 : Colors.purple.shade700,
                    ),
                  ],
                  circles: [
                    // Safe corridor radius around cab
                    CircleMarker(
                      point: const LatLng(23.0310, 72.5590),
                      radius: 100,
                      useRadiusInMeter: true,
                      color: (isOffCorridor ? Colors.red : Colors.purple).withValues(alpha: 0.15),
                      borderColor: isOffCorridor ? Colors.red : Colors.purple,
                      borderStrokeWidth: 2,
                    ),
                  ],
                  markers: [
                    // Live Cab Marker
                    Marker(
                      point: const LatLng(23.0310, 72.5590),
                      width: 140,
                      height: 64,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade900,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.local_taxi, size: 10, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  _plateController.text,
                                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Icon(Icons.navigation, size: 32, color: Colors.purple),
                        ],
                      ),
                    ),

                    // Destination Marker
                    Marker(
                      point: const LatLng(23.0220, 72.5650),
                      width: 120,
                      height: 60,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade700,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text("📍 CG Road (Drop)", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                          const Icon(Icons.flag, size: 28, color: Colors.red),
                        ],
                      ),
                    ),

                    // Police Station Marker along route
                    Marker(
                      point: const LatLng(23.0295, 72.5560),
                      width: 110,
                      height: 58,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade800,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text("Police Chowki", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                          ),
                          const Icon(Icons.local_police, size: 26, color: Colors.blue),
                        ],
                      ),
                    ),

                    // Hospital Safety Node Marker
                    Marker(
                      point: const LatLng(23.0335, 72.5630),
                      width: 100,
                      height: 58,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade800,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text("Apollo Hospital", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                          ),
                          const Icon(Icons.local_hospital, size: 26, color: Colors.teal),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Origin: University Gate", style: TextStyle(fontSize: 10, color: Colors.grey)),
                    Text("Dest: ${_destinationController.text}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple)),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Route Deviation Simulator Slider Card (for live demo testing!)
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Simulate Route Deviation (Demo Test):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(
                      "${_routeDeviationMeters.toInt()} meters",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isOffCorridor ? Colors.red : Colors.purple,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _routeDeviationMeters,
                  min: 0,
                  max: 150,
                  divisions: 15,
                  activeColor: isOffCorridor ? Colors.red : Colors.purple,
                  onChanged: (val) {
                    setState(() {
                      _routeDeviationMeters = val;
                    });
                  },
                ),
                Text(
                  isOffCorridor
                      ? "⚠️ WARNING: Cab has deviated ${_routeDeviationMeters.toInt()}m from approved route corridor! Emergency contacts alerted."
                      : "✓ Route is within safe 100m corridor threshold.",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isOffCorridor ? Colors.red : Colors.green.shade800,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // AI Dynamic Safety Assessment & Telemetry
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "AI Dynamic Trip Safety Assessment",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.purple),
                ),
                const SizedBox(height: 12),
                _buildSafetyCheckRow(
                  icon: Icons.mic,
                  title: "In-Cab Audio Blackbox",
                  status: _audioBlackboxActive ? "Active • 0 Threat Words Detected" : "Muted",
                  statusColor: Colors.green,
                ),
                const Divider(height: 16),
                _buildSafetyCheckRow(
                  icon: Icons.shield,
                  title: "Driver Behaviour Scan",
                  status: "Smooth acceleration • No abnormal halts",
                  statusColor: Colors.green,
                ),
                const Divider(height: 16),
                _buildSafetyCheckRow(
                  icon: Icons.people_outline,
                  title: "Guardian Live Mesh Sync",
                  status: "Linked with Priya Sharma & Mother (2 active)",
                  statusColor: Colors.purple,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Action Buttons Row: SOS Panic + I Reached Safely
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.emergency),
                label: const Text("CAB SOS", style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: _triggerPanicAlert,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.check_circle),
                label: const Text("I Have Reached Safely", style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: _showSafeArrivalDialog,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // Pre-trip Configuration Form View
  Widget _buildStartTripView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Configure Smart Cab Trip",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.purple),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Enter cab plate number or scan with camera to start continuous path monitoring.",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 18),

                // Cab Plate Input
                TextField(
                  controller: _plateController,
                  decoration: InputDecoration(
                    labelText: "Cab Registration Number",
                    prefixIcon: const Icon(Icons.directions_car, color: Colors.purple),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.purple),
                      tooltip: "Scan Number Plate via OCR",
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Camera OCR plate scanner initialized! Detected: GJ-01-XX-9999")),
                        );
                      },
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                // Destination Input
                TextField(
                  controller: _destinationController,
                  decoration: InputDecoration(
                    labelText: "Destination Address",
                    prefixIcon: const Icon(Icons.location_on, color: Colors.teal),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                // Provider Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedProvider,
                  decoration: InputDecoration(
                    labelText: "Cab / Ride Service",
                    prefixIcon: const Icon(Icons.local_taxi, color: Colors.purple),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: ["Uber Premier", "Ola Prime", "Rapido Auto", "Private Taxi", "Airport Shuttle"]
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedProvider = val);
                  },
                ),
                const SizedBox(height: 16),

                // Audio Blackbox Toggle
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Blackbox Audio Recording", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text("Encrypts ambient cabin audio for evidence proof", style: TextStyle(fontSize: 11)),
                  value: _audioBlackboxActive,
                  activeThumbColor: Colors.purple,
                  onChanged: (val) => setState(() => _audioBlackboxActive = val),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple.shade700,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
          ),
          icon: const Icon(Icons.navigation, size: 24),
          label: const Text("Start Safe Journey", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          onPressed: () {
            setState(() {
              _tripStarted = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Cab Safe Journey Started! Real-time GPS corridor active."),
                backgroundColor: Colors.purple,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSafetyCheckRow({
    required IconData icon,
    required String title,
    required String status,
    required Color statusColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: statusColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}


// ==========================================
// 3. WALK MONITOR SCREEN (SMART WALK GUARDIAN)
// ==========================================
class WalkMonitorScreen extends StatefulWidget {
  const WalkMonitorScreen({super.key});

  @override
  State<WalkMonitorScreen> createState() => _WalkMonitorScreenState();
}

class _WalkMonitorScreenState extends State<WalkMonitorScreen> {
  bool _walkActive = false; // Default OFF: starts tracking only when activated by user!

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart Walk Guardian"),
        backgroundColor: Colors.pink.shade800,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              color: _walkActive ? Colors.pink.shade50 : Colors.grey.shade100,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _walkActive ? Colors.pink.shade100 : Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.directions_walk,
                        size: 36,
                        color: _walkActive ? Colors.pink.shade800 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _walkActive ? "Walk Guardian Active" : "Walk Guardian Standby (Off)",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _walkActive ? Colors.pink.shade900 : Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _walkActive ? Colors.green.shade100 : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _walkActive ? "TRACKING" : "OFF",
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: _walkActive ? Colors.green.shade800 : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _walkActive
                                ? "Monitoring accelerometer for drop, snatch, run & stop events. Live corridor tracking active."
                                : "Sensors idle. Tap button below to activate pedestrian protection & start live tracking.",
                            style: TextStyle(fontSize: 12, color: _walkActive ? Colors.pink.shade900 : Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Live Pedestrian Google Map
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.map, color: Colors.pink),
                            SizedBox(width: 8),
                            Text(
                              "Pedestrian Live Google Map",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.pink),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.pink.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.pink.shade200),
                          ),
                          child: const Text("PEDESTRIAN CORRIDOR", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.pink)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LiveGoogleMapView(
                      height: 230,
                      center: const LatLng(23.0320, 72.5600),
                      zoom: 15.5,
                      showControls: true,
                      interactive: true,
                      title: "Walking Corridor: University to Home",
                      polylines: [
                        Polyline(
                          points: const [
                            LatLng(23.0360, 72.5580),
                            LatLng(23.0340, 72.5590),
                            LatLng(23.0320, 72.5600),
                            LatLng(23.0290, 72.5620),
                          ],
                          strokeWidth: 4.5,
                          color: Colors.pink.shade600,
                        ),
                      ],
                      circles: [
                        // Safe lit zone perimeter
                        CircleMarker(
                          point: const LatLng(23.0320, 72.5600),
                          radius: 120,
                          useRadiusInMeter: true,
                          color: Colors.pink.withValues(alpha: 0.15),
                          borderColor: Colors.pink,
                          borderStrokeWidth: 2,
                        ),
                      ],
                      markers: [
                        // Pedestrian marker
                        Marker(
                          point: const LatLng(23.0320, 72.5600),
                          width: 120,
                          height: 60,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.pink.shade900,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text("🚶 You Walking", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
                              const Icon(Icons.person_pin, size: 32, color: Colors.pink),
                            ],
                          ),
                        ),
                        // Police Post nearby
                        Marker(
                          point: const LatLng(23.0290, 72.5620),
                          width: 100,
                          height: 56,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade900,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text("Safe Police Booth", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                              ),
                              const Icon(Icons.shield, size: 24, color: Colors.blue),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Well-lit corridor recommended • 2 SOS emergency booths within 300m",
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Telemetry Cards
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildWalkMetricRow(
                      Icons.vibration,
                      "Drop / Snatch Sensor",
                      _walkActive ? "CALIBRATED & ARMED" : "STANDBY (INACTIVE)",
                      _walkActive ? Colors.green : Colors.grey,
                    ),
                    const Divider(height: 16),
                    _buildWalkMetricRow(
                      Icons.directions_run,
                      "Abnormal Running / Halt",
                      _walkActive ? "NORMAL PACE (4.2 km/h)" : "OFFLINE (AWAITING START)",
                      _walkActive ? Colors.teal : Colors.grey,
                    ),
                    const Divider(height: 16),
                    _buildWalkMetricRow(
                      Icons.record_voice_over,
                      "Voice Trigger 'CAPCAP'",
                      _walkActive ? "LISTENING (MIC OK)" : "PAUSED (OFFLINE)",
                      _walkActive ? Colors.purple : Colors.grey,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _walkActive = !_walkActive;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(
                          _walkActive ? Icons.check_circle : Icons.stop_circle,
                          color: _walkActive ? Colors.greenAccent : Colors.orangeAccent,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _walkActive
                                ? "Smart Walk Guardian Activated! Accelerometer tracking & GPS corridor active."
                                : "Walk Guardian session ended safely.",
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: _walkActive ? Colors.pink.shade900 : Colors.grey.shade900,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _walkActive ? Colors.red.shade700 : Colors.pink.shade700,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: Icon(_walkActive ? Icons.stop_circle : Icons.play_arrow),
              label: Text(
                _walkActive ? "End Walk Guardian Session" : "Start Smart Walk Session",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalkMetricRow(IconData icon, String title, String val, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ),
        Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: color)),
      ],
    );
  }
}
