import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../config/app_theme.dart';
import 'detalle_liga_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MisLigasScreen extends StatefulWidget {
  const MisLigasScreen({Key? key}) : super(key: key);

  @override
  State<MisLigasScreen> createState() => _MisLigasScreenState();
}

class _MisLigasScreenState extends State<MisLigasScreen> {
  List<dynamic> _ligas = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarLigas();
  }

  Future<void> _cargarLigas() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final ligas = await ApiService.getMisLigas();
      setState(() { _ligas = ligas; _cargando = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _cargando = false; });
    }
  }

  Future<void> _navegarADetalleLiga(Map<String, dynamic> liga) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final authHeaders = await ApiService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/ligas/${liga['id']}'),
        headers: authHeaders,
      );
      if (mounted) Navigator.pop(context);
      if (response.statusCode == 200) {
        final ligaCompleta = jsonDecode(response.body);
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DetalleLigaScreen(liga: ligaCompleta)),
          ).then((_) => _cargarLigas());
        }
      } else {
        throw Exception('Error al cargar liga');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Mis Ligas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _cargarLigas,
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : Column(
                  children: [
                    _buildHeader(),
                    Expanded(child: _buildBody()),
                  ],
                ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryColor, Color(0xFF5C0066)],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.secondaryColor.withOpacity(0.4)),
            ),
            child: const Icon(Icons.emoji_events, color: AppTheme.secondaryColor, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mis Ligas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _ligas.isEmpty
                    ? 'Sin ligas activas'
                    : '${_ligas.length} liga${_ligas.length == 1 ? '' : 's'} activa${_ligas.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: AppTheme.secondaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_ligas.isEmpty) return _buildEmpty();
    return RefreshIndicator(
      onRefresh: _cargarLigas,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        itemCount: _ligas.length,
        itemBuilder: (context, index) => _LigaCard(
          liga: _ligas[index],
          onTap: () => _navegarADetalleLiga(_ligas[index]),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, Color(0xFF5C0066)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.5),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.sports_soccer, size: 50, color: AppTheme.secondaryColor),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Sin ligas activas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Crea una nueva liga o únete a\nuna existente con un código.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 14, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 64, color: Colors.red[300]),
            const SizedBox(height: 20),
            const Text('No se pudieron cargar las ligas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              _error!.replaceAll('Exception: ', ''),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondaryColor),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _cargarLigas,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tarjeta de liga ───────────────────────────────────────────────────────────

class _LigaCard extends StatelessWidget {
  final Map<String, dynamic> liga;
  final VoidCallback onTap;

  const _LigaCard({required this.liga, required this.onTap});

  static const List<Color> _avatarColors = [
    Color(0xFF6C3BDB),
    Color(0xFF1565C0),
    Color(0xFF2E7D32),
    Color(0xFFC62828),
    Color(0xFF6A1B9A),
    Color(0xFF00838F),
    Color(0xFFE65100),
  ];

  Color get _avatarColor {
    final nombre = liga['nombre'] as String? ?? 'L';
    return _avatarColors[nombre.codeUnitAt(0) % _avatarColors.length];
  }

  Color get _estadoColor {
    switch (liga['estado'] ?? 'pendiente') {
      case 'en_curso':   return const Color(0xFF00D084);
      case 'finalizada': return Colors.grey;
      default:           return AppTheme.secondaryColor;
    }
  }

  String get _estadoLabel {
    switch (liga['estado'] ?? 'pendiente') {
      case 'en_curso':   return 'En curso';
      case 'finalizada': return 'Finalizada';
      default:           return 'Pendiente';
    }
  }

  IconData get _estadoIcon {
    switch (liga['estado'] ?? 'pendiente') {
      case 'en_curso':   return Icons.play_circle_filled_rounded;
      case 'finalizada': return Icons.flag_rounded;
      default:           return Icons.hourglass_empty_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombre     = liga['nombre'] as String? ?? 'Liga';
    final numPart    = (liga['num_participantes'] ?? 0) as int;
    final maxPart    = (liga['max_participantes'] ?? 10) as int;
    final presupuesto = liga['presupuesto_inicial'] ?? 100;
    final codigo     = liga['codigo_invitacion'] ?? '';
    final progreso   = maxPart > 0 ? (numPart / maxPart).clamp(0.0, 1.0) : 0.0;
    final ac         = _avatarColor;
    final ec         = _estadoColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: ec.withOpacity(0.3), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Cabecera ──────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [ac.withOpacity(0.18), Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [ac, ac.withOpacity(0.65)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: ac.withOpacity(0.45),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          nombre[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Nombre + badge estado
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _Badge(icon: _estadoIcon, label: _estadoLabel, color: ec),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppTheme.textSecondaryColor, size: 26),
                  ],
                ),
              ),

              // ── Divisor ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(height: 1, color: AppTheme.borderColor),
              ),

              // ── Stats ─────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  children: [
                    // Barra participantes
                    Row(
                      children: [
                        const Icon(Icons.people_alt_rounded,
                            size: 14, color: AppTheme.textSecondaryColor),
                        const SizedBox(width: 6),
                        const Text(
                          'Participantes',
                          style: TextStyle(
                              color: AppTheme.textSecondaryColor, fontSize: 12),
                        ),
                        const Spacer(),
                        Text(
                          '$numPart / $maxPart',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progreso,
                        minHeight: 6,
                        backgroundColor: AppTheme.borderColor,
                        valueColor: AlwaysStoppedAnimation<Color>(ec),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Chips: presupuesto + código
                    Row(
                      children: [
                        _Chip(
                          icon: Icons.account_balance_wallet_outlined,
                          label: '${presupuesto}M',
                          color: AppTheme.secondaryColor,
                        ),
                        const SizedBox(width: 8),
                        _Chip(
                          icon: Icons.vpn_key_outlined,
                          label: codigo,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Badge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
