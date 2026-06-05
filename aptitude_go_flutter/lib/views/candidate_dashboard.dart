import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import '../core/hive_database.dart';
import 'reward_wheel.dart';
import 'test_interface.dart';
import 'multiplayer_topic_screen.dart';

class CandidateDashboard extends StatefulWidget {
  const CandidateDashboard({super.key});

  @override
  State<CandidateDashboard> createState() => _CandidateDashboardState();
}

class _CandidateDashboardState extends State<CandidateDashboard> {
  List<dynamic> _generalCategories = [];
  List<dynamic> _companyCategories = [];
  List<dynamic> _attempts = [];
  bool _isLoading = true;
  bool _spinEligible = false;
  bool _attemptsLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCachedDashboardData();
    _fetchDashboardData();
  }

  void _loadCachedDashboardData() {
    final cachedGeneral = HiveDatabase.instance.getCachedGeneralCategories();
    final cachedCompany = HiveDatabase.instance.getCachedCompanyCategories();
    
    if (cachedGeneral.isNotEmpty || cachedCompany.isNotEmpty) {
      setState(() {
        _generalCategories = cachedGeneral;
        _companyCategories = cachedCompany;
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchDashboardData() async {
    if (_generalCategories.isEmpty && _companyCategories.isEmpty) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    final api = Provider.of<ApiClient>(context, listen: false);
    try {
      // 1. Fetch practice categories
      final catResponse = await api.get('tests/practice/');
      
      // 2. Fetch spin wheel status
      final spinResponse = await api.get('gamification/reward-wheel/status/');
      
      // Update user status inside ApiClient (silent sync)
      await api.checkAuthStatus();

      // 3. Fetch attempt history for chart
      List<dynamic> attempts = [];
      setState(() => _attemptsLoading = true);
      try {
        final attemptsResponse = await api.get('tests/attempt-history/');
        attempts = attemptsResponse.data['attempts'] ?? [];
      } catch (_) {}

      if (mounted) {
        setState(() {
          _generalCategories = catResponse.data['general_categories'] ?? [];
          _companyCategories = catResponse.data['company_categories'] ?? [];
          _spinEligible = spinResponse.data['eligible'] ?? false;
          _attempts = attempts;
          _attemptsLoading = false;
          _isLoading = false;
          _error = null;
        });
      }

      // Save new data to Hive local database cache
      await HiveDatabase.instance.saveCategories(
        general: catResponse.data['general_categories'] ?? [],
        company: catResponse.data['company_categories'] ?? [],
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_generalCategories.isEmpty && _companyCategories.isEmpty) {
            _error = "Failed to load dashboard. Pull to retry.";
          } else {
            // Quieter notice when offline but using local cache
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Offline Mode: Loaded categories from local database.'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = Provider.of<ApiClient>(context);
    final user = api.currentUser!;

    // XP calculation for percentage bar (level logic: 100 XP per level in Django)
    final int xp = user['exp'] ?? 0;
    final int nextLevelXp = 100;
    final int currentLevelProgress = xp % nextLevelXp;
    final double xpPercentage = (currentLevelProgress / nextLevelXp).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.bolt, color: AppTheme.neonPurple),
            const SizedBox(width: 8),
            Text(
              "Aptitude GO",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
            ),
          ],
        ),
        actions: [
          // Coins indicator
          Row(
            children: [
              const Icon(Icons.monetization_on, color: AppTheme.goldAccent, size: 20),
              const SizedBox(width: 4),
              Text(
                "${user['coins'] ?? 0}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(width: 14),
          // Lives indicator
          Row(
            children: [
              const Icon(Icons.favorite, color: AppTheme.livesRed, size: 20),
              const SizedBox(width: 4),
              Text(
                "${user['lives'] ?? 0}/5",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchDashboardData,
        color: AppTheme.neonPurple,
        backgroundColor: AppTheme.surface,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.neonPurple))
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // User stats card
                    _buildUserStatsCard(user, xpPercentage, currentLevelProgress),
                    const SizedBox(height: 20),

                    // Spin wheel promotion alert
                    if (_spinEligible) ...[
                      _buildSpinAlertCard(),
                      const SizedBox(height: 20),
                    ],

                    // Multiplayer Entry Card
                    _buildMultiplayerEntryCard(),
                    const SizedBox(height: 24),

                    // Score History Chart
                    if (_attempts.length >= 2) ...[
                      _buildScoreChart(),
                      const SizedBox(height: 24),
                    ],

                    if (_error != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white54),
                        ),
                      )
                    ] else ...[
                      // General Categories
                      _buildCategorySection(
                        title: "Core Aptitude Topics",
                        subtitle: "Recommended based on your target interests",
                        categories: _generalCategories,
                      ),
                      const SizedBox(height: 24),

                      // Company Categories
                      if (_companyCategories.isNotEmpty) ...[
                        _buildCategorySection(
                          title: "Company Specific Papers",
                          subtitle: "Simulate exam questions from top recruiters",
                          categories: _companyCategories,
                          isCompany: true,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildUserStatsCard(Map<String, dynamic> user, double xpPercent, int currentXp) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppTheme.neonPurple.withValues(alpha: 0.1),
            backgroundImage: user['avatar_url'] != null ? NetworkImage(user['avatar_url']) : null,
            child: user['avatar_url'] == null
                ? const Icon(Icons.person, color: AppTheme.neonPurple, size: 30)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hi, ${user['first_name'] ?? user['username']}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  "Level ${user['level'] ?? 1}",
                  style: const TextStyle(color: AppTheme.neonPurple, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                LinearPercentIndicator(
                  lineHeight: 6.0,
                  percent: xpPercent,
                  padding: EdgeInsets.zero,
                  backgroundColor: AppTheme.divider,
                  progressColor: AppTheme.neonPurple,
                  barRadius: const Radius.circular(3),
                ),
                const SizedBox(height: 4),
                Text(
                  "$currentXp / 100 XP",
                  style: const TextStyle(fontSize: 11, color: Colors.white30),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSpinAlertCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.neonPurple.withValues(alpha: 0.15), AppTheme.neonBlue.withValues(alpha: 0.15)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.neonPurple.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.stars, color: AppTheme.goldAccent, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Monthly Spin Available!",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  "Spin the lucky wheel and win coins or lives.",
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RewardWheelScreen()),
              );
              if (result == true) {
                _fetchDashboardData();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neonPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text("Spin Now", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiplayerEntryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.people_outline, color: AppTheme.neonBlue, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      "Multiplayer Arena",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  "Challenge a live opponent, win 40 coins, and race for accuracy.",
                  style: TextStyle(fontSize: 13, color: Colors.white38),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MultiplayerTopicScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neonBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text("Play VS", style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildScoreChart() {
    final spots = _attempts.asMap().entries.map((e) {
      final pct = (e.value['percentage'] as num?)?.toDouble() ?? 0;
      return FlSpot(e.key.toDouble(), pct);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, color: AppTheme.neonPurple, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Score History',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 170,
            child: _attemptsLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.neonPurple))
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        getDrawingHorizontalLine: (_) =>
                            FlLine(color: AppTheme.divider, strokeWidth: 1),
                        getDrawingVerticalLine: (_) =>
                            FlLine(color: Colors.transparent),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()}%',
                                style: const TextStyle(
                                  color: Colors.white24,
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 20,
                            interval: _attempts.length > 10
                                ? (_attempts.length / 5).ceilToDouble()
                                : 1,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= _attempts.length) {
                                return const SizedBox.shrink();
                              }
                              final attempt = _attempts[idx];
                              final dateStr =
                                  attempt['completed_at'] as String? ?? '';
                              final label = dateStr.length >= 10
                                  ? dateStr.substring(5, 10)
                                  : '${idx + 1}';
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                    color: Colors.white24,
                                    fontSize: 9,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      minY: 0,
                      maxY: 100,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: AppTheme.neonPurple,
                          barWidth: 2.5,
                          preventCurveOverShooting: true,
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppTheme.neonPurple.withValues(alpha: 0.08),
                          ),
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              final idx = spot.spotIndex;
                              final attempt = idx < _attempts.length
                                  ? _attempts[idx]
                                  : null;
                              final catName =
                                  attempt?['category_name'] as String? ?? '';
                              return LineTooltipItem(
                                '${spot.y.toStringAsFixed(0)}%\n$catName',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection({
    required String title,
    required String subtitle,
    required List<dynamic> categories,
    bool isCompany = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white30)),
        const SizedBox(height: 12),
        
        // Grid View of Categories
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
          ),
          itemBuilder: (context, index) {
            final cat = categories[index];
            final Color themeColor = isCompany ? AppTheme.neonBlue : AppTheme.neonPurple;
            
            return Card(
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TestInterfaceScreen(categorySlug: cat['slug']),
                    ),
                  ).then((_) => _fetchDashboardData());
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        isCompany ? Icons.apartment_outlined : Icons.menu_book_outlined,
                        color: themeColor,
                        size: 26,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cat['name'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, height: 1.2),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${cat['q_count'] ?? 0} Questions",
                            style: const TextStyle(fontSize: 10, color: Colors.white30),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
