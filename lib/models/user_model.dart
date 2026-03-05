class UserModel {
  final String id;
  final String email;
  final String username;
  final String? photoUrl;
  final DateTime createdAt;
  final List<String> leagueIds;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    this.photoUrl,
    required this.createdAt,
    this.leagueIds = const [],
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      photoUrl: data['photoUrl'],
      createdAt: DateTime.parse(data['createdAt']),
      leagueIds: List<String>.from(data['leagueIds'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'username': username,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'leagueIds': leagueIds,
    };
  }
}