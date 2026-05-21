import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/copa_2026_provider.dart';
import '../widgets/match_card.dart';
import 'copa_2026_screen.dart';
import 'history_screen.dart';
import 'stats_screen.dart';
import 'quiz_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    _DashboardTab(),
    Copa2026Screen(),
    HistoryScreen(),
    StatsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: const Color(0xFF0D1A0D),
        indicatorColor: const Color(0xFFFFD700).withValues(alpha: 0.25),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_soccer_outlined),
            selectedIcon: Icon(Icons.sports_soccer),
            label: 'Copa 2026',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'História',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<Copa2026Provider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<Copa2026Provider>();
    final today = DateTime.now();
    final dateStr = DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(today);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1A0D),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF0D1A0D),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                '🏆 Copa do Mundo',
                style: TextStyle(
                    color: Color(0xFFFFD700), fontWeight: FontWeight.bold),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A472A), Color(0xFF0D1A0D)],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                dateStr,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ),
          ),
          // Jogos do dia
          SliverToBoxAdapter(
            child: _SectionTitle(
              icon: Icons.today,
              title: 'Jogos de Hoje',
              subtitle: 'Copa do Mundo 2026',
            ),
          ),
          if (provider.loading)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: Color(0xFFFFD700)),
                ),
              ),
            )
          else if (provider.error != null)
            SliverToBoxAdapter(
              child: _ErrorCard(message: provider.error!),
            )
          else if (provider.todayMatches.isEmpty)
            SliverToBoxAdapter(
              child: _EmptyMatchesCard(
                upcomingMatches: provider.nextDaysMatches,
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => MatchCard(
                  match: provider.todayMatches[i],
                  show2026Actions: true,
                ),
                childCount: provider.todayMatches.length,
              ),
            ),
          // Próximos jogos (quando não há hoje)
          if (!provider.loading &&
              provider.todayMatches.isEmpty &&
              provider.nextDaysMatches.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _SectionTitle(
                icon: Icons.schedule,
                title: 'Próximos Jogos',
                subtitle: 'Próximos 4 dias',
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => MatchCard(
                  match: provider.nextDaysMatches[i],
                  show2026Actions: true,
                ),
                childCount: provider.nextDaysMatches.length,
              ),
            ),
          ],
          // Cards de navegação rápida
          SliverToBoxAdapter(
            child: _SectionTitle(
              icon: Icons.grid_view,
              title: 'Explorar',
              subtitle: '',
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.6,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              delegate: SliverChildListDelegate([
                _NavCard(
                  icon: Icons.sports_soccer,
                  title: 'Copa 2026',
                  subtitle: '80 jogos • 48 seleções',
                  color: const Color(0xFF1A472A),
                  onTap: () => _goToTab(context, 1),
                ),
                _NavCard(
                  icon: Icons.history,
                  title: 'História',
                  subtitle: '1930 – 2022',
                  color: const Color(0xFF1A3A47),
                  onTap: () => _goToTab(context, 2),
                ),
                _NavCard(
                  icon: Icons.bar_chart,
                  title: 'Estatísticas',
                  subtitle: 'Gráficos e rankings',
                  color: const Color(0xFF3A1A47),
                  onTap: () => _goToTab(context, 3),
                ),
                _NavCard(
                  icon: Icons.quiz,
                  title: 'Quiz',
                  subtitle: 'Teste seu conhecimento',
                  color: const Color(0xFF472A1A),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const QuizScreen()),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _goToTab(BuildContext context, int index) {
    final homeState = context.findAncestorStateOfType<_HomeScreenState>();
    homeState?.setState(() => homeState._currentIndex = index);
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionTitle(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFFD700), size: 18),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(subtitle,
                style:
                    const TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _NavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFFFFD700), size: 22),
            const SizedBox(height: 6),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            Text(subtitle,
                style:
                    const TextStyle(color: Colors.white54, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _EmptyMatchesCard extends StatelessWidget {
  final List upcomingMatches;

  const _EmptyMatchesCard({required this.upcomingMatches});

  @override
  Widget build(BuildContext context) {
    final nextDate = upcomingMatches.isNotEmpty
        ? upcomingMatches.first.date
        : '11/06/2026';
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2D1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text('⚽', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          const Text('Nenhum jogo hoje',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            'Próximo jogo: $nextDate',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Erro ao carregar dados.\nVerifique sua conexão.',
                style: const TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}
