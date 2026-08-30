import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class DatabaseService extends ChangeNotifier {
  bool _initialized = false;
  bool _useEmulator = true; // Set true for local testing
  bool _isOfflineMode = false;
  bool _backendHealthy = false;
  FirebaseFirestore? _firestore;
  FirebaseAuth? _auth;

  // Production Mode Switch (Demo vs Production Architecture)
  bool _productionMode = false;
  bool get productionMode => _productionMode;

  // Production Configuration Templates (Upgrade-Ready)
  final Map<String, dynamic> productionGateways = {
    "smsGateway": {
      "provider": "SMSIndiaHub",
      "endpoint": "https://api.smsindiahub.in/sendsms.php",
      "senderId": "SHESHLD",
      "apiKey": "PROD_API_KEY_XXXXXXXXXXXX"
    },
    "otpProvider": {
      "provider": "Twilio Verify",
      "serviceSid": "VAXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
      "accountSid": "ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    },
    "emergencyApi": {
      "dispatchEndpoint": "https://emergency.112.gov.in/api/v1/dispatch",
      "authHeader": "Bearer 112_PROD_INTEGRATION_TOKEN_XXXXXX"
    },
    "
<truncated 30038 bytes>
ted to Level $targetLevel: $details");

    // 4. Fire corresponding alerts
    if (targetLevel >= 2) {
      var cases = getCollection("Cases");
      var existingCase = cases.firstWhere((c) => c['sourceId'] == sessionId, orElse: () => <String, dynamic>{});
      if (existingCase.isEmpty) {
        String caseId = "case-${DateTime.now().millisecondsSinceEpoch}";
        await addDocument("Cases", caseId, {
          "caseId": caseId,
          "sourceId": sessionId,
          "complaintType": "SOS Escalation Alert",
          "casePriority": targetLevel == 4 ? "critical" : (targetLevel == 3 ? "high" : "medium"),
          "caseSeverity": targetLevel == 4 ? "critical" : (targetLevel == 3 ? "high" : "medium"),
          "assignedStation": "Central Dispatch Desk",
          "assignedOfficer": "",
          "evidenceCount": 0,
          "status": "open",
          "createdAt": DateTime.now().toIso8601String()
        });
      } else {
        await updateDocument("Cases", existingCase['caseId'], {
          "casePriority": targetLevel == 4 ? "critical" : (targetLevel == 3 ? "high" : "medium"),
          "caseSeverity": targetLevel == 4 ? "critical" : (targetLevel == 3 ? "high" : "medium"),
        });
      }
    }

    // Notify all guardians about the escalation
    var guardians = getCollection("Guardians").where((g) => g['userId'] == currentUserId || g['userId'] == session?['userId']);
    for (var g in guardians) {
      await createNotification(
        userId: g['guardianId'],
        title: "SOS ESCALATION: Level $targetLevel",
        body: "Emergency tracking escalated: $details",
        type: "SOS Alert",
        priority: "high"
      );
The above content does NOT show the entire file contents. If you need to view any lines of the file which were not shown to complete your task, call this tool again to view those lines.
