import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/api/ligas_api.dart';
import '../../config/app_theme.dart';
import '../../widgets/jugador_detalles_sheet.dart';

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
      final data = await LigasApi.getMiEquipoCompleto(widget.ligaId);
      setState(() {
        _plantilla = List<Map<String, dynamic>>.from(data['plantilla']);
        _alineacion = {
          'POR': null,
          'DEF1': null, 'DEF2': null, 'DEF3': null, 'DEF4': null, 'DEF5': null,
          'MED1': null, 'MED2': null, 'MED3': null, 'MED4': null, 'MED5': null,
          'DEL1': null, 'DEL2': null, 'DEL3': null,
        };
        if (data['equipo']['formacion'] != null) {
          _formacionSeleccionada = data['equipo']['formacion'];
        }
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
          color: AppTheme.surfaceColor,
          child: TabBar(
            controller: _tabController,
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppTheme.surfaceVariantColor,
          child: Row(
            children: [
              const Text(
                'Formación:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _formacionSeleccionada,
                    isExpanded: true,
                    dropdownColor: AppTheme.surfaceColor,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryColor,
                    ),
                    icon: const Icon(Icons.arrow_drop_down, color: AppTheme.secondaryColor),
                    items: ['4-3-3', '4-4-2', '3-5-2', '5-3-2'].map((formacion) {
                      return DropdownMenuItem(
                        value: formacion,
                        child: Text(formacion),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _formacionSeleccionada = value!);
                    },
                  ),
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
        Container(
          color: AppTheme.surfaceVariantColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: ElevatedButton.icon(
            onPressed: _guardarAlineacion,
            icon: const Icon(Icons.save_rounded),
            label: const Text('Guardar Alineación'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
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
              'POR': Offset(width * 0.5,  height * 0.87),
              'DEF1': Offset(width * 0.15, height * 0.63),
              'DEF2': Offset(width * 0.35, height * 0.63),
              'DEF3': Offset(width * 0.65, height * 0.63),
              'DEF4': Offset(width * 0.85, height * 0.63),
              'MED1': Offset(width * 0.15, height * 0.37),
              'MED2': Offset(width * 0.35, height * 0.37),
              'MED3': Offset(width * 0.65, height * 0.37),
              'MED4': Offset(width * 0.85, height * 0.37),
              'DEL1': Offset(width * 0.35, height * 0.10),
              'DEL2': Offset(width * 0.65, height * 0.10),
            };
            break;
          case '4-3-3':
            posiciones = {
              'POR': Offset(width * 0.5,  height * 0.87),
              'DEF1': Offset(width * 0.15, height * 0.63),
              'DEF2': Offset(width * 0.35, height * 0.63),
              'DEF3': Offset(width * 0.65, height * 0.63),
              'DEF4': Offset(width * 0.85, height * 0.63),
              'MED1': Offset(width * 0.25, height * 0.37),
              'MED2': Offset(width * 0.5,  height * 0.37),
              'MED3': Offset(width * 0.75, height * 0.37),
              'DEL1': Offset(width * 0.2,  height * 0.10),
              'DEL2': Offset(width * 0.5,  height * 0.10),
              'DEL3': Offset(width * 0.8,  height * 0.10),
            };
            break;
          case '3-5-2':
            posiciones = {
              'POR': Offset(width * 0.5,  height * 0.87),
              'DEF1': Offset(width * 0.25, height * 0.63),
              'DEF2': Offset(width * 0.5,  height * 0.63),
              'DEF3': Offset(width * 0.75, height * 0.63),
              'MED1': Offset(width * 0.1,  height * 0.37),
              'MED2': Offset(width * 0.3,  height * 0.37),
              'MED3': Offset(width * 0.5,  height * 0.37),
              'MED4': Offset(width * 0.7,  height * 0.37),
              'MED5': Offset(width * 0.9,  height * 0.37),
              'DEL1': Offset(width * 0.35, height * 0.10),
              'DEL2': Offset(width * 0.65, height * 0.10),
            };
            break;
          case '5-3-2':
            posiciones = {
              'POR': Offset(width * 0.5,  height * 0.87),
              'DEF1': Offset(width * 0.1,  height * 0.63),
              'DEF2': Offset(width * 0.3,  height * 0.63),
              'DEF3': Offset(width * 0.5,  height * 0.63),
              'DEF4': Offset(width * 0.7,  height * 0.63),
              'DEF5': Offset(width * 0.9,  height * 0.63),
              'MED1': Offset(width * 0.25, height * 0.37),
              'MED2': Offset(width * 0.5,  height * 0.37),
              'MED3': Offset(width * 0.75, height * 0.37),
              'DEL1': Offset(width * 0.35, height * 0.10),
              'DEL2': Offset(width * 0.65, height * 0.10),
            };
            break;
          default:
            posiciones = {};
        }

        return Stack(
          clipBehavior: Clip.none,
          children: _posicionesActivas.map((pos) {
            final offset = posiciones[pos] ?? Offset.zero;
            final jugador = _alineacion[pos];
            
            return Positioned(
              left: offset.dx - 35,
              top: offset.dy - 35,
              child: GestureDetector(
                onTap: () => _seleccionarJugador(pos),
                onLongPress: jugador != null
                    ? () => mostrarDetallesJugador(context, jugador)
                    : null,
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

    final posColor = jugador != null ? _getColorPosicion(jugador['posicion']) : AppTheme.surfaceVariantColor;
    final bool lesionado = jugador?['lesionado'] == true;
    final bool suspendido = jugador?['suspendido'] == true;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: (lesionado || suspendido) ? posColor.withOpacity(0.55) : posColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: lesionado
                      ? Colors.red
                      : suspendido
                          ? Colors.red.shade900
                          : (jugador != null ? Colors.white : AppTheme.secondaryColor),
                  width: jugador != null ? 2.5 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: jugador != null
                  ? Center(
                      child: Text(
                        jugador['nombre'].split(' ').last.substring(0, 3).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                        ),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.add, color: AppTheme.secondaryColor, size: 28),
                    ),
            ),
            // Badge de lesión (cruz roja)
            if (lesionado)
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.red, width: 1.5),
                  ),
                  child: const Icon(Icons.add, color: Colors.red, size: 14),
                ),
              )
            // Badge de sanción (tarjeta roja)
            else if (suspendido)
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  width: 12,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.65),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            jugador != null ? jugador['nombre'].split(' ').last : posicionTipo,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
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
            Icon(Icons.sports_soccer, size: 80, color: AppTheme.textSecondaryColor),
            SizedBox(height: 16),
            Text('No tienes jugadores en tu plantilla'),
            SizedBox(height: 8),
            Text(
              'Ve al mercado para fichar jugadores',
              style: TextStyle(color: AppTheme.textSecondaryColor),
            ),
          ],
        ),
      );
    }

    // Agrupar por posición
    final grupos = {'POR': [], 'DEF': [], 'MED': [], 'DEL': []};
    for (final j in _plantilla) {
      final pos = j['posicion'] as String;
      if (grupos.containsKey(pos)) grupos[pos]!.add(j);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      children: grupos.entries.where((e) => e.value.isNotEmpty).map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _getColorPosicion(entry.key),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _nombrePosicion(entry.key),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.textSecondaryColor,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${entry.value.length})',
                    style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
                  ),
                ],
              ),
            ),
            ...entry.value.map<Widget>((jugador) {
              final bool lesionado = jugador['lesionado'] == true;
              final bool suspendido = jugador['suspendido'] == true;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  leading: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        backgroundColor: lesionado || suspendido
                            ? _getColorPosicion(jugador['posicion']).withOpacity(0.5)
                            : _getColorPosicion(jugador['posicion']),
                        child: Text(
                          jugador['posicion'],
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                      if (lesionado)
                        Positioned(
                          bottom: -2, right: -2,
                          child: Container(
                            width: 16, height: 16,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.red, width: 1.5),
                            ),
                            child: const Icon(Icons.add, color: Colors.red, size: 10),
                          ),
                        )
                      else if (suspendido)
                        Positioned(
                          bottom: -2, right: -2,
                          child: Container(
                            width: 10, height: 13,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          jugador['nombre'],
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      if (lesionado)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.withOpacity(0.4)),
                          ),
                          child: Text(
                            'Lesionado ${jugador['jornadas_lesion'] > 0 ? "(${jugador['jornadas_lesion']}J)" : ""}',
                            style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        )
                      else if (suspendido)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.withOpacity(0.4)),
                          ),
                          child: const Text(
                            'Sancionado',
                            style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    '${jugador['precio']}M  •  Media: ${jugador['media_fifa']}',
                    style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.sell, color: Colors.red[400], size: 22),
                        tooltip: 'Vender por ${jugador['precio']}M',
                        onPressed: () => _confirmarVentaJugador(jugador),
                      ),
                      IconButton(
                        icon: const Icon(Icons.info_outline, color: AppTheme.secondaryColor),
                        onPressed: () => _mostrarDetallesJugador(jugador),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      }).toList(),
    );
  }

  Future<void> _confirmarVentaJugador(Map<String, dynamic> jugador) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vender Jugador'),
        content: Text(
          '¿Estás seguro de que quieres vender a ${jugador['nombre']} por ${jugador['precio']}M?\n\n'
          'El jugador será liberado al mercado y recibirás ${jugador['precio']}M.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Vender', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      final resultado = await ApiService.venderJugador(
        ligaId: widget.ligaId,
        jugadorId: jugador['id'],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado['mensaje'] ?? 'Jugador vendido'),
            backgroundColor: Colors.green,
          ),
        );
        // Recargar equipo
        _cargarEquipo();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _mostrarDetallesJugador(Map<String, dynamic> jugador) {
    mostrarDetallesJugador(context, jugador);
  }

  Color _getColorPosicion(String posicion) {
    switch (posicion) {
      case 'POR': return const Color(0xFFE69B00);
      case 'DEF': return const Color(0xFF1565C0);
      case 'MED': return const Color(0xFF2E7D32);
      case 'DEL': return const Color(0xFFC62828);
      default: return Colors.grey;
    }
  }

  String _nombrePosicion(String pos) {
    switch (pos) {
      case 'POR': return 'PORTEROS';
      case 'DEF': return 'DEFENSAS';
      case 'MED': return 'CENTROCAMPISTAS';
      case 'DEL': return 'DELANTEROS';
      default: return pos;
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
      
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceVariantColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _getColorPosicion(posicionTipo),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Seleccionar ${_nombrePosicion(posicionTipo)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: jugadoresDisponibles.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off, size: 48, color: AppTheme.textSecondaryColor),
                        SizedBox(height: 12),
                        Text(
                          'No hay jugadores disponibles',
                          style: TextStyle(color: AppTheme.textSecondaryColor),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: jugadoresDisponibles.length,
                    itemBuilder: (context, index) {
                      final jugador = jugadoresDisponibles[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getColorPosicion(jugador['posicion']),
                            child: Text(
                              jugador['posicion'],
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                          title: Text(jugador['nombre'], style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            'Media: ${jugador['media_fifa']}  •  ${jugador['precio']}M',
                            style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
                          ),
                          trailing: const Icon(Icons.add_circle, color: AppTheme.secondaryColor),
                          onTap: () {
                            setState(() {
                              _alineacion[posicion] = jugador;
                            });
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      );
    },
  );
}

  Future<void> _guardarAlineacion() async {
    try {
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

      await LigasApi.guardarAlineacion(
        ligaId: widget.ligaId,
        formacion: _formacionSeleccionada,
        titulares: _posicionesActivas.map((pos) => {
          'posicion_en_campo': pos,
          'jugador_id': _alineacion[pos]!['id'] as int,
        }).toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alineación guardada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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