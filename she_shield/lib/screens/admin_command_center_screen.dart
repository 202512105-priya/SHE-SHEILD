import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';

class AdminCommandCenterScreen extends StatefulWidget {
  const AdminCommandCenterScreen({super.key});

  @override
  State<AdminCommandCenterScreen> createState() => _AdminCommandCenterScreenState();
}

class _AdminCommandCenterScreenState extends State<AdminCommandCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _roles = [];
  List<Map<String, dynamic>> _auditLogs = [];
  bool _loadingUsers = false;
  bool _loadingLogs = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAdminData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshAdminData({String? query}) async {
    final db = Provider.of<DatabaseService>(context, listen: false);
    if (!db.isAuthenticated || db.currentRole != 'admin') return;

    setState(() {
      _loadingUsers = true;
      _loadingLogs = true;
      _loadError = null;
    });

    final q = query ?? _searchController.text.trim();
    final usersRes = await db.adminFetchUsers(query: q);
    final rolesRes = await db.adminFetchRoles();
    final logsRes = await db.adminFetchAuditLogs();
    await db.syncFromDatabase();

    if (!mounted) return;
    setState(() {
      _loadingUsers = false;
      _loadingLogs = false;
      if (usersRes.success && usersRes.data != null) {
        _users = usersRes.data!;
      } else {
        _loadError = usersRes.error ?? 'Failed to load users';
      }
      if (rolesRes.success && rolesRes.data != null) {
        _roles = rolesRes.data!;
      }
      if (logsRes.success && logsRes.data != null) {
        _auditLogs = logsRes.data!;
      }
    });
  }

  Future<void> _handleAssignRole(Map<String, dynamic> user) async {
    final db = Provider.of<DatabaseService>(context, listen: false);
    final availableRoles = _roles.isNotEmpty
        ? _roles
        : const [
            {'id': 'ROLE_USER', 'roleName': 'registered_user', 'description': 'Standard User'},
            {'id': 'ROLE_GUARDIAN', 'roleName': 'guardian', 'description': 'Guardian'},
            {'id': 'ROLE_OFFICER', 'roleName': 'officer', 'description': 'Officer / Responder'},
            {'id': 'ROLE_ADMIN', 'roleName': 'admin', 'description': 'System Admin'},
          ];

    String selectedRoleId = user['roleId']?.toString() ?? 'ROLE_USER';

    final confirmed = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text(
            'Assign Role — ${user['fullName']}',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: availableRoles.map((r) {
              final rid = r['id'].toString();
              final rname = r['roleName'].toString();
              final desc = r['description']?.toString() ?? '';
              final isSelected = selectedRoleId == rid;
              return ListTile(
                dense: true,
                onTap: () => setModalState(() => selectedRoleId = rid),
                leading: Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: Colors.purpleAccent,
                ),
                title: Text(rname.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text(desc, style: const TextStyle(color: Colors.white60, fontSize: 11)),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade700, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, selectedRoleId),
              child: const Text('Save Role'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == null || !mounted) return;
    final res = await db.adminAssignRole(userId: user['id'].toString(), roleId: confirmed);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res.success ? 'Updated role successfully.' : (res.error ?? 'Failed to update role')),
        backgroundColor: res.success ? Colors.green : Colors.red,
      ),
    );
    await _refreshAdminData();
  }

  Future<void> _handleToggleStatus(Map<String, dynamic> user) async {
    final db = Provider.of<DatabaseService>(context, listen: false);
    final current = user['accountStatus']?.toString() ?? 'ACTIVE';
    final nextStatus = current == 'ACTIVE' ? 'SUSPENDED' : 'ACTIVE';

    final res = await db.adminUpdateAccountStatus(
      userId: user['id'].toString(),
      accountStatus: nextStatus,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          res.success
              ? '${user['fullName']} is now $nextStatus'
              : (res.error ?? 'Failed to update status'),
        ),
        backgroundColor: res.success ? Colors.green : Colors.red,
      ),
    );
    await _refreshAdminData();
  }

  Future<void> _showCreateOfficerDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final badgeCtrl = TextEditingController();
    final stationCtrl = TextEditingController();
    bool obscure = true;
    bool saving = false;
    String? errorMsg;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Row(
            children: [
              Icon(Icons.local_police, color: Colors.amber),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Create Authorized Officer Account',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (errorMsg != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.redAccent),
                      ),
                      child: Text(errorMsg!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _darkField(nameCtrl, 'Officer Full Name', validator: (v) => (v == null || v.trim().length < 2) ? 'Enter valid name' : null),
                  const SizedBox(height: 10),
                  _darkField(emailCtrl, 'Official Email', validator: (v) => (v == null || !v.contains('@')) ? 'Enter valid email' : null),
                  const SizedBox(height: 10),
                  _darkField(phoneCtrl, 'Phone Number', validator: (v) => ((v ?? '').replaceAll(RegExp(r'\D'), '').length < 10) ? 'Enter 10-15 digits' : null),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: passwordCtrl,
                    obscureText: obscure,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Officer Password',
                      labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      suffixIcon: IconButton(
                        icon: Icon(obscure ? Icons.visibility : Icons.visibility_off, color: Colors.white60),
                        onPressed: () => setModalState(() => obscure = !obscure),
                      ),
                    ),
                    validator: (v) {
                      final pw = v ?? '';
                      if (pw.length < 8) return 'Min 8 chars';
                      if (!RegExp(r'[A-Z]').hasMatch(pw) ||
                          !RegExp(r'[a-z]').hasMatch(pw) ||
                          !RegExp(r'\d').hasMatch(pw) ||
                          !RegExp(r'''[!@#$%^&*(),.?":{}|<>_\-+=/\\;~\[\]]''').hasMatch(pw)) {
                        return 'Require upper, lower, digit & symbol';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  _darkField(badgeCtrl, 'Badge ID (e.g. POLICE-GJ-2026)'),
                  const SizedBox(height: 10),
                  _darkField(stationCtrl, 'Police Station / Unit'),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade700, foregroundColor: Colors.white),
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setModalState(() {
                        saving = true;
                        errorMsg = null;
                      });
                      final db = Provider.of<DatabaseService>(context, listen: false);
                      final res = await db.adminCreateOfficer(
                        fullName: nameCtrl.text,
                        email: emailCtrl.text,
                        phone: phoneCtrl.text,
                        password: passwordCtrl.text,
                        badgeId: badgeCtrl.text,
                        station: stationCtrl.text,
                      );
                      if (!ctx.mounted) return;
                      if (res.success) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Officer ${nameCtrl.text.trim()} provisioned in Cloud Database!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        _refreshAdminData();
                      } else {
                        setModalState(() {
                          saving = false;
                          errorMsg = res.error ?? 'Failed to create officer';
                        });
                      }
                    },
              child: Text(saving ? 'Provisioning...' : 'Create Officer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _darkField(TextEditingController ctrl, String label, {String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
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
            Expanded(
              child: Text(
                'Admin Command Center',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh Users & Telemetry',
            onPressed: () => _refreshAdminData(),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Sign Out',
            onPressed: () async {
              await db.logout();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(context, '/welcome', (_) => false);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.manage_accounts), text: 'Users & RBAC'),
            Tab(icon: Icon(Icons.analytics), text: 'Operations & Audit'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUserManagementTab(db),
          _buildOperationsTab(db),
        ],
      ),
    );
  }

  Widget _buildUserManagementTab(DatabaseService db) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      onSubmitted: (val) => _refreshAdminData(query: val),
                      decoration: InputDecoration(
                        hintText: 'Search by name, email, or phone...',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                        prefixIcon: const Icon(Icons.search, color: Colors.purpleAccent),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.white54),
                                onPressed: () {
                                  _searchController.clear();
                                  _refreshAdminData(query: '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                    icon: const Icon(Icons.local_police, size: 18),
                    label: const Text('Create Officer'),
                    onPressed: _showCreateOfficerDialog,
                  ),
                ],
              ),
              if (_loadError != null) ...[
                const SizedBox(height: 10),
                Text(_loadError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
              ],
            ],
          ),
        ),
        Expanded(
          child: _loadingUsers
              ? const Center(child: CircularProgressIndicator())
              : _users.isEmpty
                  ? const Center(
                      child: Text('No users found matching your query.', style: TextStyle(color: Colors.white60)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _users.length,
                      itemBuilder: (ctx, i) {
                        final u = _users[i];
                        final role = u['role']?.toString() ?? 'registered_user';
                        final status = u['accountStatus']?.toString() ?? 'ACTIVE';
                        final isActive = status == 'ACTIVE';
                        final createdAt = (u['createdAt']?.toString() ?? '').split('.').first;
                        final roleColor = role == 'admin'
                            ? Colors.purpleAccent
                            : (role == 'officer'
                                ? Colors.lightBlueAccent
                                : (role == 'guardian' ? Colors.pinkAccent : Colors.tealAccent));

                        return Card(
                          color: const Color(0xFF1E293B),
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: roleColor.withValues(alpha: 0.35)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        u['fullName']?.toString() ?? '',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: roleColor.withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: roleColor),
                                      ),
                                      child: Text(
                                        role.toUpperCase(),
                                        style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: (isActive ? Colors.green : Colors.red).withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: isActive ? Colors.green : Colors.redAccent),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          color: isActive ? Colors.greenAccent : Colors.redAccent,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text('${u['email']} • ${u['phone']}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                const SizedBox(height: 4),
                                Text(
                                  'ID: ${u['id']} • Aadhaar: ${u['aadhaarVerified'] == true ? "Verified" : "Unverified"} • Registered: ${createdAt.isEmpty ? "Migrated" : createdAt}',
                                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                                ),
                                if ((u['badgeId']?.toString() ?? '').isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Badge: ${u['badgeId']} (${u['station']})',
                                    style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 11),
                                  ),
                                ],
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.purpleAccent,
                                        side: const BorderSide(color: Colors.purpleAccent),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      icon: const Icon(Icons.admin_panel_settings, size: 15),
                                      label: const Text('Assign Role', style: TextStyle(fontSize: 11)),
                                      onPressed: () => _handleAssignRole(u),
                                    ),
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: isActive ? Colors.orangeAccent : Colors.greenAccent,
                                        side: BorderSide(color: isActive ? Colors.orangeAccent : Colors.greenAccent),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      icon: Icon(isActive ? Icons.block : Icons.check_circle, size: 15),
                                      label: Text(isActive ? 'Deactivate' : 'Activate', style: const TextStyle(fontSize: 11)),
                                      onPressed: u['id'] == db.currentUserId ? null : () => _handleToggleStatus(u),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildOperationsTab(DatabaseService db) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                        Text(
                          'Authenticated Admin: ${db.userName}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${db.userEmail} • Role: ${db.currentRole} • ${db.permissions.length} RBAC Permissions',
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
              _buildStatTile('Registered Users', '${_users.length}', Icons.people, Colors.purpleAccent),
              _buildStatTile('Active SOS Cases', '${db.sosCases.length}', Icons.emergency, Colors.redAccent),
              _buildStatTile('Cyber Complaints', '${db.cyberComplaints.length}', Icons.security, Colors.amber),
              _buildStatTile('Active Vault Assets', '${db.vaultAssets.length}', Icons.lock, Colors.blueAccent),
            ],
          ),
          const SizedBox(height: 24),

          const Text(
            'AUTHORIZED MODULE SWITCHING',
            style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.1),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.local_police, size: 16),
                label: const Text('Officer Responder Desk'),
                onPressed: () => Navigator.pushNamed(context, '/responder_dashboard'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.family_restroom, size: 16),
                label: const Text('Guardian Portal'),
                onPressed: () => Navigator.pushNamed(context, '/guardian_dashboard'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.shield, size: 16),
                label: const Text('User Safety View'),
                onPressed: () => Navigator.pushNamed(context, '/dashboard'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'LIVE SECURITY AUDIT STREAM',
                style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.1),
              ),
              if (_loadingLogs) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
          const SizedBox(height: 10),
          Card(
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: _auditLogs.isEmpty
                  ? const Text('No security events recorded yet.', style: TextStyle(color: Colors.white54, fontSize: 12))
                  : Column(
                      children: _auditLogs.take(20).map((log) {
                        return _buildAuditRow(
                          log['action']?.toString() ?? 'AUDIT',
                          '${log['actor_email'] ?? 'system'}: ${log['details'] ?? log['target_id'] ?? ''}',
                          (log['created_at']?.toString() ?? '').split('.').first,
                        );
                      }).toList(),
                    ),
            ),
          ),
          const SizedBox(height: 30),
        ],
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
}
