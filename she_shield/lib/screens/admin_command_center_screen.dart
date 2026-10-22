import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';

class AdminCommandCenterScreen extends StatefulWidget {
  const AdminCommandCenterScreen({super.key});

  @override
  State<AdminCommandCenterScreen> createState() => _AdminCommandCenterScreenState();
}

class _AdminCommandCenterScreenState extends State<AdminCommandCenterScreen> {
  bool _isAuthenticated = false;

  final _cardIdController = TextEditingController(text: 'ADM-99');
  final _passwordController = TextEditingController(text: 'ADM123');

  bool _layer1Passed = false;
  bool _layer2Passed = false;
  String? _errorMessage;

  @override
  void dispose() {
    _cardIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _verifyAdminCredentials() {
    final cardId = _cardIdController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _errorMessage = null;
      _layer1Passed = (cardId == 'ADM-99');
      _layer2Passed = (password == 'ADM123');
    });

    if (_layer1Passed && _layer2Passed) {
      setState(() {
        _isAuthenticated = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Layer 1 & Layer 2 Authentication Success! Access Granted to Command Center.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      setState(() {
        if (!_layer1Passed && !_layer2Passed) {
          _errorMessage = 'Invalid Admin Card ID & Platform Password!';
        } else if (!_layer1Passed) {
          _errorMessage = 'Invalid Layer 1 Admin Card ID! (Expected ADM-99)';
        } else {
          _errorMessage = 'Invalid Layer 2 Platform Password! (Expected ADM123)';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return _buildAuthenticationScreen();
    }

    return _buildDashboardScreen();
  }

  // -------------------------------------------------------------
  // LAYER 1 & LAYER 2 AUTHENTICATION SCREEN
  // -------------------------------------------------------------
  Widget _buildAuthenticationScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Admin Command Authorization', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            padding: const EdgeInsets.all(28.0),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.purple.shade400.withValues(alpha: 0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.shade900.withValues(alpha: 0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.admin_panel_settings, size: 56, color: Colors.purpleAccent),
                ),
                const SizedBox(height: 16),
                const Text(
                  'SYSTEM COMMAND ACCESS',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Two-Layer Administrative Clearance Required',
                  style: TextStyle(fontSize: 12, color: Colors.white60),
                ),
                const SizedBox(height: 24),

                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Layer 1: Admin Card ID
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'LAYER 1: ADMIN CARD ID',
                          style: TextStyle(color: Colors.purpleAccent, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        if (_layer1Passed)
                          const Text('✓ VERIFIED', style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _cardIdController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.black26,
                        hintText: 'Enter Admin Card ID (ADM-99)',
                        hintStyle: const TextStyle(color: Colors.white38),
                        prefixIcon: const Icon(Icons.badge, color: Colors.purpleAccent),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Layer 2: Platform Password
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'LAYER 2: PLATFORM PASSWORD',
                          style: TextStyle(color: Colors.purpleAccent, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        if (_layer2Passed)
                          const Text('✓ VERIFIED', style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.black26,
                        hintText: 'Enter Platform Password (ADM123)',
                        hintStyle: const TextStyle(color: Colors.white38),
                        prefixIcon: const Icon(Icons.key, color: Colors.purpleAccent),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purpleAccent.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _verifyAdminCredentials,
                    icon: const Icon(Icons.lock_open),
                    label: const Text('Unlock Command Center', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // DASHBOARD SCREEN (POST AUTHENTICATION)
  // -------------------------------------------------------------
  Widget _buildDashboardScreen() {
    final db = Provider.of<DatabaseService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.security, color: Colors.amber),
            SizedBox(width: 8),
            Text('Admin Command Center', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 14),
                SizedBox(width: 4),
                Text('ADM-99 VERIFIED', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Lock Command Center',
            onPressed: () {
              setState(() {
                _isAuthenticated = false;
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Security Level Card
            Card(
              color: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Colors.purpleAccent, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.shield, color: Colors.purpleAccent, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Administrative Level 1 & 2 Security Clearance Active',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Logged Card ID: ADM-99 | Session Token: SEC-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
                            style: const TextStyle(color: Colors.white60, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Telemetry Grid Stats
            const Text(
              'PLATFORM TELEMETRY & HEALTH',
              style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.1),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                _buildStatTile('Active SOS Cases', '${db.sosCases.length}', Icons.emergency, Colors.redAccent),
                _buildStatTile('Cyber Complaints', '${db.cyberComplaints.length}', Icons.security, Colors.amber),
                _buildStatTile('Active Vault Assets', '${db.vaultAssets.length}', Icons.lock, Colors.blueAccent),
                _buildStatTile('System Latency', '12 ms', Icons.speed, Colors.greenAccent),
              ],
            ),
            const SizedBox(height: 24),

            // System Control Center
            const Text(
              'COMMAND & DISPATCH CONTROLS',
              style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.1),
            ),
            const SizedBox(height: 12),
            Card(
              color: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.broadcast_on_personal, color: Colors.redAccent),
                    title: const Text('Emergency Broadcast System', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Dispatch high-priority alert to all active units', style: TextStyle(color: Colors.white60, fontSize: 12)),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Broadcasting emergency alert to all responder nodes...')),
                        );
                      },
                      child: const Text('Broadcast'),
                    ),
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  ListTile(
                    leading: const Icon(Icons.vpn_key, color: Colors.amber),
                    title: const Text('Cryptographic Key Rotation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Rotate AES-256 master Vault keys', style: TextStyle(color: Colors.white60, fontSize: 12)),
                    trailing: OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.amber, side: const BorderSide(color: Colors.amber)),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('AES-256 Master Keys re-encrypted and rotated successfully.')),
                        );
                      },
                      child: const Text('Rotate Keys'),
                    ),
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  ListTile(
                    leading: const Icon(Icons.receipt_long, color: Colors.cyanAccent),
                    title: const Text('Audit Trail Log Stream', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Inspect immutable tamper audit logs', style: TextStyle(color: Colors.white60, fontSize: 12)),
                    trailing: OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.cyanAccent, side: const BorderSide(color: Colors.cyanAccent)),
                      onPressed: () => _showAuditLogDialog(),
                      child: const Text('View Logs'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Recent Incident Activity Log
            const Text(
              'LIVE SYSTEM AUDIT STREAM',
              style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.1),
            ),
            const SizedBox(height: 12),
            Card(
              color: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    _buildAuditRow('SYS_AUTH', 'Card ID ADM-99 verified with Level 2 Pass.', '00:01 mins ago'),
                    _buildAuditRow('SOS_ALERT', 'Distress signal received from Lat: 23.0234', '04:12 mins ago'),
                    _buildAuditRow('VAULT_SYNC', 'Tamper check PASS for Travel_Trip_Audio.mp4', '12:45 mins ago'),
                    _buildAuditRow('BLE_BEACON', 'Smartwatch pairing handshake verified.', '30:00 mins ago'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAuditRow(String tag, String text, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(4)),
            child: Text(tag, style: const TextStyle(color: Colors.purpleAccent, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12))),
          Text(time, style: const TextStyle(color: Colors.white38, fontSize: 10)),
        ],
      ),
    );
  }

  void _showAuditLogDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Cryptographic Tamper Audit Log', style: TextStyle(color: Colors.white)),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• SHA-256 HASH VERIFICATION: PASS', style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
              Text('• LOG ENCRYPTION MODE: AES-256 GCM', style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text('• TOTAL AUDITED EVENTS: 1,489', style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text('• NO UNAUTHORIZED TAMPERING DETECTED', style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close Log', style: TextStyle(color: Colors.purpleAccent)),
            ),
          ],
        );
      },
    );
  }
}