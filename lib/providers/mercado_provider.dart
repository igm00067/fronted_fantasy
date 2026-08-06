// ─────────────────────────────────────────────────────────────────────────────
// providers/mercado_provider.dart — Estado global del mercado de fichajes
//
// Gestiona en un solo lugar los jugadores en subasta y el saldo disponible
// del usuario en una liga concreta. Se registra en main.dart.
//
// Flujo de uso en mercado_screen.dart:
//   1. Al entrar a la pantalla → provider.cargar(ligaId)
//   2. Ambas peticiones (mercado + saldo) se lanzan en paralelo con Future.wait
//   3. El usuario pulsa pujar → provider.pujar(mercadoId, cantidad)
//      → recarga automáticamente para reflejar la puja actualizada
//   4. Al salir de la liga o hacer logout → provider.limpiar()
//
// Nota: se guarda _ligaId para poder recargar sin que el widget lo repase.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import '../services/api/mercado_api.dart';
import '../services/api/ligas_api.dart';

/// Provider que combina jugadores en subasta y saldo disponible del usuario.
/// Se actualiza automáticamente después de cada puja exitosa (recargar).
class MercadoProvider with ChangeNotifier {
  List<Map<String, dynamic>> _jugadores = []; // lista de items activos en el mercado
  double _saldo = 0.0;    // saldo disponible del equipo del usuario en esta liga
  bool _isLoading = false;
  String? _error;
  int? _ligaId;           // liga activa; guardado para poder recargar sin parámetro

  List<Map<String, dynamic>> get jugadores => _jugadores;
  double get saldo => _saldo;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Carga en paralelo los jugadores del mercado y el saldo del usuario.
  /// GET /api/mercado/<ligaId>       → lista de items en subasta activos
  /// GET /api/ligas/<ligaId>/mi-equipo → campo equipo.saldo_disponible
  /// Usar Future.wait evita hacer las peticiones secuencialmente (ahorra tiempo).
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

  /// Recarga usando el mismo ligaId de la última llamada a cargar().
  /// Se llama automáticamente después de cada puja para actualizar la UI.
  Future<void> recargar() async {
    if (_ligaId != null) await cargar(_ligaId!);
  }

  /// Envía una puja al backend y recarga el mercado si tiene éxito.
  /// POST /api/mercado/<mercadoId>/pujar con body { 'cantidad': cantidad }
  /// Devuelve null si tuvo éxito, o el mensaje de error si falló.
  /// El backend valida que cantidad > puja_actual y cantidad <= saldo_disponible.
  Future<String?> pujar({required int mercadoId, required double cantidad}) async {
    try {
      await MercadoApi.realizarPuja(mercadoId: mercadoId, cantidad: cantidad);
      await recargar(); // actualiza saldo y lista tras la puja exitosa
      return null; // sin error
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  /// Limpia el estado al salir de la liga o hacer logout.
  /// Impide que al entrar a otra liga se muestren datos de la anterior.
  void limpiar() {
    _jugadores = [];
    _saldo = 0.0;
    _error = null;
    _ligaId = null;
    notifyListeners();
  }
}
