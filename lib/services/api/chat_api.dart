import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class ChatApi {
  static Future<List<dynamic>> getConversaciones(int ligaId) async {
    try {
      final headers = await ApiClient.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/chat/conversaciones/$ligaId'),
        headers: headers,
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Error al obtener conversaciones: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<Map<String, dynamic>> getOCrearConversacion({
    required int otroUsuarioId,
    required int ligaId,
  }) async {
    try {
      final headers = await ApiClient.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/chat/conversacion/$otroUsuarioId/$ligaId'),
        headers: headers,
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Error al obtener conversación: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<Map<String, dynamic>> getMensajes(int conversacionId) async {
    try {
      final headers = await ApiClient.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/chat/mensajes/$conversacionId'),
        headers: headers,
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Error al obtener mensajes: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<Map<String, dynamic>> crearOferta({
    required int conversacionId,
    int? jugadorOfrecidoId,
    double dineroOfrecido = 0,
    int? jugadorSolicitadoId,
    double dineroSolicitado = 0,
    String mensaje = '',
  }) async {
    final headers = await ApiClient.getAuthHeaders();
    final response = await http.post(
      Uri.parse('${ApiClient.baseUrl}/chat/oferta/crear'),
      headers: headers,
      body: jsonEncode({
        'conversacion_id': conversacionId,
        'jugador_ofrecido_id': jugadorOfrecidoId,
        'dinero_ofrecido': dineroOfrecido,
        'jugador_solicitado_id': jugadorSolicitadoId,
        'dinero_solicitado': dineroSolicitado,
        'mensaje': mensaje,
      }),
    );
    if (response.statusCode == 201) return jsonDecode(response.body);
    final error = jsonDecode(response.body);
    throw Exception(error['error'] ?? 'Error creando oferta');
  }

  static Future<Map<String, dynamic>> responderOferta({
    required int ofertaId,
    required String accion, // 'ACEPTAR' o 'RECHAZAR'
  }) async {
    final headers = await ApiClient.getAuthHeaders();
    final response = await http.post(
      Uri.parse('${ApiClient.baseUrl}/chat/oferta/$ofertaId/responder'),
      headers: headers,
      body: jsonEncode({'accion': accion}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    final error = jsonDecode(response.body);
    throw Exception(error['error'] ?? 'Error respondiendo oferta');
  }
}
