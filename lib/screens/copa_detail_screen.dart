import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/history_provider.dart';
import '../widgets/match_card.dart';
import 'match_detail_screen.dart';

class CopaDetailScreen extends StatefulWidget {
  final int year;

  const CopaDetailScreen({super.key, required this.year});

  @override
  State<CopaDetailScreen> createState() => _CopaDetailScreenState();
}

class _CopaDetailScreenState extends State<CopaDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().loadYear(widget.year);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HistoryProvider>();
    final info = worldCupInfo[widget.year];
    final isLoading = provider.isLoading(widget.year);
    final error = provider.getError(widget.year);

    final grouped = provider.groupByRound(widget.year);
    final rounds = grouped.keys.toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1A0D),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: const Color(0xFF1A472A),
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Copa ${widget.year}',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A472A), Color(0xFF0D2A1A)],
                  ),
                ),
                child: info != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 30),
                            Text(info['flag']!,
                                style: const TextStyle(fontSize: 48)),
                            Text(
                              info['champion']! == '?'
                                  ? '🏆 A definir'
                                  : '🏆 ${info['champion']}',
                              style: const TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Sede: ${info['host']}',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    : null,
              ),
            ),
          ),
          if (isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFFFFD700)),
              ),
            )
          else if (error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off, color: Colors.white38, size: 48),
                    const SizedBox(height: 12),
                    const Text('Erro ao carregar',
                        style: TextStyle(color: Colors.white54)),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () =>
                          provider.loadYear(widget.year),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: Colors.black),
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Artilheiros da copa
            if (provider.getTopScorers(widget.year).isNotEmpty) ...[
              _SliverSectionTitle(title: '⚽ Artilheiros'),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: provider.getTopScorers(widget.year).length,
                    itemBuilder: (ctx, i) {
                      final s = provider.getTopScorers(widget.year)[i];
                      return Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2D1E),
                          borderRadius: BorderRadius.circular(10),
                          border: i == 0
                              ? Border.all(
                                  color: const Color(0xFFFFD700), width: 1.5)
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${i == 0 ? "🥇" : i == 1 ? "🥈" : i == 2 ? "🥉" : "${i + 1}."} ${s['name']}',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text('${s['goals']} gol${s['goals'] == 1 ? '' : 's'}',
                                style: const TextStyle(
                                    color: Color(0xFFFFD700), fontSize: 12)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
            // Partidas por fase
            ...rounds.map((round) {
              final roundMatches = grouped[round]!;
              return [
                _SliverSectionTitle(title: round),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => MatchCard(
                      match: roundMatches[i],
                      showGroup: roundMatches[i].group != null,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              MatchDetailScreen(match: roundMatches[i]),
                        ),
                      ),
                    ),
                    childCount: roundMatches.length,
                  ),
                ),
              ];
            }).expand((l) => l),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ],
      ),
    );
  }
}

class _SliverSectionTitle extends SliverToBoxAdapter {
  _SliverSectionTitle({required String title})
      : super(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
}
