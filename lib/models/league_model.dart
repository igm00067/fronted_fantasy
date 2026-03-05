class LeagueModel {
  final String id;
  final String name;
  final String code; // Código para unirse
  final String adminId;
  final List<String> memberIds;
  final DateTime createdAt;
  final bool isPublic;
  final int maxMembers;

  LeagueModel({
    required this.id,
    required this.name,
    required this.code,
    required this.adminId,
    this.memberIds = const [],
    required this.createdAt,
    this.isPublic = false,
    this.maxMembers = 20,
  });

  factory LeagueModel.fromFirestore(Map<String, dynamic> data, String id) {
    return LeagueModel(
      id: id,
      name: data['name'] ?? '',
      code: data['code'] ?? '',
      adminId: data['adminId'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      createdAt: DateTime.parse(data['createdAt']),
      isPublic: data['isPublic'] ?? false,
      maxMembers: data['maxMembers'] ?? 20,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'code': code,
      'adminId': adminId,
      'memberIds': memberIds,
      'createdAt': createdAt.toIso8601String(),
      'isPublic': isPublic,
      'maxMembers': maxMembers,
    };
  }

  bool get isFull => memberIds.length >= maxMembers;
  int get membersCount => memberIds.length;
}