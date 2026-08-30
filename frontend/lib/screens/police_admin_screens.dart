import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import 'auth_screens.dart'; // For GlassCard
import 'monitoring_screens.dart'; // For SafetyAssessmentMap
import '../services/pdf_report_service.dart';

// -------------------------------------------------------------
// MULTI-USER GUARDIAN PORTAL
// -------------------------------------------------------------
class GuardianDashboardScreen extends StatefulWidget {
  const GuardianDashboardScreen({super.key});

  @override
  State<GuardianDashboardScreen> createState() => _GuardianDashboardScreenState();
}

class _GuardianDashboardScreenState extends State<GuardianDashboardScreen> {
  String? _selectedUserId;

  @override
  Widget build(BuildContext context) {
    var db = Provider.of<DatabaseService>(context);
    
    // Get all approved requests
    var approvedLinks = db.getCollection("Guardians")
        .where((g) => g['guardianId'] == db.currentUserId)
        .toList();

    List<Map<String, dynamic>> linkedUsers = [];
    for (var link in approvedLinks) {
      var user = db.getDocument("Users", link['userId']);
      if (user != null) {
        linkedUsers.add({
          ...user,
          "relationship": link['relation'] ?? "Relative"
        });
      }
    }

    // fallback mock if none linked yet to prevent empty screen
    if (li
<truncated 11464 bytes>
                ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B218B), foregroundColor: Colors.white),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Launching navigation tracking stream...")),
                                  );
                                },
                                icon: const Icon(Icons.directions),
                                label: const Text("Navigate"),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F), foregroundColor: Colors.white),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Emergency: Dispatch warning to local station cell.")),
                                  );
                                },
                                icon: const Icon(Icons.security),
                                label: const Text("Police"),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
The above content does NOT show the entire file contents. If you need to view any lines of the file which were not shown to complete your task, call this tool again to view those lines.
