// ─────────────────────────────────────────────────────────────────────────────
// providers/ligas_provider.dart — Estado global de la lista de ligas del usuario
//
// Gestiona la carga y el estado de las ligas en las que participa el usuario.
// Usado principalmente en mis_ligas_screen.dart para mostrar la lista inicial.
//
// Patrón: ChangeNotifier + Provider (como AuthProvider)
// Se registra en main.dart y se puede acceder desde cualquier widget.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import '../models/liga.dart';
import '../services/api/ligas_api.dart';

class LigasProvider with ChangeNotifier {
  List<Liga> _ligas = [];
  bool _isLoading = false;
  String? _error;

  List<Liga> get ligas    => _ligas;
  bool get isLoading      => _isLoading;
  String? get error       => _error;

  /// Carga las ligas del usuario desde GET /api/ligas/mis-ligas.
  /// Convierte la respuesta JSON cruda a List<Liga> usando Liga.fromJson().
  Future<void> cargarMisLigas() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final raw = await LigasApi.getMisLigas();
      _ligas = raw
          .cast<Map<String, dynamic>>()
          .map((json) => Liga.fromJson(json))
          .toList();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Limpia el estado (útil al hacer logout para no mostrar datos del usuario anterior).
  void limpiar() {
    _ligas = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
