import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/hive_database.dart';
import '../core/theme.dart';
import 'recruiter_candidate_view.dart';

class RecruiterCandidatesScreen extends StatefulWidget {
  final Map<String, dynamic>? dashData;

  const RecruiterCandidatesScreen({super.key, this.dashData});

  @override
  State<RecruiterCandidatesScreen> createState() => _RecruiterCandidatesScreenState();
}

class _RecruiterCandidatesScreenState extends State<RecruiterCandidatesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Top People
  List<Map<String, dynamic>> _topPeople = [];
  bool _topLoading = false;
  String? _topError;

  // Search by Role
  String _selectedRole = '';
  List<Map<String, dynamic>> _roleCandidates = [];
  bool _roleLoading = false;
  String? _roleError;

  // Cache key for top people
  static const String _topCacheKey = 'cached_top_people';

  static const List<String> roles = [
    'Software Engineer',
    'Data Analyst',
    'Data Scientist',
    'Project Manager',
    'Product Manager',
    'UI/UX Designer',
    'HR Executive',
    'Marketing Specialist',
    'Business Analyst',
    'Cyber Security Analyst',
    'Cloud Engineer',
    'DevOps Engineer',
    'QA Engineer',
    'Full Stack Developer',
    'Frontend Developer',
    'Backend Developer',
    'Mobile App Developer',
    'AI/ML Engineer',
    'Network Engineer',
    'Database Administrator',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadCachedTopPeople();
    _fetchTopPeople();
    if (roles.isNotEmpty) {
      _selectedRole = roles.first;
      _fetchByRole();
    }
  }

  void _loadCachedTopPeople() {
    try {
      final cached = HiveDatabase.instance.getCachedTopPeople();
      if (cached.isNotEmpty) {
        setState(() => _topPeople = cached);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
  }

  Future<void> _fetchTopPeople() async {
    setState(() {
      _topLoading = true;
      _topError = null;
    });
    final api = Provider.of<ApiClient>(context, listen: false);
    try {
      final response = await api.get('recruiter/top-people/');
      if (mounted) {
        final raw = response.data['results'] as List? ?? [];
        final people = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        // Sort by rank (already sorted from backend but ensure client-side too)
        people.sort((a, b) =>
          ((a['rank'] as num?)?.toInt() ?? 999).compareTo((b['rank'] as num?)?.toInt() ?? 999));
        setState(() {
          _topPeople = people;
          _topLoading = false;
        });
        HiveDatabase.instance.saveCachedTopPeople(people);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _topError = 'Failed to load top candidates.';
          _topLoading = false;
        });
      }
    }
  }

  Future<void> _fetchByRole() async {
    if (_selectedRole.isEmpty) return;
    setState(() {
      _roleLoading = true;
      _roleError = null;
    });
    final api = Provider.of<ApiClient>(context, listen: false);
    try {
      final response = await api.get(
        'recruiter/search/',
        queryParameters: {'role': _selectedRole},
      );
      if (mounted) {
        final raw = response.data['results'] as List? ?? [];
        final candidates = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        // Sort by profile_score then level for best ranking
        candidates.sort((a, b) {
          final scoreA = (a['profile_score'] as num?)?.toInt() ?? 0;
          final scoreB = (b['profile_score'] as num?)?.toInt() ?? 0;
          if (scoreB != scoreA) return scoreB.compareTo(scoreA);
          return ((b['level'] as num?)?.toInt() ?? 0).compareTo((a['level'] as num?)?.toInt() ?? 0);
        });
        setState(() {
          _roleCandidates = candidates;
          _roleLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _roleError = 'Failed to load candidates. Make sure the server is running.';
          _roleLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: AppTheme.neonPurple,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          indicatorColor: AppTheme.neonPurple,
          tabs: const [
            Tab(text: 'Top People'),
            Tab(text: 'Search by Role'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTopPeopleTab(),
              _buildSearchByRoleTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopPeopleTab() {
    if (_topLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.neonPurple));
    }
    if (_topError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, size: 48, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25)),
              const SizedBox(height: 16),
              Text(_topError!, style: const TextStyle(color: AppTheme.livesRed)),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: _fetchTopPeople,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_topPeople.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.emoji_events_outlined, size: 64, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15)),
              const SizedBox(height: 16),
              Text(
                'No candidates registered yet',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            '${_topPeople.length} candidate${_topPeople.length == 1 ? '' : 's'} ranked by level, score, certificates & more',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchTopPeople,
            color: AppTheme.neonPurple,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: _topPeople.length,
              itemBuilder: (context, index) => _candidateCard(
                _topPeople[index],
                rank: _topPeople[index]['rank'] as int?,
                showRole: true,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchByRoleTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Browse Candidates by Role',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 42,
                child: DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.work_outline, size: 20),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 14)))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedRole = val);
                      _fetchByRole();
                    }
                  },
                  dropdownColor: Theme.of(context).cardColor,
                ),
              ),
            ],
          ),
        ),
        if (_roleError != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.livesRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.livesRed.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppTheme.livesRed, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_roleError!, style: const TextStyle(color: AppTheme.livesRed, fontSize: 13))),
                  TextButton(
                    onPressed: _fetchByRole,
                    child: const Text('Retry', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
        if (_roleLoading)
          const Expanded(
            child: Center(child: CircularProgressIndicator(color: AppTheme.neonPurple)),
          )
        else if (_roleCandidates.isEmpty)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15)),
                    const SizedBox(height: 16),
                    Text(
                      'No candidates found for this role',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Candidates appear here when they register with "$_selectedRole" as their interested field.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
                    children: [
                      Text(
                        '${_roleCandidates.length} candidate${_roleCandidates.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.sort, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
                      const SizedBox(width: 4),
                      Text(
                        'sorted by level',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchByRole,
                    color: AppTheme.neonPurple,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: _roleCandidates.length,
                      itemBuilder: (context, index) => _candidateCard(
                        _roleCandidates[index],
                        showRole: false,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _candidateCard(Map<String, dynamic> candidate, {int? rank, bool showRole = false}) {
    final name = '${candidate['first_name'] ?? ''} ${candidate['last_name'] ?? ''}'.trim();
    final displayName = name.isNotEmpty ? name : '@${candidate['username'] ?? ''}';
    final level = HiveDatabase.levelInfo(candidate['exp'] ?? 0)[0];
    final avgScore = (candidate['avg_score'] as num?)?.toStringAsFixed(1) ?? '—';
    final totalScore = candidate['total_score'] ?? '—';
    final avatarUrl = candidate['avatar_url'] as String?;
    final role = candidate['interested_field'] as String? ?? '';
    final certCount = candidate['certificate_count'] ?? 0;
    final examsDone = candidate['exams_completed'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      color: Theme.of(context).cardColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RecruiterCandidateView(username: candidate['username']),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Profile picture with rank badge
              Stack(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.neonPurple.withValues(alpha: 0.1),
                    backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                    child: (avatarUrl == null || avatarUrl.isEmpty)
                        ? Text(
                            (displayName.isNotEmpty ? displayName[0] : '?').toUpperCase(),
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.neonPurple),
                          )
                        : null,
                  ),
                  if (rank != null && rank <= 3)
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: rank == 1
                              ? const Color(0xFFFFD700)
                              : (rank == 2 ? Colors.grey[400] : Colors.brown[300]),
                          shape: BoxShape.circle,
                          border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            '$rank',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Level + Score row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.neonPurple.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome, size: 12, color: AppTheme.neonPurple.withValues(alpha: 0.8)),
                              const SizedBox(width: 4),
                              Text(
                                'Level $level',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.neonPurple.withValues(alpha: 0.9)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.emeraldGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, size: 12, color: AppTheme.emeraldGreen.withValues(alpha: 0.8)),
                              const SizedBox(width: 4),
                              Text(
                                avgScore,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.emeraldGreen.withValues(alpha: 0.9)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Role + certs row
                    Row(
                      children: [
                        if (role.isNotEmpty) ...[
                          Icon(Icons.work_outline, size: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              role,
                              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Icon(Icons.verified, size: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45)),
                        const SizedBox(width: 4),
                        Text(
                          '$certCount cert${certCount == 1 ? '' : 's'}',
                          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55)),
                        ),
                        if (totalScore is int && totalScore > 0) ...[
                          Icon(Icons.trending_up, size: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45)),
                          const SizedBox(width: 4),
                          Text(
                            '$totalScore pts',
                            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55)),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (examsDone is int && examsDone > 0) ...[
                          Icon(Icons.assignment, size: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45)),
                          const SizedBox(width: 4),
                          Text(
                            '$examsDone exam${examsDone == 1 ? '' : 's'}',
                            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55)),
                          ),
                          const SizedBox(width: 12),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
