import 'package:flutter/foundation.dart';
import '../models/match.dart';
import '../services/world_cup_api_service.dart';

// Campeões hardcoded para exibição rápida na lista histórica
const Map<int, Map<String, String>> worldCupInfo = {
  1930: {'champion': 'Uruguai', 'host': 'Uruguai', 'flag': '🇺🇾'},
  1934: {'champion': 'Itália', 'host': 'Itália', 'flag': '🇮🇹'},
  1938: {'champion': 'Itália', 'host': 'França', 'flag': '🇮🇹'},
  1950: {'champion': 'Uruguai', 'host': 'Brasil', 'flag': '🇺🇾'},
  1954: {'champion': 'Alemanha', 'host': 'Suíça', 'flag': '🇩🇪'},
  1958: {'champion': 'Brasil', 'host': 'Suécia', 'flag': '🇧🇷'},
  1962: {'champion': 'Brasil', 'host': 'Chile', 'flag': '🇧🇷'},
  1966: {'champion': 'Inglaterra', 'host': 'Inglaterra', 'flag': '🏴󠁧󠁢󠁥󠁮󠁧󠁿'},
  1970: {'champion': 'Brasil', 'host': 'México', 'flag': '🇧🇷'},
  1974: {'champion': 'Alemanha', 'host': 'Alemanha', 'flag': '🇩🇪'},
  1978: {'champion': 'Argentina', 'host': 'Argentina', 'flag': '🇦🇷'},
  1982: {'champion': 'Itália', 'host': 'Espanha', 'flag': '🇮🇹'},
  1986: {'champion': 'Argentina', 'host': 'México', 'flag': '🇦🇷'},
  1990: {'champion': 'Alemanha', 'host': 'Itália', 'flag': '🇩🇪'},
  1994: {'champion': 'Brasil', 'host': 'EUA', 'flag': '🇧🇷'},
  1998: {'champion': 'França', 'host': 'França', 'flag': '🇫🇷'},
  2002: {'champion': 'Brasil', 'host': 'Japão/Coreia do Sul', 'flag': '🇧🇷'},
  2006: {'champion': 'Itália', 'host': 'Alemanha', 'flag': '🇮🇹'},
  2010: {'champion': 'Espanha', 'host': 'África do Sul', 'flag': '🇪🇸'},
  2014: {'champion': 'Alemanha', 'host': 'Brasil', 'flag': '🇩🇪'},
  2018: {'champion': 'França', 'host': 'Rússia', 'flag': '🇫🇷'},
  2022: {'champion': 'Argentina', 'host': 'Catar', 'flag': '🇦🇷'},
  2026: {'champion': '?', 'host': 'EUA/México/Canadá', 'flag': '🏆'},
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
    if (_errorMap[year] == 'NOT_FOUND') return;
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
