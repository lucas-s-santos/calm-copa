class Team {
  final String name;
  final String? nameNormalised;
  final String continent;
  final String flagIcon;
  final String fifaCode;
  final String group;
  final String confed;

  const Team({
    required this.name,
    this.nameNormalised,
    required this.continent,
    required this.flagIcon,
    required this.fifaCode,
    required this.group,
    required this.confed,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      name: json['name'] as String,
      nameNormalised: json['name_normalised'] as String?,
      continent: json['continent'] as String,
      flagIcon: json['flag_icon'] as String? ?? '🏳️',
      fifaCode: json['fifa_code'] as String,
      group: json['group'] as String,
      confed: json['confed'] as String,
    );
  }

  String get displayName => nameNormalised ?? name;
}
