# Skill-wise XP Persistence & Analytics Plan for AlphaFlow

## Motivation
To enable skill-based analytics (e.g., radar/spider charts for Physical, Mental, Spiritual, Social, Creative skills), we need to track and persist XP earned for each skill, not just the overall total XP. This will allow users to visualize their growth in each area and unlock richer analytics features.

---

## Current State
- **Overall/session XP** is persisted in SharedPreferences via `PreferencesService` (`_keySessionXp`).
- **Daily XP** is tracked with a date-prefixed key.
- **XP is awarded** when guided tasks are completed, but not split by skill.
- **Guided tasks** will have a `tag` field indicating their skill (Physical, Mental, Spiritual, Social, Creative).

---

## Design Decisions
- **Persist skill XP** in SharedPreferences using a prefix key (e.g., `skill_xp_Physical`).
- **Update skill XP** whenever a guided task is completed, based on its tag.
- **Maintain overall XP** as before, for compatibility and progress tracking.
- **Expose skill XP** via Riverpod providers for use in analytics UI.

---

## Implementation Steps

### 1. Update PreferencesService
- [ ] Add a key prefix for skill XP: `static const _keySkillXpPrefix = 'skill_xp_';`
- [ ] Add methods:
  - `Future<void> saveSkillXp(String skill, int xp)`
  - `int loadSkillXp(String skill)`
  - (Optional) `Future<void> saveAllSkillXp(Map<String, int> skillXpMap)`
  - (Optional) `Map<String, int> loadAllSkillXp(List<String> skills)`

### 2. Update Guided Task Model
- [ ] Ensure each guided task has a `tag` field (already planned/added in JSON).
- [ ] Update the model if necessary to expose the tag.

### 3. Update XP Awarding Logic
- [ ] In the provider or service where XP is awarded for task completion:
  - Retrieve the skill tag from the completed task.
  - Load current XP for that skill from SharedPreferences.
  - Add the awarded XP to the skill's total and save it back.
  - Continue updating overall/session/daily XP as before.

### 4. Add Skill XP Providers
- [ ] Create a Riverpod provider (e.g., `skillXpProvider`) that exposes the XP for each skill.
- [ ] Optionally, create a provider that returns a map of all skill XPs for analytics.

### 5. Analytics UI Integration (Future)
- [ ] Use the skill XP providers as the data source for the radar/spider chart.
- [ ] Display the user's progress in each skill area.

---

## Example: Skill XP Persistence
```dart
// In PreferencesService
Future<void> saveSkillXp(String skill, int xp) async {
  await _prefs.setInt(_keySkillXpPrefix + skill, xp);
}
int loadSkillXp(String skill) {
  return _prefs.getInt(_keySkillXpPrefix + skill) ?? 0;
}
```

---

## Notes
- **Backward compatibility:** Existing users will have 0 XP for each skill until they complete a new task (or a migration script is run).
- **Multiple tags:** If a task can have multiple skill tags, decide whether to split XP or award full XP to each skill.
- **Reset/clear:** Consider adding methods to reset all skill XPs if needed.

---

## Checklist
- [ ] PreferencesService updated
- [ ] Guided task model exposes tag
- [ ] XP awarding logic updates skill XP
- [ ] Skill XP providers created
- [ ] Ready for analytics UI

---

*This document is a living plan. Update as implementation progresses.* 