import 'package:flutter/material.dart';
import '../providers/history_provider.dart';
import 'copa_detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  static const _allYears = [
    1930, 1934, 1938, 1950, 1954, 1958, 1962, 1966, 1970, 1974,
    1978, 1982, 1986, 1990, 1994, 1998, 2002, 2006, 2010, 2014,
    2018, 2022, 2026,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1A0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A472A),
        title: const Text('📖 História da Copa',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _allYears.length,
        itemBuilder: (ctx, i) {
          final year = _allYears[_allYears.length - 1 - i]; // mais recente primeiro
          final info = worldCupInfo[year];
          final isCurrent = year == 2026;

          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CopaDetailScreen(year: year),
              ),
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isCurrent
                      ? [const Color(0xFF1A472A), const Color(0xFF0D2A1A)]
                      : [const Color(0xFF1E2D1E), const Color(0xFF162316)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isCurrent
                      ? const Color(0xFFFFD700).withValues(alpha: 0.6)
                      : Colors.white12,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Ano
                    SizedBox(
                      width: 56,
                      child: Text(
                        '$year',
                        style: TextStyle(
                          color: isCurrent
                              ? const Color(0xFFFFD700)
                              : Colors.white54,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Bandeira do campeão
                    Text(
                      info?['flag'] ?? '🏆',
                      style: const TextStyle(fontSize: 36),
                    ),
                    const SizedBox(width: 16),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            info?['champion'] == '?'
                                ? '🏆 A definir'
                                : info?['champion'] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Sede: ${info?['host'] ?? ''}',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12),
                          ),
                          if (isCurrent)
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                'Em andamento • EUA/México/Canadá',
                                style: TextStyle(
                                    color: Color(0xFFFFD700), fontSize: 11),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white38),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
