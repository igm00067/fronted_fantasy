// ─────────────────────────────────────────────────────────────────────────────
// services/api_service.dart — Fachada (Facade) de todos los servicios API
//
// Reúne en una sola clase todos los métodos de comunicación con el backend.
// Delega internamente a las clases de dominio específicas:
//   AuthApi       → autenticación (register, login, logout)
//   LigasApi      → gestión de ligas, equipos, jugadores, clasificación
//   MercadoApi    → mercado de subastas y pujas
//   ChatApi       → mensajes y ofertas de traspaso
//   SimulacionApi → confirmación de inicio, calendario, partidos, cambios
//
// Las pantallas existentes importan ApiService para mantener compatibilidad.
// El código nuevo puede importar directamente la clase de dominio correspondiente.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:http/http.dart' as http;
import 'api/api_client.dart';
import 'api/auth_api.dart';
import 'api/ligas_api.dart';
import 'api/mercado_api.dart';
import 'api/chat_api.dart';
import 'api/simulacion_api.dart';

/// Facade that delegates to domain-specific API classes.
/// Kept for backward compatibility with existing screens.
/// New code should import the domain classes directly (e.g. LigasApi, MercadoApi).
class ApiService {
  // Exposed so legacy screens can still reference ApiService.baseUrl
  static const String baseUrl = ApiClient.baseUrl;

  // ── Token / Headers ─────────────────────────────────────────────────────────
  static Future<String?> getToken() => ApiClient.getToken();
  static Future<void> saveToken(String token) => ApiClient.saveToken(token);
  static Future<void> removeToken() => ApiClient.removeToken();
  static Future<Map<String, String>> getAuthHeaders() => ApiClient.getAuthHeaders();

  // ── Auth ─────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> register({
    required String nombre,
    required String email,
    required String password,
  }) => AuthApi.register(nombre: nombre, email: email, password: password);

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) => AuthApi.login(email: email, password: password);

  static Future<Map<String, dynamic>> getCurrentUser() => AuthApi.getCurrentUser();
  static Future<void> logout() => AuthApi.logout();

  // ── Ligas ────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> crearLiga({
    required String nombre,
    required int competicionId,
    String? nombreEquipo,
    int maxParticipantes = 10,
    double presupuestoInicial = 100.0,
  }) => LigasApi.crearLiga(
    nombre: nombre,
    competicionId: competicionId,
    nombreEquipo: nombreEquipo,
    maxParticipantes: maxParticipantes,
    presupuestoInicial: presupuestoInicial,
  );

  static Future<List<dynamic>> getMisLigas() => LigasApi.getMisLigas();

  static Future<Map<String, dynamic>> unirseALiga({
    required String codigoInvitacion,
    required String nombreEquipo,
  }) => LigasApi.unirseALiga(
    codigoInvitacion: codigoInvitacion,
    nombreEquipo: nombreEquipo,
  );

  static Future<Map<String, dynamic>> getLiga(int ligaId) =>
      LigasApi.getLiga(ligaId);

  static Future<Map<String, dynamic>> getClasificacion(int ligaId) =>
      LigasApi.getClasificacion(ligaId);

  static Future<List<dynamic>> getMiEquipo(int ligaId) =>
      LigasApi.getMiEquipo(ligaId);

  static Future<double> getSaldoDisponible(int ligaId) =>
      LigasApi.getSaldoDisponible(ligaId);

  static Future<List<dynamic>> getEquipoUsuario(int ligaId, int usuarioId) =>
      LigasApi.getEquipoUsuario(ligaId, usuarioId);

  static Future<Map<String, dynamic>> getPropiedadJugadores(int ligaId) =>
      LigasApi.getPropiedadJugadores(ligaId);

  static Future<Map<String, dynamic>> venderJugador({
    required int ligaId,
    required int jugadorId,
  }) => LigasApi.venderJugador(ligaId: ligaId, jugadorId: jugadorId);

  static Future<Map<String, dynamic>> abandonarLiga(int ligaId) =>
      LigasApi.abandonarLiga(ligaId);

  static Future<Map<String, dynamic>> expulsarParticipante(int ligaId, int usuarioId) =>
      LigasApi.expulsarParticipante(ligaId, usuarioId);

  // ── Jugadores / Equipos / Competiciones ──────────────────────────────────────
  static Future<List<dynamic>> getJugadores({
    int? equipoId,
    String? posicion,
    double? maxPrecio,
  }) => LigasApi.getJugadores(equipoId: equipoId, posicion: posicion, maxPrecio: maxPrecio);

  static Future<List<dynamic>> buscarJugadores(String nombre) =>
      LigasApi.buscarJugadores(nombre);

  static Future<List<dynamic>> getCompeticiones() => LigasApi.getCompeticiones();

  static Future<List<dynamic>> getEquipos({int? competicionId}) =>
      LigasApi.getEquipos(competicionId: competicionId);

  static Future<List<dynamic>> getUsuarios() => LigasApi.getUsuarios();

  static Future<Map<String, dynamic>> crearUsuario({
    required String nombre,
    required String email,
  }) => LigasApi.crearUsuario(nombre: nombre, email: email);

  static Future<void> eliminarUsuario(int id) => LigasApi.eliminarUsuario(id);

  // ── Mercado ──────────────────────────────────────────────────────────────────
  static Future<List<dynamic>> getMercado(int ligaId) =>
      MercadoApi.getMercado(ligaId);

  static Future<Map<String, dynamic>> realizarPuja({
    required int mercadoId,
    required double cantidad,
  }) => MercadoApi.realizarPuja(mercadoId: mercadoId, cantidad: cantidad);

  static Future<List<dynamic>> getMisPujas(int ligaId) =>
      MercadoApi.getMisPujas(ligaId);

  static Future<List<dynamic>> getHistorialMercado(int ligaId) =>
      MercadoApi.getHistorialMercado(ligaId);

  // ── Chat ─────────────────────────────────────────────────────────────────────
  static Future<List<dynamic>> getConversaciones(int ligaId) =>
      ChatApi.getConversaciones(ligaId);

  static Future<Map<String, dynamic>> getOCrearConversacion({
    required int otroUsuarioId,
    required int ligaId,
  }) => ChatApi.getOCrearConversacion(otroUsuarioId: otroUsuarioId, ligaId: ligaId);

  static Future<Map<String, dynamic>> getMensajes(int conversacionId) =>
      ChatApi.getMensajes(conversacionId);

  static Future<Map<String, dynamic>> crearOferta({
    required int conversacionId,
    int? jugadorOfrecidoId,
    double dineroOfrecido = 0,
    int? jugadorSolicitadoId,
    double dineroSolicitado = 0,
    String mensaje = '',
  }) => ChatApi.crearOferta(
    conversacionId: conversacionId,
    jugadorOfrecidoId: jugadorOfrecidoId,
    dineroOfrecido: dineroOfrecido,
    jugadorSolicitadoId: jugadorSolicitadoId,
    dineroSolicitado: dineroSolicitado,
    mensaje: mensaje,
  );

  static Future<Map<String, dynamic>> responderOferta({
    required int ofertaId,
    required String accion,
  }) => ChatApi.responderOferta(ofertaId: ofertaId, accion: accion);

  // ── Simulación ───────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getEstadoInicio(int ligaId) =>
      SimulacionApi.getEstadoInicio(ligaId);

  static Future<Map<String, dynamic>> confirmarInicio(int ligaId) =>
      SimulacionApi.confirmarInicio(ligaId);

  static Future<void> retirarConfirmacion(int ligaId) =>
      SimulacionApi.retirarConfirmacion(ligaId);

  static Future<List<dynamic>> getCalendario(int ligaId) =>
      SimulacionApi.getCalendario(ligaId);

  static Future<Map<String, dynamic>?> getJornadaActual(int ligaId) =>
      SimulacionApi.getJornadaActual(ligaId);

  static Future<Map<String, dynamic>> getPartido(int partidoId) =>
      SimulacionApi.getPartido(partidoId);

  static Future<void> enviarCambiosDescanso({
    required int ligaId,
    required int partidoId,
    required List<Map<String, int>> cambios,
  }) => SimulacionApi.enviarCambiosDescanso(
    ligaId: ligaId,
    partidoId: partidoId,
    cambios: cambios,
  );

  static Future<Map<String, dynamic>> simularJornadaManual(int ligaId) =>
      SimulacionApi.simularJornadaManual(ligaId);

  // ── Test ─────────────────────────────────────────────────────────────────────
  static Future<bool> testConexion() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:5000/'));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
