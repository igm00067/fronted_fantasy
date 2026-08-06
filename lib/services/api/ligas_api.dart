// ─────────────────────────────────────────────────────────────────────────────
// services/api/ligas_api.dart — Llamadas HTTP a los blueprints ligas, jugadores,
//                               equipos, competiciones y usuarios del backend
//
// Agrupa en una sola clase estática todos los endpoints relacionados con la
// gestión de ligas y datos auxiliares. Organizado en secciones:
//
//   ── Ligas ──────── CRUD de ligas, unirse, clasificación, abandono, expulsión
//   ── Equipo ──────── mi equipo, alineación, ver plantilla rival, vender jugador
//   ── Jugadores/Equipos/Competiciones ── catálogos y búsqueda
//   ── Usuarios ────── lista y gestión de usuarios (admin)
//
// Patrón de errores: todas las funciones lanzan Exception con el mensaje del
// servidor si el código HTTP no es el esperado.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

/// Clase estática de acceso a la API de ligas, equipos y catálogos.
class LigasApi {
  // ── Ligas ──────────────────────────────────────────────────────────────────

  /// POST /api/ligas
  /// Crea una nueva liga fantasy. El creador se convierte automáticamente en
  /// el primer participante y se le asigna un equipo con nombre opcional.
  /// El backend genera el codigo_invitacion de 6 caracteres aleatorio.
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

  /// GET /api/ligas/mis-ligas
  /// Devuelve todas las ligas en las que participa el usuario autenticado.
  /// Usada en LigasProvider.cargarMisLigas() → mis_ligas_screen.dart.
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

  /// POST /api/ligas/unirse
  /// Une al usuario a una liga usando el código de invitación.
  /// El backend crea un EquipoFantasy para el usuario y un ParticipanteLiga.
  /// Falla si la liga ya alcanzó max_participantes o si el usuario ya está.
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

  /// GET /api/ligas/<ligaId>
  /// Obtiene los detalles completos de una liga: nombre, estado, participantes, etc.
  static Future<Map<String, dynamic>> getLiga(int ligaId) async {
    final headers = await ApiClient.getAuthHeaders();
    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}/ligas/$ligaId'),
      headers: headers,
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error obteniendo liga');
  }

  /// GET /api/ligas/<ligaId>/clasificacion
  /// Devuelve la tabla de clasificación de la liga con stats de cada equipo:
  /// partidos jugados, victorias, empates, derrotas, goles, puntos fantasy.
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

  /// GET /api/ligas/<ligaId>/mi-equipo — llamada base privada.
  /// Devuelve { equipo: {...}, plantilla: [...] }.
  /// Compartida por getMiEquipo() y getSaldoDisponible() para evitar duplicar peticiones
  /// cuando ya tenemos ambos datos disponibles en el mismo endpoint.
  static Future<Map<String, dynamic>> _getMiEquipoData(int ligaId) async {
    final headers = await ApiClient.getAuthHeaders();
    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}/ligas/$ligaId/mi-equipo'),
      headers: headers,
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error obteniendo mi equipo');
  }

  /// Devuelve el mapa completo { equipo, plantilla }. Usado en mi_equipo_screen.dart.
  static Future<Map<String, dynamic>> getMiEquipoCompleto(int ligaId) =>
      _getMiEquipoData(ligaId);

  /// Devuelve solo la lista de jugadores en plantilla. Usado donde no se necesita equipo.
  static Future<List<dynamic>> getMiEquipo(int ligaId) async {
    final data = await _getMiEquipoData(ligaId);
    return data['plantilla'];
  }

  /// Devuelve solo el saldo disponible del equipo. Usado en MercadoProvider.cargar().
  static Future<double> getSaldoDisponible(int ligaId) async {
    final data = await _getMiEquipoData(ligaId);
    return (data['equipo']['saldo_disponible'] as num).toDouble();
  }

  /// POST /api/ligas/<ligaId>/mi-equipo/alineacion
  /// Guarda la alineación del usuario: qué jugadores son titulares y la formación.
  /// El backend actualiza es_titular y posicion_en_campo en PlantillaEquipo.
  /// También se aplican los cambios de descanso en esta llamada si el partido está activo.
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

  /// GET /api/ligas/<ligaId>/equipo/<usuarioId>
  /// Devuelve el equipo completo de otro usuario (para ver la plantilla rival).
  /// Igual que _getMiEquipoData pero para cualquier usuarioId, no solo el autenticado.
  static Future<Map<String, dynamic>> getEquipoUsuarioCompleto(int ligaId, int usuarioId) async {
    final headers = await ApiClient.getAuthHeaders();
    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}/ligas/$ligaId/equipo/$usuarioId'),
      headers: headers,
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error obteniendo equipo del usuario');
  }

  /// Igual que getEquipoUsuarioCompleto pero devuelve solo la lista de plantilla.
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

  /// GET /api/ligas/<ligaId>/propiedad-jugadores
  /// Devuelve un mapa { jugador_id → usuario_id } con todos los jugadores
  /// que ya tienen dueño en la liga. Se usa en crear_oferta_screen.dart para
  /// filtrar qué jugadores puede solicitar el usuario al rival.
  static Future<Map<String, dynamic>> getPropiedadJugadores(int ligaId) async {
    final headers = await ApiClient.getAuthHeaders();
    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}/ligas/$ligaId/propiedad-jugadores'),
      headers: headers,
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error al obtener propiedad de jugadores');
  }

  /// POST /api/ligas/<ligaId>/mi-equipo/vender-jugador
  /// Vende un jugador de vuelta al mercado libre.
  /// El backend elimina al jugador de PlantillaEquipo y suma su precio al saldo.
  /// Se registra en HistorialTransaccion con tipo VENTA.
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

  /// POST /api/ligas/<ligaId>/abandonar
  /// El usuario sale de la liga. Si era el creador, el rol pasa al siguiente
  /// participante por fecha_union. Si era el último, la liga se elimina.
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

  /// POST /api/ligas/<ligaId>/expulsar/<usuarioId>
  /// Solo puede llamarlo el creador de la liga. Expulsa al participante
  /// y marca su registro como abandonado en HistorialTransaccion (tipo EXPULSION).
  static Future<Map<String, dynamic>> expulsarParticipante(int ligaId, int usuarioId) async {
    final headers = await ApiClient.getAuthHeaders();
    final response = await http.post(
      Uri.parse('${ApiClient.baseUrl}/ligas/$ligaId/expulsar/$usuarioId'),
      headers: headers,
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    final error = jsonDecode(response.body);
    throw Exception(error['error'] ?? 'Error al expulsar participante');
  }

  // ── Jugadores / Equipos / Competiciones ────────────────────────────────────

  /// GET /api/jugadores[?equipo_id=&posicion=&max_precio=]
  /// Devuelve el catálogo de jugadores con filtros opcionales.
  /// Usado en buscar_jugadores_screen.dart para explorar el catálogo completo.
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

  /// GET /api/jugadores/buscar?nombre=<nombre>
  /// Búsqueda por nombre (LIKE %nombre%). Usada en el buscador de jugadores
  /// con debounce para no saturar el backend con cada tecla.
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

  /// GET /api/competiciones
  /// Devuelve todas las competiciones disponibles (ej. La Liga, Champions...).
  /// Usada en crear_liga_screen.dart para que el usuario elija la competición.
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

  /// GET /api/equipos[?competicion_id=<id>]
  /// Devuelve equipos reales de fútbol, opcionalmente filtrados por competición.
  /// Usada en buscar_jugadores_screen.dart para filtrar jugadores por equipo.
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
  // Endpoints de gestión de usuarios (principalmente para uso interno/admin).

  /// GET /api/usuarios — devuelve todos los usuarios registrados.
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
