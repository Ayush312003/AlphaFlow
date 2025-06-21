# AlphaFlow Progress Report: Guided Mode Storage Optimization

## Current State Analysis

### Existing Firestore Usage Issues
- **Multiple reads/writes on app startup**: App mode and selected track are stored in Firestore and read on every app launch
- **Inefficient data structure**: Track progress and task completions may be missing due to migration only running once
- **Cost implications**: Live updates for every user action create unnecessary Firestore operations

### Current Data Structure
```
/users/{userId}/
├── appMode: "guided" | "custom"
├── selectedTrack: "trackId"
├── firstActiveDate: timestamp
├── trackProgress: {trackId: levelNumber} (may be missing)
└── taskCompletions/ (subcollection)
    ├── {completionId}/
    │   ├── taskId: string
    │   ├── trackId: string
    │   ├── date: timestamp
    │   └── xpAwarded: number
```

## Proposed Storage Strategy

### 1. Hybrid Storage Approach

#### Local Storage (SharedPreferences)
- **Custom tasks**: Store completely locally
- **App mode**: Store locally instead of Firestore
- **Selected track**: Store locally instead of Firestore
- **Pending sync queue**: For guided task completions

#### Bundled Assets
- **Guided tracks/levels**: Bundle as JSON asset in app
- **Track definitions**: Include task descriptions, XP values, requirements

#### Firestore (Minimal Usage)
- **User completions for guided tasks only**: Store in `/users/{userId}/taskCompletions`
- **Batch syncing**: Sync pending completions on app open/close or connectivity changes

### 2. Data Migration Strategy

#### Phase 1: Local Storage Migration
- Migrate app mode and selected track from Firestore to SharedPreferences
- Update app startup to read from local storage first

#### Phase 2: Guided Tracks Bundling
- Convert guided tracks to JSON asset
- Create provider to load and manage track data
- Remove track definitions from Firestore

#### Phase 3: Completion Storage Optimization
- Implement batch syncing for guided task completions
- Add pending sync queue in SharedPreferences
- Sync on app lifecycle events

## Required Code Changes

### 1. SharedPreferences Service
```dart
class LocalStorageService {
  static const String _appModeKey = 'app_mode';
  static const String _selectedTrackKey = 'selected_track';
  static const String _pendingCompletionsKey = 'pending_completions';
  
  // App mode management
  Future<void> setAppMode(String mode);
  Future<String?> getAppMode();
  
  // Track selection management
  Future<void> setSelectedTrack(String trackId);
  Future<String?> getSelectedTrack();
  
  // Pending completions queue
  Future<void> addPendingCompletion(Map<String, dynamic> completion);
  Future<List<Map<String, dynamic>>> getPendingCompletions();
  Future<void> clearPendingCompletions();
}
```

### 2. Guided Tracks Asset Provider
```dart
class GuidedTracksProvider extends ChangeNotifier {
  List<Track> _tracks = [];
  
  Future<void> loadTracks();
  Track? getTrack(String trackId);
  List<Track> get allTracks;
  
  // Track progress calculation
  int getCurrentLevel(String trackId, List<TaskCompletion> completions);
  bool isTaskCompleted(String taskId, String trackId, List<TaskCompletion> completions);
}
```

### 3. Batch Sync Service
```dart
class BatchSyncService {
  Future<void> syncPendingCompletions();
  Future<void> syncOnAppOpen();
  Future<void> syncOnAppClose();
  
  // Connectivity-aware syncing
  Future<void> syncOnConnectivityChange(bool isConnected);
}
```

### 4. Updated User Service
```dart
class UserService {
  // Remove Firestore reads for app mode and track selection
  Future<String> getAppMode(); // Read from SharedPreferences
  Future<String?> getSelectedTrack(); // Read from SharedPreferences
  
  // Keep only guided completions in Firestore
  Future<void> saveGuidedCompletion(TaskCompletion completion);
  Future<List<TaskCompletion>> getGuidedCompletions(String trackId);
}
```

## Implementation Priority

### Phase 1: Immediate (Week 1)
1. **Create LocalStorageService** with SharedPreferences implementation
2. **Update app startup** to read app mode and track from local storage
3. **Migrate existing data** from Firestore to SharedPreferences
4. **Test app mode switching** functionality

### Phase 2: Core (Week 2)
1. **Create guided tracks JSON asset** with all track definitions
2. **Implement GuidedTracksProvider** to load and manage track data
3. **Update UI components** to use bundled track data
4. **Remove track definitions** from Firestore

### Phase 3: Optimization (Week 3)
1. **Implement BatchSyncService** for guided completions
2. **Add pending sync queue** in SharedPreferences
3. **Update completion logic** to use batch syncing
4. **Add connectivity monitoring** for sync triggers

### Phase 4: Cleanup (Week 4)
1. **Remove unused Firestore fields** (appMode, selectedTrack, trackProgress)
2. **Optimize Firestore queries** for completions only
3. **Add error handling** and retry logic for sync failures
4. **Performance testing** and monitoring

## Expected Benefits

### Cost Reduction
- **90% reduction in Firestore reads** on app startup
- **80% reduction in Firestore writes** for app configuration
- **Batch operations** reduce individual write costs

### Performance Improvements
- **Faster app startup** (no Firestore reads for configuration)
- **Offline functionality** for custom tasks
- **Reduced network usage** with batch syncing

### User Experience
- **Seamless mode switching** without network dependency
- **Consistent performance** regardless of network conditions
- **Data persistence** across app restarts

## Risk Mitigation

### Data Loss Prevention
- **Backup strategy**: Keep Firestore as backup for critical data
- **Migration validation**: Verify data integrity after migration
- **Rollback plan**: Ability to revert to previous storage method

### Sync Reliability
- **Retry logic**: Handle sync failures gracefully
- **Conflict resolution**: Handle concurrent modifications
- **Data validation**: Ensure completion data integrity

## Success Metrics

### Technical Metrics
- Firestore read operations: Target 90% reduction
- Firestore write operations: Target 80% reduction
- App startup time: Target 50% improvement
- Offline functionality: 100% for custom tasks

### User Metrics
- App crash rate: Maintain <1%
- Task completion success rate: Maintain 100%
- User satisfaction: No degradation in user experience

## Next Steps

1. **Review and approve** this implementation plan
2. **Begin Phase 1** with LocalStorageService implementation
3. **Set up monitoring** for Firestore usage metrics
4. **Create test cases** for migration scenarios
5. **Plan rollback strategy** in case of issues

---

*This document serves as the implementation guide for optimizing AlphaFlow's storage strategy while maintaining functionality and improving performance.* 

final guidedLevelsProvider = FutureProvider.family<List<LevelDefinition>, String>((ref, trackId) async {
  final track = await ref.watch(guidedTrackByIdProvider(trackId).future);
  // If track is null (not found), return an empty list of levels.
  return track?.levels ?? [];
}); 