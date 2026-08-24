import 'package:flutter/foundation.dart';

class DatabaseService extends ChangeNotifier {
  bool _initialized = true;
  bool get initialized => _initialized;
  
  bool _onboardingCompleted = false;
  bool get onboardingCompleted => _onboardingCompleted;

  String? _currentUserId;
  String? get currentUserId => _currentUserId;

  String sha256Hash(String value) {
    return "hash_value_placeholder";
  }

  Future<void> addDocument(String collection, String docId, Map<String, dynamic> data) async {
    // Database storage operations
  }
}