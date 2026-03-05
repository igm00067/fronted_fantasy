class TeamModel {
  final String id;
  final String name;
  final String code; // BAR, RMA, ATM, etc.
  final String logoUrl;
  final String stadium;
  final List<String> playerIds;

  TeamModel({
    required this.id,
    required this.name,
    required this.code,
    required this.logoUrl,
    required this.stadium,
    this.playerIds = const [],
  });

  factory TeamModel.fromFirestore(Map<String, dynamic> data, String id) {
    return TeamModel(
      id: id,
      name: data['name'] ?? '',
      code: data['code'] ?? '',
      logoUrl: data['logoUrl'] ?? '',
      stadium: data['stadium'] ?? '',
      playerIds: List<String>.from(data['playerIds'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'code': code,
      'logoUrl': logoUrl,
      'stadium': stadium,
      'playerIds': playerIds,
    };
  }
}