import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/match.dart';
import '../services/world_cup_api_service.dart';

const _weightedScores = [
  [1, 0], [0, 1], [2, 1], [1, 2], [2, 0], [0, 2], [1, 1],
  [3, 1], [1, 3], [3, 0], [0, 3], [2, 2], [3, 2], [2, 3],
  [4, 0], [0, 4], [4, 1], [1, 4],
];
const _weights = [12, 12, 9, 9, 8, 8, 7, 5, 5, 4, 4, 3, 2, 2, 1, 1, 1, 1];
const _weightsNoTie = [13, 13, 10, 10, 9, 9, 6, 6, 5, 5, 3, 3, 1, 1, 1, 1];

class SimulatorProvider extends ChangeNotifier {
  final WorldCupApiService _api = WorldCupApiService();

  List<Match> _matches = [];
  final Map<String, List<int>> _results = {}; // matchKey -> [s1, s2]

  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;
  bool get isLoaded => _matches.isNotEmpty;

  List<Match> get allMatches => _matches;

  List<Match> get groupMatches =>
      _matches.where((m) => m.group != null).toList();

  List<Match> get knockoutMatches =>
      _matches.where((m) => m.group == null).toList();

  List<Match> get roundOf32 =>
      _matches.where((m) => m.round == 'Round of 32').toList();

  List<Match> get roundOf16 =>
      _matches.where((m) => m.round == 'Round of 16').toList();

  List<Match> get quarterFinals =>
      _matches.where((m) => m.round == 'Quarter-final').toList();

  List<Match> get semiFinals =>
      _matches.where((m) => m.round == 'Semi-final').toList();

  List<Match> get thirdPlace =>
      _matches.where((m) => m.round == 'Match for third place').toList();

  List<Match> get final_ =>
      _matches.where((m) => m.round == 'Final').toList();

  // ── Data Loading ──────────────────────────────────────────────────────────

  Future<void> load() async {
    if (_matches.isNotEmpty) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _matches = await _api.fetchMatches(2026);
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  // ── Results ───────────────────────────────────────────────────────────────

  List<int>? getResult(String matchKey) => _results[matchKey];

  bool hasResult(String matchKey) => _results.containsKey(matchKey);

  void setResult(Match match, int s1, int s2) {
    _results[match.matchKey] = [s1, s2];
    notifyListeners();
  }

  void removeResult(String matchKey) {
    _results.remove(matchKey);
    notifyListeners();
  }

  void resetAll() {
    _results.clear();
    notifyListeners();
  }

  void resetGroups() {
    for (final m in groupMatches) {
      _results.remove(m.matchKey);
    }
    notifyListeners();
  }

  // ── Auto-Simulate ─────────────────────────────────────────────────────────

  void autoSimulateGroups() {
    for (final m in groupMatches) {
      if (!hasResult(m.matchKey)) {
        _results[m.matchKey] = _randomScore();
      }
    }
    notifyListeners();
  }

  void autoSimulateAllGroups() {
    for (final m in groupMatches) {
      _results[m.matchKey] = _randomScore();
    }
    notifyListeners();
  }

  void autoSimulateKnockout() {
    final rounds = [
      roundOf32, roundOf16, quarterFinals, semiFinals, thirdPlace, final_
    ];
    for (final round in rounds) {
      for (final m in round) {
        if (!hasResult(m.matchKey)) {
          _results[m.matchKey] = _randomScore(canDraw: false);
        }
      }
    }
    notifyListeners();
  }

  void autoSimulateAll() {
    autoSimulateAllGroups();
    for (final m in knockoutMatches) {
      _results[m.matchKey] = _randomScore(canDraw: false);
    }
    notifyListeners();
  }

  // ── Standings ─────────────────────────────────────────────────────────────

  /// Returns group standings: groupName -> sorted list of team stats
  Map<String, List<Map<String, dynamic>>> computeAllStandings() {
    final Map<String, Map<String, Map<String, int>>> raw = {};

    for (final m in groupMatches) {
      final g = m.group!;
      raw.putIfAbsent(g, () => {});
      raw[g]!.putIfAbsent(m.team1, () => _emptyStats());
      raw[g]!.putIfAbsent(m.team2, () => _emptyStats());

      final result = _results[m.matchKey];
      if (result == null) continue;

      final s1 = result[0], s2 = result[1];
      _applyResult(raw[g]!, m.team1, m.team2, s1, s2);
    }

    final standings = <String, List<Map<String, dynamic>>>{};
    for (final entry in raw.entries) {
      standings[entry.key] = _sortGroup(entry.value);
    }
    return standings;
  }

  Map<String, int> _emptyStats() =>
      {'pts': 0, 'pj': 0, 'v': 0, 'e': 0, 'd': 0, 'gp': 0, 'gc': 0};

  void _applyResult(Map<String, Map<String, int>> g, String t1, String t2,
      int s1, int s2) {
    g[t1]!['pj'] = g[t1]!['pj']! + 1;
    g[t2]!['pj'] = g[t2]!['pj']! + 1;
    g[t1]!['gp'] = g[t1]!['gp']! + s1;
    g[t1]!['gc'] = g[t1]!['gc']! + s2;
    g[t2]!['gp'] = g[t2]!['gp']! + s2;
    g[t2]!['gc'] = g[t2]!['gc']! + s1;

    if (s1 > s2) {
      g[t1]!['pts'] = g[t1]!['pts']! + 3;
      g[t1]!['v'] = g[t1]!['v']! + 1;
      g[t2]!['d'] = g[t2]!['d']! + 1;
    } else if (s1 == s2) {
      g[t1]!['pts'] = g[t1]!['pts']! + 1;
      g[t2]!['pts'] = g[t2]!['pts']! + 1;
      g[t1]!['e'] = g[t1]!['e']! + 1;
      g[t2]!['e'] = g[t2]!['e']! + 1;
    } else {
      g[t2]!['pts'] = g[t2]!['pts']! + 3;
      g[t2]!['v'] = g[t2]!['v']! + 1;
      g[t1]!['d'] = g[t1]!['d']! + 1;
    }
  }

  List<Map<String, dynamic>> _sortGroup(
      Map<String, Map<String, int>> group) {
    final list = group.entries.map((e) {
      final sg = e.value['gp']! - e.value['gc']!;
      return {'team': e.key, ...e.value, 'sg': sg};
    }).toList();
    list.sort((a, b) {
      int c = (b['pts'] as int).compareTo(a['pts'] as int);
      if (c != 0) return c;
      c = (b['sg'] as int).compareTo(a['sg'] as int);
      if (c != 0) return c;
      return (b['gp'] as int).compareTo(a['gp'] as int);
    });
    return list;
  }

  // ── Team Code Resolution ──────────────────────────────────────────────────

  /// Resolves a bracket team code to an actual team name.
  /// - "1A" → 1st place Group A
  /// - "2B" → 2nd place Group B
  /// - "3A/B/C/D/F" → best 3rd-place from those groups
  /// - "W73" → winner of match 73
  /// - "L101" → loser of match 101
  String resolveCode(String code) {
    // Winner of a match
    final wMatch = RegExp(r'^W(\d+)$').firstMatch(code);
    if (wMatch != null) {
      final num = int.parse(wMatch.group(1)!);
      return _matchWinner(num) ?? 'W$num';
    }

    // Loser of a match
    final lMatch = RegExp(r'^L(\d+)$').firstMatch(code);
    if (lMatch != null) {
      final num = int.parse(lMatch.group(1)!);
      return _matchLoser(num) ?? 'L$num';
    }

    // Position + group: "1A", "2B", etc.
    final posGroup = RegExp(r'^([12])([A-L])$').firstMatch(code);
    if (posGroup != null) {
      final pos = int.parse(posGroup.group(1)!) - 1;
      final groupLetter = posGroup.group(2)!;
      final standings = computeAllStandings();
      final groupStandings = standings['Group $groupLetter'];
      if (groupStandings != null && pos < groupStandings.length) {
        return groupStandings[pos]['team'] as String;
      }
      return code;
    }

    // 3rd-place slot: "3A/B/C/D/F"
    if (code.startsWith('3')) {
      return _resolveBest3rd(code) ?? code;
    }

    return code;
  }

  String? _matchWinner(int matchNum) {
    final match = _matchByNum(matchNum);
    if (match == null) return null;
    final result = _results[match.matchKey];
    if (result == null) return null;
    // Resolve the team codes of the match first
    final t1 = resolveCode(match.team1);
    final t2 = resolveCode(match.team2);
    return result[0] >= result[1] ? t1 : t2;
  }

  String? _matchLoser(int matchNum) {
    final match = _matchByNum(matchNum);
    if (match == null) return null;
    final result = _results[match.matchKey];
    if (result == null) return null;
    final t1 = resolveCode(match.team1);
    final t2 = resolveCode(match.team2);
    return result[0] >= result[1] ? t2 : t1;
  }

  Match? _matchByNum(int num) {
    try {
      return _matches.firstWhere((m) => m.num == num);
    } catch (_) {
      return null;
    }
  }

  // Track which 3rd-place teams have been assigned (to avoid duplicates)
  final Set<String> _assigned3rd = {};

  String? _resolveBest3rd(String code) {
    // Parse allowed groups from "3A/B/C/D/F"
    final letters = code.substring(1).split('/');
    final allowedGroups = letters.map((l) => 'Group $l').toSet();

    final standings = computeAllStandings();
    final candidates = <Map<String, dynamic>>[];

    for (final entry in standings.entries) {
      if (!allowedGroups.contains(entry.key)) continue;
      if (entry.value.length >= 3) {
        final third = Map<String, dynamic>.from(entry.value[2]);
        third['group'] = entry.key;
        candidates.add(third);
      }
    }

    // Sort: pts desc, sg desc, gp desc
    candidates.sort((a, b) {
      int c = (b['pts'] as int).compareTo(a['pts'] as int);
      if (c != 0) return c;
      c = (b['sg'] as int).compareTo(a['sg'] as int);
      if (c != 0) return c;
      return (b['gp'] as int).compareTo(a['gp'] as int);
    });

    // Find first unassigned
    for (final c in candidates) {
      final team = c['team'] as String;
      if (!_assigned3rd.contains(team)) {
        _assigned3rd.add(team);
        return team;
      }
    }

    return candidates.isNotEmpty ? candidates.first['team'] as String : null;
  }

  /// Clears the 3rd-place assignment cache (call before resolving bracket).
  void reset3rdAssignment() => _assigned3rd.clear();

  // ── Projected champion & results ──────────────────────────────────────────

  String? get projectedChampion {
    if (final_.isEmpty) return null;
    final f = final_.first;
    final result = _results[f.matchKey];
    if (result == null) return null;
    final t1 = resolveCode(f.team1);
    final t2 = resolveCode(f.team2);
    return result[0] >= result[1] ? t1 : t2;
  }

  int get simulatedGroupMatches =>
      groupMatches.where((m) => hasResult(m.matchKey)).length;

  int get totalGroupMatches => groupMatches.length;

  bool get allGroupsSimulated =>
      simulatedGroupMatches == totalGroupMatches;

  /// Public single-match random score (used by UI buttons)
  List<int> autoSimulateKnockoutMatch({bool canDraw = false}) =>
      _randomScore(canDraw: canDraw);

  // ── Random Score ──────────────────────────────────────────────────────────

  List<int> _randomScore({bool canDraw = true}) {
    final scores = canDraw
        ? _weightedScores
        : _weightedScores.where((s) => s[0] != s[1]).toList();
    final weights = canDraw ? _weights : _weightsNoTie;

    final total = weights.reduce((a, b) => a + b);
    int r = Random().nextInt(total);
    int cumulative = 0;
    for (int i = 0; i < scores.length; i++) {
      cumulative += weights[i];
      if (r < cumulative) return [...scores[i]];
    }
    return [1, 0];
  }
}
