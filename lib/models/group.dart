class Group {
  final String name;
  final List<String> teams;

  const Group({required this.name, required this.teams});

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      name: json['name'] as String,
      teams: (json['teams'] as List).map((t) => t as String).toList(),
    );
  }
}

class GroupStanding {
  final String team;
  final String flag;
  int points;
  int played;
  int won;
  int drawn;
  int lost;
  int goalsFor;
  int goalsAgainst;

  GroupStanding({
    required this.team,
    this.flag = '',
    this.points = 0,
    this.played = 0,
    this.won = 0,
    this.drawn = 0,
    this.lost = 0,
    this.goalsFor = 0,
    this.goalsAgainst = 0,
  });

  int get goalDiff => goalsFor - goalsAgainst;
}
