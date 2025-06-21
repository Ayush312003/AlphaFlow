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
import 'package:alphaflow/widgets/app_lifecycle_handler.dart'; // For batch sync lifecycle handling
import 'package:alphaflow/features/user_profile/application/user_data_providers.dart';
import 'package:alphaflow/features/auth/application/auth_providers.dart';
import 'package:alphaflow/features/user_profile/application/user_data_service.dart';
import 'package:alphaflow/features/guided/providers/guided_tracks_provider.dart'; // For migration
import 'package:alphaflow/data/models/guided_track.dart'; // For migration List<GuidedTrack>
import 'package:google_fonts/google_fonts.dart'; // For better font and emoji support
import 'package:alphaflow/providers/task_completions_provider.dart'; // For localCompletionsInitializerProvider

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final prefsService = await PreferencesService.init();

  runApp(
    ProviderScope(
      overrides: [
        preferencesServiceProvider.overrideWithValue(prefsService),
      ],
      child: const AlphaFlowApp(),
    ),
  );
}

class AlphaFlowApp extends ConsumerStatefulWidget {
  const AlphaFlowApp({super.key});

  @override
  ConsumerState<AlphaFlowApp> createState() => _AlphaFlowAppState();
}

class _AlphaFlowAppState extends ConsumerState<AlphaFlowApp> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId != null && userId.isNotEmpty) {
      final userDataService = ref.read(userDataServiceProvider);
      final guidedTracksAsync = ref.read(guidedTracksProvider);
      final prefsService = ref.read(preferencesServiceProvider);

      // Ensure user document exists and migrate data if needed
      await userDataService.ensureUserDataDocumentExists(userId);
      
      // Handle async loading of guided tracks for migration
      final allGuidedTracks = await guidedTracksAsync.when(
        data: (tracks) => tracks,
        loading: () => <GuidedTrack>[],
        error: (error, stack) {
          print("Error loading guided tracks for migration: $error");
          return <GuidedTrack>[];
        },
      );
      
      await userDataService.migrateUserDataIfNeeded(userId, prefsService, allGuidedTracks);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLifecycleHandler(
      child: Consumer(
        builder: (context, ref, child) {
          final authState = ref.watch(anonymousUserProvider);
          
          // Initialize local completions with Firestore data
          ref.watch(localCompletionsInitializerProvider);

          return MaterialApp(
            title: 'AlphaFlow',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
              useMaterial3: true,
              textTheme: GoogleFonts.notoSansTextTheme(Theme.of(context).textTheme),
            ),
            debugShowCheckedModeBanner: false,
            home: authState.when(
              data: (user) {
                if (user == null) {
                  return const LoadingScreen();
                }

                // Always start with HomePage and let it handle navigation
                return const HomePage();
              },
              loading: () => const LoadingScreen(),
              error: (error, stack) {
                print('Auth error: $error');
                return const LoadingScreen();
              },
            ),
            routes: {
              '/home': (context) {
                print('Navigating to /home');
                return const HomePage();
              },
              '/select_mode': (context) {
                print('Navigating to /select_mode');
                return const SelectModePage();
              },
              '/select_track': (context) {
                print('Navigating to /select_track');
                return const SelectTrackPage();
              },
              '/task_editor': (context) {
                print('Navigating to /task_editor');
                final args = ModalRoute.of(context)?.settings.arguments;
                if (args is CustomTask) {
                  return TaskEditorPage(taskToEdit: args);
                }
                return const TaskEditorPage();
              },
              '/settings': (context) {
                print('Navigating to /settings');
                return const SettingsPage();
              },
            },
            onUnknownRoute: (settings) {
              print('Unknown route: ${settings.name}');
              return MaterialPageRoute(
                builder: (context) => Scaffold(
                  body: Center(child: Text('Unknown route: ${settings.name}')),
                ),
              );
            },
          );
        },
      ),
    );
  }
}