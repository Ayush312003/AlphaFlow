// lib/data/local/preferences_service.dart

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_mode.dart';
import '../models/custom_task.dart';
import '../models/task_completion.dart';

class PreferencesService {
  static const _keyAppMode        = 'app_mode';
  static const _keySelectedTrack  = 'selected_track';
  static const _keyCustomTasks    = 'custom_tasks';
  static const _keyCompletions    = 'task_completions';

  final SharedPreferences _prefs;

  PreferencesService._(this._prefs);

  /// Initialize the service (call this once at app startup)
  static Future<PreferencesService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesService._(prefs);
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // AppMode
  // ──────────────────────────────────────────────────────────────────────────────

  Future<void> setAppMode(AppMode mode) async {
    await _prefs.setString(_keyAppMode, mode.toShortString());
  }

  AppMode? getAppMode() {
    final s = _prefs.getString(_keyAppMode);
    return AppMode.fromString(s);
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // Selected Guided Track
  // ──────────────────────────────────────────────────────────────────────────────

  Future<void> setSelectedTrack(String trackId) async {
    await _prefs.setString(_keySelectedTrack, trackId);
  }

  String? getSelectedTrack() {
    return _prefs.getString(_keySelectedTrack);
  }

  Future<void> clearSelectedTrack() async {
    await _prefs.remove(_keySelectedTrack);
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // CustomTask List
  // ──────────────────────────────────────────────────────────────────────────────

  Future<void> saveCustomTasks(List<CustomTask> tasks) async {
    final jsonList = tasks.map((t) => t.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await _prefs.setString(_keyCustomTasks, jsonString);
  }

  List<CustomTask> loadCustomTasks() {
    final jsonString = _prefs.getString(_keyCustomTasks);
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      final List decoded = jsonDecode(jsonString);
      return decoded
          .map((e) => CustomTask.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      // If parsing fails, reset to empty list
      return [];
    }
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // TaskCompletion List
  // ──────────────────────────────────────────────────────────────────────────────

  Future<void> saveCompletions(List<TaskCompletion> completions) async {
    final jsonList = completions.map((c) => c.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await _prefs.setString(_keyCompletions, jsonString);
  }

  List<TaskCompletion> loadCompletions() {
    final jsonString = _prefs.getString(_keyCompletions);
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      final List decoded = jsonDecode(jsonString);
      return decoded
          .map((e) => TaskCompletion.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // Helpers / Reset
  // ──────────────────────────────────────────────────────────────────────────────

  Future<void> clearAppMode() async {
    await _prefs.remove(_keyAppMode);
  }

  /// Clears all stored preferences (for debugging or logout)
  Future<void> clearAll() async {
    await clearAppMode();
    await clearSelectedTrack();
    await _prefs.remove(_keyCustomTasks); // Assuming these will have their own clear methods later
    await _prefs.remove(_keyCompletions);  // Assuming these will have their own clear methods later
  }
}
