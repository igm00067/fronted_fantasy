import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../config/app_theme.dart';

class InicioLigaScreen extends StatefulWidget {
  final int ligaId;
  final String ligaNombre;

  const InicioLigaScreen({
    Key? key,
    required this.ligaId,
    required this.ligaNombre,
  }) : super(key: key);

  @override
  State<InicioLigaScreen> createState() => _InicioLigaScreenState();
}

class _InicioLigaScreenState extends State<InicioLigaScreen> {
  Map<String, dynamic>? _estado;
  bool _cargando = true;
  bool _enviando = false;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _cargar();
    // Refrescar la lista de participantes cada 5 segundos
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_enviando) _cargar();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final data = await ApiService.getEstadoInicio(widget.ligaId);
      setState(() { _estado = data; _cargando = false; });
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  Future<void> _toggleConfirmacion() async {
    if (_estado == null || _enviando) return;
    setState(() => _enviando = true);
    try {
      if (_estado!['yo_confirme'] == true) {
        await ApiService.retirarConfirmacion(widget.ligaId);
      } else {
        await ApiService.confirmarInicio(widget.ligaId);
      }
      await _cargar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const Center(child: CircularProgressIndicator());

    final participantes = (_estado?['participantes'] as List?) ?? [];
    final confirmados = _estado?['confirmados'] ?? 0;
    final total = _estado?['total'] ?? 0;
    final yoConfirme = _estado?['yo_confirme'] == true;
    final progreso = total > 0 ? confirmados / total : 0.0;

    return RefreshIndicator(
      onRefresh: _cargar,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Cabecera ──
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.sports_soccer, size: 48, color: AppTheme.secondaryColor),
                  const SizedBox(height: 12),
                  Text(
                    widget.ligaNombre,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Esperando que todos los participantes\nconfirmen para iniciar la liga',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Progreso ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Confirmaciones', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(
                        '$confirmados / $total',
                        style: const TextStyle(
                          color: AppTheme.secondaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progreso,
                      minHeight: 10,
                      backgroundColor: AppTheme.borderColor,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.secondaryColor),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Lista de participantes ──
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: Row(
                      children: const [
                        Icon(Icons.people, size: 16, color: AppTheme.textSecondaryColor),
                        SizedBox(width: 8),
                        Text('PARTICIPANTES',
                            style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold,
                              letterSpacing: 1.2, color: AppTheme.textSecondaryColor,
                            )),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppTheme.borderColor),
                  ...participantes.map((p) => _buildParticipanteTile(p)),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Botón confirmar ──
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _enviando ? null : _toggleConfirmacion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: yoConfirme ? Colors.red[800] : AppTheme.secondaryColor,
                  foregroundColor: yoConfirme ? Colors.white : Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: _enviando
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : Icon(yoConfirme ? Icons.cancel : Icons.check_circle),
                label: Text(
                  yoConfirme ? 'Retirar confirmación' : '¡Estoy listo para jugar!',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            if (yoConfirme)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  confirmados < total
                      ? 'Esperando a ${total - confirmados} jugador${total - confirmados == 1 ? '' : 'es'} más...'
                      : '¡Todos listos! Generando calendario...',
                  style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipanteTile(Map<String, dynamic> p) {
    final confirmo = p['confirmado'] == true;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: CircleAvatar(
        backgroundColor: confirmo
            ? AppTheme.secondaryColor.withOpacity(0.2)
            : AppTheme.surfaceVariantColor,
        child: Icon(
          confirmo ? Icons.check : Icons.hourglass_empty,
          color: confirmo ? AppTheme.secondaryColor : AppTheme.textSecondaryColor,
          size: 18,
        ),
      ),
      title: Text(p['nombre'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      trailing: confirmo
          ? const Text('✓ Listo', style: TextStyle(color: AppTheme.secondaryColor, fontWeight: FontWeight.bold, fontSize: 13))
          : const Text('Pendiente', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13)),
    );
  }
}
