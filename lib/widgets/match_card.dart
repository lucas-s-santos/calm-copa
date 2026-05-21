import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/match.dart';
import '../models/local_result.dart';
import '../providers/copa_2026_provider.dart';
import 'score_entry_dialog.dart';

class MatchCard extends StatelessWidget {
  final Match match;
  final bool show2026Actions;
  final bool showGroup;
  final VoidCallback? onTap;

  const MatchCard({
    super.key,
    required this.match,
    this.show2026Actions = false,
    this.showGroup = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    LocalResult? localResult;

    if (show2026Actions) {
      final provider = context.watch<Copa2026Provider>();
      localResult = provider.localResults[match.matchKey];
    }

    final score = match.score;
    final hasApiResult = score?.hasResult == true;
    final hasLocalResult = localResult != null;

    String scoreText = '- x -';
    bool isLocal = false;

    if (hasApiResult) {
      scoreText = score!.displayScore;
    } else if (hasLocalResult) {
      scoreText = localResult.displayScore;
      isLocal = true;
    }

    final dateFormatted = _formatDate(match.date);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2D1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isLocal
                ? const Color(0xFFFFD700).withValues(alpha:0.6)
                : const Color(0xFF2A4A2A),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  if (showGroup && match.group != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha:0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        match.group!,
                        style: TextStyle(
                            color: theme.colorScheme.primary, fontSize: 11),
                      ),
                    )
                  else
                    Text(match.round,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11)),
                  const Spacer(),
                  Text(dateFormatted,
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      match.team1,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: (hasApiResult || hasLocalResult)
                          ? theme.colorScheme.primary.withValues(alpha:0.15)
                          : const Color(0xFF2A3D2A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      scoreText,
                      style: TextStyle(
                        color: (hasApiResult || hasLocalResult)
                            ? theme.colorScheme.primary
                            : Colors.white38,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      match.team2,
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on,
                      color: Colors.white38, size: 12),
                  const SizedBox(width: 4),
                  Text(match.ground,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 11)),
                  if (isLocal) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withValues(alpha:0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('📝 Local',
                          style: TextStyle(
                              color: Color(0xFFFFD700), fontSize: 10)),
                    ),
                  ],
                ],
              ),
              if (show2026Actions && !hasApiResult) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _openScoreDialog(context, localResult),
                    icon: const Icon(Icons.edit, size: 14),
                    label: Text(
                        hasLocalResult ? 'Editar resultado' : 'Inserir resultado'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFFD700),
                      side: const BorderSide(
                          color: Color(0xFFFFD700), width: 0.8),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('dd/MM', 'pt_BR').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  Future<void> _openScoreDialog(
      BuildContext context, LocalResult? existing) async {
    final provider = context.read<Copa2026Provider>();
    final result = await showDialog(
      context: context,
      builder: (_) =>
          ScoreEntryDialog(match: match, existingResult: existing),
    );

    if (result == 'delete') {
      await provider.deleteResult(match.matchKey);
    } else if (result is List<int> && result.length == 2) {
      await provider.saveResult(match.matchKey, result[0], result[1]);
    }
  }
}
