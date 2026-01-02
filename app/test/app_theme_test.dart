import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:from_fed_to_chain_app/core/theme/app_theme.dart';

void main() {
  group('App Theme Tests', () {
    testWidgets('Dark theme has correct properties', (tester) async {
      final theme = AppTheme.darkTheme;

      expect(theme.brightness, equals(Brightness.dark));
      expect(theme.useMaterial3, isTrue);
      expect(theme.scaffoldBackgroundColor, equals(AppTheme.backgroundColor));
    });

    testWidgets('Color scheme is properly configured', (tester) async {
      final theme = AppTheme.darkTheme;
      final colorScheme = theme.colorScheme;

      expect(colorScheme.brightness, equals(Brightness.dark));
      expect(colorScheme.primary, equals(AppTheme.primaryColor));
      expect(colorScheme.secondary, equals(AppTheme.secondaryColor));
      expect(colorScheme.surface, equals(AppTheme.surfaceColor));
      // Material 3: backgroundColor is now set via scaffoldBackgroundColor, not ColorScheme
      expect(theme.scaffoldBackgroundColor, equals(AppTheme.backgroundColor));
    });

    testWidgets('AppBar theme is correctly configured', (tester) async {
      final theme = AppTheme.darkTheme;
      final appBarTheme = theme.appBarTheme;

      expect(appBarTheme.backgroundColor, equals(Colors.transparent));
      expect(appBarTheme.elevation, equals(0));
      expect(appBarTheme.centerTitle, isTrue);
    });

    testWidgets('Card theme is correctly configured', (tester) async {
      final theme = AppTheme.darkTheme;
      final cardTheme = theme.cardTheme;

      expect(cardTheme.color, equals(AppTheme.surfaceColor));
      expect(cardTheme.elevation, equals(AppTheme.elevationS));
    });

    testWidgets('Button themes are correctly configured', (tester) async {
      final theme = AppTheme.darkTheme;

      expect(theme.elevatedButtonTheme.style?.backgroundColor?.resolve({}),
          equals(AppTheme.primaryColor));
      expect(theme.textButtonTheme.style?.foregroundColor?.resolve({}),
          equals(AppTheme.primaryColor));
    });

    test('Language colors are properly defined', () {
      expect(AppTheme.getLanguageColor('zh-TW'), isA<Color>());
      expect(AppTheme.getLanguageColor('en-US'), isA<Color>());
      expect(AppTheme.getLanguageColor('ja-JP'), isA<Color>());
      expect(
          AppTheme.getLanguageColor('unknown'), equals(AppTheme.primaryColor));
    });

    test('Category colors are properly defined', () {
      expect(AppTheme.getCategoryColor('daily-news'), isA<Color>());
      expect(AppTheme.getCategoryColor('ethereum'), isA<Color>());
      expect(AppTheme.getCategoryColor('macro'), isA<Color>());
      expect(AppTheme.getCategoryColor('startup'), isA<Color>());
      expect(AppTheme.getCategoryColor('ai'), isA<Color>());
      expect(AppTheme.getCategoryColor('unknown'),
          equals(AppTheme.secondaryColor));
    });

    test('Category display names are correct', () {
      expect(
          AppTheme.getCategoryDisplayName('daily-news'), equals('Daily News'));
      expect(AppTheme.getCategoryDisplayName('ethereum'), equals('Ethereum'));
      expect(AppTheme.getCategoryDisplayName('macro'), equals('Macro'));
      expect(AppTheme.getCategoryDisplayName('startup'), equals('Startup'));
      expect(AppTheme.getCategoryDisplayName('ai'), equals('AI'));
      expect(AppTheme.getCategoryDisplayName('defi'), equals('DeFi'));
      expect(AppTheme.getCategoryDisplayName('unknown'), equals('UNKNOWN'));
    });

    test('Language display names are correct', () {
      expect(AppTheme.getLanguageDisplayName('zh-TW'), equals('繁體中文'));
      expect(AppTheme.getLanguageDisplayName('en-US'), equals('English'));
      expect(AppTheme.getLanguageDisplayName('ja-JP'), equals('日本語'));
      expect(AppTheme.getLanguageDisplayName('unknown'), equals('UNKNOWN'));
    });

    test('Glass morphism decoration is properly configured', () {
      final decoration = AppTheme.glassMorphismDecoration;

      expect(decoration.color, isA<Color>());
      expect(decoration.borderRadius, isA<BorderRadius>());
      expect(decoration.border, isA<Border>());
      expect(decoration.boxShadow, isNotEmpty);
    });

    test('Card decoration is properly configured', () {
      final decoration = AppTheme.cardDecoration;

      expect(decoration.color, equals(AppTheme.surfaceColor));
      expect(decoration.borderRadius, isA<BorderRadius>());
      expect(decoration.boxShadow, isNotEmpty);
    });

    test('Gradient card decoration is properly configured', () {
      final decoration = AppTheme.gradientCardDecoration;

      expect(decoration.gradient, isA<Gradient>());
      expect(decoration.borderRadius, isA<BorderRadius>());
      expect(decoration.boxShadow, isNotEmpty);
    });

    test('Spacing constants are defined', () {
      expect(AppTheme.spacingXS, equals(4.0));
      expect(AppTheme.spacingS, equals(8.0));
      expect(AppTheme.spacingM, equals(16.0));
      expect(AppTheme.spacingL, equals(24.0));
      expect(AppTheme.spacingXL, equals(32.0));
      expect(AppTheme.spacingXXL, equals(48.0));
    });

    test('Border radius constants are defined', () {
      expect(AppTheme.radiusS, equals(8.0));
      expect(AppTheme.radiusM, equals(12.0));
      expect(AppTheme.radiusL, equals(16.0));
      expect(AppTheme.radiusXL, equals(24.0));
    });

    test('Elevation constants are defined', () {
      expect(AppTheme.elevationS, equals(2.0));
      expect(AppTheme.elevationM, equals(4.0));
      expect(AppTheme.elevationL, equals(8.0));
      expect(AppTheme.elevationXL, equals(16.0));
    });

    test('Animation durations are defined', () {
      expect(AppTheme.animationFast, equals(const Duration(milliseconds: 150)));
      expect(
          AppTheme.animationMedium, equals(const Duration(milliseconds: 300)));
      expect(AppTheme.animationSlow, equals(const Duration(milliseconds: 500)));
    });

    test('Audio state colors are defined', () {
      expect(AppTheme.playingColor, equals(AppTheme.successColor));
      expect(AppTheme.pausedColor, equals(AppTheme.warningColor));
      expect(AppTheme.loadingColor, equals(AppTheme.primaryColor));
      expect(AppTheme.errorStateColor, equals(AppTheme.errorColor));
    });

    test('Safe padding methods work correctly', () {
      expect(AppTheme.safePadding, isA<EdgeInsets>());
      expect(AppTheme.safeHorizontalPadding, isA<EdgeInsets>());
      expect(AppTheme.safeVerticalPadding, isA<EdgeInsets>());
    });

    testWidgets('Theme can be applied to MaterialApp', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: Center(
              child: Text('Test App'),
            ),
          ),
        ),
      );

      expect(find.text('Test App'), findsOneWidget);

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme?.brightness, equals(Brightness.dark));
    });

    testWidgets('Widgets use theme colors correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            appBar: AppBar(title: const Text('Test')),
            body: const Column(
              children: [
                Card(child: Text('Card')),
                ElevatedButton(onPressed: null, child: Text('Button')),
                TextButton(onPressed: null, child: Text('Text Button')),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
      expect(find.text('Card'), findsOneWidget);
      expect(find.text('Button'), findsOneWidget);
      expect(find.text('Text Button'), findsOneWidget);

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('Input decoration theme works', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: TextField(
              decoration: InputDecoration(
                labelText: 'Test Input',
                hintText: 'Enter text',
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Test Input'), findsOneWidget);
    });

    testWidgets('Progress indicator theme works', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: Column(
              children: [
                CircularProgressIndicator(),
                LinearProgressIndicator(),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('List tile theme works', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: ListTile(
              leading: Icon(Icons.star),
              title: Text('Test Item'),
              subtitle: Text('Subtitle'),
            ),
          ),
        ),
      );

      expect(find.text('Test Item'), findsOneWidget);
      expect(find.text('Subtitle'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });
  });
}
