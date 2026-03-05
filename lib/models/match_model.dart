class MatchModel {
  final String id;
  final String homeTeamId;
  final String awayTeamId;
  final String homeTeamName;
  final String awayTeamName;
  final DateTime matchDate;
  final int gameweek;
  final int? homeScore;
  final int? awayScore;
  final String status; // scheduled, live, finished
  final String venue;

  MatchModel({
    required this.id,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.matchDate,
    required this.gameweek,
    this.homeScore,
    this.awayScore,
    this.status = 'scheduled',
    required this.venue,
  });

  factory MatchModel.fromFirestore(Map<String, dynamic> data, String id) {
    return MatchModel(
      id: id,
      homeTeamId: data['homeTeamId'] ?? '',
      awayTeamId: data['awayTeamId'] ?? '',
      homeTeamName: data['homeTeamName'] ?? '',
      awayTeamName: data['awayTeamName'] ?? '',
      matchDate: DateTime.parse(data['matchDate']),
      gameweek: data['gameweek'] ?? 1,
      homeScore: data['homeScore'],
      awayScore: data['awayScore'],
      status: data['status'] ?? 'scheduled',
      venue: data['venue'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'homeTeamId': homeTeamId,
      'awayTeamId': awayTeamId,
      'homeTeamName': homeTeamName,
      'awayTeamName': awayTeamName,
      'matchDate': matchDate.toIso8601String(),
      'gameweek': gameweek,
      'homeScore': homeScore,
      'awayScore': awayScore,
      'status': status,
      'venue': venue,
    };
  }

  bool get isLive => status == 'live';
  bool get isFinished => status == 'finished';
  bool get isScheduled => status == 'scheduled';
}