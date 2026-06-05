import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'register_screen.dart';

class CompanyOnboardingScreen extends StatelessWidget {
  const CompanyOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final focuses = [
      {'title': 'Tech & Software Roles', 'desc': 'Looking to evaluate coding skills, logic, and core IT concepts.', 'icon': Icons.computer_rounded, 'value': 'Software Engineering'},
      {'title': 'Management & MBA Roles', 'desc': 'Hiring for product, analytics, marketing, or general business management.', 'icon': Icons.analytics_rounded, 'value': 'Management / MBA'},
      {'title': 'General Recruitment', 'desc': 'General aptitude evaluations across math, verbal, and logical categories.', 'icon': Icons.groups_rounded, 'value': 'General Graduate'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Recruiter Focus"),
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
                  "What is your hiring focus?",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 26),
                ),
                const SizedBox(height: 12),
                Text(
                  "Select the candidate area you are most interested in evaluating.",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 36),
                
                ...focuses.map((f) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RegisterScreen(
                              isCompany: true,
                              hiringFocus: f['value'] as String,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                        child: Row(
                          children: [
                            Icon(f['icon'] as IconData, color: AppTheme.neonBlue, size: 28),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    f['title'] as String,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    f['desc'] as String,
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
