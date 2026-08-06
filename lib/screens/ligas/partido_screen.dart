// ─────────────────────────────────────────────────────────────────────────────
// screens/ligas/partido_screen.dart — Seguimiento de un partido en tiempo real
//
// Permite al usuario ver el desarrollo del partido y gestionar sustituciones.
// Se accede desde JornadaScreen al tocar un partido activo o finalizado.
//
// Actualización de datos:
//   Timer cada 5 segundos → GET /api/ligas/partidos/<id>
//   Devuelve estado, marcador, eventos y alineaciones actualizadas.
//   Los eventos de Socket.IO (partido_minuto, partido_evento) también pueden
//   actualizar la UI en tiempo real si el usuario tiene el socket activo.
//
// Gestión de cambios (sustituciones):
//   _cambiosPendientes:   cambios seleccionados por el usuario (local)
//   _cambiosRealizados:   cambios ya enviados al backend (del servidor)
//   _maxCambios = 5:      límite total de cambios por partido
//   Durante el descanso → "Aplicar cambios" → POST /cambios-descanso
//
// Estados del partido (campo 'estado'):
//   'pendiente'     → no iniciado
//   'primer_tiempo' → en curso (minutos 0-45)
//   'descanso'      → se muestran controles de sustitución
//   'segundo_tiempo'→ en curso (minutos 45-90+)
//   'finalizado'    → se muestra resultado final
//
// _esEquipoLocal: determina si el equipo del usuario es el local o visitante
//                 para mostrar los controles de sustitución del lado correcto.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../config/app_theme.dart';

class PartidoScreen extends StatefulWidget {
  final int partidoId;
  final int ligaId;

  const PartidoScreen({Key? key, required this.partidoId, required this.ligaId}) : super(key: key);

  @override
  State<PartidoScreen> createState() => _PartidoScreenState();
}

class _PartidoScreenState extends State<PartidoScreen> {
  Map<String, dynamic>? _partido;  // respuesta completa de GET /partidos/<id>
  bool _primeraCarga = true;         // muestra spinner solo en la primera carga
  Timer? _timer;                     // polling cada 5 segundos
  final ScrollController _scrollCtrl = ScrollController();

  int? _miEquipoId;          // id del equipo del usuario autenticado en este partido
  int _cambiosRealizados = 0; // cambios ya aplicados (del servidor)
  bool _esEquipoLocal = false; // true si el equipo del usuario es el local
  Set<int> _jugadoresSalePendientes = {}; // ids de jugadores ya marcados para salir

  List<Map<String, dynamic>> _cambiosPendientes = []; // cambios seleccionados localmente
  bool _enviandoCambios = false; // bloquea el botón mientras envía al backend

  static const int _maxCambios = 5; // límite de sustituciones por partido

  @override
  void initState() {
    super.initState();
    _cargar();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _cargar());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    try {
      final data = await ApiService.getPartido(widget.partidoId);
      if (mounted) {
        setState(() {
          _partido = data;
          _primeraCarga = false;
          _miEquipoId = data['mi_equipo_id'];
          _cambiosRealizados = data['cambios_realizados'] ?? 0;
          _esEquipoLocal = data['mi_equipo_id'] != null &&
              data['mi_equipo_id'] == data['equipo_local_id'];
          _jugadoresSalePendientes = Set<int>.from(
            (data['jugadores_sale_pendientes'] as List? ?? []).map((id) => id as int),
          );
        });
      }
    } catch (_) {
      if (mounted) setState(() => _primeraCarga = false);
    }
  }

  // ── Helpers de estado en tiempo real (derivado de eventos del partido) ────
  Set<int> _expulsadosEnPartido() {
    if (_partido == null) return {};
    final eventos = (_partido!['eventos'] as List?) ?? [];
    return {
      for (final e in eventos)
        if ((e['tipo'] == 'roja' || e['tipo'] == 'doble_amarilla') &&
            e['jugador_id'] != null)
          e['jugador_id'] as int
    };
  }

  Set<int> _lesionadosEnPartido() {
    if (_partido == null) return {};
    final eventos = (_partido!['eventos'] as List?) ?? [];
    return {
      for (final e in eventos)
        if (e['tipo'] == 'lesion' && e['jugador_id'] != null)
          e['jugador_id'] as int
    };
  }

  Set<int> _conAmarillaEnPartido() {
    if (_partido == null) return {};
    final eventos = (_partido!['eventos'] as List?) ?? [];
    final Map<int, int> conteo = {};
    for (final e in eventos) {
      if (e['tipo'] == 'amarilla' && e['jugador_id'] != null) {
        final id = e['jugador_id'] as int;
        conteo[id] = (conteo[id] ?? 0) + 1;
      }
    }
    return conteo.keys.toSet();
  }

  Future<void> _enviarCambios() async {
    if (_cambiosPendientes.isEmpty) return;
    setState(() => _enviandoCambios = true);
    try {
      await ApiService.enviarCambiosDescanso(
        ligaId: widget.ligaId,
        partidoId: widget.partidoId,
        cambios: _cambiosPendientes.map((c) => {
          'jugador_sale_id': c['sale']['jugador_id'] as int,
          'jugador_entra_id': c['entra']['jugador_id'] as int,
        }).toList(),
      );
      setState(() => _cambiosPendientes = []);
      await _cargar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cambios enviados'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _enviandoCambios = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_primeraCarga) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_partido == null) return const Scaffold(body: Center(child: Text('Partido no encontrado')));

    final estado = _partido!['estado'] as String;
    final esVivo = ['primer_tiempo', 'descanso', 'segundo_tiempo'].contains(estado);

    final miEquipoJuega = _miEquipoId != null &&
        (_miEquipoId == _partido!['equipo_local_id'] ||
         _miEquipoId == _partido!['equipo_visitante_id']);

    final cambiosTotales = _cambiosRealizados + _cambiosPendientes.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Jornada ${_partido!['jornada_numero'] ?? ''}'),
        actions: [
          if (esVivo)
            IconButton(
              icon: const Icon(Icons.grass),
              tooltip: 'Ver alineaciones',
              onPressed: _mostrarAlineaciones,
            ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollCtrl,
        child: Column(
          children: [
            _buildMarcador(),
            if (esVivo && miEquipoJuega) _buildCambiosPanel(cambiosTotales),
            _buildEventos(),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Marcador
  // ──────────────────────────────────────────────
  Widget _buildMarcador() {
    final gl = _partido!['goles_local'] ?? 0;
    final gv = _partido!['goles_visitante'] ?? 0;
    final estado = _partido!['estado'] as String;
    final minuto = _partido!['minuto_actual'] as int?;

    final estadoLabel = {
      'pendiente': 'Por jugar',
      'primer_tiempo': '1er Tiempo',
      'descanso': 'Descanso',
      'segundo_tiempo': '2º Tiempo',
      'finalizado': 'Finalizado',
    }[estado] ?? estado;

    final estadoColor = {
      'primer_tiempo': Colors.green,
      'descanso': Colors.orange,
      'segundo_tiempo': Colors.green,
      'finalizado': AppTheme.textSecondaryColor,
      'pendiente': AppTheme.textSecondaryColor,
    }[estado] ?? AppTheme.textSecondaryColor;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: estadoColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: estadoColor.withOpacity(0.5)),
                ),
                child: Text(estadoLabel,
                    style: TextStyle(color: estadoColor, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              if (minuto != null) ...[
                const SizedBox(width: 8),
                Text("${minuto}'",
                    style: TextStyle(color: estadoColor, fontWeight: FontWeight.w600, fontSize: 12)),
              ],
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  _partido!['equipo_local_nombre'] ?? 'Local',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariantColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$gl - $gv',
                  style: const TextStyle(
                    fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  _partido!['equipo_visitante_nombre'] ?? 'Visitante',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Panel de cambios
  // ──────────────────────────────────────────────
  Widget _buildCambiosPanel(int cambiosTotales) {
    final estado = _partido!['estado'] as String;
    final enDescanso = estado == 'descanso';

    final miPlantilla = _esEquipoLocal
        ? (_partido!['plantilla_local'] as List?) ?? []
        : (_partido!['plantilla_visitante'] as List?) ?? [];

    // IDs de jugadores que están pendientes de salir en cambios locales o enviados
    final yaVenden = <int>{
      ..._cambiosPendientes.map((c) => c['sale']['jugador_id'] as int),
      ..._jugadoresSalePendientes,
    };
    // IDs de jugadores que están pendientes de entrar (localmente, aún no enviados)
    final yaEntranIds = <int>{
      ..._cambiosPendientes.map((c) => c['entra']['jugador_id'] as int),
    };

    // Estado en tiempo real derivado de eventos
    final expulsadosIds = _expulsadosEnPartido();
    final lesionadosIds = _lesionadosEnPartido();
    final amarillasIds = _conAmarillaEnPartido();

    // Titulares = en campo (es_titular del backend o entraron en cambio local pendiente)
    // Excluye: ya en yaVenden, expulsados en este partido, lesionados en este partido
    final titulares = miPlantilla.where((j) {
      final id = j['jugador_id'] as int;
      final enCampo = j['es_titular'] == true || yaEntranIds.contains(id);
      return enCampo &&
          !yaVenden.contains(id) &&
          !expulsadosIds.contains(id) &&
          !lesionadosIds.contains(id);
    }).toList();

    // Suplentes = no en campo, no lesionados/suspendidos en DB, no pendientes de entrar
    final suplentes = miPlantilla.where((j) {
      final id = j['jugador_id'] as int;
      return j['es_titular'] == false &&
          j['suspendido'] != true &&
          j['lesionado'] != true &&
          !yaEntranIds.contains(id);
    }).toList();

    final cambiosRestantes = _maxCambios - cambiosTotales;
    final puedeAnadir = cambiosRestantes > 0 && titulares.isNotEmpty && suplentes.isNotEmpty;

    final colorPanel = enDescanso ? Colors.orange : Colors.blue;
    final iconPanel = enDescanso ? Icons.timer : Icons.swap_horiz;
    final textoEstado = enDescanso
        ? 'DESCANSO - Haz tus cambios ahora'
        : 'EN VIVO - Puedes hacer cambios';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorPanel.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorPanel.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(iconPanel, color: colorPanel, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(textoEstado,
                    style: TextStyle(fontWeight: FontWeight.bold, color: colorPanel, fontSize: 14)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colorPanel.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$cambiosTotales / $_maxCambios',
                    style: TextStyle(color: colorPanel, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),

          if (_cambiosPendientes.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...(_cambiosPendientes.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.swap_horiz, size: 14, color: Colors.orange),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('${c['sale']['nombre']} → ${c['entra']['nombre']}',
                        style: const TextStyle(fontSize: 13)),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _cambiosPendientes.remove(c)),
                    child: const Icon(Icons.close, size: 16, color: AppTheme.textSecondaryColor),
                  ),
                ],
              ),
            ))),
          ],

          const SizedBox(height: 12),

          Row(
            children: [
              if (puedeAnadir)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _mostrarSelectorCambio(
                      titulares, suplentes, amarillasIds, expulsadosIds, lesionadosIds,
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Añadir cambio', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(foregroundColor: colorPanel),
                  ),
                ),
              if (puedeAnadir && _cambiosPendientes.isNotEmpty)
                const SizedBox(width: 8),
              if (_cambiosPendientes.isNotEmpty)
                Expanded(
                  child: ElevatedButton(
                    onPressed: _enviandoCambios ? null : _enviarCambios,
                    style: ElevatedButton.styleFrom(backgroundColor: colorPanel),
                    child: _enviandoCambios
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Confirmar', style: TextStyle(color: Colors.white)),
                  ),
                ),
            ],
          ),

          if (cambiosRestantes == 0)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('Has alcanzado el máximo de cambios.',
                  style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Modal de cambios — vista dividida
  // ──────────────────────────────────────────────
  void _mostrarSelectorCambio(
    List titulares,
    List suplentes,
    Set<int> amarillasIds,
    Set<int> expulsadosIds,
    Set<int> lesionadosIds,
  ) {
    Map<String, dynamic>? jugadorSale;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.85,
            child: Column(
              children: [
                // Handle bar
                Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Título y botón deshacer
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.swap_horiz, color: AppTheme.secondaryColor),
                      const SizedBox(width: 8),
                      const Text('Realizar Cambio',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Spacer(),
                      if (jugadorSale != null)
                        TextButton(
                          onPressed: () => setModalState(() => jugadorSale = null),
                          child: const Text('Deshacer', style: TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
                ),
                // Instrucción activa
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    jugadorSale == null
                        ? '① Selecciona el titular que sale'
                        : '② Selecciona el suplente que entra',
                    style: TextStyle(
                      fontSize: 12,
                      color: jugadorSale == null ? Colors.orange : Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Divider(height: 1),
                // Vista dividida: titulares | suplentes
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Columna izquierda: titulares (quién sale) ──
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              color: Colors.red.withOpacity(0.08),
                              child: const Center(
                                child: Text('SALE ↑',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                      fontSize: 12,
                                      letterSpacing: 1,
                                    )),
                              ),
                            ),
                            Expanded(
                              child: ListView(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                children: titulares.map<Widget>((j) {
                                  final id = j['jugador_id'] as int;
                                  final isSelected = jugadorSale != null &&
                                      jugadorSale!['jugador_id'] == id;
                                  return _buildCambioTileCompacto(
                                    jugador: j,
                                    isSelected: isSelected,
                                    tieneAmarillaVivo: amarillasIds.contains(id),
                                    onTap: () => setModalState(() => jugadorSale = j),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Divisor vertical
                      VerticalDivider(width: 1, color: AppTheme.borderColor),
                      // ── Columna derecha: suplentes (quién entra) ──
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              color: Colors.green.withOpacity(0.08),
                              child: const Center(
                                child: Text('ENTRA ↓',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                      fontSize: 12,
                                      letterSpacing: 1,
                                    )),
                              ),
                            ),
                            Expanded(
                              child: jugadorSale == null
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Text(
                                          'Primero selecciona quién sale',
                                          style: TextStyle(
                                            color: AppTheme.textSecondaryColor,
                                            fontSize: 12,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    )
                                  : ListView(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      children: suplentes.map<Widget>((j) {
                                        return _buildCambioTileCompacto(
                                          jugador: j,
                                          isSelected: false,
                                          tieneAmarillaVivo: false,
                                          onTap: () {
                                            setState(() => _cambiosPendientes
                                                .add({'sale': jugadorSale, 'entra': j}));
                                            Navigator.pop(ctx);
                                          },
                                        );
                                      }).toList(),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCambioTileCompacto({
    required Map<String, dynamic> jugador,
    required bool isSelected,
    required bool tieneAmarillaVivo,
    required VoidCallback onTap,
  }) {
    final bool lesionado = jugador['lesionado'] == true;
    final bool suspendido = jugador['suspendido'] == true;

    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.withOpacity(0.15) : Colors.transparent,
          border: isSelected
              ? const Border(left: BorderSide(color: Colors.orange, width: 3))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: _colorPos(jugador['posicion'] ?? ''),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  (jugador['posicion'] as String? ?? '?')[0],
                  style: const TextStyle(
                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    jugador['nombre'] ?? '',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text('Media: ${jugador['media_fifa']}',
                      style: const TextStyle(
                          fontSize: 10, color: AppTheme.textSecondaryColor)),
                ],
              ),
            ),
            // Badges de estado (en tiempo real primero, luego DB)
            if (lesionado) ...[
              _buildCruzLesion(),
              const SizedBox(width: 4),
            ] else if (suspendido) ...[
              _buildTarjetaRoja(),
              const SizedBox(width: 4),
            ] else if (tieneAmarillaVivo) ...[
              _buildTarjetaAmarilla(),
              const SizedBox(width: 4),
            ],
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.orange, size: 18),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Vista de alineaciones en el campo
  // ──────────────────────────────────────────────
  void _mostrarAlineaciones() {
    final expulsadosIds = _expulsadosEnPartido();
    final lesionadosIds = _lesionadosEnPartido();
    final amarillasIds = _conAmarillaEnPartido();

    // Filtrar jugadores que ya no están en el campo (expulsados/lesionados en este partido)
    final plantillaLocal = ((_partido!['plantilla_local'] as List?) ?? [])
        .where((j) {
          final id = j['jugador_id'] as int;
          return j['es_titular'] == true &&
              !expulsadosIds.contains(id) &&
              !lesionadosIds.contains(id);
        })
        .cast<Map<String, dynamic>>()
        .toList();
    final plantillaVisitante = ((_partido!['plantilla_visitante'] as List?) ?? [])
        .where((j) {
          final id = j['jugador_id'] as int;
          return j['es_titular'] == true &&
              !expulsadosIds.contains(id) &&
              !lesionadosIds.contains(id);
        })
        .cast<Map<String, dynamic>>()
        .toList();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        backgroundColor: Colors.transparent,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: BoxDecoration(
            color: const Color(0xFF1B5E20),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Cabecera con nombres de equipos
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _partido!['equipo_visitante_nombre'] ?? 'Visitante',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_partido!['goles_local']} - ${_partido!['goles_visitante']}',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _partido!['equipo_local_nombre'] ?? 'Local',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              // Campo de fútbol
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.green[700]!, Colors.green[600]!],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CustomPaint(
                    painter: _CampoPartidoPainter(),
                    child: LayoutBuilder(
                      builder: (_, constraints) => Stack(
                        children: [
                          // Visitante ocupa la mitad superior
                          ..._buildJugadoresEnCampo(
                              plantillaVisitante, constraints,
                              esLocal: false, amarillasIds: amarillasIds),
                          // Local ocupa la mitad inferior
                          ..._buildJugadoresEnCampo(
                              plantillaLocal, constraints,
                              esLocal: true, amarillasIds: amarillasIds),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Leyenda
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLeyendaItem(Icons.add, Colors.red, 'Lesionado'),
                    const SizedBox(width: 12),
                    _buildLeyendaItem(null, Colors.red, 'Sancionado', esRoja: true),
                    const SizedBox(width: 12),
                    _buildLeyendaItem(null, Colors.amber, 'Amarilla', esAmarilla: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeyendaItem(IconData? icon, Color color, String label,
      {bool esRoja = false, bool esAmarilla = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (esRoja || esAmarilla)
          Container(
            width: 10, height: 13,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(1.5)),
          )
        else
          Container(
            width: 16, height: 16,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.5),
            ),
            child: Icon(icon, color: color, size: 10),
          ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  List<Widget> _buildJugadoresEnCampo(
    List<Map<String, dynamic>> jugadores,
    BoxConstraints constraints, {
    required bool esLocal,
    required Set<int> amarillasIds,
  }) {
    final w = constraints.maxWidth;
    final h = constraints.maxHeight;

    final por = jugadores.where((j) => j['posicion'] == 'POR').toList();
    final def = jugadores.where((j) => j['posicion'] == 'DEF').toList();
    final med = jugadores.where((j) => j['posicion'] == 'MED').toList();
    final del = jugadores.where((j) => j['posicion'] == 'DEL').toList();

    final filas = [por, def, med, del];
    final yCoords = esLocal
        ? [0.92, 0.80, 0.68, 0.56]
        : [0.08, 0.20, 0.32, 0.44];

    final widgets = <Widget>[];
    for (int i = 0; i < filas.length; i++) {
      final fila = filas[i];
      if (fila.isEmpty) continue;
      final yFrac = yCoords[i];
      final n = fila.length;
      for (int k = 0; k < n; k++) {
        final xFrac = (k + 1) / (n + 1);
        final jugador = fila[k];
        final id = jugador['jugador_id'] as int;
        widgets.add(Positioned(
          left: w * xFrac - 24,
          top: h * yFrac - 30,
          child: _buildPlayerDot(jugador, tieneAmarillaVivo: amarillasIds.contains(id)),
        ));
      }
    }
    return widgets;
  }

  Widget _buildPlayerDot(Map<String, dynamic> jugador, {bool tieneAmarillaVivo = false}) {
    final bool lesionado = jugador['lesionado'] == true;
    final bool suspendido = jugador['suspendido'] == true;
    final color = _colorPos(jugador['posicion'] ?? '');
    final nombreCompleto = jugador['nombre'] as String? ?? '';
    final apellido = nombreCompleto.split(' ').last;
    final shortName = apellido.length > 7 ? apellido.substring(0, 7) : apellido;

    // Determinar badge a mostrar: prioridad lesion > suspendido > amarilla viva
    Widget? badge;
    if (lesionado) {
      badge = Positioned(
        bottom: -3, right: -3,
        child: Container(
          width: 16, height: 16,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.red, width: 1.5),
          ),
          child: const Icon(Icons.add, color: Colors.red, size: 10),
        ),
      );
    } else if (suspendido) {
      badge = Positioned(
        bottom: -3, right: -3,
        child: Container(
          width: 9, height: 12,
          decoration: BoxDecoration(
              color: Colors.red, borderRadius: BorderRadius.circular(1.5)),
        ),
      );
    } else if (tieneAmarillaVivo) {
      badge = Positioned(
        bottom: -3, right: -3,
        child: Container(
          width: 9, height: 12,
          decoration: BoxDecoration(
              color: Colors.amber, borderRadius: BorderRadius.circular(1.5)),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: (lesionado || suspendido) ? color.withOpacity(0.6) : color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: tieneAmarillaVivo
                      ? Colors.amber
                      : lesionado
                          ? Colors.red
                          : suspendido
                              ? Colors.red.shade900
                              : Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: Center(
                child: Text(
                  shortName.substring(0, shortName.length.clamp(0, 3)).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    shadows: [Shadow(color: Colors.black45, blurRadius: 3)],
                  ),
                ),
              ),
            ),
            if (badge != null) badge,
          ],
        ),
        const SizedBox(height: 2),
        Container(
          constraints: const BoxConstraints(maxWidth: 52),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.65),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            shortName,
            style: const TextStyle(
                fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────
  // Eventos del partido
  // ──────────────────────────────────────────────
  Widget _buildEventos() {
    final eventos = (_partido!['eventos'] as List?) ?? [];
    if (eventos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Text('Sin eventos aún',
            style: TextStyle(color: AppTheme.textSecondaryColor),
            textAlign: TextAlign.center),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('EVENTOS DEL PARTIDO',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppTheme.textSecondaryColor)),
          const SizedBox(height: 10),
          ...eventos.reversed.map((e) => _buildEventoTile(e)),
        ],
      ),
    );
  }

  Widget _buildEventoTile(Map<String, dynamic> e) {
    final tipo = e['tipo'] as String;
    final minuto = e['minuto'];
    final desc = e['descripcion'] ?? tipo;

    final iconoTipo = {
      'gol': '⚽',
      'amarilla': '🟨',
      'roja': '🟥',
      'doble_amarilla': '🟨🟨',
      'lesion': '🚑',
      'cambio': '🔄',
    }[tipo] ?? '•';

    final colorTipo = {
      'gol': Colors.green,
      'amarilla': Colors.amber,
      'roja': Colors.red,
      'doble_amarilla': Colors.orange,
      'lesion': Colors.red[300]!,
      'cambio': Colors.blue,
    }[tipo] ?? AppTheme.textSecondaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorTipo.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorTipo.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            alignment: Alignment.center,
            child: Text("${minuto}'",
                style: TextStyle(
                    color: colorTipo, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(width: 8),
          Text(iconoTipo, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(child: Text(desc, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Helpers de iconos de estado
  // ──────────────────────────────────────────────
  Widget _buildCruzLesion() {
    return Container(
      width: 18, height: 18,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.red, width: 1.5),
      ),
      child: const Icon(Icons.add, color: Colors.red, size: 12),
    );
  }

  Widget _buildTarjetaRoja() {
    return Container(
      width: 10, height: 14,
      decoration: BoxDecoration(
          color: Colors.red, borderRadius: BorderRadius.circular(1.5)),
    );
  }

  Widget _buildTarjetaAmarilla() {
    return Container(
      width: 10, height: 14,
      decoration: BoxDecoration(
          color: Colors.amber, borderRadius: BorderRadius.circular(1.5)),
    );
  }

  Color _colorPos(String pos) {
    switch (pos) {
      case 'POR': return const Color(0xFFE69B00);
      case 'DEF': return const Color(0xFF1565C0);
      case 'MED': return const Color(0xFF2E7D32);
      case 'DEL': return const Color(0xFFC62828);
      default: return Colors.grey;
    }
  }
}

// ──────────────────────────────────────────────
// Painter del campo para la vista de alineaciones
// ──────────────────────────────────────────────
class _CampoPartidoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Borde del campo
    canvas.drawRect(Rect.fromLTWH(2, 2, size.width - 4, size.height - 4), paint);
    // Línea central
    canvas.drawLine(
        Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
    // Círculo central
    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2), size.width * 0.11, paint);
    // Punto central
    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 3, dotPaint);

    // Área grande — parte superior (visitante)
    final boxW = size.width * 0.44;
    final boxH = size.height * 0.12;
    canvas.drawRect(
        Rect.fromLTWH((size.width - boxW) / 2, 2, boxW, boxH), paint);
    // Área grande — parte inferior (local)
    canvas.drawRect(
        Rect.fromLTWH(
            (size.width - boxW) / 2, size.height - boxH - 2, boxW, boxH),
        paint);

    // Área pequeña — superior
    final goalW = size.width * 0.22;
    final goalH = size.height * 0.05;
    canvas.drawRect(
        Rect.fromLTWH((size.width - goalW) / 2, 2, goalW, goalH), paint);
    // Área pequeña — inferior
    canvas.drawRect(
        Rect.fromLTWH(
            (size.width - goalW) / 2, size.height - goalH - 2, goalW, goalH),
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
