import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../config/app_theme.dart';
import 'partido_screen.dart';

class JornadaScreen extends StatefulWidget {
  final int ligaId;
  const JornadaScreen({Key? key, required this.ligaId}) : super(key: key);

  @override
  State<JornadaScreen> createState() => _JornadaScreenState();
}

class _JornadaScreenState extends State<JornadaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _jornadaActual;
  List<dynamic> _calendario = [];
  bool _primeraCarga = true;
  Timer? _timer;

  final ScrollController _scrollJornada = ScrollController();
  final ScrollController _scrollCalendario = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargar();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) => _cargar());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    _scrollJornada.dispose();
    _scrollCalendario.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    try {
      final results = await Future.wait([
        ApiService.getJornadaActual(widget.ligaId),
        ApiService.getCalendario(widget.ligaId),
      ]);
      if (mounted) {
        setState(() {
          _jornadaActual = results[0] as Map<String, dynamic>?;
          _calendario = results[1] as List<dynamic>;
          _primeraCarga = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _primeraCarga = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar
        Container(
          color: AppTheme.surfaceVariantColor,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.secondaryColor,
            labelColor: AppTheme.secondaryColor,
            unselectedLabelColor: AppTheme.textSecondaryColor,
            tabs: const [
              Tab(text: 'Jornada actual'),
              Tab(text: 'Calendario'),
            ],
          ),
        ),
        Expanded(
          child: _primeraCarga
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildJornadaActual(),
                    _buildCalendario(),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildJornadaActual() {
    if (_jornadaActual == null) {
      return const Center(
        child: Text('No hay jornada activa', style: TextStyle(color: AppTheme.textSecondaryColor)),
      );
    }

    final partidos = (_jornadaActual!['partidos'] as List?) ?? [];
    final numero = _jornadaActual!['numero'];
    final estado = _jornadaActual!['estado'] as String;

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        controller: _scrollJornada,
        padding: const EdgeInsets.all(16),
        children: [
          _buildJornadaHeader('Jornada $numero', estado),
          const SizedBox(height: 12),
          ...partidos.map((p) => _buildPartidoCard(p, mostrarBoton: true)),
        ],
      ),
    );
  }

  Widget _buildCalendario() {
    if (_calendario.isEmpty) {
      return const Center(
        child: Text('El calendario aún no está generado',
            style: TextStyle(color: AppTheme.textSecondaryColor)),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.builder(
        controller: _scrollCalendario,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _calendario.length,
        itemBuilder: (_, i) {
          final jornada = _calendario[i];
          final partidos = (jornada['partidos'] as List?) ?? [];
          final estado = jornada['estado'] as String;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: _buildJornadaHeader('Jornada ${jornada['numero']}', estado),
              ),
              ...partidos.map((p) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                    child: _buildPartidoCard(p, mostrarBoton: false),
                  )),
              const Divider(color: AppTheme.borderColor),
            ],
          );
        },
      ),
    );
  }

  Widget _buildJornadaHeader(String titulo, String estado) {
    final colorEstado = {
      'pendiente': AppTheme.textSecondaryColor,
      'en_curso': Colors.green,
      'finalizada': AppTheme.secondaryColor,
    }[estado] ?? AppTheme.textSecondaryColor;

    final labelEstado = {
      'pendiente': 'Pendiente',
      'en_curso': 'En curso',
      'finalizada': 'Finalizada',
    }[estado] ?? estado;

    return Row(
      children: [
        Text(titulo,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: colorEstado.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colorEstado.withOpacity(0.5)),
          ),
          child: Text(labelEstado,
              style: TextStyle(color: colorEstado, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildPartidoCard(Map<String, dynamic> partido, {required bool mostrarBoton}) {
    final estado = partido['estado'] as String;
    final gl = partido['goles_local'] ?? 0;
    final gv = partido['goles_visitante'] ?? 0;
    final finalizado = estado == 'finalizado';
    final enJuego = ['primer_tiempo', 'descanso', 'segundo_tiempo'].contains(estado);

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: mostrarBoton || enJuego || finalizado
            ? () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => PartidoScreen(
                    partidoId: partido['id'], ligaId: widget.ligaId)))
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  partido['equipo_local_nombre'] ?? 'Local',
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: enJuego
                      ? Colors.green.withOpacity(0.15)
                      : AppTheme.surfaceVariantColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: enJuego ? Colors.green.withOpacity(0.5) : AppTheme.borderColor,
                  ),
                ),
                child: finalizado || enJuego
                    ? Text('$gl - $gv',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: enJuego ? Colors.green : AppTheme.secondaryColor,
                        ))
                    : const Text('vs',
                        style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  partido['equipo_visitante_nombre'] ?? 'Visitante',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
              if (enJuego)
                const Icon(Icons.live_tv, size: 14, color: Colors.green),
            ],
          ),
        ),
      ),
    );
  }
}
