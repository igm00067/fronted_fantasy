import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class SimulacionApi {
  static Future<Map<String, dynamic>> getEstadoInicio(int ligaId) async {
    final headers = await ApiClient.getAuthHeaders();
    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}/ligas/$ligaId/estado-inicio'),
      headers: headers,
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error obteniendo estado de inicio');
  }

  static Future<Map<String, dynamic>> confirmarInicio(int ligaId) async {
    final headers = await ApiClient.getAuthHeaders();
    final response = await http.post(
      Uri.parse('${ApiClient.baseUrl}/ligas/$ligaId/confirmar-inicio'),
      headers: headers,
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception(jsonDecode(response.body)['error'] ?? 'Error al confirmar');
  }

  static Future<void> retirarConfirmacion(int ligaId) async {
    final headers = await ApiClient.getAuthHeaders();
    final response = await http.delete(
      Uri.parse('${ApiClient.baseUrl}/ligas/$ligaId/confirmar-inicio'),
      headers: headers,
    );
    if (response.statusCode != 200) throw Exception('Error al retirar confirmación');
  }

  static Future<List<dynamic>> getCalendario(int ligaId) async {
    final headers = await ApiClient.getAuthHeaders();
    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}/ligas/$ligaId/calendario'),
      headers: headers,
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error obteniendo calendario');
  }

  static Future<Map<String, dynamic>?> getJornadaActual(int ligaId) async {
    final headers = await ApiClient.getAuthHeaders();
    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}/ligas/$ligaId/jornada-actual'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data == null) return null;
      if (data['jornada'] == null && !data.containsKey('id')) return null;
      return data;
    }
    throw Exception('Error obteniendo jornada actual');
  }

  static Future<Map<String, dynamic>> getPartido(int partidoId) async {
    final headers = await ApiClient.getAuthHeaders();
    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}/ligas/partidos/$partidoId'),
      headers: headers,
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error obteniendo partido');
  }

  static Future<void> enviarCambiosDescanso({
    required int ligaId,
    required int partidoId,
    required List<Map<String, int>> cambios,
  }) async {
    final headers = await ApiClient.getAuthHeaders();
    final response = await http.post(
      Uri.parse('${ApiClient.baseUrl}/ligas/$ligaId/partidos/$partidoId/cambios-descanso'),
      headers: headers,
      body: jsonEncode({'cambios': cambios}),
    );
    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Error al enviar cambios');
    }
  }

  static Future<Map<String, dynamic>> simularJornadaManual(int ligaId) async {
    final headers = await ApiClient.getAuthHeaders();
    final response = await http.post(
      Uri.parse('${ApiClient.baseUrl}/ligas/$ligaId/simular-jornada'),
      headers: headers,
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception(jsonDecode(response.body)['error'] ?? 'Error al simular');
  }
}
