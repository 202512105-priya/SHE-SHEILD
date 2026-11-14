import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/local_database_service.dart';
import '../widgets/server_config_dialog.dart';

// Helper Glassmorphism Card Widget
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24.0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(
          color: Colors.purple.shade100.withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.shade100.withValues(alpha: 0.2),
            spreadRadius: 2,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

bool _isValidEmail(String email) {
  return RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$').hasMatch(email.trim());
}

String? _validateStrongPassword(String password) {
  if (password.length < 8) return 'At least 8 characters required';
  if (!RegExp(r'[A-Z]').hasMatch(password)) return 'Include at least 1 uppercase letter';
  if (!RegExp(r'[a-z]').hasMatch(password)) return 'Include at least 1 lowercase letter';
  if (!RegExp(r'\d').hasMatch(password)) return 'Include at least 1 digit';
  if (!RegExp(r'''[!@#$%^&*(),.?":{}|<>_\-+=/\\;~\[\]]''').hasMatch(password)) {
    return 'Include at least 1 special character';
  }
  return null;
}

double _passwordStrengthScore(String pw) {
  if (pw.isEmpty) return 0.0;
  double score = 0;
  if (pw.length >= 8) score += 0.2;
  if (RegExp(r'[A-Z]').hasMatch(pw)) score += 0.2;
  if (RegExp(r'[a-z]').hasMatch(pw)) score += 0.2;
  if (RegExp(r'\d').hasMatch(pw)) score += 0.2;
  if (RegExp(r'''[!@#$%^&*(),.?":{}|<>_\-+=/\\;~\[\]]''').hasMatch(pw)) score += 0.2;
  return score;
}

bool _verhoeffCheck(String numStr) {
  if (!RegExp(r'^\d{12}$').hasMatch(numStr)) return false;
  const d = [
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
    [1, 2, 3, 4, 0, 6, 7, 8, 9, 5],
    [2, 3, 4, 0, 1, 7, 8, 9, 5, 6],
    [3, 4, 0, 1, 2, 8, 9, 5, 6, 7],
    [4, 0, 1, 2, 3, 9, 5, 6, 7, 8],
    [5, 9, 8, 7, 6, 0, 4, 3, 2, 1],
    [6, 5, 9, 8, 7, 1, 0, 4, 3, 2],
    [7, 6, 5, 9, 8, 2, 1, 0, 4, 3],
    [8, 7, 6, 5, 9, 3, 2, 1, 0, 4],
    [9, 8, 7, 6, 5, 4, 3, 2, 1, 0],
  ];
  const p = [
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
    [1, 5, 7, 6, 2, 8, 3, 0, 9, 4],
    [5, 8, 0, 3, 7, 9, 6, 1, 4, 2],
    [8, 9, 1, 6, 0, 4, 3, 5, 2, 7],
    [9, 4, 5, 3, 1, 2, 6, 8, 7, 0],
    [4, 2, 8, 6, 5, 7, 3, 9, 0, 1],
    [2, 7, 9, 3, 8, 0, 6, 4, 1, 5],
    [7, 0, 4, 6, 9, 1, 3, 2, 5, 8],
  ];
  int c = 0;
  final reversed = numStr.split('').reversed.toList();
  for (int i = 0; i < reversed.length; i++) {
    c = d[c][p[i % 8][int.parse(reversed[i])]];
  }
  return c == 0;
}

class DatabaseHealthBadge extends StatefulWidget {
  const DatabaseHealthBadge({super.key});

  @override
  State<DatabaseHealthBadge> createState() => _DatabaseHealthBadgeState();
}

class _DatabaseHealthBadgeState extends State<DatabaseHealthBadge> {
  final _db = LocalDatabaseService();
  bool _probing = false;

  @override
  void initState() {
    super.initState();
    _checkHealth();
  }

  Future<void> _checkHealth() async {
    if (!mounted) return;
    setState(() => _probing = true);
    await _db.connect(forceReprobe: true);
    if (mounted) {
      setState(() => _probing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _db.healthState;
    Color bg;
    Color border;
    Color text;
    IconData icon;
    String label;

    if (_probing || state == BackendHealthState.checking) {
      bg = Colors.grey.shade50;
      border = Colors.grey.shade300;
      text = Colors.grey.shade800;
      icon = Icons.sync;
      label = "Checking Database Connection...";
    } else if (state == BackendHealthState.cloudDatabaseConnected) {
      bg = Colors.green.shade50;
      border = Colors.green.shade300;
      text = Colors.green.shade800;
      icon = Icons.cloud_done;
      label = "Cloud Database Connected (${_db.databaseLabel})";
    } else if (state == BackendHealthState.databaseFailed) {
      bg = Colors.red.shade50;
      border = Colors.red.shade300;
      text = Colors.red.shade900;
      icon = Icons.error_outline;
      label = "Database Connection Failed";
    } else {
      bg = Colors.orange.shade50;
      border = Colors.orange.shade300;
      text = Colors.orange.shade900;
      icon = Icons.warning_amber_rounded;
      label = "Backend Unavailable (Tap to retry)";
    }

    return InkWell(
      onTap: _checkHealth,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: text),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Welcome Screen with Role Entry Points
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple.shade50,
              Colors.purple.shade100.withValues(alpha: 0.3),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.purple.shade100,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.shade200.withValues(alpha: 0.5),
                          blurRadius: 20,
                        )
                      ],
                    ),
                    child: Icon(Icons.shield_outlined, size: 56, color: Colors.purple.shade800),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "SHE SHIELD",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: Colors.purple.shade900,
                  ),
                ),
                Text(
                  "Cyber-Integrated Women Safety Network",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                const Center(child: DatabaseHealthBadge()),
                const SizedBox(height: 24),
                const Text(
                  "Access Portal",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Register as a User or Guardian, or sign in with your verified role credentials",
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 18),

                _RoleCard(
                  title: "New Account Registration",
                  subtitle: "Register as a Safety User or Trusted Guardian",
                  icon: Icons.person_add,
                  color: Colors.purple,
                  onTap: () => Navigator.pushNamed(context, '/register_user'),
                ),
                const SizedBox(height: 14),

                _RoleCard(
                  title: "Sign In (User / Guardian)",
                  subtitle: "Sign in to access your personal safety dashboard or linked family guardian view",
                  icon: Icons.login,
                  color: Colors.pink,
                  onTap: () => Navigator.pushNamed(context, '/login'),
                ),
                const SizedBox(height: 14),

                _RoleCard(
                  title: "Emergency Responder (Officer)",
                  subtitle: "Admin-provisioned police & responder portal for SOS and cyber cases",
                  icon: Icons.local_police,
                  color: Colors.blue.shade800,
                  onTap: () => Navigator.pushNamed(context, '/login'),
                ),
                const SizedBox(height: 14),

                _RoleCard(
                  title: "She Shield Admin Command",
                  subtitle: "Administrator portal for RBAC, officer provisioning & security audit logs",
                  icon: Icons.admin_panel_settings,
                  color: Colors.deepPurple.shade900,
                  onTap: () => Navigator.pushNamed(context, '/login'),
                ),

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already registered? ", style: TextStyle(color: Colors.grey.shade700)),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/login'),
                      child: Text(
                        "Sign In Here",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade800,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

// Secure Database-Backed Login Screen
class LoginScreen extends StatefulWidget {
  final String? initialMessage;
  const LoginScreen({super.key, this.initialMessage});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final db = Provider.of<DatabaseService>(context, listen: false);
    final res = await db.authenticateWithCredentials(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    if (res.success) {
      final targetRoute = db.homeRouteForRole;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Signed in as ${db.userName} (${db.currentRole})"),
          backgroundColor: Colors.green.shade700,
        ),
      );
      Navigator.pushNamedAndRemoveUntil(context, targetRoute, (_) => false);
    } else {
      setState(() {
        _errorMessage = res.error ?? 'Authentication failed. Check your credentials.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sign In"),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.cloud_done, color: Colors.greenAccent, size: 20),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: GlassCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.lock_person, size: 48, color: Colors.purple.shade700),
                    const SizedBox(height: 12),
                    const Text(
                      "Welcome Back",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Sign in with your verified account. Your role dashboard is assigned automatically by the server.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 12),
                    const Center(child: DatabaseHealthBadge()),
                    const SizedBox(height: 16),

                    if (widget.initialMessage != null && _errorMessage == null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Text(
                          widget.initialMessage!,
                          style: TextStyle(fontSize: 12, color: Colors.amber.shade900, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(fontSize: 12, color: Colors.red.shade900, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: "Email Address",
                        hintText: "you@example.com",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Email address is required';
                        if (!_isValidEmail(val)) return 'Enter a valid email address';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: "Password",
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Password is required';
                        return null;
                      },
                      onFieldSubmitted: (_) => _isLoading ? null : _submitLogin(),
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isLoading ? null : _submitLogin,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text("Sign In", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Need a new user account? ", style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacementNamed(context, '/register_user'),
                          child: Text(
                            "Register",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade800,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
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

// Public Registration Screen (Supports User or Guardian; admin/officer cannot self-register)
class RegisterUserScreen extends StatefulWidget {
  final String initialAccountType;
  final String? inviteToken;
  final String? shareToken;

  const RegisterUserScreen({
    super.key,
    this.initialAccountType = 'registered_user',
    this.inviteToken,
    this.shareToken,
  });

  @override
  State<RegisterUserScreen> createState() => _RegisterUserScreenState();
}

class _RegisterUserScreenState extends State<RegisterUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _aadhaarController = TextEditingController();

  late String _accountType;
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  bool _aadhaarSubmittedForReview = false;
  bool _faceCaptureRequested = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _accountType = widget.initialAccountType == 'guardian' ? 'guardian' : 'registered_user';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _aadhaarController.dispose();
    super.dispose();
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final db = Provider.of<DatabaseService>(context, listen: false);
    final res = await db.registerAccount(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
      accountType: _accountType,
      aadhaarNumber: _aadhaarSubmittedForReview ? _aadhaarController.text.trim() : null,
      inviteToken: widget.inviteToken,
      shareToken: widget.shareToken,
    );

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
    });

    if (res.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _accountType == 'guardian'
                ? "Guardian account created! Redirecting to Guardian Dashboard..."
                : "Account registered & secured in Cloud Database! Welcome to SHE SHIELD.",
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushNamedAndRemoveUntil(context, db.homeRouteForRole, (_) => false);
    } else {
      setState(() {
        _errorMessage = res.error ?? 'Registration failed. Please check your details.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pw = _passwordController.text;
    final strength = _passwordStrengthScore(pw);
    final strengthColor = strength <= 0.4
        ? Colors.red
        : (strength < 1.0 ? Colors.orange : Colors.green);
    final strengthLabel = strength <= 0.4
        ? 'Weak'
        : (strength < 1.0 ? 'Moderate' : 'Strong');

    return Scaffold(
      appBar: AppBar(
        title: Text(_accountType == 'guardian' ? "Guardian Registration" : "User Registration"),
        backgroundColor: _accountType == 'guardian' ? Colors.teal.shade800 : Colors.purple.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          "Create Safety Profile",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _accountType == 'guardian' ? Colors.teal.shade900 : Colors.purple.shade900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Select whether you are registering as a Safety User or a Trusted Guardian.",
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                selected: _accountType == 'registered_user',
                                selectedColor: Colors.purple.shade100,
                                avatar: Icon(Icons.person_outline, size: 18, color: Colors.purple.shade800),
                                label: const Text("Safety User"),
                                onSelected: (_) => setState(() => _accountType = 'registered_user'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ChoiceChip(
                                selected: _accountType == 'guardian',
                                selectedColor: Colors.teal.shade100,
                                avatar: Icon(Icons.shield_outlined, size: 18, color: Colors.teal.shade800),
                                label: const Text("Guardian"),
                                onSelected: (_) => setState(() => _accountType = 'guardian'),
                              ),
                            ),
                          ],
                        ),
                        if (widget.inviteToken != null || widget.shareToken != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.teal.shade300),
                            ),
                            child: Text(
                              widget.shareToken != null
                                  ? "Complete Guardian registration to view this shared live journey inside your Guardian Dashboard."
                                  : "Complete Guardian registration to accept this guardian invitation automatically.",
                              style: TextStyle(fontSize: 12, color: Colors.teal.shade900, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),

                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.red.shade300),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(fontSize: 12, color: Colors.red.shade900, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: "Full Name",
                            hintText: "Enter your full name",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (val) {
                            final v = (val ?? '').trim();
                            if (v.length < 2) return 'Full Name must be at least 2 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: "Email Address",
                            hintText: "you@example.com",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Email Address is required';
                            if (!_isValidEmail(val)) return 'Enter a valid email address';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: "Phone Number",
                            hintText: "+91 98765 43210",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                          ),
                          validator: (val) {
                            final digits = (val ?? '').replaceAll(RegExp(r'\D'), '');
                            if (digits.length < 10 || digits.length > 15) {
                              return 'Enter a valid 10 to 15 digit phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: "Password",
                            hintText: "Min 8 chars, upper, lower, number & symbol",
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (val) => _validateStrongPassword(val ?? ''),
                        ),
                        if (pw.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: strength,
                                  color: strengthColor,
                                  backgroundColor: Colors.grey.shade200,
                                  minHeight: 6,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                strengthLabel,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: strengthColor),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Aadhaar Identity Verification Card (Honest Verification State)
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.badge, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                "Aadhaar Identity Verification",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.shade300),
                              ),
                              child: Text(
                                _aadhaarSubmittedForReview ? "Pending KYC" : "Not Verified",
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _aadhaarController,
                          keyboardType: TextInputType.number,
                          maxLength: 12,
                          decoration: const InputDecoration(
                            labelText: "12-Digit Aadhaar Number (Optional KYC)",
                            hintText: "Validated by Verhoeff checksum (requires official UIDAI verification)",
                            border: OutlineInputBorder(),
                            counterText: '',
                          ),
                          validator: (val) {
                            final v = (val ?? '').trim();
                            if (v.isEmpty) return null;
                            if (!_verhoeffCheck(v)) {
                              return 'Invalid 12-digit Aadhaar checksum';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.upload_file),
                          label: Text(
                            _aadhaarSubmittedForReview
                                ? "Queued for UIDAI / Admin KYC Verification"
                                : "Submit Aadhaar for Pending KYC Review",
                          ),
                          onPressed: () {
                            final v = _aadhaarController.text.trim();
                            if (v.isEmpty || !_verhoeffCheck(v)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Enter a valid 12-digit Aadhaar number first (Verhoeff checksum)."),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                              return;
                            }
                            setState(() => _aadhaarSubmittedForReview = true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Aadhaar reference queued. Status remains Pending Verification until verified."),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Face Biometrics Card (Honest Verification State)
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.face_retouching_natural, color: Colors.purple.shade700),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                "Live Face Biometrics",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.shade300),
                              ),
                              child: Text(
                                _faceCaptureRequested ? "Pending Enrollment" : "Not Verified",
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Biometric face matching requires live camera enrollment and liveness verification (cannot be marked verified statically).",
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.camera_alt),
                          label: Text(
                            _faceCaptureRequested
                                ? "Enrollment Requested (Pending Biometric Check)"
                                : "Request Live Face Biometrics Enrollment",
                          ),
                          onPressed: () {
                            setState(() => _faceCaptureRequested = true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Biometric enrollment flagged as Pending Verification."),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Complete Registration Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade800,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _isSubmitting ? null : _submitRegistration,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            "Complete Registration & Enter Dashboard",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
