import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String defaultBaseUrl = "http://localhost:5000";
  final String baseUrl;
  ApiClient({this.baseUrl = defaultBaseUrl});

  Map<String, String> _buildHeaders([String? token]) {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Map<String, String> getAuthHeaders(String token) {
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token"
    };
  }

  bool isUnauthorized(int statusCode) => statusCode == 401;

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: _buildHeaders(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> sendSos(String sessionId, double lat, double lng, [String? token]) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/sos/broadcast'),
      headers: _buildHeaders(token),
      body: jsonEncode({'sessionId': sessionId, 'latitude': lat, 'longitude': lng}),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> sendTravelPing(String tripId, double lat, double lng, [String? token]) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/travel/ping'),
      headers: _buildHeaders(token),
      body: jsonEncode({'tripId': tripId, 'latitude': lat, 'longitude': lng}),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> submitCyberReport(Map<String, dynamic> data, [String? token]) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/cyber/submit'),
      headers: _buildHeaders(token),
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }
}
