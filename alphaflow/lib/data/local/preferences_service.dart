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
  static const _keyPendingCompletions = 'pending_completions'; // New: for batch syncing
  static const _keySessionXp      = 'session_xp';
  static const _keyDailyXpPrefix  = 'daily_xp_';
  // Generic key for migration flag - can be reused if other migrations are needed.
  // Specific migration flags should use more descriptive keys like _keyMigratedToFirestoreV1
  static const _keyGenericBoolPrefix = 'generic_bool_';
  static const _keySkillXpPrefix = 'skill_xp_';


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

  Future<void> saveTaskCompletions(List<TaskCompletion> completions) async {
    final jsonList = completions.map((c) => c.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await _prefs.setString('task_completions_cache', jsonString);
  }

  List<TaskCompletion>? loadTaskCompletions() {
    final jsonString = _prefs.getString('task_completions_cache');
    if (jsonString == null || jsonString.isEmpty) return null;
    try {
      final List decoded = jsonDecode(jsonString);
      return decoded
          .map((e) => TaskCompletion.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      return null;
    }
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

  // --- Pending Completions Queue for Batch Syncing ---
  
  /// Adds a guided task completion to the pending sync queue
  /// This will be synced to Firestore in batches
  Future<void> addPendingCompletion(Map<String, dynamic> completion) async {
    final pendingCompletions = getPendingCompletions();
    
    // Create a unique key for this completion to avoid duplicates
    final completionKey = '${completion['taskId']}_${completion['trackId']}_${completion['date']}';
    
    // Check if this completion already exists in pending queue
    final existingIndex = pendingCompletions.indexWhere((comp) => 
      '${comp['taskId']}_${comp['trackId']}_${comp['date']}' == completionKey
    );
    
    if (existingIndex >= 0) {
      // Update existing completion
      pendingCompletions[existingIndex] = completion;
    } else {
      // Add new completion
      pendingCompletions.add(completion);
    }
    
    await _savePendingCompletions(pendingCompletions);
  }
  
  /// Gets all pending completions from the queue
  List<Map<String, dynamic>> getPendingCompletions() {
    final jsonString = _prefs.getString(_keyPendingCompletions);
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      final List decoded = jsonDecode(jsonString);
      return decoded
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) { 
      return []; 
    }
  }
  
  /// Removes specific completions from the pending queue after successful sync
  Future<void> removePendingCompletions(List<Map<String, dynamic>> completedCompletions) async {
    final pendingCompletions = getPendingCompletions();
    
    for (final completed in completedCompletions) {
      final completionKey = '${completed['taskId']}_${completed['trackId']}_${completed['date']}';
      pendingCompletions.removeWhere((pending) => 
        '${pending['taskId']}_${pending['trackId']}_${pending['date']}' == completionKey
      );
    }
    
    await _savePendingCompletions(pendingCompletions);
  }
  
  /// Clears all pending completions (use after successful batch sync)
  Future<void> clearPendingCompletions() async {
    await _prefs.remove(_keyPendingCompletions);
  }
  
  /// Private method to save pending completions
  Future<void> _savePendingCompletions(List<Map<String, dynamic>> completions) async {
    // Convert Timestamp objects to ISO strings for JSON serialization
    final serializableCompletions = completions.map((completion) {
      final Map<String, dynamic> serializable = Map<String, dynamic>.from(completion);
      
      // Convert Timestamp to ISO string if it exists
      if (serializable['date'] != null) {
        if (serializable['date'] is String) {
          // Already a string, keep as is
        } else {
          // Convert to ISO string
          serializable['date'] = serializable['date'].toDate().toIso8601String();
        }
      }
      
      return serializable;
    }).toList();
    
    final jsonString = jsonEncode(serializableCompletions);
    await _prefs.setString(_keyPendingCompletions, jsonString);
  }

  // Session XP (for current session)
  Future<void> saveSessionXp(int xp) async {
    await _prefs.setInt(_keySessionXp, xp);
  }
  
  int loadSessionXp() {
    return _prefs.getInt(_keySessionXp) ?? 0;
  }

  // Daily XP tracking
  Future<void> saveDailyXp(String dateKey, int xp) async {
    await _prefs.setInt(_keyDailyXpPrefix + dateKey, xp);
  }
  
  int loadDailyXp(String dateKey) {
    return _prefs.getInt(_keyDailyXpPrefix + dateKey) ?? 0;
  }

  // Clear daily XP for a specific date
  Future<void> clearDailyXp(String dateKey) async {
    await _prefs.remove(_keyDailyXpPrefix + dateKey);
  }

  // Clear all daily XP data
  Future<void> clearAllDailyXp() async {
    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_keyDailyXpPrefix)) {
        await _prefs.remove(key);
      }
    }
  }

  // --- Skill XP Persistence ---
  Future<void> saveSkillXp(String skill, int xp) async {
    await _prefs.setInt(_keySkillXpPrefix + skill, xp);
  }

  int loadSkillXp(String skill) {
    return _prefs.getInt(_keySkillXpPrefix + skill) ?? 0;
  }

  Future<void> saveAllSkillXp(Map<String, int> skillXpMap) async {
    for (final entry in skillXpMap.entries) {
      await _prefs.setInt(_keySkillXpPrefix + entry.key, entry.value);
    }
  }

  Map<String, int> loadAllSkillXp(List<String> skills) {
    final Map<String, int> result = {};
    for (final skill in skills) {
      result[skill] = _prefs.getInt(_keySkillXpPrefix + skill) ?? 0;
    }
    return result;
  }

  // Clear all skill XP data
  Future<void> clearAllSkillXp() async {
    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_keySkillXpPrefix)) {
        await _prefs.remove(key);
      }
    }
  }

  // Helpers / Reset
  Future<void> clearAppMode() async { await _prefs.remove(_keyAppMode); }
  Future<void> clearAll() async {
    await clearAppMode();
    await clearSelectedTrack();
    await _prefs.remove(_keyCustomTasks);
    await _prefs.remove(_keyCompletions);
    await _prefs.remove(_keyFirstActiveDate);
    await clearPendingCompletions(); // Clear pending completions too
    await clearAllSkillXp(); // Clear skill XP data too
    // Also clear any migration flags if doing a full reset for testing
    // Example: await _prefs.remove(_keyGenericBoolPrefix + 'hasMigratedUserDataToFirestore_v1');
  }
}
