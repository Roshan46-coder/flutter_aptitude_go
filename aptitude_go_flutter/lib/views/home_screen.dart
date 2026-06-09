import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import '../widgets/floating_pill_nav_bar.dart';
import '../widgets/robot_avatar.dart';
import 'login_screen.dart';
import 'candidate_dashboard.dart';
import 'practice_arena.dart';
import 'store.dart';
import 'inbox_screen.dart';
import 'profile_screen.dart';
import 'recruiter_main_shell.dart';
import 'admin_dashboard.dart';
import '../widgets/aptix_chat_bot.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final api = Provider.of<ApiClient>(context);
    final user = api.currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const LoginScreen(),
              transitionDuration: Duration.zero,
            ),
            (route) => false,
          );
        }
      });
      return const SizedBox.shrink();
    }

    // Role-based routing
    if (user['is_superuser'] == true) {
      return const AdminDashboardScreen();
    }

    if (user['is_company'] == true) {
      return const RecruiterMainShell();
    }

    // Candidate Screens Navigation Shell
    final screens = [
      const CandidateDashboard(),
      const PracticeArena(),
      const StoreScreen(),
      const InboxScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: FloatingPillNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          FloatingPillNavItem(label: 'Practice', icon: Icons.dashboard_outlined,    activeIcon: Icons.dashboard_rounded),
          FloatingPillNavItem(label: 'Arena',    icon: Icons.menu_book_outlined,    activeIcon: Icons.menu_book_rounded),
          FloatingPillNavItem(label: 'Store',    icon: Icons.shopping_bag_outlined, activeIcon: Icons.shopping_bag_rounded),
          FloatingPillNavItem(label: 'Chat',     icon: Icons.chat_bubble_outline,   activeIcon: Icons.chat_bubble_rounded),
          FloatingPillNavItem(label: 'Profile',  icon: Icons.account_circle_outlined, activeIcon: Icons.account_circle_rounded),
        ],
      ),
      floatingActionButton: SizedBox(
        width: 56,
        height: 56,
        child: FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const AptixChatBotSheet(),
            );
          },
          backgroundColor: AppTheme.neonPurple,
          child: const RobotAvatar(size: 32, accentColor: Colors.white, autoAnimate: true),
        ),
      ),
    );
  }
}
