import 'package:flutter/material.dart';
import '../../services/api_service.dart';
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
  List<dynamic> _jugadoresMercado = [];
  double? _saldoDisponible;
  bool _cargando = true;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _cargarMercado();
    // Actualizar cada 5 segundos
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _cargarMercado();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _cargarMercado() async {
    try {
      final results = await Future.wait([
        ApiService.getMercado(widget.ligaId),
        ApiService.getSaldoDisponible(widget.ligaId),
      ]);
      if (mounted) {
        setState(() {
          _jugadoresMercado = results[0] as List<dynamic>;
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
    final tiempoRestante = mercado['tiempo_restante_segundos'] ?? 0;
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
    final controller = TextEditingController(text: precioMinimo.toStringAsFixed(1));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pujar por ${jugador['nombre']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Precio actual: ${precioActual}M'),
                if (_saldoDisponible != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.secondaryColor.withOpacity(0.5)),
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
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'La puja mínima es +0.5M sobre el precio actual',
              style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Cantidad (M)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final cantidad = double.tryParse(controller.text);
              if (cantidad == null || cantidad <= precioActual) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('La puja debe ser mayor a ${precioActual}M'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);
              await _realizarPuja(mercado['id'], cantidad, jugador['nombre']);
            },
            child: const Text('Confirmar Puja'),
          ),
        ],
      ),
    );
  }

  Future<void> _realizarPuja(int mercadoId, double cantidad, String nombreJugador) async {
    try {
      await ApiService.realizarPuja(
        mercadoId: mercadoId,
        cantidad: cantidad,
      );

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