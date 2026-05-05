import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class MercadoApi {
  static Future<List<dynamic>> getMercado(int ligaId) async {
    try {
      final headers = await ApiClient.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/mercado/$ligaId'),
        headers: headers,
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Error al obtener mercado: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<Map<String, dynamic>> realizarPuja({
    required int mercadoId,
    required double cantidad,
  }) async {
    try {
      final headers = await ApiClient.getAuthHeaders();
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/mercado/$mercadoId/pujar'),
        headers: headers,
        body: jsonEncode({'cantidad': cantidad}),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Error al realizar puja');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<List<dynamic>> getMisPujas(int ligaId) async {
    try {
      final headers = await ApiClient.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/mercado/$ligaId/mis-pujas'),
        headers: headers,
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Error al obtener pujas: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<List<dynamic>> getHistorialMercado(int ligaId) async {
    try {
      final headers = await ApiClient.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/mercado/$ligaId/historial'),
        headers: headers,
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Error al obtener historial: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
