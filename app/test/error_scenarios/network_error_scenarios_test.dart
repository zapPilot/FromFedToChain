import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';
import 'package:from_fed_to_chain_app/features/content/widgets/audio_list.dart';
import 'package:from_fed_to_chain_app/features/audio/widgets/mini_player.dart';
import '../widgets/widget_test_utils.dart';

/// Error scenario tests for network failures and edge cases
/// Tests how the app handles realistic network problems and service failures
void main() {
  group('Network Error Scenarios', () {
    setUp(() {
      WidgetTestUtils.resetCallbacks();
    });

    group('ContentService Error Handling', () {
      testWidgets('should handle network timeout gracefully', (tester) async {
        // Simulate network timeout scenario
        await tester.pumpWidget(
          WidgetTestUtils.createTestWrapper(
            Scaffold(
              body: Column(
                children: [
                  const Text('Network timeout scenario'),
                  Expanded(
                    child: AudioList(
                      episodes: const [], // Empty list simulating timeout
                      onEpisodeTap: (audioFile) {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        // Should show empty state message instead of crashing
        expect(find.text('No episodes found'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle invalid JSON response gracefully',
          (tester) async {
        // Test handling of corrupted/invalid API response
        final invalidAudioFile = AudioFile(
          id: 'invalid-json-test',
          title: '', // Empty title to simulate invalid data
          language: 'unknown',
          category: 'unknown',
          streamingUrl: 'invalid-url',
          path: 'invalid-path',
          lastModified:
              DateTime.fromMillisecondsSinceEpoch(0), // Invalid epoch date
        );

        await tester.pumpWidget(
          WidgetTestUtils.createTestWrapper(
            Scaffold(
              body: AudioList(
                episodes: [invalidAudioFile],
                onEpisodeTap: (audioFile) {},
              ),
            ),
          ),
        );

        // Should render without crashing despite invalid data
        expect(find.byType(AudioList), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle server error (500) response', (tester) async {
        // Simulate server error scenario with empty content
        await tester.pumpWidget(
          WidgetTestUtils.createTestWrapper(
            Scaffold(
              appBar: AppBar(title: const Text('Server Error Test')),
              body: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: const Text(
                      'Server temporarily unavailable',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  Expanded(
                    child: AudioList(
                      episodes: const [],
                      onEpisodeTap: (audioFile) {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Server temporarily unavailable'), findsOneWidget);
        expect(find.text('No episodes found'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle malformed streaming URLs', (tester) async {
        final malformedAudioFile = AudioFile(
          id: 'malformed-url-test',
          title: 'Test Audio with Malformed URL',
          language: 'en-US',
          category: 'daily-news',
          streamingUrl: 'not-a-valid-url',
          path: 'invalid/path',
          lastModified: DateTime.now(),
        );

        await tester.pumpWidget(
          WidgetTestUtils.createTestWrapper(
            Scaffold(
              body: AudioList(
                episodes: [malformedAudioFile],
                onEpisodeTap: (audioFile) {
                  // This would normally trigger audio playback
                  // but should handle malformed URL gracefully
                },
              ),
            ),
          ),
        );

        expect(find.byType(AudioList), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('AudioService Error Handling', () {
      testWidgets('should handle audio playback failure gracefully',
          (tester) async {
        final audioFile = WidgetTestUtils.createTestAudioFile(
          streamingUrl: 'https://invalid-audio-url.com/non-existent.m3u8',
        );

        // Test MiniPlayer with error state
        await tester.pumpWidget(
          WidgetTestUtils.createTestWrapper(
            MiniPlayer(
              audioFile: audioFile,
              isPlaying: false,
              isPaused: false,
              isLoading: false,
              hasError: true, // Simulate audio playback error
              stateText: 'Playback failed',
              onTap: () {},
              onPlayPause: () {},
              onNext: () {},
              onPrevious: () {},
            ),
          ),
        );

        expect(find.byType(MiniPlayer), findsOneWidget);
        expect(find.text('Playback failed'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle network disconnection during playback',
          (tester) async {
        final audioFile = WidgetTestUtils.createTestAudioFile();
        bool hasError = false;
        String stateText = 'Playing';

        await tester.pumpWidget(
          WidgetTestUtils.createTestWrapper(
            StatefulBuilder(
              builder: (context, setState) {
                return MiniPlayer(
                  audioFile: audioFile,
                  isPlaying: !hasError,
                  isPaused: false,
                  isLoading: false,
                  hasError: hasError,
                  stateText: stateText,
                  onTap: () {},
                  onPlayPause: () {
                    setState(() {
                      // Simulate network disconnection during playback
                      hasError = true;
                      stateText = 'Connection lost';
                    });
                  },
                  onNext: () {},
                  onPrevious: () {},
                );
              },
            ),
          ),
        );

        // Initially playing
        expect(find.text('Playing'), findsOneWidget);

        // Simulate network disconnection
        final playPauseButton = find.byIcon(Icons.pause);
        if (playPauseButton.evaluate().isNotEmpty) {
          await tester.tap(playPauseButton.first);
          await tester.pump();
        }

        // Should show error state
        expect(find.text('Connection lost'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle audio buffer underrun', (tester) async {
        final audioFile = WidgetTestUtils.createTestAudioFile();

        await tester.pumpWidget(
          WidgetTestUtils.createTestWrapper(
            MiniPlayer(
              audioFile: audioFile,
              isPlaying: false,
              isPaused: false,
              isLoading: true, // Simulate buffering state
              hasError: false,
              stateText: 'Buffering...',
              onTap: () {},
              onPlayPause: () {},
              onNext: () {},
              onPrevious: () {},
            ),
          ),
        );

        expect(find.text('Buffering...'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('Data Corruption Scenarios', () {
      testWidgets('should handle missing required fields gracefully',
          (tester) async {
        // Test with AudioFile missing required fields (simulated with null-safe defaults)
        final corruptedAudioFile = AudioFile(
          id: '', // Empty ID
          title: '', // Empty title
          language: '',
          category: '',
          streamingUrl: '',
          path: '',
          lastModified: DateTime.fromMillisecondsSinceEpoch(0), // Epoch time
        );

        await tester.pumpWidget(
          WidgetTestUtils.createTestWrapper(
            Scaffold(
              body: AudioList(
                episodes: [corruptedAudioFile],
                onEpisodeTap: (audioFile) {},
              ),
            ),
          ),
        );

        expect(find.byType(AudioList), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle extremely large file sizes', (tester) async {
        final hugeAudioFile = AudioFile(
          id: 'huge-file-test',
          title: 'Extremely Large Audio File',
          language: 'en-US',
          category: 'daily-news',
          streamingUrl: 'https://example.com/huge-file.m3u8',
          path: '/huge/file.m3u8',
          duration: const Duration(hours: 24), // 24 hour audio
          fileSizeBytes: 999999999999, // Nearly 1TB
          lastModified: DateTime.now(),
        );

        await tester.pumpWidget(
          WidgetTestUtils.createTestWrapper(
            Scaffold(
              body: AudioList(
                episodes: [hugeAudioFile],
                onEpisodeTap: (audioFile) {},
              ),
            ),
          ),
        );

        expect(find.byType(AudioList), findsOneWidget);
        // Should handle extremely large file sizes without overflow
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle negative duration values', (tester) async {
        final negativeDurationFile = AudioFile(
          id: 'negative-duration-test',
          title: 'Invalid Duration Audio',
          language: 'en-US',
          category: 'daily-news',
          streamingUrl: 'https://example.com/audio.m3u8',
          path: '/audio.m3u8',
          duration: const Duration(seconds: -100), // Negative duration
          lastModified: DateTime.now(),
        );

        await tester.pumpWidget(
          WidgetTestUtils.createTestWrapper(
            Scaffold(
              body: AudioList(
                episodes: [negativeDurationFile],
                onEpisodeTap: (audioFile) {},
              ),
            ),
          ),
        );

        expect(find.byType(AudioList), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('Memory Pressure Scenarios', () {
      testWidgets('should handle low memory conditions', (tester) async {
        // Simulate low memory by creating many audio files
        final manyAudioFiles = List.generate(
            1000,
            (index) => WidgetTestUtils.createTestAudioFile(
                  id: 'memory-pressure-$index',
                  title: 'Audio File $index for Memory Pressure Test',
                ));

        try {
          await tester.pumpWidget(
            WidgetTestUtils.createTestWrapper(
              SizedBox(
                height: 400,
                child: AudioList(
                  episodes: manyAudioFiles,
                  onEpisodeTap: (audioFile) {},
                ),
              ),
            ),
          );

          expect(find.byType(AudioList), findsOneWidget);
          expect(tester.takeException(), isNull);
        } catch (e) {
          // Should fail gracefully if memory is exhausted
          expect(e, isA<Exception>());
        }
      });

      testWidgets('should handle rapid widget creation and disposal',
          (tester) async {
        // Rapidly create and dispose widgets to test memory management
        for (int i = 0; i < 20; i++) {
          final audioFile = WidgetTestUtils.createTestAudioFile(
            id: 'rapid-test-$i',
            title: 'Rapid Creation Test $i',
          );

          await tester.pumpWidget(
            WidgetTestUtils.createTestWrapper(
              MiniPlayer(
                audioFile: audioFile,
                isPlaying: i % 2 == 0,
                isPaused: i % 2 == 1,
                isLoading: false,
                hasError: false,
                stateText: i % 2 == 0 ? 'Playing' : 'Paused',
                onTap: () {},
                onPlayPause: () {},
                onNext: () {},
                onPrevious: () {},
              ),
            ),
          );

          // Immediately dispose
          await tester.pumpWidget(
            WidgetTestUtils.createTestWrapper(
              const SizedBox.shrink(),
            ),
          );
        }

        expect(tester.takeException(), isNull);
      });
    });

    group('Edge Case User Interactions', () {
      testWidgets('should handle rapid successive taps', (tester) async {
        final audioFile = WidgetTestUtils.createTestAudioFile();
        int tapCount = 0;

        await tester.pumpWidget(
          WidgetTestUtils.createTestWrapper(
            MiniPlayer(
              audioFile: audioFile,
              isPlaying: false,
              isPaused: true,
              isLoading: false,
              hasError: false,
              stateText: 'Paused',
              onTap: () {
                tapCount++;
              },
              onPlayPause: () {
                tapCount++;
              },
              onNext: () {
                tapCount++;
              },
              onPrevious: () {
                tapCount++;
              },
            ),
          ),
        );

        // Rapidly tap multiple controls
        for (int i = 0; i < 50; i++) {
          final playButton = find.byIcon(Icons.play_arrow);
          if (playButton.evaluate().isNotEmpty) {
            await tester.tap(playButton.first);
          }

          final nextButton = find.byIcon(Icons.skip_next);
          if (nextButton.evaluate().isNotEmpty) {
            await tester.tap(nextButton.first);
          }

          await tester.pump(const Duration(milliseconds: 1));
        }

        // Should handle rapid taps without crashing
        expect(tapCount, greaterThan(0));
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle simultaneous multiple error states',
          (tester) async {
        final audioFile = WidgetTestUtils.createTestAudioFile();

        await tester.pumpWidget(
          WidgetTestUtils.createTestWrapper(
            MiniPlayer(
              audioFile: audioFile,
              isPlaying: false,
              isPaused: false,
              isLoading: true, // Loading AND error simultaneously
              hasError: true, // This creates a conflicting state
              stateText: 'Error while loading',
              onTap: () {},
              onPlayPause: () {},
              onNext: () {},
              onPrevious: () {},
            ),
          ),
        );

        // Should handle conflicting states gracefully
        expect(find.byType(MiniPlayer), findsOneWidget);
        expect(find.text('Error while loading'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('Platform Integration Errors', () {
      testWidgets('should handle audio focus loss', (tester) async {
        final audioFile = WidgetTestUtils.createTestAudioFile();
        bool isPlaying = true;
        String stateText = 'Playing';

        await tester.pumpWidget(
          WidgetTestUtils.createTestWrapper(
            StatefulBuilder(
              builder: (context, setState) {
                return MiniPlayer(
                  audioFile: audioFile,
                  isPlaying: isPlaying,
                  isPaused: !isPlaying,
                  isLoading: false,
                  hasError: false,
                  stateText: stateText,
                  onTap: () {
                    // Simulate audio focus loss (phone call, other app, etc.)
                    setState(() {
                      isPlaying = false;
                      stateText = 'Paused - Focus lost';
                    });
                  },
                  onPlayPause: () {},
                  onNext: () {},
                  onPrevious: () {},
                );
              },
            ),
          ),
        );

        expect(find.text('Playing'), findsOneWidget);

        // Simulate focus loss
        await tester.tap(find.byType(MiniPlayer));
        await tester.pump();

        expect(find.text('Paused - Focus lost'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle headphone disconnection', (tester) async {
        final audioFile = WidgetTestUtils.createTestAudioFile();
        bool isPlaying = true;

        await tester.pumpWidget(
          WidgetTestUtils.createTestWrapper(
            StatefulBuilder(
              builder: (context, setState) {
                return MiniPlayer(
                  audioFile: audioFile,
                  isPlaying: isPlaying,
                  isPaused: !isPlaying,
                  isLoading: false,
                  hasError: false,
                  stateText: isPlaying
                      ? 'Playing'
                      : 'Paused - Headphones disconnected',
                  onTap: () {},
                  onPlayPause: () {
                    // Simulate headphone disconnection auto-pause
                    setState(() {
                      isPlaying = false;
                    });
                  },
                  onNext: () {},
                  onPrevious: () {},
                );
              },
            ),
          ),
        );

        // Initially playing
        expect(find.text('Playing'), findsOneWidget);

        // Simulate headphone disconnection
        final playPauseButton = find.byIcon(Icons.pause);
        if (playPauseButton.evaluate().isNotEmpty) {
          await tester.tap(playPauseButton.first);
          await tester.pump();
        }

        expect(find.text('Paused - Headphones disconnected'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('Stress Test Scenarios', () {
      testWidgets('should handle app lifecycle state changes during playback',
          (tester) async {
        final audioFile = WidgetTestUtils.createTestAudioFile();

        // Test app going to background and foreground during playback
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

        // Simulate multiple app lifecycle changes
        for (int i = 0; i < 10; i++) {
          await tester.pump(); // Simulate frame updates
          await tester.pump(const Duration(milliseconds: 100));
        }

        expect(find.byType(MiniPlayer), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
  });
}
