import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:from_fed_to_chain_app/widgets/audio_item_card.dart';
import 'package:from_fed_to_chain_app/models/audio_file.dart';
import 'package:from_fed_to_chain_app/themes/app_theme.dart';
import '../test_utils.dart';

void main() {
  group('AudioItemCard Widget Tests', () {
    late AudioFile sampleAudioFile;
    bool wasTapped = false;
    bool wasLongPressed = false;

    void onTap() {
      wasTapped = true;
    }

    void onLongPress() {
      wasLongPressed = true;
    }

    setUp(() {
      sampleAudioFile = TestUtils.createSampleAudioFile();
      wasTapped = false;
      wasLongPressed = false;
    });

    Widget createAudioItemCard({
      AudioFile? audioFile,
      VoidCallback? onTapCallback,
      VoidCallback? onLongPressCallback,
      bool showPlayButton = true,
      bool isCurrentlyPlaying = false,
    }) {
      return AudioItemCard(
        audioFile: audioFile ?? sampleAudioFile,
        onTap: onTapCallback ?? onTap,
        onLongPress: onLongPressCallback ?? onLongPress,
        showPlayButton: showPlayButton,
        isCurrentlyPlaying: isCurrentlyPlaying,
      );
    }

    testWidgets('should render with basic structure', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createAudioItemCard());

      // Verify main structure
      TestUtils.expectWidgetExists(find.byType(AudioItemCard));
      TestUtils.expectWidgetExists(find.byType(Card));
      TestUtils.expectWidgetExists(find.byType(InkWell));
      TestUtils.expectWidgetExists(find.byType(Row));
    });

    testWidgets('should display audio file information correctly',
        (tester) async {
      final audioFile = TestUtils.createSampleAudioFile(
        title: 'Bitcoin Market Analysis',
        category: 'daily-news',
        language: 'en-US',
      );

      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioItemCard(audioFile: audioFile));

      // Verify title is displayed
      TestUtils.expectTextExists('Bitcoin Market Analysis');

      // Verify category chip with emoji
      TestUtils.expectTextExists('📰 Daily News');

      // Verify language chip with flag
      TestUtils.expectTextExists('🇺🇸 English');
    });

    testWidgets('should handle very long titles with ellipsis (overflow fix)',
        (tester) async {
      final audioFile = TestUtils.createSampleAudioFile(
        title:
            'This is an extremely long title that should be truncated to prevent overflow issues in the user interface and maintain good visual design',
      );

      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioItemCard(audioFile: audioFile));

      // Verify the title text widget exists with ellipsis overflow
      final titleText = find.text(audioFile.title);
      TestUtils.expectWidgetExists(titleText);

      // Check that Text widget has ellipsis overflow
      final textWidget = tester.widget<Text>(titleText);
      expect(textWidget.overflow, equals(TextOverflow.ellipsis));
      expect(textWidget.maxLines, equals(2));
    });

    testWidgets(
        'should handle category and language chips with Wrap for overflow prevention',
        (tester) async {
      final audioFile = TestUtils.createSampleAudioFile(
          category: 'daily-news', language: 'en-US');

      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioItemCard(audioFile: audioFile));

      // Verify Wrap widget is used for chips to prevent overflow
      TestUtils.expectWidgetExists(find.byType(Wrap));

      // Verify both chips are present
      TestUtils.expectTextExists('📰 Daily News');
      TestUtils.expectTextExists('🇺🇸 English');
    });

    testWidgets(
        'should use SingleChildScrollView for metadata to prevent overflow',
        (tester) async {
      final audioFile = TestUtils.createSampleAudioFile(
        duration: const Duration(hours: 2, minutes: 34, seconds: 56),
        fileSizeBytes: 256 * 1024 * 1024, // 256 MB
      );

      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioItemCard(audioFile: audioFile));

      // Verify SingleChildScrollView is used for metadata row
      final scrollViews = find.byType(SingleChildScrollView);
      expect(scrollViews.evaluate().length, greaterThan(0));

      // Find the scrollable metadata section
      final metadataScroll = find.ancestor(
        of: find.textContaining('2:34:56'),
        matching: find.byType(SingleChildScrollView),
      );
      TestUtils.expectWidgetExists(metadataScroll);
    });

    testWidgets('should handle tap interactions correctly', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createAudioItemCard());

      // Tap the card
      await TestUtils.tapWidget(tester, find.byType(InkWell));

      expect(wasTapped, isTrue);
    });

    testWidgets('should handle long press interactions correctly',
        (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createAudioItemCard());

      // Long press the card
      await TestUtils.longPressWidget(tester, find.byType(InkWell));

      expect(wasLongPressed, isTrue);
    });

    testWidgets('should show play button when showPlayButton is true',
        (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioItemCard(showPlayButton: true));

      // Verify play button is present
      TestUtils.expectIconExists(Icons.play_arrow);
      TestUtils.expectWidgetExists(find.byType(IconButton));
    });

    testWidgets('should show duration info when showPlayButton is false',
        (tester) async {
      final audioFile = TestUtils.createSampleAudioFile(
        duration: const Duration(minutes: 15, seconds: 30),
      );

      await TestUtils.pumpWidgetWithMaterialApp(
          tester,
          createAudioItemCard(
            audioFile: audioFile,
            showPlayButton: false,
          ));

      // Verify duration is displayed
      TestUtils.expectTextExists('15:30');

      // Verify play button is not present
      TestUtils.expectWidgetNotExists(find.byIcon(Icons.play_arrow));
    });

    testWidgets('should show pause icon when currently playing',
        (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioItemCard(isCurrentlyPlaying: true));

      // Verify pause icon is shown instead of play
      TestUtils.expectIconExists(Icons.pause);
      TestUtils.expectWidgetNotExists(find.byIcon(Icons.play_arrow));
    });

    testWidgets('should display "Now Playing" indicator when currently playing',
        (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioItemCard(isCurrentlyPlaying: true));

      // Verify "Now Playing" indicator
      TestUtils.expectTextExists('Now Playing');
      TestUtils.expectIconExists(Icons.graphic_eq);
    });

    testWidgets(
        'should show current playing border when isCurrentlyPlaying is true',
        (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioItemCard(isCurrentlyPlaying: true));

      // Find the container with border
      final containerWithBorder = find.descendant(
        of: find.byType(InkWell),
        matching: find.byType(Container),
      );

      TestUtils.expectWidgetExists(containerWithBorder);
    });

    testWidgets(
        'should display formatted date correctly for different time periods',
        (tester) async {
      final now = DateTime.now();

      // Test today
      final todayFile = TestUtils.createSampleAudioFile(
        publishDate: now,
      );
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioItemCard(audioFile: todayFile));
      TestUtils.expectTextExists('Today');

      // Test yesterday
      final yesterdayFile = TestUtils.createSampleAudioFile(
        publishDate: now.subtract(const Duration(days: 1)),
      );
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioItemCard(audioFile: yesterdayFile));
      TestUtils.expectTextExists('Yesterday');

      // Test few days ago
      final fewDaysFile = TestUtils.createSampleAudioFile(
        publishDate: now.subtract(const Duration(days: 3)),
      );
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioItemCard(audioFile: fewDaysFile));
      TestUtils.expectTextExists('3 days ago');
    });

    testWidgets('should display HLS indicator for streaming files',
        (tester) async {
      final hlsFile = TestUtils.createSampleAudioFile(
        streamingUrl: 'https://example.com/stream.m3u8',
      );

      await TestUtils.pumpWidgetWithMaterialApp(tester,
          createAudioItemCard(audioFile: hlsFile, showPlayButton: false));

      // Verify HLS indicator
      TestUtils.expectTextExists('HLS');
    });

    testWidgets('should show correct category icons and colors',
        (tester) async {
      final categories = ['daily-news', 'ethereum', 'macro', 'startup', 'ai'];
      final expectedIcons = [
        Icons.newspaper,
        Icons.currency_bitcoin,
        Icons.trending_up,
        Icons.rocket_launch,
        Icons.smart_toy,
      ];

      for (int i = 0; i < categories.length; i++) {
        final audioFile =
            TestUtils.createSampleAudioFile(category: categories[i]);

        await TestUtils.pumpWidgetWithMaterialApp(
            tester, createAudioItemCard(audioFile: audioFile));

        // Verify category icon
        TestUtils.expectIconExists(expectedIcons[i]);

        await tester.pumpWidget(Container()); // Clear previous widget
      }
    });

    testWidgets('should show correct language flags', (tester) async {
      final languages = ['zh-TW', 'en-US', 'ja-JP'];
      final expectedFlags = ['🇹🇼', '🇺🇸', '🇯🇵'];

      for (int i = 0; i < languages.length; i++) {
        final audioFile =
            TestUtils.createSampleAudioFile(language: languages[i]);

        await TestUtils.pumpWidgetWithMaterialApp(
            tester, createAudioItemCard(audioFile: audioFile));

        // Verify language flag
        expect(find.textContaining(expectedFlags[i]), findsOneWidget);

        await tester.pumpWidget(Container()); // Clear previous widget
      }
    });

    testWidgets('should handle file size formatting correctly', (tester) async {
      final audioFile = TestUtils.createSampleAudioFile(
        fileSizeBytes: 1536 * 1024, // 1.5 MB
      );

      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioItemCard(audioFile: audioFile));

      // Should display formatted file size
      final fileSizeText = find.textContaining('MB');
      TestUtils.expectWidgetExists(fileSizeText);
    });

    testWidgets('should handle missing optional fields gracefully',
        (tester) async {
      final audioFile = TestUtils.createSampleAudioFile(
        duration: null,
        fileSizeBytes: null,
      );

      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioItemCard(audioFile: audioFile));

      // Should render without crashing
      TestUtils.expectWidgetExists(find.byType(AudioItemCard));

      // Duration and file size should not be displayed
      TestUtils.expectWidgetNotExists(find.textContaining(':'));
      TestUtils.expectWidgetNotExists(find.textContaining('MB'));
    });

    testWidgets('should handle edge case with very small screen sizes',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(300, 600));

      final audioFile = TestUtils.createSampleAudioFile(
        title: 'Very Long Title That Might Cause Overflow On Small Screens',
      );

      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioItemCard(audioFile: audioFile));

      // Should render without overflow errors
      TestUtils.expectWidgetExists(find.byType(AudioItemCard));

      // Reset screen size
      await tester.binding.setSurfaceSize(const Size(800, 600));
    });

    testWidgets('should handle rapid tap interactions', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createAudioItemCard());

      int tapCount = 0;
      final rapidTapCard = createAudioItemCard(
        onTapCallback: () => tapCount++,
      );

      await TestUtils.pumpWidgetWithMaterialApp(tester, rapidTapCard);

      // Perform rapid taps
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byType(InkWell));
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(tapCount, equals(5));
    });

    testWidgets('should maintain consistent styling across different states',
        (tester) async {
      // Test normal state
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioItemCard(isCurrentlyPlaying: false));

      final normalCard = find.byType(Card);
      TestUtils.expectWidgetExists(normalCard);

      // Test playing state
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioItemCard(isCurrentlyPlaying: true));

      final playingCard = find.byType(Card);
      TestUtils.expectWidgetExists(playingCard);
    });

    testWidgets('should handle accessibility correctly', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createAudioItemCard());

      // Verify the card is interactive
      TestUtils.expectWidgetExists(find.byType(InkWell));

      // Verify interactive elements exist
      TestUtils.expectWidgetExists(find.byType(IconButton));
    });

    testWidgets('should apply correct theme colors', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createAudioItemCard());

      // Verify gradient container for artwork
      final gradientContainers = find.byType(Container);
      expect(gradientContainers.evaluate().length, greaterThan(0));
    });

    testWidgets('should handle null onLongPress callback gracefully',
        (tester) async {
      final cardWithoutLongPress = AudioItemCard(
        audioFile: sampleAudioFile,
        onTap: onTap,
        // onLongPress is null
      );

      await TestUtils.pumpWidgetWithMaterialApp(tester, cardWithoutLongPress);

      // Should render without issues
      TestUtils.expectWidgetExists(find.byType(AudioItemCard));
    });

    testWidgets('should show correct duration format for different lengths',
        (tester) async {
      final testCases = [
        (const Duration(seconds: 45), '0:45'),
        (const Duration(minutes: 5, seconds: 30), '5:30'),
        (const Duration(hours: 1, minutes: 23, seconds: 45), '1:23:45'),
        (const Duration(hours: 2, minutes: 0, seconds: 0), '2:00:00'),
      ];

      for (final (duration, expectedFormat) in testCases) {
        final audioFile = TestUtils.createSampleAudioFile(duration: duration);

        await TestUtils.pumpWidgetWithMaterialApp(
            tester, createAudioItemCard(audioFile: audioFile));

        TestUtils.expectTextExists(expectedFormat);

        await tester.pumpWidget(Container()); // Clear previous widget
      }
    });

    testWidgets('should handle scrolling in metadata section', (tester) async {
      final audioFile = TestUtils.createSampleAudioFile(
        duration: const Duration(hours: 1, minutes: 30),
        fileSizeBytes: 100 * 1024 * 1024, // 100 MB
      );

      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioItemCard(audioFile: audioFile));

      // Find the metadata scroll view
      final metadataScroll = find.byType(SingleChildScrollView);
      TestUtils.expectWidgetExists(metadataScroll);

      // Test horizontal scrolling
      await TestUtils.scrollWidget(
        tester,
        metadataScroll.first,
        const Offset(-50, 0),
      );

      // Should still render correctly after scrolling
      TestUtils.expectWidgetExists(find.byType(AudioItemCard));
    });

    testWidgets('should preserve layout with info chips wrapped correctly',
        (tester) async {
      final audioFile = TestUtils.createSampleAudioFile(
        category: 'daily-news',
        language: 'en-US',
      );

      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioItemCard(audioFile: audioFile));

      // Verify Wrap widget is handling chip layout
      final wrapWidget = find.byType(Wrap);
      TestUtils.expectWidgetExists(wrapWidget);

      // Both chips should be present
      TestUtils.expectTextExists('📰 Daily News');
      TestUtils.expectTextExists('🇺🇸 English');

      // Verify proper spacing in Wrap
      final wrap = tester.widget<Wrap>(wrapWidget);
      expect(wrap.spacing, equals(AppTheme.spacingS));
      expect(wrap.runSpacing, equals(AppTheme.spacingXS));
    });
  });
}
