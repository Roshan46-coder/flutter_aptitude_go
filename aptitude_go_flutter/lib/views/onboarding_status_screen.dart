import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'onboarding_interest_screen.dart';

class OnboardingStatusScreen extends StatelessWidget {
  const OnboardingStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final statuses = [
      {'title': 'Student', 'desc': 'Currently enrolled in university or high school.', 'icon': Icons.school_outlined},
      {'title': 'Professional', 'desc': 'Working professional checking or improving skills.', 'icon': Icons.badge_outlined},
      {'title': 'Job Seeker', 'desc': 'Actively looking for internships or job openings.', 'icon': Icons.search_outlined},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Candidate Status"),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "What is your current status?",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 26),
                ),
                const SizedBox(height: 12),
                Text(
                  "We customize test priority recommendations based on your experience status.",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 36),
                
                ...statuses.map((s) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OnboardingInterestScreen(
                              status: s['title'] as String,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                        child: Row(
                          children: [
                            Icon(s['icon'] as IconData, color: AppTheme.neonPurple, size: 28),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s['title'] as String,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    s['desc'] as String,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
