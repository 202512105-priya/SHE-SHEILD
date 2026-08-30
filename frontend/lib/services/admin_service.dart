// lib/services/admin_service.dart
import 'package:local_auth/local_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class AdminService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();

  // Generate a 6‑digit OTP (placeholder – real implementation would call Twilio)
  Future<String> generateOtp(String phone) async {
    // Simulate OTP generation
    final otp = (Random().nextInt(900000) + 100000).toString();
    // Store OTP temporarily in Firestore (for demo only)
    await _firestore.collection('AdminOTPs').doc(phone).set({
      'otp': otp,
      'expiresAt': DateTime.now().add(const Duration(minutes: 5)).toIso8601String(),
    });
    return otp;
  }

  // Verify OTP
  Future<bool> verifyOtp(String phone, String entered) async {
    final doc = await _firestore.collection('AdminOTPs').doc(phone).get();
    if (!doc.exists) return false;
    final data = doc.data()!;
    if (data['otp'] == entered &&
        DateTime.parse(data['expiresAt']).isAfter(DateTime.now())) {
      return true;
    }
    return false;
  }

  // Biometric authentication
  Future<bool> authenticateBiometric() async {
    try {
      bool canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) return false;
      return await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access admin features',
        biometricOnly: true,
        useErrorDialogs: true,
        stickyAuth: true,
      );
    } catch (e) {
      debugPrint('Biometric auth error: $e');
      return false;
    }
  }

  // Simulated access‑alert notification
  Future<void> triggerAccessAlert(String adminId) async {
    await _firestore.collection('AdminAccessAlerts').add({
      'adminId': adminId,
      'timestamp': DateTime.now().toIso8601String(),
      'message': 'Admin accessed restricted area',
    });
  }
}
