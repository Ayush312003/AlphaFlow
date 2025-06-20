// lib/data/local/preferences_service.dart

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_mode.dart';
import '../models/custom_task.dart';
import '../models/task_completion.dart'; // Old model, used for migration reading

class PreferencesService {
  static const _keyAppMode        = 'app_mode';
  static const _keySelectedTrack  = 'selected_track';
  static const _keyCustomTasks    = 'custom_tasks';
  static const _keyCompletions    = 'task_completions';
  static const _keyFirstActiveDate = 'first_active_date';
  // Generic key for migration flag - can be reused if other migrations are needed.
  // Specific migration flags should use more descriptive keys like _keyMigratedToFirestoreV1
  static const _keyGenericBoolPrefix = 'generic_bool_';


  final SharedPreferences _prefs;

  PreferencesService._(this._prefs);

  static Future<PreferencesService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesService._(prefs);
  }

  // --- Boolean Getter/Setter ---
  Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(_keyGenericBoolPrefix + key, value);
  }

  bool getBool(String key, {bool defaultValue = false}) {
    return _prefs.getBool(_keyGenericBoolPrefix + key) ?? defaultValue;
  }

  // AppMode
  Future<void> setAppMode(AppMode mode) async {
    await _prefs.setString(_keyAppMode, mode.toShortString());
  }
  AppMode? getAppMode() {
    final s = _prefs.getString(_keyAppMode);
    return AppMode.fromString(s);
  }

  // Selected Guided Track
  Future<void> setSelectedTrack(String trackId) async {
    await _prefs.setString(_keySelectedTrack, trackId);
  }
  String? getSelectedTrack() {
    return _prefs.getString(_keySelectedTrack);
  }
  Future<void> clearSelectedTrack() async {
    await _prefs.remove(_keySelectedTrack);
  }

  // CustomTask List
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
    } catch (e) { return []; }
  }

  // TaskCompletion List (Old model from SharedPreferences)
  Future<void> saveCompletions(List<TaskCompletion> completions) async {
    final jsonList = completions.map((c) => c.toJson()).toList(); // Uses old TaskCompletion.toJson
    final jsonString = jsonEncode(jsonList);
    await _prefs.setString(_keyCompletions, jsonString);
  }
  List<TaskCompletion> loadCompletions() { // Returns list of old TaskCompletion model
    final jsonString = _prefs.getString(_keyCompletions);
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      final List decoded = jsonDecode(jsonString);
      return decoded
          .map((e) => TaskCompletion.fromJson(Map<String, dynamic>.from(e))) // Uses old TaskCompletion.fromJson
          .toList();
    } catch (e) { return []; }
  }

  // First Active Date (Old SharedPreferences version)
  Future<void> saveFirstActiveDate(DateTime date) async {
    final normalizedDate = DateTime.utc(date.year, date.month, date.day);
    await _prefs.setString(_keyFirstActiveDate, normalizedDate.toIso8601String().substring(0, 10));
  }
  DateTime? loadFirstActiveDate() {
    final dateString = _prefs.getString(_keyFirstActiveDate);
    if (dateString == null || dateString.isEmpty) return null;
    try {
      final parsedDate = DateTime.parse(dateString);
      return DateTime.utc(parsedDate.year, parsedDate.month, parsedDate.day);
    } catch (e) { return null; }
  }

  // Helpers / Reset
  Future<void> clearAppMode() async { await _prefs.remove(_keyAppMode); }
  Future<void> clearAll() async {
    await clearAppMode();
    await clearSelectedTrack();
    await _prefs.remove(_keyCustomTasks);
    await _prefs.remove(_keyCompletions);
    await _prefs.remove(_keyFirstActiveDate);
    // Also clear any migration flags if doing a full reset for testing
    // Example: await _prefs.remove(_keyGenericBoolPrefix + 'hasMigratedUserDataToFirestore_v1');
  }
}
