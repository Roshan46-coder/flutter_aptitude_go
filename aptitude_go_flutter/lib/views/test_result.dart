import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/api_client.dart';
import '../core/theme.dart';

class TestResultScreen extends StatelessWidget {
  final Map<String, dynamic> resultData;

  const TestResultScreen({super.key, required this.resultData});

  @override
  Widget build(BuildContext context) {
    final int score = resultData['correct'] ?? 0;
    final int total = resultData['total'] ?? 10;
    final int coins = resultData['coins_earned'] ?? 0;
    final int exp = resultData['exp_earned'] ?? 0;
    final bool leveledUp = resultData['leveled_up'] ?? false;
    final List<dynamic> results = resultData['results'] ?? [];
    final apiBaseUrl = () {
      try {
        final api = Provider.of<ApiClient>(context, listen: false);
        return api.baseUrl;
      } catch (_) {}
      return 'http://localhost:8000/api/';
    }();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.popUntil(context, (route) => route.isFirst);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Test Scorecard"),
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Celebration Level Up Banner
              if (leveledUp) ...[
                _buildLevelUpBanner(resultData['new_level'] ?? 2),
                const SizedBox(height: 20),
              ],

              // Main Summary Score Card
              _buildScoreSummaryCard(score, total, coins, exp),
              const SizedBox(height: 24),

              if (results.isNotEmpty) ...[
                Text(
                  "Detailed Answers Review",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
              ],

              // Detail breakdowns list
              ...results.map((res) {
                final isCoding = res['is_coding'] as bool;
                final isCorrect = res['is_correct'] as bool;
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isCorrect ? AppTheme.emeraldGreen.withValues(alpha: 0.1) : AppTheme.livesRed.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                color: isCorrect ? AppTheme.emeraldGreen : AppTheme.livesRed,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Colors.white,
                                    height: 1.4,
                                  ),
                                  children: _buildQuestionSpans(res['question_text'] ?? '', apiBaseUrl),
                                ),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: AppTheme.divider, height: 1),
                        const SizedBox(height: 12),
                        
                        // Answer Details
                        if (isCoding) ...[
                          const Text("Your Code Answer:", style: TextStyle(color: Colors.white30, fontSize: 11)),
                          const SizedBox(height: 4),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.background,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              res['user_code'] != null && res['user_code'].toString().isNotEmpty
                                  ? res['user_code']
                                  : "[No Answer Typed]",
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.white70),
                            ),
                          ),
                        ] else ...[
                          _buildSelectedAndCorrectOptionInfo(res),
                        ],
                        
                        if (res['explanation'] != null && res['explanation'].toString().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Text("Explanation:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.neonPurple)),
                          const SizedBox(height: 4),
                          Text(
                            res['explanation'].toString().replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n'),
                            style: const TextStyle(fontSize: 12, color: Colors.white54, height: 1.4),
                          ),
                        ]
                      ],
                    ),
                  ),
                );
              }),
              
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  icon: const Icon(Icons.home_rounded, size: 20, color: Colors.white),
                  label: const Text(
                    "Back to Dashboard",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelUpBanner(int newLevel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.goldAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.goldAccent, width: 1.5),
      ),
      child: Column(
        children: [
          const Icon(Icons.workspace_premium_rounded, color: AppTheme.goldAccent, size: 48),
          const SizedBox(height: 10),
          const Text(
            "LEVELED UP! 🎉",
            style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.goldAccent, fontSize: 20, letterSpacing: 1.0),
          ),
          const SizedBox(height: 4),
          Text(
            "You reached Level $newLevel! Keep cracking aptitude problems.",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreSummaryCard(int score, int total, int coins, int exp) {
    final double accuracy = total > 0 ? (score / total) * 100 : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          Text(
            "$score / $total",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 44, color: AppTheme.neonPurple),
          ),
          const Text("Score", style: TextStyle(color: Colors.white30, fontSize: 13)),
          const SizedBox(height: 8),
          Text(
            "Accuracy: ${accuracy.toStringAsFixed(0)}%",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: accuracy >= 70
                  ? AppTheme.emeraldGreen
                  : (accuracy >= 40 ? AppTheme.neonBlue : AppTheme.livesRed),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: AppTheme.divider),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Coins Reward
              Column(
                children: [
                  const Icon(Icons.monetization_on, color: AppTheme.goldAccent, size: 28),
                  const SizedBox(height: 6),
                  Text(
                    "+ $coins",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                  ),
                  const Text("Coins", style: TextStyle(color: Colors.white30, fontSize: 11)),
                ],
              ),
              // XP Reward
              Column(
                children: [
                  const Icon(Icons.stars, color: AppTheme.neonPurple, size: 28),
                  const SizedBox(height: 6),
                  Text(
                    "+ $exp",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                  ),
                  const Text("EXP", style: TextStyle(color: Colors.white30, fontSize: 11)),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSelectedAndCorrectOptionInfo(Map<String, dynamic> res) {
    final selectedOpt = res['selected_option'];
    final correctOpt = res['correct_option'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Text("Your Choice: ", style: TextStyle(color: Colors.white30, fontSize: 12)),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                (selectedOpt != null ? selectedOpt['text'] : "[Unanswered]").toString().replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' '),
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: res['is_correct'] ? AppTheme.emeraldGreen : AppTheme.livesRed,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Text("Correct Option: ", style: TextStyle(color: Colors.white30, fontSize: 12)),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                (correctOpt != null ? correctOpt['text'] : "[N/A]").toString().replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' '),
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: AppTheme.emeraldGreen,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<InlineSpan> _buildQuestionSpans(String text, String apiBaseUrl) {
    final spans = <InlineSpan>[];
    final cleanedText = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    final imgRegex = RegExp(r"""<img\s+[^>]*src=["']([^"']+)["'][^>]*>""", caseSensitive: false);
    int lastEnd = 0;

    for (final match in imgRegex.allMatches(cleanedText)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: cleanedText.substring(lastEnd, match.start)));
      }
      final src = match.group(1);
      if (src != null) {
        final filename = () {
          var s = src;
          final lastSlash = s.lastIndexOf('/');
          if (lastSlash != -1) {
            s = s.substring(lastSlash + 1);
          }
          return s;
        }();

        final url = () {
          if (src.startsWith('http://') || src.startsWith('https://')) {
            return src;
          }
          final idx = apiBaseUrl.indexOf('/api/');
          final djangoBase = idx != -1 ? apiBaseUrl.substring(0, idx) : apiBaseUrl;

          if (src.startsWith('/media/') || src.startsWith('media/')) {
            final cleanSrc = src.startsWith('/') ? src : '/$src';
            return '$djangoBase$cleanSrc';
          }

          var cleanSrc = src;
          if (cleanSrc.startsWith('/images/')) {
            cleanSrc = cleanSrc.replaceFirst('/images/', '');
          } else if (cleanSrc.startsWith('images/')) {
            cleanSrc = cleanSrc.replaceFirst('images/', '');
          } else if (cleanSrc.startsWith('/')) {
            cleanSrc = cleanSrc.substring(1);
          }

          return '$djangoBase/media/question_images/$cleanSrc';
        }();

        final isSvg = filename.toLowerCase().endsWith('.svg');
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: CachedNetworkImage(
              imageUrl: url,
              height: 120,
              fit: BoxFit.contain,
              placeholder: (ctx, _) => Container(
                height: 120,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(strokeWidth: 2, color: AppTheme.neonPurple),
              ),
              errorWidget: (ctx, e, st) => Image.asset(
                'assets/images/$filename',
                height: 120,
                fit: BoxFit.contain,
                errorBuilder: (ctx2, e2, st2) => Container(
                  height: 120,
                  alignment: Alignment.center,
                  child: const Icon(Icons.image_outlined, color: Colors.white24, size: 40),
                ),
              ),
            ),
          ),
        ));
      }
      lastEnd = match.end;
    }

    if (lastEnd < cleanedText.length) {
      spans.add(TextSpan(text: cleanedText.substring(lastEnd)));
    }

    if (spans.isEmpty) {
      spans.add(TextSpan(text: cleanedText));
    }

    return spans;
  }
}
