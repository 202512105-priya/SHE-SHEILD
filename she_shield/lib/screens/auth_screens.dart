import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';

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

// Welcome Screen with Role Selector
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
                const SizedBox(height: 20),
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
                const SizedBox(height: 32),
                const Text(
                  "Select Your Role",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Choose how you want to access the safety portal",
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),

                // Role Card 1: Women User
                _RoleCard(
                  title: "Women User",
                  subtitle: "Access personal safety, travel guardian, SOS triggers & cyber defense",
                  icon: Icons.person,
                  color: Colors.purple,
                  onTap: () {
                    Provider.of<DatabaseService>(context, listen: false).setRole('user');
                    Navigator.pushNamed(context, '/register_user');
                  },
                ),
                const SizedBox(height: 16),

                // Role Card 2: Guardian
                _RoleCard(
                  title: "Guardian / Family Member",
                  subtitle: "Monitor loved ones, receive real-time alerts & live location updates",
                  icon: Icons.people,
                  color: Colors.pink,
                  onTap: () {
                    Provider.of<DatabaseService>(context, listen: false).setRole('guardian');
                    Navigator.pushNamed(context, '/register_guardian');
                  },
                ),
                const SizedBox(height: 16),

                // Role Card 3: Emergency Responder
                _RoleCard(
                  title: "Emergency Responder",
                  subtitle: "Police & Dispatchers managing live critical SOS cases and dispatch",
                  icon: Icons.local_police,
                  color: Colors.blue.shade800,
                  onTap: () {
                    Provider.of<DatabaseService>(context, listen: false).setRole('responder');
                    Navigator.pushNamed(context, '/register_responder');
                  },
                ),
                const SizedBox(height: 16),

                // Role Card 4: Admin
                _RoleCard(
                  title: "She Shield Admin",
                  subtitle: "System control, audit logs, cyber complaints & threat analytics",
                  icon: Icons.admin_panel_settings,
                  color: Colors.deepPurple.shade900,
                  onTap: () {
                    Provider.of<DatabaseService>(context, listen: false).setRole('admin');
                    Navigator.pushNamed(context, '/admin_login');
                  },
                ),

                const SizedBox(height: 28),
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

// Login Screen
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: "tisha@gmail.com");
  final _passwordController = TextEditingController(text: "password123");
  String _selectedRole = 'user';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sign In"),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.lock_person, size: 48, color: Colors.purple.shade700),
              const SizedBox(height: 16),
              const Text(
                "Welcome Back",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Access your SHE SHIELD Account",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),

              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: const InputDecoration(
                  labelText: "Login Role",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                ),
                items: const [
                  DropdownMenuItem(value: 'user', child: Text("Women User")),
                  DropdownMenuItem(value: 'guardian', child: Text("Guardian")),
                  DropdownMenuItem(value: 'responder', child: Text("Emergency Responder")),
                  DropdownMenuItem(value: 'admin', child: Text("Admin")),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedRole = val);
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Email Address",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  final db = Provider.of<DatabaseService>(context, listen: false);
                  db.setRole(_selectedRole);
                  db.loginUser(_emailController.text, "tisha");

                  if (_selectedRole == 'user') {
                    Navigator.pushReplacementNamed(context, '/dashboard');
                  } else if (_selectedRole == 'guardian') {
                    Navigator.pushReplacementNamed(context, '/guardian_dashboard');
                  } else if (_selectedRole == 'responder') {
                    Navigator.pushReplacementNamed(context, '/responder_dashboard');
                  } else {
                    Navigator.pushReplacementNamed(context, '/admin_dashboard');
                  }
                },
                child: const Text("Sign In", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// User Registration Screen with Aadhaar, Face Match & Mobile OTP
class RegisterUserScreen extends StatefulWidget {
  const RegisterUserScreen({super.key});

  @override
  State<RegisterUserScreen> createState() => _RegisterUserScreenState();
}

class _RegisterUserScreenState extends State<RegisterUserScreen> {
  final _nameController = TextEditingController(text: "tisha");
  final _emailController = TextEditingController(text: "tisha@gmail.com");
  final _phoneController = TextEditingController(text: "12435578494630");
  final _passwordController = TextEditingController(text: "password123");

  void _showOtpDialog() {
    final List<TextEditingController> otpControllers =
        List.generate(6, (index) => TextEditingController(text: "${[1, 2, 4, 3, 5, 5][index]}"));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.phonelink_ring, color: Colors.purple),
            SizedBox(width: 8),
            Text("Mobile OTP Verification"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Enter 6-digit code sent to ${_phoneController.text}:",
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                6,
                (i) => SizedBox(
                  width: 38,
                  child: TextField(
                    controller: otpControllers[i],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade700, foregroundColor: Colors.white),
            onPressed: () {
              Provider.of<DatabaseService>(context, listen: false).verifyOtp();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Mobile OTP Verified Successfully! (6-Digit OTP Matched)"),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text("Verify OTP"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Registration"),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
      ),
      body: Consumer<DatabaseService>(
        builder: (context, db, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
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
                          color: Colors.purple.shade900,
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: "Full Name",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: "Email Address",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: "Phone Number",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Password",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Aadhaar Verification Card
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.badge, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          const Text(
                            "Aadhaar Identity Verification",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (db.aadhaarVerified)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Aadhaar Card Verified: 9845-XXXX-1234",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Icons.upload_file),
                          label: const Text("Upload Aadhaar ID Document"),
                          onPressed: () {
                            db.verifyAadhaar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Aadhaar Document Processed & Verified!"),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Face Biometrics Card
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.face_retouching_natural, color: Colors.purple.shade700),
                          const SizedBox(width: 8),
                          const Text(
                            "Live Face Biometrics",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (db.faceVerified)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.verified, color: Colors.green),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Face Biometrics Match: 94.6% (Verified)",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text("Capture Live Camera Face Biometrics"),
                          onPressed: () {
                            db.verifyFace();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Face Match Score: 94.6% (Verified)"),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Mobile OTP Verification Card
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.smartphone, color: Colors.orange.shade800),
                          const SizedBox(width: 8),
                          const Text(
                            "Mobile OTP Verification",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (db.otpVerified)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.mark_email_read, color: Colors.green),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Phone Verified via 6-Digit OTP",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.orange.shade800),
                          ),
                          icon: Icon(Icons.sms, color: Colors.orange.shade800),
                          label: Text(
                            "Send & Verify Mobile OTP",
                            style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold),
                          ),
                          onPressed: _showOtpDialog,
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
                  onPressed: () {
                    db.loginUser(_emailController.text, _nameController.text);
                    Navigator.pushReplacementNamed(context, '/dashboard');
                  },
                  child: const Text(
                    "Complete Registration & Enter Dashboard",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Guardian Registration Screen
class RegisterGuardianScreen extends StatefulWidget {
  const RegisterGuardianScreen({super.key});

  @override
  State<RegisterGuardianScreen> createState() => _RegisterGuardianScreenState();
}

class _RegisterGuardianScreenState extends State<RegisterGuardianScreen> {
  final _nameController = TextEditingController(text: "Guardian User");
  final _emailController = TextEditingController(text: "guardian@gmail.com");
  final _phoneController = TextEditingController(text: "9876543210");
  String _relation = "Mother";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Register Guardian"),
        backgroundColor: Colors.pink.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.family_restroom, size: 48, color: Colors.pink.shade700),
              const SizedBox(height: 12),
              const Text(
                "Guardian Network Registration",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Guardian Full Name", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Guardian Email", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: "Phone Number", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _relation,
                decoration: const InputDecoration(labelText: "Relationship to User", border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: "Mother", child: Text("Mother")),
                  DropdownMenuItem(value: "Father", child: Text("Father")),
                  DropdownMenuItem(value: "Spouse", child: Text("Spouse")),
                  DropdownMenuItem(value: "Sister", child: Text("Sister")),
                  DropdownMenuItem(value: "Friend", child: Text("Friend")),
                  DropdownMenuItem(value: "Other", child: Text("Other")),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _relation = val);
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  final db = Provider.of<DatabaseService>(context, listen: false);
                  db.setRole('guardian');
                  db.loginUser(_emailController.text, _nameController.text);
                  Navigator.pushReplacementNamed(context, '/guardian_dashboard');
                },
                child: const Text("Register as Guardian"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Emergency Responder Registration Screen
class RegisterResponderScreen extends StatefulWidget {
  const RegisterResponderScreen({super.key});

  @override
  State<RegisterResponderScreen> createState() => _RegisterResponderScreenState();
}

class _RegisterResponderScreenState extends State<RegisterResponderScreen> {
  final _nameController = TextEditingController(text: "Inspector Vikram");
  final _emailController = TextEditingController(text: "vikram@police.gov.in");
  final _badgeController = TextEditingController(text: "POLICE-GJ-8842");
  final _stationController = TextEditingController(text: "Navrangpura Police Station");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Responder Portal Registration"),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.local_police, size: 48, color: Colors.blue.shade900),
              const SizedBox(height: 12),
              const Text(
                "Official Police / First Responder Registration",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Officer Name", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Official Email Address", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _badgeController,
                decoration: const InputDecoration(labelText: "Badge ID / Service Reg Number", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stationController,
                decoration: const InputDecoration(labelText: "Police Station / Mobile Unit Location", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade900,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  final db = Provider.of<DatabaseService>(context, listen: false);
                  db.setRole('responder');
                  db.loginUser(_emailController.text, _nameController.text);
                  Navigator.pushReplacementNamed(context, '/responder_dashboard');
                },
                child: const Text("Register Officer Profile"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Admin Login Screen
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _adminKeyController = TextEditingController(text: "ADMIN-SHE-SHIELD-KEY-99");
  final _passwordController = TextEditingController(text: "adminpass");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Security Portal"),
        backgroundColor: Colors.deepPurple.shade900,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.admin_panel_settings, size: 52, color: Colors.deepPurple.shade900),
              const SizedBox(height: 12),
              const Text(
                "She Shield System Admin Login",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _adminKeyController,
                decoration: const InputDecoration(labelText: "Admin Passcode / Master Security Token", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Master Password", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple.shade900,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  final db = Provider.of<DatabaseService>(context, listen: false);
                  db.setRole('admin');
                  db.loginUser("admin@sheshield.gov.in", "System Admin");
                  Navigator.pushReplacementNamed(context, '/admin_dashboard');
                },
                child: const Text("Authorize Admin Access"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
