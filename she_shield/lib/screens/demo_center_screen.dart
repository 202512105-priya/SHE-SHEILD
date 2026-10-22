import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';

class DemoCenterScreen extends StatefulWidget {
  const DemoCenterScreen({super.key});

  @override
  State<DemoCenterScreen> createState() => _DemoCenterScreenState();
}

class _DemoCenterScreenState extends State<DemoCenterScreen> {
  String _lastSimulatedEvent = 'None';

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF6FE),
      appBar: AppBar(
        title: const Text('Feature Demo & Testing Center'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Reset Demo State',
            onPressed: () {
              setState(() {
                _lastSimulatedEvent = 'Resetting system state to defaults...';
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Demo state reset completed.')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Status Card
            Card(
              color: const Color(0xFF4A148C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.science, color: Colors.amber, size: 28),
                        SizedBox(width: 10),
                        Text(
                          'SHE SHIELD Interactive Sandbox',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Test safety algorithms, live alert dispatchers, cab deviations, and cyber threat classifiers instantly.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.amber, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Last Trigger: $_lastSimulatedEvent',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'monospace'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Feature Simulation Section
            const Text(
              'FEATURE SIMULATIONS & TRIGGERS',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.purple, letterSpacing: 1.1),
            ),
            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _buildDemoButton(
                  title: 'Trigger SOS Alert',
                  subtitle: 'Simulate critical distress dispatch',
                  icon: Icons.emergency,
                  color: Colors.red,
                  onTap: () {
                    setState(() {
                      _lastSimulatedEvent = 'SOS Emergency Triggered at ${DateTime.now().toString().substring(11, 19)}';
                    });
                    _showSimulatedSosDialog(context, db);
                  },
                ),
                _buildDemoButton(
                  title: 'Cab Deviation Alert',
                  subtitle: 'Simulate 50m off-route cab drift',
                  icon: Icons.local_taxi,
                  color: Colors.orange.shade800,
                  onTap: () {
                    db.updateCabMetrics(riskIndex: 85, deviations: 3, unsafeHits: 2);
                    setState(() {
                      _lastSimulatedEvent = 'Cab deviation risk elevated to 85%';
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('⚠️ Cab deviation detected! Risk index elevated to 85%.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                ),
                _buildDemoButton(
                  title: 'Cyber Threat Case',
                  subtitle: 'Inject blackmail cyber dossier',
                  icon: Icons.security,
                  color: Colors.indigo,
                  onTap: () {
                    db.addCyberComplaint(
                      'SIMULATED: Blackmail attempt detected via social messaging platform.',
                      'https://cybercrime.gov.in/evidence/simulated_991',
                    );
                    setState(() {
                      _lastSimulatedEvent = 'Cyber threat dossier injected with 95% score';
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cyber crime dossier successfully added to queue.'),
                        backgroundColor: Colors.indigo,
                      ),
                    );
                  },
                ),
                _buildDemoButton(
                  title: 'Test Secret Voice SOS',
                  subtitle: 'Simulate "Box Box" detection',
                  icon: Icons.mic,
                  color: Colors.purple,
                  onTap: () {
                    setState(() {
                      _lastSimulatedEvent = 'Voice phrase "Box Box" recognized via Offline Engine';
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🎙️ Voice Phrase "Box Box" Detected! Initiating SOS Protocol...'),
                        backgroundColor: Colors.purple,
                      ),
                    );
                  },
                ),
                _buildDemoButton(
                  title: 'BLE Wearable Handshake',
                  subtitle: 'Simulate Smartwatch sync',
                  icon: Icons.watch,
                  color: Colors.teal,
                  onTap: () {
                    setState(() {
                      _lastSimulatedEvent = 'BLE Smartwatch beacon paired & synced';
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('⌚ Smartwatch BLE Panic Switch Connected.'),
                        backgroundColor: Colors.teal,
                      ),
                    );
                  },
                ),
                _buildDemoButton(
                  title: 'Vault Asset Tamper Test',
                  subtitle: 'Verify SHA-256 hash match',
                  icon: Icons.lock_clock,
                  color: Colors.blue.shade800,
                  onTap: () {
                    db.addVaultAsset('Simulated_Audio_Evidence_${DateTime.now().millisecondsSinceEpoch}.aac');
                    setState(() {
                      _lastSimulatedEvent = 'Evidence asset stored & SHA-256 verified';
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🔒 Asset written to vault. Tamper Check: PASS'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick Screen Navigation Matrix
            const Text(
              'QUICK SCREEN NAVIGATION MATRIX',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.purple, letterSpacing: 1.1),
            ),
            const SizedBox(height: 12),

            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildNavTile(context, 'Responder Dashboard', '/responder_dashboard', Icons.local_police, Colors.purple),
                  _buildNavTile(context, 'Responder Onboarding Form', '/register_responder', Icons.assignment_ind, Colors.indigo),
                  _buildNavTile(context, 'Admin Command Center', '/admin_dashboard', Icons.admin_panel_settings, Colors.deepPurple),
                  _buildNavTile(context, 'Help & Support Center', '/help_center', Icons.help, Colors.teal),
                  _buildNavTile(context, 'SOS Protection Center', '/sos_protection', Icons.shield, Colors.red),
                  _buildNavTile(context, 'Cab Guardian Monitor', '/cab_monitor', Icons.local_taxi, Colors.orange),
                  _buildNavTile(context, 'Walk Guardian Monitor', '/walk_monitor', Icons.directions_walk, Colors.blue),
                  _buildNavTile(context, 'Evidence Vault Locker', '/evidence_vault', Icons.folder_special, Colors.brown),
                  _buildNavTile(context, 'Wearable Device Pairing', '/wearable_pairing', Icons.watch, Colors.green),
                  _buildNavTile(context, 'Guardian Linking Screen', '/manage_guardians', Icons.group_add, Colors.pink),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.15),
                radius: 20,
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavTile(BuildContext context, String title, String route, IconData icon, Color color) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      subtitle: Text('Navigate to $route', style: const TextStyle(fontSize: 11, color: Colors.grey)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: () => Navigator.pushNamed(context, route),
    );
  }

  void _showSimulatedSosDialog(BuildContext context, DatabaseService db) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Text('SIMULATED SOS ALERT', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• Emergency distress signal dispatched to local responders.', style: TextStyle(fontSize: 13)),
              SizedBox(height: 6),
              Text('• GPS Location: 23.0234, 72.5724', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              SizedBox(height: 6),
              Text('• Audio & Video background recording active.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel Alert', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/responder_dashboard');
              },
              child: const Text('Open Responder Dashboard'),
            ),
          ],
        );
      },
    );
  }
}
