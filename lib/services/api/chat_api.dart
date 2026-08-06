// ─────────────────────────────────────────────────────────────────────────────
// services/api/chat_api.dart — Llamadas HTTP al blueprint chat del backend
//
// El sistema de chat permite comunicación privada 1:1 entre usuarios de una liga
// y el intercambio de ofertas de traspaso directas (entre dos equipos).
//
// Tipos de mensaje:
//   TEXTO  → mensaje de texto libre
//   OFERTA → oferta de traspaso con jugadores y/o dinero
//
// Flujo de oferta:
//   1. Usuario A crea oferta → POST /chat/oferta/crear
//   2. Backend emite 'new_message' por Socket.IO con tipo=OFERTA
//   3. Usuario B ve la oferta en chat_conversacion_screen.dart
//   4. Usuario B responde → POST /chat/oferta/<id>/responder con ACEPTAR/RECHAZAR
//   5. Si ACEPTAR: backend ejecuta chat_service.ejecutar_intercambio()
//      y emite 'oferta_resuelta' a ambos usuarios
//
// Endpoints:
//   GET  /api/chat/conversaciones/<ligaId>         → lista de conversaciones del usuario
//   GET  /api/chat/conversacion/<otro>/<liga>      → obtener/crear conversación
//   GET  /api/chat/mensajes/<conversacionId>       → historial de mensajes
//   POST /api/chat/oferta/crear                    → crear oferta de traspaso
//   POST /api/chat/oferta/<id>/responder           → aceptar o rechazar oferta
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class ChatApi {
  /// GET /api/chat/conversaciones/<ligaId>
  /// Devuelve todas las conversaciones del usuario en la liga, con el último mensaje
  /// y el nombre del otro participante. Usada en chat_liga_screen.dart.
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

  /// GET /api/chat/conversacion/<otroUsuarioId>/<ligaId>
  /// Obtiene la conversación entre el usuario autenticado y otro usuario en la liga.
  /// Si no existe, el backend la crea automáticamente.
  /// Usada en chat_conversacion_screen.dart al abrir un chat.
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

  /// GET /api/chat/mensajes/<conversacionId>
  /// Devuelve el historial de mensajes de una conversación (TEXTO + OFERTA).
  /// Los mensajes OFERTA incluyen los detalles del intercambio y el estado actual
  /// (PENDIENTE, ACEPTADA, RECHAZADA).
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

  /// POST /api/chat/oferta/crear
  /// Crea una oferta de traspaso en una conversación.
  /// Combinaciones posibles:
  ///   - Jugador por jugador (intercambio)
  ///   - Jugador por dinero (compra con compensación)
  ///   - Solo dinero (oferta en efectivo por un jugador del otro)
  ///   - Jugador + dinero por jugador (oferta mixta)
  /// El backend emite 'new_message' con tipo=OFERTA por Socket.IO al destinatario.
  static Future<Map<String, dynamic>> crearOferta({
    required int conversacionId,
    int? jugadorOfrecidoId,         // jugador que ofrece el remitente (puede ser null)
    double dineroOfrecido = 0,       // dinero adicional que pone el remitente
    int? jugadorSolicitadoId,        // jugador que quiere del destinatario (puede ser null)
    double dineroSolicitado = 0,     // dinero que pide al destinatario
    String mensaje = '',             // mensaje de texto que acompaña la oferta
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

  /// POST /api/chat/oferta/<ofertaId>/responder
  /// El destinatario acepta o rechaza una oferta recibida.
  ///   accion: 'ACEPTAR' → ejecuta el intercambio de jugadores/dinero
  ///           'RECHAZAR' → cambia estado a RECHAZADA, no mueve nada
  /// Si ACEPTAR: el backend llama chat_service.ejecutar_intercambio() y emite
  /// 'oferta_resuelta' por Socket.IO a ambos usuarios de la conversación.
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
