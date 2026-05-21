import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/simulator_provider.dart';
import '../models/match.dart';
import '../models/local_result.dart';
import '../widgets/score_entry_dialog.dart';
import '../widgets/bracket_widget.dart';

class SimulatorScreen extends StatefulWidget {
  const SimulatorScreen({super.key});

  @override
  State<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends State<SimulatorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SimulatorProvider>().load();
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SimulatorProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1A0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A472A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('🎮 Simulador Copa 2026',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: const Color(0xFF1E2D1E),
            onSelected: (v) => _handleAction(context, v, provider),
            itemBuilder: (_) => [
              _menuItem('sim_all', '⚡ Auto-simular tudo', Colors.yellowAccent),
              _menuItem('sim_groups', '🎲 Simular fase de grupos', Colors.white70),
              _menuItem('sim_knockout', '🏆 Simular eliminatórias', Colors.white70),
              _menuItem('reset_groups', '↩ Resetar grupos', Colors.orange),
              _menuItem('reset_all', '🗑 Resetar tudo', Colors.red),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: const Color(0xFFFFD700),
          labelColor: const Color(0xFFFFD700),
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Grupos'),
            Tab(text: 'Eliminatórias'),
            Tab(text: 'Bracket'),
          ],
        ),
      ),
      body: provider.loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFFFD700)),
                  SizedBox(height: 12),
                  Text('Carregando dados...',
                      style: TextStyle(color: Colors.white54)),
                ],
              ),
            )
          : provider.error != null
              ? _ErrorView(error: provider.error!, onRetry: provider.load)
              : Column(
                  children: [
                    _ProgressBar(provider: provider),
                    Expanded(
                      child: TabBarView(
                        controller: _tab,
                        children: [
                          _GroupsTab(provider: provider),
                          _KnockoutTab(provider: provider),
                          BracketWidget(provider: provider),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  PopupMenuItem<String> _menuItem(String value, String label, Color color) {
    return PopupMenuItem(
      value: value,
      child: Text(label, style: TextStyle(color: color)),
    );
  }

  void _handleAction(
      BuildContext ctx, String action, SimulatorProvider provider) {
    switch (action) {
      case 'sim_all':
        provider.autoSimulateAll();
      case 'sim_groups':
        provider.autoSimulateGroups();
      case 'sim_knockout':
        if (!provider.allGroupsSimulated) {
          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
            content: Text('Simule os grupos primeiro!'),
            backgroundColor: Colors.orange,
          ));
          return;
        }
        provider.autoSimulateKnockout();
      case 'reset_groups':
        provider.resetGroups();
      case 'reset_all':
        _confirmReset(ctx, provider);
    }
  }

  Future<void> _confirmReset(BuildContext ctx, SimulatorProvider provider) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E2D1E),
        title: const Text('Resetar simulação?',
            style: TextStyle(color: Colors.white)),
        content: const Text('Todos os resultados simulados serão apagados.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Resetar'),
          ),
        ],
      ),
    );
    if (ok == true) provider.resetAll();
  }
}

// ── Progress Bar ─────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final SimulatorProvider provider;
  const _ProgressBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    final done = provider.simulatedGroupMatches;
    final total = provider.totalGroupMatches;
    final pct = total > 0 ? done / total : 0.0;

    return Container(
      color: const Color(0xFF0D1A0D),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$done/$total jogos de grupos simulados',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: const Color(0xFF1E2D1E),
                    color: const Color(0xFFFFD700),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          if (provider.projectedChampion != null) ...[
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('🏆 Projeção',
                    style: TextStyle(color: Colors.white38, fontSize: 10)),
                Text(
                  provider.projectedChampion!,
                  style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Groups Tab ────────────────────────────────────────────────────────────────

class _GroupsTab extends StatelessWidget {
  final SimulatorProvider provider;
  const _GroupsTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<Match>>{};
    for (final m in provider.groupMatches) {
      grouped.putIfAbsent(m.group!, () => []).add(m);
    }
    final groups = grouped.keys.toList()..sort();

    final standings = provider.computeAllStandings();

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: groups.length,
      itemBuilder: (ctx, i) {
        final groupName = groups[i];
        final matches = grouped[groupName]!;
        final groupStandings = standings[groupName] ?? [];

        return ExpansionTile(
          initiallyExpanded: i == 0,
          backgroundColor: const Color(0xFF0D1A0D),
          collapsedBackgroundColor: const Color(0xFF0D1A0D),
          iconColor: const Color(0xFFFFD700),
          collapsedIconColor: Colors.white38,
          title: Row(
            children: [
              Text(groupName,
                  style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              const Spacer(),
              _GroupStandingsMini(standings: groupStandings),
            ],
          ),
          children: [
            // Mini standings
            if (groupStandings.isNotEmpty)
              _MiniStandingsTable(standings: groupStandings),
            // Matches
            ...matches.map((m) => _SimMatchCard(
                  match: m,
                  provider: provider,
                )),
          ],
        );
      },
    );
  }
}

class _GroupStandingsMini extends StatelessWidget {
  final List<Map<String, dynamic>> standings;
  const _GroupStandingsMini({required this.standings});

  @override
  Widget build(BuildContext context) {
    if (standings.isEmpty) return const SizedBox();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: standings
          .take(2)
          .map((s) => Container(
                margin: const EdgeInsets.only(left: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A472A),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(s['team'] as String,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 10)),
              ))
          .toList(),
    );
  }
}

class _MiniStandingsTable extends StatelessWidget {
  final List<Map<String, dynamic>> standings;
  const _MiniStandingsTable({required this.standings});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2D1E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: standings.asMap().entries.map((entry) {
          final idx = entry.key;
          final s = entry.value;
          final isQ = idx < 2;
          final isMaybe3rd = idx == 2;
          return Container(
            color: isQ
                ? const Color(0xFF1A472A).withValues(alpha: 0.4)
                : isMaybe3rd
                    ? const Color(0xFF2A3A1A).withValues(alpha: 0.4)
                    : null,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  child: Text('${idx + 1}',
                      style: TextStyle(
                          color: isQ ? const Color(0xFFFFD700) : Colors.white38,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: Text(s['team'] as String,
                      style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
                _StatCell('${s['pj']}'),
                _StatCell('${s['v']}'),
                _StatCell('${s['e']}'),
                _StatCell('${s['d']}'),
                _StatCell('${s['sg']}'),
                _StatCell('${s['pts']}',
                    bold: true, color: const Color(0xFFFFD700)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String text;
  final bool bold;
  final Color color;

  const _StatCell(this.text,
      {this.bold = false, this.color = Colors.white54});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 26,
      child: Text(text,
          textAlign: TextAlign.center,
          style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
    );
  }
}

// ── Knockout Tab ──────────────────────────────────────────────────────────────

class _KnockoutTab extends StatelessWidget {
  final SimulatorProvider provider;
  const _KnockoutTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (!provider.allGroupsSimulated) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('⚽', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              const Text(
                'Simule a fase de grupos primeiro para ver as eliminatórias!',
                style: TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context
                    .read<SimulatorProvider>()
                    .autoSimulateGroups(),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Auto-simular grupos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
        ),
      );
    }

    provider.reset3rdAssignment();

    final rounds = [
      ('Round of 32', provider.roundOf32),
      ('Round of 16', provider.roundOf16),
      ('Quartas de Final', provider.quarterFinals),
      ('Semifinais', provider.semiFinals),
      ('Disputa 3º Lugar', provider.thirdPlace),
      ('Final', provider.final_),
    ];

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        for (final (label, matches) in rounds)
          if (matches.isNotEmpty) ...[
            _KnockoutSectionHeader(label: label),
            for (final m in matches)
              _KnockoutMatchCard(
                match: m,
                provider: provider,
              ),
          ],
      ],
    );
  }
}

class _KnockoutSectionHeader extends StatelessWidget {
  final String label;
  const _KnockoutSectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _KnockoutMatchCard extends StatelessWidget {
  final Match match;
  final SimulatorProvider provider;

  const _KnockoutMatchCard({required this.match, required this.provider});

  @override
  Widget build(BuildContext context) {
    final t1 = provider.resolveCode(match.team1);
    final t2 = provider.resolveCode(match.team2);
    final result = provider.getResult(match.matchKey);
    final tbd1 = t1 == match.team1 && match.team1.length > 2;
    final tbd2 = t2 == match.team2 && match.team2.length > 2;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2D1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: result != null
              ? const Color(0xFFFFD700).withValues(alpha: 0.4)
              : Colors.white12,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Text(match.round,
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 11)),
                const Spacer(),
                Text(match.date,
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    tbd1 ? '❓ A definir' : t1,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        color: tbd1 ? Colors.white38 : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: result != null
                        ? const Color(0xFFFFD700).withValues(alpha: 0.12)
                        : const Color(0xFF2A3D2A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    result != null
                        ? '${result[0]} x ${result[1]}'
                        : 'x',
                    style: TextStyle(
                      color: result != null
                          ? const Color(0xFFFFD700)
                          : Colors.white24,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    tbd2 ? '❓ A definir' : t2,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        color: tbd2 ? Colors.white38 : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(match.ground,
                style:
                    const TextStyle(color: Colors.white38, fontSize: 11)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!tbd1 && !tbd2)
                  SizedBox(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _simulate(context, t1, t2),
                      icon: const Icon(Icons.casino, size: 14),
                      label: const Text('Auto'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(
                            color: Colors.white24),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                if (!tbd1 && !tbd2)
                  SizedBox(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _openDialog(context, t1, t2),
                      icon: const Icon(Icons.edit, size: 14),
                      label: const Text('Inserir'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFFD700),
                        side: const BorderSide(
                            color: Color(0xFFFFD700), width: 0.8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _simulate(BuildContext context, String t1, String t2) {
    final provider = context.read<SimulatorProvider>();
    // Use a knockout-aware match copy with resolved team names
    final fakeProv = context.read<SimulatorProvider>();
    final score = fakeProv.autoSimulateKnockoutMatch();
    provider.setResult(match, score[0], score[1]);
  }

  Future<void> _openDialog(
      BuildContext context, String t1, String t2) async {
    // Create a fake match with resolved team names for the dialog
    final fakeMatch = Match(
      round: match.round,
      date: match.date,
      time: match.time,
      team1: t1,
      team2: t2,
      ground: match.ground,
      num: match.num,
    );
    final existing = provider.getResult(match.matchKey);
    final existingResult = existing != null
        ? LocalResult(matchKey: match.matchKey, score1: existing[0], score2: existing[1])
        : null;

    final result = await showDialog(
      context: context,
      builder: (_) =>
          ScoreEntryDialog(match: fakeMatch, existingResult: existingResult),
    );

    if (result == 'delete') {
      provider.removeResult(match.matchKey);
    } else if (result is List<int> && result.length == 2) {
      provider.setResult(match, result[0], result[1]);
    }
  }
}

// ── Error View ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
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
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black),
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}

// ── Sim Match Card (group stage) ──────────────────────────────────────────────

class _SimMatchCard extends StatelessWidget {
  final Match match;
  final SimulatorProvider provider;

  const _SimMatchCard({required this.match, required this.provider});

  @override
  Widget build(BuildContext context) {
    final result = provider.getResult(match.matchKey);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF162316),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: result != null
              ? const Color(0xFFFFD700).withValues(alpha: 0.3)
              : Colors.white12,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(match.team1,
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: Colors.white, fontSize: 13)),
            ),
            GestureDetector(
              onTap: () => _openDialog(context),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: result != null
                      ? const Color(0xFFFFD700).withValues(alpha: 0.12)
                      : const Color(0xFF2A3D2A),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  result != null
                      ? '${result[0]} x ${result[1]}'
                      : '- x -',
                  style: TextStyle(
                      color: result != null
                          ? const Color(0xFFFFD700)
                          : Colors.white24,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Expanded(
              child: Text(match.team2,
                  textAlign: TextAlign.left,
                  style:
                      const TextStyle(color: Colors.white, fontSize: 13)),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () {
                final score = provider.autoSimulateKnockoutMatch(canDraw: true);
                provider.setResult(match, score[0], score[1]);
              },
              icon: const Icon(Icons.casino,
                  color: Colors.white38, size: 18),
              tooltip: 'Sortear resultado',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDialog(BuildContext context) async {
    final result = provider.getResult(match.matchKey);
    final existing = result != null
        ? LocalResult(matchKey: match.matchKey, score1: result[0], score2: result[1])
        : null;

    final dialogResult = await showDialog(
      context: context,
      builder: (_) =>
          ScoreEntryDialog(match: match, existingResult: existing),
    );

    if (dialogResult == 'delete') {
      provider.removeResult(match.matchKey);
    } else if (dialogResult is List<int> && dialogResult.length == 2) {
      provider.setResult(match, dialogResult[0], dialogResult[1]);
    }
  }
}
