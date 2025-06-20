import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:alphaflow/providers/app_mode_provider.dart'; // Old
import 'package:alphaflow/data/models/app_mode.dart';
import 'package:alphaflow/features/guided/presentation/guided_home_page.dart';
import 'package:alphaflow/features/custom/presentation/custom_home_page.dart';
import 'package:alphaflow/widgets/navigation_drawer_widget.dart'; // Placeholder import
// import 'package:alphaflow/providers/selected_track_provider.dart'; // Old
import 'package:alphaflow/features/user_profile/application/user_data_providers.dart'; // New
import 'package:alphaflow/features/guided/providers/guided_tracks_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appMode = ref.watch(firestoreAppModeProvider); // Changed
    const Widget drawerWidget = NavigationDrawerWidget(); // Use the actual widget

    String appBarTitle = "AlphaFlow"; // Default title
    Widget currentPageBody;

    if (appMode == null) {
      // This case should ideally not be reached if previous navigation is correct.
      // Perform navigation after the build cycle is complete.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(context, '/select_mode', (route) => false);
      });
      currentPageBody = const Center(child: CircularProgressIndicator());
      // appBarTitle remains default or could be "Loading..."
    } else if (appMode == AppMode.guided) {
      final selectedTrackId = ref.watch(firestoreSelectedTrackProvider); // Changed
      if (selectedTrackId == null) {
        // This case implies an inconsistent state, redirect to track selection.
        // The route check for '/home' or isFirst is to avoid issues if already on home or during init.
        WidgetsBinding.instance.addPostFrameCallback((_) {
             Navigator.pushNamedAndRemoveUntil(context, '/select_track', (route) => route.settings.name == '/home' || route.isFirst);
        });
        currentPageBody = const Center(child: Text("No track selected, redirecting...", style: TextStyle(fontSize: 16)));
        appBarTitle = "Guided Mode";
      } else {
        final track = ref.watch(guidedTrackByIdProvider(selectedTrackId));
        appBarTitle = track?.title ?? "Guided Mode"; // Use track title or fallback
        currentPageBody = const GuidedHomePage(); // GuidedHomePage now returns only its body
      }
    } else if (appMode == AppMode.custom) {
      appBarTitle = "My Custom Tasks"; // More specific title for custom mode
      currentPageBody = const CustomHomePage(); // CustomHomePage returns Scaffold (no AppBar) + FAB
    } else {
      // Fallback for any unknown app mode, should ideally not be reached.
      appBarTitle = "Error";
      currentPageBody = const Center(child: Text("Error: Unknown app mode.", style: TextStyle(fontSize: 16, color: Colors.red)));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        // Actions can be added here later if needed globally for both modes
      ),
      drawer: drawerWidget,
      body: currentPageBody,
    );
  }
}
