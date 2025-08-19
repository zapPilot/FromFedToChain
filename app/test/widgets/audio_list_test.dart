import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:from_fed_to_chain_app/widgets/audio_list.dart';
import 'package:from_fed_to_chain_app/widgets/audio_item_card.dart';
import 'package:from_fed_to_chain_app/models/audio_file.dart';
import 'package:from_fed_to_chain_app/themes/app_theme.dart';
import '../test_utils.dart';

void main() {
  group('AudioList Widget Tests', () {
    late List<AudioFile> sampleEpisodes;
    AudioFile? tappedEpisode;
    AudioFile? longPressedEpisode;
    bool loadMoreCalled = false;

    void onEpisodeTap(AudioFile episode) {
      tappedEpisode = episode;
    }

    void onEpisodeLongPress(AudioFile episode) {
      longPressedEpisode = episode;
    }

    void onLoadMore() {
      loadMoreCalled = true;
    }

    setUp(() {
      sampleEpisodes = TestUtils.createSampleAudioFileList(5);
      tappedEpisode = null;
      longPressedEpisode = null;
      loadMoreCalled = false;
    });

    Widget createAudioList({
      List<AudioFile>? episodes,
      Function(AudioFile)? onEpisodeTapCallback,
      Function(AudioFile)? onEpisodeLongPressCallback,
      ScrollController? scrollController,
      bool showLoadingMore = false,
      VoidCallback? onLoadMoreCallback,
    }) {
      return AudioList(
        episodes: episodes ?? sampleEpisodes,
        onEpisodeTap: onEpisodeTapCallback ?? onEpisodeTap,
        onEpisodeLongPress: onEpisodeLongPressCallback ?? onEpisodeLongPress,
        scrollController: scrollController,
        showLoadingMore: showLoadingMore,
        onLoadMore: onLoadMoreCallback ?? onLoadMore,
      );
    }

    testWidgets('should render with basic structure when episodes exist',
        (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createAudioList());

      // Verify main structure
      TestUtils.expectWidgetExists(find.byType(AudioList));
      TestUtils.expectWidgetExists(find.byType(ListView));

      // Should not show empty state
      TestUtils.expectWidgetNotExists(find.text('No episodes found'));
    });

    testWidgets('should display all episodes correctly', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createAudioList());

      // Verify all episodes are displayed as AudioItemCard widgets
      expect(find.byType(AudioItemCard), findsNWidgets(sampleEpisodes.length));

      // Verify episode titles are displayed
      for (final episode in sampleEpisodes) {
        TestUtils.expectTextExists(episode.title);
      }
    });

    testWidgets('should show empty state when no episodes', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioList(episodes: []));

      // Verify empty state is displayed
      TestUtils.expectTextExists('No episodes found');
      TestUtils.expectTextExists('Try different filters or search terms');
      TestUtils.expectIconExists(Icons.headphones_outlined);

      // Should not show ListView
      TestUtils.expectWidgetNotExists(find.byType(ListView));
    });

    testWidgets('should handle episode tap correctly', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createAudioList());

      // Tap the first episode
      await TestUtils.tapWidget(tester, find.byType(AudioItemCard).first);

      expect(tappedEpisode, equals(sampleEpisodes.first));
    });

    testWidgets('should handle episode long press correctly', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createAudioList());

      // Long press the first episode
      await TestUtils.longPressWidget(tester, find.byType(AudioItemCard).first);

      expect(longPressedEpisode, equals(sampleEpisodes.first));
    });

    testWidgets('should handle null long press callback gracefully',
        (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioList(onEpisodeLongPressCallback: null));

      // Should render without issues
      TestUtils.expectWidgetExists(find.byType(AudioList));
      expect(find.byType(AudioItemCard), findsNWidgets(sampleEpisodes.length));
    });

    testWidgets('should show loading more indicator when enabled',
        (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioList(showLoadingMore: true));

      // Verify loading indicator is shown
      TestUtils.expectWidgetExists(find.byType(CircularProgressIndicator));
      TestUtils.expectTextExists('Loading more episodes...');

      // Total item count should be episodes + 1 for loading indicator
      expect(find.byType(AudioItemCard), findsNWidgets(sampleEpisodes.length));
    });

    testWidgets('should not show loading more indicator when disabled',
        (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioList(showLoadingMore: false));

      // Verify loading indicator is not shown
      TestUtils.expectWidgetNotExists(find.byType(CircularProgressIndicator));
      TestUtils.expectWidgetNotExists(find.text('Loading more episodes...'));
    });

    testWidgets('should display episodes with staggered animations',
        (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createAudioList());

      // Verify animation widgets are present
      expect(find.byType(AnimationConfiguration),
          findsNWidgets(sampleEpisodes.length));
      expect(find.byType(SlideAnimation), findsNWidgets(sampleEpisodes.length));
      expect(
          find.byType(FadeInAnimation), findsNWidgets(sampleEpisodes.length));
    });

    testWidgets('should handle scrolling correctly', (tester) async {
      final scrollController = ScrollController();

      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioList(scrollController: scrollController));

      // Verify ListView uses the provided scroll controller
      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.controller, equals(scrollController));
    });

    testWidgets('should handle scrolling with many episodes', (tester) async {
      final manyEpisodes = TestUtils.createSampleAudioFileList(20);

      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioList(episodes: manyEpisodes));

      // Scroll down to see more episodes
      await TestUtils.scrollWidget(
        tester,
        find.byType(ListView),
        const Offset(0, -500),
      );

      // Should still render correctly after scrolling
      TestUtils.expectWidgetExists(find.byType(AudioList));
    });

    testWidgets('should properly space episodes with padding', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createAudioList());

      // Find ListView and verify padding
      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(
          listView.padding,
          equals(const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: AppTheme.spacingS,
          )));

      // Verify individual episode padding
      final paddingWidgets = find.byType(Padding);
      expect(paddingWidgets.evaluate().length, greaterThan(0));
    });

    testWidgets('should handle single episode correctly', (tester) async {
      final singleEpisode = [
        TestUtils.createSampleAudioFile(title: 'Single Episode')
      ];

      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioList(episodes: singleEpisode));

      // Verify single episode is displayed
      expect(find.byType(AudioItemCard), findsOneWidget);
      TestUtils.expectTextExists('Single Episode');
    });

    testWidgets('should handle large number of episodes efficiently',
        (tester) async {
      final largeEpisodeList = TestUtils.createSampleAudioFileList(100);

      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioList(episodes: largeEpisodeList));

      // Should render without performance issues
      TestUtils.expectWidgetExists(find.byType(AudioList));
      TestUtils.expectWidgetExists(find.byType(ListView));

      // ListView.builder should handle large lists efficiently
      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.itemBuilder, isNotNull);
    });

    testWidgets('should maintain episode order correctly', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createAudioList());

      // Get all AudioItemCard widgets
      final cardWidgets = find.byType(AudioItemCard);

      // Verify the first card displays the first episode
      await tester.tap(cardWidgets.first);
      await tester.pumpAndSettle();

      expect(tappedEpisode, equals(sampleEpisodes.first));
    });

    testWidgets('should handle rapid scrolling without errors', (tester) async {
      final manyEpisodes = TestUtils.createSampleAudioFileList(50);

      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioList(episodes: manyEpisodes));

      // Perform rapid scrolling
      for (int i = 0; i < 5; i++) {
        await TestUtils.scrollWidget(
          tester,
          find.byType(ListView),
          const Offset(0, -200),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Should still render correctly
      TestUtils.expectWidgetExists(find.byType(AudioList));
    });

    testWidgets('should handle animations correctly on initial render',
        (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createAudioList());

      // Pump to allow animations to start
      await tester.pump();

      // Verify animation components are present
      expect(find.byType(AnimationConfiguration),
          findsNWidgets(sampleEpisodes.length));

      // Wait for animations to complete
      await TestUtils.waitForAnimation(
          tester, const Duration(milliseconds: 800));

      // Should still be properly rendered
      TestUtils.expectWidgetExists(find.byType(AudioList));
    });

    testWidgets('should handle empty state styling correctly', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioList(episodes: []));

      // Verify empty state structure
      TestUtils.expectWidgetExists(find.byType(Center));
      TestUtils.expectWidgetExists(find.byType(Column));

      // Verify icon styling
      final icon = tester.widget<Icon>(find.byIcon(Icons.headphones_outlined));
      expect(icon.size, equals(80));

      // Verify text styling
      TestUtils.expectTextExists('No episodes found');
      TestUtils.expectTextExists('Try different filters or search terms');
    });

    testWidgets('should handle loading more indicator styling correctly',
        (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioList(showLoadingMore: true));

      // Verify loading indicator structure
      TestUtils.expectWidgetExists(find.byType(CircularProgressIndicator));

      // Verify indicator color
      final indicator = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator));
      expect(indicator.valueColor?.value, equals(AppTheme.primaryColor));

      // Verify loading text
      TestUtils.expectTextExists('Loading more episodes...');
    });

    testWidgets('should handle mixed episode types correctly', (tester) async {
      final mixedEpisodes = [
        TestUtils.createSampleAudioFile(
          title: 'News Episode',
          category: 'daily-news',
          language: 'en-US',
        ),
        TestUtils.createSampleAudioFile(
          title: 'Tech Episode',
          category: 'ethereum',
          language: 'ja-JP',
        ),
        TestUtils.createSampleAudioFile(
          title: 'Business Episode',
          category: 'macro',
          language: 'zh-TW',
        ),
      ];

      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioList(episodes: mixedEpisodes));

      // Verify all episodes are displayed
      expect(find.byType(AudioItemCard), findsNWidgets(3));

      // Verify different episode types are shown
      TestUtils.expectTextExists('News Episode');
      TestUtils.expectTextExists('Tech Episode');
      TestUtils.expectTextExists('Business Episode');
    });

    testWidgets('should handle scroll controller disposal correctly',
        (tester) async {
      final scrollController = ScrollController();

      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioList(scrollController: scrollController));

      // Widget should use the controller
      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.controller, equals(scrollController));

      // Dispose the widget
      await tester.pumpWidget(Container());

      // Controller should still be valid (not disposed by the widget)
      expect(scrollController.hasClients, isFalse);
    });

    testWidgets('should handle item count correctly with loading more',
        (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioList(showLoadingMore: true));

      // Item count should be episodes + 1 for loading indicator
      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.itemCount, equals(sampleEpisodes.length + 1));
    });

    testWidgets('should handle item count correctly without loading more',
        (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioList(showLoadingMore: false));

      // Item count should be just episodes
      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.itemCount, equals(sampleEpisodes.length));
    });

    testWidgets('should handle accessibility correctly', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createAudioList());

      // Verify ListView is scrollable (accessibility)
      TestUtils.expectWidgetExists(find.byType(ListView));

      // Verify each episode is interactive
      expect(find.byType(AudioItemCard), findsNWidgets(sampleEpisodes.length));
    });

    testWidgets('should handle performance with frequent rebuilds',
        (tester) async {
      var episodeCount = 5;

      // Build initial list
      await TestUtils.pumpWidgetWithMaterialApp(
          tester,
          createAudioList(
              episodes: TestUtils.createSampleAudioFileList(episodeCount)));

      // Simulate frequent rebuilds with different episode counts
      for (int i = 0; i < 5; i++) {
        episodeCount += 2;
        await TestUtils.pumpWidgetWithMaterialApp(
            tester,
            createAudioList(
                episodes: TestUtils.createSampleAudioFileList(episodeCount)));
        await tester.pump();
      }

      // Should handle rebuilds efficiently
      TestUtils.expectWidgetExists(find.byType(AudioList));
    });

    testWidgets('should handle edge case with very long episode titles',
        (tester) async {
      final longTitleEpisodes = [
        TestUtils.createSampleAudioFile(
          title:
              'This is an extremely long episode title that might cause layout issues if not handled properly in the UI component design',
        ),
      ];

      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioList(episodes: longTitleEpisodes));

      // Should render without overflow issues
      TestUtils.expectWidgetExists(find.byType(AudioList));
      TestUtils.expectWidgetExists(find.byType(AudioItemCard));
    });
  });
}
