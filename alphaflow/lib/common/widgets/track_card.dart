import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:alphaflow/core/constants/spacing.dart';
import 'package:alphaflow/common/widgets/layout_templates.dart';
import 'package:alphaflow/data/models/guided_track.dart';

/// Get background image path for a track
String _getTrackBackgroundImage(String trackId) {
  switch (trackId) {
    case 'monk_mode':
      return 'assets/monkMode.jpg';
    case '75_hard':
      return 'assets/75Hard.jpg';
    case 'morning_miracle':
      return 'assets/earlyRiser.jpg';
    case 'dopamine_detox':
      return 'assets/socialMedia.jpg';
    default:
      return 'assets/monkMode.jpg'; // fallback
  }
}

/// Modern, clean card widget for displaying guided tracks with background images
class TrackCard extends StatelessWidget {
  final GuidedTrack track;
  final VoidCallback? onTap;
  final bool isSelected;

  const TrackCard({
    super.key,
    required this.track,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.all(Spacing.sm),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Spacing.radiusLg),
          border: isSelected 
            ? Border.all(color: Colors.white, width: 2)
            : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Spacing.radiusLg),
          child: Stack(
            children: [
              // Background image with blur
              Positioned.fill(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                  child: Image.asset(
                    _getTrackBackgroundImage(track.id),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              
              // Dark overlay for better text visibility
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Content
              Padding(
                padding: EdgeInsets.all(Spacing.md),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Empty top section for spacing
                    const SizedBox(height: 8),
                    
                    // Bottom section with title and levels
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: Spacing.xs),
                        Row(
                          children: [
                            Text(
                              'Levels',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(width: Spacing.xs),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(Spacing.radiusSm),
                              ),
                              child: Text(
                                '${track.levels.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
}

/// Clean empty state widget
class TrackSelectionEmptyState extends StatelessWidget {
  final VoidCallback? onExploreTracks;
  final VoidCallback? onCreateCustom;

  const TrackSelectionEmptyState({
    super.key,
    this.onExploreTracks,
    this.onCreateCustom,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(Spacing.pageSpacing),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Clean icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.flag_outlined,
                size: 50,
                color: Theme.of(context).primaryColor,
              ),
            ),
            
            SizedBox(height: Spacing.xl),
            
            // Simple title
            Text(
              'Choose Your Path',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: Spacing.lg),
            
            // Clean action buttons
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: LayoutButton(
                    text: 'Explore Tracks',
                    onPressed: onExploreTracks,
                    isPrimary: true,
                  ),
                ),
                SizedBox(height: Spacing.md),
                SizedBox(
                  width: double.infinity,
                  child: LayoutButton(
                    text: 'Create Custom',
                    onPressed: onCreateCustom,
                    isPrimary: false,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 