import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:from_fed_to_chain_app/widgets/audio_controls.dart';
import 'package:from_fed_to_chain_app/widgets/search_bar.dart';
import 'package:from_fed_to_chain_app/themes/app_theme.dart';

void main() {
  group('Basic Widget Tests', () {
    testWidgets('AudioControls renders correctly', (tester) async {
      bool playPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: AudioControls(
              isPlaying: false,
              isLoading: false,
              hasError: false,
              onPlayPause: () {
                playPressed = true;
              },
              onNext: () {},
              onPrevious: () {},
              onSkipForward: () {},
              onSkipBackward: () {},
            ),
          ),
        ),
      );

      // Should find the play button
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      // Tap the play button
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      expect(playPressed, true);
    });

    testWidgets('AudioControls shows pause when playing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: AudioControls(
              isPlaying: true,
              isLoading: false,
              hasError: false,
              onPlayPause: () {},
              onNext: () {},
              onPrevious: () {},
              onSkipForward: () {},
              onSkipBackward: () {},
            ),
          ),
        ),
      );

      // Should find the pause button when playing
      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
    });

    testWidgets('AudioControls handles different sizes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Column(
              children: [
                AudioControls(
                  isPlaying: false,
                  isLoading: false,
                  hasError: false,
                  onPlayPause: () {},
                  onNext: () {},
                  onPrevious: () {},
                  onSkipForward: () {},
                  onSkipBackward: () {},
                  size: AudioControlsSize.small,
                ),
                AudioControls(
                  isPlaying: false,
                  isLoading: false,
                  hasError: false,
                  onPlayPause: () {},
                  onNext: () {},
                  onPrevious: () {},
                  onSkipForward: () {},
                  onSkipBackward: () {},
                  size: AudioControlsSize.medium,
                ),
                AudioControls(
                  isPlaying: false,
                  isLoading: false,
                  hasError: false,
                  onPlayPause: () {},
                  onNext: () {},
                  onPrevious: () {},
                  onSkipForward: () {},
                  onSkipBackward: () {},
                  size: AudioControlsSize.large,
                ),
              ],
            ),
          ),
        ),
      );

      // Should find 3 audio control widgets
      expect(find.byType(AudioControls), findsNWidgets(3));
    });

    testWidgets('SearchBarWidget renders and accepts input', (tester) async {
      String searchQuery = '';

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SearchBarWidget(
              onSearchChanged: (query) {
                searchQuery = query;
              },
            ),
          ),
        ),
      );

      // Should find the search input field
      expect(find.byType(TextField), findsOneWidget);

      // Enter text
      await tester.enterText(find.byType(TextField), 'bitcoin');
      await tester.pump();

      expect(searchQuery, 'bitcoin');
    });

    testWidgets('SearchBarWidget shows clear button when has text',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SearchBarWidget(
              initialValue: 'test query',
              onSearchChanged: (query) {},
            ),
          ),
        ),
      );

      // Should find the clear button when there's text
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('SearchBarWidget clear button works', (tester) async {
      String searchQuery = 'initial query';

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: SearchBarWidget(
                  initialValue: searchQuery,
                  onSearchChanged: (query) {
                    setState(() {
                      searchQuery = query;
                    });
                  },
                ),
              );
            },
          ),
        ),
      );

      // Tap the clear button
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      expect(searchQuery, '');
    });
  });

  group('Theme Tests', () {
    test('AppTheme provides correct colors', () {
      expect(AppTheme.primaryColor, const Color(0xFF6366F1));
      expect(AppTheme.backgroundColor, const Color(0xFF0F172A));
      expect(AppTheme.surfaceColor, const Color(0xFF1E293B));
    });

    test('AppTheme provides language colors', () {
      expect(AppTheme.getLanguageColor('zh-TW'), isA<Color>());
      expect(AppTheme.getLanguageColor('en-US'), isA<Color>());
      expect(AppTheme.getLanguageColor('ja-JP'), isA<Color>());
    });

    test('AppTheme provides category colors', () {
      expect(AppTheme.getCategoryColor('daily-news'), isA<Color>());
      expect(AppTheme.getCategoryColor('ethereum'), isA<Color>());
      expect(AppTheme.getCategoryColor('macro'), isA<Color>());
    });

    test('AppTheme provides display names', () {
      expect(AppTheme.getCategoryDisplayName('daily-news'), 'Daily News');
      expect(AppTheme.getCategoryDisplayName('ethereum'), 'Ethereum');
      expect(AppTheme.getLanguageDisplayName('zh-TW'), '繁體中文');
      expect(AppTheme.getLanguageDisplayName('en-US'), 'English');
    });
  });
}
