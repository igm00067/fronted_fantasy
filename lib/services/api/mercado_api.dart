// ─────────────────────────────────────────────────────────────────────────────
// services/api/mercado_api.dart — Llamadas HTTP al blueprint mercado del backend
//
// El mercado es un sistema de subastas ciegas con fecha de cierre automática.
// Los items (jugadores) se añaden cuando la liga inicia (generar_jugadores_mercado).
// El scheduler tick_mercado (cada 30s) procesa items cuya fecha_cierre ya pasó
// y asigna el jugador al mejor postor mediante procesar_ganador_subasta().
//
// Endpoints:
//   GET  /api/mercado/<ligaId>              → items activos en subasta
//   POST /api/mercado/<mercadoId>/pujar     → enviar puja sobre un item
//   GET  /api/mercado/<ligaId>/mis-pujas    → pujas activas del usuario
//   GET  /api/mercado/<ligaId>/historial    → historial de subastas cerradas
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class MercadoApi {
  /// GET /api/mercado/<ligaId>
  /// Devuelve la lista de items activos en el mercado de la liga.
  /// Cada item incluye jugador, puja_actual, mejor_postor, fecha_cierre.
  /// Usada en MercadoProvider.cargar() y en mercado_screen.dart.
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

  /// POST /api/mercado/<mercadoId>/pujar
  /// Envía una puja sobre un item del mercado.
  /// El backend valida: cantidad > puja_actual Y cantidad <= saldo_disponible.
  /// Si la puja es exitosa, la puja_actual del item sube y el mejor_postor cambia.
  /// El dinero se reserva al pujar y se devuelve si pierde la subasta.
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

  /// GET /api/mercado/<ligaId>/mis-pujas
  /// Devuelve todas las pujas activas del usuario autenticado en la liga.
  /// Cada elemento incluye el item de mercado y la cantidad pujada.
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

  /// GET /api/mercado/<ligaId>/historial
  /// Devuelve el historial de subastas cerradas: quién ganó cada jugador y a qué precio.
  /// Usado en historial_mercado_screen.dart para ver traspasos pasados.
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
