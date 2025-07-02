import 'package:flutter/material.dart';
import 'package:alphaflow/core/theme/alphaflow_theme.dart';

class XpCapPopup extends StatelessWidget {
  final VoidCallback? onDismiss;
  
  const XpCapPopup({
    super.key,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AlphaFlowTheme.guidedBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AlphaFlowTheme.guidedAccentOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  Icons.emoji_events_rounded,
                  size: 30,
                  color: AlphaFlowTheme.guidedAccentOrange,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Title
              Text(
                'Daily XP Cap Reached!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AlphaFlowTheme.guidedTextPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              // Message
              Text(
                'You\'ve reached today\'s maximum XP limit of 200 XP. Come back tomorrow to continue earning!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AlphaFlowTheme.guidedTextSecondary.withValues(alpha: 0.8),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              // Dismiss button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onDismiss?.call();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AlphaFlowTheme.guidedAccentOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Got it!',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 