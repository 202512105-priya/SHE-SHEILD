import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';

/// Admin-only Officer Provisioning Screen (legacy route helper).
/// Requires an authenticated Admin session with 'admin:create_officer' permission.
class RegisterResponderScreen extends StatefulWidget {
  const RegisterResponderScreen({super.key});

  @override
  State<RegisterResponderScreen> createState() => _RegisterResponderScreenState();
}

class _RegisterResponderScreenState extends State<RegisterResponderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _stationController = TextEditingController();
  final _badgeController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _stationController.dispose();
    _badgeController.dispose();
    super.dispose();
  }

  Future<void> _submitOnboarding() async {
    final db = Provider.of<DatabaseService>(context, listen: false);
    if (!db.hasPermission('admin:create_officer')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Forbidden: Only Administrators can provision Officer accounts.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final res = await db.adminCreateOfficer(
      fullName: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      password: _passwordController.text,
      badgeId: _badgeController.text,
      station: _stationController.text,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (res.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authorized Officer account created in SQLite!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.error ?? 'Failed to create officer account.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    if (!db.hasPermission('admin:create_officer')) {
      return Scaffold(
        appBar: AppBar(title: const Text('Restricted')),
        body: const Center(
          child: Text('403 Forbidden: Administrator authorization required to provision officers.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFBF6FE),
      appBar: AppBar(title: const Text('Provision Officer Account'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
                validator: (val) => val == null || val.trim().length < 2 ? 'Enter full name' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Official Email', prefixIcon: Icon(Icons.email)),
                validator: (val) => val == null || !val.contains('@') ? 'Enter official email' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Official Phone Number', prefixIcon: Icon(Icons.phone)),
                validator: (val) => val == null || val.trim().length < 10 ? 'Enter phone number' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Officer Password', prefixIcon: Icon(Icons.lock)),
                validator: (val) => val == null || val.length < 8 ? 'Minimum 8 characters' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _badgeController,
                decoration: const InputDecoration(labelText: 'Badge ID', prefixIcon: Icon(Icons.badge)),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _stationController,
                decoration: const InputDecoration(labelText: 'Police Station', prefixIcon: Icon(Icons.corporate_fare)),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitOnboarding,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Create Authorized Officer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
