import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import 'candidate_dashboard.dart';
import 'recruiter_dashboard.dart';
import 'events_screen.dart';
import 'leaderboard_screen.dart';
import 'inbox_screen.dart';
import 'profile_screen.dart';
import 'candidate_profile_screen.dart';
import 'recruiter_profile_screen.dart';
import 'multiplayer_topic_screen.dart';
import 'admin_dashboard.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final api = context.watch<ApiClient>();
    final user = api.currentUser;
    final isCompany  = user?['is_company'] == true;
    final isStaff    = user?['is_staff'] == true;

    // Build dynamic tab list based on role
    final tabs = _buildTabs(isCompany: isCompany, isStaff: isStaff);

    // Clamp index in case role changes
    final safeIndex = _currentIndex.clamp(0, tabs.length - 1);

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: tabs.map((t) => t.screen).toList(),
      ),
      bottomNavigationBar: _buildNavBar(tabs, safeIndex),
    );
  }

  List<_NavTab> _buildTabs({required bool isCompany, required bool isStaff}) {
    if (isStaff) {
      return [
        _NavTab('Dashboard', Icons.dashboard_outlined, Icons.dashboard, const AdminDashboardScreen()),
        _NavTab('Events',    Icons.event_outlined,     Icons.event,     const EventsScreen()),
        _NavTab('Inbox',     Icons.mail_outline,       Icons.mail,      const InboxScreen()),
        _NavTab('Profile',   Icons.person_outline,     Icons.person,    const ProfileScreen()),
      ];
    }

    if (isCompany) {
      return [
        _NavTab('Dashboard',  Icons.business_outlined,   Icons.business,    const RecruiterDashboardScreen()),
        _NavTab('Events',     Icons.event_outlined,       Icons.event,       const EventsScreen()),
        _NavTab('Leaderboard',Icons.leaderboard_outlined, Icons.leaderboard, const LeaderboardScreen()),
        _NavTab('Inbox',      Icons.mail_outline,         Icons.mail,        const InboxScreen()),
        _NavTab('Profile',    Icons.person_outline,       Icons.person,      const RecruiterProfileScreen()),
      ];
    }

    // Candidate (default)
    return [
      _NavTab('Home',       Icons.home_outlined,        Icons.home,        const CandidateDashboard()),
      _NavTab('Battle',     Icons.flash_on_outlined,    Icons.flash_on,    const MultiplayerTopicScreen()),
      _NavTab('Events',     Icons.event_outlined,       Icons.event,       const EventsScreen()),
      _NavTab('Ranks',      Icons.leaderboard_outlined, Icons.leaderboard, const LeaderboardScreen()),
      _NavTab('Profile',    Icons.person_outline,       Icons.person,      const CandidateProfileScreen()),
    ];
  }

  Widget _buildNavBar(List<_NavTab> tabs, int currentIndex) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(top: BorderSide(color: AppTheme.divider)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 62,
          child: Row(
            children: tabs.asMap().entries.map((entry) {
              final i    = entry.key;
              final tab  = entry.value;
              final sel  = i == currentIndex;

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _currentIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Indicator dot + icon
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(
                            horizontal: sel ? 14 : 0,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: sel ? AppTheme.neonPurple.withValues(alpha: 0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            sel ? tab.activeIcon : tab.icon,
                            color: sel ? AppTheme.neonPurple : Colors.white24,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          tab.label,
                          style: TextStyle(
                            fontSize: 10,
                            color: sel ? AppTheme.neonPurple : Colors.white24,
                            fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavTab {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget screen;
  const _NavTab(this.label, this.icon, this.activeIcon, this.screen);
}
