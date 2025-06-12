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
  static const _keyFirstActiveDate = 'first_active_date'; // New key added

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
  // First Active Date
  // ──────────────────────────────────────────────────────────────────────────────

  Future<void> saveFirstActiveDate(DateTime date) async {
    // Normalize to UTC and store as YYYY-MM-DD string
    final normalizedDate = DateTime.utc(date.year, date.month, date.day);
    await _prefs.setString(_keyFirstActiveDate, normalizedDate.toIso8601String().substring(0, 10));
  }

  DateTime? loadFirstActiveDate() {
    final dateString = _prefs.getString(_keyFirstActiveDate);
    if (dateString == null || dateString.isEmpty) {
      return null;
    }
    try {
      // DateTime.parse will handle ISO8601 date strings (YYYY-MM-DD) correctly.
      // The resulting DateTime will be in local time if no timezone info,
      // but we reconstruct as UTC to be consistent with how it was saved.
      final parsedDate = DateTime.parse(dateString);
      return DateTime.utc(parsedDate.year, parsedDate.month, parsedDate.day);
    } catch (e) {
      print("Error parsing firstActiveDate: $e");
      // Consider removing the invalid key if parsing fails, or log more robustly.
      // await _prefs.remove(_keyFirstActiveDate);
      return null;
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
    await _prefs.remove(_keyCustomTasks);
    await _prefs.remove(_keyCompletions);
    await _prefs.remove(_keyFirstActiveDate); // Also clear firstActiveDate on full reset
  }
}
