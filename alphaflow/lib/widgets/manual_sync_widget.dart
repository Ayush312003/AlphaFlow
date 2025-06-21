import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphaflow/providers/task_completions_provider.dart';
import 'package:alphaflow/providers/batch_sync_provider.dart';
import 'package:alphaflow/data/models/app_mode.dart';
import 'package:alphaflow/providers/app_mode_provider.dart';

/// Widget that provides manual sync functionality with double slide down gesture
/// Only active in guided mode
class ManualSyncWidget extends ConsumerStatefulWidget {
  final Widget child;

  const ManualSyncWidget({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<ManualSyncWidget> createState() => _ManualSyncWidgetState();
}

class _ManualSyncWidgetState extends ConsumerState<ManualSyncWidget> {
  bool _isDragging = false;
  double _dragDistance = 0.0;
  bool _hasTriggeredSync = false;
  static const double _syncThreshold = 100.0; // Distance needed to trigger sync

  @override
  Widget build(BuildContext context) {
    final appMode = ref.watch(localAppModeProvider);
    
    // Only enable manual sync in guided mode
    if (appMode != AppMode.guided) {
      return widget.child;
    }

    return GestureDetector(
      onVerticalDragStart: (_) {
        setState(() {
          _isDragging = true;
          _dragDistance = 0.0;
          _hasTriggeredSync = false;
        });
      },
      onVerticalDragUpdate: (details) {
        if (!_isDragging) return;
        
        setState(() {
          _dragDistance += details.delta.dy;
        });

        // Trigger sync when dragged down past threshold
        if (_dragDistance > _syncThreshold && !_hasTriggeredSync) {
          _triggerManualSync();
          setState(() {
            _hasTriggeredSync = true;
          });
        }
      },
      onVerticalDragEnd: (_) {
        setState(() {
          _isDragging = false;
          _dragDistance = 0.0;
        });
      },
      child: Stack(
        children: [
          widget.child,
          // Show sync indicator when dragging
          if (_isDragging && _dragDistance > 0)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: _dragDistance.clamp(0.0, 100.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    ],
                  ),
                ),
                child: SizedBox(
                  height: _dragDistance.clamp(0.0, 100.0),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _hasTriggeredSync ? Icons.check_circle : Icons.sync,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _hasTriggeredSync ? 'Syncing...' : 'Pull down to sync',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _triggerManualSync() async {
    try {
      final completionsManager = ref.read(completionsManagerProvider);
      await completionsManager.syncPendingCompletions();
      
      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync completed successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Show error feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
} 