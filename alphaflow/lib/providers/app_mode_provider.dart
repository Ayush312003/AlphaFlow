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
    state = mode;
    await _prefsService.setAppMode(mode);
  }

  Future<void> clearAppMode() async {
    state = null;
    await _prefsService.clearAppMode();
  }
}
