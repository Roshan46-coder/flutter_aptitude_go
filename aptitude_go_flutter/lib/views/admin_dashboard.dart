import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _dashData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchAdminData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAdminData() async {
    setState(() => _isLoading = true);
    final api = Provider.of<ApiClient>(context, listen: false);
    try {
      final response = await api.get('admin/stats/');
      final raw = response.data;
      if (mounted) {
        setState(() {
          _dashData = {
            'stats': {
              'total_users': raw['total_users'] ?? 0,
              'total_candidates': raw['total_candidates'] ?? raw['total_users'] ?? 0,
              'total_recruiters': raw['total_recruiters'] ?? 0,
              'total_questions': raw['total_questions'] ?? 0,
              'total_attempts': raw['total_tests_taken'] ?? 0,
              'active_events': 0,
            },
            'pending_approvals': raw['pending_approvals'] ?? (raw['recent_users'] as List?)?.map((u) => {
              'id': u['id'], 'username': u['username'], 'email': u['email']
            }).toList() ?? [],
            'users': raw['users'] ?? (raw['recent_users'] as List?)?.map((u) => {
              'id': u['id'], 'username': u['username'], 'email': u['email'],
              'is_company': u['is_company'] ?? false,
              'is_staff': u['is_staff'] ?? false,
              'is_superuser': u['is_superuser'] ?? false,
              'is_active': true,
            }).toList() ?? [],
            'categories': raw['categories'] ?? [],
            'events': raw['events'] ?? [],
            'anti_malpractice_enabled': raw['anti_malpractice_enabled'] ?? false,
          };
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approveUser(int userId, bool approve) async {
    final api = Provider.of<ApiClient>(context, listen: false);
    await api.post('admin/approve-user/$userId/', data: {'approve': approve});
    _fetchAdminData();
  }

  Future<void> _banUser(int userId) async {
    // Capture api before async gap
    final api = Provider.of<ApiClient>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User?'),
        content: const Text('This user will be permanently deleted from the platform. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.livesRed),
            child: const Text('Delete'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
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
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Users'),
            Tab(text: 'Questions'),
            Tab(text: 'Events'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.neonPurple))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildUsersTab(),
                _buildQuestionsTab(),
                _buildEventsTab(),
              ],
            ),
    );
  }

  Future<void> _toggleMalpractice() async {
    final api = Provider.of<ApiClient>(context, listen: false);
    try {
      await api.post('admin/toggle-malpractice/');
      _fetchAdminData();
    } catch (_) {}
  }

  Widget _buildOverviewTab() {
    final stats = _dashData?['stats'] as Map<String, dynamic>? ?? {};
    final antiMalpractice = _dashData?['anti_malpractice_enabled'] == true;
    return RefreshIndicator(
      onRefresh: _fetchAdminData,
      color: AppTheme.neonPurple,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Platform Overview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _adminStatCard('Total Users', '${stats['total_users'] ?? 0}', Icons.people, AppTheme.neonPurple),
                _adminStatCard('Candidates', '${stats['total_candidates'] ?? 0}', Icons.school_outlined, AppTheme.neonBlue),
                _adminStatCard('Recruiters', '${stats['total_recruiters'] ?? 0}', Icons.business_outlined, AppTheme.emeraldGreen),
                _adminStatCard('Questions', '${stats['total_questions'] ?? 0}', Icons.quiz_outlined, AppTheme.goldAccent),
                _adminStatCard('Test Attempts', '${stats['total_attempts'] ?? 0}', Icons.assignment_outlined, Colors.orange),
                _adminStatCard('Active Events', '${stats['active_events'] ?? 0}', Icons.event, Colors.cyan),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: antiMalpractice ? AppTheme.emeraldGreen.withValues(alpha: 0.3) : AppTheme.divider),
              ),
              child: Row(
                children: [
                  Icon(
                    antiMalpractice ? Icons.security : Icons.security_outlined,
                    color: antiMalpractice ? AppTheme.emeraldGreen : Colors.white38,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Anti-Malpractice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(
                          antiMalpractice ? 'Enabled - Page switch detection active' : 'Disabled',
                          style: TextStyle(color: antiMalpractice ? AppTheme.emeraldGreen : Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: antiMalpractice,
                    activeColor: AppTheme.emeraldGreen,
                    onChanged: (_) => _toggleMalpractice(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Pending Approvals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            ...(_dashData?['pending_approvals'] as List? ?? []).map((user) => _pendingApprovalCard(user)),
          ],
        ),
      ),
    );
  }

  Widget _adminStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 20)),
              Text(label, style: const TextStyle(color: Colors.white30, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pendingApprovalCard(Map<String, dynamic> user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.pending_actions_outlined, color: AppTheme.goldAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['username'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(user['email'] ?? '', style: const TextStyle(color: Colors.white30, fontSize: 12)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _approveUser(user['id'], false),
            style: TextButton.styleFrom(foregroundColor: AppTheme.livesRed),
            child: const Text('Reject'),
          ),
          const SizedBox(width: 4),
          ElevatedButton(
            onPressed: () => _approveUser(user['id'], true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emeraldGreen,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    final users = (_dashData?['users'] as List?) ?? [];
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.divider),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.neonPurple.withValues(alpha: 0.1),
              child: Text(
                (user['username'] as String? ?? '?')[0].toUpperCase(),
                style: const TextStyle(color: AppTheme.neonPurple, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(user['username'] ?? ''),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['email'] ?? '', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                const SizedBox(height: 2),
                Row(children: [
                  _roleBadge(user['is_company'] == true ? 'Recruiter' : 'Candidate'),
                  if (user['is_staff'] == true) ...[const SizedBox(width: 4), _roleBadge('Admin', color: AppTheme.goldAccent)],
                  if (user['is_active'] == false) ...[const SizedBox(width: 4), _roleBadge('Banned', color: AppTheme.livesRed)],
                ]),
              ],
            ),
            trailing: user['is_superuser'] != true
                ? IconButton(
                    icon: Icon(
                      user['is_active'] == true ? Icons.block : Icons.check_circle_outline,
                      color: user['is_active'] == true ? AppTheme.livesRed : AppTheme.emeraldGreen,
                      size: 22,
                    ),
                    onPressed: () => _banUser(user['id']),
                    tooltip: user['is_active'] == true ? 'Ban User' : 'Unban User',
                  )
                : null,
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _roleBadge(String label, {Color color = AppTheme.neonPurple}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildQuestionsTab() {
    final categories = (_dashData?['categories'] as List?) ?? [];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _showAddQuestionDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add Question'),
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return ExpansionTile(
                title: Text(cat['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${cat['question_count'] ?? 0} questions',
                    style: const TextStyle(color: Colors.white38, fontSize: 12)),
                iconColor: AppTheme.neonPurple,
                children: (cat['questions'] as List? ?? []).map<Widget>((q) {
                  return ListTile(
                    dense: true,
                    title: Text(
                      q['text'] ?? '',
                      style: const TextStyle(fontSize: 13, color: Colors.white70),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text('Difficulty: ${q['difficulty'] ?? 'N/A'}',
                        style: const TextStyle(fontSize: 11, color: Colors.white30)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.white30, size: 20),
                      onPressed: () => _deleteQuestion(q['id']),
                    ),
                  );
                }).toList(),
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
          title: const Text('Add New Question'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: textCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Question Text')),
                  const SizedBox(height: 10),
                  ...List.generate(4, (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
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
                  DropdownButtonFormField<String>(
                    initialValue: difficulty,
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
              child: const Text('Add'),
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _showAddEventDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Create Event'),
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final isLive = event['is_live'] == true;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isLive ? AppTheme.emeraldGreen.withValues(alpha: 0.4) : AppTheme.divider,
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
                                  color: AppTheme.emeraldGreen.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text('LIVE', style: TextStyle(color: AppTheme.emeraldGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            Expanded(child: Text(event['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold))),
                          ]),
                          const SizedBox(height: 4),
                          Text(
                            '${_formatDate(event['start_time'])} → ${_formatDate(event['end_time'])}',
                            style: const TextStyle(color: Colors.white30, fontSize: 12),
                          ),
                          Text(
                            '${event['participant_count'] ?? 0} participants',
                            style: const TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.white30),
                      onPressed: () => _deleteEvent(event['id']),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showAddEventDialog() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime? startTime;
    DateTime? endTime;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Create Event'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Event Title')),
                const SizedBox(height: 10),
                TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description')),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(startTime == null ? 'Select Start Time' : _formatDate(startTime!.toIso8601String()),
                      style: const TextStyle(fontSize: 14)),
                  trailing: const Icon(Icons.calendar_today_outlined, color: AppTheme.neonPurple),
                  onTap: () async {
                    final picked = await showDateTimePicker(ctx);
                    if (picked != null) setState(() => startTime = picked);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(endTime == null ? 'Select End Time' : _formatDate(endTime!.toIso8601String()),
                      style: const TextStyle(fontSize: 14)),
                  trailing: const Icon(Icons.calendar_today_outlined, color: AppTheme.neonPurple),
                  onTap: () async {
                    final picked = await showDateTimePicker(ctx);
                    if (picked != null) setState(() => endTime = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.isEmpty || startTime == null || endTime == null) return;
                final api = Provider.of<ApiClient>(context, listen: false);
                await api.post('events/create/', data: {
                  'title': titleCtrl.text,
                  'description': descCtrl.text,
                  'start_time': startTime!.toIso8601String(),
                  'end_time': endTime!.toIso8601String(),
                });
                if (ctx.mounted) Navigator.pop(ctx);
                _fetchAdminData();
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<DateTime?> showDateTimePicker(BuildContext ctx) async {
    final date = await showDatePicker(
      context: ctx,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !ctx.mounted) return null;
    final time = await showTimePicker(context: ctx, initialTime: TimeOfDay.now());
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
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
}
