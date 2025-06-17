// import 'package:alphaflow/data/models/app_mode.dart';
// import 'package:alphaflow/data/models/custom_task.dart';
// import 'package:alphaflow/data/models/user_data.dart';
// import 'package:alphaflow/features/custom/presentation/task_editor_page.dart';
// import 'package:alphaflow/features/guided/presentation/select_track_page.dart';
// import 'package:alphaflow/features/home/presentation/home_page.dart';
// import 'package:alphaflow/features/onboarding/presentation/select_mode_page.dart';
// import 'package:alphaflow/features/settings/presentation/settings_page.dart';
// // Updated path for appModeNotifierProvider - it's still in app_mode_provider.dart
// import 'package:alphaflow/providers/app_mode_provider.dart';
// // Updated path for selectedTrackNotifierProvider - it's still in selected_track_provider.dart
// import 'package:alphaflow/providers/selected_track_provider.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:alphaflow/data/local/preferences_service.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';
// import 'package:alphaflow/widgets/loading_screen.dart';
// import 'package:alphaflow/features/user_profile/application/user_data_providers.dart';
// import 'package:alphaflow/features/auth/application/auth_providers.dart';
// import 'package:alphaflow/features/user_profile/application/user_data_service.dart';
// import 'package:alphaflow/features/guided/providers/guided_tracks_provider.dart'; // For migration
// import 'package:alphaflow/data/models/guided_track.dart'; // For migration List<GuidedTrack>
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//   final prefsService = await PreferencesService.init();
//
//   final container = ProviderContainer(
//     overrides: [
//       preferencesServiceProvider.overrideWithValue(prefsService),
//       // guidedTracksProvider may need to be overridden if it depends on something async
//       // For now, assume it's a simple Provider as before.
//     ],
//   );
//
//   try {
//     final user = await container.read(anonymousUserProvider.future);
//     if (user?.uid != null) {
//       final userId = user!.uid;
//       final userDataService = container.read(userDataServiceProvider);
//       await userDataService.ensureUserDataDocumentExists(userId);
//
//       // Perform migration
//       final allGuidedTracks = container.read(guidedTracksProvider); // Read for XP lookup
//       await userDataService.migrateUserDataIfNeeded(userId, prefsService, allGuidedTracks);
//     }
//   } catch (e) {
//     print("Error during initial user setup/migration: $e");
//     // Decide how to handle this - e.g., show an error page or try to proceed.
//   }
//
//   runApp(
//       UncontrolledProviderScope(
//         container: container,
//         child: const MyApp(),
//       )
//   );
// }
//
// class MyApp extends ConsumerWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final userDataAsync = ref.watch(userDataProvider);
//
//     return userDataAsync.when(
//       loading: () => MaterialApp(
//         initialRoute: '/',
//         routes: {'/': (context) => const LoadingScreen()},
//         debugShowCheckedModeBanner: false,
//       ),
//       error: (err, stack) {
//         print("Error loading user data in MyApp: $err");
//         print(stack);
//         return MaterialApp(home: Scaffold(body: Center(child: Text("Error loading data: $err"))));
//       },
//       data: (userData) {
//         final AppMode? appMode = userData?.appMode;
//         final String? selectedTrack = userData?.selectedTrackId;
//
//         String initialRoute = '/home'; // Original default
//         if (appMode == null) {
//           initialRoute = '/select_mode';
//         } else if (appMode == AppMode.guided && selectedTrack == null) {
//           initialRoute = '/select_track';
//         }
//
//         return MaterialApp(
//           title: 'AlphaFlow',
//           theme: ThemeData(
//             colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
//             useMaterial3: true,
//           ),
//           debugShowCheckedModeBanner: false,
//           initialRoute: initialRoute,
//           routes: {
//             '/home': (context) => const HomePage(),
//             '/select_mode': (context) => const SelectModePage(),
//             '/select_track': (context) => const SelectTrackPage(),
//             '/task_editor': (context) {
//               final args = ModalRoute.of(context)?.settings.arguments;
//               if (args is CustomTask) {
//                 return TaskEditorPage(taskToEdit: args);
//               }
//               return const TaskEditorPage();
//             },
//             '/settings': (context) => const SettingsPage(),
//           },
//         );
//       },
//     );
//   }
// }
import 'package:alphaflow/data/models/app_mode.dart';
import 'package:alphaflow/data/models/custom_task.dart';
import 'package:alphaflow/data/models/user_data.dart';
import 'package:alphaflow/features/custom/presentation/task_editor_page.dart';
import 'package:alphaflow/features/guided/presentation/select_track_page.dart';
import 'package:alphaflow/features/home/presentation/home_page.dart';
import 'package:alphaflow/features/onboarding/presentation/select_mode_page.dart';
import 'package:alphaflow/features/settings/presentation/settings_page.dart';
// Updated path for appModeNotifierProvider - it's still in app_mode_provider.dart
import 'package:alphaflow/providers/app_mode_provider.dart';
// Updated path for selectedTrackNotifierProvider - it's still in selected_track_provider.dart
import 'package:alphaflow/providers/selected_track_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphaflow/data/local/preferences_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:alphaflow/widgets/loading_screen.dart';
import 'package:alphaflow/features/user_profile/application/user_data_providers.dart';
import 'package:alphaflow/features/auth/application/auth_providers.dart';
import 'package:alphaflow/features/user_profile/application/user_data_service.dart';
import 'package:alphaflow/features/guided/providers/guided_tracks_provider.dart'; // For migration
import 'package:alphaflow/data/models/guided_track.dart'; // For migration List<GuidedTrack>

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final prefsService = await PreferencesService.init();

  final container = ProviderContainer(
    overrides: [
      preferencesServiceProvider.overrideWithValue(prefsService),
      // guidedTracksProvider may need to be overridden if it depends on something async
      // For now, assume it's a simple Provider as before.
    ],
  );

  try {
    print("MAIN_TRACE: Attempting to get anonymous user...");
    final user = await container.read(anonymousUserProvider.future);
    print("MAIN_TRACE: Anonymous user future completed. User: ${user?.uid}");

    if (user?.uid != null) {
      final userId = user!.uid;
      print("MAIN_TRACE: UserID: $userId. Accessing UserDataService...");
      final userDataService = container.read(userDataServiceProvider);
      print("MAIN_TRACE: UserDataService accessed. Ensuring user document exists for $userId...");
      await userDataService.ensureUserDataDocumentExists(userId);
      print("MAIN_TRACE: ensureUserDataDocumentExists completed for $userId.");

      print("MAIN_TRACE: Accessing guidedTracksProvider...");
      final allGuidedTracks = container.read(guidedTracksProvider);
      print("MAIN_TRACE: guidedTracksProvider accessed. Starting data migration for $userId...");
      await userDataService.migrateUserDataIfNeeded(userId, prefsService, allGuidedTracks);
      print("MAIN_TRACE: migrateUserDataIfNeeded completed for $userId.");
    } else {
      print("MAIN_TRACE: User was null or user.uid was null after anonymous sign-in attempt.");
    }
  } catch (e, s) { // Added stack trace parameter s
    print("MAIN_TRACE: ERROR during initial user setup/migration: $e");
    print("MAIN_TRACE: Stack trace: $s"); // Print stack trace
  }
  print("MAIN_TRACE: Proceeding to runApp().");
  runApp(
      UncontrolledProviderScope(
        container: container,
        child: const MyApp(),
      )
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDataAsync = ref.watch(userDataProvider);

    return userDataAsync.when(
      loading: () => MaterialApp(
        initialRoute: '/',
        routes: {'/': (context) => const LoadingScreen()},
        debugShowCheckedModeBanner: false,
      ),
      error: (err, stack) {
        print("Error loading user data in MyApp: $err");
        print(stack);
        return MaterialApp(home: Scaffold(body: Center(child: Text("Error loading data: $err"))));
      },
      data: (userData) {
        final AppMode? appMode = userData?.appMode;
        final String? selectedTrack = userData?.selectedTrackId;

        String initialRoute = '/home'; // Original default
        if (appMode == null) {
          initialRoute = '/select_mode';
        } else if (appMode == AppMode.guided && selectedTrack == null) {
          initialRoute = '/select_track';
        }

        return MaterialApp(
          title: 'AlphaFlow',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
            useMaterial3: true,
          ),
          debugShowCheckedModeBanner: false,
          initialRoute: initialRoute,
          routes: {
            '/home': (context) => const HomePage(),
            '/select_mode': (context) => const SelectModePage(),
            '/select_track': (context) => const SelectTrackPage(),
            '/task_editor': (context) {
              final args = ModalRoute.of(context)?.settings.arguments;
              if (args is CustomTask) {
                return TaskEditorPage(taskToEdit: args);
              }
              return const TaskEditorPage();
            },
            '/settings': (context) => const SettingsPage(),
          },
        );
      },
    );
  }
}