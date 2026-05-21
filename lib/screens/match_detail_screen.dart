import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/match.dart';
import '../models/local_result.dart';
import '../providers/copa_2026_provider.dart';
import '../widgets/score_entry_dialog.dart';

class MatchDetailScreen extends StatelessWidget {
  final Match match;
  final bool show2026Actions;

  const MatchDetailScreen({
    super.key,
    required this.match,
    this.show2026Actions = false,
  });

  @override
  Widget build(BuildContext context) {
    LocalResult? localResult;
    if (show2026Actions) {
      localResult =
          context.watch<Copa2026Provider>().localResults[match.matchKey];
    }

    final apiScore = match.score;
    final hasApiResult = apiScore?.hasResult == true;
    final hasLocalResult = localResult != null;

    String scoreText = 'A jogar';
    bool isLocal = false;
    if (hasApiResult) {
      scoreText = apiScore!.displayScore;
    } else if (hasLocalResult) {
      scoreText = localResult.displayScore;
      isLocal = true;
    }

    final dateFormatted = _formatDate(match.date);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1A0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A472A),
        title: Text(match.round,
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Cabeçalho com placar
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1A472A), Color(0xFF0D1A0D)],
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              child: Column(
                children: [
                  if (match.group != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(match.group!,
                          style: const TextStyle(
                              color: Color(0xFFFFD700), fontSize: 13)),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _TeamColumn(name: match.team1),
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: (hasApiResult || hasLocalResult)
                                  ? const Color(0xFFFFD700).withValues(alpha: 0.15)
                                  : const Color(0xFF1E2D1E),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isLocal
                                    ? const Color(0xFFFFD700)
                                    : Colors.white24,
                              ),
                            ),
                            child: Text(
                              scoreText,
                              style: TextStyle(
                                color: (hasApiResult || hasLocalResult)
                                    ? const Color(0xFFFFD700)
                                    : Colors.white38,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isLocal) ...[
                            const SizedBox(height: 6),
                            const Text('📝 Resultado local',
                                style: TextStyle(
                                    color: Color(0xFFFFD700), fontSize: 11)),
                          ],
                          if (apiScore?.ht != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Intervalo: ${apiScore!.ht![0]}-${apiScore.ht![1]}',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 11),
                            ),
                          ],
                          if (apiScore?.et != null) ...[
                            Text(
                              'Prorrogação: ${apiScore!.et![0]}-${apiScore.et![1]}',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 11),
                            ),
                          ],
                          if (apiScore?.p != null) ...[
                            Text(
                              'Pênaltis: ${apiScore!.p![0]}-${apiScore.p![1]}',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 11),
                            ),
                          ],
                        ],
                      ),
                      _TeamColumn(name: match.team2),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_today,
                          color: Colors.white38, size: 14),
                      const SizedBox(width: 4),
                      Text(dateFormatted,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 13)),
                      const SizedBox(width: 16),
                      const Icon(Icons.access_time,
                          color: Colors.white38, size: 14),
                      const SizedBox(width: 4),
                      Text(match.time,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.white38, size: 14),
                      const SizedBox(width: 4),
                      Text(match.ground,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),

            // Botão de inserir resultado (Copa 2026)
            if (show2026Actions && !hasApiResult)
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openScoreDialog(context, localResult),
                    icon: const Icon(Icons.edit),
                    label: Text(hasLocalResult
                        ? 'Editar resultado'
                        : 'Inserir resultado'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),

            // Artilheiros
            if (match.goals1.isNotEmpty || match.goals2.isNotEmpty) ...[
              const _SectionDivider(title: 'Gols'),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: match.goals1
                          .map((g) => _GoalRow(goal: g, align: Alignment.centerRight))
                          .toList(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      children: match.goals2
                          .map((g) => _GoalRow(goal: g, align: Alignment.centerLeft))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat("dd 'de' MMMM 'de' yyyy", 'pt_BR').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  Future<void> _openScoreDialog(
      BuildContext context, LocalResult? existing) async {
    final provider = context.read<Copa2026Provider>();
    final result = await showDialog(
      context: context,
      builder: (_) => ScoreEntryDialog(match: match, existingResult: existing),
    );
    if (result == 'delete') {
      await provider.deleteResult(match.matchKey);
    } else if (result is List<int> && result.length == 2) {
      await provider.saveResult(match.matchKey, result[0], result[1]);
    }
  }
}

class _TeamColumn extends StatelessWidget {
  final String name;
  const _TeamColumn({required this.name});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      child: Text(
        name,
        textAlign: TextAlign.center,
        style: const TextStyle(
            color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  final dynamic goal;
  final Alignment align;
  const _GoalRow({required this.goal, required this.align});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Align(
        alignment: align,
        child: Text(
          '${goal.icon} ${goal.name} ${goal.displayMinute}',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
          textAlign: align == Alignment.centerRight
              ? TextAlign.right
              : TextAlign.left,
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  final String title;
  const _SectionDivider({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Colors.white12)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(title,
                style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
          const Expanded(child: Divider(color: Colors.white12)),
        ],
      ),
    );
  }
}
