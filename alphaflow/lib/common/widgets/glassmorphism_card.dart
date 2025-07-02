import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:alphaflow/core/theme/alphaflow_theme.dart';

/// Premium glassmorphism card with background image and blur effects
class GlassmorphismCard extends StatelessWidget {
  final String backgroundImagePath;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final double height;
  final bool isSelected;

  const GlassmorphismCard({
    super.key,
    required this.backgroundImagePath,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.height = 180.0,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        margin: const EdgeInsets.only(bottom: AlphaFlowTheme.betweenCards),
        decoration: AlphaFlowTheme.glassmorphismCardDecoration.copyWith(
          border: isSelected 
            ? Border.all(color: AlphaFlowTheme.highlight, width: 2)
            : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AlphaFlowTheme.cardRadius),
          child: Stack(
            children: [
              // Background image with blur
              Positioned.fill(
                child: ImageFiltered(
                  imageFilter: AlphaFlowTheme.cardBlurFilter,
                  child: Image.asset(
                    backgroundImagePath,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              
              // Gradient overlay for better text readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AlphaFlowTheme.cardGradient,
                  ),
                ),
              ),
              
              // Content positioned at bottom-left
              Positioned(
                left: AlphaFlowTheme.insideCard,
                right: AlphaFlowTheme.insideCard,
                bottom: AlphaFlowTheme.insideCard,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: AlphaFlowTheme.cardTitleSize,
                        fontWeight: FontWeight.bold,
                        color: AlphaFlowTheme.textPrimary,
                        fontFamily: 'Sora',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    SizedBox(height: AlphaFlowTheme.titleToSubtitle),
                    
                    // Subtitle
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: AlphaFlowTheme.cardSubtitleSize,
                        fontWeight: FontWeight.w500,
                        color: AlphaFlowTheme.textSecondary,
                        fontFamily: 'Sora',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

/// Premium track selection card specifically for guided tracks
class PremiumTrackCard extends StatelessWidget {
  final String trackId;
  final String title;
  final String subtitle;
  final int levelCount;
  final VoidCallback? onTap;
  final bool isSelected;

  const PremiumTrackCard({
    super.key,
    required this.trackId,
    required this.title,
    required this.subtitle,
    required this.levelCount,
    this.onTap,
    this.isSelected = false,
  });

  String _getBackgroundImagePath() {
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
        return 'assets/monkMode.jpg';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassmorphismCard(
      backgroundImagePath: _getBackgroundImagePath(),
      title: title,
      subtitle: '$subtitle • $levelCount Levels',
      onTap: onTap,
      height: 180.0,
      isSelected: isSelected,
    );
  }
} 