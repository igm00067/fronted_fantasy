import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'ver_equipo_usuario_screen.dart';


class ClasificacionLigaScreen extends StatefulWidget {
  final int ligaId;

  const ClasificacionLigaScreen({Key? key, required this.ligaId}) : super(key: key);

  @override
  State<ClasificacionLigaScreen> createState() => _ClasificacionLigaScreenState();
}

class _ClasificacionLigaScreenState extends State<ClasificacionLigaScreen> {
  List<dynamic> _clasificacion = [];
  Map<String, dynamic>? _liga;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarClasificacion();
  }

  Future<void> _cargarClasificacion() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final data = await ApiService.getClasificacion(widget.ligaId);
      setState(() {
        _liga = data['liga'];
        _clasificacion = data['clasificacion'];
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _cargarClasificacion,
      child: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar clasificación',
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
                        onPressed: _cargarClasificacion,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _clasificacion.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.emoji_events,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay participantes',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Invita a tus amigos a unirse',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Header con información de la liga
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _liga?['nombre'] ?? '',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  Text(
                                    '${_clasificacion.length} participantes',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: _cargarClasificacion,
                              ),
                            ],
                          ),
                        ),

                        // Tabla de clasificación
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: _buildTablaHeader(),
                        ),

                        Expanded(
                          child: ListView.builder(
                            itemCount: _clasificacion.length,
                            itemBuilder: (context, index) {
                              final participante = _clasificacion[index];
                              return _buildFilaClasificacion(participante);
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildTablaHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const SizedBox(width: 40, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
          const Expanded(
            flex: 3,
            child: Text('Equipo', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 40, child: Text('PJ', style: TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(width: 40, child: Text('PTS', style: TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(width: 50, child: Text('DIF', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildFilaClasificacion(Map<String, dynamic> participante) {
    final posicion = participante['posicion'];
    final color = _getColorPosicion(posicion);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: posicion <= 3 ? 4 : 1,
      child: InkWell(
        onTap: () => _mostrarDetalles(participante),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            border: posicion <= 3
                ? Border(
                    left: BorderSide(
                      color: color,
                      width: 4,
                    ),
                  )
                : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Posición
              SizedBox(
                width: 40,
                child: CircleAvatar(
                  backgroundColor: color,
                  radius: 16,
                  child: Text(
                    '$posicion',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              // Nombre del equipo y usuario
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      participante['equipo_nombre'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      participante['usuario_nombre'],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Partidos jugados
              SizedBox(
                width: 40,
                child: Text(
                  '${participante['partidos_jugados']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),

              // Puntos
              SizedBox(
                width: 40,
                child: Text(
                  '${participante['puntos']}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Diferencia de goles
              SizedBox(
                width: 50,
                child: Text(
                  '${participante['diferencia_goles'] > 0 ? '+' : ''}${participante['diferencia_goles']}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: participante['diferencia_goles'] > 0
                        ? Colors.green
                        : participante['diferencia_goles'] < 0
                            ? Colors.red
                            : Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColorPosicion(int posicion) {
    switch (posicion) {
      case 1:
        return Colors.amber; // Oro
      case 2:
        return Colors.grey; // Plata
      case 3:
        return Colors.brown; // Bronce
      default:
        return Colors.blue;
    }
  }

  void _mostrarDetalles(Map<String, dynamic> participante) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(participante['equipo_nombre']),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Jugador', participante['usuario_nombre']),
          _buildInfoRow('Posición', '#${participante['posicion']}'),
          const Divider(),
          _buildInfoRow('Partidos jugados', '${participante['partidos_jugados']}'),
          _buildInfoRow('Victorias', '${participante['partidos_ganados']}'),
          _buildInfoRow('Empates', '${participante['partidos_empatados']}'),
          _buildInfoRow('Derrotas', '${participante['partidos_perdidos']}'),
          const Divider(),
          _buildInfoRow('Puntos', '${participante['puntos']}'),
          _buildInfoRow('Goles a favor', '${participante['goles_favor']}'),
          _buildInfoRow('Goles en contra', '${participante['goles_contra']}'),
          _buildInfoRow(
            'Diferencia',
            '${participante['diferencia_goles'] > 0 ? '+' : ''}${participante['diferencia_goles']}',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VerEquipoUsuarioScreen(
                  ligaId: widget.ligaId,
                  usuarioId: participante['usuario_id'],
                  nombreUsuario: participante['usuario_nombre'],
                  nombreEquipo: participante['equipo_nombre'],
                ),
              ),
            );
          },
          icon: const Icon(Icons.visibility),
          label: const Text('Ver equipo'),
        ),
      ],
    ),
  );
}

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }
}