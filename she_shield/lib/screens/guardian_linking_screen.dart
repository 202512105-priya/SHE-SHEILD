import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import 'auth_screens.dart';

class GuardianLinkingScreen extends StatefulWidget {
  const GuardianLinkingScreen({super.key});

  @override
  State<GuardianLinkingScreen> createState() => _GuardianLinkingScreenState();
}

class _GuardianLinkingScreenState extends State<GuardianLinkingScreen> {
  final _emailController = TextEditingController(text: 'abc@gmail.com');
  final _relationController = TextEditingController(text: 'mother');
  final _phoneController = TextEditingController(text: '+91 9876543210');

  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _relationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _sendLinkRequest() {
    if (_emailController.text.trim().isEmpty || _relationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all guardian details.')),
      );
      return;
    }

    var db = Provider.of<DatabaseService>(context, listen: false);
    db.addGuardian(_emailController.text.trim(), _relationController.text.trim());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.greenAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Link Request sent to ${_emailController.text} (${_relationController.text})!',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.purple,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var db = Provider.of<DatabaseService>(context);
    var guardians = db.guardians;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guardian Linking & Network'),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade50, Colors.pink.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Form Card: Onboard Trusted Guardian
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.person_add_alt_1, color: Colors.purple, size: 26),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Onboard Trusted Guardian",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple,
                                ),
                              ),
                              Text(
                                "Link safe contacts for automatic emergency alerts",
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        "Guardian Email",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: "abc@gmail.com",
                          prefixIcon: const Icon(Icons.email, color: Colors.purple),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                      const SizedBox(height: 14),

                      const Text(
                        "Relationship",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _relationController,
                        decoration: InputDecoration(
                          hintText: "e.g. mother, sister, friend",
                          prefixIcon: const Icon(Icons.family_restroom, color: Colors.purple),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                      const SizedBox(height: 14),

                      const Text(
                        "Phone Number",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: "+91 9876543210",
                          prefixIcon: const Icon(Icons.phone, color: Colors.purple),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                      const SizedBox(height: 20),

                      ElevatedButton.icon(
                        onPressed: _sendLinkRequest,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          backgroundColor: Colors.purple,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.send_rounded, color: Colors.white),
                        label: const Text(
                          "Send Link Request",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Guardian Status Stepper (Pending Approvals Timeline)
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Pending Approvals Timeline",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purple),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              "IN PROGRESS",
                              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Target Guardian: ${guardians.isNotEmpty ? guardians.last['email'] : 'abc@gmail.com'} (${guardians.isNotEmpty ? guardians.last['relation'] : 'mother'})",
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 20),

                      // Stepper bar [Sent -> Accepted -> Verified -> Active]
                      Row(
                        children: [
                          _buildStepperNode("Sent", isDone: true, isFirst: true),
                          _buildStepperLine(isDone: true),
                          _buildStepperNode("Accepted", isDone: true),
                          _buildStepperLine(isDone: true),
                          _buildStepperNode("Verified", isDone: true),
                          _buildStepperLine(isDone: false),
                          _buildStepperNode("Active", isDone: false, isLast: true),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.purple, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Waiting for final 2FA biometrics check from guardian device to activate live GPS & SOS triggers.",
                                style: TextStyle(fontSize: 11, color: Colors.purple),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Active Verified Guardians List
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Active Verified Guardians",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purple),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              "2 VERIFIED",
                              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      _buildActiveGuardianTile(
                        name: "Sunita Sharma",
                        relation: "Mother",
                        email: "abc@gmail.com",
                        phone: "+91 9876543210",
                        isPrimary: true,
                      ),
                      const Divider(height: 16),
                      _buildActiveGuardianTile(
                        name: "Rohan Sharma",
                        relation: "Brother",
                        email: "rohan@gmail.com",
                        phone: "+91 9123456789",
                        isPrimary: false,
                      ),
                      if (guardians.length > 1) ...[
                        const Divider(height: 16),
                        ...guardians.skip(1).map((g) => _buildActiveGuardianTile(
                          name: g['email'].toString().split('@')[0],
                          relation: g['relation'].toString(),
                          email: g['email'].toString(),
                          phone: "+91 9998887770",
                          isPrimary: false,
                        )),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepperNode(String label, {required bool isDone, bool isFirst = false, bool isLast = false}) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isDone ? Colors.green : Colors.grey.shade300,
              shape: BoxShape.circle,
              border: Border.all(color: isDone ? Colors.green : Colors.grey, width: 2),
            ),
            child: Icon(
              isDone ? Icons.check : Icons.hourglass_empty,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
              color: isDone ? Colors.green.shade800 : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepperLine({required bool isDone}) {
    return Container(
      width: 20,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: isDone ? Colors.green : Colors.grey.shade300,
    );
  }

  Widget _buildActiveGuardianTile({
    required String name,
    required String relation,
    required String email,
    required String phone,
    required bool isPrimary,
  }) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Colors.purple.shade100,
          child: Text(
            name.substring(0, 1),
            style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(width: 6),
                  if (isPrimary)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text("Primary", style: TextStyle(color: Colors.purple, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              Text("$relation • $email", style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(phone, style: const TextStyle(fontSize: 11, color: Colors.purple)),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.call, color: Colors.green),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Calling $name ($phone)...")),
            );
          },
        ),
      ],
    );
  }
}
