// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:from_fed_to_chain_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Load environment variables for testing
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      // Ignore if .env doesn't exist in test environment
      print('Test warning: Could not load .env file: $e');
    }

    // Build our app and trigger a frame.
    await tester.pumpWidget(const FromFedToChainApp(audioHandler: null));

    // Verify that the app loads without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
