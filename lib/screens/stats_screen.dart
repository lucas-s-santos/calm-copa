import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/history_provider.dart';
import '../utils/team_flags.dart';
import '../utils/team_names_pt.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<HistoryProvider>().loadStatsYears();
      if (mounted) setState(() => _loaded = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HistoryProvider>();
    final titles = provider.titlesByCountry;
    final goalsByYear = provider.goalsByYear;
    final sortedTitles = titles.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: const Color(0xFF0D1A0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A472A),
        title: const Text('📊 Estatísticas',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: !_loaded
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFFFD700)),
                  SizedBox(height: 16),
                  Text('Carregando dados históricos...',
                      style: TextStyle(color: Colors.white54)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Cards resumo ──────────────────────────────────────────
                _SummaryCards(stats: provider.globalStats),
                const SizedBox(height: 24),

                // ── Títulos por País ──────────────────────────────────────
                _SectionTitle(title: '🏆 Títulos por País'),
                const SizedBox(height: 8),
                Container(
                  height: 280,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2D1E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: (sortedTitles.first.value + 1).toDouble(),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final country = sortedTitles[groupIndex].key;
                            return BarTooltipItem(
                              '$country\n${rod.toY.toInt()} título(s)',
                              const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= sortedTitles.length) {
                                return const SizedBox();
                              }
                              final flag =
                                  _champFlag(sortedTitles[idx].key);
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(flag,
                                    style: const TextStyle(fontSize: 18)),
                              );
                            },
                            reservedSize: 36,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, meta) => Text(
                              '${value.toInt()}',
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 11),
                            ),
                            reservedSize: 24,
                          ),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        getDrawingHorizontalLine: (_) =>
                            FlLine(color: Colors.white12, strokeWidth: 1),
                        drawVerticalLine: false,
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: sortedTitles.asMap().entries.map((e) {
                        return BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: e.value.value.toDouble(),
                              color: const Color(0xFFFFD700),
                              width: 22,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4)),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Gols por Edição ───────────────────────────────────────
                if (goalsByYear.isNotEmpty) ...[
                  _SectionTitle(title: '⚽ Gols por Edição'),
                  const SizedBox(height: 8),
                  Container(
                    height: 220,
                    padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2D1E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _GoalsLineChart(goalsByYear: goalsByYear),
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Artilheiros Históricos ────────────────────────────────
                if (provider.allTimeTopScorers.isNotEmpty) ...[
                  _SectionTitle(title: '🥇 Artilheiros Históricos'),
                  const SizedBox(height: 8),
                  _TopScorersCard(scorers: provider.allTimeTopScorers),
                  const SizedBox(height: 24),
                ],

                // ── Jogos mais Goleados ───────────────────────────────────
                if (provider.highestScoringMatches.isNotEmpty) ...[
                  _SectionTitle(title: '🔥 Jogos mais Goleados'),
                  const SizedBox(height: 8),
                  _HighScoringCard(matches: provider.highestScoringMatches),
                  const SizedBox(height: 24),
                ],

                // ── Países com mais Participações ─────────────────────────
                if (provider.participationsByCountry.isNotEmpty) ...[
                  _SectionTitle(title: '🌍 Países com mais Participações'),
                  const SizedBox(height: 8),
                  _ParticipationsCard(
                      participations: provider.participationsByCountry),
                  const SizedBox(height: 24),
                ],

                const SizedBox(height: 8),
              ],
            ),
    );
  }

  String _champFlag(String country) {
    const flags = {
      'Brasil': '🇧🇷',
      'Alemanha': '🇩🇪',
      'Itália': '🇮🇹',
      'Argentina': '🇦🇷',
      'França': '🇫🇷',
      'Uruguai': '🇺🇾',
      'Inglaterra': '🏴󠁧󠁢󠁥󠁮󠁧󠁿',
      'Espanha': '🇪🇸',
    };
    return flags[country] ?? '🏆';
  }
}

// ── Cards de Resumo ───────────────────────────────────────────────────────────

class _SummaryCards extends StatelessWidget {
  final Map<String, int> stats;
  const _SummaryCards({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
          icon: '⚽',
          label: 'Gols',
          value: '${stats['goals'] ?? 0}',
        ),
        const SizedBox(width: 8),
        _StatCard(
          icon: '🎮',
          label: 'Partidas',
          value: '${stats['matches'] ?? 0}',
        ),
        const SizedBox(width: 8),
        _StatCard(
          icon: '🏆',
          label: 'Edições',
          value: '${stats['editions'] ?? 0}',
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  const _StatCard(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2D1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
                style:
                    const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ── Artilheiros Históricos ────────────────────────────────────────────────────

class _TopScorersCard extends StatelessWidget {
  final List<Map<String, dynamic>> scorers;
  const _TopScorersCard({required this.scorers});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2D1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: scorers.asMap().entries.map((entry) {
          final i = entry.key;
          final s = entry.value;
          final name = s['name'] as String;
          final goals = s['goals'] as int;
          final medals = ['🥇', '🥈', '🥉'];
          final medal = i < 3 ? medals[i] : '${i + 1}.';
          final isLast = i == scorers.length - 1;

          return Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              border: i > 0
                  ? const Border(top: BorderSide(color: Colors.white12))
                  : null,
              borderRadius: i == 0
                  ? const BorderRadius.vertical(top: Radius.circular(11))
                  : isLast
                      ? const BorderRadius.vertical(
                          bottom: Radius.circular(11))
                      : null,
              color: i == 0
                  ? const Color(0xFFFFD700).withValues(alpha: 0.06)
                  : null,
            ),
            child: Row(
              children: [
                SizedBox(
                    width: 30,
                    child: Text(medal,
                        style: TextStyle(
                            fontSize: i < 3 ? 18 : 13,
                            color: Colors.white54))),
                Expanded(
                  child: Text(name,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A472A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$goals ⚽',
                    style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Jogos mais Goleados ───────────────────────────────────────────────────────

class _HighScoringCard extends StatelessWidget {
  final List<Map<String, dynamic>> matches;
  const _HighScoringCard({required this.matches});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2D1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: matches.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final year = item['year'] as int;
          final m = item['match'];
          final total = item['total'] as int;
          final ft = m.score.ft as List<int>;
          final f1 = TeamFlags.get(m.team1 as String);
          final f2 = TeamFlags.get(m.team2 as String);
          final n1 = TeamNamesPt.translate(m.team1 as String);
          final n2 = TeamNamesPt.translate(m.team2 as String);
          final isLast = i == matches.length - 1;

          return Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              border: i > 0
                  ? const Border(top: BorderSide(color: Colors.white12))
                  : null,
              borderRadius: i == 0
                  ? const BorderRadius.vertical(top: Radius.circular(11))
                  : isLast
                      ? const BorderRadius.vertical(
                          bottom: Radius.circular(11))
                      : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A472A).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    children: [
                      Text('$total',
                          style: const TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      const Text('gols',
                          style: TextStyle(
                              color: Colors.white38, fontSize: 9)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (f1.isNotEmpty) ...[
                            Text(f1,
                                style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 4),
                          ],
                          Flexible(
                              child: Text(n1,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12),
                                  overflow: TextOverflow.ellipsis)),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '${ft[0]} – ${ft[1]}',
                              style: const TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (f2.isNotEmpty) ...[
                            Text(f2,
                                style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 4),
                          ],
                          Flexible(
                              child: Text(n2,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12),
                                  overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text('Copa $year  •  ${TeamNamesPt.round(m.round as String)}',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Participações por País ────────────────────────────────────────────────────

class _ParticipationsCard extends StatelessWidget {
  final Map<String, int> participations;
  const _ParticipationsCard({required this.participations});

  @override
  Widget build(BuildContext context) {
    final entries = participations.entries.toList();
    final maxVal = entries.isEmpty ? 1 : entries.first.value;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2D1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: entries.asMap().entries.map((entry) {
          final i = entry.key;
          final country = entry.value.key;
          final count = entry.value.value;
          final flag = TeamFlags.get(country);
          final name = TeamNamesPt.translate(country);
          final barFraction = count / maxVal;
          final isLast = i == entries.length - 1;

          return Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              border: i > 0
                  ? const Border(top: BorderSide(color: Colors.white12))
                  : null,
              borderRadius: i == 0
                  ? const BorderRadius.vertical(top: Radius.circular(11))
                  : isLast
                      ? const BorderRadius.vertical(
                          bottom: Radius.circular(11))
                      : null,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  child: Text('${i + 1}',
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 11)),
                ),
                const SizedBox(width: 6),
                if (flag.isNotEmpty) ...[
                  Text(flag, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                ],
                SizedBox(
                  width: 100,
                  child: Text(name,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12),
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: barFraction,
                        child: Container(
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700)
                                .withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text('$count',
                    style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _GoalsLineChart extends StatelessWidget {
  final Map<int, int> goalsByYear;
  const _GoalsLineChart({required this.goalsByYear});

  @override
  Widget build(BuildContext context) {
    final sorted = goalsByYear.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final spots = sorted.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.value.toDouble());
    }).toList();

    final maxY = sorted.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (sorted.length - 1).toDouble(),
        minY: 0,
        maxY: (maxY + 20).toDouble(),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      '${sorted[s.x.toInt()].key}\n${s.y.toInt()} gols',
                      const TextStyle(color: Colors.white, fontSize: 11),
                    ))
                .toList(),
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 3,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= sorted.length) return const SizedBox();
                return Text(
                  '${sorted[idx].key}',
                  style: const TextStyle(color: Colors.white38, fontSize: 9),
                );
              },
              reservedSize: 24,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 50,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}',
                style: const TextStyle(color: Colors.white38, fontSize: 9),
              ),
              reservedSize: 30,
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: Colors.white12, strokeWidth: 1),
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFFFFD700),
            barWidth: 2.5,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFFFFD700).withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(title,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold)),
    );
  }
}
