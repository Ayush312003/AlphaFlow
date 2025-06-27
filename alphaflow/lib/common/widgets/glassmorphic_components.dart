import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:alphaflow/core/theme/alphaflow_theme.dart';

/// Premium glassmorphic components for AlphaFlow Guided Mode
class GlassmorphicComponents {
  /// Glassmorphic card container with backdrop filter
  static Widget glassmorphicCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double borderRadius = 20,
    bool withShine = true,
  }) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: AlphaFlowTheme.guidedCardBlurFilter,
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: withShine 
                ? AlphaFlowTheme.guidedGlassmorphismCardWithShine.copyWith(
                    borderRadius: BorderRadius.circular(borderRadius),
                  )
                : AlphaFlowTheme.guidedGlassmorphismCardDecoration.copyWith(
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
            child: child,
          ),
        ),
      ),
    );
  }

  /// Calendar-specific glassmorphic card with strong shine effect
  static Widget calendarGlassmorphicCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double borderRadius = 20,
  }) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: AlphaFlowTheme.guidedCardBlurFilter,
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: AlphaFlowTheme.calendarStrongShine.copyWith(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  /// Custom checkbox with orange accent
  static Widget customCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
    double size = 24,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: value ? AlphaFlowTheme.guidedCheckboxFill : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: value ? AlphaFlowTheme.guidedCheckboxFill : AlphaFlowTheme.guidedCheckboxOutline,
            width: 2,
          ),
        ),
        child: value
            ? const Icon(
                Icons.check,
                color: Colors.white,
                size: 16,
              )
            : null,
      ),
    );
  }

  /// Custom progress bar with orange accent
  static Widget customProgressBar({
    required double value,
    double height = 6,
    double borderRadius = 3,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AlphaFlowTheme.guidedProgressBarTrack,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: AlphaFlowTheme.guidedProgressBarFill,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    );
  }

  /// Calendar day item with frosted glass effect
  static Widget calendarDay({
    required String day,
    required bool isActive,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? AlphaFlowTheme.guidedCardBackground : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? Border.all(color: AlphaFlowTheme.guidedCardBorder, width: 1) : null,
        ),
        child: Center(
          child: Text(
            day,
            style: TextStyle(
              color: isActive ? AlphaFlowTheme.guidedTextPrimary : AlphaFlowTheme.guidedInactiveText,
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontFamily: 'Sora',
            ),
          ),
        ),
      ),
    );
  }

  /// Divider with custom color
  static Widget customDivider() {
    return Container(
      height: 1,
      color: AlphaFlowTheme.guidedDividerLine,
      margin: const EdgeInsets.symmetric(vertical: 16),
    );
  }
} 