# Premium Analytics Implementation Plan

## Overview
Implement advanced analytics for premium users, including time-based insights, skill breakdowns, streaks, recommendations, and visualizations. All analytics are based on user task completion data in Firebase and task metadata in `guided_tracks.json`.

---

## 1. Data Requirements

### A. Firebase (Already Implemented)
- `users/{userId}/firstActiveDate` (timestamp)
- `users/{userId}/taskCompletions/{completionId}` (document per completion)
  - Fields: `date` (timestamp), `taskId` (string), `trackId` (string), `xpAwarded` (number)

### B. Local Asset
- `assets/guided_tracks.json`
  - Contains all tasks, their `tag` (skill category), and XP values.

---

## 2. Data Fetching & Preparation

### A. Fetch Task Completions
- Query all documents in `users/{userId}/taskCompletions`.
- For each document, extract: `date`, `taskId`, `trackId`, `xpAwarded`.

### B. Fetch Task Metadata
- Load `guided_tracks.json` at app startup or on analytics page load.
- Build a **lookup map**: `{taskId: {tag, title, ...}}` for fast access.

---

## 3. Data Aggregation & Analytics Logic

### A. Time-Based Aggregation
- **Group completions by day/week/month** using the `date` field.
- For each period, sum:
  - Total XP
  - Number of tasks completed
  - XP per skill (using `tag` from metadata)

### B. Skill Breakdown
- For all completions, group by `tag` and sum XP.
- Calculate percentage of total XP per skill.

### C. Streaks
- Sort completions by date.
- For each day, check if at least one task was completed.
- Count consecutive days with completions for current and longest streak.

### D. Best Days
- Find the day(s) with the highest total XP or most tasks completed.

### E. Most Improved Skill
- Compare XP per skill between two periods (e.g., this week vs. last week).
- Find the skill with the largest positive difference.

### F. Recommendations
- Identify skills (tags) with the least activity in the last week.
- Suggest tasks from those skills (using metadata).

---

## 4. Visualizations

### A. Calendar Heatmap
- For each day since `firstActiveDate`, show a colored cell based on total XP or tasks completed.
- Use a package like [`table_calendar`](https://pub.dev/packages/table_calendar) or a custom grid.

### B. Bar Graphs
- Show XP per week/month or per skill.
- Use a charting package like [`fl_chart`](https://pub.dev/packages/fl_chart).

### C. Trend Lines
- Line chart of XP per skill over time.

---

## 5. UI/UX Integration

- Add a new “Premium Analytics” page, only accessible to premium users.
- Display:
  - Calendar heatmap
  - Bar/line charts
  - Skill breakdown (pie/bar)
  - Streaks, best days, most improved skill
  - Personalized recommendations
- Show loading indicators while data is being fetched/processed.

---

## 6. Technical Steps

### A. Data Layer
- [ ] Create a service/class to fetch all task completions for the current user from Firebase.
- [ ] Create a service/class to load and parse `guided_tracks.json` and build a `{taskId: tag}` map.

### B. Analytics Logic
- [ ] Implement functions to:
  - [ ] Aggregate completions by day/week/month.
  - [ ] Aggregate XP by skill.
  - [ ] Calculate streaks and best days.
  - [ ] Compare skill XP between periods.
  - [ ] Generate recommendations.

### C. Visualization
- [ ] Integrate charting/heatmap packages.
- [ ] Build widgets for each visualization (calendar, bar, line, pie).

### D. UI
- [ ] Build the Premium Analytics page.
- [ ] Add logic to show/hide this page based on user’s premium status.

### E. Testing
- [ ] Test with users who have a lot of data and users with little data.
- [ ] Handle edge cases (no completions, missing tags, etc.).

---

## 7. Example: Aggregating XP Per Week

```dart
// Pseudocode
Map<String, int> getXpPerWeek(List<TaskCompletion> completions) {
  final Map<String, int> xpPerWeek = {};
  for (final completion in completions) {
    final week = getWeekString(completion.date); // e.g., '2025-W29'
    xpPerWeek[week] = (xpPerWeek[week] ?? 0) + completion.xpAwarded;
  }
  return xpPerWeek;
}
```

---

## 8. Example: Mapping Task to Skill

```dart
// Pseudocode
final taskMeta = {...}; // {taskId: {tag, ...}}
String getSkillForTask(String taskId) => taskMeta[taskId]?.tag ?? 'Unknown';
```

---

## 9. Documentation & Handover

- Document all new classes, functions, and data structures.
- Write clear comments and provide example usage for each analytics function.
- Ensure all new code is covered by unit tests where possible.

---

## 10. Stretch Goals (Optional)
- Cache analytics results for faster loading.
- Allow users to filter analytics by track, skill, or date range.
- Add export/share functionality for analytics.

---

# Summary Table

| Step                | What to Build/Do                                      |
|---------------------|------------------------------------------------------|
| Data Fetching       | Firebase completions, load guided_tracks.json        |
| Data Aggregation    | Group by date, skill, calculate streaks, etc.        |
| Visualization       | Calendar, bar, line, pie charts                      |
| UI                  | Premium Analytics page, show/hide for premium users  |
| Testing             | Edge cases, performance                              |

---

**Hand this plan to your junior engineer. They should follow each step, ask for clarification if needed, and check off each item as they go.**
If you want, I can provide more detailed code templates for any part of this plan! 