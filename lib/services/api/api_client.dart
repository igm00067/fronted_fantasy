import 'package:shared_preferences/shared_preferences.dart';

/// Base HTTP client: URL, token management and header building.
/// All domain API classes import from here.
class ApiClient {
  // EMULADOR Android → 'http://10.0.2.2:5000/api'
  // DISPOSITIVO FÍSICO (USB) → 'http://localhost:5000/api' + adb reverse tcp:5000 tcp:5000
  static const String baseUrl = 'http://10.0.2.2:5000/api';

  static const Map<String, String> publicHeaders = {
    'Content-Type': 'application/json',
  };

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
