import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:from_fed_to_chain_app/models/audio_file.dart';
import 'package:from_fed_to_chain_app/widgets/audio_item_card.dart';
import 'package:from_fed_to_chain_app/widgets/filter_bar.dart';
import 'package:from_fed_to_chain_app/widgets/search_bar.dart' as custom_search;
import 'package:from_fed_to_chain_app/widgets/mini_player.dart';
import 'package:from_fed_to_chain_app/themes/app_theme.dart';
import 'package:from_fed_to_chain_app/services/audio_player_service.dart';
import 'package:from_fed_to_chain_app/services/player_state_notifier.dart';

import 'widgets/widget_test_utils.dart';
import 'test_utils.dart';

/// Integration tests for core app functionality
/// These tests verify the key user workflows and component interactions
void main() {
  group('Core App Integration Tests', () {
    late List<AudioFile> testAudioFiles;

    setUp(() {
      WidgetTestUtils.resetCallbacks();
      testAudioFiles = WidgetTestUtils.createTestAudioFileList(count: 10);
    });

    group('Audio List Display Integration', () {
      testWidgets('should display audio items with proper content filtering',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              backgroundColor: AppTheme.backgroundColor,
              body: Column(
                children: [
                  // Filter bar with search
                  FilterBar(
                    selectedLanguage: 'en-US',
                    selectedCategory: 'all',
                    onLanguageChanged: WidgetTestUtils.mockLanguageChanged,
                    onCategoryChanged: WidgetTestUtils.mockCategoryChanged,
                  ),
                  custom_search.SearchBarWidget(
                    onSearchChanged: WidgetTestUtils.mockSearchChanged,
                  ),
                  // Audio list
                  Expanded(
                    child: ListView.builder(
                      itemCount: testAudioFiles.length,
                      itemBuilder: (context, index) {
                        return AudioItemCard(
                          audioFile: testAudioFiles[index],
                          onTap: WidgetTestUtils.mockTap,
                          showPlayButton: true,
                          isCurrentlyPlaying: index == 0, // First item playing
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        // Verify all components are rendered
        expect(find.byType(FilterBar), findsOneWidget);
        expect(find.byType(custom_search.SearchBarWidget), findsOneWidget);
        expect(find.byType(ListView), findsOneWidget);
        expect(find.byType(AudioItemCard), findsAtLeastNWidget(3));

        // Verify first item shows as currently playing
        final audioCards = find.byType(AudioItemCard);
        expect(audioCards, findsWidgets);
        expect(find.text('Now Playing'), findsOneWidget);

        // Verify filter functionality exists
        expect(find.text('Language'), findsOneWidget);
        expect(find.text('Category'), findsOneWidget);
      });

      testWidgets('should handle audio item selection and playback state',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: ListView.builder(
                itemCount: 3,
                itemBuilder: (context, index) {
                  return AudioItemCard(
                    audioFile: testAudioFiles[index],
                    onTap: WidgetTestUtils.mockTap,
                    showPlayButton: true,
                    isCurrentlyPlaying: false,
                  );
                },
              ),
            ),
          ),
        );

        // Test tapping on an audio item
        final firstCard = find.byType(AudioItemCard).first;
        await tester.tap(firstCard);
        await tester.pumpAndSettle();

        expect(WidgetTestUtils.tapCount, equals(1));
      });
    });

    group('Search and Filter Integration', () {
      testWidgets('should integrate search bar with filter functionality',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Column(
                children: [
                  custom_search.SearchBarWidget(
                    onSearchChanged: WidgetTestUtils.mockSearchChanged,
                  ),
                  FilterBar(
                    selectedLanguage: 'en-US',
                    selectedCategory: 'daily-news',
                    onLanguageChanged: WidgetTestUtils.mockLanguageChanged,
                    onCategoryChanged: WidgetTestUtils.mockCategoryChanged,
                  ),
                ],
              ),
            ),
          ),
        );

        // Test search interaction
        final searchField = find.byType(TextField);
        await tester.enterText(searchField, 'Bitcoin');
        await tester.pumpAndSettle();

        expect(WidgetTestUtils.lastSearchText, equals('Bitcoin'));

        // Test filter interaction - look for language selection
        final languageChips = find.textContaining('English');
        if (languageChips.evaluate().isNotEmpty) {
          await tester.tap(languageChips.first);
          await tester.pumpAndSettle();
          expect(WidgetTestUtils.lastSelectedLanguage, isNotEmpty);
        }
      });

      testWidgets('should clear search when clear button is tapped',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: custom_search.SearchBarWidget(
                onSearchChanged: WidgetTestUtils.mockSearchChanged,
                initialValue: 'Initial Search',
              ),
            ),
          ),
        );

        // Should show clear button when there's text
        expect(find.byIcon(Icons.clear), findsOneWidget);

        // Tap clear button
        await tester.tap(find.byIcon(Icons.clear));
        await tester.pumpAndSettle();

        // Should trigger search change with empty text
        expect(WidgetTestUtils.lastSearchText, equals(''));
      });
    });

    group('Mini Player Integration', () {
      testWidgets('should display mini player with correct audio information',
          (WidgetTester tester) async {
        final testAudio = testAudioFiles.first;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Column(
                children: [
                  const Expanded(child: SizedBox()), // Main content area
                  WidgetTestUtils.createMiniPlayer(
                    audioFile: testAudio,
                    playbackState: AppPlaybackState.playing,
                    onTap: WidgetTestUtils.mockTap,
                    onPlayPause: WidgetTestUtils.mockPlayPause,
                    onNext: WidgetTestUtils.mockNext,
                    onPrevious: WidgetTestUtils.mockPrevious,
                  ),
                ],
              ),
            ),
          ),
        );

        // Verify mini player displays audio information
        expect(find.byType(MiniPlayer), findsOneWidget);
        expect(find.text(testAudio.displayTitle), findsOneWidget);

        // Verify controls are present
        expect(find.byIcon(Icons.skip_previous), findsOneWidget);
        expect(find.byIcon(Icons.pause), findsOneWidget); // Playing state
        expect(find.byIcon(Icons.skip_next), findsOneWidget);

        // Test play/pause interaction
        await tester.tap(find.byIcon(Icons.pause));
        await tester.pumpAndSettle();
        expect(WidgetTestUtils.lastPlayPauseState, isTrue);
      });

      testWidgets('should handle mini player navigation controls',
          (WidgetTester tester) async {
        final testAudio = testAudioFiles.first;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: WidgetTestUtils.createMiniPlayer(
                audioFile: testAudio,
                playbackState: AppPlaybackState.paused,
                onTap: WidgetTestUtils.mockTap,
                onPlayPause: WidgetTestUtils.mockPlayPause,
                onNext: WidgetTestUtils.mockNext,
                onPrevious: WidgetTestUtils.mockPrevious,
              ),
            ),
          ),
        );

        // Test previous button
        await tester.tap(find.byIcon(Icons.skip_previous));
        await tester.pumpAndSettle();

        // Test next button
        await tester.tap(find.byIcon(Icons.skip_next));
        await tester.pumpAndSettle();

        // Verify both interactions were captured
        expect(WidgetTestUtils.tapCount, equals(2));
      });
    });

    group('Theme and Accessibility Integration', () {
      testWidgets('should apply consistent theming across components',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              backgroundColor: AppTheme.backgroundColor,
              body: Column(
                children: [
                  custom_search.SearchBarWidget(
                    onSearchChanged: WidgetTestUtils.mockSearchChanged,
                  ),
                  FilterBar(
                    selectedLanguage: 'en-US',
                    selectedCategory: 'all',
                    onLanguageChanged: WidgetTestUtils.mockLanguageChanged,
                    onCategoryChanged: WidgetTestUtils.mockCategoryChanged,
                  ),
                  AudioItemCard(
                    audioFile: testAudioFiles.first,
                    onTap: WidgetTestUtils.mockTap,
                    showPlayButton: true,
                    isCurrentlyPlaying: false,
                  ),
                ],
              ),
            ),
          ),
        );

        // Verify theme consistency
        WidgetTestUtils.verifyThemeColors(tester);

        // Verify components render without errors
        expect(tester.takeException(), isNull);
      });

      testWidgets('should meet basic accessibility requirements',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Column(
                children: [
                  custom_search.SearchBarWidget(
                    onSearchChanged: WidgetTestUtils.mockSearchChanged,
                  ),
                  AudioItemCard(
                    audioFile: testAudioFiles.first,
                    onTap: WidgetTestUtils.mockTap,
                    showPlayButton: true,
                    isCurrentlyPlaying: false,
                  ),
                ],
              ),
            ),
          ),
        );

        // Run basic accessibility checks
        await WidgetTestUtils.verifyAccessibility(tester);
      });
    });

    group('Error Handling Integration', () {
      testWidgets('should handle audio file with missing metadata gracefully',
          (WidgetTester tester) async {
        final audioFileWithMissingData = AudioFile(
          id: 'broken-audio',
          title: 'Broken Audio File',
          language: 'en-US',
          category: 'daily-news',
          streamingUrl: '', // Empty URL
          path: 'broken.m3u8',
          lastModified: DateTime.now(),
          // No duration or file size
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: AudioItemCard(
                audioFile: audioFileWithMissingData,
                onTap: WidgetTestUtils.mockTap,
                showPlayButton: true,
                isCurrentlyPlaying: false,
              ),
            ),
          ),
        );

        // Should render without throwing errors
        expect(find.byType(AudioItemCard), findsOneWidget);
        expect(find.text('Broken Audio File'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle empty audio list gracefully',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Column(
                children: [
                  custom_search.SearchBarWidget(
                    onSearchChanged: WidgetTestUtils.mockSearchChanged,
                  ),
                  FilterBar(
                    selectedLanguage: 'en-US',
                    selectedCategory: 'all',
                    onLanguageChanged: WidgetTestUtils.mockLanguageChanged,
                    onCategoryChanged: WidgetTestUtils.mockCategoryChanged,
                  ),
                  const Expanded(
                    child: Center(
                      child: Text('No audio files found'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        // Should display empty state without errors
        expect(find.text('No audio files found'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('Performance Integration', () {
      testWidgets('should handle large audio file lists efficiently',
          (WidgetTester tester) async {
        final largeAudioList =
            WidgetTestUtils.createTestAudioFileList(count: 100);

        // Measure rendering time
        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: ListView.builder(
                itemCount: largeAudioList.length,
                itemBuilder: (context, index) {
                  return AudioItemCard(
                    audioFile: largeAudioList[index],
                    onTap: WidgetTestUtils.mockTap,
                    showPlayButton: true,
                    isCurrentlyPlaying: false,
                  );
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        stopwatch.stop();

        // Should render within reasonable time (less than 1 second)
        expect(stopwatch.elapsed.inMilliseconds, lessThan(1000));
        expect(tester.takeException(), isNull);

        // Should be able to scroll through the list
        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    });

    group('State Management Integration', () {
      testWidgets('should maintain consistent state across component updates',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    children: [
                      custom_search.SearchBarWidget(
                        onSearchChanged: (text) {
                          WidgetTestUtils.mockSearchChanged(text);
                          setState(() {});
                        },
                      ),
                      Text('Current search: ${WidgetTestUtils.lastSearchText}'),
                    ],
                  );
                },
              ),
            ),
          ),
        );

        // Test state updates are reflected in UI
        await tester.enterText(find.byType(TextField), 'Test Search');
        await tester.pumpAndSettle();

        expect(find.text('Current search: Test Search'), findsOneWidget);
      });
    });
  });
}
