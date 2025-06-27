import 'package:flutter/material.dart';
import 'package:alphaflow/data/models/today_task.dart';
import 'package:alphaflow/data/models/streak_info.dart';
import 'package:alphaflow/common/widgets/glassmorphic_components.dart';
import 'package:alphaflow/core/theme/alphaflow_theme.dart';

/// Premium glassmorphic task card with animations
class PremiumTaskCard extends StatefulWidget {
  final TodayTask task;
  final TaskStreakInfo? streakInfo;
  final bool isEditable;
  final ValueChanged<bool> onToggleCompletion;
  final bool animateOnLoad;

  const PremiumTaskCard({
    super.key,
    required this.task,
    this.streakInfo,
    required this.isEditable,
    required this.onToggleCompletion,
    this.animateOnLoad = false,
  });

  @override
  State<PremiumTaskCard> createState() => _PremiumTaskCardState();
}

class _PremiumTaskCardState extends State<PremiumTaskCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    if (widget.animateOnLoad) {
      _animationController.forward();
    } else {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleToggle() {
    if (!widget.isEditable) return;

    // Animate checkbox
    _animationController.forward(from: 0.0);
    
    // Toggle completion
    widget.onToggleCompletion(!widget.task.isCompleted);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: GlassmorphicComponents.glassmorphicCard(
              child: Row(
                children: [
                  // Custom checkbox
                  GestureDetector(
                    onTap: widget.isEditable ? _handleToggle : null,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: widget.task.isCompleted ? AlphaFlowTheme.guidedCheckboxFill : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: widget.task.isCompleted ? AlphaFlowTheme.guidedCheckboxFill : AlphaFlowTheme.guidedCheckboxOutline,
                          width: 2,
                        ),
                      ),
                      child: widget.task.isCompleted
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            )
                          : null,
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Task content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Task title
                        Text(
                          widget.task.title,
                          style: TextStyle(
                            color: AlphaFlowTheme.guidedTextPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Sora',
                            decoration: widget.task.isCompleted 
                                ? TextDecoration.lineThrough 
                                : null,
                          ),
                        ),
                        
                        if (widget.task.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.task.description,
                            style: TextStyle(
                              color: widget.task.isCompleted
                                  ? AlphaFlowTheme.guidedTextSecondary.withOpacity(0.5)
                                  : AlphaFlowTheme.guidedTextSecondary,
                              fontSize: 14,
                              fontFamily: 'Sora',
                            ),
                          ),
                        ],
                        
                        // Streak indicator
                        if (widget.streakInfo != null && widget.streakInfo!.streakCount > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.local_fire_department,
                                size: 16,
                                color: AlphaFlowTheme.guidedAccentOrange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "${widget.streakInfo!.streakCount} day${widget.streakInfo!.streakCount == 1 ? '' : 's'}",
                                style: TextStyle(
                                  color: AlphaFlowTheme.guidedAccentOrange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Sora',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // XP value
                  Text(
                    "${widget.task.xp} XP",
                    style: TextStyle(
                      color: AlphaFlowTheme.guidedAccentOrange,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Sora',
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
} 