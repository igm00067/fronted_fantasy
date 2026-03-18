import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class ApiService {
  // EMULADOR Android → usa: 'http://10.0.2.2:5000/api'
  // DISPOSITIVO FÍSICO (USB) → usa: 'http://localhost:5000/api' + ejecutar "adb reverse tcp:5000 tcp:5000"
  //static const String baseUrl = 'http://localhost:5000/api';
  static const String baseUrl = 'http://10.0.2.2:5000/api';
  
  static final Map<String, String> headers = {
    'Content-Type': 'application/json',
  };

   // ==================== AUTH ====================
  
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
      print('DEBUG TOKEN: $token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Registro
  static Future<Map<String, dynamic>> register({
    required String nombre,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: headers,
        body: jsonEncode({
          'nombre': nombre,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await saveToken(data['access_token']);
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Error al registrar');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Login
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await saveToken(data['access_token']);
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Credenciales inválidas');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener usuario actual
  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final authHeaders = await getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: authHeaders,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al obtener usuario');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Logout
  static Future<void> logout() async {
    await removeToken();
  }

  // ==================== LIGAS ====================
  
  static Future<Map<String, dynamic>> crearLiga({
    required String nombre,
    required int competicionId,
    String? nombreEquipo,
    int maxParticipantes = 10,
    double presupuestoInicial = 100.0,
  }) async {
    try {
      final authHeaders = await getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/ligas'),
        headers: authHeaders,
        body: jsonEncode({
          'nombre': nombre,
          'competicion_id': competicionId,
          'nombre_equipo': nombreEquipo,
          'max_participantes': maxParticipantes,
          'presupuesto_inicial': presupuestoInicial,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Error al crear liga');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<List<dynamic>> getMisLigas() async {
    try {
      final authHeaders = await getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/ligas/mis-ligas'),
        headers: authHeaders,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al obtener ligas');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<Map<String, dynamic>> unirseALiga({
    required String codigoInvitacion,
    required String nombreEquipo,
  }) async {
    try {
      final authHeaders = await getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/ligas/unirse'),
        headers: authHeaders,
        body: jsonEncode({
          'codigo_invitacion': codigoInvitacion,
          'nombre_equipo': nombreEquipo,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Error al unirse a liga');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // ==================== USUARIOS ====================
  
  static Future<List<dynamic>> getUsuarios() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/usuarios'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al obtener usuarios: ${response.statusCode}');
      }
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
        Uri.parse('$baseUrl/usuarios'),
        headers: headers,
        body: jsonEncode({
          'nombre': nombre,
          'email': email,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al crear usuario: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<void> eliminarUsuario(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/usuarios/$id'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Error al eliminar usuario');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // ==================== COMPETICIONES ====================
  
  static Future<List<dynamic>> getCompeticiones() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/competiciones'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al obtener competiciones: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // ==================== EQUIPOS ====================
  
  static Future<List<dynamic>> getEquipos({int? competicionId}) async {
    try {
      String url = '$baseUrl/equipos';
      if (competicionId != null) {
        url += '?competicion_id=$competicionId';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al obtener equipos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // ==================== JUGADORES ====================
  
  static Future<List<dynamic>> getJugadores({
    int? equipoId,
    String? posicion,
    double? maxPrecio,
  }) async {
    try {
      String url = '$baseUrl/jugadores';
      List<String> params = [];
      
      if (equipoId != null) params.add('equipo_id=$equipoId');
      if (posicion != null) params.add('posicion=$posicion');
      if (maxPrecio != null) params.add('max_precio=$maxPrecio');
      
      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al obtener jugadores: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<List<dynamic>> buscarJugadores(String nombre) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/jugadores/buscar?nombre=$nombre'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al buscar jugadores: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // ==================== CLASIFICACIÓN ====================

  static Future<Map<String, dynamic>> getClasificacion(int ligaId) async {
    try {
      final authHeaders = await getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/ligas/$ligaId/clasificacion'),
        headers: authHeaders,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al obtener clasificación: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // ==================== MERCADO ====================

static Future<List<dynamic>> getMercado(int ligaId) async {
  try {
    final authHeaders = await getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/mercado/$ligaId'),
      headers: authHeaders,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener mercado: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error de conexión: $e');
  }
}

static Future<Map<String, dynamic>> realizarPuja({
  required int mercadoId,
  required double cantidad,
}) async {
  try {
    final authHeaders = await getAuthHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/mercado/$mercadoId/pujar'),
      headers: authHeaders,
      body: jsonEncode({
        'cantidad': cantidad,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Error al realizar puja');
    }
  } catch (e) {
    throw Exception('Error de conexión: $e');
  }
}

static Future<List<dynamic>> getMisPujas(int ligaId) async {
  try {
    final authHeaders = await getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/mercado/$ligaId/mis-pujas'),
      headers: authHeaders,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener pujas: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error de conexión: $e');
  }
}
// ==================== HISTORIAL ====================

static Future<List<dynamic>> getHistorialMercado(int ligaId) async {
  try {
    final authHeaders = await getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/mercado/$ligaId/historial'),
      headers: authHeaders,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener historial: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error de conexión: $e');
  }
}

// ==================== CHAT ====================

static Future<List<dynamic>> getConversaciones(int ligaId) async {
  try {
    final authHeaders = await getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/chat/conversaciones/$ligaId'),
      headers: authHeaders,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener conversaciones: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error de conexión: $e');
  }
}

static Future<Map<String, dynamic>> getOCrearConversacion({
  required int otroUsuarioId,
  required int ligaId,
}) async {
  try {
    final authHeaders = await getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/chat/conversacion/$otroUsuarioId/$ligaId'),
      headers: authHeaders,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener conversación: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error de conexión: $e');
  }
}

static Future<List<dynamic>> getMensajes(int conversacionId) async {
  try {
    final authHeaders = await getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/chat/mensajes/$conversacionId'),
      headers: authHeaders,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener mensajes: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error de conexión: $e');
  }
}

// ==================== OFERTAS ====================

static Future<List<dynamic>> getMiEquipo(int ligaId) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');

  final response = await http.get(
    Uri.parse('$baseUrl/ligas/$ligaId/mi-equipo'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data['plantilla'];
  } else {
    throw Exception('Error obteniendo mi equipo');
  }
}

static Future<List<dynamic>> getEquipoUsuario(int ligaId, int usuarioId) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');

  final response = await http.get(
    Uri.parse('$baseUrl/ligas/$ligaId/equipo/$usuarioId'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data['plantilla'];
  } else {
    throw Exception('Error obteniendo equipo del usuario');
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
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');

  final response = await http.post(
    Uri.parse('$baseUrl/chat/oferta/crear'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: json.encode({
      'conversacion_id': conversacionId,
      'jugador_ofrecido_id': jugadorOfrecidoId,
      'dinero_ofrecido': dineroOfrecido,
      'jugador_solicitado_id': jugadorSolicitadoId,
      'dinero_solicitado': dineroSolicitado,
      'mensaje': mensaje,
    }),
  );

  if (response.statusCode == 201) {
    return json.decode(response.body);
  } else {
    final error = json.decode(response.body);
    throw Exception(error['error'] ?? 'Error creando oferta');
  }
}

static Future<Map<String, dynamic>> responderOferta({
  required int ofertaId,
  required String accion, // 'ACEPTAR' o 'RECHAZAR'
}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');

  final response = await http.post(
    Uri.parse('$baseUrl/chat/oferta/$ofertaId/responder'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: json.encode({
      'accion': accion,
    }),
  );

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    final error = json.decode(response.body);
    throw Exception(error['error'] ?? 'Error respondiendo oferta');
  }
}




  // Método de prueba
  static Future<bool> testConexion() async {
    try {
      // EMULADOR: 'http://10.0.2.2:5000/'  |  DISPOSITIVO FÍSICO: 'http://192.168.194.109:5000/'
      final response = await http.get(Uri.parse('http://10.0.2.2:5000/'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}