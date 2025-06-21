import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:alphaflow/data/models/guided_track.dart';
import 'package:alphaflow/data/models/guided_task.dart';
import 'package:alphaflow/data/models/level_definition.dart';
import 'package:alphaflow/data/models/frequency.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GuidedTracksService {
  static const String _assetPath = 'assets/guided_tracks.json';
  
  /// Loads guided tracks from the bundled JSON asset
  static Future<List<GuidedTrack>> loadGuidedTracks() async {
    try {
      final String jsonString = await rootBundle.loadString(_assetPath);
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      final List<dynamic> tracksJson = jsonData['tracks'] as List<dynamic>;
      
      return tracksJson.map((trackJson) => _parseGuidedTrack(trackJson)).toList();
    } catch (e) {
      print('Error loading guided tracks from JSON: $e');
      // Return empty list if loading fails
      return [];
    }
  }
  
  /// Parses a single guided track from JSON
  static GuidedTrack _parseGuidedTrack(Map<String, dynamic> trackJson) {
    final List<dynamic> levelsJson = trackJson['levels'] as List<dynamic>;
    final List<LevelDefinition> levels = levelsJson.map((levelJson) => _parseLevelDefinition(levelJson)).toList();
    
    return GuidedTrack(
      id: trackJson['id'] as String,
      title: trackJson['title'] as String,
      description: trackJson['description'] as String,
      icon: trackJson['icon'] as String,
      theme: trackJson['theme'] as String,
      levels: levels,
    );
  }
  
  /// Parses a level definition from JSON
  static LevelDefinition _parseLevelDefinition(Map<String, dynamic> levelJson) {
    final List<dynamic> tasksJson = levelJson['unlockTasks'] as List<dynamic>;
    final List<GuidedTask> tasks = tasksJson.map((taskJson) => _parseGuidedTask(taskJson)).toList();
    
    return LevelDefinition(
      levelNumber: levelJson['levelNumber'] as int,
      title: levelJson['title'] as String,
      icon: levelJson['icon'] as String,
      xpThreshold: levelJson['xpThreshold'] as int,
      unlockTasks: tasks,
    );
  }
  
  /// Parses a guided task from JSON
  static GuidedTask _parseGuidedTask(Map<String, dynamic> taskJson) {
    return GuidedTask(
      id: taskJson['id'] as String,
      title: taskJson['title'] as String,
      description: taskJson['description'] as String,
      frequency: _parseFrequency(taskJson['frequency'] as String),
      xp: taskJson['xp'] as int,
      requiredLevel: taskJson['requiredLevel'] as int,
    );
  }
  
  /// Parses frequency from string
  static Frequency _parseFrequency(String frequencyString) {
    switch (frequencyString) {
      case 'daily':
        return Frequency.daily;
      case 'weekly':
        return Frequency.weekly;
      case 'oneTime':
        return Frequency.oneTime;
      default:
        return Frequency.daily;
    }
  }
} 