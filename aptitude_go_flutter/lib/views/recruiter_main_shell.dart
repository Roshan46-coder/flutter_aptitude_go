import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../widgets/floating_pill_nav_bar.dart';
import 'recruiter_dashboard.dart';
import 'recruiter_candidates_screen.dart';
import 'recruiter_analytics_screen.dart';
import 'recruiter_profile_screen.dart';
import 'login_screen.dart';

class RecruiterMainShell extends StatefulWidget {
  const RecruiterMainShell({super.key});

  @override
  State<RecruiterMainShell> createState() => _RecruiterMainShellState();
}

class _RecruiterMainShellState extends State<RecruiterMainShell> {
  int _currentIndex = 0;
  Map<String, dynamic>? _dashData;

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
  }

  Future<void> _fetchDashboard() async {
    final api = Provider.of<ApiClient>(context, listen: false);
    try {
      final response = await api.get('recruiter/dashboard/');
      if (mounted) setState(() { _dashData = response.data; });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      RecruiterDashboardScreen(dashData: _dashData, onRefresh: _fetchDashboard),
      RecruiterCandidatesScreen(dashData: _dashData),
      RecruiterAnalyticsScreen(dashData: _dashData),
      const RecruiterProfileScreen(hideAppBar: false),
    ];

    return Scaffold(
      appBar: _currentIndex == 3
          ? null
          : AppBar(
              title: Consumer<ApiClient>(
                builder: (context, api, _) {
                  final name = '${api.currentUser?['first_name'] ?? ''} ${api.currentUser?['last_name'] ?? ''}'.trim();
                  return Text(name.isNotEmpty ? 'Welcome, $name' : 'Recruiter Dashboard');
                },
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout_rounded),
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
              ],
            ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: FloatingPillNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          FloatingPillNavItem(label: 'Dashboard',  icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded),
          FloatingPillNavItem(label: 'Candidates', icon: Icons.people_outline,     activeIcon: Icons.people_rounded),
          FloatingPillNavItem(label: 'Analytics',  icon: Icons.analytics_outlined, activeIcon: Icons.analytics_rounded),
          FloatingPillNavItem(label: 'Profile',    icon: Icons.account_circle_outlined, activeIcon: Icons.account_circle_rounded),
        ],
      ),
    );
  }
}
