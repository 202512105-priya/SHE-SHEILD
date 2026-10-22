import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';

class RegisterResponderScreen extends StatefulWidget {
  const RegisterResponderScreen({super.key});

  @override
  State<RegisterResponderScreen> createState() => _RegisterResponderScreenState();
}

class _RegisterResponderScreenState extends State<RegisterResponderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Officer Rahul Sharma');
  final _emailController = TextEditingController(text: 'rahul.sharma@police.gov.in');
  final _phoneController = TextEditingController(text: '+91 98765 01234');
  final _passwordController = TextEditingController(text: 'ResponderPass911');
  final _stationController = TextEditingController(text: 'Central Command Police Station #4');
  final _jurisdictionController = TextEditingController(text: 'North Zone & Highway Sector');

  bool _govtIdUploaded = false;
  bool _deptIdUploaded = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _stationController.dispose();
    _jurisdictionController.dispose();
    super.dispose();
  }

  void _submitOnboarding() {
    if (_formKey.currentState!.validate()) {
      if (!_govtIdUploaded || !_deptIdUploaded) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please upload both Govt ID and Dept ID before submitting verification.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      Future.delayed(const Duration(seconds: 1), () {
        final db = Provider.of<DatabaseService>(context, listen: false);
        db.loginUser(_emailController.text, _nameController.text);
        db.setRole('responder');

        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Responder Onboarding Completed & Verified! Redirecting to Dashboard...'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacementNamed(context, '/responder_dashboard');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6FE),
      appBar: AppBar(
        title: const Text('Responder Onboarding'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner Card
              Card(
                color: const Color(0xFF4A148C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Icon(Icons.local_police, size: 48, color: Colors.amber),
                      SizedBox(height: 10),
                      Text(
                        'Police & Emergency Unit Access',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Register official responder credentials to access live emergency dispatch networks and cyber threat streams.',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Personal Information Section
              const Text(
                'OFFICER CREDENTIALS',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.purple, letterSpacing: 1.1),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person, color: Colors.purple),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Enter full name' : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Official Email Address (.gov.in)',
                  prefixIcon: Icon(Icons.email, color: Colors.purple),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Enter official email' : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Official Phone Number',
                  prefixIcon: Icon(Icons.phone, color: Colors.purple),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Enter phone number' : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Responder Password',
                  prefixIcon: Icon(Icons.lock, color: Colors.purple),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Enter password' : null,
              ),
              const SizedBox(height: 24),

              // Police Station & Jurisdiction
              const Text(
                'STATION & JURISDICTION',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.purple, letterSpacing: 1.1),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _stationController,
                decoration: const InputDecoration(
                  labelText: 'Police Station Name',
                  prefixIcon: Icon(Icons.corporate_fare, color: Colors.purple),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Enter police station name' : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _jurisdictionController,
                decoration: const InputDecoration(
                  labelText: 'Jurisdiction / Zone Sector',
                  prefixIcon: Icon(Icons.map, color: Colors.purple),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Enter jurisdiction zone' : null,
              ),
              const SizedBox(height: 24),

              // Upload Official Documents Section
              const Text(
                'GOVT IDENTITY VERIFICATION',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.purple, letterSpacing: 1.1),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: _govtIdUploaded ? Colors.green : Colors.purple,
                          width: 1.5,
                        ),
                        backgroundColor: _govtIdUploaded ? Colors.green.shade50 : Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _govtIdUploaded = true;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Govt ID Document Uploaded & Verified (Aadhaar/PAN)')),
                        );
                      },
                      icon: Icon(
                        _govtIdUploaded ? Icons.check_circle : Icons.upload_file,
                        color: _govtIdUploaded ? Colors.green : Colors.purple,
                      ),
                      label: Text(
                        _govtIdUploaded ? 'Govt ID Uploaded' : 'Upload Govt ID',
                        style: TextStyle(
                          color: _govtIdUploaded ? Colors.green.shade900 : Colors.purple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: _deptIdUploaded ? Colors.green : Colors.purple,
                          width: 1.5,
                        ),
                        backgroundColor: _deptIdUploaded ? Colors.green.shade50 : Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _deptIdUploaded = true;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Department Badge Uploaded & Cryptographically Signed')),
                        );
                      },
                      icon: Icon(
                        _deptIdUploaded ? Icons.check_circle : Icons.badge,
                        color: _deptIdUploaded ? Colors.green : Colors.purple,
                      ),
                      label: Text(
                        _deptIdUploaded ? 'Dept ID Uploaded' : 'Upload Dept ID',
                        style: TextStyle(
                          color: _deptIdUploaded ? Colors.green.shade900 : Colors.purple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Submit Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A148C),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _isSubmitting ? null : _submitOnboarding,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Complete Officer Onboarding',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
