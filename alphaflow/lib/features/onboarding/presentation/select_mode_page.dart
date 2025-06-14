import 'package:alphaflow/data/models/app_mode.dart';
import 'package:alphaflow/providers/app_mode_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelectModePage extends ConsumerWidget {
  const SelectModePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Mode'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Choose Your Path',
                style: textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  final appModeNotifier = ref.read(appModeNotifierProvider.notifier);
                  appModeNotifier.setAppMode(AppMode.guided);
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/select_track', (route) => false);
                },
                child: const Text('Guided Mode'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  final appModeNotifier = ref.read(appModeNotifierProvider.notifier);
                  appModeNotifier.setAppMode(AppMode.custom);
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/home', (route) => false);
                },
                child: const Text('Custom Mode'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
