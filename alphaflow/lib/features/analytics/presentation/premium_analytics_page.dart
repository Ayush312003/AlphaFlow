import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphaflow/providers/premium_analytics_provider.dart';
import 'package:alphaflow/core/theme/alphaflow_theme.dart';
import 'package:fl_chart/fl_chart.dart';

class PremiumAnalyticsPage extends ConsumerWidget {
  const PremiumAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(premiumAnalyticsProvider);
    final isWide = MediaQuery.of(context).size.width > 600;

    // Prepare daily XP data for the line chart
    final List<MapEntry<String, int>> dailyXpEntries = analytics?.xpPerDay.entries.toList() ?? [];
    dailyXpEntries.sort((a, b) => a.key.compareTo(b.key));
    final List<FlSpot> dailyXpSpots = [
      for (int i = 0; i < dailyXpEntries.length; i++)
        FlSpot(i.toDouble(), dailyXpEntries[i].value.toDouble())
    ];
    final List<String> dateLabels = [
      for (final entry in dailyXpEntries) entry.key
    ];

    // Prepare weekly XP data for the trend/comparison chart
    final List<MapEntry<String, int>> weeklyXpEntriesRaw = analytics?.xpPerWeek.entries.toList() ?? [];
    weeklyXpEntriesRaw.sort((a, b) => a.key.compareTo(b.key));
    // Limit to latest 5 weeks
    final List<MapEntry<String, int>> weeklyXpEntries = weeklyXpEntriesRaw.length > 5
        ? weeklyXpEntriesRaw.sublist(weeklyXpEntriesRaw.length - 5)
        : weeklyXpEntriesRaw;
    final List<FlSpot> weeklyXpSpots = [
      for (int i = 0; i < weeklyXpEntries.length; i++)
        FlSpot(i.toDouble(), weeklyXpEntries[i].value.toDouble())
    ];
    // Previous week line (shifted by one, or just last two weeks)
    final int n = weeklyXpEntries.length;
    final List<FlSpot> prevWeekSpots = n > 1
        ? [
            for (int i = 0; i < n - 1; i++)
              FlSpot(i.toDouble() + 1, weeklyXpEntries[i].value.toDouble())
          ]
        : [];
    // Calculate % change for the last week
    final int thisWeekXp = n > 0 ? weeklyXpEntries[n - 1].value : 0;
    final int lastWeekXp = n > 1 ? weeklyXpEntries[n - 2].value : 0;
    final int percentChange = lastWeekXp > 0 ? (((thisWeekXp - lastWeekXp) / lastWeekXp) * 100).round() : 0;
    final bool improvement = thisWeekXp >= lastWeekXp;

    return Scaffold(
      backgroundColor: AlphaFlowTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AlphaFlowTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Advanced Analytics',
          style: TextStyle(
            color: AlphaFlowTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontFamily: 'Sora',
          ),
        ),
        centerTitle: true,
      ),
      body: analytics == null
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFFA500),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Refined Hero Card
                  _buildRefinedHeroCard(analytics),
                  const SizedBox(height: 18),
                  // Analytics Cards Grid (mobile: column, wide: grid)
                  isWide
                      ? Wrap(
                          spacing: 18,
                          runSpacing: 18,
                          children: [
                            SizedBox(width: 340, child: _buildAnalyticsCard(_buildWeeklyXpTrendChart(weeklyXpSpots, prevWeekSpots, weeklyXpEntries, percentChange, improvement))),
                            SizedBox(width: 340, child: _buildAnalyticsCard(_buildDailyXpLineChart(dailyXpSpots, dateLabels))),
                            SizedBox(width: 340, child: _buildAnalyticsCard(_buildRecommendationCards(analytics))),
                          ],
                        )
                      : Column(
                          children: [
                            _buildAnalyticsCard(_buildWeeklyXpTrendChart(weeklyXpSpots, prevWeekSpots, weeklyXpEntries, percentChange, improvement)),
                            const SizedBox(height: 14),
                            _buildAnalyticsCard(_buildDailyXpLineChart(dailyXpSpots, dateLabels)),
                            const SizedBox(height: 14),
                            _buildAnalyticsCard(_buildRecommendationCards(analytics)),
                          ],
                        ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildRefinedHeroCard(PremiumAnalytics analytics) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.10), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: _buildHeroStat('Total XP', analytics.totalXp.toString(), Icons.star)),
          Expanded(child: _buildHeroStat('Current Streak', analytics.currentStreak.toString(), Icons.local_fire_department)),
          Expanded(child: _buildHeroStat('Longest Streak', analytics.longestStreak.toString(), Icons.emoji_events)),
        ],
      ),
    );
  }

  Widget _buildHeroStat(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            fontFamily: 'Sora',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
            fontFamily: 'Sora',
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildDailyXpLineChart(List<FlSpot> spots, List<String> dateLabels) {
    if (spots.isEmpty) {
      return const Center(
        child: Text('No daily XP data available', style: TextStyle(color: Colors.white70)),
      );
    }
    final maxY = spots.map((e) => e.y).fold<double>(0, (prev, y) => y > prev ? y : prev);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.show_chart, color: Color(0xFFFFA500), size: 20),
            const SizedBox(width: 8),
            const Text(
              'Daily XP Trend',
              style: TextStyle(
                color: AlphaFlowTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Sora',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY < 10 ? 10 : maxY * 1.2,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.white.withOpacity(0.05),
                  strokeWidth: 0.7,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: const TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: (spots.length / 6).ceilToDouble(),
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= dateLabels.length) return const SizedBox.shrink();
                      final label = dateLabels[idx];
                      final parts = label.split('-');
                      return Text(
                        '${parts[1]}/${parts[2]}',
                        style: const TextStyle(color: Colors.white38, fontSize: 10),
                      );
                    },
                  ),
                ),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: const Color(0xFFFFA500),
                  barWidth: 2,
                  isStrokeCapRound: true,
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFFA500).withOpacity(0.06),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  dotData: FlDotData(
                    show: false,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyXpTrendChart(List<FlSpot> spots, List<FlSpot> prevWeekSpots, List<MapEntry<String, int>> weeklyXpEntries, int percentChange, bool improvement) {
    if (spots.isEmpty) {
      return const Center(
        child: Text('No weekly XP data available', style: TextStyle(color: Colors.white70)),
      );
    }
    // Prepare bar chart data
    final maxY = weeklyXpEntries.isNotEmpty ?
      weeklyXpEntries.map((e) => e.value).reduce((a, b) => a > b ? a : b) : 10;
    final barGroups = <BarChartGroupData>[];
    for (int i = 0; i < weeklyXpEntries.length; i++) {
      final current = weeklyXpEntries[i].value.toDouble();
      final prev = i > 0 ? weeklyXpEntries[i - 1].value.toDouble() : 0.0;
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: current,
              color: const Color(0xFFFFA500),
              width: 14,
              borderRadius: BorderRadius.circular(4),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxY * 1.2,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
            if (i > 0)
              BarChartRodData(
                toY: prev,
                color: Colors.white.withOpacity(0.3),
                width: 10,
                borderRadius: BorderRadius.circular(4),
              ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bar_chart, color: Color(0xFFFFA500), size: 20),
            const SizedBox(width: 8),
            const Text(
              'Weekly XP Trend',
              style: TextStyle(
                color: AlphaFlowTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Sora',
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: improvement ? Colors.green.withOpacity(0.13) : Colors.red.withOpacity(0.13),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    improvement ? Icons.arrow_upward : Icons.arrow_downward,
                    color: improvement ? Colors.green : Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${improvement ? '+' : ''}$percentChange%',
                    style: TextStyle(
                      color: improvement ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              maxY: maxY < 10 ? 10 : maxY * 1.2,
              barGroups: barGroups,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.white.withOpacity(0.07),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: const TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: (weeklyXpEntries.length / 6).ceilToDouble(),
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= weeklyXpEntries.length) return const SizedBox.shrink();
                      final label = weeklyXpEntries[idx].key;
                      return Text(
                        label,
                        style: const TextStyle(color: Colors.white54, fontSize: 10),
                      );
                    },
                  ),
                ),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyComparisonChart(PremiumAnalytics analytics) {
    // Calculate this week and last week XP
    final now = DateTime.now();
    final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
    
    final thisWeekXp = _calculateWeekXp(analytics.xpPerDay, thisWeekStart);
    final lastWeekXp = _calculateWeekXp(analytics.xpPerDay, lastWeekStart);
    
    final improvement = thisWeekXp > lastWeekXp;
    final percentageChange = lastWeekXp > 0 
        ? ((thisWeekXp - lastWeekXp) / lastWeekXp * 100).round()
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.compare_arrows,
              color: Color(0xFFFFA500),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Weekly Comparison',
              style: TextStyle(
                color: AlphaFlowTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Sora',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              // Comparison bars
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [Color(0xFFFFA500), Color(0xFFFF8C00)],
                                ),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFA500).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  '$thisWeekXp',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'This Week',
                            style: TextStyle(
                              color: AlphaFlowTheme.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Sora',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '$lastWeekXp',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Last Week',
                            style: TextStyle(
                              color: AlphaFlowTheme.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Sora',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Improvement indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: improvement ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: improvement ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      improvement ? Icons.trending_up : Icons.trending_down,
                      color: improvement ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      improvement 
                          ? '+$percentageChange% from last week'
                          : '$percentageChange% from last week',
                      style: TextStyle(
                        color: improvement ? Colors.green : Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Sora',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  int _calculateWeekXp(Map<String, int> xpPerDay, DateTime weekStart) {
    int totalXp = 0;
    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final dayString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      totalXp += xpPerDay[dayString] ?? 0;
    }
    return totalXp;
  }

  Widget _buildRecommendationCards(PremiumAnalytics analytics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.lightbulb,
              color: Color(0xFFFFA500),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Personalized Recommendations',
              style: TextStyle(
                color: AlphaFlowTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Sora',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...analytics.recommendations.map((recommendation) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFA500).withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFA500).withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA500).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lightbulb,
                  color: Color(0xFFFFA500),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  recommendation,
                  style: TextStyle(
                    color: AlphaFlowTheme.textPrimary,
                    fontSize: 14,
                    fontFamily: 'Sora',
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }
} 