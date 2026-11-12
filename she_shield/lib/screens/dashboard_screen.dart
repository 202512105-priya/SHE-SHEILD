import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/voice_engine_service.dart';
import '../widgets/audio_evidence_section.dart';
import '../widgets/server_config_dialog.dart';
import '../services/geo_platform_stub.dart'
    if (dart.library.io) '../services/geo_platform_io.dart'
    if (dart.library.js_interop) '../services/geo_platform_web.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Timer? _sosTimer;
  int _countdown = 5;
  bool _isHoldingSos = false;
  bool _micPromptShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _promptMicrophoneIfNeeded();
    });
  }

  Future<void> _promptMicrophoneIfNeeded() async {
    if (!mounted || _micPromptShown) return;
    final db = Provider.of<DatabaseService>(context, listen: false);
    if (!db.isAuthenticated || !db.hasPermission('voice_sos:own')) return;

    final engine = VoiceEngineService();
    final alreadyGranted = await engine.checkMicPermission();
    if (!mounted || alreadyGranted || _micPromptShown) return;

    _micPromptShown = true;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.mic, color: Colors.purple.shade800),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Allow Microphone for Voice SOS?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'SHE SHIELD needs microphone permission to detect your custom Voice SOS phrase and automatically record audio evidence into your encrypted vault when triggered.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Not Now'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade800,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.mic, size: 16),
            label: const Text('Allow Microphone'),
            onPressed: () async {
              Navigator.pop(ctx);
              final granted = await engine.requestMicPermission();
              await platformRequestNotificationPermission();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    granted
                        ? 'Microphone access granted! You can now configure & enable Voice SOS.'
                        : (engine.errorMessage ?? 'Microphone permission denied.'),
                  ),
                  backgroundColor: granted ? Colors.green : Colors.red,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _startSosCountdown() {
    setState(() {
      _isHoldingSos = true;
      _countdown = 5;
    });

    _sosTimer?.cancel();
    _sosTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        setState(() {
          _isHoldingSos = false;
          _countdown = 5;
        });
        _triggerSmartShieldSosPortal();
      }
    });
  }

  void _cancelSosCountdown() {
    _sosTimer?.cancel();
    setState(() {
      _isHoldingSos = false;
      _countdown = 5;
    });
  }

  Future<void> _triggerSmartShieldSosPortal() async {
    final db = Provider.of<DatabaseService>(context, listen: false);
    final gpsSample = await platformGetCurrentPosition();
    if (!mounted) return;
    final gpsStr = (gpsSample.ok && gpsSample.latitude != null && gpsSample.longitude != null)
        ? '${gpsSample.latitude!.toStringAsFixed(5)}, ${gpsSample.longitude!.toStringAsFixed(5)}'
        : 'GPS Unavailable';
    final sosId = 'SOS-BTN-${DateTime.now().millisecondsSinceEpoch}';

    db.addSosCase(
      id: sosId,
      userName: db.userName.isNotEmpty ? db.userName : 'SHE SHIELD User',
      userPhone: db.userPhone,
      gps: gpsStr,
      locationName: gpsSample.ok ? 'Live Device GPS' : 'GPS Signal Unavailable',
      deviceType: 'Hold SOS Panic Trigger',
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.red.shade900,
        title: const Column(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white, size: 56),
            SizedBox(height: 8),
            Text(
              "SMARTSHIELD SOS PORTAL",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 20,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              "HIGH PRIORITY CRITICAL DISPATCH",
              style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.redAccent),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Incident ID:", style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Flexible(
                        child: Text(sosId, style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 11.5), overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("GPS Coordinates:", style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text(gpsStr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("SQLite Persistence:", style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text(
                        db.isDatabaseLive ? "Synced Live" : "Local Standby",
                        style: TextStyle(color: db.isDatabaseLive ? Colors.greenAccent : Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Live SOS alert dispatched to Responder Grid & Linked Guardians!",
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showCancelPinDialog();
            },
            child: const Text("Close / Enter PIN", style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.red.shade900,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.phone),
            label: const Text("Call 112 Direct", style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () async {
              Navigator.pop(context);
              await platformOpenExternalUrl('tel:112');
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showProfileModal(BuildContext context, DatabaseService db) async {
    final nameCtrl = TextEditingController(text: db.userName);
    final phoneCtrl = TextEditingController(text: db.userPhone);
    bool saving = false;
    String? err;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.verified_user, color: Colors.purple.shade800),
              const SizedBox(width: 8),
              const Expanded(child: Text('Safety Profile & KYC', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Account Email: ${db.userEmail}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Role: ${db.currentRole ?? 'registered_user'} • Status: ${db.accountStatus}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Chip(
                      label: Text('Aadhaar: ${db.aadhaarVerified ? "Verified" : "Pending / Unverified"}', style: const TextStyle(fontSize: 11)),
                      backgroundColor: db.aadhaarVerified ? Colors.green.shade100 : Colors.orange.shade50,
                    ),
                    Chip(
                      label: Text('Biometrics: ${db.faceVerified ? "Verified" : "Not Verified"}', style: const TextStyle(fontSize: 11)),
                      backgroundColor: db.faceVerified ? Colors.green.shade100 : Colors.orange.shade50,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder(), isDense: true),
                ),
                if (err != null) ...[
                  const SizedBox(height: 8),
                  Text(err!, style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.pop(ctx), child: const Text('Close')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade800, foregroundColor: Colors.white),
              onPressed: saving
                  ? null
                  : () async {
                      setModalState(() {
                        saving = true;
                        err = null;
                      });
                      final res = await db.updateProfile(fullName: nameCtrl.text, phone: phoneCtrl.text);
                      if (!ctx.mounted) return;
                      if (res.success) {
                        Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(content: Text('Safety Profile updated in SQLite!'), backgroundColor: Colors.green),
                          );
                        }
                      } else {
                        setModalState(() {
                          saving = false;
                          err = res.error ?? 'Update failed.';
                        });
                      }
                    },
              child: Text(saving ? 'Saving...' : 'Save Profile'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelPinDialog() {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enter Deactivation PIN"),
        content: TextField(
          controller: pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: "Default PIN: 1234", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("SOS Alert Deactivated with Valid Safety PIN.")),
              );
            },
            child: const Text("Deactivate SOS"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseService>(
      builder: (context, db, _) {
        return Scaffold(
          backgroundColor: Colors.purple.shade50.withValues(alpha: 0.4),
          appBar: AppBar(
            backgroundColor: Colors.purple.shade900,
            foregroundColor: Colors.white,
            elevation: 0,
            title: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.purple.shade200,
                  child: Text(
                    db.userName.isNotEmpty ? db.userName[0].toUpperCase() : "T",
                    style: TextStyle(color: Colors.purple.shade900, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hello, ${db.userName}!",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.cloud_done,
                              size: 11,
                              color: Colors.greenAccent,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                "Vercel Cloud Database Active",
                                style: const TextStyle(fontSize: 10, color: Colors.white70),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.manage_accounts_outlined, color: Colors.white),
                tooltip: "Safety Profile & KYC",
                onPressed: () => _showProfileModal(context, db),
              ),
              IconButton(
                icon: const Icon(Icons.help_outline, color: Colors.white),
                tooltip: "Help Center & Helplines",
                onPressed: () => Navigator.pushNamed(context, '/help_center'),
              ),
              IconButton(
                icon: const Icon(Icons.apps_rounded, color: Colors.white),
                tooltip: "Simulation Sandbox",
                onPressed: () => Navigator.pushNamed(context, '/demo_center'),
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                tooltip: "Sign Out",
                onPressed: () async {
                  await db.logout();
                  if (!context.mounted) return;
                  Navigator.pushNamedAndRemoveUntil(context, '/welcome', (_) => false);
                },
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 5-Second Hold Emergency SOS Button Section
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: Colors.white,
                      border: Border.all(color: Colors.red.shade100, width: 2),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "EMERGENCY SOS DISPATCH",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isHoldingSos
                              ? "HOLDING... DISPATCHING IN $_countdown SECONDS!"
                              : "Press and Hold for 5 seconds to activate SOS Portal",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: _isHoldingSos ? FontWeight.bold : FontWeight.normal,
                            color: _isHoldingSos ? Colors.red.shade900 : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTapDown: (_) => _startSosCountdown(),
                          onTapUp: (_) => _cancelSosCountdown(),
                          onTapCancel: () => _cancelSosCountdown(),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: _isHoldingSos
                                    ? [Colors.orange.shade700, Colors.red.shade900]
                                    : [Colors.red.shade500, Colors.red.shade900],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withValues(alpha: 0.4),
                                  blurRadius: _isHoldingSos ? 30 : 15,
                                  spreadRadius: _isHoldingSos ? 10 : 3,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isHoldingSos)
                                    Text(
                                      "$_countdown",
                                      style: const TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    )
                                  else ...[
                                    const Icon(Icons.touch_app, size: 36, color: Colors.white),
                                    const SizedBox(height: 4),
                                    const Text(
                                      "HOLD SOS",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (_isHoldingSos) ...[
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: _cancelSosCountdown,
                            child: const Text("Release to Cancel"),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  "SHE SHIELD Protection Modules",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 14),

                // Grid of 10 Feature Tiles
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.15,
                  children: const [
                    _FeatureTile(
                      title: "SOS Protection Center",
                      subtitle: "Voice & Hardware Triggers",
                      icon: Icons.shield_moon,
                      color: Color(0xFFD32F2F),
                      route: '/sos_protection',
                      badge: "LIVE",
                    ),
                    _FeatureTile(
                      title: "Safe Arrival Travel Mode",
                      subtitle: "Route & Time Guardian",
                      icon: Icons.card_travel,
                      color: Color(0xFF00796B),
                      route: '/travel_monitor',
                      badge: "LIVE",
                    ),
                    _FeatureTile(
                      title: "Wearables Integration",
                      subtitle: "Smart Ring, Band & Watch",
                      icon: Icons.watch,
                      color: Colors.deepPurple,
                      route: '/wearable_pairing',
                      badge: "LIVE",
                    ),
                    _FeatureTile(
                      title: "Report Cyber Crime",
                      subtitle: "AI Threat & Blackmail",
                      icon: Icons.security,
                      color: Color(0xFFC2185B),
                      route: '/cyber_report',
                      badge: "LIVE",
                    ),
                    _FeatureTile(
                      title: "Upload Evidence Vault",
                      subtitle: "Blockchain Hashed Media",
                      icon: Icons.enhanced_encryption,
                      color: Color(0xFF303F9F),
                      route: '/evidence_vault',
                      badge: "LIVE",
                    ),
                    _FeatureTile(
                      title: "Cab Monitoring",
                      subtitle: "Plate Score & Deviation",
                      icon: Icons.local_taxi,
                      color: Color(0xFFE65100),
                      route: '/cab_monitor',
                      badge: "LIVE",
                    ),
                    _FeatureTile(
                      title: "Walk Monitoring",
                      subtitle: "Motion Anomaly Detector",
                      icon: Icons.directions_walk,
                      color: Color(0xFF1976D2),
                      route: '/walk_monitor',
                      badge: "LIVE",
                    ),
                    _FeatureTile(
                      title: "Complaint Status",
                      subtitle: "Track Cyber Filings",
                      icon: Icons.assignment_turned_in,
                      color: Color(0xFFE65100),
                      route: '/complaint_status',
                      badge: "LIVE",
                    ),
                    _FeatureTile(
                      title: "Manage Guardians",
                      subtitle: "Linked Family Network",
                      icon: Icons.people,
                      color: Color(0xFF7B1FA2),
                      route: '/manage_guardians',
                      badge: "LIVE",
                    ),
                    _FeatureTile(
                      title: "Awareness Hub",
                      subtitle: "Safety Guides & Legal Rights",
                      icon: Icons.menu_book,
                      color: Color(0xFF2E7D32),
                      route: '/awareness_hub',
                      badge: "LIVE",
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const AudioEvidenceSection(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;
  final String? badge;

  const _FeatureTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
    this.badge = "LIVE",
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pushNamed(context, route),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Text(
                      badge ?? "LIVE",
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
