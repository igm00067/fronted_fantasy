// ─────────────────────────────────────────────────────────────────────────────
// models/jugador.dart — Modelos Dart para jugadores reales y de plantilla
//
// Jugador: jugador real del mundo del fútbol (tabla jugadores en el backend).
//   Se usa en la pantalla de buscar jugadores, en el mercado, y en el detalle
//   de plantillas. Se crea desde GET /api/jugadores o GET /api/jugadores/buscar.
//
// JugadorEnPlantilla: jugador tal como aparece en el equipo fantasy de un usuario.
//   Incluye campos de plantilla (es_titular, es_capitan, posicion_en_campo).
//   Se crea desde GET /api/ligas/<id>/mi-equipo → lista 'plantilla'.
//
// Relación: JugadorEnPlantilla contiene un Jugador (composición).
//   Ventaja: si necesitas los datos del jugador real, accedes a `.jugador.*`;
//   si necesitas datos de plantilla, accedes directamente al JugadorEnPlantilla.
// ─────────────────────────────────────────────────────────────────────────────

/// Modelo inmutable de un jugador real.
/// Campos de estadísticas son opcionales (pueden ser null si el backend
/// no ha calculado medias aún para ese jugador).
class Jugador {
  final int id;
  final String nombre;
  final String posicion; // POR, DEF, MED, DEL
  final double precio;   // en millones de euros (M)
  final int equipoRealId;
  final String? equipoRealNombre; // join opcional desde el backend
  final String? nacionalidad;
  final String? fotoPerfil;   // URL de imagen del jugador (puede ser null)
  final int? dorsal;
  // Estadísticas medias calculadas por el backend a partir de eventos de partido
  final double? mediaGoles;
  final double? mediaAsistencias;
  final double? mediaTarjetasAmarillas;
  final double? mediaTarjetasRojas;
  final double? mediaPuntos;  // puntos fantasy promedio por partido

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

  /// Deserializa desde el JSON devuelto por GET /api/jugadores o GET /api/jugadores/buscar.
  /// Los campos de estadísticas pueden ser null si el jugador no tiene partidos simulados.
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

  /// Serializa a JSON. Se usa al enviar un jugador como parte de una oferta de chat.
  /// No incluye las estadísticas de media porque no se envían al backend.
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

  /// Envuelve este jugador en un JugadorEnPlantilla con datos de alineación.
  /// Se usa en pantallas donde se necesita mostrar si el jugador es titular/capitán
  /// pero el dato base viene de la lista de jugadores (no del endpoint de plantilla).
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
///
/// Combina los datos del jugador real (Jugador) con la configuración
/// de alineación del usuario en su equipo:
///   - esTitular: si el usuario lo ha puesto en el once inicial
///   - esCapitan: si el usuario lo ha elegido como capitán (×1.5 puntos)
///   - posicionEnCampo: string libre del usuario (ej. "DC", "CAM")
///   - dorsal: número de camiseta asignado en la plantilla
///
/// Se crea desde GET /api/ligas/<id>/mi-equipo (campo 'plantilla')
/// y también desde GET /api/ligas/<id>/equipo/<usuario_id> (ver plantilla rival).
class JugadorEnPlantilla {
  final Jugador jugador;
  final bool esTitular;
  final bool esCapitan;
  final String? posicionEnCampo; // posición táctica en el campo (puede diferir de jugador.posicion)
  final int? dorsal;             // dorsal asignado en el equipo fantasy (puede diferir del real)

  const JugadorEnPlantilla({
    required this.jugador,
    required this.esTitular,
    required this.esCapitan,
    this.posicionEnCampo,
    this.dorsal,
  });

  /// Deserializa desde el JSON de la plantilla.
  /// El JSON incluye tanto los campos del jugador real como los de plantilla
  /// en el mismo objeto plano (flatten), por eso se crea Jugador.fromJson(json)
  /// pasando el mismo mapa que contiene los campos de plantilla.
  factory JugadorEnPlantilla.fromJson(Map<String, dynamic> json) {
    return JugadorEnPlantilla(
      jugador: Jugador.fromJson(json),    // usa los campos del jugador real del mismo mapa
      esTitular: json['es_titular'] as bool? ?? false,
      esCapitan: json['es_capitan'] as bool? ?? false,
      posicionEnCampo: json['posicion_en_campo'] as String?,
      dorsal: json['dorsal'] as int?,
    );
  }
}
