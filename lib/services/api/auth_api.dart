import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class AuthApi {
  static Future<Map<String, dynamic>> register({
    required String nombre,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/auth/register'),
        headers: ApiClient.publicHeaders,
        body: jsonEncode({'nombre': nombre, 'email': email, 'password': password}),
      );
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await ApiClient.saveToken(data['access_token']);
        return data;
      }
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Error al registrar');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/auth/login'),
        headers: ApiClient.publicHeaders,
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await ApiClient.saveToken(data['access_token']);
        return data;
      }
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Credenciales inválidas');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final headers = await ApiClient.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/auth/me'),
        headers: headers,
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Error al obtener usuario');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<void> logout() => ApiClient.removeToken();
}
