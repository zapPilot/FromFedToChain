// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fromfedtochain_v2/main.dart';
import 'package:fromfedtochain_v2/services/content_service.dart';
import 'package:fromfedtochain_v2/services/audio_service.dart';
import 'package:fromfedtochain_v2/services/auth_service.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Initialize services
    final contentService = ContentService();
    final audioService = AudioPlayerService();
    final authService = AuthService();

    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(
      contentService: contentService,
      audioService: audioService,
      authService: authService,
    ));

    // Verify splash screen appears
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
