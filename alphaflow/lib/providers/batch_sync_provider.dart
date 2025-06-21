import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/batch_sync_service.dart';
import '../data/local/preferences_service.dart';
import 'package:alphaflow/features/auth/application/auth_providers.dart'; // For currentUserIdProvider
import 'app_mode_provider.dart'; // For preferencesServiceProvider

/// Provider for BatchSyncService instance
final batchSyncServiceProvider = Provider<BatchSyncService>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final prefsService = ref.watch(preferencesServiceProvider);
  
  return BatchSyncService(
    FirebaseFirestore.instance,
    prefsService,
    userId,
  );
});

/// Provider that exposes the count of pending completions
final pendingCompletionsCountProvider = Provider<int>((ref) {
  final batchSyncService = ref.watch(batchSyncServiceProvider);
  return batchSyncService.getPendingCompletionsCount();
});

/// Provider for sync status - useful for UI indicators
final syncStatusProvider = StateNotifierProvider<SyncStatusNotifier, SyncStatus>((ref) {
  return SyncStatusNotifier();
});

/// Notifier for managing sync status
class SyncStatusNotifier extends StateNotifier<SyncStatus> {
  SyncStatusNotifier() : super(SyncStatus.idle());

  void setSyncing() {
    state = SyncStatus.syncing();
  }

  void setSuccess() {
    state = SyncStatus.success();
  }

  void setError(String error) {
    state = SyncStatus.error(error);
  }

  void reset() {
    state = SyncStatus.idle();
  }
}

/// Class representing different sync states
class SyncStatus {
  final SyncState state;
  final String? errorMessage;

  const SyncStatus._(this.state, [this.errorMessage]);

  factory SyncStatus.idle() => const SyncStatus._(SyncState.idle);
  factory SyncStatus.syncing() => const SyncStatus._(SyncState.syncing);
  factory SyncStatus.success() => const SyncStatus._(SyncState.success);
  factory SyncStatus.error(String message) => SyncStatus._(SyncState.error, message);

  bool get isIdle => state == SyncState.idle;
  bool get isSyncing => state == SyncState.syncing;
  bool get isSuccess => state == SyncState.success;
  bool get isError => state == SyncState.error;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SyncStatus &&
        other.state == state &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => state.hashCode ^ errorMessage.hashCode;

  @override
  String toString() {
    switch (state) {
      case SyncState.idle:
        return 'SyncStatus.idle';
      case SyncState.syncing:
        return 'SyncStatus.syncing';
      case SyncState.success:
        return 'SyncStatus.success';
      case SyncState.error:
        return 'SyncStatus.error: $errorMessage';
    }
  }
}

/// Enum for sync states
enum SyncState {
  idle,
  syncing,
  success,
  error,
} 