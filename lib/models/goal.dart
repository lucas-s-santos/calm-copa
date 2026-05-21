class Goal {
  final String name;
  final int minute;
  final int? offset;
  final bool penalty;
  final bool ownGoal;

  const Goal({
    required this.name,
    required this.minute,
    this.offset,
    this.penalty = false,
    this.ownGoal = false,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      name: json['name'] as String,
      minute: json['minute'] as int,
      offset: json['offset'] as int?,
      penalty: json['penalty'] == true,
      ownGoal: json['owngoal'] == true,
    );
  }

  String get displayMinute =>
      offset != null ? "$minute+$offset'" : "$minute'";

  String get icon => ownGoal ? '🥅' : (penalty ? '⚽(P)' : '⚽');
}
