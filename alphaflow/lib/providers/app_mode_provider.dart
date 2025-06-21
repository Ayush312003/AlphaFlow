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

// AppModeNotifier now uses SharedPreferences instead of Firestore
class AppModeNotifier extends StateNotifier<AppMode?> {
  final PreferencesService _prefsService;

  AppModeNotifier(this._prefsService) : super(null) {
    // Initialize state from SharedPreferences
    _loadAppMode();
  }

  /// Loads app mode from SharedPreferences
  void _loadAppMode() {
    final appMode = _prefsService.getAppMode();
    state = appMode;
  }

  Future<void> setAppMode(AppMode mode) async {
    // Update SharedPreferences
    await _prefsService.setAppMode(mode);
    // Update local state
    state = mode;
  }

  Future<void> clearAppMode() async {
    // Clear from SharedPreferences
    await _prefsService.clearAppMode();
    // Update local state
    state = null;
  }

  /// Resets app mode to null (for settings page)
  Future<void> resetAppMode() async {
    await clearAppMode();
  }
}

final appModeNotifierProvider = StateNotifierProvider<AppModeNotifier, AppMode?>((ref) {
  final prefsService = ref.watch(preferencesServiceProvider);
  return AppModeNotifier(prefsService);
});

// Provider for getting app mode from SharedPreferences
final localAppModeProvider = Provider<AppMode?>((ref) {
  // Watch the notifier provider to get updates when app mode changes
  return ref.watch(appModeNotifierProvider);
});

// The main provider for GETTING appMode is now localAppModeProvider.
// UI should switch to watching localAppModeProvider instead of firestoreAppModeProvider.
// appModeNotifierProvider is for SETTING the app mode.

// firstActiveDateProvider is now replaced by firestoreFirstActiveDateProvider from user_data_providers.dart
// So the old firstActiveDateProvider that read from SharedPreferences is no longer needed here.
