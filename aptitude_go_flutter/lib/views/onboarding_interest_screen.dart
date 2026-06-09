import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'register_screen.dart';

class OnboardingInterestScreen extends StatelessWidget {
  final String status;
  
  const OnboardingInterestScreen({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final fields = [
      {
        'title': 'Tech / IT / Software',
        'desc': 'Programming, code logic, debugging, and computer fundamentals.',
        'icon': Icons.code_rounded,
        'value': 'Software Engineering'
      },
      {
        'title': 'Management / Banking / MBA',
        'desc': 'Quantitative, logical reasoning, verbal, and mental calculation.',
        'icon': Icons.trending_up_rounded,
        'value': 'Management / MBA'
      },
      {
        'title': 'Civil Services / Govt Exams',
        'desc': 'General aptitude, verbal ability, logic, and comprehensive attention.',
        'icon': Icons.gavel_rounded,
        'value': 'Government / Civil Services'
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Field"),
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
                  "What is your dream job?",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 26),
                ),
                const SizedBox(height: 12),
                Text(
                  "We prioritize categories corresponding to your target domain.",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 36),
                
                ...fields.map((f) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RegisterScreen(
                              isCompany: false,
                              currentStatus: status,
                              interestedField: f['value'] as String,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                        child: Row(
                          children: [
                            Icon(f['icon'] as IconData, color: AppTheme.neonPurple, size: 28),
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
                              color: context.onSurface.withValues(alpha: 0.30),
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
