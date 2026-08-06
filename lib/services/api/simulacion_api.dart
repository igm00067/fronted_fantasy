// ─────────────────────────────────────────────────────────────────────────────
// services/api/simulacion_api.dart — Llamadas HTTP para inicio y simulación
//
// Flujo de inicio de liga (en inicio_liga_screen.dart):
//   1. getEstadoInicio() → ver cuántos han confirmado y si el usuario ya confirmó
//   2. confirmarInicio() → votar "listo para empezar"
//   3. retirarConfirmacion() → deshacer voto
//   4. Cuando TODOS los participantes confirman → backend genera el calendario
//      (generar_calendario_sync) y asigna jugadores aleatorios a cada equipo
//
// Flujo de consulta de simulación:
//   getCalendario()     → todas las jornadas y partidos (con resultados si finalizados)
//   getJornadaActual()  → jornada en curso o null si no hay ninguna activa
//   getPartido()        → detalle de un partido con eventos minuto a minuto
//   enviarCambiosDescanso() → sustituciones durante el descanso
//   simularJornadaManual()  → forzar simulación de la jornada actual (debug/admin)
//
// La simulación ocurre en el backend vía APScheduler (tick_scheduler cada 60s).
// El frontend recibe actualizaciones en tiempo real por Socket.IO (no polling).
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class SimulacionApi {
  /// GET /api/ligas/<ligaId>/estado-inicio
  /// Devuelve cuántos participantes han confirmado y si el usuario ya confirmó.
  /// Respuesta: { total: N, confirmados: M, usuario_confirmado: bool }
  /// Usado en inicio_liga_screen.dart para mostrar el progreso de confirmaciones.
  static Future<Map<String, dynamic>> getEstadoInicio(int ligaId) async {
    final headers = await ApiClient.getAuthHeaders();
    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}/ligas/$ligaId/estado-inicio'),
      headers: headers,
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error obteniendo estado de inicio');
  }

  /// POST /api/ligas/<ligaId>/confirmar-inicio
  /// El usuario confirma que está listo para empezar la liga.
  /// Si todos los participantes confirman, el backend:
  ///   1. Asigna jugadores aleatorios a cada equipo (2POR+5DEF+5MED+3DEL)
  ///   2. Genera el calendario round-robin (todos contra todos ×2)
  ///   3. Cambia el estado de la liga a 'en_curso'
  ///   4. Programa la primera jornada
  static Future<Map<String, dynamic>> confirmarInicio(int ligaId) async {
    final headers = await ApiClient.getAuthHeaders();
    final response = await http.post(
      Uri.parse('${ApiClient.baseUrl}/ligas/$ligaId/confirmar-inicio'),
      headers: headers,
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception(jsonDecode(response.body)['error'] ?? 'Error al confirmar');
  }

  /// DELETE /api/ligas/<ligaId>/confirmar-inicio
  /// El usuario retira su confirmación (mientras no todos hayan confirmado).
  static Future<void> retirarConfirmacion(int ligaId) async {
    final headers = await ApiClient.getAuthHeaders();
    final response = await http.delete(
      Uri.parse('${ApiClient.baseUrl}/ligas/$ligaId/confirmar-inicio'),
      headers: headers,
    );
    if (response.statusCode != 200) throw Exception('Error al retirar confirmación');
  }

  /// GET /api/ligas/<ligaId>/calendario
  /// Devuelve todas las jornadas con sus partidos. Para partidos finalizados
  /// incluye el resultado y los eventos (goles, tarjetas, etc.).
  /// Usado en la pantalla de calendario/jornada_screen.dart.
  static Future<List<dynamic>> getCalendario(int ligaId) async {
    final headers = await ApiClient.getAuthHeaders();
    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}/ligas/$ligaId/calendario'),
      headers: headers,
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error obteniendo calendario');
  }

  /// GET /api/ligas/<ligaId>/jornada-actual
  /// Devuelve la jornada actualmente en curso o null si no hay ninguna activa.
  /// Se usa en home_screen.dart y en la pantalla de liga para mostrar el partido activo.
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

  /// GET /api/ligas/partidos/<partidoId>
  /// Devuelve el detalle completo de un partido:
  ///   - Estado (pendiente, primer_tiempo, descanso, segundo_tiempo, finalizado)
  ///   - Marcador actual
  ///   - Lista de eventos con minuto, tipo (gol/tarjeta/lesión/cambio), jugador
  ///   - Alineaciones de ambos equipos
  /// Usado en partido_screen.dart para ver el partido en tiempo real.
  static Future<Map<String, dynamic>> getPartido(int partidoId) async {
    final headers = await ApiClient.getAuthHeaders();
    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}/ligas/partidos/$partidoId'),
      headers: headers,
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error obteniendo partido');
  }

  /// POST /api/ligas/<ligaId>/partidos/<partidoId>/cambios-descanso
  /// Envía las sustituciones que el usuario quiere hacer durante el descanso.
  /// Cada cambio: { jugador_sale_id: int, jugador_entra_id: int }
  /// El backend las aplica al inicio del segundo tiempo.
  /// Máximo 5 cambios por partido (suma de los del descanso y en juego).
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

  /// POST /api/ligas/<ligaId>/simular-jornada
  /// Fuerza la simulación inmediata de la jornada actual sin esperar al scheduler.
  /// Útil para depuración o para demostrar la aplicación sin esperar el tick de 60s.
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
