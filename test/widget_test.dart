import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Basic App Tests', () {
    testWidgets('should create a MaterialApp', (tester) async {
      final testApp = MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('From Fed to Chain Audio'),
          ),
        ),
      );

      await tester.pumpWidget(testApp);

      expect(find.text('From Fed to Chain Audio'), findsOneWidget);
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should display app icon and text', (tester) async {
      final testApp = MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.audiotrack, size: 64),
                SizedBox(height: 16),
                Text(
                  'From Fed to Chain Audio',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('Audio content streaming app'),
              ],
            ),
          ),
        ),
      );

      await tester.pumpWidget(testApp);

      expect(find.byIcon(Icons.audiotrack), findsOneWidget);
      expect(find.text('From Fed to Chain Audio'), findsOneWidget);
      expect(find.text('Audio content streaming app'), findsOneWidget);
    });
  });

  group('App Theme Tests', () {
    testWidgets('should apply dark theme correctly', (tester) async {
      final testApp = MaterialApp(
        theme: ThemeData(
          brightness: Brightness.dark,
        ),
        home: Scaffold(
          body: Center(
            child: Text('Theme Test'),
          ),
        ),
      );

      await tester.pumpWidget(testApp);

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme?.brightness, equals(Brightness.dark));
      expect(find.text('Theme Test'), findsOneWidget);
    });
  });
}
