import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/copa_2026_provider.dart';
import '../models/match.dart';
import '../widgets/match_card.dart';
import 'match_detail_screen.dart';
import 'simulator_screen.dart';

class Copa2026Screen extends StatefulWidget {
  const Copa2026Screen({super.key});

  @override
  State<Copa2026Screen> createState() => _Copa2026ScreenState();
}

class _Copa2026ScreenState extends State<Copa2026Screen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<Copa2026Provider>().load();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1A0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A472A),
        title: const Text('🏆 Copa do Mundo 2026',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.sports_esports, color: Color(0xFFFFD700)),
            tooltip: 'Simulador',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SimulatorScreen()),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFFD700),
          labelColor: const Color(0xFFFFD700),
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Hoje'),
            Tab(text: 'Agenda'),
            Tab(text: 'Grupos'),
            Tab(text: 'Seleções'),
          ],
        ),
      ),
      body: Consumer<Copa2026Provider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFD700)),
            );
          }
          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off, color: Colors.white38, size: 48),
                  const SizedBox(height: 12),
                  const Text('Erro ao carregar dados',
                      style: TextStyle(color: Colors.white)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: provider.load,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        foregroundColor: Colors.black),
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _TodayTab(provider: provider),
              _ScheduleTab(provider: provider),
              _GroupsTab(provider: provider),
              _TeamsTab(provider: provider),
            ],
          );
        },
      ),
    );
  }
}

// ── Tab: Hoje ─────────────────────────────────────────────────────────────────

class _TodayTab extends StatelessWidget {
  final Copa2026Provider provider;
  const _TodayTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final label = DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(today);

    final todayMatches = provider.todayMatches;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Text(label,
              style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
        ),
        if (todayMatches.isEmpty) ...[
          const SizedBox(height: 24),
          const Center(
            child: Column(
              children: [
                Text('⚽', style: TextStyle(fontSize: 48)),
                SizedBox(height: 12),
                Text('Nenhum jogo hoje',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('A Copa começa em 11/06/2026',
                    style: TextStyle(color: Colors.white54)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Próximos jogos:',
                style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ),
          ...provider.nextDaysMatches.map((m) => MatchCard(
                match: m,
                show2026Actions: true,
                onTap: () => _openDetail(context, m),
              )),
        ] else
          ...todayMatches.map((m) => MatchCard(
                match: m,
                show2026Actions: true,
                onTap: () => _openDetail(context, m),
              )),
      ],
    );
  }

  void _openDetail(BuildContext context, Match m) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MatchDetailScreen(match: m, show2026Actions: true),
      ),
    );
  }
}

// ── Tab: Agenda ───────────────────────────────────────────────────────────────

class _ScheduleTab extends StatelessWidget {
  final Copa2026Provider provider;
  const _ScheduleTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<Match>>{};
    for (final m in provider.matches) {
      grouped.putIfAbsent(m.date, () => []).add(m);
    }
    final dates = grouped.keys.toList()..sort();

    return ListView.builder(
      itemCount: dates.length,
      itemBuilder: (ctx, i) {
        final date = dates[i];
        final matches = grouped[date]!;
        final dt = DateTime.tryParse(date);
        final label = dt != null
            ? DateFormat("EEE, dd/MM", 'pt_BR').format(dt)
            : date;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(label,
                  style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
            ),
            ...matches.map((m) => MatchCard(
                  match: m,
                  show2026Actions: true,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          MatchDetailScreen(match: m, show2026Actions: true),
                    ),
                  ),
                )),
          ],
        );
      },
    );
  }
}

// ── Tab: Grupos ───────────────────────────────────────────────────────────────

class _GroupsTab extends StatelessWidget {
  final Copa2026Provider provider;
  const _GroupsTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final groups = provider.groups;
    if (groups.isEmpty) {
      return const Center(
          child: Text('Carregando grupos...',
              style: TextStyle(color: Colors.white54)));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: groups.length,
      itemBuilder: (ctx, i) {
        final group = groups[i];
        final standings = provider.getGroupStandings(group.name);

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2D1E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFF1A472A),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    Text(group.name,
                        style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                  ],
                ),
              ),
              // Cabeçalho da tabela
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                        child: Text('Seleção',
                            style: TextStyle(
                                color: Colors.white38, fontSize: 11))),
                    SizedBox(
                        width: 28,
                        child: Text('PJ',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white38, fontSize: 11))),
                    SizedBox(
                        width: 28,
                        child: Text('V',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white38, fontSize: 11))),
                    SizedBox(
                        width: 28,
                        child: Text('E',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white38, fontSize: 11))),
                    SizedBox(
                        width: 28,
                        child: Text('D',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white38, fontSize: 11))),
                    SizedBox(
                        width: 36,
                        child: Text('SG',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white38, fontSize: 11))),
                    SizedBox(
                        width: 36,
                        child: Text('PTS',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                                fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              ...standings.asMap().entries.map((entry) {
                final idx = entry.key;
                final s = entry.value;
                final isQualified = idx < 2;
                return Container(
                  color: isQualified
                      ? const Color(0xFF1A472A).withValues(alpha: 0.3)
                      : null,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Text(s['flag'] as String,
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(s['team'] as String,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12)),
                      ),
                      _Cell('${s['pj']}'),
                      _Cell('${s['v']}'),
                      _Cell('${s['e']}'),
                      _Cell('${s['d']}'),
                      _Cell('${s['sg']}', width: 36),
                      _Cell('${s['pts']}',
                          width: 36,
                          bold: true,
                          color: const Color(0xFFFFD700)),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;
  final double width;
  final bool bold;
  final Color color;

  const _Cell(this.text,
      {this.width = 28, this.bold = false, this.color = Colors.white70});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(text,
          textAlign: TextAlign.center,
          style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
    );
  }
}

// ── Tab: Seleções ─────────────────────────────────────────────────────────────

class _TeamsTab extends StatelessWidget {
  final Copa2026Provider provider;
  const _TeamsTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final byConfed = <String, List<dynamic>>{};
    for (final t in provider.teams) {
      byConfed.putIfAbsent(t.confed, () => []).add(t);
    }
    final confeds = byConfed.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: confeds.length,
      itemBuilder: (ctx, i) {
        final confed = confeds[i];
        final teams = byConfed[confed]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(confed,
                  style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ),
            ...teams.map((t) => ListTile(
                  leading: Text(t.flagIcon,
                      style: const TextStyle(fontSize: 28)),
                  title: Text(t.displayName,
                      style: const TextStyle(color: Colors.white)),
                  subtitle: Text('Grupo ${t.group} • ${t.fifaCode}',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11)),
                  dense: true,
                )),
          ],
        );
      },
    );
  }
}
