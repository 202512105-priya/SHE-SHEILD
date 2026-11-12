import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/local_database_service.dart';
import 'auth_screens.dart';

class GuardianLinkingScreen extends StatefulWidget {
  const GuardianLinkingScreen({super.key});

  @override
  State<GuardianLinkingScreen> createState() => _GuardianLinkingScreenState();
}

class _GuardianLinkingScreenState extends State<GuardianLinkingScreen> {
  final LocalDatabaseService _api = LocalDatabaseService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _relationController = TextEditingController(text: 'Mother');
  final _phoneController = TextEditingController();

  bool _loading = true;
  bool _submitting = false;
  List<Map<String, dynamic>> _connections = const [];
  List<Map<String, dynamic>> _invitations = const [];
  Map<String, dynamic>? _lastInviteResult;

  @override
  void initState() {
    super.initState();
    _loadNetwork();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _relationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadNetwork() async {
    setState(() => _loading = true);
    final res = await _api.getGuardianNetwork();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success && res.data != null) {
        _connections = (res.data!['connections'] is List)
            ? (res.data!['connections'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
            : const [];
        _invitations = (res.data!['invitations'] is List)
            ? (res.data!['invitations'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
            : const [];
      }
    });
  }

  Future<void> _sendLinkRequest() async {
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final rel = _relationController.text.trim();
    final name = _nameController.text.trim();

    if ((email.isEmpty && phone.isEmpty) || rel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter Guardian email or phone number, plus relationship.')),
      );
      return;
    }

    setState(() {
      _submitting = true;
      _lastInviteResult = null;
    });
    final res = await _api.requestGuardianConnection(
      email: email,
      phone: phone,
      guardianName: name,
      relationship: rel,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (!res.success || res.data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.error ?? 'Failed to send guardian request.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    setState(() {
      _lastInviteResult = res.data;
    });
    await _loadNetwork();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res.data!['message']?.toString() ?? 'Guardian request processed.'),
        backgroundColor: Colors.teal.shade700,
      ),
    );
  }

  Future<void> _revokeConnection(String connectionId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revoke Guardian Access?'),
        content: const Text(
          'This guardian will immediately lose access to monitor your live journeys and SOS alerts.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Revoke Access'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final res = await _api.revokeGuardianConnection(connectionId);
    if (!mounted) return;
    if (res.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Guardian access revoked immediately.')),
      );
      await _loadNetwork();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.error ?? 'Failed to revoke access.'), backgroundColor: Colors.red.shade700),
      );
    }
  }

  String _fullInviteUrl(String path) {
    final clean = path.startsWith('#') ? path : '#$path';
    try {
      final base = Uri.base;
      if (base.scheme == 'http' || base.scheme == 'https') {
        return '${base.origin}/$clean';
      }
    } catch (_) {}
    return clean;
  }

  @override
  Widget build(BuildContext context) {
    final activeConns = _connections.where((c) => c['status'] == 'ACCEPTED').toList();
    final pendingConns = _connections.where((c) => c['status'] == 'PENDING').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guardian Linking & Network'),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(onPressed: _loadNetwork, icon: const Icon(Icons.refresh), tooltip: 'Refresh'),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.person_add_alt_1, color: Colors.teal.shade800, size: 26),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Add Trusted Guardian",
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal.shade900),
                                    ),
                                    const Text(
                                      "Connect an existing Guardian account or send a secure join invitation.",
                                      style: TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: "Guardian Name (optional for existing accounts)",
                              hintText: "e.g. Sunita",
                              prefixIcon: Icon(Icons.person_outline, color: Colors.teal.shade700),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: "Guardian Registered Email",
                              hintText: "guardian@example.com",
                              prefixIcon: Icon(Icons.email, color: Colors.teal.shade700),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: "Guardian Phone Number",
                              hintText: "+91 9876543210",
                              prefixIcon: Icon(Icons.phone, color: Colors.teal.shade700),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _relationController,
                            decoration: InputDecoration(
                              labelText: "Relationship",
                              hintText: "Mother, Father, Sister, Friend...",
                              prefixIcon: Icon(Icons.family_restroom, color: Colors.teal.shade700),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                          const SizedBox(height: 16),

                          ElevatedButton.icon(
                            onPressed: _submitting ? null : _sendLinkRequest,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              backgroundColor: Colors.teal.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: _submitting
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.send_rounded),
                            label: Text(
                              _submitting ? "Processing..." : "Send Connection / Invitation",
                              style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
                            ),
                          ),

                          if (_lastInviteResult != null && _lastInviteResult!['invitePath'] != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.orange.shade400),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Invitation Link Created', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Text(_lastInviteResult!['deliveryMessage']?.toString() ?? '', style: const TextStyle(fontSize: 12)),
                                  const SizedBox(height: 6),
                                  SelectableText(
                                    _fullInviteUrl(_lastInviteResult!['invitePath'].toString()),
                                    style: TextStyle(fontSize: 12, color: Colors.teal.shade900, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white),
                                    onPressed: () async {
                                      await Clipboard.setData(
                                        ClipboardData(text: _fullInviteUrl(_lastInviteResult!['invitePath'].toString())),
                                      );
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Guardian invitation link copied!')),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.copy, size: 16),
                                    label: const Text('Copy Registration Invite Link'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Connected Guardians Card
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Connected Guardians (${activeConns.length})",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal.shade900),
                              ),
                              if (_loading)
                                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (activeConns.isEmpty)
                            Text(
                              "No accepted guardians yet. Send a request above and ask them to accept from their Guardian Dashboard.",
                              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
                            )
                          else
                            ...activeConns.map((c) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.teal.shade100,
                                    child: Text(
                                      (c['guardianName']?.toString() ?? 'G').substring(0, 1).toUpperCase(),
                                      style: TextStyle(color: Colors.teal.shade900, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  title: Text(c['guardianName']?.toString() ?? 'Guardian', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text("${c['relationship']} • ${c['email']}\n${c['phone']}"),
                                  isThreeLine: true,
                                  trailing: OutlinedButton(
                                    onPressed: () => _revokeConnection(c['id'].toString()),
                                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700),
                                    child: const Text('Revoke'),
                                  ),
                                )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Pending Requests & Sent Invitations
                    if (pendingConns.isNotEmpty || _invitations.isNotEmpty)
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Pending Requests & Invitations",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal.shade900),
                            ),
                            const SizedBox(height: 10),
                            ...pendingConns.map((c) => ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.hourglass_top, color: Colors.orange),
                                  title: Text("${c['guardianName']} (${c['relationship']})"),
                                  subtitle: Text("Waiting for guardian approval • ${c['email']}"),
                                  trailing: TextButton(
                                    onPressed: () => _revokeConnection(c['id'].toString()),
                                    child: const Text('Cancel'),
                                  ),
                                )),
                            ..._invitations.map((inv) => ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(
                                    inv['status'] == 'ACCEPTED' ? Icons.check_circle : Icons.mail_outline,
                                    color: inv['status'] == 'ACCEPTED' ? Colors.green : Colors.orange,
                                  ),
                                  title: Text("${inv['guardianName']} (${inv['relationship']})"),
                                  subtitle: Text("Status: ${inv['status']} • ${inv['email'] ?? inv['phone']}"),
                                )),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
