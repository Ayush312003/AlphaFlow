import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphaflow/features/user_profile/application/user_data_providers.dart'; // For new providers
import 'package:alphaflow/features/user_profile/application/user_data_service.dart'; // For UserDataService
import 'package:alphaflow/features/auth/application/auth_providers.dart'; // For currentUserIdProvider

class SelectedTrackNotifier extends StateNotifier<String?> {
  final Reader _read;
  final String? _userId;

  SelectedTrackNotifier(this._read, this._userId) : super(null);

  Future<void> setSelectedTrack(String trackId) async {
    if (_userId == null || _userId!.isEmpty) return;
    // state = trackId;
    await _read(userDataServiceProvider).updateSelectedTrack(_userId!, trackId);
  }

  Future<void> clearSelectedTrack() async {
    if (_userId == null || _userId!.isEmpty) return;
    // state = null;
    await _read(userDataServiceProvider).updateSelectedTrack(_userId!, null);
  }
}

final selectedTrackNotifierProvider = StateNotifierProvider<SelectedTrackNotifier, String?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return SelectedTrackNotifier(ref.read, userId);
});

// The main provider for GETTING selectedTrack is now firestoreSelectedTrackProvider.
// UI should switch to watching firestoreSelectedTrackProvider.
// selectedTrackNotifierProvider is for SETTING the track.
