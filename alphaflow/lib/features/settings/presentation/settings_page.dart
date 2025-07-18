import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphaflow/features/user_profile/application/user_data_providers.dart';
import 'package:alphaflow/providers/app_mode_provider.dart';
import 'package:alphaflow/providers/selected_track_provider.dart';
import 'package:alphaflow/providers/custom_tasks_provider.dart';
import 'package:alphaflow/providers/task_completions_provider.dart';
import 'package:alphaflow/providers/xp_provider.dart';
import 'package:alphaflow/providers/guided_level_provider.dart';
import 'package:alphaflow/providers/today_tasks_provider.dart';
import 'package:alphaflow/providers/custom_task_streaks_provider.dart';
import 'package:alphaflow/providers/guided_task_streaks_provider.dart';
import 'package:alphaflow/widgets/batch_sync_test_widget.dart'; // For development testing
import 'package:alphaflow/core/theme/alphaflow_theme.dart'; // Import the correct theme
// preferencesServiceProvider is defined in app_mode_provider.dart (already imported)
// No direct import for 'package:alphaflow/data/local/preferences_service.dart' needed if using provider

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  void _showResetAppModeConfirmationDialog(
    BuildContext context,
    WidgetRef ref,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // Renamed to dialogContext for clarity
        return AlertDialog(
          title: const Text('Reset App Mode?'),
          content: const Text(
            'Are you sure you want to reset the app mode? You will be taken back to the initial mode selection.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Reset'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () async {
                // Make this async
                await ref
                    .read(completionsManagerProvider) // Changed
                    .clearGuidedTaskCompletions();
                await ref.read(selectedTrackNotifierProvider.notifier).resetSelectedTrack(); // Changed to use reset method
                await ref.read(appModeNotifierProvider.notifier).resetAppMode(); // Changed to use reset method
                
                // Clear skill XP data for analytics
                final prefsService = ref.read(preferencesServiceProvider);
                await prefsService.clearAllSkillXp();
                
                // Invalidate all related providers
                ref.invalidate(xpProvider);
                ref.invalidate(totalTrackXpProvider);
                ref.invalidate(currentGuidedLevelProvider);
                ref.invalidate(guidedTaskStreaksProvider);
                ref.invalidate(localAppModeProvider);
                ref.invalidate(localSelectedTrackProvider);

                Navigator.of(dialogContext).pop(); // Close dialog first
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/select_mode', (route) => false);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AlphaFlowTheme.background,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AlphaFlowTheme.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            leading: const Icon(
              Icons.restart_alt,
              color: AlphaFlowTheme.textPrimary,
            ),
            title: const Text(
              'Reset App Mode',
              style: TextStyle(
                color: AlphaFlowTheme.textPrimary,
                fontFamily: 'Sora',
              ),
            ),
            subtitle: const Text(
              'Return to the initial mode selection screen.',
              style: TextStyle(
                color: AlphaFlowTheme.textSecondary,
                fontFamily: 'Sora',
              ),
            ),
            onTap: () {
              _showResetAppModeConfirmationDialog(
                context,
                ref,
              );
            },
          ),
          const Divider(color: Color(0xFF333333)),
          // Development testing section
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Development Tools',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF888888),
                fontFamily: 'Sora',
              ),
            ),
          ),
          const BatchSyncTestWidget(), // Add the test widget
          // Future settings options will be added here
        ],
      ),
    );
  }
}
