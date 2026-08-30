import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../services/database_service.dart';
import 'auth_screens.dart'; // For GlassCard

class EvidenceVaultScreen extends StatefulWidget {
  const EvidenceVaultScreen({super.key});

  @override
  State<EvidenceVaultScreen> createState() => _EvidenceVaultScreenState();
}

class _EvidenceVaultScreenState extends State<EvidenceVaultScreen> {
  bool _loading = false;
  Map<String, dynamic>? _selectedOcrReport;

  Future<void> _simulateUpload(String label, String extension) async {
    setState(() => _loading = true);

    // Predictable file names based on user uploads
    String fileName = "ev_${label.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.$extension";
    await Future.delayed(const Duration(seconds: 1));

    var db = Provider.of<DatabaseService>(context, listen: false);
    String evidenceId = "ev-${DateTime.now().millisecondsSinceEpoch}";
    
    // Cryptographic SHA256 hash generation
    String hashValue = db.sha256Hash(fileName + DateTime.now().toIso8601String());

    // Create Evidence document with default "uploaded" status
    await db.addDocument("Evidence", evidenceId, {
      "evidenceId": evidenceId,
      "userId": db.currentUserId,
      "fileUrl": "https://storage.emulator/she-shield-demo/$fileName",
      "fileName": fileName,
      "fileType": label,

<truncated 26635 bytes>
_selectedOcrReport = null;
                    });
                  },
                ),
              ],
            ),
            const Divider(height: 24),
            Text("Verification: ${rep['generatedBy']}", style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 12),
            const Text("Extracted Assets Content:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(12)),
              child: Text(rep['extractedText'], style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
            ),
            const SizedBox(height: 16),
            const Text("Threat Markers:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            Text(rep['summary'], style: const TextStyle(fontSize: 13, color: Colors.red, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text("Flagged Threat Vectors:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: (rep['threatIndicators'] as List).map((t) {
                return Chip(
                  backgroundColor: Colors.red.shade50,
                  label: Text(t.toString(), style: const TextStyle(color: Colors.red, fontSize: 10)),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
