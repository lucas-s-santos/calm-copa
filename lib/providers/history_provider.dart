import 'package:flutter/foundation.dart';
import '../models/match.dart';
import '../services/world_cup_api_service.dart';

// Campeões hardcoded para exibição rápida na lista histórica
const Map<int, Map<String, String>> worldCupInfo = {
  1930: {'champion': 'Uruguay', 'host': 'Uruguay', 'flag': '🇺🇾'},
  1934: {'champion': 'Italy', 'host': 'Italy', 'flag': '🇮🇹'},
  1938: {'champion': 'Italy', 'host': 'France', 'flag': '🇮🇹'},
  1950: {'champion': 'Uruguay', 'host': 'Brazil', 'flag': '🇺🇾'},
  1954: {'champion': 'Germany', 'host': 'Switzerland', 'flag': '🇩🇪'},
  1958: {'champion': 'Brazil', 'host': 'Sweden', 'flag': '🇧🇷'},
  1962: {'champion': 'Brazil', 'host': 'Chile', 'flag': '🇧🇷'},
  1966: {'champion': 'England', 'host': 'England', 'flag': '🏴󠁧󠁢󠁥󠁮󠁧󠁿'},
  1970: {'champion': 'Brazil', 'host': 'Mexico', 'flag': '🇧🇷'},
  1974: {'champion': 'Germany', 'host': 'Germany', 'flag': '🇩🇪'},
  1978: {'champion': 'Argentina', 'host': 'Argentina', 'flag': '🇦🇷'},
  1982: {'champion': 'Italy', 'host': 'Spain', 'flag': '🇮🇹'},
  1986: {'champion': 'Argentina', 'host': 'Mexico', 'flag': '🇦🇷'},
  1990: {'champion': 'Germany', 'host': 'Italy', 'flag': '🇩🇪'},
  1994: {'champion': 'Brazil', 'host': 'USA', 'flag': '🇧🇷'},
  1998: {'champion': 'France', 'host': 'France', 'flag': '🇫🇷'},
  2002: {'champion': 'Brazil', 'host': 'Japan/South Korea', 'flag': '🇧🇷'},
  2006: {'champion': 'Italy', 'host': 'Germany', 'flag': '🇮🇹'},
  2010: {'champion': 'Spain', 'host': 'South Africa', 'flag': '🇪🇸'},
  2014: {'champion': 'Germany', 'host': 'Brazil', 'flag': '🇩🇪'},
  2018: {'champion': 'France', 'host': 'Russia', 'flag': '🇫🇷'},
  2022: {'champion': 'Argentina', 'host': 'Qatar', 'flag': '🇦🇷'},
  2026: {'champion': '?', 'host': 'USA/México/Canadá', 'flag': '🏆'},
};

class HistoryProvider extends ChangeNotifier {
  final WorldCupApiService _api = WorldCupApiService();

  final Map<int, List<Match>> _matchCache = {};
  final Map<int, bool> _loadingMap = {};
  final Map<int, String?> _errorMap = {};

  List<Match> getMatches(int year) => _matchCache[year] ?? [];
  bool isLoading(int year) => _loadingMap[year] ?? false;
  String? getError(int year) => _errorMap[year];

  Future<void> loadYear(int year) async {
    if (_matchCache.containsKey(year)) return;
    _loadingMap[year] = true;
    _errorMap[year] = null;
    notifyListeners();

    try {
      _matchCache[year] = await _api.fetchMatches(year);
    } catch (e) {
      _errorMap[year] = e.toString();
    }

    _loadingMap[year] = false;
    notifyListeners();
  }

  // Agrupa partidas por fase/rodada
  Map<String, List<Match>> groupByRound(int year) {
    final matches = _matchCache[year] ?? [];
    final Map<String, List<Match>> grouped = {};
    for (final m in matches) {
      grouped.putIfAbsent(m.round, () => []).add(m);
    }
    return grouped;
  }

  // Retorna os top artilheiros de uma copa
  List<Map<String, dynamic>> getTopScorers(int year) {
    final matches = _matchCache[year] ?? [];
    final Map<String, int> scorers = {};
    for (final m in matches) {
      for (final g in m.goals1) {
        if (!g.ownGoal) {
          scorers[g.name] = (scorers[g.name] ?? 0) + 1;
        }
      }
      for (final g in m.goals2) {
        if (!g.ownGoal) {
          scorers[g.name] = (scorers[g.name] ?? 0) + 1;
        }
      }
    }
    final list = scorers.entries
        .map((e) => {'name': e.key, 'goals': e.value})
        .toList()
      ..sort((a, b) => (b['goals'] as int).compareTo(a['goals'] as int));
    return list.take(10).toList();
  }

  // Estatísticas globais: títulos por país
  Map<String, int> get titlesByCountry {
    final Map<String, int> titles = {};
    for (final info in worldCupInfo.values) {
      final champ = info['champion']!;
      if (champ == '?') continue;
      titles[champ] = (titles[champ] ?? 0) + 1;
    }
    return titles;
  }

  // Gols por edição (necessita que as copas estejam carregadas)
  Map<int, int> get goalsByYear {
    final Map<int, int> goals = {};
    for (final entry in _matchCache.entries) {
      int total = 0;
      for (final m in entry.value) {
        if (m.score?.hasResult == true) {
          total += m.score!.ft[0] + m.score!.ft[1];
        }
      }
      if (total > 0) goals[entry.key] = total;
    }
    return goals;
  }

  // Artilheiros históricos (todas as copas carregadas)
  List<Map<String, dynamic>> get allTimeTopScorers {
    final Map<String, int> scorers = {};
    for (final matches in _matchCache.values) {
      for (final m in matches) {
        for (final g in [...m.goals1, ...m.goals2]) {
          if (!g.ownGoal) {
            scorers[g.name] = (scorers[g.name] ?? 0) + 1;
          }
        }
      }
    }
    final list = scorers.entries
        .map((e) => {'name': e.key, 'goals': e.value})
        .toList()
      ..sort((a, b) => (b['goals'] as int).compareTo(a['goals'] as int));
    return list.take(10).toList();
  }

  // Carrega copas ricas em dados para estatísticas (com artilheiros)
  Future<void> loadStatsYears() async {
    final richYears = [2014, 2018, 2022, 2006, 2010, 2002, 1998, 1994, 1990, 1986];
    await Future.wait(richYears.map(loadYear));
  }
}
