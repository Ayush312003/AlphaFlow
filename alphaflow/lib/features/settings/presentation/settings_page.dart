import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Settings Page Placeholder\n\nOptions like "Clear All Data", "Reset Mode", etc., will go here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16), // Added style for better appearance
          ),
        ),
      ),
    );
  }
}
