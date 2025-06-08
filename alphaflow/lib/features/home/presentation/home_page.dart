import 'package:alphaflow/data/models/app_mode.dart';
import 'package:alphaflow/features/custom/presentation/custom_home_page.dart';
import 'package:alphaflow/features/guided/presentation/guided_home_page.dart';
import 'package:alphaflow/providers/app_mode_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appMode = ref.watch(appModeProvider);

    if (appMode == null) {
      // This case should ideally not be reached if previous navigation is correct.
      // Perform navigation after the build cycle is complete.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(
            context, '/select_mode', (route) => false);
      });
      // Show loading indicator while redirecting
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (appMode == AppMode.guided) {
      return const GuidedHomePage();
    }

    if (appMode == AppMode.custom) {
      return const CustomHomePage();
    }

    // Fallback, should ideally not be reached if logic is sound.
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: const Center(child: Text("Error: Unknown app mode.")),
    );
  }
}
