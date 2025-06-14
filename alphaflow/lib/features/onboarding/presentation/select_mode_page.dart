import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Keep if any page it navigates to needs it, or for consistency.

class SelectModePage extends ConsumerWidget {
  const SelectModePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print("Building MINIMAL SelectModePage"); // Debug print
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Mode (Minimal)'),
      ),
      body: const Center(
        child: Text('This is a minimal Select Mode Page.'),
      ),
    );
  }
}
