import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphaflow/core/theme/alphaflow_theme.dart';
import 'package:alphaflow/providers/xp_provider.dart';
import 'package:flutter_radar_chart/flutter_radar_chart.dart';
import 'package:alphaflow/features/analytics/presentation/premium_analytics_page.dart';

class AnalyticsPage extends ConsumerWidget {
  const AnalyticsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Define the skill tags that correspond to the guided tasks
    const skillTags = ['Physical', 'Mental', 'Spiritual', 'Lifestyle', 'Learning'];
    
    // Get skill XP data
    final skillXpMap = ref.watch(allSkillXpProvider(skillTags));
    final totalTrackXp = ref.watch(totalTrackXpProvider);
    
    // Convert skill XP to radar chart data (normalize to 0-100 scale)
    final maxXp = skillXpMap.values.isEmpty ? 1 : skillXpMap.values.reduce((a, b) => a > b ? a : b);
    final normalizedData = skillXpMap.values.map((xp) => maxXp > 0 ? (xp / maxXp * 100).round() : 0).toList();
    
    // Calculate total skill XP
    final totalSkillXp = skillXpMap.values.fold(0, (sum, xp) => sum + xp);

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 200) {
          // Left-to-right swipe detected
          Navigator.of(context).maybePop();
        }
      },
      child: Scaffold(
        backgroundColor: AlphaFlowTheme.guidedBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AlphaFlowTheme.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Skill Analytics',
            style: TextStyle(
              color: AlphaFlowTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontFamily: 'Sora',
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total XP Summary Card
              _buildSummaryCard(context, totalTrackXp, totalSkillXp),
              const SizedBox(height: 24),
              
              // Radar Chart Section
              _buildRadarChartSection(context, skillTags, normalizedData, skillXpMap),
              const SizedBox(height: 24),
              
              // Skill Breakdown Section
              _buildSkillBreakdownSection(context, skillTags, skillXpMap, maxXp),
              // Section Divider and Advanced Analytics Button
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Divider(thickness: 1, color: Colors.white.withOpacity(0.08)),
                    const SizedBox(height: 12),
                    Text(
                      'Want deeper insights?',
                      style: TextStyle(
                        color: AlphaFlowTheme.textSecondary,
                        fontSize: 14,
                        fontFamily: 'Sora',
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFA500),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Sora',
                            fontSize: 16,
                          ),
                        ),
                        icon: const Icon(Icons.analytics_outlined),
                        label: const Text('View Advanced Analytics'),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const PremiumAnalyticsPage(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, int totalTrackXp, int totalSkillXp) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AlphaFlowTheme.guidedAccentOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AlphaFlowTheme.guidedAccentOrange.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Total Progress',
            style: TextStyle(
              color: AlphaFlowTheme.guidedTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Sora',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Current Track\'s XP', totalTrackXp.toString()),
              _buildStatItem('Total Skill XP', totalSkillXp.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AlphaFlowTheme.guidedAccentOrange,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Sora',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AlphaFlowTheme.guidedTextSecondary,
            fontSize: 14,
            fontFamily: 'Sora',
          ),
        ),
      ],
    );
  }

  Widget _buildRadarChartSection(BuildContext context, List<String> skillTags, List<int> normalizedData, Map<String, int> skillXpMap) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Skill Distribution',
            style: TextStyle(
              color: AlphaFlowTheme.guidedTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Sora',
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              height: 300,
              child: RadarChart(
                features: skillTags,
                data: [normalizedData],
                ticks: const [20, 40, 60, 80, 100],
                outlineColor: AlphaFlowTheme.guidedAccentOrange,
                graphColors: const [AlphaFlowTheme.guidedAccentOrange],
                featuresTextStyle: const TextStyle(
                  color: AlphaFlowTheme.guidedTextPrimary,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Sora',
                  fontSize: 12,
                ),
                ticksTextStyle: const TextStyle(
                  color: AlphaFlowTheme.guidedTextSecondary,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillBreakdownSection(BuildContext context, List<String> skillTags, Map<String, int> skillXpMap, int maxXp) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Skill Breakdown',
            style: TextStyle(
              color: AlphaFlowTheme.guidedTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Sora',
            ),
          ),
          const SizedBox(height: 16),
          ...skillTags.map((skill) => _buildSkillItem(skill, skillXpMap[skill] ?? 0, maxXp)),
        ],
      ),
    );
  }

  Widget _buildSkillItem(String skill, int xp, int maxXp) {
    final percentage = maxXp > 0 ? (xp / maxXp * 100).round() : 0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              skill,
              style: const TextStyle(
                color: AlphaFlowTheme.guidedTextPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Sora',
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$xp XP',
                      style: const TextStyle(
                        color: AlphaFlowTheme.guidedAccentOrange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Sora',
                      ),
                    ),
                    Text(
                      '$percentage%',
                      style: const TextStyle(
                        color: AlphaFlowTheme.guidedTextSecondary,
                        fontSize: 12,
                        fontFamily: 'Sora',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: maxXp > 0 ? xp / maxXp : 0,
                  backgroundColor: AlphaFlowTheme.guidedTextSecondary.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(AlphaFlowTheme.guidedAccentOrange),
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 