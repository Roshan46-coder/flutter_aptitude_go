import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import 'matchmaking_screen.dart';

class MultiplayerTopicScreen extends StatefulWidget {
  const MultiplayerTopicScreen({super.key});

  @override
  State<MultiplayerTopicScreen> createState() => _MultiplayerTopicScreenState();
}

class _MultiplayerTopicScreenState extends State<MultiplayerTopicScreen> {
  List<dynamic> _categories = [];
  bool _isLoading = true;
  int? _selectedCategory;
  String _difficulty = 'Medium';

  final List<String> _difficulties = ['Easy', 'Medium', 'Hard'];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    final api = Provider.of<ApiClient>(context, listen: false);
    try {
      final response = await api.get('tests/practice/');
      // Extract categories from general_categories (which have id, name, slug, q_count)
      final general = (response.data['general_categories'] as List?) ?? [];
      if (mounted) {
        setState(() {
          _categories = general;
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
      appBar: AppBar(title: const Text('⚔️ Multiplayer Challenge')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.neonPurple))
          : Column(
              children: [
                // Header Banner
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.neonPurple.withValues(alpha: 0.25), AppTheme.neonBlue.withValues(alpha: 0.15)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.neonPurple.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Text('⚡', style: TextStyle(fontSize: 36)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Real-time Battle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                            const SizedBox(height: 4),
                            Text(
                              'Challenge another player to a live quiz duel. Fastest correct answer wins!',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Difficulty selector
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Difficulty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 10),
                      Row(
                        children: _difficulties.map((diff) {
                          final selected = _difficulty == diff;
                          final color = diff == 'Easy' ? AppTheme.emeraldGreen
                              : diff == 'Medium' ? AppTheme.goldAccent
                              : AppTheme.livesRed;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () => setState(() => _difficulty = diff),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: selected ? color.withValues(alpha: 0.15) : AppTheme.cardBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: selected ? color : AppTheme.divider,
                                      width: selected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(diff,
                                      style: TextStyle(
                                        color: selected ? color : Colors.white38,
                                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Category label
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Select Topic', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
                const SizedBox(height: 10),

                // Categories grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.4,
                    ),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final selected = _selectedCategory == cat['id'];
                      final catColor = _getCategoryColor(index);
                      final catIcon = _getCategoryIcon(cat['name'] ?? '');

                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat['id']),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: selected ? catColor.withValues(alpha: 0.15) : AppTheme.cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected ? catColor : AppTheme.divider,
                              width: selected ? 2 : 1,
                            ),
                            boxShadow: selected
                                ? [BoxShadow(color: catColor.withValues(alpha: 0.2), blurRadius: 12, spreadRadius: 2)]
                                : [],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(catIcon, style: const TextStyle(fontSize: 28)),
                              const SizedBox(height: 8),
                              Text(
                                cat['name'] ?? '',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: selected ? catColor : Colors.white70,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (selected) ...[
                                const SizedBox(height: 4),
                                Icon(Icons.check_circle, color: catColor, size: 16),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Find Match button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: _selectedCategory == null ? null : _findMatch,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      backgroundColor: AppTheme.neonPurple,
                      disabledBackgroundColor: AppTheme.divider,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.flash_on_rounded, size: 20),
                        SizedBox(width: 8),
                        Text('Find Match', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _findMatch() {
    if (_selectedCategory == null) return;
    final catName = _categories.firstWhere((c) => c['id'] == _selectedCategory)['name'] ?? 'Battle';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MatchmakingScreen(
          categoryId: _selectedCategory!,
          categoryName: catName,
          difficulty: _difficulty,
        ),
      ),
    );
  }

  Color _getCategoryColor(int index) {
    final colors = [
      AppTheme.neonPurple, AppTheme.neonBlue, AppTheme.emeraldGreen,
      AppTheme.goldAccent, Colors.orange, Colors.cyan, Colors.pink, Colors.teal,
    ];
    return colors[index % colors.length];
  }

  String _getCategoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('math')) return '📐';
    if (lower.contains('verbal') || lower.contains('language')) return '📝';
    if (lower.contains('reason') || lower.contains('logic')) return '🧠';
    if (lower.contains('data') || lower.contains('interpret')) return '📊';
    if (lower.contains('general') || lower.contains('gk')) return '🌍';
    if (lower.contains('tech') || lower.contains('computer')) return '💻';
    if (lower.contains('science')) return '🔬';
    return '🎯';
  }
}
