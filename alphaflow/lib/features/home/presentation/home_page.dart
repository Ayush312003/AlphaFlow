import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphaflow/data/models/app_mode.dart';
import 'package:alphaflow/features/guided/presentation/guided_home_page.dart';
import 'package:alphaflow/features/custom/presentation/custom_home_page.dart';
import 'package:alphaflow/features/onboarding/presentation/select_mode_page.dart';
import 'package:alphaflow/features/guided/presentation/select_track_page.dart';
import 'package:alphaflow/widgets/navigation_drawer_widget.dart';
import 'package:alphaflow/features/guided/providers/guided_tracks_provider.dart';
import 'package:alphaflow/providers/app_mode_provider.dart';
import 'package:alphaflow/providers/selected_track_provider.dart';
import 'package:alphaflow/widgets/sync_status_indicator.dart';
import 'package:alphaflow/common/widgets/layout_templates.dart';
import 'package:alphaflow/common/widgets/track_card.dart';
import 'package:alphaflow/core/constants/spacing.dart';
import 'package:alphaflow/core/theme/alphaflow_theme.dart';
import 'package:alphaflow/common/widgets/glassmorphism_card.dart';
import 'package:alphaflow/features/guided/presentation/analytics_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appMode = ref.watch(localAppModeProvider);

    // If no app mode is set, show the select mode page
    if (appMode == null) {
      return const SelectModePage();
    }

    // If guided mode but no track selected, show the track selection grid
    if (appMode == AppMode.guided) {
      final selectedTrackId = ref.watch(localSelectedTrackProvider);
      if (selectedTrackId == null) {
        return _buildTrackSelectionPage(context, ref);
      }
    }

    // If we have a valid app mode and track (if guided), show the appropriate home page
    return _buildHomePage(context, ref, appMode);
  }

  Widget _buildTrackSelectionPage(BuildContext context, WidgetRef ref) {
    const Widget drawerWidget = NavigationDrawerWidget();

    return Scaffold(
      backgroundColor: AlphaFlowTheme.background,
      appBar: AppBar(
        title: const Text(
          "Choose Your Track",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AlphaFlowTheme.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      drawer: drawerWidget,
      body: _buildTrackSelectionBody(context, ref),
    );
  }

  Widget _buildTrackSelectionBody(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(guidedTracksProvider);

    return tracksAsync.when(
      data: (tracks) {
        if (tracks.isEmpty) {
          return const TrackSelectionEmptyState();
        }

        return CustomScrollView(
          slivers: [
            // Premium header
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AlphaFlowTheme.screenPadding, 
                  AlphaFlowTheme.screenPadding, 
                  AlphaFlowTheme.screenPadding, 
                  AlphaFlowTheme.screenPadding * 2
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose Your Path',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: AlphaFlowTheme.screenTitleSize,
                        fontWeight: FontWeight.bold,
                        color: AlphaFlowTheme.textPrimary,
                        fontFamily: 'Sora',
                      ),
                    ),
                    SizedBox(height: AlphaFlowTheme.titleToSubtitle),
                    Text(
                      'Discover tracks designed to help you grow',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AlphaFlowTheme.textSecondary,
                        fontFamily: 'Sora',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Premium track cards
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: AlphaFlowTheme.screenPadding),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final track = tracks[index];
                    return PremiumTrackCard(
                      trackId: track.id,
                      title: track.title,
                      subtitle: track.description,
                      levelCount: track.levels.length,
                      onTap: () {
                        ref.read(selectedTrackNotifierProvider.notifier).setSelectedTrack(track.id);
                      },
                    );
                  },
                  childCount: tracks.length,
                ),
              ),
            ),

            // Bottom spacing
            const SliverToBoxAdapter(
              child: SizedBox(height: 32),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Padding(
          padding: EdgeInsets.all(AlphaFlowTheme.screenPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.withOpacity(0.5),
              ),
              SizedBox(height: AlphaFlowTheme.betweenCards),
              Text(
                "Something went wrong",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AlphaFlowTheme.textPrimary,
                  fontFamily: 'Sora',
                ),
              ),
              SizedBox(height: AlphaFlowTheme.titleToSubtitle),
              Text(
                "Please try again later",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AlphaFlowTheme.textSecondary,
                  fontFamily: 'Sora',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomePage(BuildContext context, WidgetRef ref, AppMode appMode) {
    const Widget drawerWidget = NavigationDrawerWidget();

    String appBarTitle = "AlphaFlow";
    Widget currentPageBody;

    if (appMode == AppMode.guided) {
      final selectedTrackId = ref.watch(localSelectedTrackProvider);
      final trackAsync = ref.watch(guidedTrackByIdProvider(selectedTrackId!));
      
      return trackAsync.when(
        data: (track) {
          appBarTitle = track?.title ?? "Guided Mode";
          currentPageBody = const GuidedHomePage();
          
          return Scaffold(
            backgroundColor: AlphaFlowTheme.background,
            appBar: AppBar(
              title: Text(
                appBarTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AlphaFlowTheme.textPrimary,
                ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.analytics_outlined,
                    color: AlphaFlowTheme.textPrimary,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const AnalyticsPage()),
                    );
                  },
                ),
              ],
            ),
            drawer: drawerWidget,
            body: currentPageBody,
          );
        },
        loading: () => Scaffold(
          backgroundColor: AlphaFlowTheme.background,
          appBar: AppBar(
            title: const Text(
              "Guided Mode",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AlphaFlowTheme.textPrimary,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          drawer: drawerWidget,
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) => Scaffold(
          backgroundColor: AlphaFlowTheme.background,
          appBar: AppBar(
            title: const Text(
              "Guided Mode",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AlphaFlowTheme.textPrimary,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          drawer: drawerWidget,
          body: Center(child: Text("Error loading track: $error")),
        ),
      );
    } else if (appMode == AppMode.custom) {
      appBarTitle = "Custom Mode";
      currentPageBody = const CustomHomePage();
    } else {
      currentPageBody = const Center(child: Text("Unknown app mode", style: TextStyle(fontSize: 16)));
    }

    return Scaffold(
      backgroundColor: AlphaFlowTheme.background,
      appBar: AppBar(
        title: Text(
          appBarTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AlphaFlowTheme.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      drawer: drawerWidget,
      body: currentPageBody,
    );
  }
}
