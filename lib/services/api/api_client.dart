// ─────────────────────────────────────────────────────────────────────────────
// services/api/api_client.dart — Cliente HTTP base
//
// Clase estática con la URL base del backend y utilidades para manejar el JWT.
// Todas las clases de dominio (AuthApi, LigasApi, etc.) importan de aquí.
//
// El JWT se persiste en SharedPreferences con la clave 'access_token'.
// Se añade automáticamente en la cabecera Authorization de cada petición
// autenticada a través de getAuthHeaders().
// ─────────────────────────────────────────────────────────────────────────────
import 'package:shared_preferences/shared_preferences.dart';

/// Base HTTP client: URL, token management and header building.
/// All domain API classes import from here.
class ApiClient {
  // URL base del servidor Flask.
  // En emulador Android, '10.0.2.2' mapea a localhost del host (la PC).
  // En dispositivo físico por USB, usar 'adb reverse tcp:5000 tcp:5000'
  // y cambiar a 'http://localhost:5000/api'.
  static const String baseUrl = 'http://10.0.2.2:5000/api';

  // Cabeceras para endpoints públicos (sin autenticación)
  static const Map<String, String> publicHeaders = {
    'Content-Type': 'application/json',
  };

  /// Lee el JWT guardado en SharedPreferences.
  /// Devuelve null si el usuario no ha iniciado sesión.
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  /// Guarda el JWT tras un login exitoso.
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  /// Elimina el JWT al hacer logout.
  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  /// Construye las cabeceras HTTP con el JWT incluido.
  /// Si no hay token (usuario no autenticado), solo incluye Content-Type.
  /// Se usa en todos los endpoints protegidos con @jwt_required() en el backend.
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
