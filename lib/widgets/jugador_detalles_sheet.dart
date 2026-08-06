// ─────────────────────────────────────────────────────────────────────────────
// widgets/jugador_detalles_sheet.dart — Bottom sheet de detalles de un jugador
//
// Función global que abre un DraggableScrollableSheet con información completa:
//   - Cabecera con gradiente por posición (POR=verde, DEF=azul, MED=naranja, DEL=rojo)
//   - Media FIFA del jugador (calculada por el backend con pesos por posición)
//   - Atributos FIFA: velocidad, tiro, pase, regate, defensa, físico (hexágono visual)
//   - Estadísticas de partido: medias de goles, asistencias, tarjetas, puntos
//   - Precio en el mercado
//
// Se llama desde múltiples pantallas:
//   MercadoScreen, MiEquipoScreen, BuscarJugadoresScreen, VerEquipoUsuarioScreen
//
// El jugador se pasa como Map<String, dynamic> (no como objeto Jugador)
// porque en muchos contextos viene directamente del JSON del backend sin parsear.
//
// Color por posición (también usado en _colorPosicion):
//   POR → verde   DEF → azul   MED → naranja/ámbar   DEL → rojo
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Abre el bottom sheet de detalles completos de un jugador.
/// Funciona desde cualquier pantalla que tenga un BuildContext disponible.
void mostrarDetallesJugador(
    BuildContext context, Map<String, dynamic> jugador) {
  final posicion = jugador['posicion'] as String? ?? '';
  final colorPos = _colorPosicion(posicion);
  final media = (jugador['media_fifa'] as num?)?.toInt() ?? 0;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Cabecera ──
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [colorPos, colorPos.withOpacity(0.6)],
                  ),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    // Pastilla de arrastre
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.white38,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Row(
                      children: [
                        // Badge media + posición
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$media',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                posicion,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                jugador['nombre'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                jugador['nacionalidad'] ?? '',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 13),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _infoBadge(Icons.cake,
                                      '${jugador['edad'] ?? '-'} años'),
                                  const SizedBox(width: 8),
                                  _infoBadge(Icons.monetization_on,
                                      '${jugador['precio'] ?? '-'}M'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Stats ──
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ESTADÍSTICAS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _statBar('Velocidad', jugador['velocidad'], Colors.cyan),
                    _statBar('Tiro', jugador['tiro'], Colors.red),
                    _statBar('Pase', jugador['pase'], Colors.blue),
                    _statBar('Regate', jugador['regate'], Colors.purple),
                    _statBar('Defensa', jugador['defensa'], Colors.teal),
                    _statBar('Físico', jugador['fisico'], Colors.orange),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: colorPos.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: colorPos.withOpacity(0.4), width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'MEDIA GLOBAL',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            '$media',
                            style: TextStyle(
                              color: colorPos,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _infoBadge(IconData icon, String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.black26,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.white70),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    ),
  );
}

Widget _statBar(String label, dynamic valor, Color color) {
  final v = (valor as num?)?.toInt() ?? 0;
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(
                fontSize: 13, color: AppTheme.textSecondaryColor),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: v / 100,
              minHeight: 8,
              backgroundColor: AppTheme.borderColor,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 28,
          child: Text(
            '$v',
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
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
