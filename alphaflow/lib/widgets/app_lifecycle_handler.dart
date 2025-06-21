import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphaflow/providers/batch_sync_provider.dart';
import 'package:alphaflow/providers/task_completions_provider.dart';

/// Widget that handles app lifecycle events for batch syncing
/// This should be placed at the root of the app to catch all lifecycle events
class AppLifecycleHandler extends ConsumerStatefulWidget {
  final Widget child;

  const AppLifecycleHandler({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<AppLifecycleHandler> createState() => _AppLifecycleHandlerState();
}

class _AppLifecycleHandlerState extends ConsumerState<AppLifecycleHandler>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Sync on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncOnAppOpen();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground - NO SYNC to reduce Firestore usage
        break;
      case AppLifecycleState.paused:
        // App went to background - NO SYNC to reduce Firestore usage
        break;
      case AppLifecycleState.detached:
        // App is about to be terminated
        _syncOnAppClose();
        break;
      case AppLifecycleState.inactive:
        // App is inactive (e.g., receiving a phone call)
        // Don't sync here as the app might come back quickly
        break;
      case AppLifecycleState.hidden:
        // App is hidden (new in Flutter 3.13+)
        _syncOnAppClose();
        break;
    }
  }

  /// Syncs pending completions when app opens
  Future<void> _syncOnAppOpen() async {
    try {
      final completionsManager = ref.read(completionsManagerProvider);
      await completionsManager.syncOnStartup();
    } catch (e) {
      // Log error but don't crash the app
      debugPrint('Error syncing on app open: $e');
    }
  }

  /// Syncs pending completions when app closes
  Future<void> _syncOnAppClose() async {
    try {
      final batchSyncService = ref.read(batchSyncServiceProvider);
      await batchSyncService.syncPendingCompletions();
    } catch (e) {
      // Log error but don't crash the app
      debugPrint('Error syncing on app close: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
} 