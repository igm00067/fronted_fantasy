import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MiEquipoScreen extends StatefulWidget {
  final int ligaId;

  const MiEquipoScreen({Key? key, required this.ligaId}) : super(key: key);

  @override
  State<MiEquipoScreen> createState() => _MiEquipoScreenState();
}

class _MiEquipoScreenState extends State<MiEquipoScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _formacionSeleccionada = '4-3-3';
  
  List<Map<String, dynamic>> _plantilla = [];
  bool _cargando = true;
  Map<String, dynamic> _alineacion = {
    'POR': null,
    'DEF1': null,
    'DEF2': null,
    'DEF3': null,
    'DEF4': null,
    'MED1': null,
    'MED2': null,
    'MED3': null,
    'DEL1': null,
    'DEL2': null,
    'DEL3': null,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarEquipo();  // ← Cargar jugadores del backend
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarEquipo() async {
  setState(() => _cargando = true);
  
  try {
    final authHeaders = await ApiService.getAuthHeaders();
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/ligas/${widget.ligaId}/mi-equipo'),
      headers: authHeaders,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _plantilla = List<Map<String, dynamic>>.from(data['plantilla']);
        
        // Cargar alineación guardada si existe
        if (data['equipo']['formacion'] != null) {
          _formacionSeleccionada = data['equipo']['formacion'];
        }
        
        // Cargar jugadores titulares
        if (data['titulares'] != null) {
          final titulares = List<Map<String, dynamic>>.from(data['titulares']);
          for (var titular in titulares) {
            final jugador = _plantilla.firstWhere(
              (j) => j['id'] == titular['jugador_id'],
              orElse: () => {},
            );
            if (jugador.isNotEmpty) {
              _alineacion[titular['posicion_en_campo']] = jugador;
            }
          }
        }
        
        _cargando = false;
      });
    } else {
      throw Exception('Error al cargar equipo');
    }
  } catch (e) {
    setState(() => _cargando = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

  List<String> get _posicionesActivas {
    switch (_formacionSeleccionada) {
      case '4-4-2':
        return ['POR', 'DEF1', 'DEF2', 'DEF3', 'DEF4', 'MED1', 'MED2', 'MED3', 'MED4', 'DEL1', 'DEL2'];
      case '4-3-3':
        return ['POR', 'DEF1', 'DEF2', 'DEF3', 'DEF4', 'MED1', 'MED2', 'MED3', 'DEL1', 'DEL2', 'DEL3'];
      case '3-5-2':
        return ['POR', 'DEF1', 'DEF2', 'DEF3', 'MED1', 'MED2', 'MED3', 'MED4', 'MED5', 'DEL1', 'DEL2'];
      case '5-3-2':
        return ['POR', 'DEF1', 'DEF2', 'DEF3', 'DEF4', 'DEF5', 'MED1', 'MED2', 'MED3', 'DEL1', 'DEL2'];
      default:
        return ['POR', 'DEF1', 'DEF2', 'DEF3', 'DEF4', 'MED1', 'MED2', 'MED3', 'DEL1', 'DEL2', 'DEL3'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.grey[200],
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.black,
            indicatorColor: Theme.of(context).primaryColor,
            tabs: const [
              Tab(text: 'Alineación'),
              Tab(text: 'Plantilla'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAlineacionTab(),
              _buildPlantillaTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlineacionTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Row(
            children: [
              const Text(
                'Formación:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButton<String>(
                  value: _formacionSeleccionada,
                  isExpanded: true,
                  items: ['4-3-3', '4-4-2', '3-5-2', '5-3-2'].map((formacion) {
                    return DropdownMenuItem(
                      value: formacion,
                      child: Text(formacion, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _formacionSeleccionada = value!);
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.green[700]!, Colors.green[600]!],
              ),
            ),
            child: CustomPaint(
              painter: CampoPainter(),
              child: _buildFormacion(),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _guardarAlineacion,
            icon: const Icon(Icons.save),
            label: const Text('Guardar Alineación'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormacion() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        Map<String, Offset> posiciones;
        
        switch (_formacionSeleccionada) {
          case '4-4-2':
            posiciones = {
              'POR': Offset(width * 0.5, height * 0.9),
              'DEF1': Offset(width * 0.15, height * 0.7),
              'DEF2': Offset(width * 0.35, height * 0.7),
              'DEF3': Offset(width * 0.65, height * 0.7),
              'DEF4': Offset(width * 0.85, height * 0.7),
              'MED1': Offset(width * 0.15, height * 0.45),
              'MED2': Offset(width * 0.35, height * 0.45),
              'MED3': Offset(width * 0.65, height * 0.45),
              'MED4': Offset(width * 0.85, height * 0.45),
              'DEL1': Offset(width * 0.35, height * 0.15),
              'DEL2': Offset(width * 0.65, height * 0.15),
            };
            break;
          case '4-3-3':
            posiciones = {
              'POR': Offset(width * 0.5, height * 0.9),
              'DEF1': Offset(width * 0.15, height * 0.7),
              'DEF2': Offset(width * 0.35, height * 0.7),
              'DEF3': Offset(width * 0.65, height * 0.7),
              'DEF4': Offset(width * 0.85, height * 0.7),
              'MED1': Offset(width * 0.25, height * 0.45),
              'MED2': Offset(width * 0.5, height * 0.45),
              'MED3': Offset(width * 0.75, height * 0.45),
              'DEL1': Offset(width * 0.2, height * 0.15),
              'DEL2': Offset(width * 0.5, height * 0.15),
              'DEL3': Offset(width * 0.8, height * 0.15),
            };
            break;
          case '3-5-2':
            posiciones = {
              'POR': Offset(width * 0.5, height * 0.9),
              'DEF1': Offset(width * 0.25, height * 0.7),
              'DEF2': Offset(width * 0.5, height * 0.7),
              'DEF3': Offset(width * 0.75, height * 0.7),
              'MED1': Offset(width * 0.15, height * 0.45),
              'MED2': Offset(width * 0.3, height * 0.45),
              'MED3': Offset(width * 0.5, height * 0.45),
              'MED4': Offset(width * 0.7, height * 0.45),
              'MED5': Offset(width * 0.85, height * 0.45),
              'DEL1': Offset(width * 0.35, height * 0.15),
              'DEL2': Offset(width * 0.65, height * 0.15),
            };
            break;
          case '5-3-2':
            posiciones = {
              'POR': Offset(width * 0.5, height * 0.9),
              'DEF1': Offset(width * 0.1, height * 0.7),
              'DEF2': Offset(width * 0.3, height * 0.7),
              'DEF3': Offset(width * 0.5, height * 0.7),
              'DEF4': Offset(width * 0.7, height * 0.7),
              'DEF5': Offset(width * 0.9, height * 0.7),
              'MED1': Offset(width * 0.25, height * 0.45),
              'MED2': Offset(width * 0.5, height * 0.45),
              'MED3': Offset(width * 0.75, height * 0.45),
              'DEL1': Offset(width * 0.35, height * 0.15),
              'DEL2': Offset(width * 0.65, height * 0.15),
            };
            break;
          default:
            posiciones = {};
        }

        return Stack(
          children: _posicionesActivas.map((pos) {
            final offset = posiciones[pos] ?? Offset.zero;
            final jugador = _alineacion[pos];
            
            return Positioned(
              left: offset.dx - 35,
              top: offset.dy - 35,
              child: GestureDetector(
                onTap: () => _seleccionarJugador(pos),
                child: _buildJugadorCard(jugador, pos),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildJugadorCard(Map<String, dynamic>? jugador, String posicion) {
    final posicionTipo = posicion.startsWith('POR') ? 'POR' 
        : posicion.startsWith('DEF') ? 'DEF'
        : posicion.startsWith('MED') ? 'MED'
        : 'DEL';
    
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: jugador != null ? Colors.blue : Colors.grey[300],
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: jugador != null
              ? ClipOval(
                  child: Center(
                    child: Text(
                      jugador['nombre'].split(' ').last.substring(0, 3).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              : Center(
                  child: Icon(Icons.add, color: Colors.grey[600], size: 30),
                ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            jugador != null ? jugador['nombre'].split(' ').last : posicionTipo,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPlantillaTab() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_plantilla.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_soccer, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('No tienes jugadores en tu plantilla'),
            SizedBox(height: 8),
            Text('Hubo un error al cargar tus jugadores'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _plantilla.length,
      itemBuilder: (context, index) {
        final jugador = _plantilla[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getColorPosicion(jugador['posicion']),
              child: Text(
                jugador['posicion'],
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            title: Text(jugador['nombre'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Valor: ${jugador['precio']}M • Media: ${jugador['media_fifa']}'),
            trailing: IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _mostrarDetallesJugador(jugador),
            ),
          ),
        );
      },
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

  Color _getColorPosicion(String posicion) {
    switch (posicion) {
      case 'POR': return Colors.amber;
      case 'DEF': return Colors.blue;
      case 'MED': return Colors.green;
      case 'DEL': return Colors.red;
      default: return Colors.grey;
    }
  }

  void _seleccionarJugador(String posicion) {
  final posicionTipo = posicion.startsWith('POR') ? 'POR'
      : posicion.startsWith('DEF') ? 'DEF'
      : posicion.startsWith('MED') ? 'MED'
      : 'DEL';
  
  showModalBottomSheet(
    context: context,
    builder: (context) {
      // Obtener IDs de jugadores ya alineados
      final jugadoresAlineados = _alineacion.values
          .where((j) => j != null)
          .map((j) => j['id'])
          .toSet();
      
      // Filtrar jugadores disponibles por posición y que no estén alineados
      final jugadoresDisponibles = _plantilla.where((j) => 
        j['posicion'] == posicionTipo && !jugadoresAlineados.contains(j['id'])
      ).toList();
      
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seleccionar $posicionTipo',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: jugadoresDisponibles.isEmpty
                  ? const Center(child: Text('No tienes jugadores disponibles en esta posición'))
                  : ListView.builder(
                      itemCount: jugadoresDisponibles.length,
                      itemBuilder: (context, index) {
                        final jugador = jugadoresDisponibles[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getColorPosicion(jugador['posicion']),
                            child: Text(
                              jugador['posicion'],
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          title: Text(jugador['nombre']),
                          subtitle: Text('Media: ${jugador['media_fifa']}'),
                          onTap: () {
                            setState(() {
                              _alineacion[posicion] = jugador;
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    },
  );
}

  Future<void> _guardarAlineacion() async {
  try {
    // Validar que tenga todos los titulares
    final titularesCompletos = _posicionesActivas.every((pos) => _alineacion[pos] != null);
    
    if (!titularesCompletos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa toda la alineación antes de guardar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Preparar datos para enviar
    final alineacionData = {
      'formacion': _formacionSeleccionada,
      'titulares': _posicionesActivas.map((pos) {
        final jugador = _alineacion[pos];
        return {
          'posicion_en_campo': pos,
          'jugador_id': jugador['id'],
        };
      }).toList(),
    };

    final authHeaders = await ApiService.getAuthHeaders();
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/ligas/${widget.ligaId}/mi-equipo/alineacion'),
      headers: authHeaders,
      body: jsonEncode(alineacionData),
    );

    if (response.statusCode == 200) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alineación guardada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      throw Exception('Error al guardar alineación');
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
}

class CampoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 50, paint);
    
    canvas.drawRect(Rect.fromLTWH(size.width * 0.3, 0, size.width * 0.4, size.height * 0.15), paint);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.3, size.height * 0.85, size.width * 0.4, size.height * 0.15), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}