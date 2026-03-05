class PlayerStats {
  final int pace;
  final int shooting;
  final int passing;
  final int dribbling;
  final int defending;
  final int physical;

  const PlayerStats({
    required this.pace,
    required this.shooting,
    required this.passing,
    required this.dribbling,
    required this.defending,
    required this.physical,
  });

  factory PlayerStats.fromMap(Map<String, dynamic> data) {
    return PlayerStats(
      pace: data['pace'] as int? ?? 50,
      shooting: data['shooting'] as int? ?? 50,
      passing: data['passing'] as int? ?? 50,
      dribbling: data['dribbling'] as int? ?? 50,
      defending: data['defending'] as int? ?? 50,
      physical: data['physical'] as int? ?? 50,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pace': pace,
      'shooting': shooting,
      'passing': passing,
      'dribbling': dribbling,
      'defending': defending,
      'physical': physical,
    };
  }
}

class PlayerModel {
  final String id;
  final String name;
  final String photoUrl;
  final String team;
  final String teamCode; // BAR, RMA, etc.
  final String teamLogoUrl;
  final String position; // GK, DEF, MID, FWD
  final int overall; // Rating 1-99
  final double price; // Precio en millones
  final PlayerStats stats;
  final int totalPoints;
  final int weekPoints;
  final bool isInjured;
  final bool isSuspended;
  final List<String> upcomingMatches;

  PlayerModel({
    required this.id,
    required this.name,
    required this.photoUrl,
    required this.team,
    required this.teamCode,
    required this.teamLogoUrl,
    required this.position,
    required this.overall,
    required this.price,
    required this.stats,
    this.totalPoints = 0,
    this.weekPoints = 0,
    this.isInjured = false,
    this.isSuspended = false,
    this.upcomingMatches = const [],
  });

  // Convertir desde Firestore
  factory PlayerModel.fromFirestore(Map<String, dynamic> data, String id) {
    return PlayerModel(
      id: id,
      name: data['name'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      team: data['team'] ?? '',
      teamCode: data['teamCode'] ?? '',
      teamLogoUrl: data['teamLogoUrl'] ?? '',
      position: data['position'] ?? 'MID',
      overall: data['overall'] ?? 70,
      price: (data['price'] ?? 0.0).toDouble(),
      stats: PlayerStats.fromMap(data['stats'] ?? {}),
      totalPoints: data['totalPoints'] ?? 0,
      weekPoints: data['weekPoints'] ?? 0,
      isInjured: data['isInjured'] ?? false,
      isSuspended: data['isSuspended'] ?? false,
      upcomingMatches: List<String>.from(data['upcomingMatches'] ?? []),
    );
  }

  // Convertir a Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'photoUrl': photoUrl,
      'team': team,
      'teamCode': teamCode,
      'teamLogoUrl': teamLogoUrl,
      'position': position,
      'overall': overall,
      'price': price,
      'stats': stats.toMap(),
      'totalPoints': totalPoints,
      'weekPoints': weekPoints,
      'isInjured': isInjured,
      'isSuspended': isSuspended,
      'upcomingMatches': upcomingMatches,
    };
  }

  // Copiar con modificaciones
  PlayerModel copyWith({
    String? name,
    String? photoUrl,
    int? totalPoints,
    int? weekPoints,
    bool? isInjured,
    bool? isSuspended,
  }) {
    return PlayerModel(
      id: id,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      team: team,
      teamCode: teamCode,
      teamLogoUrl: teamLogoUrl,
      position: position,
      overall: overall,
      price: price,
      stats: stats,
      totalPoints: totalPoints ?? this.totalPoints,
      weekPoints: weekPoints ?? this.weekPoints,
      isInjured: isInjured ?? this.isInjured,
      isSuspended: isSuspended ?? this.isSuspended,
      upcomingMatches: upcomingMatches,
    );
  }
}