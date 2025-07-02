// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:alphaflow/data/local/preferences_service.dart'; // Added import
import 'package:alphaflow/providers/app_mode_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:alphaflow/main.dart';
// Removed import 'fake_preferences_service.dart';

void main() {
  late PreferencesService fakePreferencesService;

  setUpAll(() async { // Made setUpAll async
    SharedPreferences.setMockInitialValues({});
    // Initialize a real PreferencesService with mocked SharedPreferences
    fakePreferencesService = await PreferencesService.init();
  });

  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesServiceProvider.overrideWithValue(fakePreferencesService),
        ],
        child: const AlphaFlowApp(),
      ),
    );

    // Verify that the SelectModePage is shown (initial route when appMode is null)
    expect(find.text('Choose Your Path'), findsOneWidget);
    expect(find.text('Guided Mode'), findsOneWidget);
    expect(find.text('Custom Mode'), findsOneWidget);

    // Example: Verify AppBar title as well, if needed
    expect(find.widgetWithText(AppBar, 'Select Your Mode'), findsOneWidget);
  });
}
