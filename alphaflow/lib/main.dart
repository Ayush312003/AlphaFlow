import 'package:alphaflow/data/models/app_mode.dart';
import 'package:alphaflow/data/models/app_mode.dart';
import 'package:alphaflow/data/models/custom_task.dart';
import 'package:alphaflow/features/custom/presentation/task_editor_page.dart';
import 'package:alphaflow/features/guided/presentation/select_track_page.dart';
import 'package:alphaflow/features/home/presentation/home_page.dart';
import 'package:alphaflow/features/onboarding/presentation/select_mode_page.dart';
import 'package:alphaflow/features/settings/presentation/settings_page.dart'; // Added import
import 'package:alphaflow/providers/app_mode_provider.dart';
import 'package:alphaflow/providers/selected_track_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphaflow/data/local/preferences_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefsService = await PreferencesService.init();
  runApp(ProviderScope(
    overrides: [
      preferencesServiceProvider.overrideWithValue(prefsService),
    ],
    child: MyApp(),
  ));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appMode = ref.watch(appModeProvider);
    final selectedTrack = ref.watch(selectedTrackProvider);

    String initialRoute = '/home';

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
      initialRoute: initialRoute,
      routes: {
        '/home': (context) => const HomePage(),
        '/select_mode': (context) => const SelectModePage(),
        '/select_track': (context) => const SelectTrackPage(),
        '/task_editor': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is CustomTask) {
            return TaskEditorPage(taskToEdit: args); // For editing an existing task
          }
          return const TaskEditorPage(); // For creating a new task (taskToEdit will be null)
        },
        '/settings': (context) => const SettingsPage(), // Added route
      },
    );
  }
}
