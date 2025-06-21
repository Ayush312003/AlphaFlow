import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphaflow/providers/batch_sync_provider.dart';

/// Widget that displays sync status and pending completions count
/// Useful for debugging and providing user feedback
class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider);
    final pendingCount = ref.watch(pendingCompletionsCountProvider);

    // Don't show anything if there are no pending completions and sync is idle
    if (pendingCount == 0 && syncStatus.isIdle) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getBackgroundColor(syncStatus),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getBorderColor(syncStatus),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _getIcon(syncStatus),
          const SizedBox(width: 4),
          Text(
            _getStatusText(syncStatus, pendingCount),
            style: TextStyle(
              fontSize: 12,
              color: _getTextColor(syncStatus),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor(SyncStatus status) {
    switch (status.state) {
      case SyncState.idle:
        return Colors.grey.shade100;
      case SyncState.syncing:
        return Colors.blue.shade50;
      case SyncState.success:
        return Colors.green.shade50;
      case SyncState.error:
        return Colors.red.shade50;
    }
  }

  Color _getBorderColor(SyncStatus status) {
    switch (status.state) {
      case SyncState.idle:
        return Colors.grey.shade300;
      case SyncState.syncing:
        return Colors.blue.shade200;
      case SyncState.success:
        return Colors.green.shade200;
      case SyncState.error:
        return Colors.red.shade200;
    }
  }

  Color _getTextColor(SyncStatus status) {
    switch (status.state) {
      case SyncState.idle:
        return Colors.grey.shade700;
      case SyncState.syncing:
        return Colors.blue.shade700;
      case SyncState.success:
        return Colors.green.shade700;
      case SyncState.error:
        return Colors.red.shade700;
    }
  }

  Widget _getIcon(SyncStatus status) {
    switch (status.state) {
      case SyncState.idle:
        return Icon(
          Icons.cloud_upload_outlined,
          size: 14,
          color: _getTextColor(status),
        );
      case SyncState.syncing:
        return SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(_getTextColor(status)),
          ),
        );
      case SyncState.success:
        return Icon(
          Icons.check_circle_outline,
          size: 14,
          color: _getTextColor(status),
        );
      case SyncState.error:
        return Icon(
          Icons.error_outline,
          size: 14,
          color: _getTextColor(status),
        );
    }
  }

  String _getStatusText(SyncStatus status, int pendingCount) {
    switch (status.state) {
      case SyncState.idle:
        return pendingCount > 0 ? '$pendingCount pending' : '';
      case SyncState.syncing:
        return 'Syncing...';
      case SyncState.success:
        return 'Synced';
      case SyncState.error:
        return status.errorMessage ?? 'Sync error';
    }
  }
} 