import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiIntegrationService {
  final String baseUrl;

  ApiIntegrationService({this.baseUrl = "https://api.sheshield.internal"});

  Future<Map<String, dynamic>> postUserWorkflow(String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('API Workflow Request Failed: ${response.statusCode}');
    }
  }
}
