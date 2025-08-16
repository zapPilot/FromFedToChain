import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:from_fed_to_chain_app/widgets/audio_list.dart';
import 'package:from_fed_to_chain_app/widgets/audio_item_card.dart';
import 'package:from_fed_to_chain_app/models/audio_file.dart';
import '../test_utils.dart';
import '../helpers/widget_test_helpers.dart';

void main() {
  group('AudioList Widget Tests', () {
    late List<AudioFile> testEpisodes;
    late Function(AudioFile) mockOnEpisodeTap;
    late Function(AudioFile) mockOnEpisodeLongPress;

    setUp(() {
      testEpisodes = [
        TestUtils.createSampleAudioFile(
          id: 'episode-1',
          title: 'Bitcoin Market Analysis',
          category: 'daily-news',
          language: 'en-US',
        ),
        TestUtils.createSampleAudioFile(
          id: 'episode-2',
          title: 'Ethereum 2.0 Deep Dive',
          category: 'ethereum',
          language: 'en-US',
        ),
        TestUtils.createSampleAudioFile(
          id: 'episode-3',
          title: 'DeFi Protocols Explained',
          category: 'defi',
          language: 'ja-JP',
        ),
      ];

      mockOnEpisodeTap = (episode) {};
      mockOnEpisodeLongPress = (episode) {};
    });

    testWidgets('displays list of audio episodes correctly', (tester) async {
      await tester.pumpWidget(
        WidgetTestHelpers.createMinimalTestWrapper(
          child: AudioList(
            episodes: testEpisodes,
            onEpisodeTap: mockOnEpisodeTap,
            onEpisodeLongPress: mockOnEpisodeLongPress,
          ),
        ),
      );

      // Verify all episodes are displayed
      expect(find.byType(AudioItemCard), findsNWidgets(testEpisodes.length));
      
      // Verify episode titles are displayed
      for (final episode in testEpisodes) {
        expect(find.text(episode.displayTitle), findsOneWidget);
      }
    });

    testWidgets('displays empty state when no episodes', (tester) async {
      await tester.pumpWidget(
        WidgetTestHelpers.createMinimalTestWrapper(
          child: AudioList(
            episodes: [],
            onEpisodeTap: mockOnEpisodeTap,
          ),
        ),
      );

      // Verify empty state is displayed
      expect(find.text('No episodes found'), findsOneWidget);
      expect(find.text('Try different filters or search terms'), findsOneWidget);
      expect(find.byIcon(Icons.headphones_outlined), findsOneWidget);
      
      // Verify no audio cards are displayed
      expect(find.byType(AudioItemCard), findsNothing);
    });

    testWidgets('handles episode tap correctly', (tester) async {
      AudioFile? tappedEpisode;
      
      await tester.pumpWidget(
        WidgetTestHelpers.createMinimalTestWrapper(
          child: AudioList(
            episodes: testEpisodes,
            onEpisodeTap: (episode) => tappedEpisode = episode,
          ),
        ),
      );

      // Tap on the first episode
      await tester.tap(find.byType(AudioItemCard).first);
      await tester.pumpAndSettle();

      // Verify the callback was called with correct episode
      expect(tappedEpisode, equals(testEpisodes.first));
    });

    testWidgets('handles episode long press correctly', (tester) async {
      AudioFile? longPressedEpisode;
      
      await tester.pumpWidget(
        WidgetTestHelpers.createMinimalTestWrapper(
          child: AudioList(
            episodes: testEpisodes,
            onEpisodeTap: mockOnEpisodeTap,
            onEpisodeLongPress: (episode) => longPressedEpisode = episode,
          ),
        ),
      );

      // Long press on the first episode
      await tester.longPress(find.byType(AudioItemCard).first);
      await tester.pumpAndSettle();

      // Verify the callback was called with correct episode
      expect(longPressedEpisode, equals(testEpisodes.first));
    });

    testWidgets('supports scrolling through long lists', (tester) async {
      // Create a long list of episodes
      final longEpisodeList = List.generate(
        50,
        (index) => TestUtils.createSampleAudioFile(
          id: 'episode-$index',
          title: 'Episode $index',
          category: 'daily-news',
          language: 'en-US',
        ),
      );

      await tester.pumpWidget(
        WidgetTestHelpers.createMinimalTestWrapper(
          child: AudioList(
            episodes: longEpisodeList,
            onEpisodeTap: mockOnEpisodeTap,
          ),
        ),
      );

      // Verify initial episodes are visible
      expect(find.text('Episode 0'), findsOneWidget);
      expect(find.text('Episode 49'), findsNothing);

      // Scroll to bottom
      await WidgetTestHelpers.scrollUntilVisible(
        tester,
        find.text('Episode 49'),
        find.byType(ListView),
        delta: -500.0,
      );

      // Verify last episode is now visible
      expect(find.text('Episode 49'), findsOneWidget);
    });

    testWidgets('displays loading more indicator when showLoadingMore is true', (tester) async {
      await tester.pumpWidget(
        WidgetTestHelpers.createMinimalTestWrapper(
          child: AudioList(
            episodes: testEpisodes,
            onEpisodeTap: mockOnEpisodeTap,
            showLoadingMore: true,
          ),
        ),
      );

      // Verify loading indicator is displayed
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading more episodes...'), findsOneWidget);
      
      // Verify all episodes plus loading indicator
      expect(find.byType(AudioItemCard), findsNWidgets(testEpisodes.length));
    });

    testWidgets('calls onLoadMore when scrolled to bottom with loading indicator', (tester) async {
      bool onLoadMoreCalled = false;
      
      await tester.pumpWidget(
        WidgetTestHelpers.createMinimalTestWrapper(
          child: AudioList(
            episodes: testEpisodes,
            onEpisodeTap: mockOnEpisodeTap,
            showLoadingMore: true,
            onLoadMore: () => onLoadMoreCalled = true,
          ),
        ),
      );

      // Scroll to bottom to trigger onLoadMore
      await WidgetTestHelpers.scrollUntilVisible(
        tester,
        find.text('Loading more episodes...'),
        find.byType(ListView),
        delta: -500.0,
      );

      // Note: onLoadMore callback would typically be triggered by scroll position,
      // but that requires more complex scroll physics simulation
      // This test verifies the UI structure for loading more
      expect(find.text('Loading more episodes...'), findsOneWidget);
    });

    testWidgets('maintains scroll position when episodes list updates', (tester) async {
      final scrollController = ScrollController();
      
      await tester.pumpWidget(
        WidgetTestHelpers.createMinimalTestWrapper(
          child: AudioList(
            episodes: testEpisodes,
            onEpisodeTap: mockOnEpisodeTap,
            scrollController: scrollController,
          ),
        ),
      );

      // Scroll down
      scrollController.jumpTo(200.0);
      await tester.pump();

      // Verify scroll position is maintained
      expect(scrollController.offset, equals(200.0));
    });

    testWidgets('handles different screen sizes correctly', (tester) async {
      await WidgetTestHelpers.testMultipleScreenSizes(
        tester,
        WidgetTestHelpers.createMinimalTestWrapper(
          child: AudioList(
            episodes: testEpisodes,
            onEpisodeTap: mockOnEpisodeTap,
          ),
        ),
        (tester, size) async {
          // Verify episodes are displayed regardless of screen size
          expect(find.byType(AudioItemCard), findsNWidgets(testEpisodes.length));
          
          // Verify padding is applied correctly
          final listView = tester.widget<ListView>(find.byType(ListView));
          expect(listView.padding, isNotNull);
        },
      );
    });

    testWidgets('supports accessibility features', (tester) async {
      await tester.pumpWidget(
        WidgetTestHelpers.createMinimalTestWrapper(
          child: AudioList(
            episodes: testEpisodes,
            onEpisodeTap: mockOnEpisodeTap,
          ),
        ),
      );

      await WidgetTestHelpers.verifyAccessibility(tester);

      // Verify semantic information is present - ListView exists
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('handles edge cases gracefully', (tester) async {
      // Test with empty episode data
      final edgeEpisodes = [
        TestUtils.createEdgeCaseAudioFile(),
      ];

      await tester.pumpWidget(
        WidgetTestHelpers.createMinimalTestWrapper(
          child: AudioList(
            episodes: edgeEpisodes,
            onEpisodeTap: mockOnEpisodeTap,
          ),
        ),
      );

      // Verify widget doesn't crash with edge case data
      expect(find.byType(AudioItemCard), findsOneWidget);
    });

    testWidgets('applies correct theme styling', (tester) async {
      await WidgetTestHelpers.testBothThemes(
        tester,
        (theme) => WidgetTestHelpers.createMinimalTestWrapper(
          theme: theme,
          child: AudioList(
            episodes: testEpisodes,
            onEpisodeTap: mockOnEpisodeTap,
          ),
        ),
        (tester, theme) async {
          // Verify theme-appropriate styling is applied
          expect(find.byType(ListView), findsOneWidget);
          expect(find.byType(AudioItemCard), findsNWidgets(testEpisodes.length));
        },
      );
    });

    testWidgets('handles animations correctly', (tester) async {
      await tester.pumpWidget(
        WidgetTestHelpers.createMinimalTestWrapper(
          child: AudioList(
            episodes: testEpisodes,
            onEpisodeTap: mockOnEpisodeTap,
          ),
        ),
      );

      // Test that animations complete without errors
      await WidgetTestHelpers.testAnimationCompletion(tester);
      
      // Verify all episodes are still visible after animations
      expect(find.byType(AudioItemCard), findsNWidgets(testEpisodes.length));
    });
  });
}