import 'package:flutter/material.dart';
import '../services/api_service.dart';

class JugadoresScreen extends StatefulWidget {
  const JugadoresScreen({Key? key}) : super(key: key);

  @override
  State<JugadoresScreen> createState() => _JugadoresScreenState();
}

class _JugadoresScreenState extends State<JugadoresScreen> {
  List<dynamic> _jugadores = [];
  List<dynamic> _competiciones = [];
  List<dynamic> _equipos = [];
  bool _cargando = true;
  int? _competicionSeleccionada;
  int? _equipoSeleccionado;
  String? _posicionSeleccionada;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final competiciones = await ApiService.getCompeticiones();
      setState(() {
        _competiciones = competiciones;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      _mostrarError('Error: $e');
    }
  }

  Future<void> _cargarEquipos(int competicionId) async {
    try {
      final equipos = await ApiService.getEquipos(competicionId: competicionId);
      setState(() {
        _equipos = equipos;
        _equipoSeleccionado = null;
      });
    } catch (e) {
      _mostrarError('Error al cargar equipos: $e');
    }
  }

  Future<void> _cargarJugadores() async {
    setState(() => _cargando = true);
    try {
      final jugadores = await ApiService.getJugadores(
        equipoId: _equipoSeleccionado,
        posicion: _posicionSeleccionada,
      );
      setState(() {
        _jugadores = jugadores;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      _mostrarError('Error: $e');
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jugadores'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarJugadores,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                // Selector de competición
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Competición',
                    border: OutlineInputBorder(),
                  ),
                  value: _competicionSeleccionada,
                  items: _competiciones.map((comp) {
                    return DropdownMenuItem<int>(
                      value: comp['id'],
                      child: Text(comp['nombre']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _competicionSeleccionada = value;
                      _equipos = [];
                      _equipoSeleccionado = null;
                    });
                    if (value != null) {
                      _cargarEquipos(value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                
                // Selector de equipo
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Equipo',
                    border: OutlineInputBorder(),
                  ),
                  value: _equipoSeleccionado,
                  items: _equipos.map((equipo) {
                    return DropdownMenuItem<int>(
                      value: equipo['id'],
                      child: Text(equipo['nombre']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _equipoSeleccionado = value);
                    _cargarJugadores();
                  },
                ),
                const SizedBox(height: 12),
                
                // Selector de posición
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Posición',
                    border: OutlineInputBorder(),
                  ),
                  value: _posicionSeleccionada,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Todas')),
                    DropdownMenuItem(value: 'POR', child: Text('Portero')),
                    DropdownMenuItem(value: 'DEF', child: Text('Defensa')),
                    DropdownMenuItem(value: 'MED', child: Text('Centrocampista')),
                    DropdownMenuItem(value: 'DEL', child: Text('Delantero')),
                  ],
                  onChanged: (value) {
                    setState(() => _posicionSeleccionada = value);
                    if (_equipoSeleccionado != null) {
                      _cargarJugadores();
                    }
                  },
                ),
              ],
            ),
          ),
          
          // Lista de jugadores
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _jugadores.isEmpty
                    ? const Center(child: Text('Selecciona un equipo para ver jugadores'))
                    : ListView.builder(
                        itemCount: _jugadores.length,
                        itemBuilder: (context, index) {
                          final jugador = _jugadores[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getColorPosicion(jugador['posicion']),
                                child: Text(
                                  jugador['posicion'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              title: Text(
                                jugador['nombre'],
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${jugador['nacionalidad']} • ${jugador['edad']} años'),
                                  Text('Media FIFA: ${jugador['media_fifa']}'),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${jugador['precio']}M',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.green,
                                    ),
                                  ),
                                  Text(
                                    'VEL ${jugador['velocidad']}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () => _mostrarDetallesJugador(jugador),
                            ),
                          );
                        },
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Posición: ${jugador['posicion']}'),
            Text('Nacionalidad: ${jugador['nacionalidad']}'),
            Text('Edad: ${jugador['edad']} años'),
            Text('Precio: ${jugador['precio']}M'),
            const Divider(),
            const Text('Estadísticas FIFA:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Velocidad: ${jugador['velocidad']}'),
            Text('Tiro: ${jugador['tiro']}'),
            Text('Pase: ${jugador['pase']}'),
            Text('Regate: ${jugador['regate']}'),
            Text('Defensa: ${jugador['defensa']}'),
            Text('Físico: ${jugador['fisico']}'),
            Text('Media: ${jugador['media_fifa']}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
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
}