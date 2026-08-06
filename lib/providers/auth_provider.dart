// ─────────────────────────────────────────────────────────────────────────────
// providers/auth_provider.dart — Estado global de autenticación
//
// Usa el patrón Provider (ChangeNotifier) para que toda la app acceda al
// estado de sesión sin pasar el usuario por parámetros entre pantallas.
//
// Se registra en main.dart con MultiProvider y es accesible desde cualquier
// widget con: Provider.of<AuthProvider>(context) o context.watch<AuthProvider>()
//
// Estados posibles:
//   isLoading=true            → verificando sesión al arrancar la app
//   isAuthenticated=false     → no hay sesión o token expirado
//   isAuthenticated=true      → usuario logueado con datos en _usuario
//
// Flujo de autenticación:
//   1. Al crear AuthProvider (en main), se llama _checkAuthStatus()
//   2. Si hay JWT guardado en SharedPreferences, verifica si sigue válido
//      llamando a GET /api/auth/me
//   3. Si el token expiró o no hay → isAuthenticated=false → pantalla de login
//   4. El usuario hace login → POST /api/auth/login → guarda JWT → isAuthenticated=true
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  Map<String, dynamic>? _usuario;     // datos del usuario autenticado (from GET /api/auth/me)
  bool _isAuthenticated = false;
  bool _isLoading = true;             // true mientras verifica la sesión al arrancar

  Map<String, dynamic>? get usuario       => _usuario;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading       => _isLoading;

  AuthProvider() {
    // Al crear el Provider (al arrancar la app), verificar si hay sesión guardada
    _checkAuthStatus();
  }

  /// Verifica si el JWT guardado en SharedPreferences sigue siendo válido.
  /// Llama a GET /api/auth/me con el token; si falla (401/403) limpia la sesión.
  Future<void> _checkAuthStatus() async {
    try {
      final token = await ApiService.getToken();
      if (token != null) {
        // Valida el token haciendo una petición autenticada al backend
        final userData = await ApiService.getCurrentUser();
        _usuario = userData;
        _isAuthenticated = true;
      }
    } catch (e) {
      // Token expirado, inválido o sin conexión → no autenticado
      _isAuthenticated = false;
      _usuario = null;
    } finally {
      _isLoading = false;
      notifyListeners(); // notifica a main.dart para redirigir a login o home
    }
  }

  /// Registra un nuevo usuario. NO hace login automático.
  /// El usuario debe verificar su email antes de poder entrar.
  /// Lanza excepción si el email ya existe o hay error de red.
  Future<void> register({
    required String nombre,
    required String email,
    required String password,
  }) async {
    try {
      await ApiService.register(
        nombre: nombre,
        email: email,
        password: password,
      );
      // El usuario debe verificar su email antes de poder acceder
    } catch (e) {
      rethrow;
    }
  }

  /// Autentica al usuario y guarda el JWT.
  /// Lanza excepción con el mensaje del servidor si las credenciales son incorrectas
  /// o si el email no está verificado (código 'email_no_verificado').
  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiService.login(
        email: email,
        password: password,
      );
      _usuario = response['usuario'];
      _isAuthenticated = true;
      notifyListeners(); // notifica a todos los widgets que observan este provider
    } catch (e) {
      rethrow;
    }
  }

  /// Cierra la sesión: elimina el JWT y limpia el estado.
  Future<void> logout() async {
    await ApiService.logout();
    _usuario = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}