import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import 'recruiter_candidate_view.dart';
import 'recruiter_exam_screen.dart';

class RecruiterDashboardScreen extends StatefulWidget {
  final Map<String, dynamic>? dashData;
  final Future<void> Function()? onRefresh;

  const RecruiterDashboardScreen({
    super.key,
    this.dashData,
    this.onRefresh,
  });

  @override
  State<RecruiterDashboardScreen> createState() => _RecruiterDashboardScreenState();
}

class _RecruiterDashboardScreenState extends State<RecruiterDashboardScreen> {
  Map<String, dynamic>? _examDetail;
  Map<String, dynamic>? _selectedExam;
  bool _loadingDetail = false;
  String _searchQuery = '';
  String _sortBy = 'score_desc';
  String _filterStatus = 'all';

  void _viewExamCandidates(Map<String, dynamic> exam) async {
    setState(() { _loadingDetail = true; _selectedExam = exam; });
    final api = Provider.of<ApiClient>(context, listen: false);
    try {
      final res = await api.get('recruiter/exam-results/${exam['id']}/');
      if (mounted) {
        setState(() {
          _examDetail = res.data;
          _loadingDetail = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingDetail = false);
    }
  }

  void _backToList() {
    setState(() {
      _examDetail = null;
      _selectedExam = null;
    });
  }

  List<Map<String, dynamic>> _filteredCandidates() {
    final candidates = List<Map<String, dynamic>>.from(
      (_examDetail?['candidates'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? []
    );

    var filtered = candidates.where((c) {
      if (_filterStatus == 'passed' && c['passed'] != true) return false;
      if (_filterStatus == 'failed' && c['passed'] == true) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final name = '${c['first_name'] ?? ''} ${c['last_name'] ?? ''}'.toLowerCase();
        final uname = (c['username'] as String? ?? '').toLowerCase();
        final email = (c['email'] as String? ?? '').toLowerCase();
        if (!name.contains(q) && !uname.contains(q) && !email.contains(q)) return false;
      }
      return true;
    }).toList();

    switch (_sortBy) {
      case 'score_desc':
        filtered.sort((a, b) => (b['score'] as num).compareTo(a['score'] as num));
        break;
      case 'score_asc':
        filtered.sort((a, b) => (a['score'] as num).compareTo(b['score'] as num));
        break;
      case 'name':
        filtered.sort((a, b) {
          final na = '${a['first_name'] ?? ''} ${a['last_name'] ?? ''}'.trim().toLowerCase();
          final nb = '${b['first_name'] ?? ''} ${b['last_name'] ?? ''}'.trim().toLowerCase();
          return na.compareTo(nb);
        });
        break;
      case 'date':
        filtered.sort((a, b) {
          final da = a['completed_at'] as String? ?? '';
          final db = b['completed_at'] as String? ?? '';
          return db.compareTo(da);
        });
        break;
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final stats = widget.dashData?['stats'] as Map<String, dynamic>? ?? {};
    final exams = List<Map<String, dynamic>>.from(
      (widget.dashData?['exams'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? []
    );

    if (_examDetail != null && _selectedExam != null) {
      return _buildExamDetailView();
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh ?? () async {},
      color: AppTheme.neonPurple,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Platform Statistics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1.5,
                    child: _statCard('Total Candidates', '${stats['total_candidates'] ?? 0}', Icons.people_outline, AppTheme.neonPurple, context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1.5,
                    child: _statCard('Tests Taken', '${stats['total_attempts'] ?? 0}', Icons.quiz_outlined, AppTheme.neonBlue, context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 3.0,
              child: _statCard('Avg Score', ((stats['avg_score'] ?? 0.0) as num).toStringAsFixed(1), Icons.bar_chart, AppTheme.goldAccent, context),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Exam Management', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const RecruiterExamScreen()));
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Create Exam', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (exams.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  children: [
                    Icon(Icons.quiz_outlined, size: 48, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
                    const SizedBox(height: 12),
                    Text('No exams created yet',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 15)),
                    const SizedBox(height: 8),
                    Text('Create your first exam to see results here',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 12)),
                  ],
                ),
              )
            else
              ...exams.map((exam) => _buildExamCard(exam, context)),
          ],
        ),
      ),
    );
  }

  Widget _buildExamCard(Map<String, dynamic> exam, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _viewExamCandidates(exam),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.neonPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.quiz_outlined, color: AppTheme.neonPurple, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exam['title'] ?? 'Untitled Exam',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('${exam['participant_count'] ?? 0} participants  •  ${exam['total_questions'] ?? 0} questions',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: exam['status'] == 'LIVE'
                      ? AppTheme.emeraldGreen.withValues(alpha: 0.15)
                      : exam['status'] == 'ENDED'
                          ? Colors.grey.withValues(alpha: 0.15)
                          : AppTheme.neonBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  exam['status'] as String? ?? 'UPCOMING',
                  style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.bold,
                    color: exam['status'] == 'LIVE'
                        ? AppTheme.emeraldGreen
                        : exam['status'] == 'ENDED'
                            ? Colors.grey
                            : AppTheme.neonBlue,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppTheme.neonPurple, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExamDetailView() {
    final analytics = _examDetail?['analytics'] as Map<String, dynamic>? ?? {};
    final candidates = _filteredCandidates();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _backToList,
        ),
        title: Text(_selectedExam?['title'] ?? 'Exam Results'),
      ),
      body: _loadingDetail
          ? const Center(child: CircularProgressIndicator(color: AppTheme.neonPurple))
          : RefreshIndicator(
              onRefresh: () async => _viewExamCandidates(_selectedExam!),
              color: AppTheme.neonPurple,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAnalyticsRow(analytics),
                    const SizedBox(height: 20),
                    _buildSearchSortBar(),
                    const SizedBox(height: 12),
                    if (candidates.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        width: double.infinity,
                        child: Column(
                          children: [
                            Icon(Icons.people_outline, size: 48, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
                            const SizedBox(height: 12),
                            Text('No candidates found',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4))),
                          ],
                        ),
                      )
                    else
                      ...candidates.map((c) => _buildCandidateCard(c)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAnalyticsRow(Map<String, dynamic> analytics) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _analyticsChip('Total', '${analytics['total_candidates'] ?? 0}', Icons.people, AppTheme.neonPurple),
              _analyticsChip('Avg Score', '${analytics['average_score'] ?? 0}', Icons.score, AppTheme.neonBlue),
              _analyticsChip('Highest', '${analytics['highest_score'] ?? 0}', Icons.trending_up, AppTheme.emeraldGreen),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _analyticsChip('Lowest', '${analytics['lowest_score'] ?? 0}', Icons.trending_down, AppTheme.livesRed),
              _analyticsChip('Avg %', '${analytics['average_percentage'] ?? 0}%', Icons.pie_chart, AppTheme.goldAccent),
              _analyticsChip('Pass %', '${analytics['pass_percentage'] ?? 0}%', Icons.verified, AppTheme.emeraldGreen),
            ],
          ),
        ],
      ),
    );
  }

  Widget _analyticsChip(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
          Text(label, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4))),
        ],
      ),
    );
  }

  Widget _buildSearchSortBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search candidates...',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildDropdown('Sort', _sortBy, [
                  'score_desc', 'score_asc', 'name', 'date',
                ], [
                  'Highest Score', 'Lowest Score', 'Name', 'Date Attempted',
                ], (v) => setState(() => _sortBy = v!)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDropdown('Filter', _filterStatus, [
                  'all', 'passed', 'failed',
                ], [
                  'All', 'Passed', 'Failed',
                ], (v) => setState(() => _filterStatus = v!)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> values, List<String> labels, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      items: List.generate(values.length, (i) => DropdownMenuItem(value: values[i], child: Text(labels[i], style: const TextStyle(fontSize: 12)))),
      onChanged: onChanged,
    );
  }

  Widget _buildCandidateCard(Map<String, dynamic> candidate) {
    final name = '${candidate['first_name'] ?? ''} ${candidate['last_name'] ?? ''}'.trim();
    final displayName = name.isNotEmpty ? name : (candidate['username'] ?? 'Unknown');
    final passed = candidate['passed'] == true;
    final percentage = (candidate['percentage'] as num?)?.toDouble() ?? 0.0;
    final score = candidate['score'] ?? 0;
    final total = candidate['total_questions'] ?? 0;
    final completedAt = candidate['completed_at'] as String? ?? '';
    final rank = candidate['rank'];
    final hasCert = candidate['has_certificate'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: passed
            ? AppTheme.emeraldGreen.withValues(alpha: 0.3)
            : Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppTheme.neonPurple.withValues(alpha: 0.15),
                  child: Text(
                    (displayName.isNotEmpty ? displayName[0] : '?').toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.neonPurple),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(child: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                          if (rank != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: rank <= 3 ? AppTheme.goldAccent.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('#$rank', style: TextStyle(
                                fontSize: 10, fontWeight: FontWeight.bold,
                                color: rank <= 3 ? AppTheme.goldAccent : Colors.grey,
                              )),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(candidate['email'] as String? ?? '',
                        style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4))),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: passed ? AppTheme.emeraldGreen.withValues(alpha: 0.15) : AppTheme.livesRed.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        passed ? 'PASS' : 'FAIL',
                        style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold,
                          color: passed ? AppTheme.emeraldGreen : AppTheme.livesRed,
                        ),
                      ),
                    ),
                    if (hasCert) ...[
                      const SizedBox(height: 3),
                      Icon(Icons.verified, color: AppTheme.emeraldGreen, size: 16),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _infoBadge('$score/$total', Icons.score, AppTheme.neonPurple),
                const SizedBox(width: 8),
                _infoBadge('${percentage.toStringAsFixed(1)}%', Icons.pie_chart, percentage >= 70 ? AppTheme.emeraldGreen : AppTheme.goldAccent),
                const SizedBox(width: 8),
                _infoBadge(_formatDate(completedAt), Icons.calendar_today, AppTheme.neonBlue),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RecruiterCandidateView(username: candidate['username']),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person_outline, size: 16),
                    label: const Text('View Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.neonBlue,
                      side: BorderSide(color: AppTheme.neonBlue.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openChat(candidate['username'] as String? ?? ''),
                    icon: const Icon(Icons.chat_bubble_outline, size: 16),
                    label: const Text('Message', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.neonPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoBadge(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  void _openChat(String username) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ChatSheet(participant: username),
    );
  }

  String _formatDate(String iso) {
    if (iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso.length > 10 ? iso.substring(0, 10) : iso;
    }
  }

  Widget _statCard(String label, String value, IconData icon, Color color, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
              Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChatSheet extends StatefulWidget {
  final String participant;
  const _ChatSheet({required this.participant});

  @override
  State<_ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends State<_ChatSheet> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final api = Provider.of<ApiClient>(context, listen: false);
    final currentUser = api.currentUser;
    final currentUsername = currentUser?['username'] as String? ?? '';

    final inboxRes = await api.get('inbox/');
    final conversations = List<Map<String, dynamic>>.from(
      ((inboxRes.data['conversations'] as List?)?..map((e) => Map<String, dynamic>.from(e))) ?? []
    );

    int? foundId;
    for (final conv in conversations) {
      final participants = List<String>.from(conv['participants'] ?? []);
      if (participants.contains(currentUsername) && participants.contains(widget.participant)) {
        foundId = conv['conversation_id'] as int?;
        break;
      }
    }

    if (foundId != null) {
      final chatRes = await api.get('chat/$foundId/', queryParameters: {'other_user': widget.participant});
      final data = chatRes.data is Map ? Map<String, dynamic>.from(chatRes.data) : {};
      final msgs = List<Map<String, dynamic>>.from(
        (data['messages'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? []
      );
      if (mounted) setState(() { _messages = msgs; _loading = false; });
      Future.delayed(const Duration(milliseconds: 100), () => _scrollToBottom());
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    final api = Provider.of<ApiClient>(context, listen: false);
    final currentUser = api.currentUser;
    final currentUsername = currentUser?['username'] as String? ?? '';

    setState(() {
      _messages.add({
        'sender': currentUsername,
        'content': text,
        'timestamp': DateTime.now().toIso8601String(),
      });
    });
    Future.delayed(const Duration(milliseconds: 50), _scrollToBottom);

    await api.post('recruiter/message/', data: {'to': widget.participant, 'message': text});
    _loadMessages();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final api = Provider.of<ApiClient>(context);
    final currentUsername = api.currentUser?['username'] as String? ?? '';

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.neonPurple.withValues(alpha: 0.15),
                  child: Text(
                    (widget.participant.isNotEmpty ? widget.participant[0] : '?').toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.neonPurple, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 10),
                Text('Chat with ${widget.participant}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.neonPurple))
                : _messages.isEmpty
                    ? Center(
                        child: Text('Start a conversation',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4))),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (ctx, i) {
                          final msg = _messages[i];
                          final isMe = msg['sender'] == currentUsername;
                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isMe ? AppTheme.neonPurple : Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(16).copyWith(
                                  bottomRight: isMe ? const Radius.circular(4) : null,
                                  bottomLeft: !isMe ? const Radius.circular(4) : null,
                                ),
                                border: !isMe ? Border.all(color: Theme.of(context).dividerColor) : null,
                              ),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                              child: Column(
                                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Text(msg['content'] ?? '',
                                    style: TextStyle(color: isMe ? Colors.white : Theme.of(context).colorScheme.onSurface, fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Text(_formatChatTime(msg['timestamp'] as String? ?? ''),
                                    style: TextStyle(fontSize: 9, color: isMe ? Colors.white60 : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4))),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppTheme.neonPurple,
                  radius: 20,
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatChatTime(String iso) {
    if (iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso);
      final now = DateTime.now();
      if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
      return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}
