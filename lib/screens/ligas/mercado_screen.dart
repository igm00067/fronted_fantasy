// ─────────────────────────────────────────────────────────────────────────────
// screens/ligas/mercado_screen.dart — Mercado de subastas de jugadores
//
// Muestra la lista de jugadores en subasta activa en la liga.
// Cada item incluye: jugador, puja actual, mejor postor y tiempo restante.
//
// Sistema de timers doble:
//   _pollTimer (5s):       sincroniza datos con el servidor
//                          → actualiza puja_actual, mejor_postor, tiempo real
//   _countdownTimer (1s):  decrementa el tiempo restante localmente cada segundo
//                          sin llamar al servidor, para dar sensación fluida
//
// El saldo disponible del usuario se muestra en la cabecera y se actualiza
// automáticamente tras cada puja exitosa.
//
// Al tocar un jugador → JugadorDetallesSheet (bottom sheet con stats del jugador)
// Al tocar "Pujar"   → _mostrarDialogoPuja() → bottom sheet con slider y chips rápidos
//                        (implementado con StatefulBuilder + showModalBottomSheet)
//
// FAB de búsqueda (desde DetalleLigaScreen): navega a BuscarJugadoresScreen
// para buscar jugadores del catálogo y verlos desde esta misma sección.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import '../../services/api/mercado_api.dart';
import '../../services/api/ligas_api.dart';
import '../../config/app_theme.dart';
import '../../widgets/jugador_detalles_sheet.dart';
import 'buscar_jugadores_screen.dart';
import 'dart:async';

class MercadoScreen extends StatefulWidget {
  final int ligaId;
  final int competicionId;

  const MercadoScreen({
    Key? key,
    required this.ligaId,
    required this.competicionId,
  }) : super(key: key);

  @override
  State<MercadoScreen> createState() => _MercadoScreenState();
}

class _MercadoScreenState extends State<MercadoScreen> {
  List<dynamic> _jugadoresMercado = []; // items activos devueltos por GET /api/mercado/<id>
  double? _saldoDisponible;              // saldo del usuario en esta liga
  bool _cargando = true;
  String? _error;
  Timer? _pollTimer;       // timer de 5s para sincronizar con el servidor
  Timer? _countdownTimer;  // timer de 1s para decrementar _tiemposLocales fluidamente
  // Mapa id_mercado → segundos_restantes calculado desde fecha_cierre del servidor.
  // Se actualiza en cada poll y se decrementa localmente entre polls.
  final Map<int, int> _tiemposLocales = {};

  @override
  void initState() {
    super.initState();
    _cargarMercado();
    // Sincronizar datos con el servidor cada 5 segundos
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _cargarMercado();
    });
    // Decrementar countdown localmente cada segundo sin llamar al servidor
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        for (final id in _tiemposLocales.keys.toList()) {
          if (_tiemposLocales[id]! > 0) _tiemposLocales[id] = _tiemposLocales[id]! - 1;
        }
      });
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _cargarMercado() async {
    try {
      final results = await Future.wait([
        MercadoApi.getMercado(widget.ligaId),
        LigasApi.getSaldoDisponible(widget.ligaId),
      ]);
      if (mounted) {
        final lista = results[0] as List<dynamic>;
        // Sincronizar tiempos locales con los del servidor
        for (final item in lista) {
          final id = item['id'] as int;
          final segundos = item['tiempo_restante_segundos'] as int? ?? 0;
          _tiemposLocales[id] = segundos;
        }
        setState(() {
          _jugadoresMercado = lista;
          _saldoDisponible = results[1] as double;
          _cargando = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _cargando = false;
        });
      }
    }
  }

  Color _getColorPosicion(String posicion) {
    switch (posicion) {
      case 'POR':
        return Colors.amber;
      case 'DEF':
        return Colors.blue;
      case 'MED':
        return Colors.green;
      case 'DEL':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatearTiempo(int segundos) {
    if (segundos <= 0) return 'FINALIZADO';
    final minutos = segundos ~/ 60;
    final segs = segundos % 60;
    return '${minutos}:${segs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _cargarMercado,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppTheme.surfaceVariantColor,
            child: Row(
              children: [
                const Icon(Icons.store, color: AppTheme.secondaryColor),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Mercado de Fichajes',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                if (_saldoDisponible != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.secondaryColor.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.account_balance_wallet,
                            size: 14, color: AppTheme.secondaryColor),
                        const SizedBox(width: 5),
                        Text(
                          '${_saldoDisponible!.toStringAsFixed(1)}M',
                          style: const TextStyle(
                            color: AppTheme.secondaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _cargarMercado,
                ),
              ],
            ),
          ),

          // Contenido
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 60, color: Colors.red[300]),
                            const SizedBox(height: 16),
                            Text(
                              'Error al cargar mercado',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _error!.replaceAll('Exception: ', ''),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppTheme.textSecondaryColor),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _cargarMercado,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : _jugadoresMercado.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_cart_outlined,
                                    size: 80, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('No hay jugadores en el mercado'),
                                SizedBox(height: 8),
                                Text(
                                  'Espera a que se generen nuevos jugadores',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _jugadoresMercado.length,
                            itemBuilder: (context, index) {
                              final item = _jugadoresMercado[index];
                              return _buildJugadorCard(item);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildJugadorCard(Map<String, dynamic> item) {
    final jugador = item['jugador'];
    final mercado = item;
    final id = item['id'] as int;
    final tiempoRestante = _tiemposLocales[id] ?? 0;
    final mejorPostor = mercado['mejor_postor'];
    final precioActual = mercado['precio_actual'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      child: Column(
        children: [
          // Header con tiempo restante
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: tiempoRestante > 0
              ? AppTheme.secondaryColor.withOpacity(0.15)
              : AppTheme.surfaceVariantColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.timer,
                      size: 16,
                      color: tiempoRestante > 0
                          ? AppTheme.secondaryColor
                          : AppTheme.textSecondaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatearTiempo(tiempoRestante),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: tiempoRestante > 0
                            ? AppTheme.secondaryColor
                            : AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
                if (mejorPostor != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Mejor postor: ${mejorPostor['equipo_nombre']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Información del jugador
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: _getColorPosicion(jugador['posicion']),
              radius: 30,
              child: Text(
                jugador['posicion'],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              jugador['nombre'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('${mercado['equipo_real_nombre']}'),
                Text('${jugador['nacionalidad']} • ${jugador['edad']} años'),
                Text('Media FIFA: ${jugador['media_fifa']}'),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${precioActual}M',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: AppTheme.secondaryColor,
                  ),
                ),
                const Text(
                  'precio actual',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),

          // Botones
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _mostrarDetallesJugador(jugador),
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text('Detalles'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: tiempoRestante > 0
                        ? () => _mostrarDialogoPuja(mercado, jugador)
                        : null,
                    icon: const Icon(Icons.gavel, size: 18),
                    label: const Text('Pujar'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDetallesJugador(Map<String, dynamic> jugador) {
    mostrarDetallesJugador(context, jugador);
  }

  void _mostrarDialogoPuja(Map<String, dynamic> mercado, Map<String, dynamic> jugador) {
    final precioActual = double.parse(mercado['precio_actual'].toString());
    final precioMinimo = precioActual + 0.5;
    double puja = precioMinimo;
    final posicion = jugador['posicion'] as String? ?? '';
    final colorPos = _getColorPosicion(posicion);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setStateLocal) {
          final pujaValida = puja > precioActual;
          final saldoSuficiente = _saldoDisponible == null || puja <= _saldoDisponible!;

          return Container(
            decoration: const BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, MediaQuery.of(sheetCtx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Player header
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: colorPos,
                      radius: 22,
                      child: Text(posicion,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            jugador['nombre'] ?? '',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 17),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${mercado['equipo_real_nombre'] ?? ''} · Media ${jugador['media_fifa'] ?? ''}',
                            style: const TextStyle(
                                color: AppTheme.textSecondaryColor, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (_saldoDisponible != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppTheme.secondaryColor.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.account_balance_wallet,
                                size: 12, color: AppTheme.secondaryColor),
                            const SizedBox(width: 4),
                            Text(
                              '${_saldoDisponible!.toStringAsFixed(1)}M',
                              style: const TextStyle(
                                  color: AppTheme.secondaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                // Current price row
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariantColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Precio actual',
                          style: TextStyle(
                              color: AppTheme.textSecondaryColor, fontSize: 13)),
                      Text(
                        '${precioActual.toStringAsFixed(1)}M',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Amount selector
                const Text('Tu puja',
                    style: TextStyle(
                        color: AppTheme.textSecondaryColor, fontSize: 13)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildBidButton(
                      icon: Icons.remove,
                      onPressed: puja > precioMinimo
                          ? () => setStateLocal(() =>
                              puja = (puja - 0.5)
                                  .clamp(precioMinimo, double.infinity))
                          : null,
                    ),
                    const SizedBox(width: 24),
                    Column(
                      children: [
                        Text(
                          '${puja.toStringAsFixed(1)}M',
                          style: TextStyle(
                            color: pujaValida && saldoSuficiente
                                ? AppTheme.secondaryColor
                                : Colors.red[300],
                            fontWeight: FontWeight.bold,
                            fontSize: 34,
                          ),
                        ),
                        Text(
                          !saldoSuficiente
                              ? 'Saldo insuficiente'
                              : '+${(puja - precioActual).toStringAsFixed(1)}M sobre el precio',
                          style: TextStyle(
                            color: saldoSuficiente
                                ? AppTheme.textSecondaryColor
                                : Colors.red[300],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),
                    _buildBidButton(
                      icon: Icons.add,
                      onPressed: () =>
                          setStateLocal(() => puja = puja + 0.5),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Quick increments
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildQuickChip(
                        '+1M', () => setStateLocal(() => puja += 1.0)),
                    const SizedBox(width: 8),
                    _buildQuickChip(
                        '+5M', () => setStateLocal(() => puja += 5.0)),
                    const SizedBox(width: 8),
                    _buildQuickChip(
                        '+10M', () => setStateLocal(() => puja += 10.0)),
                  ],
                ),
                const SizedBox(height: 20),
                // Confirm row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetCtx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textSecondaryColor,
                          side: const BorderSide(color: AppTheme.borderColor),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: pujaValida && saldoSuficiente
                            ? () async {
                                Navigator.pop(sheetCtx);
                                await _realizarPuja(
                                    mercado['id'], puja, jugador['nombre']);
                              }
                            : null,
                        icon: const Icon(Icons.gavel, size: 18),
                        label: Text('Pujar ${puja.toStringAsFixed(1)}M'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondaryColor,
                          foregroundColor: Colors.black,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBidButton(
      {required IconData icon, VoidCallback? onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: onPressed != null
              ? AppTheme.primaryColor
              : AppTheme.surfaceVariantColor,
          border: Border.all(
            color: onPressed != null
                ? AppTheme.secondaryColor.withOpacity(0.5)
                : AppTheme.borderColor,
          ),
        ),
        child: Icon(icon,
            color: onPressed != null
                ? AppTheme.secondaryColor
                : AppTheme.textSecondaryColor),
      ),
    );
  }

  Widget _buildQuickChip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: AppTheme.secondaryColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: AppTheme.secondaryColor.withOpacity(0.35)),
        ),
        child: Text(
          label,
          style: const TextStyle(
              color: AppTheme.secondaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 13),
        ),
      ),
    );
  }

  Future<void> _realizarPuja(int mercadoId, double cantidad, String nombreJugador) async {
    try {
      await MercadoApi.realizarPuja(mercadoId: mercadoId, cantidad: cantidad);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Puja realizada por $nombreJugador! (${cantidad}M)'),
            backgroundColor: Colors.green,
          ),
        );
        _cargarMercado();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}