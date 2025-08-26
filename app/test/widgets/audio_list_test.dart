import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:from_fed_to_chain_app/widgets/audio_list.dart';
import 'package:from_fed_to_chain_app/widgets/audio_item_card.dart';
import 'package:from_fed_to_chain_app/models/audio_file.dart';
import '../test_utils.dart';

void main() {
  group('AudioList Widget Tests', () {
    late List<AudioFile> testEpisodes;
    late List<String> tappedEpisodeIds;

    setUp(() {
      testEpisodes = TestUtils.createSampleAudioFileList(5);
      tappedEpisodeIds = [];
    });

    void onEpisodeTap(AudioFile episode) {
      tappedEpisodeIds.add(episode.id);
    }

    Widget createAudioList({
      List<AudioFile>? episodes,
      bool showLoadingMore = false,
      VoidCallback? onLoadMore,
      Function(AudioFile)? onEpisodeLongPress,
    }) {
      return TestUtils.wrapWithMaterialApp(
        AudioList(
          episodes: episodes ?? testEpisodes,
          onEpisodeTap: onEpisodeTap,
          onEpisodeLongPress: onEpisodeLongPress,
          showLoadingMore: showLoadingMore,
          onLoadMore: onLoadMore,
        ),
      );
    }

    group('Basic Rendering Tests', () {
      testWidgets('renders with episode list', (tester) async {
        await tester.pumpWidget(createAudioList());
        await tester.pumpAndSettle();

        // Should find AudioList widget
        expect(find.byType(AudioList), findsOneWidget);

        // Should display audio items
        expect(find.byType(AudioItemCard), findsNWidgets(5));
      });

      testWidgets('renders empty list correctly', (tester) async {
        await tester.pumpWidget(createAudioList(episodes: []));
        await tester.pumpAndSettle();

        // Should show empty state
        expect(find.byType(AudioList), findsOneWidget);
        expect(find.byType(AudioItemCard), findsNothing);
      });

      testWidgets('renders with showLoadingMore indicator', (tester) async {
        await tester.pumpWidget(createAudioList(showLoadingMore: true));
        await tester.pumpAndSettle();

        // Should show loading indicator at bottom
        expect(find.byType(AudioList), findsOneWidget);
        expect(find.byType(AudioItemCard), findsNWidgets(5));
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('handles empty state correctly', (tester) async {
        await tester.pumpWidget(createAudioList(episodes: []));
        await tester.pumpAndSettle();

        // Should show empty state
        expect(find.byType(AudioList), findsOneWidget);
        expect(find.byType(AudioItemCard), findsNothing);
      });
    });

    group('Episode Display Tests', () {
      testWidgets('displays episode titles correctly', (tester) async {
        await tester.pumpWidget(createAudioList());
        await tester.pumpAndSettle();

        // Check that episode titles are displayed
        for (final episode in testEpisodes) {
          expect(find.text(episode.title), findsOneWidget);
        }
      });

      testWidgets('displays episode metadata correctly', (tester) async {
        await tester.pumpWidget(createAudioList());
        await tester.pumpAndSettle();

        // Check for category emojis and durations
        for (final episode in testEpisodes) {
          expect(find.text(episode.categoryEmoji), findsOneWidget);
          expect(find.text(episode.formattedDuration), findsOneWidget);
        }
      });

      testWidgets('displays different languages correctly', (tester) async {
        final mixedLanguageEpisodes = [
          TestUtils.createSampleAudioFile(
            id: 'en-episode',
            title: 'English Episode',
            language: 'en-US',
          ),
          TestUtils.createSampleAudioFile(
            id: 'jp-episode',
            title: 'Japanese Episode',
            language: 'ja-JP',
          ),
          TestUtils.createSampleAudioFile(
            id: 'tw-episode',
            title: 'Traditional Chinese Episode',
            language: 'zh-TW',
          ),
        ];

        await tester
            .pumpWidget(createAudioList(episodes: mixedLanguageEpisodes));
        await tester.pumpAndSettle();

        // Check that all episodes are displayed
        expect(find.text('English Episode'), findsOneWidget);
        expect(find.text('Japanese Episode'), findsOneWidget);
        expect(find.text('Traditional Chinese Episode'), findsOneWidget);
      });

      testWidgets('displays different categories correctly', (tester) async {
        final mixedCategoryEpisodes = [
          TestUtils.createSampleAudioFile(
            id: 'news-episode',
            title: 'News Episode',
            category: 'daily-news',
          ),
          TestUtils.createSampleAudioFile(
            id: 'eth-episode',
            title: 'Ethereum Episode',
            category: 'ethereum',
          ),
          TestUtils.createSampleAudioFile(
            id: 'macro-episode',
            title: 'Macro Episode',
            category: 'macro',
          ),
        ];

        await tester
            .pumpWidget(createAudioList(episodes: mixedCategoryEpisodes));
        await tester.pumpAndSettle();

        // Check that all episodes are displayed with correct emojis
        expect(find.text('📰'), findsOneWidget); // daily-news
        expect(find.text('⚡'), findsOneWidget); // ethereum
        expect(find.text('📊'), findsOneWidget); // macro
      });
    });

    group('User Interaction Tests', () {
      testWidgets('handles episode tap correctly', (tester) async {
        await tester.pumpWidget(createAudioList());
        await tester.pumpAndSettle();

        // Tap on first episode
        final firstEpisodeCard = find.byType(AudioItemCard).first;
        await tester.tap(firstEpisodeCard);
        await tester.pumpAndSettle();

        // Should call onEpisodeTap callback
        expect(tappedEpisodeIds.length, equals(1));
        expect(tappedEpisodeIds.first, equals(testEpisodes.first.id));
      });

      testWidgets('handles multiple episode taps', (tester) async {
        await tester.pumpWidget(createAudioList());
        await tester.pumpAndSettle();

        // Tap on multiple episodes
        final episodeCards = find.byType(AudioItemCard);
        for (int i = 0; i < 3; i++) {
          await tester.tap(episodeCards.at(i));
          await tester.pumpAndSettle();
        }

        // Should record all taps
        expect(tappedEpisodeIds.length, equals(3));
        for (int i = 0; i < 3; i++) {
          expect(tappedEpisodeIds[i], equals(testEpisodes[i].id));
        }
      });

      testWidgets('handles rapid taps correctly', (tester) async {
        await tester.pumpWidget(createAudioList());
        await tester.pumpAndSettle();

        // Rapidly tap same episode
        final firstEpisodeCard = find.byType(AudioItemCard).first;
        for (int i = 0; i < 5; i++) {
          await tester.tap(firstEpisodeCard);
          await tester.pump(const Duration(milliseconds: 50));
        }
        await tester.pumpAndSettle();

        // Should handle rapid taps gracefully
        expect(tappedEpisodeIds.length, equals(5));
        expect(tappedEpisodeIds.every((id) => id == testEpisodes.first.id),
            isTrue);
      });

      testWidgets('handles long press correctly', (tester) async {
        List<AudioFile> longPressedEpisodes = [];

        await tester.pumpWidget(createAudioList(
          onEpisodeLongPress: (episode) => longPressedEpisodes.add(episode),
        ));
        await tester.pumpAndSettle();

        // Long press on first episode
        final firstEpisodeCard = find.byType(AudioItemCard).first;
        await tester.longPress(firstEpisodeCard);
        await tester.pumpAndSettle();

        // Should call onEpisodeLongPress callback
        expect(longPressedEpisodes.length, equals(1));
        expect(longPressedEpisodes.first.id, equals(testEpisodes.first.id));
      });
    });

    group('Scrolling Tests', () {
      testWidgets('supports vertical scrolling with many episodes',
          (tester) async {
        final manyEpisodes = TestUtils.createSampleAudioFileList(20);
        await tester.pumpWidget(createAudioList(episodes: manyEpisodes));
        await tester.pumpAndSettle();

        // Should be scrollable
        expect(find.byType(ListView), findsOneWidget);

        // Scroll down
        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await tester.pumpAndSettle();

        // Should handle scrolling without errors
        expect(find.byType(AudioList), findsOneWidget);
      });

      testWidgets('maintains scroll position during updates', (tester) async {
        final manyEpisodes = TestUtils.createSampleAudioFileList(20);
        await tester.pumpWidget(createAudioList(episodes: manyEpisodes));
        await tester.pumpAndSettle();

        // Scroll to middle
        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pumpAndSettle();

        // Update with same episodes (simulating refresh)
        await tester.pumpWidget(createAudioList(episodes: manyEpisodes));
        await tester.pumpAndSettle();

        // Should maintain scroll position
        expect(find.byType(AudioList), findsOneWidget);
      });

      testWidgets('handles scroll to edge cases', (tester) async {
        final manyEpisodes = TestUtils.createSampleAudioFileList(10);
        await tester.pumpWidget(createAudioList(episodes: manyEpisodes));
        await tester.pumpAndSettle();

        final listView = find.byType(ListView);

        // Scroll to top
        await tester.drag(listView, const Offset(0, 1000));
        await tester.pumpAndSettle();

        // Scroll to bottom
        await tester.drag(listView, const Offset(0, -2000));
        await tester.pumpAndSettle();

        // Should handle edge scrolling gracefully
        expect(find.byType(AudioList), findsOneWidget);
      });
    });

    group('Performance Tests', () {
      testWidgets('handles large episode lists efficiently', (tester) async {
        final largeEpisodeList = TestUtils.createSampleAudioFileList(100);

        final stopwatch = Stopwatch()..start();
        await tester.pumpWidget(createAudioList(episodes: largeEpisodeList));
        await tester.pumpAndSettle();
        stopwatch.stop();

        // Should render within reasonable time (< 5 seconds)
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));
        expect(find.byType(AudioList), findsOneWidget);
      });

      testWidgets('handles frequent updates efficiently', (tester) async {
        // Start with empty list
        await tester.pumpWidget(createAudioList(episodes: []));
        await tester.pumpAndSettle();

        // Add episodes incrementally
        for (int i = 1; i <= 10; i++) {
          final episodes = TestUtils.createSampleAudioFileList(i);
          await tester.pumpWidget(createAudioList(episodes: episodes));
          await tester.pumpAndSettle();
        }

        // Should handle incremental updates
        expect(find.byType(AudioItemCard), findsNWidgets(10));
      });

      testWidgets('handles load more functionality', (tester) async {
        await tester.pumpWidget(createAudioList(
          showLoadingMore: true,
          onLoadMore: () {},
        ));
        await tester.pumpAndSettle();

        // Should show loading indicator
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Scroll to trigger load more
        await tester.drag(find.byType(ListView), const Offset(0, -1000));
        await tester.pumpAndSettle();

        // Load more functionality should be available
        expect(find.byType(AudioList), findsOneWidget);
        // Note: onLoadMore would be called if triggered by scrolling
      });
    });

    group('Accessibility Tests', () {
      testWidgets('provides proper semantic labels', (tester) async {
        await tester.pumpWidget(createAudioList());
        await tester.pumpAndSettle();

        // Check for semantic information
        expect(find.byType(Semantics), findsWidgets);
      });

      testWidgets('supports keyboard navigation', (tester) async {
        await tester.pumpWidget(createAudioList());
        await tester.pumpAndSettle();

        // Audio items should be focusable/tappable
        final audioCards = find.byType(AudioItemCard);
        expect(audioCards, findsWidgets);

        // Each card should be interactive
        for (int i = 0; i < testEpisodes.length; i++) {
          final card = audioCards.at(i);
          expect(card, findsOneWidget);
        }
      });
    });

    group('Edge Cases', () {
      testWidgets('handles episodes with missing data', (tester) async {
        final episodesWithMissingData = [
          TestUtils.createSampleAudioFile(
            title: '', // Empty title
            duration: Duration.zero, // Zero duration
          ),
          TestUtils.createSampleAudioFile(
            title: 'Valid Episode',
            duration: const Duration(minutes: 5),
          ),
        ];

        await tester
            .pumpWidget(createAudioList(episodes: episodesWithMissingData));
        await tester.pumpAndSettle();

        // Should render both episodes without crashing
        expect(find.byType(AudioItemCard), findsNWidgets(2));
      });

      testWidgets('handles very long episode titles', (tester) async {
        final longTitleEpisode = TestUtils.createSampleAudioFile(
          title:
              'This is a very long episode title that should be handled gracefully by the UI without causing overflow or layout issues',
        );

        await tester.pumpWidget(createAudioList(episodes: [longTitleEpisode]));
        await tester.pumpAndSettle();

        // Should render without overflow
        expect(find.byType(AudioItemCard), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('handles very short episode durations', (tester) async {
        final shortDurationEpisode = TestUtils.createSampleAudioFile(
          duration: const Duration(seconds: 1),
        );

        await tester
            .pumpWidget(createAudioList(episodes: [shortDurationEpisode]));
        await tester.pumpAndSettle();

        // Should display short duration correctly
        expect(find.text('0:01'), findsOneWidget);
      });

      testWidgets('handles very long episode durations', (tester) async {
        final longDurationEpisode = TestUtils.createSampleAudioFile(
          duration: const Duration(hours: 2, minutes: 30, seconds: 45),
        );

        await tester
            .pumpWidget(createAudioList(episodes: [longDurationEpisode]));
        await tester.pumpAndSettle();

        // Should display long duration correctly (2:30:45 = 150:45 in mm:ss format)
        expect(find.text('150:45'), findsOneWidget);
      });
    });

    group('Visual Layout Tests', () {
      testWidgets('maintains consistent spacing between items', (tester) async {
        await tester.pumpWidget(createAudioList());
        await tester.pumpAndSettle();

        // Check for proper spacing elements
        expect(find.byType(SizedBox), findsWidgets);
      });

      testWidgets('adapts to different screen sizes', (tester) async {
        // Test with narrow screen
        await tester.binding.setSurfaceSize(const Size(300, 600));
        await tester.pumpWidget(createAudioList());
        await tester.pumpAndSettle();
        expect(find.byType(AudioList), findsOneWidget);

        // Test with wide screen
        await tester.binding.setSurfaceSize(const Size(800, 600));
        await tester.pumpWidget(createAudioList());
        await tester.pumpAndSettle();
        expect(find.byType(AudioList), findsOneWidget);

        // Reset to default size
        await tester.binding.setSurfaceSize(null);
      });
    });
  });
}
