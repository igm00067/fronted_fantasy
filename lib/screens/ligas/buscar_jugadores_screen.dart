// ─────────────────────────────────────────────────────────────────────────────
// screens/ligas/buscar_jugadores_screen.dart — Catálogo completo de jugadores
//
// Permite explorar todos los jugadores de la competición con filtros y ordenación.
// Se abre desde el FAB de búsqueda en MercadoScreen/DetalleLigaScreen.
//
// Filtros disponibles:
//   - Búsqueda por nombre (filtro local sobre los datos ya cargados)
//   - Filtro por equipo real (dropdown con equipos de la competición)
//   - Filtro por posición (POR / DEF / MED / DEL)
//
// Ordenaciones (enum OrdenJugador):
//   nombreAsc/Desc, precioAsc/Desc, mediaAsc/Desc
//
// Datos cargados al inicio:
//   - GET /api/jugadores?equipo_real_id=... (todos los jugadores filtrados)
//   - GET /api/equipos?competicion_id=... (para el dropdown de equipos)
//   - GET /api/ligas/<id>/propiedad-jugadores (para mostrar a qué equipo pertenece)
//
// Al tocar un jugador → JugadorDetallesSheet con stats FIFA y disponibilidad.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../config/app_theme.dart';
import '../../widgets/jugador_detalles_sheet.dart';

/// Opciones de ordenación para la lista de jugadores.
enum OrdenJugador { nombreAsc, nombreDesc, precioAsc, precioDesc, mediaAsc, mediaDesc }

class BuscarJugadoresScreen extends StatefulWidget {
  final int competicionId;
  final int? ligaId;

  const BuscarJugadoresScreen({
    Key? key,
    required this.competicionId,
    this.ligaId,
  }) : super(key: key);

  @override
  State<BuscarJugadoresScreen> createState() => _BuscarJugadoresScreenState();
}

class _BuscarJugadoresScreenState extends State<BuscarJugadoresScreen> {
  final TextEditingController _busquedaController = TextEditingController();

  List<dynamic> _todosJugadores = [];
  List<dynamic> _jugadoresFiltrados = [];
  List<dynamic> _equipos = [];
  Map<int, String> _nombreEquipo = {};
  // jugador_id → nombre equipo fantasy propietario
  Map<int, String> _propiedadJugador = {};

  int? _equipoSeleccionado;
  String? _posicionSeleccionada;
  OrdenJugador _orden = OrdenJugador.mediaDesc;

  bool _cargando = true;
  String? _error;

  static const _posiciones = ['POR', 'DEF', 'MED', 'DEL'];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _busquedaController.addListener(_aplicarFiltros);
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final futures = <Future>[
        ApiService.getJugadores(),
        ApiService.getEquipos(competicionId: widget.competicionId),
        if (widget.ligaId != null)
          ApiService.getPropiedadJugadores(widget.ligaId!),
      ];
      final results = await Future.wait(futures);

      final todosJugadores = results[0] as List<dynamic>;
      _equipos = results[1] as List<dynamic>;
      _nombreEquipo = { for (final e in _equipos) e['id'] as int : e['nombre'] as String };

      if (widget.ligaId != null && results.length > 2) {
        final raw = results[2] as Map<String, dynamic>;
        _propiedadJugador = raw.map((k, v) => MapEntry(int.parse(k), v as String));
      }

      // Solo jugadores de esta competición
      final equiposIds = _nombreEquipo.keys.toSet();
      _todosJugadores = todosJugadores.where((j) {
        final eId = (j['equipo_real_id'] as num?)?.toInt();
        return eId != null && equiposIds.contains(eId);
      }).toList();

      _aplicarFiltros();
      setState(() => _cargando = false);
    } catch (e) {
      setState(() { _error = e.toString(); _cargando = false; });
    }
  }

  void _aplicarFiltros() {
    final texto = _busquedaController.text.toLowerCase().trim();

    List<dynamic> resultado = _todosJugadores.where((j) {
      final nombre = (j['nombre'] as String? ?? '').toLowerCase();
      if (texto.isNotEmpty && !nombre.contains(texto)) return false;
      if (_posicionSeleccionada != null && j['posicion'] != _posicionSeleccionada) return false;
      if (_equipoSeleccionado != null && j['equipo_real_id'] != _equipoSeleccionado) return false;
      return true;
    }).toList();

    resultado.sort((a, b) {
      switch (_orden) {
        case OrdenJugador.nombreAsc:
          return (a['nombre'] as String).compareTo(b['nombre'] as String);
        case OrdenJugador.nombreDesc:
          return (b['nombre'] as String).compareTo(a['nombre'] as String);
        case OrdenJugador.precioAsc:
          return ((a['precio'] as num?) ?? 0).compareTo((b['precio'] as num?) ?? 0);
        case OrdenJugador.precioDesc:
          return ((b['precio'] as num?) ?? 0).compareTo((a['precio'] as num?) ?? 0);
        case OrdenJugador.mediaAsc:
          return ((a['media_fifa'] as num?) ?? 0).compareTo((b['media_fifa'] as num?) ?? 0);
        case OrdenJugador.mediaDesc:
          return ((b['media_fifa'] as num?) ?? 0).compareTo((a['media_fifa'] as num?) ?? 0);
      }
    });

    setState(() => _jugadoresFiltrados = resultado);
  }

  void _limpiarFiltros() {
    setState(() {
      _equipoSeleccionado = null;
      _posicionSeleccionada = null;
      _orden = OrdenJugador.mediaDesc;
    });
    _busquedaController.clear();
  }

  bool get _hayFiltrosActivos =>
      _busquedaController.text.isNotEmpty ||
      _posicionSeleccionada != null ||
      _equipoSeleccionado != null ||
      _orden != OrdenJugador.mediaDesc;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Jugadores'),
        actions: [
          if (_hayFiltrosActivos)
            TextButton(
              onPressed: _limpiarFiltros,
              child: const Text('Limpiar', style: TextStyle(color: AppTheme.secondaryColor)),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Barra de búsqueda ──
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              controller: _busquedaController,
              autofocus: false,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _busquedaController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => _busquedaController.clear(),
                      )
                    : null,
              ),
            ),
          ),

          // ── Filtros ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Posición
                Expanded(child: _dropdownPosicion()),
                const SizedBox(width: 8),
                // Orden
                Expanded(child: _dropdownOrden()),
              ],
            ),
          ),

          // Filtro equipo (fila separada por si hay muchos)
          if (_equipos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: _dropdownEquipo(),
            ),

          // ── Contador resultado ──
          if (!_cargando)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Row(
                children: [
                  Text(
                    '${_jugadoresFiltrados.length} jugadores',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondaryColor),
                  ),
                ],
              ),
            ),

          // ── Lista ──
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildError()
                    : _jugadoresFiltrados.isEmpty
                        ? _buildVacio()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            itemCount: _jugadoresFiltrados.length,
                            itemBuilder: (context, index) =>
                                _buildJugadorCard(_jugadoresFiltrados[index]),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _dropdownPosicion() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _posicionSeleccionada != null
            ? _colorPosicion(_posicionSeleccionada!).withOpacity(0.15)
            : AppTheme.surfaceVariantColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _posicionSeleccionada != null
              ? _colorPosicion(_posicionSeleccionada!).withOpacity(0.6)
              : AppTheme.borderColor,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _posicionSeleccionada,
          isExpanded: true,
          hint: const Text('Posición', style: TextStyle(fontSize: 13)),
          dropdownColor: AppTheme.surfaceVariantColor,
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Todas las posiciones', style: TextStyle(fontSize: 13)),
            ),
            ..._posiciones.map((p) => DropdownMenuItem<String?>(
                  value: p,
                  child: Row(
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          color: _colorPosicion(p),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(p, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                )),
          ],
          onChanged: (v) {
            setState(() => _posicionSeleccionada = v);
            _aplicarFiltros();
          },
        ),
      ),
    );
  }

  Widget _dropdownOrden() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariantColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<OrdenJugador>(
          value: _orden,
          isExpanded: true,
          dropdownColor: AppTheme.surfaceVariantColor,
          items: const [
            DropdownMenuItem(value: OrdenJugador.mediaDesc, child: Text('Media ↓', style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: OrdenJugador.mediaAsc,  child: Text('Media ↑', style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: OrdenJugador.precioDesc, child: Text('Precio ↓', style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: OrdenJugador.precioAsc,  child: Text('Precio ↑', style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: OrdenJugador.nombreAsc,  child: Text('Nombre A-Z', style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: OrdenJugador.nombreDesc, child: Text('Nombre Z-A', style: TextStyle(fontSize: 13))),
          ],
          onChanged: (v) {
            if (v != null) { setState(() => _orden = v); _aplicarFiltros(); }
          },
        ),
      ),
    );
  }

  Widget _dropdownEquipo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _equipoSeleccionado != null
            ? AppTheme.secondaryColor.withOpacity(0.12)
            : AppTheme.surfaceVariantColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _equipoSeleccionado != null
              ? AppTheme.secondaryColor.withOpacity(0.5)
              : AppTheme.borderColor,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: _equipoSeleccionado,
          isExpanded: true,
          hint: Row(
            children: const [
              Icon(Icons.shield_outlined, size: 14, color: AppTheme.textSecondaryColor),
              SizedBox(width: 6),
              Text('Equipo real', style: TextStyle(fontSize: 13)),
            ],
          ),
          dropdownColor: AppTheme.surfaceVariantColor,
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('Todos los equipos', style: TextStyle(fontSize: 13)),
            ),
            ..._equipos.map((e) => DropdownMenuItem<int?>(
                  value: e['id'] as int,
                  child: Text(e['nombre'] as String? ?? '', style: const TextStyle(fontSize: 13)),
                )),
          ],
          onChanged: (v) {
            setState(() => _equipoSeleccionado = v);
            _aplicarFiltros();
          },
        ),
      ),
    );
  }

  Widget _buildJugadorCard(Map<String, dynamic> jugador) {
    final posicion  = jugador['posicion'] as String? ?? '';
    final color     = _colorPosicion(posicion);
    final media     = (jugador['media_fifa'] as num?)?.toInt() ?? 0;
    final precio    = jugador['precio'];
    final jugadorId = (jugador['id'] as num?)?.toInt();

    // Estado de propiedad en la liga
    final propietario = jugadorId != null ? _propiedadJugador[jugadorId] : null;
    final tieneOwner  = propietario != null;
    final mostrarOwner = widget.ligaId != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => mostrarDetallesJugador(context, jugador),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              // Badge posición + media
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withOpacity(0.5)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$media',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      posicion,
                      style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Info jugador
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      jugador['nombre'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _nombreEquipo[(jugador['equipo_real_id'] as num?)?.toInt()] ??
                          jugador['nacionalidad'] ?? '',
                      style: const TextStyle(
                          color: AppTheme.textSecondaryColor, fontSize: 12),
                    ),
                    // Badge de propiedad
                    if (mostrarOwner) ...[
                      const SizedBox(height: 5),
                      _OwnerBadge(
                        propietario: propietario,
                        tieneOwner: tieneOwner,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Columna derecha: precio
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${precio ?? '-'}M',
                      style: const TextStyle(
                        color: AppTheme.secondaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 16, color: AppTheme.textSecondaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 48, color: AppTheme.textSecondaryColor),
          const SizedBox(height: 12),
          const Text('No se encontraron jugadores',
              style: TextStyle(color: AppTheme.textSecondaryColor)),
          if (_hayFiltrosActivos) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _limpiarFiltros,
              child: const Text('Limpiar filtros',
                  style: TextStyle(color: AppTheme.secondaryColor)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: AppTheme.textSecondaryColor)),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: _cargarDatos, child: const Text('Reintentar')),
        ],
      ),
    );
  }

  Color _colorPosicion(String posicion) {
    switch (posicion) {
      case 'POR': return const Color(0xFFE69B00);
      case 'DEF': return const Color(0xFF1565C0);
      case 'MED': return const Color(0xFF2E7D32);
      case 'DEL': return const Color(0xFFC62828);
      default:    return Colors.grey;
    }
  }
}

// ── Badge de propiedad ────────────────────────────────────────────────────────

class _OwnerBadge extends StatelessWidget {
  final String? propietario;
  final bool tieneOwner;

  const _OwnerBadge({required this.propietario, required this.tieneOwner});

  @override
  Widget build(BuildContext context) {
    if (tieneOwner) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.red.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield_rounded, size: 10, color: Colors.redAccent),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                propietario!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF00D084).withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF00D084).withOpacity(0.35)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 10, color: Color(0xFF00D084)),
          SizedBox(width: 4),
          Text(
            'Disponible',
            style: TextStyle(
              color: Color(0xFF00D084),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
