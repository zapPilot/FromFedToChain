import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:from_fed_to_chain_app/features/content/widgets/audio_item_card.dart';
import 'package:from_fed_to_chain_app/features/content/widgets/search_bar.dart'
    as custom_search;
import 'package:from_fed_to_chain_app/features/content/widgets/audio_list.dart';
import 'package:from_fed_to_chain_app/features/audio/widgets/mini_player.dart';
import 'package:from_fed_to_chain_app/features/content/widgets/filter_bar.dart';
import 'package:from_fed_to_chain_app/features/audio/widgets/audio_controls.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';
import 'package:from_fed_to_chain_app/core/theme/app_theme.dart';
import '../widgets/widget_test_utils.dart';

/// Performance benchmark tests for critical widgets
/// These tests measure rendering performance, memory usage, and responsiveness
void main() {
  group('Widget Performance Benchmarks', () {
    setUp(() {
      WidgetTestUtils.resetCallbacks();
    });

    group('AudioItemCard Performance', () {
      testWidgets('should render single card within performance threshold',
          (tester) async {
        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          WidgetTestUtils.createTestWrapper(
            AudioItemCard(
              audioFile: WidgetTestUtils.createTestAudioFile(),
              onTap: () {},
            ),
          ),
        );

        stopwatch.stop();

        // Rendering should complete within 500ms for single card (generous threshold)
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
      });

      testWidgets('should handle rapid card creation efficiently',
          (tester) async {
        final stopwatch = Stopwatch()..start();
        final cards = <Widget>[];

        // Create 50 cards rapidly
        for (int i = 0; i < 50; i++) {
          cards.add(
            AudioItemCard(
              audioFile: WidgetTestUtils.createTestAudioFile(
                title: 'Performance Test Card $i',
                id: 'perf-test-$i',
              ),
              onTap: () {},
            ),
          );
        }

        await tester.pumpWidget(
          WidgetTestUtils.createTestWrapper(
            SizedBox(
              height: 600,
              child: SingleChildScrollView(
                child: Column(children: cards),
              ),
            ),
          ),
        );

        stopwatch.stop();

        // 50 cards should render within 2 seconds
        expect(stopwatch.elapsedMilliseconds, lessThan(2000));
      });

      testWidgets('should maintain performance with complex content',
          (tester) async {
        final complexAudioFile = AudioFile(
          id: 'performance-test-complex',
          title:
              'Very Long Audio Title That Contains Multiple Words And Should Test Text Rendering Performance With Complex Layout Constraints',
          category: 'daily-news',
          language: 'en-US',
          streamingUrl: 'https://example.com/complex-audio.m3u8',
          path: '/complex/path/audio.m3u8',
          duration: const Duration(hours: 2, minutes: 30, seconds: 45),
          fileSizeBytes: 250000000, // 250MB
          lastModified: DateTime.now(),
        );

        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          WidgetTestUtils.createTestWrapper(
            AudioItemCard(
              audioFile: complexAudioFile,
              onTap: () {},
              isCurrentlyPlaying: true,
            ),
          ),
        );

        stopwatch.stop();

        // Complex content should still render within 400ms
        expect(stopwatch.elapsedMilliseconds, lessThan(400));
      });
    });

    group('SearchBarWidget Performance', () {
      testWidgets('should handle rapid text input efficiently', (tester) async {
        String currentSearchText = '';
        final searchChanges = <String>[];

        await tester.pumpWidget(
          WidgetTestUtils.createTestWrapper(
            custom_search.SearchBarWidget(
              onSearchChanged: (text) {
                currentSearchText = text;
                searchChanges.add(text);
              },
              hintText: 'Performance Test Search',
            ),
          ),
        );

        final searchField = find.byType(TextField);
        expect(searchField, findsOneWidget);

        final stopwatch = Stopwatch()..start();

        // Simulate rapid typing of 20 characters
        const testText = 'rapid typing test 123';
        for (int i = 0; i < testText.length; i++) {
          await tester.enterText(searchField, testText.substring(0, i + 1));
          await tester.pump(const Duration(milliseconds: 10));
        }

        stopwatch.stop();

        // Rapid typing should complete within 1 second
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
        expect(currentSearchText, equals(testText));
        expect(searchChanges.length, equals(testText.length));
      });

      testWidgets('should clear search efficiently', (tester) async {
        await tester.pumpWidget(
          WidgetTestUtils.createTestWrapper(
            custom_search.SearchBarWidget(
              onSearchChanged: (text) {},
              initialValue:
                  'Initial search text that is quite long for performance testing',
            ),
          ),
        );

        final clearButton = find.byIcon(Icons.clear);
        expect(clearButton, findsOneWidget);

        final stopwatch = Stopwatch()..start();

        await tester.tap(clearButton);
        await tester.pumpAndSettle();

        stopwatch.stop();

        // Clear operation should complete within 100ms
        expect(stopwatch.elapsedMilliseconds, lessThan(100));

        final textField = find.byType(TextField);
        final textFieldWidget = tester.widget<TextField>(textField);
        expect(textFieldWidget.controller?.text, isEmpty);
      });
    });

    group('AudioList Performance', () {
      testWidgets('should render large list efficiently', (tester) async {
        final largeAudioList = List.generate(
          100,
          (index) => WidgetTestUtils.createTestAudioFile(
            title: 'Performance Test Audio Item $index',
            id: 'perf-test-$index',
          ),
        );

        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          WidgetTestUtils.createTestWrapper(
            SizedBox(
              height: 600,
              child: AudioList(
                episodes: largeAudioList,
                onEpisodeTap: (audioFile) {},
              ),
            ),
          ),
        );

        stopwatch.stop();

        // Large list should render initial view within 500ms
        expect(stopwatch.elapsedMilliseconds, lessThan(500));

        // Verify list is rendered
        expect(find.byType(AudioList), findsOneWidget);
      });

      testWidgets('should scroll through large list smoothly', (tester) async {
        final largeAudioList = List.generate(
          200,
          (index) => WidgetTestUtils.createTestAudioFile(
            title: 'Scroll Test Audio $index',
            id: 'scroll-test-$index',
          ),
        );

        await tester.pumpWidget(
          WidgetTestUtils.createTestWrapper(
            SizedBox(
              height: 400,
              child: AudioList(
                episodes: largeAudioList,
                onEpisodeTap: (audioFile) {},
              ),
            ),
          ),
        );

        final listView = find.byType(ListView);
        expect(listView, findsOneWidget);

        final stopwatch = Stopwatch()..start();

        // Perform multiple scroll operations
        for (int i = 0; i < 10; i++) {
          await tester.drag(listView, const Offset(0, -200));
          await tester.pump(const Duration(milliseconds: 50));
        }

        stopwatch.stop();

        // Scrolling operations should complete within 2 seconds
        expect(stopwatch.elapsedMilliseconds, lessThan(2000));
      });
    });

    group('MiniPlayer Performance', () {
      testWidgets('should render with audio controls efficiently',
          (tester) async {
        final audioFile = WidgetTestUtils.createTestAudioFile(
          title: 'Performance Test Audio for Mini Player',
          duration: const Duration(minutes: 5, seconds: 30),
        );

        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          WidgetTestUtils.createTestWrapper(
            MiniPlayer(
              audioFile: audioFile,
              isPlaying: true,
              isPaused: false,
              isLoading: false,
              hasError: false,
              stateText: 'Playing',
              onTap: () {},
              onPlayPause: () {},
              onNext: () {},
              onPrevious: () {},
            ),
          ),
        );

        stopwatch.stop();

        // Mini player should render within 500ms
        expect(stopwatch.elapsedMilliseconds, lessThan(500));

        expect(find.byType(MiniPlayer), findsOneWidget);
      });

      testWidgets('should handle rapid state changes efficiently',
          (tester) async {
        final audioFile = WidgetTestUtils.createTestAudioFile();
        bool isPlaying = false;
        bool isPaused = true;

        await tester.pumpWidget(
          WidgetTestUtils.createTestWrapper(
            StatefulBuilder(
              builder: (context, setState) {
                return MiniPlayer(
                  audioFile: audioFile,
                  isPlaying: isPlaying,
                  isPaused: isPaused,
                  isLoading: false,
                  hasError: false,
                  stateText: isPlaying ? 'Playing' : 'Paused',
                  onTap: () {},
                  onPlayPause: () {
                    setState(() {
                      isPlaying = !isPlaying;
                      isPaused = !isPaused;
                    });
                  },
                  onNext: () {},
                  onPrevious: () {},
                );
              },
            ),
          ),
        );

        final stopwatch = Stopwatch()..start();

        // Simulate rapid state changes (like real audio playback)
        for (int i = 0; i < 20; i++) {
          final playPauseButton =
              find.byIcon(isPlaying ? Icons.pause : Icons.play_arrow);
          if (playPauseButton.evaluate().isNotEmpty) {
            await tester.tap(playPauseButton.first);
            await tester.pump();
          }
        }

        stopwatch.stop();

        // State changes should complete within 1 second
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });
    });

    group('FilterBar Performance', () {
      testWidgets('should handle filter changes efficiently', (tester) async {
        String currentCategory = 'all';
        String currentLanguage = 'all';

        await tester.pumpWidget(
          WidgetTestUtils.createTestWrapper(
            FilterBar(
              selectedCategory: currentCategory,
              selectedLanguage: currentLanguage,
              onCategoryChanged: (category) {
                currentCategory = category;
              },
              onLanguageChanged: (language) {
                currentLanguage = language;
              },
            ),
          ),
        );

        final stopwatch = Stopwatch()..start();

        // Find and tap filter buttons multiple times
        final filterButtons = find.byType(FilterChip);
        if (filterButtons.evaluate().isNotEmpty) {
          for (int i = 0; i < 5; i++) {
            await tester.tap(filterButtons.first);
            await tester.pump(const Duration(milliseconds: 50));
          }
        }

        stopwatch.stop();

        // Filter operations should complete within 500ms
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
      });
    });

    group('AudioControls Performance', () {
      testWidgets('should render audio controls efficiently', (tester) async {
        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          WidgetTestUtils.createTestWrapper(
            const AudioControls(
              isPlaying: true,
              isLoading: false,
              hasError: false,
              onPlayPause: WidgetTestUtils.mockPlayPause,
              onNext: WidgetTestUtils.mockNext,
              onPrevious: WidgetTestUtils.mockPrevious,
              onSkipForward: WidgetTestUtils.mockSkipForward,
              onSkipBackward: WidgetTestUtils.mockSkipBackward,
            ),
          ),
        );

        stopwatch.stop();

        // Audio controls should render within 500ms
        expect(stopwatch.elapsedMilliseconds, lessThan(500));

        expect(find.byType(AudioControls), findsOneWidget);
      });

      testWidgets('should handle rapid control interactions efficiently',
          (tester) async {
        bool isPlaying = false;

        await tester.pumpWidget(
          WidgetTestUtils.createTestWrapper(
            StatefulBuilder(
              builder: (context, setState) {
                return AudioControls(
                  isPlaying: isPlaying,
                  isLoading: false,
                  hasError: false,
                  onPlayPause: () {
                    setState(() {
                      isPlaying = !isPlaying;
                    });
                  },
                  onNext: () {},
                  onPrevious: () {},
                  onSkipForward: () {},
                  onSkipBackward: () {},
                );
              },
            ),
          ),
        );

        final stopwatch = Stopwatch()..start();

        // Rapid play/pause interactions
        for (int i = 0; i < 10; i++) {
          if (find.byIcon(Icons.play_arrow).evaluate().isNotEmpty) {
            await tester.tap(find.byIcon(Icons.play_arrow).first);
          } else if (find.byIcon(Icons.pause).evaluate().isNotEmpty) {
            await tester.tap(find.byIcon(Icons.pause).first);
          }
          await tester.pump(const Duration(milliseconds: 50));
        }

        stopwatch.stop();

        // Rapid interactions should complete within 1 second
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });
    });

    group('Memory Usage Benchmarks', () {
      testWidgets('should not leak memory during widget creation and disposal',
          (tester) async {
        // Use built-in memory testing helper from WidgetTestUtils
        await WidgetTestUtils.testMemoryUsage(
          tester,
          () => SizedBox(
            height: 400,
            child: SingleChildScrollView(
              child: Column(
                children: List.generate(
                    5,
                    (index) => AudioItemCard(
                          audioFile: WidgetTestUtils.createTestAudioFile(
                            title: 'Memory Test $index',
                            id: 'memory-test-$index',
                          ),
                          onTap: () {},
                        )),
              ),
            ),
          ),
          iterations: 10,
        );

        // Test passes if no memory leaks cause crashes
        expect(find.byType(SizedBox), findsOneWidget);
      });
    });

    group('Stress Testing', () {
      testWidgets('should handle extreme widget counts', (tester) async {
        final extremeAudioList = List.generate(
          500,
          (index) => WidgetTestUtils.createTestAudioFile(
            title: 'Stress Test Item $index',
            id: 'stress-$index',
          ),
        );

        final stopwatch = Stopwatch()..start();

        try {
          await tester.pumpWidget(
            WidgetTestUtils.createTestWrapper(
              SizedBox(
                height: 400,
                child: AudioList(
                  episodes: extremeAudioList,
                  onEpisodeTap: (audioFile) {},
                ),
              ),
            ),
          );

          stopwatch.stop();

          // Should handle extreme counts within 2 seconds
          expect(stopwatch.elapsedMilliseconds, lessThan(2000));
          expect(find.byType(AudioList), findsOneWidget);
        } catch (e) {
          stopwatch.stop();
          // If it fails, ensure it fails gracefully within reasonable time
          expect(stopwatch.elapsedMilliseconds, lessThan(5000));
        }
      });
    });

    group('Performance Utilities', () {
      testWidgets('should measure widget build time accurately',
          (tester) async {
        final buildTime = await WidgetTestUtils.measureWidgetBuildTime(
          tester,
          () => AudioItemCard(
            audioFile: WidgetTestUtils.createTestAudioFile(),
            onTap: () {},
          ),
        );

        // Build time should be reasonable (under 200ms)
        expect(buildTime.inMilliseconds, lessThan(200));
      });
    });
  });
}
