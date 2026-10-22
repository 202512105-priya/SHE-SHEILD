class AuditService {
  static final List<Map<String, dynamic>> _logs = [];

  static void logEvent(String event, String user) {
    _logs.add({
      'event': event,
      'user': user,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  static List<Map<String, dynamic>> get logs => List.unmodifiable(_logs);
}