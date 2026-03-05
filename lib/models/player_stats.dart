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
