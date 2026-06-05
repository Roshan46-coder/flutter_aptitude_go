import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import 'test_interface.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _upcoming = [];
  List<dynamic> _active = [];
  List<dynamic> _past = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchEvents() async {
    setState(() => _isLoading = true);
    final api = Provider.of<ApiClient>(context, listen: false);
    try {
      final response = await api.get('events/dashboard/');
      if (mounted) {
        final List<dynamic> allEvents = response.data['student_events'] ?? response.data['recruiter_events'] ?? [];
        final upcoming = <dynamic>[];
        final active = <dynamic>[];
        final past = <dynamic>[];
        for (final ev in allEvents) {
          final status = ev['status'] as String? ?? '';
          if (status == 'LIVE') {
            active.add(ev);
          } else if (status == 'ENDED') {
            past.add(ev);
          } else {
            upcoming.add(ev);
          }
        }
        setState(() {
          _upcoming = upcoming;
          _active   = active;
          _past     = past;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _registerForEvent(int eventId, String title) async {
    final api = Provider.of<ApiClient>(context, listen: false);
    try {
      final res = await api.post('events/$eventId/register/');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res.data['message'] ?? 'Registered for "$title"'),
          backgroundColor: AppTheme.emeraldGreen,
        ));
        _fetchEvents();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Registration failed.'),
          backgroundColor: AppTheme.livesRed,
        ));
      }
    }
  }

  Future<void> _startEventExam(Map<String, dynamic> event) async {
    final api = Provider.of<ApiClient>(context, listen: false);
    try {
      final res = await api.get('events/${event['id']}/');
      final questions = res.data['questions'] as List<dynamic>?;
      if (questions == null || questions.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No questions available for this event.')),
          );
        }
        return;
      }
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TestInterfaceScreen(
              categorySlug: event['category'] ?? event['id'].toString(),
            ),
          ),
        ).then((_) => _fetchEvents());
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events & Contests'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.neonPurple,
          tabs: [
            Tab(text: 'Live (${_active.length})'),
            Tab(text: 'Upcoming (${_upcoming.length})'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.neonPurple))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildEventList(_active, isActive: true),
                _buildEventList(_upcoming, isUpcoming: true),
                _buildEventList(_past, isPast: true),
              ],
            ),
    );
  }

  Widget _buildEventList(
    List<dynamic> events, {
    bool isActive = false,
    bool isUpcoming = false,
    bool isPast = false,
  }) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? Icons.live_tv_outlined
                  : isUpcoming ? Icons.upcoming_outlined
                  : Icons.history,
              size: 56,
              color: Colors.white12,
            ),
            const SizedBox(height: 14),
            Text(
              isActive ? 'No live events right now.'
                  : isUpcoming ? 'No upcoming events.'
                  : 'No past events.',
              style: const TextStyle(color: Colors.white30),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchEvents,
      color: AppTheme.neonPurple,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: events.length,
        itemBuilder: (context, index) =>
            _eventCard(events[index], isActive: isActive, isUpcoming: isUpcoming, isPast: isPast),
      ),
    );
  }

  Widget _eventCard(
    Map<String, dynamic> event, {
    bool isActive = false,
    bool isUpcoming = false,
    bool isPast = false,
  }) {
    final isRegistered  = event['is_registered'] == true;
    final hasCompleted  = event['is_completed'] == true;
    final myScore       = event['score'];
    final participants  = event['registrations_count'] ?? event['completed_count'] ?? 0;

    Color accentColor = isActive
        ? AppTheme.emeraldGreen
        : isUpcoming
            ? AppTheme.neonPurple
            : Colors.white24;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
        boxShadow: isActive
            ? [BoxShadow(color: AppTheme.emeraldGreen.withValues(alpha: 0.08), blurRadius: 16)]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                if (isActive)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.emeraldGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(children: [
                      Container(
                        width: 6, height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: AppTheme.emeraldGreen,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text('LIVE', style: TextStyle(
                        color: AppTheme.emeraldGreen, fontSize: 10, fontWeight: FontWeight.bold,
                      )),
                    ]),
                  ),
                Expanded(
                  child: Text(
                    event['title'] ?? 'Event',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((event['description'] ?? '').isNotEmpty) ...[
                  Text(
                    event['description'],
                    style: const TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                ],

                // Time info
                Row(children: [
                  const Icon(Icons.calendar_today_outlined, size: 13, color: Colors.white30),
                  const SizedBox(width: 6),
                  Text(
                    isActive
                        ? 'Ends: ${_formatDate(event['end_time'])}'
                        : isPast
                            ? 'Ended: ${_formatDate(event['end_time'])}'
                            : 'Starts: ${_formatDate(event['start_time'])}',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.people_outline, size: 13, color: Colors.white30),
                  const SizedBox(width: 6),
                  Text('$participants participants',
                      style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ]),

                if (myScore != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.goldAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.3)),
                    ),
                    child: Text('Your score: $myScore',
                        style: const TextStyle(color: AppTheme.goldAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],

                const SizedBox(height: 14),

                // Action button
                SizedBox(
                  width: double.infinity,
                  child: _buildActionButton(
                    event, isActive: isActive, isUpcoming: isUpcoming, isPast: isPast,
                    isRegistered: isRegistered, hasCompleted: hasCompleted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    Map<String, dynamic> event, {
    required bool isActive,
    required bool isUpcoming,
    required bool isPast,
    required bool isRegistered,
    required bool hasCompleted,
  }) {
    if (isPast) {
      return OutlinedButton.icon(
        onPressed: () => _viewLeaderboard(event['id']),
        icon: const Icon(Icons.leaderboard_outlined, size: 16),
        label: const Text('View Leaderboard'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white38,
          side: const BorderSide(color: Colors.white12),
        ),
      );
    }

    if (isActive && isRegistered && !hasCompleted) {
      return ElevatedButton.icon(
        onPressed: () => _startEventExam(event),
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('Start Exam'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.emeraldGreen,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      );
    }

    if (hasCompleted) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check_circle, size: 16, color: AppTheme.emeraldGreen),
        label: const Text('Completed', style: TextStyle(color: AppTheme.emeraldGreen)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppTheme.emeraldGreen.withValues(alpha: 0.3)),
        ),
      );
    }

    if (isRegistered) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check, size: 16, color: AppTheme.neonPurple),
        label: const Text('Registered', style: TextStyle(color: AppTheme.neonPurple)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppTheme.neonPurple.withValues(alpha: 0.3)),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: () => _registerForEvent(event['id'], event['title'] ?? ''),
      icon: const Icon(Icons.how_to_reg_rounded, size: 16),
      label: const Text('Register'),
      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
    );
  }

  void _viewLeaderboard(int eventId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EventLeaderboardScreen(eventId: eventId)),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '—';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) { return iso; }
  }
}

// ─── Event Leaderboard ────────────────────────────────────────────────────────
class EventLeaderboardScreen extends StatefulWidget {
  final int eventId;
  const EventLeaderboardScreen({super.key, required this.eventId});

  @override
  State<EventLeaderboardScreen> createState() => _EventLeaderboardScreenState();
}

class _EventLeaderboardScreenState extends State<EventLeaderboardScreen> {
  List<dynamic> _entries = [];
  bool _isLoading = true;
  String _eventTitle = 'Event Leaderboard';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final api = Provider.of<ApiClient>(context, listen: false);
    try {
      final res = await api.get('events/${widget.eventId}/results/');
      if (mounted) {
        setState(() {
          _eventTitle = res.data['event_title'] ?? 'Event Leaderboard';
          _entries = res.data['leaderboard'] ?? [];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_eventTitle)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.neonPurple))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _entries.length,
              itemBuilder: (context, index) {
                final entry = _entries[index];
                final rank = index + 1;
                final medalColor = rank == 1
                    ? AppTheme.goldAccent
                    : rank == 2
                        ? Colors.grey
                        : rank == 3
                            ? Colors.brown[300]!
                            : Colors.white24;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: rank <= 3 ? medalColor.withValues(alpha: 0.3) : AppTheme.divider,
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 36,
                        child: rank <= 3
                            ? Text(rank == 1 ? '🥇' : rank == 2 ? '🥈' : '🥉',
                                style: const TextStyle(fontSize: 22), textAlign: TextAlign.center)
                            : Text('#$rank',
                                style: const TextStyle(color: Colors.white24, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(entry['username'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w500))),
                      Text('${entry['score']} pts',
                          style: TextStyle(color: medalColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
