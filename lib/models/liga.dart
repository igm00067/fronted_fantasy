class Liga {
  final int id;
  final String nombre;
  final String estado; // 'esperando', 'en_curso', 'finalizada'
  final int competicionId;
  final int creadorId;
  final int maxParticipantes;
  final int numParticipantes;
  final double presupuestoInicial;
  final int maxJugadoresPorEquipo;
  final String codigoInvitacion;

  const Liga({
    required this.id,
    required this.nombre,
    required this.estado,
    required this.competicionId,
    required this.creadorId,
    required this.maxParticipantes,
    required this.numParticipantes,
    required this.presupuestoInicial,
    required this.maxJugadoresPorEquipo,
    required this.codigoInvitacion,
  });

  factory Liga.fromJson(Map<String, dynamic> json) {
    return Liga(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      estado: json['estado'] as String? ?? 'esperando',
      competicionId: json['competicion_id'] as int,
      creadorId: json['creador_id'] as int,
      maxParticipantes: json['max_participantes'] as int? ?? 10,
      numParticipantes: json['num_participantes'] as int? ?? 0,
      presupuestoInicial: (json['presupuesto_inicial'] as num?)?.toDouble() ?? 100.0,
      maxJugadoresPorEquipo: json['max_jugadores_por_equipo'] as int? ?? 24,
      codigoInvitacion: json['codigo_invitacion'] as String? ?? '',
    );
  }

  bool get estaEsperando => estado == 'esperando';
  bool get estaEnCurso => estado == 'en_curso';
  bool get estaFinalizada => estado == 'finalizada';
  bool get estaLlena => numParticipantes >= maxParticipantes;
}

class EquipoFantasy {
  final int id;
  final String nombre;
  final double saldoDisponible;
  final int puntosTotales;
  final int usuarioId;
  final int ligaId;
  final String? formacion;

  const EquipoFantasy({
    required this.id,
    required this.nombre,
    required this.saldoDisponible,
    required this.puntosTotales,
    required this.usuarioId,
    required this.ligaId,
    this.formacion,
  });

  factory EquipoFantasy.fromJson(Map<String, dynamic> json) {
    return EquipoFantasy(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      saldoDisponible: (json['saldo_disponible'] as num?)?.toDouble() ?? 0.0,
      puntosTotales: json['puntos_totales'] as int? ?? 0,
      usuarioId: json['usuario_id'] as int,
      ligaId: json['liga_id'] as int,
      formacion: json['formacion'] as String?,
    );
  }
}
