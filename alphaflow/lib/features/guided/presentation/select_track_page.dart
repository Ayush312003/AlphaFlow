import 'package:alphaflow/features/guided/providers/guided_tracks_provider.dart';
import 'package:alphaflow/providers/selected_track_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphaflow/common/widgets/track_card.dart';
import 'package:alphaflow/core/constants/spacing.dart';
import 'package:alphaflow/core/theme/alphaflow_theme.dart';
import 'package:alphaflow/common/widgets/glassmorphism_card.dart';

class SelectTrackPage extends ConsumerWidget {
  const SelectTrackPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(guidedTracksProvider);

    return Scaffold(
      backgroundColor: AlphaFlowTheme.background,
      appBar: AppBar(
        title: const Text(
          'Choose Track',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AlphaFlowTheme.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: tracksAsync.when(
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
                        'Select Your Journey',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: AlphaFlowTheme.screenTitleSize,
                          fontWeight: FontWeight.bold,
                          color: AlphaFlowTheme.textPrimary,
                          fontFamily: 'Sora',
                        ),
                      ),
                      SizedBox(height: AlphaFlowTheme.titleToSubtitle),
                      Text(
                        'Pick a track that resonates with your goals',
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
                          Navigator.of(context).pop();
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
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFFA500), // Orange
          ),
        ),
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
      ),
    );
  }
}
