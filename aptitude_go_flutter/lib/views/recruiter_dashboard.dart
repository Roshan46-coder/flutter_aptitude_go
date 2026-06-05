import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import 'profile_screen.dart';

class RecruiterDashboardScreen extends StatefulWidget {
  const RecruiterDashboardScreen({super.key});

  @override
  State<RecruiterDashboardScreen> createState() => _RecruiterDashboardScreenState();
}

class _RecruiterDashboardScreenState extends State<RecruiterDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _dashData;
  bool _isLoading = true;
  String? _error;

  final _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  String _selectedRole = 'All';
  final List<String> _roles = ['All', 'Developer', 'Data Analyst', 'Designer', 'Manager'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchDashboard();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchDashboard() async {
    setState(() { _isLoading = true; _error = null; });
    final api = Provider.of<ApiClient>(context, listen: false);
    try {
      final response = await api.get('recruiter/dashboard/');
      if (mounted) setState(() { _dashData = response.data; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Failed to load recruiter dashboard.'; _isLoading = false; });
    }
  }

  Future<void> _searchTalent(String query) async {
    if (query.trim().isEmpty) {
      setState(() { _searchResults = []; _isSearching = false; });
      return;
    }
    setState(() => _isSearching = true);
    final api = Provider.of<ApiClient>(context, listen: false);
    try {
      final params = <String, dynamic>{'q': query};
      if (_selectedRole != 'All') params['role'] = _selectedRole;
      final response = await api.get('recruiter/search/', queryParameters: params);
      if (mounted) setState(() { _searchResults = response.data['results'] ?? []; _isSearching = false; });
    } catch (_) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _sendMessage(String username) async {
    // Capture api before async gap
    final api = Provider.of<ApiClient>(context, listen: false);
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Message @$username'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Type your message...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Send')),
        ],
      ),
    );
    if (confirmed != true || controller.text.isEmpty) return;
    await api.post('recruiter/message/', data: {'to': username, 'message': controller.text.trim()});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Message sent to @$username'), backgroundColor: AppTheme.emeraldGreen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recruiter Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () async {
              final api = Provider.of<ApiClient>(context, listen: false);
              await api.logout();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.neonPurple,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Top Talent'),
            Tab(text: 'Search'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.neonPurple))
          : _error != null
              ? Center(child: Text(_error!))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildTopTalentTab(),
                    _buildSearchTab(),
                  ],
                ),
    );
  }

  Widget _buildOverviewTab() {
    final stats = _dashData?['stats'] as Map<String, dynamic>? ?? {};
    return RefreshIndicator(
      onRefresh: _fetchDashboard,
      color: AppTheme.neonPurple,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Platform Statistics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _statCard('Total Candidates', '${stats['total_candidates'] ?? 0}', Icons.people_outline, AppTheme.neonPurple),
                _statCard('Tests Taken', '${stats['total_attempts'] ?? 0}', Icons.quiz_outlined, AppTheme.neonBlue),
                _statCard('Avg Score', ((stats['avg_score'] ?? 0.0) as num).toStringAsFixed(1), Icons.bar_chart, AppTheme.goldAccent),
                _statCard('Certifications', '${stats['total_certs'] ?? 0}', Icons.verified, AppTheme.emeraldGreen),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 22)),
              Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopTalentTab() {
    final topUsers = (_dashData?['top_talent'] as List?) ?? [];
    if (topUsers.isEmpty) {
      return const Center(child: Text('No talent data available.', style: TextStyle(color: Colors.white30)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: topUsers.length,
      itemBuilder: (context, index) {
        final user = topUsers[index];
        return _talentCard(user, rank: index + 1);
      },
    );
  }

  Widget _buildSearchTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name, skill, category...',
                  prefixIcon: const Icon(Icons.search, color: Colors.white30),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white30),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchResults = []);
                          },
                        )
                      : null,
                ),
                onChanged: (v) => _searchTalent(v),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _roles.map((role) {
                    final selected = _selectedRole == role;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(role, style: TextStyle(
                          color: selected ? AppTheme.neonPurple : Colors.white38,
                          fontSize: 12,
                        )),
                        selected: selected,
                        onSelected: (v) {
                          setState(() => _selectedRole = role);
                          _searchTalent(_searchController.text);
                        },
                        backgroundColor: AppTheme.cardBg,
                        selectedColor: AppTheme.neonPurple.withValues(alpha: 0.15),
                        checkmarkColor: AppTheme.neonPurple,
                        side: BorderSide(color: selected ? AppTheme.neonPurple.withValues(alpha: 0.4) : AppTheme.divider),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isSearching
              ? const Center(child: CircularProgressIndicator(color: AppTheme.neonPurple))
              : _searchResults.isEmpty
                  ? Center(
                      child: Text(
                        _searchController.text.isEmpty ? 'Start typing to search talent...' : 'No results found.',
                        style: const TextStyle(color: Colors.white30),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) => _talentCard(_searchResults[index]),
                    ),
        ),
      ],
    );
  }

  Widget _talentCard(Map<String, dynamic> user, {int? rank}) {
    final certs = (user['certificate_count'] as num?)?.toInt() ?? 0;
    final avgScore = (user['avg_score'] as num?)?.toStringAsFixed(1) ?? '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppTheme.neonPurple.withValues(alpha: 0.1),
              backgroundImage: user['avatar_url'] != null ? NetworkImage(user['avatar_url']) : null,
              child: user['avatar_url'] == null
                  ? const Icon(Icons.person, color: AppTheme.neonPurple) : null,
            ),
            if (rank != null && rank <= 3)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: rank == 1 ? AppTheme.goldAccent : (rank == 2 ? Colors.grey : Colors.brown[300]),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('$rank', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim().isEmpty
              ? '@${user['username']}'
              : '${user['first_name']} ${user['last_name']}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('@${user['username']}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                _badge('⭐ $avgScore', Colors.white24),
                const SizedBox(width: 6),
                _badge('🎓 $certs cert${certs != 1 ? 's' : ''}', Colors.white24),
                const SizedBox(width: 6),
                _badge('Lv ${user['level'] ?? 1}', AppTheme.neonPurple.withValues(alpha: 0.18)),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.person_outline, color: AppTheme.neonBlue, size: 20),
              tooltip: 'View Profile',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfileScreen(username: user['username'])),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, color: AppTheme.neonPurple, size: 20),
              tooltip: 'Message',
              onPressed: () => _sendMessage(user['username']),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: const TextStyle(fontSize: 10, color: Colors.white70)),
    );
  }
}
