import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../widgets/floating_pill_nav_bar.dart';
import 'candidate_dashboard.dart';
import 'recruiter_dashboard.dart';
import 'events_screen.dart';
import 'leaderboard_screen.dart';
import 'inbox_screen.dart';
import 'profile_screen.dart';
import 'candidate_profile_screen.dart';
import 'recruiter_profile_screen.dart';

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

    final navItems = _buildNavItems(isCompany: isCompany, isStaff: isStaff);
    final screens = _buildScreens(isCompany: isCompany, isStaff: isStaff);

    final safeIndex = _currentIndex.clamp(0, screens.length - 1);

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: screens,
      ),
      bottomNavigationBar: FloatingPillNavBar(
        currentIndex: safeIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: navItems,
      ),
    );
  }

  List<FloatingPillNavItem> _buildNavItems({required bool isCompany, required bool isStaff}) {
    if (isStaff) {
      return const [
        FloatingPillNavItem(label: 'Dashboard', icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded),
        FloatingPillNavItem(label: 'Events',    icon: Icons.event_outlined,     activeIcon: Icons.event_rounded),
        FloatingPillNavItem(label: 'Inbox',     icon: Icons.mail_outline,       activeIcon: Icons.mail_rounded),
        FloatingPillNavItem(label: 'Profile',   icon: Icons.person_outline,     activeIcon: Icons.person_rounded),
      ];
    }

    if (isCompany) {
      return const [
        FloatingPillNavItem(label: 'Dashboard',  icon: Icons.business_outlined,   activeIcon: Icons.business_rounded),
        FloatingPillNavItem(label: 'Events',     icon: Icons.event_outlined,       activeIcon: Icons.event_rounded),
        FloatingPillNavItem(label: 'Leaderboard',icon: Icons.leaderboard_outlined, activeIcon: Icons.leaderboard_rounded),
        FloatingPillNavItem(label: 'Inbox',      icon: Icons.mail_outline,         activeIcon: Icons.mail_rounded),
        FloatingPillNavItem(label: 'Profile',    icon: Icons.person_outline,       activeIcon: Icons.person_rounded),
      ];
    }

    return const [
      FloatingPillNavItem(label: 'Home',   icon: Icons.home_outlined,        activeIcon: Icons.home_rounded),
      FloatingPillNavItem(label: 'Events', icon: Icons.event_outlined,       activeIcon: Icons.event_rounded),
      FloatingPillNavItem(label: 'Ranks',  icon: Icons.leaderboard_outlined, activeIcon: Icons.leaderboard_rounded),
      FloatingPillNavItem(label: 'Profile',icon: Icons.person_outline,       activeIcon: Icons.person_rounded),
    ];
  }

  List<Widget> _buildScreens({required bool isCompany, required bool isStaff}) {
    if (isStaff) {
      return const [
        AdminDashboardScreen(),
        EventsScreen(),
        InboxScreen(),
        ProfileScreen(),
      ];
    }

    if (isCompany) {
      return const [
        RecruiterDashboardScreen(),
        EventsScreen(),
        LeaderboardScreen(),
        InboxScreen(),
        RecruiterProfileScreen(),
      ];
    }

    return const [
      CandidateDashboard(),
      EventsScreen(),
      LeaderboardScreen(),
      CandidateProfileScreen(),
    ];
  }
}
