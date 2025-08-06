import 'package:alphaflow/data/models/custom_task.dart';
import 'package:alphaflow/features/auth/presentation/onboarding_page.dart';
import 'package:alphaflow/features/custom/presentation/task_editor_page.dart';
import 'package:alphaflow/features/guided/presentation/select_track_page.dart';
import 'package:alphaflow/features/home/presentation/home_page.dart';
import 'package:alphaflow/features/onboarding/presentation/select_mode_page.dart';
import 'package:alphaflow/features/settings/presentation/settings_page.dart';
import 'package:alphaflow/providers/app_mode_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:alphaflow/data/local/preferences_service.dart';
import 'package:alphaflow/widgets/branded_splash_screen.dart';
import 'package:alphaflow/widgets/app_lifecycle_handler.dart'; // For batch sync lifecycle handling
import 'package:alphaflow/features/auth/application/auth_providers.dart';
import 'package:alphaflow/core/theme/alphaflow_theme.dart'; // Import the new theme

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

class AlphaFlowApp extends ConsumerWidget {
  const AlphaFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return AppLifecycleHandler(
      child: MaterialApp(
        title: 'AlphaFlow',
        theme: AlphaFlowTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        home: authState.when(
          data: (user) {
            if (user == null) {
              return const OnboardingPage();
            }
            return const HomePage();
          },
          loading: () => const BrandedSplashScreen(),
          error: (error, stack) => const BrandedSplashScreen(),
        ),
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
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => Scaffold(
              body: Center(child: Text('Unknown route: ${settings.name}')),
            ),
          );
        },
      ),
    );
  }
}