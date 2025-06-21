import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphaflow/providers/batch_sync_provider.dart';
import 'package:alphaflow/providers/task_completions_provider.dart';
import 'package:alphaflow/features/auth/application/auth_providers.dart';

/// Test widget for batch sync functionality
/// This should only be used during development/testing
class BatchSyncTestWidget extends ConsumerWidget {
  const BatchSyncTestWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider);
    final pendingCount = ref.watch(pendingCompletionsCountProvider);
    final userId = ref.watch(currentUserIdProvider);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Batch Sync Test',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('User ID: ${userId ?? "Not logged in"}'),
            Text('Sync Status: ${syncStatus.toString()}'),
            Text('Pending Completions: $pendingCount'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _addTestCompletion(ref),
                    child: const Text('Add Test Completion'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _removeTestCompletion(ref),
                    child: const Text('Remove Test Completion'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _manualSync(ref),
                child: const Text('Manual Sync'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _clearPending(ref),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade100,
                  foregroundColor: Colors.red.shade700,
                ),
                child: const Text('Clear Pending'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addTestCompletion(WidgetRef ref) {
    final completionsManager = ref.read(completionsManagerProvider);
    final now = DateTime.now();
    
    // Add a test guided task completion
    completionsManager.toggleTaskCompletion(
      'test_task_${now.millisecondsSinceEpoch}',
      now,
      trackId: 'monk_mode', // Use a track that exists in your app
    );
  }

  void _removeTestCompletion(WidgetRef ref) {
    final completionsManager = ref.read(completionsManagerProvider);
    final now = DateTime.now();
    
    // Remove a test guided task completion
    completionsManager.toggleTaskCompletion(
      'test_task_${now.millisecondsSinceEpoch}',
      now,
      trackId: 'monk_mode', // Use a track that exists in your app
    );
  }

  void _manualSync(WidgetRef ref) {
    final completionsManager = ref.read(completionsManagerProvider);
    completionsManager.syncPendingCompletions();
  }

  void _clearPending(WidgetRef ref) {
    final batchSyncService = ref.read(batchSyncServiceProvider);
    batchSyncService.clearPendingCompletions();
  }
} 