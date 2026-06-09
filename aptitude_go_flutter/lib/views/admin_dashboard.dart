import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import '../widgets/floating_pill_nav_bar.dart';
import 'login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  Map<String, dynamic>? _dashData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAdminData();
  }

  Future<void> _fetchAdminData() async {
    setState(() => _isLoading = true);
    final api = Provider.of<ApiClient>(context, listen: false);
    try {
      final response = await api.get('admin/stats/');
      final raw = response.data;
      if (mounted) {
        final rawStats = raw['stats'] as Map<String, dynamic>? ?? raw;
        setState(() {
          _dashData = {
            'stats': {
              'total_users': rawStats['total_users'] ?? raw['total_users'] ?? 0,
              'total_candidates': rawStats['total_candidates'] ?? 0,
              'total_recruiters': rawStats['total_recruiters'] ?? 0,
              'total_questions': rawStats['total_questions'] ?? raw['total_questions'] ?? 0,
              'total_attempts': rawStats['total_attempts'] ?? raw['total_tests_taken'] ?? 0,
              'total_certificates': rawStats['total_certificates'] ?? 0,
            },
            'users': raw['users'] ?? [],
            'categories': raw['categories'] ?? [],
            'events': raw['events'] ?? [],
            'attempts': raw['attempts'] ?? [],
            'certificates': raw['certificates'] ?? [],
            'analytics': raw['analytics'] ?? {},
          };
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _banUser(int userId) async {
    final api = Provider.of<ApiClient>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete User?'),
        content: const Text('This user will be permanently deleted from the platform. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.livesRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await api.post('admin/delete-user/$userId/');
    _fetchAdminData();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.offline_bolt_rounded, color: AppTheme.neonPurple, size: 28),
            const SizedBox(width: 8),
            Text(
              'Aptitude GO Admin',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        actions: [
          // Clear Admin Session secure logout
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.livesRed),
            tooltip: 'Logout',
            onPressed: () async {
              final api = Provider.of<ApiClient>(context, listen: false);
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const LoginScreen(),
                  transitionDuration: Duration.zero,
                ),
                (route) => false,
              );
              await api.logout();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.neonPurple))
          : IndexedStack(
              index: _currentIndex,
              children: [
                _buildOverviewTab(),
                _buildUsersTab(),
                _buildQuestionsTab(),
                _buildEventsTab(),
                _buildAnalyticsTab(),
              ],
            ),
      bottomNavigationBar: FloatingPillNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          FloatingPillNavItem(label: 'Overview',  icon: Icons.dashboard_outlined,       activeIcon: Icons.dashboard_rounded),
          FloatingPillNavItem(label: 'Users',     icon: Icons.people_outline_rounded,   activeIcon: Icons.people_rounded),
          FloatingPillNavItem(label: 'Questions', icon: Icons.quiz_outlined,            activeIcon: Icons.quiz_rounded),
          FloatingPillNavItem(label: 'Exams',     icon: Icons.assignment_outlined,      activeIcon: Icons.assignment_rounded),
          FloatingPillNavItem(label: 'Analytics', icon: Icons.bar_chart_rounded,        activeIcon: Icons.bar_chart_rounded),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final stats = _dashData?['stats'] as Map<String, dynamic>? ?? {};
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return RefreshIndicator(
      onRefresh: _fetchAdminData,
      color: AppTheme.neonPurple,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enterprise Dashboard', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('Platform Statistics & Control Center', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.30), fontSize: 13)),
            const SizedBox(height: 20),

            GridView.count(
              crossAxisCount: isTablet ? 3 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: isTablet ? 1.6 : 1.3,
              children: [
                _adminStatCard('Total Users', '${stats['total_users'] ?? 0}', Icons.people, AppTheme.neonPurple),
                _adminStatCard('Total Recruiters', '${stats['total_recruiters'] ?? 0}', Icons.business_outlined, AppTheme.emeraldGreen),
                _adminStatCard('Total Candidates', '${stats['total_candidates'] ?? 0}', Icons.school_outlined, AppTheme.neonBlue),
                _adminStatCard('Total Questions', '${stats['total_questions'] ?? 0}', Icons.quiz_outlined, AppTheme.goldAccent),
                _adminStatCard('Exams Conducted', '${stats['total_attempts'] ?? 0}', Icons.assignment_outlined, Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _adminStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              const Icon(Icons.arrow_upward_rounded, color: AppTheme.emeraldGreen, size: 14),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.30), fontSize: 11, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    final users = (_dashData?['users'] as List?) ?? [];
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final isCompany = user['is_company'] == true;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            leading: CircleAvatar(
              radius: 22,
              backgroundColor: AppTheme.neonPurple.withOpacity(0.1),
              child: Text(
                (user['username'] as String? ?? '?')[0].toUpperCase(),
                style: const TextStyle(color: AppTheme.neonPurple, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            title: Text(user['username'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user['email'] ?? '', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.30), fontSize: 12)),
                  const SizedBox(height: 6),
                  Row(children: [
                    _roleBadge(isCompany ? 'Recruiter' : 'Candidate', color: isCompany ? AppTheme.emeraldGreen : AppTheme.neonBlue),
                    if (user['is_superuser'] == true) ...[const SizedBox(width: 4), _roleBadge('Superuser', color: AppTheme.goldAccent)],
                  ]),
                ],
              ),
            ),
            trailing: user['is_superuser'] != true
                ? IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppTheme.livesRed,
                      size: 24,
                    ),
                    onPressed: () => _banUser(user['id']),
                    tooltip: 'Delete User',
                  )
                : null,
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _roleBadge(String label, {required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildQuestionsTab() {
    final categories = (_dashData?['categories'] as List?) ?? [];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton.icon(
            onPressed: () => _showAddQuestionDialog(),
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text('Add Question to Bank', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              backgroundColor: AppTheme.neonPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ExpansionTile(
                    title: Text(cat['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${cat['question_count'] ?? 0} questions',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 12)),
                    iconColor: AppTheme.neonPurple,
                    collapsedIconColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.30),
                    children: (cat['questions'] as List? ?? []).map<Widget>((q) {
                      return ListTile(
                        dense: true,
                        title: Text(
                          q['text'] ?? '',
                          style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.70)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text('Difficulty: ${q['difficulty'] ?? 'N/A'}',
                            style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.30))),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.livesRed, size: 20),
                          onPressed: () => _deleteQuestion(q['id']),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showAddQuestionDialog() async {
    final textCtrl = TextEditingController();
    final opt1Ctrl = TextEditingController();
    final opt2Ctrl = TextEditingController();
    final opt3Ctrl = TextEditingController();
    final opt4Ctrl = TextEditingController();
    int correctIndex = 0;
    String difficulty = 'Medium';
    int categoryId = (_dashData?['categories'] as List? ?? []).isNotEmpty
        ? (_dashData!['categories'][0]['id'] as int? ?? 0)
        : 0;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add New Question'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: textCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Question Text', alignLabelWithHint: true),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(4, (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(children: [
                      Radio<int>(
                        value: i,
                        groupValue: correctIndex,
                        onChanged: (v) => setDialogState(() => correctIndex = v!),
                        activeColor: AppTheme.emeraldGreen,
                      ),
                      Expanded(child: TextField(
                        controller: [opt1Ctrl, opt2Ctrl, opt3Ctrl, opt4Ctrl][i],
                        decoration: InputDecoration(labelText: 'Option ${i + 1}'),
                      )),
                    ]),
                  )),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: difficulty,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Difficulty'),
                    items: ['Easy', 'Medium', 'Hard'].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                    onChanged: (v) => setDialogState(() => difficulty = v!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final api = Provider.of<ApiClient>(context, listen: false);
                await api.post('admin/add-question/', data: {
                  'text': textCtrl.text,
                  'options': [opt1Ctrl.text, opt2Ctrl.text, opt3Ctrl.text, opt4Ctrl.text],
                  'correct_index': correctIndex,
                  'difficulty': difficulty,
                  'category_id': categoryId,
                });
                if (ctx.mounted) Navigator.pop(ctx);
                _fetchAdminData();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonPurple),
              child: const Text('Add Question', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteQuestion(int id) async {
    final api = Provider.of<ApiClient>(context, listen: false);
    await api.post('admin/delete-question/$id/');
    _fetchAdminData();
  }

  Widget _buildEventsTab() {
    final events = (_dashData?['events'] as List?) ?? [];
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Text('Events', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                Text('${events.length} total', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38))),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                final isLive = event['is_live'] == true;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isLive ? AppTheme.emeraldGreen.withOpacity(0.4) : Theme.of(context).dividerColor,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              if (isLive)
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.emeraldGreen.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('LIVE', style: TextStyle(color: AppTheme.emeraldGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              Expanded(child: Text(event['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                            ]),
                            const SizedBox(height: 6),
                            Text(
                              '${_formatDate(event['start_time'])} → ${_formatDate(event['end_time'])}',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.30), fontSize: 12),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${event['participant_count'] ?? 0} participants registered',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.livesRed),
                        onPressed: () => _deleteEvent(event['id']),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEvent(int id) async {
    final api = Provider.of<ApiClient>(context, listen: false);
    await api.post('admin/delete-event/$id/');
    _fetchAdminData();
  }

  String _formatDate(String? iso) {
    if (iso == null) return '—';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) { return iso; }
  }

  Widget _buildAnalyticsTab() {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final stats = _dashData?['stats'] as Map<String, dynamic>? ?? {};
    final analytics = _dashData?['analytics'] as Map<String, dynamic>? ?? {};
    final allAttempts = (_dashData?['attempts'] as List?) ?? [];
    final allUsers = (_dashData?['users'] as List?) ?? [];

    final userGrowth = (analytics['user_growth'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [0, 0, 0, 0, 0, 0, 0];
    final examActivity = (analytics['exam_activity'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [0, 0, 0, 0, 0, 0, 0];
    final recruiterActivity = (analytics['recruiter_activity'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [0, 0, 0, 0, 0, 0, 0];
    final questionGrowth = (analytics['question_growth'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [0, 0, 0, 0, 0, 0, 0];

    final completedAttempts = allAttempts.where((a) => a['percentage'] != null).toList();
    final successRate = completedAttempts.isEmpty
        ? 0.0
        : completedAttempts.where((a) => (a['percentage'] as num) >= 70).length / completedAttempts.length * 100;
    final completionRate = allAttempts.isEmpty
        ? 0.0
        : completedAttempts.length / allAttempts.length * 100;
    final avgScore = completedAttempts.isEmpty
        ? 0.0
        : completedAttempts.fold(0.0, (sum, a) => sum + (a['percentage'] as num? ?? 0).toDouble()) / completedAttempts.length;

    final candidates = allUsers.where((u) => u['is_company'] != true).toList();
    final topCandidates = candidates
        .where((u) => u['level'] != null)
        .toList()
      ..sort((a, b) => (b['level'] as int).compareTo(a['level'] as int));

    final now = DateTime.now();
    final dayLabels = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return '${d.day}/${d.month}';
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Platform Analytics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
          const SizedBox(height: 4),
          Text('Real-time platform metrics & user activity', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.30), fontSize: 13)),
          const SizedBox(height: 20),

          _buildMetricRow(stats, isTablet),
          const SizedBox(height: 20),

          if (isTablet)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildChartCard("User Growth", userGrowth, AppTheme.neonPurple, dayLabels)),
                const SizedBox(width: 12),
                Expanded(child: _buildChartCard("Exam Attempts", examActivity, AppTheme.neonBlue, dayLabels)),
              ],
            )
          else ...[
            _buildChartCard("User Growth", userGrowth, AppTheme.neonPurple, dayLabels),
            const SizedBox(height: 12),
            _buildChartCard("Exam Attempts", examActivity, AppTheme.neonBlue, dayLabels),
          ],
          const SizedBox(height: 12),

          if (isTablet)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildChartCard("Recruiter Activity", recruiterActivity, AppTheme.emeraldGreen, dayLabels)),
                const SizedBox(width: 12),
                Expanded(child: _buildChartCard("Question Growth", questionGrowth, AppTheme.goldAccent, dayLabels)),
              ],
            )
          else ...[
            _buildChartCard("Recruiter Activity", recruiterActivity, AppTheme.emeraldGreen, dayLabels),
            const SizedBox(height: 12),
            _buildChartCard("Question Growth", questionGrowth, AppTheme.goldAccent, dayLabels),
          ],
          const SizedBox(height: 20),

          _buildPerformanceSection(successRate, completionRate, avgScore, completedAttempts.length, allAttempts.length, isTablet),
          const SizedBox(height: 20),

          _buildLeaderboardSection(topCandidates.take(10).toList(), isTablet),
        ],
      ),
    );
  }

  Widget _buildMetricRow(Map<String, dynamic> stats, bool isTablet) {
    final metrics = [
      _miniStatCard('Candidates', '${stats['total_candidates'] ?? 0}', Icons.school_outlined, AppTheme.neonBlue),
      _miniStatCard('Recruiters', '${stats['total_recruiters'] ?? 0}', Icons.business_outlined, AppTheme.emeraldGreen),
      _miniStatCard('Exams Taken', '${stats['total_attempts'] ?? 0}', Icons.assignment_outlined, Colors.orange),
      _miniStatCard('Certificates', '${stats['total_certificates'] ?? 0}', Icons.verified_outlined, AppTheme.goldAccent),
    ];

    if (isTablet) {
      return Row(children: metrics.map((m) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: m))).toList());
    }
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: metrics.map((m) => SizedBox(width: (MediaQuery.of(context).size.width - 64) / 2, child: m)).toList(),
    );
  }

  Widget _miniStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87)),
                Text(label, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.30))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(String title, List<double> dataPoints, Color color, List<String> labels) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 3, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ]),
          const SizedBox(height: 14),
          SizedBox(
            height: 160,
            width: double.infinity,
            child: CustomPaint(
              painter: ChartPainter(dataPoints: dataPoints, accentColor: color),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labels.map((l) => Text(l, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24), fontSize: 9))).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceSection(double successRate, double completionRate, double avgScore, int completed, int total, bool isTablet) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 3, height: 16, decoration: BoxDecoration(color: AppTheme.neonPurple, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            const Text('Performance Metrics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ]),
          const SizedBox(height: 16),
          if (isTablet)
            Row(children: [
              Expanded(child: _buildProgressPie('Success Rate', successRate, AppTheme.emeraldGreen)),
              Expanded(child: _buildProgressPie('Completion Rate', completionRate, AppTheme.neonBlue)),
              Expanded(child: _buildProgressPie('Avg Score', avgScore, AppTheme.goldAccent)),
              Expanded(child: _buildProgressPie('Completed', total > 0 ? completed / total * 100 : 0, Colors.orange, suffix: '$completed/$total')),
            ])
          else
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(width: (MediaQuery.of(context).size.width - 76) / 2, child: _buildProgressPie('Success Rate', successRate, AppTheme.emeraldGreen)),
                SizedBox(width: (MediaQuery.of(context).size.width - 76) / 2, child: _buildProgressPie('Completion Rate', completionRate, AppTheme.neonBlue)),
                SizedBox(width: (MediaQuery.of(context).size.width - 76) / 2, child: _buildProgressPie('Avg Score', avgScore, AppTheme.goldAccent)),
                SizedBox(width: (MediaQuery.of(context).size.width - 76) / 2, child: _buildProgressPie('Completed', total > 0 ? completed / total * 100 : 0, Colors.orange, suffix: '$completed/$total')),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildProgressPie(String label, double percentage, Color color, {String? suffix}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 60,
            width: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 60,
                  width: 60,
                  child: CircularProgressIndicator(
                    value: percentage / 100,
                    strokeWidth: 5,
                    backgroundColor: color.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                Text('${percentage.toStringAsFixed(0)}%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.30), fontWeight: FontWeight.w500)),
          if (suffix != null) Text(suffix, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildLeaderboardSection(List<dynamic> topCandidates, bool isTablet) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 3, height: 16, decoration: BoxDecoration(color: AppTheme.goldAccent, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            const Text('Candidate Leaderboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const Spacer(),
            Text('${topCandidates.length} candidates', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.30))),
          ]),
          const SizedBox(height: 12),
          if (topCandidates.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('No candidate data yet', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.30))),
              ),
            )
          else
            ...topCandidates.asMap().entries.map((entry) {
              final i = entry.key;
              final u = entry.value;
              final rankColor = i == 0 ? AppTheme.goldAccent : i == 1 ? Colors.grey[400]! : i == 2 ? Colors.brown[300]! : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15);
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: i == 0 ? AppTheme.goldAccent.withOpacity(0.06) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: i == 0 ? Border.all(color: AppTheme.goldAccent.withOpacity(0.2)) : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(color: rankColor, shape: BoxShape.circle),
                      child: Center(child: Text('${i + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: i < 3 ? Colors.black : Colors.white))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(u['username'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppTheme.neonPurple.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text('Level ${u['level'] ?? 1}', style: TextStyle(color: AppTheme.neonPurple, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class ChartPainter extends CustomPainter {
  final List<double> dataPoints;
  final Color accentColor;

  ChartPainter({required this.dataPoints, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final paintLine = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final paintFill = Paint()
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final maxVal = dataPoints.reduce(max);
    final minVal = 0.0;
    final range = maxVal - minVal;

    final double widthSegment = size.width / (dataPoints.length - 1);

    for (int i = 0; i < dataPoints.length; i++) {
      final x = i * widthSegment;
      final y = size.height - ((dataPoints[i] - minVal) / range) * (size.height - 20) - 10;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        // Compute control points for smooth bezier curve
        final prevX = (i - 1) * widthSegment;
        final prevY = size.height - ((dataPoints[i - 1] - minVal) / range) * (size.height - 20) - 10;
        final controlX1 = prevX + widthSegment / 2;
        final controlY1 = prevY;
        final controlX2 = prevX + widthSegment / 2;
        final controlY2 = y;
        
        path.cubicTo(controlX1, controlY1, controlX2, controlY2, x, y);
        fillPath.cubicTo(controlX1, controlY1, controlX2, controlY2, x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Create shader for premium smooth gradient under the line chart curve
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        accentColor.withOpacity(0.35),
        accentColor.withOpacity(0.0),
      ],
    );

    paintFill.shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, paintFill);
    canvas.drawPath(path, paintLine);

    // Draw little accent points on each data node
    final paintPoint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final paintPointOutline = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < dataPoints.length; i++) {
      final x = i * widthSegment;
      final y = size.height - ((dataPoints[i] - minVal) / range) * (size.height - 20) - 10;

      canvas.drawCircle(Offset(x, y), 4.5, paintPoint);
      canvas.drawCircle(Offset(x, y), 4.5, paintPointOutline);
    }
  }

  @override
  bool shouldRepaint(covariant ChartPainter oldDelegate) =>
      oldDelegate.dataPoints != dataPoints || oldDelegate.accentColor != accentColor;
}
