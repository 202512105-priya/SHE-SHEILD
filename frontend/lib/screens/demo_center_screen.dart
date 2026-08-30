import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import 'auth_screens.dart'; // For GlassCard
import 'cyber_screens.dart'; // For CyberReportScreen

class DemoCenterScreen extends StatefulWidget {
  const DemoCenterScreen({super.key});

  @override
  State<DemoCenterScreen> createState() => _DemoCenterScreenState();
}

class _DemoCenterScreenState extends State<DemoCenterScreen> {
  bool _loading = false;

  // Ensure mock user is logged in
  Future<Map<String, dynamic>> _ensureMockUser(DatabaseService db, {required String role, required String name, required String email}) async {
    var users = db.getCollection("Users");
    var existing = users.firstWhere((u) => u['email'] == email, orElse: () => <String, dynamic>{});
    
    if (existing.isEmpty) {
      String uid = "mock-${role}-${DateTime.now().millisecondsSinceEpoch}";
      Map<String, dynamic> userDoc = {
        "uid": uid,
        "name": name,
        "email": email,
        "mobile": "+919876543210",
        "password": "password123",
        "role": role,
        "secretSosPhrase": "Box Box",
        "safeContactList": [],
        "verified": true,
        "status": "active",
        "createdAt": DateTime.now().toIso8601String()
      };
      
      if (role == "police") {
        userDoc["stationName"] = "SHE SHIELD Headquarters Cell";
        userDoc["official
<truncated 29103 bytes>
 Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.purple)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.purple),
            ],
          ),
        ),
      ),
    );
  }

  Widget _demoGridBtn({required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.purple.shade100.withOpacity(0.4)),
      ),
      color: Colors.white.withOpacity(0.9),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.purple)),
            ],
          ),
        ),
      ),
    );
  }
}

const int kStandardOutMultiplier = 101;
