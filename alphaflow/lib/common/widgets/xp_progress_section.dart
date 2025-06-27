import 'package:flutter/material.dart';
import 'package:alphaflow/common/widgets/glassmorphic_components.dart';
import 'package:alphaflow/data/models/level_definition.dart';
import 'package:alphaflow/core/theme/alphaflow_theme.dart';

/// Premium XP progress section with glassmorphic styling
class XpProgressSection extends StatefulWidget {
  final LevelDefinition? currentLevel;
  final double currentXp;
  final double totalXp;
  final String xpLabel;
  final bool animateOnLoad;

  const XpProgressSection({
    super.key,
    required this.currentLevel,
    required this.currentXp,
    required this.totalXp,
    required this.xpLabel,
    this.animateOnLoad = false,
  });

  @override
  State<XpProgressSection> createState() => _XpProgressSectionState();
}

class _XpProgressSectionState extends State<XpProgressSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    final progressValue = widget.totalXp > 0 
        ? (widget.currentXp / widget.totalXp).clamp(0.0, 1.0)
        : 0.0;

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: progressValue,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    if (widget.animateOnLoad) {
      _animationController.forward();
    } else {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(XpProgressSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Animate progress changes
    if (oldWidget.currentXp != widget.currentXp || 
        oldWidget.totalXp != widget.totalXp) {
      final progressValue = widget.totalXp > 0 
          ? (widget.currentXp / widget.totalXp).clamp(0.0, 1.0)
          : 0.0;
      
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: progressValue,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ));
      
      _animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassmorphicComponents.glassmorphicCard(
      margin: EdgeInsets.zero,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Level title
            if (widget.currentLevel != null)
              Text(
                "Level ${widget.currentLevel!.levelNumber}: ${widget.currentLevel!.title}",
                style: const TextStyle(
                  color: AlphaFlowTheme.guidedTextPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Sora',
                ),
              )
            else
              const Text(
                "Current Level: N/A",
                style: TextStyle(
                  color: AlphaFlowTheme.guidedTextPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Sora',
                ),
              ),
            
            const SizedBox(height: 8),
            
            // XP label
            Text(
              "${widget.xpLabel} ${widget.currentXp.toInt()} / ${widget.totalXp.toInt()}",
              style: const TextStyle(
                color: AlphaFlowTheme.guidedTextSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Sora',
              ),
            ),
            
            const SizedBox(height: 10),
            
            // Animated progress bar
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Container(
                  width: double.infinity,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AlphaFlowTheme.guidedProgressBarTrack,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _progressAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AlphaFlowTheme.guidedProgressBarFill,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
} 