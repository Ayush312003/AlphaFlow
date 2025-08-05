import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:alphaflow/core/theme/alphaflow_theme.dart';

class GenericGlassmorphismCard extends StatelessWidget {
  final Widget child;
  final double height;

  const GenericGlassmorphismCard({
    super.key,
    required this.child,
    this.height = 180.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.only(bottom: AlphaFlowTheme.betweenCards),
      decoration: AlphaFlowTheme.glassmorphismCardDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AlphaFlowTheme.cardRadius),
        child: BackdropFilter(
          filter: AlphaFlowTheme.cardBlurFilter,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
