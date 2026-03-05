import 'package:flutter/material.dart';
import '../../services/api_service.dart';
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
      final mercado = await ApiService.getMercado(widget.ligaId);
      if (mounted) {
        setState(() {
          _jugadoresMercado = mercado;
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
            padding: const EdgeInsets.all(16),
            color: Colors.orange[50],
            child: Row(
              children: [
                Icon(Icons.store, color: Colors.orange[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mercado de Fichajes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Puja por los jugadores disponibles',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
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
                              style: TextStyle(color: Colors.grey[600]),
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
              color: tiempoRestante > 0 ? Colors.orange[100] : Colors.grey[300],
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
                      color: tiempoRestante > 0 ? Colors.orange[900] : Colors.grey[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatearTiempo(tiempoRestante),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: tiempoRestante > 0 ? Colors.orange[900] : Colors.grey[700],
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
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.green[700],
                  ),
                ),
                Text(
                  'Base: ${mercado['precio_base']}M',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(jugador['nombre']),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Posición: ${jugador['posicion']}'),
              Text('Nacionalidad: ${jugador['nacionalidad']}'),
              Text('Edad: ${jugador['edad']} años'),
              Text('Precio: ${jugador['precio']}M'),
              const Divider(),
              const Text(
                'Estadísticas FIFA:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Velocidad: ${jugador['velocidad']}'),
              Text('Tiro: ${jugador['tiro']}'),
              Text('Pase: ${jugador['pase']}'),
              Text('Regate: ${jugador['regate']}'),
              Text('Defensa: ${jugador['defensa']}'),
              Text('Físico: ${jugador['fisico']}'),
              Text(
                'Media: ${jugador['media_fifa']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
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
            Text('Precio actual: ${precioActual}M'),
            const SizedBox(height: 8),
            Text(
              'Tu puja debe ser mayor a ${precioActual}M',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
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