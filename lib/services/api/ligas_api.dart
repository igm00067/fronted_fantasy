import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class LigasApi {
  // ── Ligas ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> crearLiga({
    required String nombre,
    required int competicionId,
    String? nombreEquipo,
    int maxParticipantes = 10,
    double presupuestoInicial = 100.0,
  }) async {
    try {
      final headers = await ApiClient.getAuthHeaders();
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/ligas'),
        headers: headers,
        body: jsonEncode({
          'nombre': nombre,
          'competicion_id': competicionId,
          'nombre_equipo': nombreEquipo,
          'max_participantes': maxParticipantes,
          'presupuesto_inicial': presupuestoInicial,
        }),
      );
      if (response.statusCode == 201) return jsonDecode(response.body);
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Error al crear liga');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<List<dynamic>> getMisLigas() async {
    try {
      final headers = await ApiClient.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/ligas/mis-ligas'),
        headers: headers,
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Error al obtener ligas');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<Map<String, dynamic>> unirseALiga({
    required String codigoInvitacion,
    required String nombreEquipo,
  }) async {
    try {
      final headers = await ApiClient.getAuthHeaders();
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/ligas/unirse'),
        headers: headers,
        body: jsonEncode({
          'codigo_invitacion': codigoInvitacion,
          'nombre_equipo': nombreEquipo,
        }),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Error al unirse a liga');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<Map<String, dynamic>> getLiga(int ligaId) async {
    final headers = await ApiClient.getAuthHeaders();
    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}/ligas/$ligaId'),
      headers: headers,
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error obteniendo liga');
  }

  static Future<Map<String, dynamic>> getClasificacion(int ligaId) async {
    try {
      final headers = await ApiClient.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/ligas/$ligaId/clasificacion'),
        headers: headers,
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Error al obtener clasificación: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // ── Equipo ─────────────────────────────────────────────────────────────────

  /// Llamada base compartida por getMiEquipo y getSaldoDisponible.
  static Future<Map<String, dynamic>> _getMiEquipoData(int ligaId) async {
    final headers = await ApiClient.getAuthHeaders();
    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}/ligas/$ligaId/mi-equipo'),
      headers: headers,
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error obteniendo mi equipo');
  }

  static Future<Map<String, dynamic>> getMiEquipoCompleto(int ligaId) =>
      _getMiEquipoData(ligaId);

  static Future<List<dynamic>> getMiEquipo(int ligaId) async {
    final data = await _getMiEquipoData(ligaId);
    return data['plantilla'];
  }

  static Future<double> getSaldoDisponible(int ligaId) async {
    final data = await _getMiEquipoData(ligaId);
    return (data['equipo']['saldo_disponible'] as num).toDouble();
  }

  static Future<void> guardarAlineacion({
    required int ligaId,
    required String formacion,
    required List<Map<String, dynamic>> titulares,
  }) async {
    final headers = await ApiClient.getAuthHeaders();
    final response = await http.post(
      Uri.parse('${ApiClient.baseUrl}/ligas/$ligaId/mi-equipo/alineacion'),
      headers: headers,
      body: jsonEncode({'formacion': formacion, 'titulares': titulares}),
    );
    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Error al guardar alineación');
    }
  }

  static Future<Map<String, dynamic>> getEquipoUsuarioCompleto(int ligaId, int usuarioId) async {
    final headers = await ApiClient.getAuthHeaders();
    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}/ligas/$ligaId/equipo/$usuarioId'),
      headers: headers,
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error obteniendo equipo del usuario');
  }

  static Future<List<dynamic>> getEquipoUsuario(int ligaId, int usuarioId) async {
    final headers = await ApiClient.getAuthHeaders();
    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}/ligas/$ligaId/equipo/$usuarioId'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as Map)['plantilla'];
    }
    throw Exception('Error obteniendo equipo del usuario');
  }

  static Future<Map<String, dynamic>> getPropiedadJugadores(int ligaId) async {
    final headers = await ApiClient.getAuthHeaders();
    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}/ligas/$ligaId/propiedad-jugadores'),
      headers: headers,
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error al obtener propiedad de jugadores');
  }

  static Future<Map<String, dynamic>> venderJugador({
    required int ligaId,
    required int jugadorId,
  }) async {
    final headers = await ApiClient.getAuthHeaders();
    final response = await http.post(
      Uri.parse('${ApiClient.baseUrl}/ligas/$ligaId/mi-equipo/vender-jugador'),
      headers: headers,
      body: jsonEncode({'jugador_id': jugadorId}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    final error = jsonDecode(response.body);
    throw Exception(error['error'] ?? 'Error al vender jugador');
  }

  static Future<Map<String, dynamic>> abandonarLiga(int ligaId) async {
    final headers = await ApiClient.getAuthHeaders();
    final response = await http.post(
      Uri.parse('${ApiClient.baseUrl}/ligas/$ligaId/abandonar'),
      headers: headers,
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    final error = jsonDecode(response.body);
    throw Exception(error['error'] ?? 'Error al abandonar liga');
  }

  // ── Jugadores / Equipos / Competiciones ────────────────────────────────────

  static Future<List<dynamic>> getJugadores({
    int? equipoId,
    String? posicion,
    double? maxPrecio,
  }) async {
    try {
      final params = [
        if (equipoId != null) 'equipo_id=$equipoId',
        if (posicion != null) 'posicion=$posicion',
        if (maxPrecio != null) 'max_precio=$maxPrecio',
      ];
      final url = '${ApiClient.baseUrl}/jugadores'
          '${params.isNotEmpty ? '?${params.join('&')}' : ''}';
      final response = await http.get(Uri.parse(url), headers: ApiClient.publicHeaders);
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Error al obtener jugadores: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<List<dynamic>> buscarJugadores(String nombre) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/jugadores/buscar?nombre=$nombre'),
        headers: ApiClient.publicHeaders,
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Error al buscar jugadores: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<List<dynamic>> getCompeticiones() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/competiciones'),
        headers: ApiClient.publicHeaders,
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Error al obtener competiciones: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<List<dynamic>> getEquipos({int? competicionId}) async {
    try {
      final url = '${ApiClient.baseUrl}/equipos'
          '${competicionId != null ? '?competicion_id=$competicionId' : ''}';
      final response = await http.get(Uri.parse(url), headers: ApiClient.publicHeaders);
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Error al obtener equipos: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // ── Usuarios ───────────────────────────────────────────────────────────────

  static Future<List<dynamic>> getUsuarios() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/usuarios'),
        headers: ApiClient.publicHeaders,
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Error al obtener usuarios: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<Map<String, dynamic>> crearUsuario({
    required String nombre,
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/usuarios'),
        headers: ApiClient.publicHeaders,
        body: jsonEncode({'nombre': nombre, 'email': email}),
      );
      if (response.statusCode == 201) return jsonDecode(response.body);
      throw Exception('Error al crear usuario: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<void> eliminarUsuario(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiClient.baseUrl}/usuarios/$id'),
        headers: ApiClient.publicHeaders,
      );
      if (response.statusCode != 200) throw Exception('Error al eliminar usuario');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
