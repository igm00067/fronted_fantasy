import 'package:flutter/material.dart';
import '../services/api/mercado_api.dart';
import '../services/api/ligas_api.dart';

class MercadoProvider with ChangeNotifier {
  List<Map<String, dynamic>> _jugadores = [];
  double _saldo = 0.0;
  bool _isLoading = false;
  String? _error;
  int? _ligaId;

  List<Map<String, dynamic>> get jugadores => _jugadores;
  double get saldo => _saldo;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> cargar(int ligaId) async {
    _ligaId = ligaId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        MercadoApi.getMercado(ligaId),
        LigasApi.getSaldoDisponible(ligaId),
      ]);
      _jugadores = (results[0] as List).cast<Map<String, dynamic>>();
      _saldo = results[1] as double;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> recargar() async {
    if (_ligaId != null) await cargar(_ligaId!);
  }

  Future<String?> pujar({required int mercadoId, required double cantidad}) async {
    try {
      await MercadoApi.realizarPuja(mercadoId: mercadoId, cantidad: cantidad);
      await recargar();
      return null; // sin error
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  void limpiar() {
    _jugadores = [];
    _saldo = 0.0;
    _error = null;
    _ligaId = null;
    notifyListeners();
  }
}
