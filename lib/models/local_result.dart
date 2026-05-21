class LocalResult {
  final String matchKey;
  final int score1;
  final int score2;

  const LocalResult({
    required this.matchKey,
    required this.score1,
    required this.score2,
  });

  String get displayScore => '$score1 x $score2';
}
