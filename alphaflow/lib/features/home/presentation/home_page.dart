import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphaflow/data/models/app_mode.dart';
import 'package:alphaflow/features/guided/presentation/guided_home_page.dart';
import 'package:alphaflow/features/custom/presentation/custom_home_page.dart';
import 'package:alphaflow/features/onboarding/presentation/select_mode_page.dart';
import 'package:alphaflow/features/guided/presentation/select_track_page.dart';
import 'package:alphaflow/widgets/navigation_drawer_widget.dart';
import 'package:alphaflow/features/guided/providers/guided_tracks_provider.dart';
import 'package:alphaflow/providers/app_mode_provider.dart';
import 'package:alphaflow/providers/selected_track_provider.dart';
import 'package:alphaflow/widgets/sync_status_indicator.dart'; // For sync status display

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appMode = ref.watch(localAppModeProvider); // Changed to local provider

    // If no app mode is set, show the select mode page
    if (appMode == null) {
      return const SelectModePage();
    }

    // If guided mode but no track selected, show the select track page
    if (appMode == AppMode.guided) {
      final selectedTrackId = ref.watch(localSelectedTrackProvider); // Changed to local provider
      if (selectedTrackId == null) {
        return const SelectTrackPage();
      }
    }

    // If we have a valid app mode and track (if guided), show the appropriate home page
    return _buildHomePage(context, ref, appMode);
  }

  Widget _buildHomePage(BuildContext context, WidgetRef ref, AppMode appMode) {
    const Widget drawerWidget = NavigationDrawerWidget(); // Use the actual widget

    String appBarTitle = "AlphaFlow"; // Default title
    Widget currentPageBody;

    if (appMode == AppMode.guided) {
      final selectedTrackId = ref.watch(localSelectedTrackProvider);
      final trackAsync = ref.watch(guidedTrackByIdProvider(selectedTrackId!));
      
      return trackAsync.when(
        data: (track) {
          appBarTitle = track?.title ?? "Guided Mode"; // Use track title or fallback
          currentPageBody = const GuidedHomePage(); // GuidedHomePage now returns only its body
          
          return Scaffold(
            appBar: AppBar(
              title: Text(appBarTitle),
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            ),
            drawer: drawerWidget,
            body: currentPageBody,
          );
        },
        loading: () => Scaffold(
          appBar: AppBar(
            title: const Text("Guided Mode"),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          drawer: drawerWidget,
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) => Scaffold(
          appBar: AppBar(
            title: const Text("Guided Mode"),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          drawer: drawerWidget,
          body: Center(child: Text("Error loading track: $error")),
        ),
      );
    } else if (appMode == AppMode.custom) {
      appBarTitle = "Custom Mode";
      currentPageBody = const CustomHomePage(); // CustomHomePage now returns only its body
    } else {
      // Fallback for any unexpected app mode
      currentPageBody = const Center(child: Text("Unknown app mode", style: TextStyle(fontSize: 16)));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      drawer: drawerWidget,
      body: currentPageBody,
    );
  }
}
