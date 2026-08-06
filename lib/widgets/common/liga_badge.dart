// ─────────────────────────────────────────────────────────────────────────────
// widgets/common/liga_badge.dart — Pastilla de estado de liga
//
// Widget reutilizable para mostrar el estado actual de una liga en forma de badge.
// Se usa en _LigaCard de MisLigasScreen.
//
// Ejemplo de uso:
//   LigaBadge(icon: Icons.play_circle, label: 'En curso', color: Color(0xFF00D084))
//   LigaBadge(icon: Icons.hourglass_empty, label: 'Pendiente', color: AppTheme.secondaryColor)
//   LigaBadge(icon: Icons.flag, label: 'Finalizada', color: Colors.grey)
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

/// Pequeña pastilla con icono + texto para mostrar el estado de una liga.
/// El fondo y el borde usan el color con opacidad reducida para discreción visual.
class LigaBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const LigaBadge({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

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
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
