import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphaflow/data/models/app_mode.dart';
import 'package:alphaflow/features/guided/presentation/guided_home_page.dart';
import 'package:alphaflow/features/custom/presentation/custom_home_page.dart';
import 'package:alphaflow/features/onboarding/presentation/select_mode_page.dart';
import 'package:alphaflow/widgets/navigation_drawer_widget.dart';
import 'package:alphaflow/features/guided/providers/guided_tracks_provider.dart';
import 'package:alphaflow/providers/app_mode_provider.dart';
import 'package:alphaflow/providers/selected_track_provider.dart';
import 'package:alphaflow/common/widgets/track_card.dart';
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
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text(
          "Choose Your Track",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Sora',
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tracks.length,
          itemBuilder: (context, index) {
            final track = tracks[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: PremiumTrackCard(
                trackId: track.id,
                title: track.title,
                subtitle: track.description,
                levelCount: track.levels.length,
                onTap: () {
                  ref.read(selectedTrackNotifierProvider.notifier).setSelectedTrack(track.id);
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFFA500),
        ),
      ),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                "Something went wrong",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Please try again later",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                "Error: $error",
                style: TextStyle(
                  color: Colors.red.withOpacity(0.7),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
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
