import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphaflow/core/theme/alphaflow_theme.dart';
import 'package:alphaflow/common/widgets/menu_item.dart';
import 'package:alphaflow/providers/app_mode_provider.dart';
import 'package:alphaflow/providers/selected_track_provider.dart';
import 'package:alphaflow/features/guided/providers/guided_tracks_provider.dart';
import 'package:alphaflow/data/models/app_mode.dart';
import 'package:alphaflow/features/analytics/presentation/premium_analytics_page.dart';
import 'package:alphaflow/providers/premium_analytics_provider.dart';

/// Premium AlphaFlow drawer with dark theme and glassmorphism design
class AlphaFlowDrawer extends ConsumerWidget {
  const AlphaFlowDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appMode = ref.watch(localAppModeProvider);
    final selectedTrackId = ref.watch(localSelectedTrackProvider);
    final tracksAsync = ref.watch(guidedTracksProvider);

    return Container(
      width: MediaQuery.of(context).size.width * 0.7,
      decoration: const BoxDecoration(
        color: AlphaFlowTheme.background,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MENU',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AlphaFlowTheme.textPrimary,
                    fontFamily: 'Sora',
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'ALPHAFLOW',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    color: Color(0xFF888888),
                    fontFamily: 'Sora',
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(
            color: Color(0xFF333333),
            height: 1,
          ),
          
          // Main Menu Items
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Custom Mode
                  MenuItem(
                    title: 'Custom Mode',
                    selected: appMode == AppMode.custom,
                    onTap: () {
                      ref.read(appModeNotifierProvider.notifier).setAppMode(AppMode.custom);
                      Navigator.of(context).pop();
                    },
                    icon: Icons.edit_outlined,
                  ),
                  
                  // Guided Tracks Section
                  const MenuSectionHeader(title: 'Guided Tracks'),
                  
                  // Guided tracks list
                  tracksAsync.when(
                    data: (tracks) {
                      return Column(
                        children: tracks.map((track) {
                          return MenuItem(
                            title: track.title,
                            selected: appMode == AppMode.guided && selectedTrackId == track.id,
                            onTap: () {
                              ref.read(appModeNotifierProvider.notifier).setAppMode(AppMode.guided);
                              ref.read(selectedTrackNotifierProvider.notifier).setSelectedTrack(track.id);
                              Navigator.of(context).pop();
                            },
                            icon: Icons.track_changes_outlined,
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (error, stack) => const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Error loading tracks',
                        style: TextStyle(
                          color: Color(0xFF888888),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  // Premium Analytics (Enhanced)
                  Consumer(
                    builder: (context, ref, _) {
                      final analytics = ref.watch(premiumAnalyticsProvider);
                      final previewMetric = analytics?.totalXp != null ? '${analytics!.totalXp} XP' : '';
                      return ListTile(
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const PremiumAnalyticsPage(),
                            ),
                          );
                        },
                        leading: const Icon(Icons.analytics_outlined, color: Color(0xFFFFA500)),
                        title: const Text(
                          'Advanced Analytics',
                          style: TextStyle(
                            color: AlphaFlowTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Sora',
                          ),
                        ),
                        subtitle: Text(
                          'Advanced insights & trends',
                          style: TextStyle(
                            color: AlphaFlowTheme.textSecondary.withOpacity(0.8),
                            fontSize: 12,
                            fontFamily: 'Sora',
                          ),
                        ),
                        trailing: previewMetric.isNotEmpty
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFA500).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  previewMetric,
                                  style: const TextStyle(
                                    color: Color(0xFFFFA500),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        tileColor: Colors.white.withOpacity(0.01),
                        hoverColor: Colors.white.withOpacity(0.04),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // Settings Section (Bottom Anchored)
          Container(
            padding: const EdgeInsets.only(bottom: 16),
            child: MenuItem(
              title: 'Settings',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/settings');
              },
              icon: Icons.settings_outlined,
            ),
          ),
        ],
      ),
    );
  }
} 