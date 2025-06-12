# AlphaFlow App: Current Status Report

**Date:** October 26, 2023

**Overview:** This document outlines the current development status of the AlphaFlow application. It details implemented features, core architectural components, pending work based on the initial design, and potential future enhancements. The goal is to provide a clear snapshot of the project's progress.

## I. Core Architecture & Setup

The application is built using Flutter and leverages several key architectural patterns and packages:

*   **Framework:** Flutter (latest stable version assumed).
*   **State Management:** `flutter_riverpod` is used for reactive state management throughout the application.
*   **Local Persistence:** `shared_preferences` is implemented via a `PreferencesService` class to store user settings, custom tasks, and completions locally.
*   **Data Models:** Clear Dart data models (`AppMode`, `Frequency`, `GuidedTrack`, `GuidedTask`, `CustomTask`, `TaskCompletion`, `LevelDefinition`) define the structure of the application's data.
*   **Utility Packages:** `uuid` for generating unique IDs for tasks.
*   **Static Data:** Pre-defined guided tracks and their associated tasks are stored as static data within the app.
*   **Code Generation:** `freezed_annotation`, `json_annotation`, `build_runner`, and `freezed` are included in `pubspec.yaml`, indicating readiness for generated data classes if needed (though current models are hand-coded).

## II. Implemented Features & UI Components

Significant progress has been made in implementing core features and UI components:

**A. Mode Selection & Initial Setup**
*   **`SelectModePage`**: Allows new users to choose between "Guided Mode" or "Custom Mode" on their first launch. This choice is persisted.
*   **`SelectTrackPage`**: For users choosing "Guided Mode", this page displays available guided tracks (e.g., "Monk Mode," "75 Hard") for selection. The chosen track is persisted.

**B. Custom Mode**
*   **`CustomHomePage`**:
    *   Displays a list of all user-created custom tasks using `Card` and `ListTile` widgets.
    *   Shows task `title`, `description`, `frequency`, selected `icon`, and `color` accents.
    *   Handles an engaging empty state when no tasks are present.
    *   **Task Completion**: Users can toggle task completion using checkboxes. Visual feedback (line-through, dimmed text, card styling changes) is provided for completed tasks. Completion status is persisted.
    *   **Task Deletion**: Tasks can be deleted with a confirmation dialog and `SnackBar` feedback.
    *   **Navigation for Add/Edit**: A Floating Action Button (FAB) navigates to `TaskEditorPage` for adding new tasks. Tapping a task's edit icon or long-pressing the task navigates to `TaskEditorPage` with task data pre-filled for editing.
    *   **Custom Icons & Colors Display**: Displays icons and color accents selected by the user for each task.
    *   **Task Streaks Display**: Shows calculated daily or weekly streaks (e.g., "🔥 5 days streak!") for each task.
*   **`TaskEditorPage` (for Custom Tasks)**:
    *   A full-page form for creating and editing custom tasks.
    *   Fields for `title` (mandatory), `description` (optional), and `frequency` (Daily, Weekly, One-Time) using `TextFormField`s and `DropdownButtonFormField`.
    *   UI for selecting a predefined `icon` and `color` for the task, with visual feedback for selection.
    *   Pre-populates form fields when editing an existing task.
    *   Handles form validation and submission (save/update) interacting with `customTasksProvider`.
    *   Provides `SnackBar` feedback on save/update and navigates back.
*   **`CustomTask` Model Enhancements**: Updated to include optional `iconName` and `colorValue` fields, with `toJson/fromJson` and `copyWith` support.

**C. Guided Mode (Initial Implementation)**
*   **`GuidedHomePage`**:
    *   Displays tasks for the currently selected guided track (hardcoded to Level 1 for now).
    *   Shows task `title`, `description`, and `XP` value.
    *   **Task Completion**: Users can toggle task completion using checkboxes. Visual feedback is provided. Completion status is persisted. (Note: XP accumulation is not yet implemented).

**D. Navigation**
*   **`HomePage`**: Acts as the main application scaffold after initial setup.
    *   Features a dynamic `AppBar` whose title changes based on the current mode or selected guided track.
    *   Hosts the `NavigationDrawerWidget`.
    *   Conditionally displays either `GuidedHomePage` or `CustomHomePage` as its body.
*   **`NavigationDrawerWidget`**:
    *   Provides global navigation accessible via a hamburger menu.
    *   Allows switching to "Custom Mode."
    *   Allows navigating to "Select Guided Track" page (clears current track to force re-selection).
    *   Lists all available guided tracks for direct selection and switching.
    *   Highlights the currently active mode and/or guided track.
    *   Includes a link to a placeholder "Settings" page.

**E. Data Persistence & State Management (Key Implemented Providers)**
*   **`preferencesServiceProvider`**: Provides the `PreferencesService` instance.
*   **`appModeProvider`**: Manages the current `AppMode` (guided/custom).
*   **`selectedTrackProvider`**: Manages the ID of the currently selected guided track.
*   **`guidedTracksProvider`**: Provides the static list of all `GuidedTrack` objects and related data (via family providers like `guidedTrackByIdProvider`, `guidedLevelsProvider`, `unlockTasksProvider`). `unlockTasksProvider` was updated to return `List<GuidedTask>`.
*   **`customTasksProvider`**: Manages the lifecycle (CRUD operations) of `CustomTask` objects, including persistence of icons/colors.
*   **`completionsProvider`**: Manages `TaskCompletion` records for both guided and custom tasks, handling date normalization and providing query methods.
*   **`customTaskStreaksProvider`**: Calculates and provides current daily/weekly streaks for custom tasks based on their completion history.

## III. Pending Features (Based on Original Design)

While significant progress has been made, the following features from the initial design document are yet to be fully implemented:

**A. Guided Mode Enhancements**
*   **XP System**:
    *   `xpProvider`: Needs to be created to calculate and manage total XP earned, likely for the current day or session.
    *   XP Bar: The UI element for displaying current XP in `GuidedHomePage` is not yet implemented.
    *   XP Accumulation Logic: Connecting task completion of `GuidedTask`s (with `xp > 0`) to `xpProvider`.
*   **Dynamic Level Progression**: Guided mode currently defaults to displaying Level 1 tasks. Logic for unlocking/progressing through `LevelDefinition`s based on XP or other criteria is pending.
*   **`streaksProvider` (for Guided Tasks)**: The original design mentioned a `streaksProvider`. While a `customTaskStreaksProvider` exists, a specific one for guided task streaks (which might have different rules or interact with XP/levels) is not yet implemented.
*   **`TaskCard` for `GuidedHome`**: If the visual design for a task in guided mode (`TaskCard`) is significantly different from the current `ListTile` approach, this specific component needs implementation.

**B. Core State Providers**
*   **`todayTasksProvider`**: This central provider, designed to filter and provide tasks for the current day based on mode, frequency, and completion status, is a key pending item. Currently, task filtering/display logic is more distributed.

**C. UI Components & Pages**
*   **`SettingsPage` Functionality**: Currently a placeholder. Needs implementation for actions like:
    *   "Reset mode" (clear `appModeProvider`, navigate to `SelectModePage`).
    *   "Re-select track" (partially covered by drawer, but a dedicated option might be desired).
    *   "Clear all data" (call `PreferencesService.clearAll()`).
*   **`TaskEditorSheet` vs. `TaskEditorPage`**: The design specified a `TaskEditorSheet`. We've implemented `TaskEditorPage` as a full page. If a modal bottom sheet is strictly required for the task editor, this would be a UI modification.

**D. Specific Data Flow Logic**
*   The comprehensive "Loading Tasks for Today" logic intended for `todayTasksProvider`.
*   XP recomputation and XP bar updates upon guided task completion.

## IV. Potential Future Enhancements

Beyond the original scope, several features have been discussed or could be considered:

**A. Custom Task Enhancements (Previously Discussed)**
*   Sub-tasks/Checklists within a custom task.
*   Measurable goals/targets (e.g., "Read X pages," with progress tracking).
*   Task prioritization (High, Medium, Low).
*   Optional due dates/deadlines for custom tasks.
*   Dedicated notes/journaling section per custom task.
*   Task archiving/viewing history instead of permanent deletion.
*   Task templates for quick creation of recurring task sets.

**B. General App Enhancements**
*   User reminders/notifications for pending tasks.
*   Firestore backend integration for data synchronization and backup.
*   Expanded theme options or UI customization.
*   A calendar view to visualize task completions and schedules.
*   Gamification elements beyond XP and streaks (e.g., badges, leaderboards if social).

## V. Next Immediate Steps (Recommendation)

To further develop the AlphaFlow app towards its initial vision, the following areas are recommended as next steps:

1.  **Implement `todayTasksProvider`**: This will centralize task loading logic for both modes and is a core part of the originally designed data flow.
2.  **Complete Guided Mode Core Features**:
    *   Implement the `xpProvider` and the XP bar UI in `GuidedHomePage`.
    *   Implement logic for dynamic level progression in guided tracks.
    *   Implement the `streaksProvider` for guided tasks if its logic differs from custom task streaks.
3.  **Implement `SettingsPage` Functionality**: Add the "Clear All Data" and other relevant settings options.

Focusing on these areas will bring the app closer to the functional state described in the initial design document, especially for the Guided Mode experience.
