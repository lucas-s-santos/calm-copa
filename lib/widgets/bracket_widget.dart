import 'package:flutter/material.dart';
import '../providers/simulator_provider.dart';
import '../models/match.dart';

class BracketWidget extends StatelessWidget {
  final SimulatorProvider provider;
  const BracketWidget({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    if (!provider.allGroupsSimulated) {
      return const Center(
        child: Text(
          'Simule os grupos para ver o bracket',
          style: TextStyle(color: Colors.white54, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      );
    }

    provider.reset3rdAssignment();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: _buildBracket(),
      ),
    );
  }

  Widget _buildBracket() {
    final r32 = provider.roundOf32;
    final r16 = provider.roundOf16;
    final qf = provider.quarterFinals;
    final sf = provider.semiFinals;
    final fin = provider.final_;
    final third = provider.thirdPlace;

    // Build columns per round
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RoundColumn(
          label: 'Round of 32',
          matches: r32,
          provider: provider,
        ),
        _ConnectorColumn(count: r32.length, nextCount: r16.length),
        _RoundColumn(
          label: 'Round of 16',
          matches: r16,
          provider: provider,
        ),
        _ConnectorColumn(count: r16.length, nextCount: qf.length),
        _RoundColumn(
          label: 'Quartas',
          matches: qf,
          provider: provider,
        ),
        _ConnectorColumn(count: qf.length, nextCount: sf.length),
        _RoundColumn(
          label: 'Semifinais',
          matches: sf,
          provider: provider,
        ),
        _ConnectorColumn(count: sf.length, nextCount: fin.length),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (fin.isNotEmpty) ...[
              const _RoundLabel(label: 'Final'),
              _BracketMatchCard(
                match: fin.first,
                provider: provider,
                highlight: true,
              ),
            ],
            const SizedBox(height: 24),
            if (third.isNotEmpty) ...[
              const _RoundLabel(label: '3º Lugar'),
              _BracketMatchCard(
                match: third.first,
                provider: provider,
              ),
            ],
            // Champion display
            if (provider.projectedChampion != null) ...[
              const SizedBox(height: 24),
              _ChampionBadge(name: provider.projectedChampion!),
            ],
          ],
        ),
      ],
    );
  }
}

// ── Round Column ──────────────────────────────────────────────────────────────

class _RoundColumn extends StatelessWidget {
  final String label;
  final List<Match> matches;
  final SimulatorProvider provider;

  const _RoundColumn({
    required this.label,
    required this.matches,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _RoundLabel(label: label),
        for (final m in matches)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: _BracketMatchCard(match: m, provider: provider),
          ),
      ],
    );
  }
}

// ── Round Label ───────────────────────────────────────────────────────────────

class _RoundLabel extends StatelessWidget {
  final String label;
  const _RoundLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A472A),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
            color: Color(0xFFFFD700),
            fontSize: 11,
            fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ── Bracket Match Card ────────────────────────────────────────────────────────

class _BracketMatchCard extends StatelessWidget {
  final Match match;
  final SimulatorProvider provider;
  final bool highlight;

  const _BracketMatchCard({
    required this.match,
    required this.provider,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final t1 = provider.resolveCode(match.team1);
    final t2 = provider.resolveCode(match.team2);
    final result = provider.getResult(match.matchKey);

    final tbd1 = t1 == match.team1 && match.team1.length > 2;
    final tbd2 = t2 == match.team2 && match.team2.length > 2;

    String? winner;
    if (result != null) {
      winner = result[0] >= result[1] ? t1 : t2;
    }

    return Container(
      width: 160,
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: highlight
            ? const Color(0xFF1A472A)
            : const Color(0xFF1E2D1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlight
              ? const Color(0xFFFFD700)
              : result != null
                  ? const Color(0xFFFFD700).withValues(alpha: 0.3)
                  : Colors.white12,
          width: highlight ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          _TeamRow(
            name: tbd1 ? '?' : t1,
            score: result?[0],
            isWinner: winner != null && winner == t1,
          ),
          Divider(
            height: 1,
            color: result != null ? Colors.white12 : Colors.white12,
          ),
          _TeamRow(
            name: tbd2 ? '?' : t2,
            score: result?[1],
            isWinner: winner != null && winner == t2,
          ),
        ],
      ),
    );
  }
}

class _TeamRow extends StatelessWidget {
  final String name;
  final int? score;
  final bool isWinner;

  const _TeamRow({
    required this.name,
    this.score,
    this.isWinner = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      color: isWinner
          ? const Color(0xFFFFD700).withValues(alpha: 0.1)
          : null,
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isWinner ? const Color(0xFFFFD700) : Colors.white70,
                fontSize: 11,
                fontWeight:
                    isWinner ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (score != null)
            Container(
              width: 22,
              alignment: Alignment.center,
              child: Text(
                '$score',
                style: TextStyle(
                  color: isWinner
                      ? const Color(0xFFFFD700)
                      : Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Connector Column ──────────────────────────────────────────────────────────

class _ConnectorColumn extends StatelessWidget {
  final int count;
  final int nextCount;

  const _ConnectorColumn({required this.count, required this.nextCount});

  @override
  Widget build(BuildContext context) {
    const cardH = 44.0; // approx height of each bracket card
    const gap = 4.0;
    const roundLabelH = 28.0;

    return SizedBox(
      width: 20,
      child: CustomPaint(
        size: Size(20, roundLabelH + count * (cardH + gap)),
        painter: _ConnectorPainter(count: count, nextCount: nextCount),
      ),
    );
  }
}

class _ConnectorPainter extends CustomPainter {
  final int count;
  final int nextCount;

  _ConnectorPainter({required this.count, required this.nextCount});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2A4A2A)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const roundLabelH = 28.0;
    const cardH = 44.0;
    const gap = 4.0;

    final pairs = count ~/ 2;
    for (int i = 0; i < pairs; i++) {
      final topIdx = i * 2;
      final botIdx = topIdx + 1;

      final topY = roundLabelH + topIdx * (cardH + gap) + cardH / 2;
      final botY = roundLabelH + botIdx * (cardH + gap) + cardH / 2;
      final midY = (topY + botY) / 2;

      // Horizontal line right from top card
      canvas.drawLine(Offset(0, topY), Offset(10, topY), paint);
      // Horizontal line right from bottom card
      canvas.drawLine(Offset(0, botY), Offset(10, botY), paint);
      // Vertical connecting line
      canvas.drawLine(Offset(10, topY), Offset(10, botY), paint);
      // Horizontal line to next round
      canvas.drawLine(Offset(10, midY), Offset(20, midY), paint);
    }
  }

  @override
  bool shouldRepaint(_ConnectorPainter old) =>
      old.count != count || old.nextCount != nextCount;
}

// ── Champion Badge ────────────────────────────────────────────────────────────

class _ChampionBadge extends StatelessWidget {
  final String name;
  const _ChampionBadge({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A472A), Color(0xFF2A6A3A)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD700), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.3),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 4),
          const Text('CAMPEÃO',
              style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2)),
          const SizedBox(height: 4),
          Text(name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
