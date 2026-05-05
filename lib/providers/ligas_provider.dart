import 'package:flutter/material.dart';
import '../models/liga.dart';
import '../services/api/ligas_api.dart';

class LigasProvider with ChangeNotifier {
  List<Liga> _ligas = [];
  bool _isLoading = false;
  String? _error;

  List<Liga> get ligas => _ligas;
  bool get isLoading => _isLoading;
  String? get error => _error;

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

  void limpiar() {
    _ligas = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
