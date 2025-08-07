# AlphaFlow Developer Guide

## 1. Project Overview

AlphaFlow is a Flutter-based mobile application designed to help users build discipline and achieve their goals through structured task management. The app offers two main modes:

*   **Guided Mode:** Users can choose from predefined "tracks" like "Monk Mode" or "75 Hard," which consist of levels and specific daily tasks. This mode is designed to provide a clear path for users to follow.
*   **Custom Mode:** Users have the flexibility to create and manage their own tasks, allowing for a more personalized experience.

The application incorporates gamification elements, such as an XP (experience points) system and leveling, to motivate users and track their progress. It also includes features for tracking task completion streaks and provides analytics to help users understand their performance over time.

### Key Features:

*   **User Authentication:** Secure sign-in and sign-up functionality using Firebase Authentication, including Google Sign-In.
*   **Guided Tracks:** Pre-built task programs with defined levels and goals.
*   **Custom Task Management:** Create, edit, and delete personal tasks.
*   **Task Scheduling and Reminders:** (Future implementation)
*   **Progress Tracking:** Calendar-based view of task completions and streaks.
*   **Gamification:** Earn XP for completing tasks and level up.
*   **Analytics:** Visual charts and statistics to monitor progress (premium feature).
*   **Cross-Platform:** Built with Flutter for a consistent experience on both iOS and Android.

## 2. Tech Stack

This project is built with Flutter and leverages several key libraries and services.

### Core Technologies

*   **Flutter:** The UI toolkit for building natively compiled applications for mobile, web, and desktop from a single codebase.
*   **Dart:** The programming language used for Flutter development.
*   **Firebase:** A platform that provides backend services for the application.
    *   **Firebase Authentication:** Used for user sign-up and sign-in.
    *   **Cloud Firestore:** A NoSQL database used to store user data, task progress, and other application data.

### State Management

*   **Flutter Riverpod:** A reactive state management library that helps with dependency injection and state management in a simple and predictable way.

### Key Libraries

*   **shared\_preferences:** For storing simple key-value data on the device (e.g., user settings).
*   **freezed & json\_serializable:** Code generation libraries for creating immutable data models and handling JSON serialization/deserialization.
*   **intl:** For internationalization and localization.
*   **table\_calendar:** A highly customizable calendar widget for displaying task completions.
*   **fl\_chart:** A library for creating beautiful charts and graphs for the analytics feature.
*   **google\_fonts:** For using custom fonts from the Google Fonts library.
*   **lottie:** For displaying Lottie animations.

## 3. Project Structure

The project follows a feature-driven directory structure, which helps in separating the code for different features and makes the codebase easier to maintain and scale.

```
alphaflow/
├── android/          # Android specific files
├── assets/           # Application assets (images, fonts, animations)
├── ios/              # iOS specific files
├── lib/              # Main application code
│   ├── common/         # Common widgets and utilities
│   ├── core/           # Core components like theme, constants, and routing
│   ├── data/           # Data layer (models, services, local storage)
│   │   ├── local/      # Local data sources (e.g., SharedPreferences)
│   │   ├── models/     # Data models (mostly using Freezed)
│   │   └── services/   # Services for interacting with APIs (e.g., Firebase)
│   ├── features/       # Feature-specific code
│   │   ├── auth/       # Authentication feature
│   │   ├── custom/     # Custom task management feature
│   │   ├── guided/     # Guided mode feature
│   │   ├── home/       # Home screen
│   │   └── ...         # Other features
│   ├── providers/      # Riverpod providers for state management
│   ├── widgets/        # Reusable widgets used across multiple features
│   ├── firebase_options.dart # Firebase configuration
│   └── main.dart       # Application entry point
├── test/             # Unit and widget tests
└── pubspec.yaml      # Project dependencies and configuration
```

### Key Directories:

*   `lib/`: This is where all the Dart code for the application resides.
*   `lib/features/`: Each feature of the application has its own directory, containing the UI, application logic, and domain layers for that feature.
*   `lib/data/`: This directory contains the data layer of the application, including data models, repositories, and data sources.
*   `lib/providers/`: This directory contains all the Riverpod providers, which are used for state management.
*   `lib/core/`: This directory contains the core components of the application, such as the theme, constants, and routing.
*   `lib/widgets/`: This directory contains reusable widgets that are shared across multiple features.
*   `assets/`: This directory contains all the static assets used in the application, such as images, fonts, and Lottie animations.

## 4. Core Concepts

This section explains the fundamental concepts and patterns used in the AlphaFlow application.

### State Management with Riverpod

The application uses the `flutter_riverpod` package for state management. Riverpod helps in managing the state of the application in a predictable and scalable way.

*   **Providers:** Providers are the most important concept in Riverpod. They are used to store and expose the state of the application. The providers for this project are defined in the `lib/providers/` directory.
*   **ConsumerWidget:** To access the state from a provider, we use `ConsumerWidget` or `Consumer` to listen to the changes in the state and rebuild the UI accordingly.
*   **Ref:** The `ref` object is used to interact with providers, such as reading their state or calling their methods.

### Authentication Flow

User authentication is handled by Firebase Authentication. The authentication flow is as follows:

1.  **AuthGate:** The `AuthGate` widget in `main.dart` is the entry point for the authentication flow. It listens to the authentication state changes from Firebase.
2.  **Sign-In:** If the user is not authenticated, the `SignInScreen` is displayed, allowing the user to sign in with their Google account.
3.  **Home Screen:** Once the user is authenticated, they are redirected to the `HomePage`.

### Data Model

The application's data is stored in Cloud Firestore. The data model is designed to be scalable and efficient.

*   **Collections:** The main collection is `users`, where each document represents a user and is identified by the user's UID from Firebase Authentication.
*   **Subcollections:** The `taskCompletions` subcollection under each user document stores the records of completed tasks.
*   **Data Models:** The data models are defined in the `lib/data/models/` directory using the `freezed` package to create immutable data classes.

### Task Management

The application supports two types of tasks:

*   **Guided Tasks:** These are predefined tasks that are part of a specific track. The definitions for these tasks are stored locally in the app bundle.
*   **Custom Tasks:** Users can create their own tasks, which are stored in Firestore under the user's document.

### XP and Gamification

The application includes a gamification system to motivate users.

*   **XP Points:** Users earn XP (Experience Points) for completing tasks.
*   **Levels:** The total XP accumulated by the user determines their level in a specific track.
*   **Streaks:** The application tracks the user's daily task completion streaks.

## 5. Features

This section provides a detailed breakdown of the main features of the application.

### Authentication (`lib/features/auth`)

*   **Functionality:** Handles user sign-in and sign-up using Firebase Authentication and Google Sign-In.
*   **Key Widgets:**
    *   `SignInScreen`: The UI for the sign-in page.
    *   `AuthGate`: The widget that handles the authentication flow.
*   **Providers:**
    *   `authRepositoryProvider`: Provides an instance of the `AuthRepository`.
    *   `authStateChangesProvider`: A stream provider that listens to the authentication state changes from Firebase.

### Guided Mode (`lib/features/guided`)

*   **Functionality:** Allows users to select a predefined track and complete the tasks associated with it.
*   **Key Widgets:**
    *   `SelectTrackPage`: The page where users can select a guided track.
    *   `GuidedTaskList`: A widget that displays the list of tasks for the selected track.
*   **Providers:**
    *   `guidedTrackRepositoryProvider`: Provides an instance of the `GuidedTrackRepository`.
    *   `selectedTrackProvider`: A state provider that holds the currently selected track.

### Custom Task Management (`lib/features/custom`)

*   **Functionality:** Enables users to create, edit, and delete their own tasks.
*   **Key Widgets:**
    *   `CustomTaskList`: A widget that displays the list of custom tasks.
    *   `TaskEditorPage`: The page for creating and editing custom tasks.
*   **Providers:**
    *   `customTaskRepositoryProvider`: Provides an instance of the `CustomTaskRepository`.
    *   `customTasksProvider`: A stream provider that provides the list of custom tasks for the current user.

## 6. How to Contribute

This section provides guidelines for developers who want to contribute to the AlphaFlow project.

### Getting Started

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/your-repo/alphaflow.git
    cd alphaflow
    ```
2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Run the code generator:**
    ```bash
    flutter pub run build_runner build --delete-conflicting-outputs
    ```
4.  **Run the app:**
    ```bash
    flutter run
    ```

### Coding Conventions

*   **Style Guide:** Please follow the official [Dart style guide](https.dart.dev/guides/language/effective-dart/style).
*   **Linting:** The project uses `flutter_lints` for static analysis. Please make sure to address any linting errors before submitting a pull request.
*   **Immutability:** Use immutable data structures as much as possible, especially for data models (using the `freezed` package).

### Branching Strategy

*   **`main` branch:** This branch should always be stable and deployable.
*   **Feature branches:** Create a new branch for each new feature or bug fix. The branch name should be descriptive (e.g., `feature/add-new-feature`, `fix/fix-bug`).
*   **Pull Requests:** Once a feature is complete, create a pull request to merge the feature branch into `main`. The pull request should include a clear description of the changes.
