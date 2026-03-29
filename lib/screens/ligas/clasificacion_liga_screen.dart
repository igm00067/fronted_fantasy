import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../config/app_theme.dart';
import 'ver_equipo_usuario_screen.dart';

class ClasificacionLigaScreen extends StatefulWidget {
  final int ligaId;

  const ClasificacionLigaScreen({Key? key, required this.ligaId})
      : super(key: key);

  @override
  State<ClasificacionLigaScreen> createState() =>
      _ClasificacionLigaScreenState();
}

class _ClasificacionLigaScreenState extends State<ClasificacionLigaScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _clasificacion = [];
  Map<String, dynamic>? _liga;
  bool _cargando = true;
  String? _error;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _cargarClasificacion();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarClasificacion() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final data = await ApiService.getClasificacion(widget.ligaId);
      setState(() {
        _liga = data['liga'];
        _clasificacion = data['clasificacion'];
        _cargando = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _cargando = false; });
    }
  }

  bool get _ligaFinalizada => _liga?['estado'] == 'finalizada';

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
            const SizedBox(height: 16),
            const Text('Error al cargar clasificación',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_error!.replaceAll('Exception: ', ''),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondaryColor)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _cargarClasificacion,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_clasificacion.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('No hay participantes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Invita a tus amigos a unirse',
                style: TextStyle(color: AppTheme.textSecondaryColor)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarClasificacion,
      child: Column(
        children: [
          // Cabecera de la liga
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_liga?['nombre'] ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    Text('${_clasificacion.length} participantes',
                        style: const TextStyle(
                            color: AppTheme.textSecondaryColor, fontSize: 13)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _cargarClasificacion,
                ),
              ],
            ),
          ),

          // Banner del campeón (solo cuando la liga ha finalizado)
          if (_ligaFinalizada) _buildWinnerBanner(),

          // Cabecera de la tabla
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: _buildTablaHeader(),
          ),

          // Lista de clasificación
          Expanded(
            child: ListView.builder(
              itemCount: _clasificacion.length,
              itemBuilder: (context, index) =>
                  _buildFilaClasificacion(_clasificacion[index]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Banner animado del campeón ──────────────────────────────────────────────
  Widget _buildWinnerBanner() {
    final ganador = _clasificacion.first as Map<String, dynamic>;
    final yoGane = ganador['es_mi_equipo'] == true;

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, child) => Transform.scale(scale: _pulseAnim.value, child: child),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFB8860B), Color(0xFFFFD700), Color(0xFFDAA520)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.5),
              blurRadius: 24,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Título
            Text(
              yoGane ? '¡ERES EL CAMPEÓN!' : '¡CAMPEÓN DE LA LIGA!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 12),

            // Trofeo + nombre
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emoji_events_rounded,
                    size: 52, color: Colors.white),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ganador['equipo_nombre'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      ganador['usuario_nombre'] ?? '',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Stats del campeón
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _statChip(Icons.stars_rounded, '${ganador['puntos']} pts'),
                  const SizedBox(width: 20),
                  _statChip(Icons.check_circle_outline,
                      '${ganador['partidos_ganados']}V'),
                  const SizedBox(width: 20),
                  _statChip(Icons.sports_soccer,
                      '+${ganador['diferencia_goles']} GD'),
                ],
              ),
            ),

            if (yoGane) ...[
              const SizedBox(height: 10),
              const Text(
                '¡Enhorabuena! Has ganado la liga.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
      ],
    );
  }

  // ── Cabecera de tabla ──────────────────────────────────────────────────────
  Widget _buildTablaHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariantColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: const Row(
        children: [
          SizedBox(width: 40, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 3,
              child: Text('Equipo', style: TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 40,
              child: Text('PJ', style: TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 40,
              child: Text('PTS', style: TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 50,
              child: Text('DIF', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  // ── Fila de clasificación ──────────────────────────────────────────────────
  Widget _buildFilaClasificacion(Map<String, dynamic> participante) {
    final posicion = participante['posicion'] as int;
    final esMio = participante['es_mi_equipo'] == true;
    final color = _getColorPosicion(posicion);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      elevation: posicion <= 3 ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: esMio
            ? const BorderSide(color: AppTheme.secondaryColor, width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _mostrarDetalles(participante),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            border: posicion <= 3
                ? Border(left: BorderSide(color: color, width: 4))
                : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Posición
              SizedBox(
                width: 40,
                child: posicion == 1 && _ligaFinalizada
                    ? const Icon(Icons.emoji_events_rounded,
                        color: Color(0xFFFFD700), size: 28)
                    : CircleAvatar(
                        backgroundColor: color,
                        radius: 16,
                        child: Text('$posicion',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                      ),
              ),

              // Nombre equipo y usuario
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            participante['equipo_nombre'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: esMio ? AppTheme.secondaryColor : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (esMio) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.person_pin_circle_rounded,
                              size: 14, color: AppTheme.secondaryColor),
                        ],
                      ],
                    ),
                    Text(
                      participante['usuario_nombre'],
                      style: const TextStyle(
                          color: AppTheme.textSecondaryColor, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Partidos jugados
              SizedBox(
                width: 40,
                child: Text('${participante['partidos_jugados']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
              ),

              // Puntos
              SizedBox(
                width: 40,
                child: Text(
                  '${participante['puntos']}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).primaryColor),
                  textAlign: TextAlign.center,
                ),
              ),

              // Diferencia de goles
              SizedBox(
                width: 50,
                child: Text(
                  '${participante['diferencia_goles'] > 0 ? '+' : ''}${participante['diferencia_goles']}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: participante['diferencia_goles'] > 0
                        ? Colors.green
                        : participante['diferencia_goles'] < 0
                            ? Colors.red
                            : Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColorPosicion(int posicion) {
    switch (posicion) {
      case 1: return const Color(0xFFFFD700); // Oro
      case 2: return Colors.blueGrey;         // Plata
      case 3: return const Color(0xFFCD7F32); // Bronce
      default: return Colors.blue;
    }
  }

  void _mostrarDetalles(Map<String, dynamic> participante) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(participante['equipo_nombre']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Jugador', participante['usuario_nombre']),
            _buildInfoRow('Posición', '#${participante['posicion']}'),
            const Divider(),
            _buildInfoRow('Partidos jugados', '${participante['partidos_jugados']}'),
            _buildInfoRow('Victorias', '${participante['partidos_ganados']}'),
            _buildInfoRow('Empates', '${participante['partidos_empatados']}'),
            _buildInfoRow('Derrotas', '${participante['partidos_perdidos']}'),
            const Divider(),
            _buildInfoRow('Puntos', '${participante['puntos']}'),
            _buildInfoRow('Goles a favor', '${participante['goles_favor']}'),
            _buildInfoRow('Goles en contra', '${participante['goles_contra']}'),
            _buildInfoRow(
              'Diferencia',
              '${participante['diferencia_goles'] > 0 ? '+' : ''}${participante['diferencia_goles']}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VerEquipoUsuarioScreen(
                    ligaId: widget.ligaId,
                    usuarioId: participante['usuario_id'],
                    nombreUsuario: participante['usuario_nombre'],
                    nombreEquipo: participante['equipo_nombre'],
                  ),
                ),
              );
            },
            icon: const Icon(Icons.visibility),
            label: const Text('Ver equipo'),
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
