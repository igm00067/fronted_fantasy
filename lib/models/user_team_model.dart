class UserTeamModel {
  final String userId;
  final List<String> playerIds; // 11 titulares + 4 suplentes = 15
  final String? captainId;
  final String? viceCaptainId;
  final String formation; // "4-3-3", "4-4-2", etc.
  final double budget; // Dinero restante
  final int totalPoints;
  final int weekPoints;
  final Map<String, bool> chipsUsed; // bench_boost, free_hit, triple_captain, wildcard

  UserTeamModel({
    required this.userId,
    this.playerIds = const [],
    this.captainId,
    this.viceCaptainId,
    this.formation = '4-3-3',
    this.budget = 100.0,
    this.totalPoints = 0,
    this.weekPoints = 0,
    Map<String, bool>? chipsUsed,
  }) : chipsUsed = chipsUsed ?? {
    'bench_boost': false,
    'free_hit': false,
    'triple_captain': false,
    'wildcard': false,
  };

  factory UserTeamModel.fromFirestore(Map<String, dynamic> data, String userId) {
    return UserTeamModel(
      userId: userId,
      playerIds: List<String>.from(data['playerIds'] ?? []),
      captainId: data['captainId'],
      viceCaptainId: data['viceCaptainId'],
      formation: data['formation'] ?? '4-3-3',
      budget: (data['budget'] ?? 100.0).toDouble(),
      totalPoints: data['totalPoints'] ?? 0,
      weekPoints: data['weekPoints'] ?? 0,
      chipsUsed: Map<String, bool>.from(data['chipsUsed'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'playerIds': playerIds,
      'captainId': captainId,
      'viceCaptainId': viceCaptainId,
      'formation': formation,
      'budget': budget,
      'totalPoints': totalPoints,
      'weekPoints': weekPoints,
      'chipsUsed': chipsUsed,
    };
  }

  bool get hasUsedChip => chipsUsed.values.any((used) => used);
  int get playersCount => playerIds.length;
  bool get isComplete => playersCount == 15;
}