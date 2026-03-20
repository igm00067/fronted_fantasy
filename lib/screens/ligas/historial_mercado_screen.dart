import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../config/app_theme.dart';
import 'package:timeago/timeago.dart' as timeago;

class HistorialMercadoScreen extends StatefulWidget {
  final int ligaId;

  const HistorialMercadoScreen({Key? key, required this.ligaId}) : super(key: key);

  @override
  State<HistorialMercadoScreen> createState() => _HistorialMercadoScreenState();
}

class _HistorialMercadoScreenState extends State<HistorialMercadoScreen> {
  List<dynamic> _transacciones = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('es', timeago.EsMessages());
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final historial = await ApiService.getHistorialMercado(widget.ligaId);
      setState(() {
        _transacciones = historial;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  Color _getColorPosicion(String posicion) {
    switch (posicion) {
      case 'POR': return const Color(0xFFE69B00);
      case 'DEF': return const Color(0xFF1565C0);
      case 'MED': return const Color(0xFF2E7D32);
      case 'DEL': return const Color(0xFFC62828);
      default:    return Colors.grey;
    }
  }

  IconData _getIconoTipo(String tipo) {
    switch (tipo) {
      case 'FICHAJE_MERCADO':  return Icons.shopping_cart;
      case 'VENTA':            return Icons.sell;
      case 'FICHAJE_INICIAL':  return Icons.card_giftcard;
      default:                 return Icons.swap_horiz;
    }
  }

  Color _getColorTipo(String tipo) {
    switch (tipo) {
      case 'FICHAJE_MERCADO': return const Color(0xFF2E7D32);
      case 'VENTA':           return const Color(0xFFE65100);
      case 'FICHAJE_INICIAL': return const Color(0xFF1565C0);
      default:                return Colors.grey;
    }
  }

  String _getTituloTipo(String tipo) {
    switch (tipo) {
      case 'FICHAJE_MERCADO': return 'Fichaje';
      case 'VENTA':           return 'Venta';
      case 'FICHAJE_INICIAL': return 'Fichaje Inicial';
      default:                return 'Transacción';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Fichajes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarHistorial,
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
                      const SizedBox(height: 16),
                      Text('Error al cargar historial',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _error!.replaceAll('Exception: ', ''),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.textSecondaryColor),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _cargarHistorial,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _transacciones.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.history, size: 80,
                              color: AppTheme.textSecondaryColor),
                          const SizedBox(height: 16),
                          const Text('No hay fichajes todavía',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text(
                            'Los fichajes aparecerán aquí cuando\nalguien gane una subasta',
                            style: TextStyle(color: AppTheme.textSecondaryColor),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _cargarHistorial,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _transacciones.length,
                        itemBuilder: (context, index) =>
                            _buildTransaccionCard(_transacciones[index]),
                      ),
                    ),
    );
  }

  Widget _buildTransaccionCard(Map<String, dynamic> transaccion) {
    final tipo = transaccion['tipo'] as String;
    final colorTipo = _getColorTipo(tipo);
    final fecha = DateTime.parse(transaccion['created_at']);
    final tiempoAtras = timeago.format(fecha, locale: 'es');
    final posicion = transaccion['jugador_posicion'] as String;
    final colorPos = _getColorPosicion(posicion);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorTipo.withOpacity(0.12),
              AppTheme.surfaceColor,
            ],
          ),
          border: Border.all(color: colorTipo.withOpacity(0.3), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Cabecera: badge tipo + tiempo ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorTipo,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: colorTipo.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getIconoTipo(tipo), color: Colors.white, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          _getTituloTipo(tipo),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariantColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 12, color: AppTheme.textSecondaryColor),
                        const SizedBox(width: 4),
                        Text(
                          tiempoAtras,
                          style: const TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Equipo ──
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorTipo.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.shield, color: colorTipo, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaccion['equipo_nombre'],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          transaccion['usuario_nombre'],
                          style: const TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Divisor ──
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.transparent,
                    AppTheme.borderColor,
                    Colors.transparent,
                  ]),
                ),
              ),

              const SizedBox(height: 12),

              // ── Jugador + precio ──
              Row(
                children: [
                  // Avatar posición
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [colorPos, colorPos.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: colorPos.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        posicion,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Nombre + nacionalidad
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaccion['jugador_nombre'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.flag,
                                size: 12, color: AppTheme.textSecondaryColor),
                            const SizedBox(width: 4),
                            Text(
                              transaccion['jugador_nacionalidad'],
                              style: const TextStyle(
                                color: AppTheme.textSecondaryColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Precio
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.secondaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      '${transaccion['precio']}M',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
