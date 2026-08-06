// ─────────────────────────────────────────────────────────────────────────────
// services/api/auth_api.dart — Llamadas HTTP al blueprint auth del backend
//
// Endpoints cubiertos:
//   POST /api/auth/register          → registrar nuevo usuario
//   POST /api/auth/login             → iniciar sesión y obtener JWT
//   GET  /api/auth/me                → obtener datos del usuario autenticado
//   POST /api/auth/forgot-password   → solicitar enlace de recuperación por email
//   POST /api/auth/resend-verification → reenviar email de verificación
//
// Nota sobre login y email no verificado:
//   Si el backend devuelve { codigo: 'email_no_verificado' }, se lanza
//   Exception('EMAIL_NO_VERIFICADO:<email>') con el prefijo especial para que
//   login_screen.dart pueda distinguirlo y mostrar el botón de reenvío.
//
// Todas las funciones lanzan Exception con el mensaje del servidor si hay error,
// o Exception('Error de conexión: ...') si hay problema de red.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

/// Clase estática de acceso a la API de autenticación.
/// Usada exclusivamente por ApiService, que actúa como fachada.
class AuthApi {
  /// POST /api/auth/register
  /// Registra un nuevo usuario. El backend envía un email de verificación.
  /// El usuario NO puede hacer login hasta verificar su email.
  /// Lanza Exception si el email ya existe (409) o datos inválidos (400).
  static Future<Map<String, dynamic>> register({
    required String nombre,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/auth/register'),
        headers: ApiClient.publicHeaders,
        body: jsonEncode({'nombre': nombre, 'email': email, 'password': password}),
      );
      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Error al registrar');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error de conexión: $e');
    }
  }

  /// POST /api/auth/login
  /// Autentica al usuario y guarda el JWT en SharedPreferences.
  /// Casos de error especiales:
  ///   - Email no verificado → lanza Exception('EMAIL_NO_VERIFICADO:<email>')
  ///     La pantalla de login detecta el prefijo y muestra el botón de reenvío.
  ///   - Credenciales incorrectas → 401 con error genérico
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/auth/login'),
        headers: ApiClient.publicHeaders,
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Guarda el JWT para peticiones futuras autenticadas
        await ApiClient.saveToken(data['access_token']);
        return data;
      }
      final error = jsonDecode(response.body);
      // Código especial: email existe pero no está verificado
      if (error['codigo'] == 'email_no_verificado') {
        throw Exception('EMAIL_NO_VERIFICADO:${error['email'] ?? email}');
      }
      throw Exception(error['error'] ?? 'Credenciales inválidas');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error de conexión: $e');
    }
  }

  /// GET /api/auth/me
  /// Obtiene los datos del usuario autenticado usando el JWT guardado.
  /// Se llama en AuthProvider._checkAuthStatus() al arrancar la app
  /// para validar si la sesión guardada sigue siendo válida.
  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final headers = await ApiClient.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/auth/me'),
        headers: headers,
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Error al obtener usuario');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Elimina el JWT de SharedPreferences (no llama al backend).
  /// El JWT del backend simplemente dejará de usarse y expirará en 7 días.
  static Future<void> logout() => ApiClient.removeToken();

  /// POST /api/auth/forgot-password
  /// Envía un email con enlace de recuperación de contraseña.
  /// El backend genera un token temporal (expira en 1 hora) y lo envía por email.
  static Future<void> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/auth/forgot-password'),
        headers: ApiClient.publicHeaders,
        body: jsonEncode({'email': email}),
      );
      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Error al enviar correo');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error de conexión: $e');
    }
  }

  /// POST /api/auth/resend-verification
  /// Reenvía el email de verificación al usuario que aún no ha verificado su cuenta.
  /// Se llama desde login_screen.dart cuando el usuario pulsa "Reenviar email".
  static Future<void> resendVerification(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/auth/resend-verification'),
        headers: ApiClient.publicHeaders,
        body: jsonEncode({'email': email}),
      );
      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Error al reenviar correo');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error de conexión: $e');
    }
  }
}
