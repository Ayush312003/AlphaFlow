import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphaflow/features/user_profile/application/user_data_providers.dart'; // For new providers
import 'package:alphaflow/features/user_profile/application/user_data_service.dart'; // For UserDataService
import 'package:alphaflow/features/auth/application/auth_providers.dart'; // For currentUserIdProvider

class SelectedTrackNotifier extends StateNotifier<String?> {
  final Ref _ref; // Changed Reader to Ref
  final String? _userId;

  SelectedTrackNotifier(this._ref, this._userId) : super(null); // Changed _read to _ref

  Future<void> setSelectedTrack(String trackId) async {
    if (_userId == null || _userId!.isEmpty) return;
    // state = trackId;
    await _ref.read(userDataServiceProvider).updateSelectedTrack(_userId!, trackId); // Changed _read to _ref.read
  }

  Future<void> clearSelectedTrack() async {
    if (_userId == null || _userId!.isEmpty) return;
    // state = null;
    await _ref.read(userDataServiceProvider).updateSelectedTrack(_userId!, null); // Changed _read to _ref.read
  }
}

final selectedTrackNotifierProvider = StateNotifierProvider<SelectedTrackNotifier, String?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return SelectedTrackNotifier(ref, userId); // Changed ref.read to ref
});

// The main provider for GETTING selectedTrack is now firestoreSelectedTrackProvider.
// UI should switch to watching firestoreSelectedTrackProvider.
// selectedTrackNotifierProvider is for SETTING the track.
