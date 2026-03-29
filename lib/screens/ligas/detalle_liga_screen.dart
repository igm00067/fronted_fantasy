import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/api_service.dart';
import '../../config/app_theme.dart';
import 'mi_equipo_screen.dart';
import 'mercado_screen.dart';
import 'buscar_jugadores_screen.dart';
import 'clasificacion_liga_screen.dart';
import 'historial_mercado_screen.dart';
import 'inicio_liga_screen.dart';
import 'jornada_screen.dart';
import '../chat/chat_liga_screen.dart';

class DetalleLigaScreen extends StatefulWidget {
  final Map<String, dynamic> liga;

  const DetalleLigaScreen({
    Key? key,
    required this.liga,
  }) : super(key: key);

  @override
  State<DetalleLigaScreen> createState() => _DetalleLigaScreenState();
}

class _DetalleLigaScreenState extends State<DetalleLigaScreen> {
  int _selectedIndex = 0;
  late String _estadoLiga;
  Timer? _pollingTimer;

  late List<Widget> _screens;
  late List<BottomNavigationBarItem> _navItems;

  @override
  void initState() {
    super.initState();
    _estadoLiga = widget.liga['estado'] ?? 'pendiente';
    _construirPantallas();
    if (_estadoLiga == 'pendiente') _iniciarPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _iniciarPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      try {
        final liga = await ApiService.getLiga(widget.liga['id']);
        final nuevoEstado = liga['estado'] ?? 'pendiente';
        if (nuevoEstado != 'pendiente' && mounted) {
          _pollingTimer?.cancel();
          setState(() {
            _estadoLiga = nuevoEstado;
            _selectedIndex = 0;
            _construirPantallas();
          });
        }
      } catch (_) {}
    });
  }

  void _construirPantallas() {
    final ligaId = widget.liga['id'] as int;
    final competicionId = widget.liga['competicion_id'] as int;
    final nombre = widget.liga['nombre'] as String;

    if (_estadoLiga == 'pendiente') {
      _screens = [
        InicioLigaScreen(ligaId: ligaId, ligaNombre: nombre),
        MiEquipoScreen(ligaId: ligaId),
        MercadoScreen(ligaId: ligaId, competicionId: competicionId),
        ClasificacionLigaScreen(ligaId: ligaId),
        ChatLigaScreen(ligaId: ligaId),
      ];
      _navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.flag), label: 'Inicio'),
        BottomNavigationBarItem(icon: Icon(Icons.shield), label: 'Mi Equipo'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Mercado'),
        BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Clasificación'),
        BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: 'Chat'),
      ];
    } else {
      _screens = [
        DashboardLigaTab(
          ligaId: ligaId,
          onNavigateToMercado: () => setState(() => _selectedIndex = 2),
        ),
        JornadaScreen(ligaId: ligaId),
        MiEquipoScreen(ligaId: ligaId),
        MercadoScreen(ligaId: ligaId, competicionId: competicionId),
        ClasificacionLigaScreen(ligaId: ligaId),
        ChatLigaScreen(ligaId: ligaId),
      ];
      _navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
        BottomNavigationBarItem(icon: Icon(Icons.sports_soccer), label: 'Jornada'),
        BottomNavigationBarItem(icon: Icon(Icons.shield), label: 'Mi Equipo'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Mercado'),
        BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Clasificación'),
        BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: 'Chat'),
      ];
    }
  }

  int get _mercadoIndex => _estadoLiga == 'pendiente' ? 2 : 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.liga['nombre']),
        actions: [
          IconButton(icon: const Icon(Icons.info_outline), onPressed: _mostrarInfoLiga),
        ],
      ),
      body: _screens[_selectedIndex],
      floatingActionButton: _selectedIndex == _mercadoIndex
          ? Opacity(
              opacity: 0.75,
              child: FloatingActionButton(
                backgroundColor: AppTheme.primaryColor,
                tooltip: 'Buscar jugadores',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BuscarJugadoresScreen(
                      competicionId: widget.liga['competicion_id'],
                      ligaId: widget.liga['id'],
                    ),
                  ),
                ),
                child: const Icon(Icons.search, color: AppTheme.secondaryColor, size: 26),
              ),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: _navItems,
      ),
    );
  }

  void _mostrarInfoLiga() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.liga['nombre']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Código', widget.liga['codigo_invitacion']),
            _buildInfoRow('Participantes',
                '${widget.liga['num_participantes']}/${widget.liga['max_participantes']}'),
            _buildInfoRow(
                'Presupuesto', '${widget.liga['presupuesto_inicial']}M'),
            _buildInfoRow(
                'Máx. jugadores', '${widget.liga['max_jugadores_por_equipo']}'),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}

// Dashboard Tab
class DashboardLigaTab extends StatefulWidget {
  final int ligaId;
  final VoidCallback onNavigateToMercado;

  const DashboardLigaTab({
    Key? key,
    required this.ligaId,
    required this.onNavigateToMercado,
  }) : super(key: key);

  @override
  State<DashboardLigaTab> createState() => _DashboardLigaTabState();
}

class _DashboardLigaTabState extends State<DashboardLigaTab> {
  Map<String, dynamic>? _liga;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosLiga();
  }

  Future<void> _cargarDatosLiga() async {
    setState(() => _cargando = true);

    try {
      final authHeaders = await ApiService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/ligas/${widget.ligaId}'),
        headers: authHeaders,
      );

      if (response.statusCode == 200) {
        setState(() {
          _liga = jsonDecode(response.body);
          _cargando = false;
        });
      }
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando || _liga == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final miEquipo = _liga!['mi_equipo'];
    final saldoDisponible =
        miEquipo != null ? miEquipo['saldo_disponible'] : 0.0;
    final numParticipantes = _liga!['num_participantes'] ?? 0;
    final maxParticipantes = _liga!['max_participantes'] ?? 10;

    return RefreshIndicator(
      onRefresh: _cargarDatosLiga,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información de la liga
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.surfaceVariantColor,
                      AppTheme.surfaceColor,
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.emoji_events,
                              color: Colors.blue[700],
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Información de la Liga',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Participantes
                      _buildStatRow(
                        context,
                        'Participantes',
                        '$numParticipantes / $maxParticipantes',
                        Icons.people,
                        Colors.purple,
                        showProgress: true,
                        progressValue: numParticipantes / maxParticipantes,
                      ),
                      const SizedBox(height: 16),

                      // Presupuesto disponible
                      _buildStatRow(
                        context,
                        'Tu Presupuesto',
                        '${saldoDisponible.toStringAsFixed(1)}M',
                        Icons.account_balance_wallet,
                        Colors.green,
                      ),
                      const SizedBox(height: 16),

                      // Código de invitación
                      _buildStatRow(
                        context,
                        'Código de Invitación',
                        _liga!['codigo_invitacion'],
                        Icons.key,
                        Colors.orange,
                        showCopyButton: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Acciones rápidas
            Text(
              'Acciones Rápidas',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.history,
                    label: 'Historial',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              HistorialMercadoScreen(ligaId: widget.ligaId),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.shopping_cart,
                    label: 'Mercado',
                    color: Colors.orange,
                    onTap: widget.onNavigateToMercado,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Botón Abandonar Liga
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _confirmarAbandonarLiga(context),
                icon: const Icon(Icons.exit_to_app, color: Colors.white),
                label: const Text(
                  'Abandonar Liga',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarAbandonarLiga(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abandonar Liga'),
        content: const Text(
          '¿Estás seguro de que quieres abandonar esta liga?\n\n'
          'Se liberarán todos tus jugadores y perderás los partidos restantes 3-0.\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Abandonar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await ApiService.abandonarLiga(widget.ligaId);

      if (mounted) {
        Navigator.pop(context); // cerrar loading
        // Volver a mis ligas (pop hasta la raíz de la liga)
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Has abandonado la liga'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // cerrar loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildStatRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color, {
    bool showProgress = false,
    double progressValue = 0.0,
    bool showCopyButton = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariantColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (showCopyButton)
                IconButton(
                  icon: Icon(Icons.copy, color: color, size: 20),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Código copiado: $value'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
            ],
          ),
          if (showProgress) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progressValue,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.18),
                AppTheme.surfaceColor,
              ],
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
