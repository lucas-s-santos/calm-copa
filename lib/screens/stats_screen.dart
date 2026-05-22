import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/history_provider.dart';

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
                              const TextStyle(color: Colors.white, fontSize: 12),
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
                              final flag = _countryFlag(sortedTitles[idx].key);
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
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: Colors.white12,
                          strokeWidth: 1,
                        ),
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

                const SizedBox(height: 16),
              ],
            ),
    );
  }

  String _countryFlag(String country) {
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
