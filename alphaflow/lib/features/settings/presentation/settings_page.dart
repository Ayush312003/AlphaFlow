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
                ref.read(selectedTrackNotifierProvider.notifier).resetSelectedTrack(); // Changed to use reset method
                ref.invalidate(xpProvider);
                ref.invalidate(totalTrackXpProvider);
                ref.invalidate(currentGuidedLevelProvider);
                ref.invalidate(guidedTaskStreaksProvider);

                ref.read(appModeNotifierProvider.notifier).resetAppMode(); // Changed to use reset method
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

  void _showClearAllUserDataConfirmationDialog(
    BuildContext context,
    WidgetRef ref,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Clear All User Data?'),
          content: const Text(
            'WARNING: This action is irreversible and will delete all your tasks, progress, and settings. Are you absolutely sure?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Clear Data'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () async {
                // Make async due to prefsService.clearAll()
                final prefsService = ref.read(preferencesServiceProvider);
                await prefsService.clearAll();

                ref.invalidate(localAppModeProvider);
                ref.invalidate(localSelectedTrackProvider);
                ref.invalidate(customTasksProvider);
                ref.invalidate(completionsProvider);
                ref.invalidate(xpProvider);
                ref.invalidate(totalTrackXpProvider);
                ref.invalidate(currentGuidedLevelProvider);
                ref.invalidate(displayedDateTasksProvider);
                ref.invalidate(customTaskStreaksProvider);
                ref.invalidate(guidedTaskStreaksProvider);

                Navigator.of(dialogContext).pop(); // Close dialog
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
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.restart_alt),
            title: const Text('Reset App Mode'),
            subtitle: const Text(
              'Return to the initial mode selection screen.',
            ),
            onTap: () {
              _showResetAppModeConfirmationDialog(
                context,
                ref,
              ); // 'ref' is available in ConsumerWidget
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: const Text('Clear All User Data'),
            subtitle: const Text('Reset all tasks, progress, and settings.'),
            onTap: () {
              _showClearAllUserDataConfirmationDialog(context, ref);
            },
          ),
          const Divider(),
          // Development testing section
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Development Tools',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
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
