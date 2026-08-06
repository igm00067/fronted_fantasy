// ─────────────────────────────────────────────────────────────────────────────
// screens/ligas/ver_equipo_usuario_screen.dart — Vista de plantilla de otro usuario
//
// Muestra la plantilla completa de un participante de la liga (no propia).
// Se accede desde ClasificacionLigaScreen al tocar el nombre de un equipo rival.
//
// Tiene dos pestañas:
//   "Titulares"  → los jugadores marcados como is_titular (alineación elegida)
//   "Plantilla"  → todos los jugadores del equipo (titulares + suplentes)
//
// Al tocar un jugador → JugadorDetallesSheet con sus estadísticas completas.
//
// Datos: GET /api/ligas/<ligaId>/equipo/<usuarioId>
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import '../../services/api/ligas_api.dart';
import '../../config/app_theme.dart';
import '../../widgets/jugador_detalles_sheet.dart';

class VerEquipoUsuarioScreen extends StatefulWidget {
  final int ligaId;
  final int usuarioId;
  final String nombreUsuario;
  final String nombreEquipo;

  const VerEquipoUsuarioScreen({
    Key? key,
    required this.ligaId,
    required this.usuarioId,
    required this.nombreUsuario,
    required this.nombreEquipo,
  }) : super(key: key);

  @override
  State<VerEquipoUsuarioScreen> createState() => _VerEquipoUsuarioScreenState();
}

class _VerEquipoUsuarioScreenState extends State<VerEquipoUsuarioScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _formacionSeleccionada = '4-3-3';

  List<Map<String, dynamic>> _plantilla = [];
  bool _cargando = true;
  Map<String, dynamic> _alineacion = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarEquipo();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarEquipo() async {
    setState(() => _cargando = true);
    try {
      final data = await LigasApi.getEquipoUsuarioCompleto(widget.ligaId, widget.usuarioId);
      setState(() {
        _plantilla = List<Map<String, dynamic>>.from(data['plantilla']);
        if (data['equipo']['formacion'] != null) {
          _formacionSeleccionada = data['equipo']['formacion'];
        }
        _alineacion = {};
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
      if (mounted) {
        setState(() => _cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<String> get _posicionesActivas {
    switch (_formacionSeleccionada) {
      case '4-4-2':
        return [
          'POR',
          'DEF1',
          'DEF2',
          'DEF3',
          'DEF4',
          'MED1',
          'MED2',
          'MED3',
          'MED4',
          'DEL1',
          'DEL2'
        ];
      case '4-3-3':
        return [
          'POR',
          'DEF1',
          'DEF2',
          'DEF3',
          'DEF4',
          'MED1',
          'MED2',
          'MED3',
          'DEL1',
          'DEL2',
          'DEL3'
        ];
      case '3-5-2':
        return [
          'POR',
          'DEF1',
          'DEF2',
          'DEF3',
          'MED1',
          'MED2',
          'MED3',
          'MED4',
          'MED5',
          'DEL1',
          'DEL2'
        ];
      case '5-3-2':
        return [
          'POR',
          'DEF1',
          'DEF2',
          'DEF3',
          'DEF4',
          'DEF5',
          'MED1',
          'MED2',
          'MED3',
          'DEL1',
          'DEL2'
        ];
      default:
        return [
          'POR',
          'DEF1',
          'DEF2',
          'DEF3',
          'DEF4',
          'MED1',
          'MED2',
          'MED3',
          'DEL1',
          'DEL2',
          'DEL3'
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.nombreEquipo),
            Text(
              widget.nombreUsuario,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
            ),
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
              const SizedBox(width: 12),
              Text(
                _formacionSeleccionada,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondaryColor,
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
                onTap: jugador != null
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
    final posicionTipo = posicion.startsWith('POR')
        ? 'POR'
        : posicion.startsWith('DEF')
            ? 'DEF'
            : posicion.startsWith('MED')
                ? 'MED'
                : 'DEL';

    final posColor = jugador != null
        ? _getColorPosicion(jugador['posicion'])
        : AppTheme.surfaceVariantColor;

    return Column(
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: posColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
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
                  child: Icon(Icons.help_outline,
                      color: AppTheme.textSecondaryColor, size: 28),
                ),
        ),
        const SizedBox(height: 4),
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
    if (_plantilla.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_soccer, size: 80, color: AppTheme.textSecondaryColor),
            SizedBox(height: 16),
            Text('Este equipo no tiene jugadores'),
          ],
        ),
      );
    }

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
                    width: 4, height: 16,
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
                  const SizedBox(width: 6),
                  Text('(${entry.value.length})',
                      style: const TextStyle(
                          color: AppTheme.textSecondaryColor, fontSize: 12)),
                ],
              ),
            ),
            ...entry.value.map<Widget>((jugador) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                leading: CircleAvatar(
                  backgroundColor: _getColorPosicion(jugador['posicion']),
                  child: Text(
                    jugador['posicion'],
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11),
                  ),
                ),
                title: Text(jugador['nombre'],
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(
                  '${jugador['precio']}M  •  Media: ${jugador['media_fifa']}',
                  style: const TextStyle(
                      color: AppTheme.textSecondaryColor, fontSize: 12),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.info_outline,
                      color: AppTheme.secondaryColor),
                  onPressed: () => mostrarDetallesJugador(context, jugador),
                ),
              ),
            )),
          ],
        );
      }).toList(),
    );
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

  String _nombrePosicion(String pos) {
    switch (pos) {
      case 'POR': return 'PORTEROS';
      case 'DEF': return 'DEFENSAS';
      case 'MED': return 'CENTROCAMPISTAS';
      case 'DEL': return 'DELANTEROS';
      default:    return pos;
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
    canvas.drawLine(
        Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 50, paint);

    canvas.drawRect(
        Rect.fromLTWH(size.width * 0.3, 0, size.width * 0.4, size.height * 0.15),
        paint);
    canvas.drawRect(
        Rect.fromLTWH(
            size.width * 0.3, size.height * 0.85, size.width * 0.4, size.height * 0.15),
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}