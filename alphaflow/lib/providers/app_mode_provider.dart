import 'package:alphaflow/data/local/preferences_service.dart';
import 'package:alphaflow/data/models/app_mode.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  // This will be overridden in main.dart
  throw UnimplementedError();
});

final appModeProvider = StateNotifierProvider<AppModeNotifier, AppMode?>((ref) {
  final prefsService = ref.watch(preferencesServiceProvider);
  return AppModeNotifier(prefsService);
});

class AppModeNotifier extends StateNotifier<AppMode?> {
  final PreferencesService _prefsService;

  AppModeNotifier(this._prefsService) : super(_prefsService.getAppMode());

  Future<void> setAppMode(AppMode mode) async {
    // Check and set firstActiveDate if not already set
    // loadFirstActiveDate is synchronous
    final DateTime? currentFirstActiveDate = _prefsService.loadFirstActiveDate();
    if (currentFirstActiveDate == null) {
      // saveFirstActiveDate is asynchronous
      await _prefsService.saveFirstActiveDate(DateTime.now());
    }

    state = mode;
    await _prefsService.setAppMode(mode);
  }

  Future<void> clearAppMode() async {
    // Clearing app mode should not clear the firstActiveDate,
    // as that marks the user's actual first engagement with the app.
    state = null;
    await _prefsService.clearAppMode();
  }
}

// Provider to expose the first active date of the user
final firstActiveDateProvider = Provider<DateTime?>((ref) {
  final prefsService = ref.watch(preferencesServiceProvider);
  return prefsService.loadFirstActiveDate();
});
