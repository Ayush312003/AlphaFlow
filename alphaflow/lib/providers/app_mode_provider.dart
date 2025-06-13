import 'package:alphaflow/data/local/preferences_service.dart'; // Still needed for other things potentially
import 'package:alphaflow/data/models/app_mode.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphaflow/features/user_profile/application/user_data_providers.dart'; // For new providers
import 'package:alphaflow/features/user_profile/application/user_data_service.dart'; // For UserDataService
import 'package:alphaflow/features/auth/application/auth_providers.dart'; // For currentUserIdProvider

// Keep this if other parts of the app still use SharedPreferences directly via it.
// If not, it could be removed if all its usages are replaced.
final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  throw UnimplementedError("Prefs service should be overridden in main.dart");
});

// AppModeNotifier now primarily WRITES to UserDataService. The state is READ via firestoreAppModeProvider.
class AppModeNotifier extends StateNotifier<AppMode?> {
  final Reader _read;
  final String? _userId;

  AppModeNotifier(this._read, this._userId) : super(null) {
    // Initial state can be null, UI will use firestoreAppModeProvider which has loading/data states.
    // Or, could try an initial sync read here if truly needed, but usually not for Notifiers.
  }

  Future<void> setAppMode(AppMode mode) async {
    if (_userId == null || _userId!.isEmpty) return;
    // Optimistically update local state if desired, or rely on stream.
    // For simplicity here, we just call the service. The UI will react to stream updates.
    // state = mode;
    await _read(userDataServiceProvider).updateAppMode(_userId!, mode);
  }

  Future<void> clearAppMode() async {
    if (_userId == null || _userId!.isEmpty) return;
    // state = null;
    await _read(userDataServiceProvider).clearAppMode(_userId!);
  }
}

final appModeNotifierProvider = StateNotifierProvider<AppModeNotifier, AppMode?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return AppModeNotifier(ref.read, userId);
});

// The main provider for GETTING appMode is now firestoreAppModeProvider.
// This old appModeProvider (if UI directly watches it for state) might need to be removed or its usages updated.
// For now, let's assume UI will switch to firestoreAppModeProvider.
// We are keeping the appModeNotifierProvider for SETTING the app mode.

// firstActiveDateProvider is now replaced by firestoreFirstActiveDateProvider from user_data_providers.dart
// So the old firstActiveDateProvider that read from SharedPreferences is no longer needed here.
