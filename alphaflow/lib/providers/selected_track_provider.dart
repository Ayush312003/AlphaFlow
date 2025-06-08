import 'package:alphaflow/data/local/preferences_service.dart';
import 'package:alphaflow/providers/app_mode_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedTrackProvider =
    StateNotifierProvider<SelectedTrackNotifier, String?>((ref) {
  final prefsService = ref.watch(preferencesServiceProvider);
  return SelectedTrackNotifier(prefsService);
});

class SelectedTrackNotifier extends StateNotifier<String?> {
  final PreferencesService _prefsService;

  SelectedTrackNotifier(this._prefsService)
      : super(_prefsService.getSelectedTrack());

  Future<void> setSelectedTrack(String trackId) async {
    state = trackId;
    await _prefsService.setSelectedTrack(trackId);
  }

  Future<void> clearSelectedTrack() async {
    state = null;
    await _prefsService.clearSelectedTrack();
  }
}
