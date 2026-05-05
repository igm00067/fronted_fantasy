class Jugador {
  final int id;
  final String nombre;
  final String posicion; // POR, DEF, MED, DEL
  final double precio;
  final int equipoRealId;
  final String? equipoRealNombre;
  final String? nacionalidad;
  final String? fotoPerfil;
  final int? dorsal;
  // Stats
  final double? mediaGoles;
  final double? mediaAsistencias;
  final double? mediaTarjetasAmarillas;
  final double? mediaTarjetasRojas;
  final double? mediaPuntos;

  const Jugador({
    required this.id,
    required this.nombre,
    required this.posicion,
    required this.precio,
    required this.equipoRealId,
    this.equipoRealNombre,
    this.nacionalidad,
    this.fotoPerfil,
    this.dorsal,
    this.mediaGoles,
    this.mediaAsistencias,
    this.mediaTarjetasAmarillas,
    this.mediaTarjetasRojas,
    this.mediaPuntos,
  });

  factory Jugador.fromJson(Map<String, dynamic> json) {
    return Jugador(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      posicion: json['posicion'] as String,
      precio: (json['precio'] as num).toDouble(),
      equipoRealId: json['equipo_real_id'] as int,
      equipoRealNombre: json['equipo_real_nombre'] as String?,
      nacionalidad: json['nacionalidad'] as String?,
      fotoPerfil: json['foto_perfil_url'] as String?,
      dorsal: json['dorsal'] as int?,
      mediaGoles: (json['media_goles'] as num?)?.toDouble(),
      mediaAsistencias: (json['media_asistencias'] as num?)?.toDouble(),
      mediaTarjetasAmarillas: (json['media_tarjetas_amarillas'] as num?)?.toDouble(),
      mediaTarjetasRojas: (json['media_tarjetas_rojas'] as num?)?.toDouble(),
      mediaPuntos: (json['media_puntos'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'posicion': posicion,
    'precio': precio,
    'equipo_real_id': equipoRealId,
    'equipo_real_nombre': equipoRealNombre,
    'nacionalidad': nacionalidad,
    'foto_perfil_url': fotoPerfil,
    'dorsal': dorsal,
  };

  // Crea una copia de este jugador con campos de plantilla incluidos
  JugadorEnPlantilla conInfoPlantilla({
    required bool esTitular,
    required bool esCapitan,
    String? posicionEnCampo,
    int? dorsalPlantilla,
  }) => JugadorEnPlantilla(
    jugador: this,
    esTitular: esTitular,
    esCapitan: esCapitan,
    posicionEnCampo: posicionEnCampo,
    dorsal: dorsalPlantilla,
  );
}

/// Jugador tal como aparece en una plantilla de equipo fantasy.
class JugadorEnPlantilla {
  final Jugador jugador;
  final bool esTitular;
  final bool esCapitan;
  final String? posicionEnCampo;
  final int? dorsal;

  const JugadorEnPlantilla({
    required this.jugador,
    required this.esTitular,
    required this.esCapitan,
    this.posicionEnCampo,
    this.dorsal,
  });

  factory JugadorEnPlantilla.fromJson(Map<String, dynamic> json) {
    return JugadorEnPlantilla(
      jugador: Jugador.fromJson(json),
      esTitular: json['es_titular'] as bool? ?? false,
      esCapitan: json['es_capitan'] as bool? ?? false,
      posicionEnCampo: json['posicion_en_campo'] as String?,
      dorsal: json['dorsal'] as int?,
    );
  }
}
