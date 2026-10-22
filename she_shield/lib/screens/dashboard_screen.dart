import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../widgets/jira_backlog_dialog.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Timer? _sosTimer;
  int _countdown = 5;
  bool _isHoldingSos = false;

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

  void _triggerSmartShieldSosPortal() {
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
              child: const Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("GPS Coordinates:", style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text("23.0225° N, 72.5714° E", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Device Battery:", style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text("88% (Optimal)", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Signal Mesh:", style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text("Active • 4 BLE Relays", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 13)),
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
                      "Live SOS alert dispatched to PCR Police Grid & Linked Guardians!",
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
            child: const Text("False Alarm / Enter PIN", style: TextStyle(color: Colors.white70)),
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
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Initiating Direct 112 Emergency Dispatch Call...")),
              );
            },
          ),
        ],
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
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hello, ${db.userName}!",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      "SHE SHIELD Security Core Active",
                      style: TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  final nextVal = !db.vivaPrototypeMode;
                  db.toggleVivaPrototypeMode(nextVal);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(nextVal
                          ? "Viva Prototype Mode: Backlog modals enabled for future sprints"
                          : "Full Running App Mode: All modules fully unlocked"),
                      duration: const Duration(seconds: 2),
                      backgroundColor: nextVal ? Colors.amber.shade900 : Colors.purple.shade900,
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: db.vivaPrototypeMode ? Colors.amber.shade400 : Colors.green.shade600,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        db.vivaPrototypeMode ? Icons.science_outlined : Icons.verified_user,
                        color: db.vivaPrototypeMode ? Colors.brown.shade900 : Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        db.vivaPrototypeMode ? "Prototype Mode" : "Full App",
                        style: TextStyle(
                          color: db.vivaPrototypeMode ? Colors.brown.shade900 : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Safety Index Card / Gauge
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [Colors.purple.shade900, Colors.purple.shade700],
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "SAFETY INDEX GAUGE",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "AI Protection Layer Active",
                                  style: TextStyle(color: Colors.white, fontSize: 14),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.greenAccent.shade400,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                db.riskTrend,
                                style: TextStyle(
                                  color: Colors.green.shade900,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Score Display & Gauge Bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "${db.safetyIndex}%",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "STABLE SAFE",
                                  style: TextStyle(
                                    color: Colors.greenAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  "0 Active Threat Vectors",
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: db.safetyIndex / 100.0,
                            minHeight: 10,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

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
                  children: [
                    _FeatureTile(
                      title: "SOS Protection Center",
                      subtitle: "Voice & Hardware Triggers",
                      icon: Icons.shield_moon,
                      color: Colors.red.shade700,
                      route: '/sos_protection',
                      ticketId: "SHE-201",
                      sprintName: "Sprint 2 (Current Sprint)",
                      description: "Hardware button sequences, custom voice recognition ('Box Box'), silent panic dispatch, and offline fallback queue.",
                      plannedFeatures: const [
                        "Hardware Power/Vol Button Interceptor",
                        "Multilingual Offline NLU Voice SOS",
                        "Zero-Network SMS Fallback Dispatch",
                      ],
                      isBacklogItem: true,
                    ),
                    _FeatureTile(
                      title: "Safe Arrival Travel Mode",
                      subtitle: "Route & Time Guardian",
                      icon: Icons.card_travel,
                      color: Colors.teal.shade700,
                      route: '/travel_monitor',
                      ticketId: "SHE-202",
                      sprintName: "Sprint 2 (Current Sprint)",
                      description: "Countdown safety timeline with automated welfare check-ins and blackbox background audio/video recording.",
                      plannedFeatures: const [
                        "Safety Timeline Countdown Clock",
                        "Background Audio/Video Recording Modes",
                        "Automated Guardian Arrival Ping",
                      ],
                      isBacklogItem: true,
                    ),
                    _FeatureTile(
                      title: "Wearables Integration",
                      subtitle: "Smart Ring, Band & Watch",
                      icon: Icons.watch,
                      color: Colors.deepPurple,
                      route: '/wearable_pairing',
                      ticketId: "SHE-301",
                      sprintName: "Sprint 3 (Backlog)",
                      description: "Bluetooth Low Energy integration for Smart Rings, Smart Bands, and Emergency Pendants with hardware distress triggers.",
                      plannedFeatures: const [
                        "BLE GATT Handshake & Battery Telemetry",
                        "Sub-second Latency Hardware Panic Trigger",
                        "Zero-Cellular Mesh Relay",
                      ],
                      isBacklogItem: true,
                    ),
                    _FeatureTile(
                      title: "Report Cyber Crime",
                      subtitle: "AI Threat & Blackmail",
                      icon: Icons.security,
                      color: Colors.pink.shade700,
                      route: '/cyber_report',
                      ticketId: "SHE-203",
                      sprintName: "Sprint 2 (Current Sprint)",
                      description: "NLP threat evaluation engine for blackmail, cyberstalking, and instant cyber cell dossier generation.",
                      plannedFeatures: const [
                        "AI Threat Classification (Blackmail/Harassment)",
                        "Offender URL & Screenshot Ingestion",
                        "Direct National Cyber Crime Portal Link",
                      ],
                      isBacklogItem: true,
                    ),
                    _FeatureTile(
                      title: "Upload Evidence Vault",
                      subtitle: "Blockchain Hashed Media",
                      icon: Icons.enhanced_encryption,
                      color: Colors.indigo.shade700,
                      route: '/evidence_vault',
                      ticketId: "SHE-302",
                      sprintName: "Sprint 3 (Backlog)",
                      description: "Tamper-proof digital locker with dynamic SHA-256 integrity hash seals and legal chain of custody audit logs.",
                      plannedFeatures: const [
                        "SHA-256 Hashing at Ingestion",
                        "AI Deepfake & Metadata Forensic Scanner",
                        "Immutable Chain of Custody PDF Export",
                      ],
                      isBacklogItem: true,
                    ),
                    _FeatureTile(
                      title: "Cab Monitoring",
                      subtitle: "Plate Score & Deviation",
                      icon: Icons.local_taxi,
                      color: Colors.amber.shade900,
                      route: '/cab_monitor',
                      ticketId: "SHE-104",
                      sprintName: "Sprint 1 (Done / Live Prototype)",
                      description: "Vehicle registration plate validation, cab safety trust scores, and journey tracking.",
                      plannedFeatures: const [
                        "Registration Plate Number Lookup",
                        "Cab Safety Trust Index Score",
                        "Safe Journey Start & Reached Status",
                      ],
                      isBacklogItem: false, // Live Prototype!
                    ),
                    _FeatureTile(
                      title: "Walk Monitoring",
                      subtitle: "Motion Anomaly Detector",
                      icon: Icons.directions_walk,
                      color: Colors.blue.shade700,
                      route: '/walk_monitor',
                      ticketId: "SHE-204",
                      sprintName: "Sprint 2 (Current Sprint)",
                      description: "Real-time motion anomaly detection for phone drop, phone snatching, running, and sudden halts.",
                      plannedFeatures: const [
                        "Device Accelerometer Motion Tracking",
                        "Periodic Safety PIN Verification",
                        "10-Second Auto-Escalation Countdown",
                      ],
                      isBacklogItem: true,
                    ),
                    _FeatureTile(
                      title: "Complaint Status",
                      subtitle: "Track Cyber Filings",
                      icon: Icons.assignment_turned_in,
                      color: Colors.orange.shade800,
                      route: '/complaint_status',
                      ticketId: "SHE-205",
                      sprintName: "Sprint 2 (Current Sprint)",
                      description: "5-stage lifecycle tracker for cyber complaints from AI analysis to law enforcement action.",
                      plannedFeatures: const [
                        "Real-time Case Timeline Stepper",
                        "Official Case Index Status",
                        "Resolution & Takedown Notices",
                      ],
                      isBacklogItem: true,
                    ),
                    _FeatureTile(
                      title: "Manage Guardians",
                      subtitle: "Linked Family Network",
                      icon: Icons.people,
                      color: Colors.purple.shade700,
                      route: '/manage_guardians',
                      ticketId: "SHE-206",
                      sprintName: "Sprint 2 (Current Sprint)",
                      description: "Trusted contact onboarding with 4-stage link verification stepper and live emergency dispatch routing.",
                      plannedFeatures: const [
                        "Guardian Invitation & OTP Handshake",
                        "4-Stage Link Approval Stepper",
                        "Direct Dial & Perimeter Alerts",
                      ],
                      isBacklogItem: true,
                    ),
                    _FeatureTile(
                      title: "Awareness Hub",
                      subtitle: "Safety Guides & Legal Rights",
                      icon: Icons.menu_book,
                      color: Colors.green.shade800,
                      route: '/awareness_hub',
                      ticketId: "SHE-303",
                      sprintName: "Sprint 3 (Backlog)",
                      description: "Educational modules on cyber safety, self-defense legal rights, and emergency preparedness.",
                      plannedFeatures: const [
                        "Offline Legal Rights & Cyber Guides",
                        "Interactive Pepper Spray Protocol",
                        "Emergency Helpline Directory",
                      ],
                      isBacklogItem: true,
                    ),
                  ],
                ),
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
  final String ticketId;
  final String sprintName;
  final String description;
  final List<String> plannedFeatures;
  final bool isBacklogItem;

  const _FeatureTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
    required this.ticketId,
    required this.sprintName,
    required this.description,
    this.plannedFeatures = const [],
    this.isBacklogItem = true,
  });

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    final inPrototypeMode = db.vivaPrototypeMode;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (inPrototypeMode && isBacklogItem) {
            JiraBacklogDialog.show(
              context,
              ticketId: ticketId,
              title: title,
              description: description,
              route: route,
              estimatedSprint: sprintName,
              plannedFeatures: plannedFeatures,
            );
          } else {
            Navigator.pushNamed(context, route);
          }
        },
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
                  if (inPrototypeMode)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isBacklogItem ? Colors.amber.shade100 : Colors.green.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isBacklogItem ? ticketId : "SPRINT 1",
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isBacklogItem ? Colors.amber.shade900 : Colors.green.shade900,
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
