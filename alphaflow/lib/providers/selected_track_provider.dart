import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphaflow/data/local/preferences_service.dart';
import 'package:alphaflow/providers/app_mode_provider.dart'; // For preferencesServiceProvider

class SelectedTrackNotifier extends StateNotifier<String?> {
  final PreferencesService _prefsService;

  SelectedTrackNotifier(this._prefsService) : super(null) {
    // Initialize state from SharedPreferences
    _loadSelectedTrack();
  }

  /// Loads selected track from SharedPreferences
  void _loadSelectedTrack() {
    final selectedTrack = _prefsService.getSelectedTrack();
    state = selectedTrack;
  }

  Future<void> setSelectedTrack(String trackId) async {
    // Update SharedPreferences
    await _prefsService.setSelectedTrack(trackId);
    // Update local state
    state = trackId;
  }

  Future<void> clearSelectedTrack() async {
    // Clear from SharedPreferences
    await _prefsService.clearSelectedTrack();
    // Update local state
    state = null;
  }

  /// Resets selected track to null (for settings page)
  Future<void> resetSelectedTrack() async {
    await clearSelectedTrack();
  }
}

final selectedTrackNotifierProvider = StateNotifierProvider<SelectedTrackNotifier, String?>((ref) {
  final prefsService = ref.watch(preferencesServiceProvider);
  return SelectedTrackNotifier(prefsService);
});

// Provider for getting selected track from SharedPreferences
final localSelectedTrackProvider = Provider<String?>((ref) {
  // Watch the notifier provider to get updates when selected track changes
  return ref.watch(selectedTrackNotifierProvider);
});

// The main provider for GETTING selectedTrack is now localSelectedTrackProvider.
// UI should switch to watching localSelectedTrackProvider instead of firestoreSelectedTrackProvider.
// selectedTrackNotifierProvider is for SETTING the track.
