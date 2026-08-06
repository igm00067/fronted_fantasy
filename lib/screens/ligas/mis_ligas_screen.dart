// ─────────────────────────────────────────────────────────────────────────────
// screens/ligas/mis_ligas_screen.dart — Lista de ligas del usuario
//
// Muestra todas las ligas en las que participa el usuario autenticado.
// Usa LigasProvider (Consumer) para gestionar el estado de carga.
//
// Flujo:
//   1. initState → cargarMisLigas() mediante addPostFrameCallback
//      (diferido para tener el contexto disponible)
//   2. Al tocar una liga → _navegarADetalleLiga() → muestra loading mientras
//      carga los datos completos de la liga → push a DetalleLigaScreen
//   3. Al volver de DetalleLigaScreen → .then() recarga la lista
//      (por si el usuario abandonó la liga mientras estaba dentro)
//
// Widgets privados:
//   _LigaCard — tarjeta individual de liga con avatar, estado, barra de progreso
//               y chips de presupuesto + código de invitación
//
// Color del avatar: determinístico por primera letra del nombre de la liga
// Color del estado: verde (en_curso) / gris (finalizada) / amarillo (pendiente)
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ligas_provider.dart';
import '../../models/liga.dart';
import '../../services/api_service.dart';
import '../../config/app_theme.dart';
import '../../widgets/common/liga_badge.dart';
import '../../widgets/common/info_chip.dart';
import 'detalle_liga_screen.dart';

class MisLigasScreen extends StatefulWidget {
  const MisLigasScreen({Key? key}) : super(key: key);

  @override
  State<MisLigasScreen> createState() => _MisLigasScreenState();
}

class _MisLigasScreenState extends State<MisLigasScreen> {
  @override
  void initState() {
    super.initState();
    // Carga inicial diferida para tener el contexto disponible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LigasProvider>().cargarMisLigas();
    });
  }

  /// Navega a la pantalla de detalle de la liga seleccionada.
  /// Primero carga los datos completos de la liga (GET /api/ligas/<id>)
  /// para obtener campos que no están en el listado (ej. codigo_invitacion completo).
  /// Muestra un spinner mientras carga para dar feedback al usuario.
  Future<void> _navegarADetalleLiga(Liga liga) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final ligaCompleta = await ApiService.getLiga(liga.id);
      if (mounted) {
        Navigator.pop(context); // cierra el spinner
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetalleLigaScreen(liga: ligaCompleta)),
        ).then((_) => context.read<LigasProvider>().cargarMisLigas()); // recarga al volver
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
    return Consumer<LigasProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            title: const Text('Mis Ligas'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: provider.cargarMisLigas,
              ),
            ],
          ),
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : provider.error != null
                  ? _buildError(provider)
                  : Column(
                      children: [
                        _buildHeader(provider.ligas),
                        Expanded(child: _buildBody(provider)),
                      ],
                    ),
        );
      },
    );
  }

  Widget _buildHeader(List<Liga> ligas) {
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
                ligas.isEmpty
                    ? 'Sin ligas activas'
                    : '${ligas.length} liga${ligas.length == 1 ? '' : 's'} activa${ligas.length == 1 ? '' : 's'}',
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

  Widget _buildBody(LigasProvider provider) {
    if (provider.ligas.isEmpty) return _buildEmpty();
    return RefreshIndicator(
      onRefresh: provider.cargarMisLigas,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        itemCount: provider.ligas.length,
        itemBuilder: (context, index) => _LigaCard(
          liga: provider.ligas[index],
          onTap: () => _navegarADetalleLiga(provider.ligas[index]),
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

  Widget _buildError(LigasProvider provider) {
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
              provider.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondaryColor),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: provider.cargarMisLigas,
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
  final Liga liga;
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

  Color get _avatarColor =>
      _avatarColors[liga.nombre.codeUnitAt(0) % _avatarColors.length];

  Color get _estadoColor {
    if (liga.estaEnCurso) return const Color(0xFF00D084);
    if (liga.estaFinalizada) return Colors.grey;
    return AppTheme.secondaryColor;
  }

  String get _estadoLabel {
    if (liga.estaEnCurso) return 'En curso';
    if (liga.estaFinalizada) return 'Finalizada';
    return 'Pendiente';
  }

  IconData get _estadoIcon {
    if (liga.estaEnCurso) return Icons.play_circle_filled_rounded;
    if (liga.estaFinalizada) return Icons.flag_rounded;
    return Icons.hourglass_empty_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final numPart  = liga.numParticipantes;
    final maxPart  = liga.maxParticipantes;
    final progreso = maxPart > 0 ? (numPart / maxPart).clamp(0.0, 1.0) : 0.0;
    final nombre = liga.nombre;
    final ac     = _avatarColor;
    final ec     = _estadoColor;

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
                          LigaBadge(icon: _estadoIcon, label: _estadoLabel, color: ec),
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
                        InfoChip(
                          icon: Icons.account_balance_wallet_outlined,
                          label: '${liga.presupuestoInicial.toInt()}M',
                          color: AppTheme.secondaryColor,
                        ),
                        const SizedBox(width: 8),
                        InfoChip(
                          icon: Icons.vpn_key_outlined,
                          label: liga.codigoInvitacion,
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

