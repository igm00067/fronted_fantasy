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
  Map<String, dynamic>? _partido;
  bool _cargando = true;
  Timer? _timer;

  // Identidad del usuario en el partido
  int? _miEquipoId;
  int _cambiosRealizados = 0;
  bool _esEquipoLocal = false;
  Set<int> _jugadoresSalePendientes = {}; // jugadores ya enviados al server pero aún no aplicados

  // Cambios pendientes (aún no enviados al servidor)
  List<Map<String, dynamic>> _cambiosPendientes = [];
  bool _enviandoCambios = false;

  static const int _maxCambios = 5;

  @override
  void initState() {
    super.initState();
    _cargar();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _cargar());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _cargar() async {
    try {
      final data = await ApiService.getPartido(widget.partidoId);
      if (mounted) {
        setState(() {
          _partido = data;
          _cargando = false;
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
      if (mounted) setState(() => _cargando = false);
    }
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
    if (_cargando) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_partido == null) return const Scaffold(body: Center(child: Text('Partido no encontrado')));

    final estado = _partido!['estado'] as String;
    final esVivo = ['primer_tiempo', 'descanso', 'segundo_tiempo'].contains(estado);

    // El usuario puede hacer cambios sólo si su equipo juega este partido
    final miEquipoJuega = _miEquipoId != null &&
        (_miEquipoId == _partido!['equipo_local_id'] ||
         _miEquipoId == _partido!['equipo_visitante_id']);

    final cambiosTotales = _cambiosRealizados + _cambiosPendientes.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Jornada ${_partido!['jornada_numero'] ?? ''}'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
        ],
      ),
      body: SingleChildScrollView(
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

  Widget _buildCambiosPanel(int cambiosTotales) {
    final estado = _partido!['estado'] as String;
    final enDescanso = estado == 'descanso';

    // Plantilla del equipo del usuario
    final miPlantilla = _esEquipoLocal
        ? (_partido!['plantilla_local'] as List?) ?? []
        : (_partido!['plantilla_visitante'] as List?) ?? [];

    // Excluir los que ya están en cambios locales (no enviados) o enviados al servidor (pendientes de aplicar)
    final yaVenden = {
      ..._cambiosPendientes.map((c) => c['sale']['jugador_id'] as int),
      ..._jugadoresSalePendientes,
    };
    final titulares = miPlantilla
        .where((j) => j['es_titular'] == true && !yaVenden.contains(j['jugador_id'] as int))
        .toList();
    final suplentes = miPlantilla
        .where((j) =>
            j['es_titular'] == false &&
            j['suspendido'] != true &&
            j['lesionado'] != true)
        .toList();

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

          // Lista de cambios pendientes locales
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
                    onPressed: () => _mostrarSelectorCambio(titulares, suplentes),
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

  void _mostrarSelectorCambio(List titulares, List suplentes) {
    Map<String, dynamic>? jugadorSale;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          expand: false,
          builder: (_, sc) => Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                color: AppTheme.surfaceVariantColor,
                child: Row(children: [
                  const Icon(Icons.swap_horiz, color: AppTheme.secondaryColor),
                  const SizedBox(width: 10),
                  Text(jugadorSale == null ? 'Selecciona quién sale' : 'Selecciona quién entra',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ]),
              ),
              Expanded(
                child: ListView(
                  controller: sc,
                  children: jugadorSale == null
                      ? titulares.map<Widget>((j) => _cambioTile(j, () {
                            setModalState(() => jugadorSale = j);
                          })).toList()
                      : suplentes.map<Widget>((j) => _cambioTile(j, () {
                            setState(() => _cambiosPendientes.add({'sale': jugadorSale, 'entra': j}));
                            Navigator.pop(ctx);
                          })).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cambioTile(Map<String, dynamic> j, VoidCallback onTap) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _colorPos(j['posicion'] ?? ''),
        child: Text(j['posicion'] ?? '?',
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
      ),
      title: Text(j['nombre'] ?? '', style: const TextStyle(fontSize: 14)),
      subtitle: Text('Media: ${j['media_fifa']}',
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
      onTap: onTap,
    );
  }

  Widget _buildEventos() {
    final eventos = (_partido!['eventos'] as List?) ?? [];
    if (eventos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Text('Sin eventos aún', style: TextStyle(color: AppTheme.textSecondaryColor),
            textAlign: TextAlign.center),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('EVENTOS DEL PARTIDO',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                  letterSpacing: 1.2, color: AppTheme.textSecondaryColor)),
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
