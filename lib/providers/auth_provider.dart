import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  Map<String, dynamic>? _usuario;
  bool _isAuthenticated = false;
  bool _isLoading = true;

  Map<String, dynamic>? get usuario => _usuario;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final token = await ApiService.getToken();
      if (token != null) {
        final userData = await ApiService.getCurrentUser();
        _usuario = userData;
        _isAuthenticated = true;
      }
    } catch (e) {
      _isAuthenticated = false;
      _usuario = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String nombre,
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiService.register(
        nombre: nombre,
        email: email,
        password: password,
      );
      _usuario = response['usuario'];
      _isAuthenticated = true;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

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
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await ApiService.logout();
    _usuario = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}