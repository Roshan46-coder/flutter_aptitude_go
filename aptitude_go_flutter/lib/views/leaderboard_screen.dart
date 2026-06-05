import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import 'profile_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _globalBoard = [];
  List<dynamic> _weeklyBoard = [];
  List<dynamic> _categories = [];
  int? _selectedCategoryId;
  List<dynamic> _categoryBoard = [];
  bool _isLoading = true;
  bool _isCategoryLoading = false;
  String? _myUsername;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _fetchLeaderboard();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.index == 2 && _categoryBoard.isEmpty && _selectedCategoryId != null) {
      _fetchCategoryBoard(_selectedCategoryId!);
    }
  }

  Future<void> _fetchLeaderboard() async {
    setState(() => _isLoading = true);
    final api = Provider.of<ApiClient>(context, listen: false);
    _myUsername = api.currentUser?['username'];
    try {
      final res = await api.get('leaderboard/');
      if (mounted) {
        setState(() {
          _globalBoard  = res.data['global'] ?? [];
          _weeklyBoard  = res.data['weekly'] ?? [];
          _categories   = res.data['categories'] ?? [];
          _isLoading = false;
          if (_categories.isNotEmpty && _selectedCategoryId == null) {
            _selectedCategoryId = _categories[0]['id'];
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchCategoryBoard(int catId) async {
    setState(() => _isCategoryLoading = true);
    final api = Provider.of<ApiClient>(context, listen: false);
    try {
      final res = await api.get('leaderboard/category/$catId/');
      if (mounted) setState(() { _categoryBoard = res.data['board'] ?? []; _isCategoryLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isCategoryLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏆 Leaderboard'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.neonPurple,
          tabs: const [
            Tab(text: 'All Time'),
            Tab(text: 'This Week'),
            Tab(text: 'By Topic'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.neonPurple))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBoard(_globalBoard),
                _buildBoard(_weeklyBoard),
                _buildCategoryTab(),
              ],
            ),
    );
  }

  Widget _buildBoard(List<dynamic> entries) {
    if (entries.isEmpty) {
      return const Center(child: Text('No data yet.', style: TextStyle(color: Colors.white30)));
    }

    return RefreshIndicator(
      onRefresh: _fetchLeaderboard,
      color: AppTheme.neonPurple,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          final isMe = entry['username'] == _myUsername;
          return _leaderCard(entry, rank: index + 1, isMe: isMe);
        },
      ),
    );
  }

  Widget _buildCategoryTab() {
    return Column(
      children: [
        // Category chips
        SizedBox(
          height: 52,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final selected = _selectedCategoryId == cat['id'];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(cat['name'] ?? '',
                      style: TextStyle(
                        color: selected ? AppTheme.neonPurple : Colors.white38,
                        fontSize: 12,
                      )),
                  selected: selected,
                  onSelected: (v) {
                    setState(() { _selectedCategoryId = cat['id']; _categoryBoard = []; });
                    _fetchCategoryBoard(cat['id']);
                  },
                  backgroundColor: AppTheme.cardBg,
                  selectedColor: AppTheme.neonPurple.withValues(alpha: 0.12),
                  checkmarkColor: AppTheme.neonPurple,
                  side: BorderSide(color: selected ? AppTheme.neonPurple.withValues(alpha: 0.4) : AppTheme.divider),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              );
            },
          ),
        ),
        const Divider(color: AppTheme.divider, height: 1),
        Expanded(
          child: _isCategoryLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.neonPurple))
              : _buildBoard(_categoryBoard),
        ),
      ],
    );
  }

  Widget _leaderCard(Map<String, dynamic> entry, {required int rank, required bool isMe}) {
    final Color medalColor;
    final String? medal;
    if (rank == 1)      { medalColor = AppTheme.goldAccent;   medal = '🥇'; }
    else if (rank == 2) { medalColor = Colors.grey;            medal = '🥈'; }
    else if (rank == 3) { medalColor = Colors.brown[300]!;     medal = '🥉'; }
    else                { medalColor = Colors.white12;          medal = null; }

    final score = entry['avg_score'] ?? entry['score'] ?? 0;
    final attempts = entry['attempts'] ?? 0;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProfileScreen(username: entry['username'])),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe
              ? AppTheme.neonPurple.withValues(alpha: 0.08)
              : rank <= 3
                  ? medalColor.withValues(alpha: 0.05)
                  : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isMe
                ? AppTheme.neonPurple.withValues(alpha: 0.4)
                : rank <= 3
                    ? medalColor.withValues(alpha: 0.2)
                    : AppTheme.divider,
            width: isMe ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Rank
            SizedBox(
              width: 40,
              child: medal != null
                  ? Text(medal, style: const TextStyle(fontSize: 22), textAlign: TextAlign.center)
                  : Text(
                      '#$rank',
                      style: TextStyle(
                        color: isMe ? AppTheme.neonPurple : Colors.white24,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
            ),
            const SizedBox(width: 10),

            // Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: medalColor.withValues(alpha: 0.12),
              backgroundImage: entry['avatar_url'] != null ? NetworkImage(entry['avatar_url']) : null,
              child: entry['avatar_url'] == null
                  ? Text(
                      (entry['username'] as String? ?? '?')[0].toUpperCase(),
                      style: TextStyle(color: medalColor, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // Name + info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(
                      entry['username'] ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isMe ? AppTheme.neonPurple : Colors.white,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppTheme.neonPurple.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('You', style: TextStyle(color: AppTheme.neonPurple, fontSize: 10)),
                      ),
                    ],
                  ]),
                  Text(
                    'Lv ${entry['level'] ?? 1} · $attempts tests',
                    style: const TextStyle(color: Colors.white30, fontSize: 11),
                  ),
                ],
              ),
            ),

            // Score
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  score is double ? score.toStringAsFixed(1) : '$score',
                  style: TextStyle(
                    color: rank == 1 ? AppTheme.goldAccent : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const Text('avg score', style: TextStyle(color: Colors.white24, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
