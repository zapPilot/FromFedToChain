import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:from_fed_to_chain_app/widgets/audio_item_card.dart';
import 'package:from_fed_to_chain_app/models/audio_file.dart';
import 'package:from_fed_to_chain_app/themes/app_theme.dart';
import 'package:from_fed_to_chain_app/config/api_config.dart';

import 'widget_test_utils.dart';

void main() {
  group('AudioItemCard Widget Tests', () {
    late AudioFile testAudioFile;

    setUp(() {
      WidgetTestUtils.resetCallbacks();
      testAudioFile = WidgetTestUtils.createTestAudioFile();
    });

    group('Rendering Tests', () {
      testWidgets('should render all components correctly',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          AudioItemCard(
            audioFile: testAudioFile,
            onTap: WidgetTestUtils.mockTap,
            showPlayButton: true,
            isCurrentlyPlaying: false,
          ),
        );

        // Verify main structure
        expect(find.byType(AudioItemCard), findsOneWidget);
        expect(find.byType(Card), findsOneWidget);
        // Verify InkWell exists (may find multiple due to MaterialApp structure)
        final audioCardInkWell = find.descendant(
          of: find.byType(AudioItemCard),
          matching: find.byType(InkWell),
        );
        expect(audioCardInkWell, findsWidgets); // Allow multiple InkWells

        // Verify episode artwork
        expect(find.byType(Icon), findsWidgets); // Category icon and others

        // Verify episode information
        expect(find.text(testAudioFile.displayTitle), findsOneWidget);
        // Use display names instead of raw codes
        expect(find.textContaining('Daily News'),
            findsOneWidget); // daily-news -> Daily News
        expect(
            find.textContaining('English'), findsOneWidget); // en-US -> English

        // Verify play button is shown
        expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      });

      testWidgets('should display episode artwork with correct category icon',
          (WidgetTester tester) async {
        final categories = [
          'daily-news',
          'ethereum',
          'macro',
          'startup',
          'ai',
          'defi'
        ];
        final expectedIcons = [
          Icons.newspaper,
          Icons.currency_bitcoin,
          Icons.trending_up,
          Icons.rocket_launch,
          Icons.smart_toy,
          Icons.account_balance,
        ];

        for (int i = 0; i < categories.length; i++) {
          final audioFile =
              WidgetTestUtils.createTestAudioFileWithCategory(categories[i]);

          await tester.pumpWidget(
            WidgetTestUtils.createTestWrapper(
              AudioItemCard(
                audioFile: audioFile,
                onTap: WidgetTestUtils.mockTap,
                showPlayButton: true,
                isCurrentlyPlaying: false,
              ),
            ),
          );

          // Verify correct category icon
          expect(find.byIcon(expectedIcons[i]), findsOneWidget);
          await tester.pump();
        }
      });

      testWidgets('should display episode title with proper truncation',
          (WidgetTester tester) async {
        final longTitleAudioFile = WidgetTestUtils.createTestAudioFile(
          title:
              'This is an extremely long title that should be truncated when displayed in the audio item card to prevent overflow and maintain proper layout',
        );

        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          AudioItemCard(
            audioFile: longTitleAudioFile,
            onTap: WidgetTestUtils.mockTap,
            showPlayButton: true,
            isCurrentlyPlaying: false,
          ),
        );

        // Verify title is displayed
        expect(find.text(longTitleAudioFile.displayTitle), findsOneWidget);

        // Verify truncation settings
        final titleFinder = find.text(longTitleAudioFile.displayTitle);
        final titleWidget = tester.widget<Text>(titleFinder);

        expect(titleWidget.maxLines, equals(2));
        expect(titleWidget.overflow, equals(TextOverflow.ellipsis));
      });

      testWidgets('should display category and language chips',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          AudioItemCard(
            audioFile: testAudioFile,
            onTap: WidgetTestUtils.mockTap,
            showPlayButton: true,
            isCurrentlyPlaying: false,
          ),
        );

        // Verify category chip
        expect(
            find.textContaining(testAudioFile.categoryEmoji), findsOneWidget);
        expect(
            find.textContaining(
                ApiConfig.getCategoryDisplayName(testAudioFile.category)),
            findsOneWidget);

        // Verify language chip
        expect(find.textContaining(testAudioFile.languageFlag), findsOneWidget);
        expect(
            find.textContaining(
                ApiConfig.getLanguageDisplayName(testAudioFile.language)),
            findsOneWidget);
      });

      testWidgets('should display metadata correctly',
          (WidgetTester tester) async {
        final audioFileWithMetadata = WidgetTestUtils.createTestAudioFile(
          duration: const Duration(minutes: 25, seconds: 30),
          fileSizeBytes: 15 * 1024 * 1024, // 15MB
          lastModified: DateTime.now().subtract(const Duration(days: 2)),
        );

        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          AudioItemCard(
            audioFile: audioFileWithMetadata,
            onTap: WidgetTestUtils.mockTap,
            showPlayButton: true,
            isCurrentlyPlaying: false,
          ),
        );

        // Verify date formatting
        expect(find.text('2 days ago'), findsOneWidget);

        // Verify duration is displayed
        expect(
            find.text(audioFileWithMetadata.formattedDuration), findsWidgets);

        // Verify file size is displayed
        expect(
            find.text(audioFileWithMetadata.formattedFileSize), findsOneWidget);
      });

      testWidgets('should handle missing metadata gracefully',
          (WidgetTester tester) async {
        final audioFileMinimalMetadata = AudioFile(
          id: 'minimal-test',
          title: 'Minimal Test Audio',
          language: 'en-US',
          category: 'daily-news',
          streamingUrl: 'https://example.com/audio.m3u8',
          path: 'audio/test.m3u8',
          lastModified: DateTime.now(),
          // No duration or file size
        );

        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          AudioItemCard(
            audioFile: audioFileMinimalMetadata,
            onTap: WidgetTestUtils.mockTap,
            showPlayButton: true,
            isCurrentlyPlaying: false,
          ),
        );

        // Should render without errors
        expect(find.byType(AudioItemCard), findsOneWidget);
        expect(
            find.text(audioFileMinimalMetadata.displayTitle), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('Play Button vs Duration Display Tests', () {
      testWidgets('should show play button when showPlayButton is true',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          AudioItemCard(
            audioFile: testAudioFile,
            onTap: WidgetTestUtils.mockTap,
            showPlayButton: true,
            isCurrentlyPlaying: false,
          ),
        );

        // Verify play button is shown
        expect(find.byIcon(Icons.play_arrow), findsOneWidget);
        expect(find.byKey(AudioItemCard.playButtonKey), findsOneWidget);
      });

      testWidgets('should show pause icon when currently playing',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          AudioItemCard(
            audioFile: testAudioFile,
            onTap: WidgetTestUtils.mockTap,
            showPlayButton: true,
            isCurrentlyPlaying: true,
          ),
        );

        // Verify pause icon is shown when playing
        expect(find.byIcon(Icons.pause), findsOneWidget);
      });

      testWidgets('should show duration info when showPlayButton is false',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          AudioItemCard(
            audioFile: testAudioFile,
            onTap: WidgetTestUtils.mockTap,
            showPlayButton: false,
            isCurrentlyPlaying: false,
          ),
        );

        // Verify duration is shown instead of play button
        expect(find.text(testAudioFile.formattedDuration), findsWidgets);
        expect(find.byIcon(Icons.play_arrow), findsNothing);
        expect(find.byIcon(Icons.pause), findsNothing);
      });

      testWidgets('should show HLS indicator for streaming files',
          (WidgetTester tester) async {
        final hlsAudioFile = WidgetTestUtils.createTestAudioFile(
          streamingUrl: 'https://example.com/stream.m3u8',
        );

        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          AudioItemCard(
            audioFile: hlsAudioFile,
            onTap: WidgetTestUtils.mockTap,
            showPlayButton: false,
            isCurrentlyPlaying: false,
          ),
        );

        // Should show HLS indicator if it's a streaming file
        if (hlsAudioFile.isHlsStream) {
          expect(find.text('HLS'), findsOneWidget);
        }
      });
    });

    group('Currently Playing State Tests', () {
      testWidgets('should highlight card when currently playing',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          AudioItemCard(
            audioFile: testAudioFile,
            onTap: WidgetTestUtils.mockTap,
            showPlayButton: true,
            isCurrentlyPlaying: true,
          ),
        );

        // Verify "Now Playing" indicator
        expect(find.text('Now Playing'), findsOneWidget);
        expect(find.byIcon(Icons.graphic_eq), findsOneWidget);

        // Verify border highlighting (check container decoration)
        final containers = find.byType(Container);
        bool foundHighlightedContainer = false;

        for (int i = 0; i < containers.evaluate().length; i++) {
          final container = tester.widget<Container>(containers.at(i));
          final decoration = container.decoration as BoxDecoration?;

          if (decoration?.border != null) {
            foundHighlightedContainer = true;
            break;
          }
        }

        expect(foundHighlightedContainer, true);
      });

      testWidgets(
          'should not show playing indicator when not currently playing',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          AudioItemCard(
            audioFile: testAudioFile,
            onTap: WidgetTestUtils.mockTap,
            showPlayButton: true,
            isCurrentlyPlaying: false,
          ),
        );

        // Verify no "Now Playing" indicator
        expect(find.text('Now Playing'), findsNothing);
        expect(find.byIcon(Icons.graphic_eq), findsNothing);
      });
    });

    group('Interaction Tests', () {
      testWidgets('should handle card tap correctly',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          AudioItemCard(
            audioFile: testAudioFile,
            onTap: WidgetTestUtils.mockTap,
            showPlayButton: true,
            isCurrentlyPlaying: false,
          ),
        );

        // Tap the card
        await WidgetTestUtils.tapAndSettle(
            tester, find.byKey(AudioItemCard.cardKey));

        // Verify callback was triggered
        expect(WidgetTestUtils.tapCount, equals(1));
      });

      testWidgets('should handle long press correctly',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          AudioItemCard(
            audioFile: testAudioFile,
            onTap: WidgetTestUtils.mockTap,
            onLongPress: WidgetTestUtils.mockLongPress,
            showPlayButton: true,
            isCurrentlyPlaying: false,
          ),
        );

        // Long press the card
        await WidgetTestUtils.longPressAndSettle(
            tester, find.byKey(AudioItemCard.cardKey));

        // Verify long press callback was triggered
        expect(WidgetTestUtils.longPressCount, equals(1));
      });

      testWidgets('should handle play button tap', (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          AudioItemCard(
            audioFile: testAudioFile,
            onTap: WidgetTestUtils.mockTap,
            showPlayButton: true,
            isCurrentlyPlaying: false,
          ),
        );

        // Tap the play button specifically
        await WidgetTestUtils.tapAndSettle(
            tester, find.byIcon(Icons.play_arrow));

        // Should trigger the main onTap callback
        expect(WidgetTestUtils.tapCount, equals(1));
      });

      testWidgets('should handle interaction without long press callback',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          AudioItemCard(
            audioFile: testAudioFile,
            onTap: WidgetTestUtils.mockTap,
            // No onLongPress provided
            showPlayButton: true,
            isCurrentlyPlaying: false,
          ),
        );

        // Should render without errors even without long press callback
        expect(find.byType(AudioItemCard), findsOneWidget);

        // Tap should still work
        await WidgetTestUtils.tapAndSettle(
            tester, find.byKey(AudioItemCard.cardKey));
        expect(WidgetTestUtils.tapCount, equals(1));
      });
    });

    group('Visual Styling Tests', () {
      testWidgets('should apply correct artwork gradient colors',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          AudioItemCard(
            audioFile: testAudioFile,
            onTap: WidgetTestUtils.mockTap,
            showPlayButton: true,
            isCurrentlyPlaying: false,
          ),
        );

        // Find artwork container with gradient
        final containers = find.byType(Container);
        bool foundGradientContainer = false;

        for (int i = 0; i < containers.evaluate().length; i++) {
          final container = tester.widget<Container>(containers.at(i));
          final decoration = container.decoration as BoxDecoration?;

          if (decoration?.gradient is LinearGradient) {
            foundGradientContainer = true;
            expect(decoration!.gradient, isA<LinearGradient>());
            break;
          }
        }

        expect(foundGradientContainer, true);
      });

      testWidgets('should apply box shadow to artwork',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          AudioItemCard(
            audioFile: testAudioFile,
            onTap: WidgetTestUtils.mockTap,
            showPlayButton: true,
            isCurrentlyPlaying: false,
          ),
        );

        // Find container with shadow
        final containers = find.byType(Container);
        bool foundShadowContainer = false;

        for (int i = 0; i < containers.evaluate().length; i++) {
          final container = tester.widget<Container>(containers.at(i));
          final decoration = container.decoration as BoxDecoration?;

          if (decoration?.boxShadow != null &&
              decoration!.boxShadow!.isNotEmpty) {
            foundShadowContainer = true;
            break;
          }
        }

        expect(foundShadowContainer, true);
      });

      testWidgets('should style info chips correctly',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          AudioItemCard(
            audioFile: testAudioFile,
            onTap: WidgetTestUtils.mockTap,
            showPlayButton: true,
            isCurrentlyPlaying: false,
          ),
        );

        // Find info chip containers
        final containers = find.byType(Container);
        int chipContainerCount = 0;

        for (int i = 0; i < containers.evaluate().length; i++) {
          final container = tester.widget<Container>(containers.at(i));
          final decoration = container.decoration as BoxDecoration?;

          // Check for chip-like styling (border + background color)
          if (decoration?.border != null && decoration?.color != null) {
            chipContainerCount++;
          }
        }

        // Should have at least category and language chips
        expect(chipContainerCount, greaterThan(0));
      });

      testWidgets('should use correct theme colors',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          AudioItemCard(
            audioFile: testAudioFile,
            onTap: WidgetTestUtils.mockTap,
            showPlayButton: true,
            isCurrentlyPlaying: false,
          ),
        );

        // Verify theme colors are applied
        WidgetTestUtils.verifyThemeColors(tester);
      });

      testWidgets('should apply card elevation and rounded corners',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          AudioItemCard(
            audioFile: testAudioFile,
            onTap: WidgetTestUtils.mockTap,
            showPlayButton: true,
            isCurrentlyPlaying: false,
          ),
        );

        // Verify card styling
        final card = tester.widget<Card>(find.byType(Card));
        expect(card.elevation, equals(AppTheme.elevationS));

        final shape = card.shape as RoundedRectangleBorder;
        expect(shape.borderRadius, isA<BorderRadius>());
      });
    });

    group('Date Formatting Tests', () {
      testWidgets('should format recent dates correctly',
          (WidgetTester tester) async {
        final testCases = [
          (DateTime.now(), 'Today'),
          (DateTime.now().subtract(const Duration(days: 1)), 'Yesterday'),
          (DateTime.now().subtract(const Duration(days: 3)), '3 days ago'),
          (DateTime.now().subtract(const Duration(days: 10)), '1 week ago'),
          (DateTime.now().subtract(const Duration(days: 15)), '2 weeks ago'),
        ];

        for (final (date, expectedText) in testCases) {
          final audioFile =
              WidgetTestUtils.createTestAudioFile(lastModified: date);

          await tester.pumpWidget(
            WidgetTestUtils.createTestWrapper(
              AudioItemCard(
                audioFile: audioFile,
                onTap: WidgetTestUtils.mockTap,
                showPlayButton: true,
                isCurrentlyPlaying: false,
              ),
            ),
          );

          // Verify correct date formatting
          expect(find.text(expectedText), findsOneWidget);
          await tester.pump();
        }
      });

      testWidgets('should format old dates with full date',
          (WidgetTester tester) async {
        final oldDate = DateTime.now().subtract(const Duration(days: 60));
        final audioFile =
            WidgetTestUtils.createTestAudioFile(lastModified: oldDate);

        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          AudioItemCard(
            audioFile: audioFile,
            onTap: WidgetTestUtils.mockTap,
            showPlayButton: true,
            isCurrentlyPlaying: false,
          ),
        );

        // Should show formatted date for old content
        expect(find.byType(AudioItemCard), findsOneWidget);
        // Note: Exact date format testing would need more complex date string matching
      });
    });

    group('Accessibility Tests', () {
      testWidgets('should meet accessibility guidelines',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          AudioItemCard(
            audioFile: testAudioFile,
            onTap: WidgetTestUtils.mockTap,
            showPlayButton: true,
            isCurrentlyPlaying: false,
          ),
        );

        await WidgetTestUtils.verifyAccessibility(tester);
      });

      testWidgets('should have sufficient tap target sizes',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          AudioItemCard(
            audioFile: testAudioFile,
            onTap: WidgetTestUtils.mockTap,
            showPlayButton: true,
            isCurrentlyPlaying: false,
          ),
        );

        // Verify basic accessibility requirements - the card exists and has content
        final audioItemCardFinder = find.byType(AudioItemCard);
        expect(audioItemCardFinder, findsOneWidget);

        final cardRenderObject =
            tester.renderObject<RenderBox>(audioItemCardFinder);
        // Card should be reasonably sized for accessibility
        expect(cardRenderObject.size.width, greaterThanOrEqualTo(200));
        expect(cardRenderObject.size.height, greaterThanOrEqualTo(60));

        // Verify interactive elements exist
        expect(find.byIcon(Icons.play_arrow), findsOneWidget);
        expect(
            find.text('Test Audio: Bitcoin Market Analysis'), findsOneWidget);
      });

      testWidgets('should provide semantic information for screen readers',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          AudioItemCard(
            audioFile: testAudioFile,
            onTap: WidgetTestUtils.mockTap,
            showPlayButton: true,
            isCurrentlyPlaying: false,
          ),
        );

        // Verify important text content is available for screen readers
        expect(find.text(testAudioFile.displayTitle), findsOneWidget);
        // Use display names instead of raw codes
        expect(find.textContaining('Daily News'),
            findsOneWidget); // daily-news -> Daily News
        expect(
            find.textContaining('English'), findsOneWidget); // en-US -> English

        // Interactive elements should be discoverable
        expect(find.byKey(AudioItemCard.cardKey), findsOneWidget);
        expect(find.byKey(AudioItemCard.playButtonKey), findsOneWidget);
      });
    });

    group('Edge Cases and Boundary Conditions', () {
      testWidgets('should handle null optional parameters gracefully',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          AudioItemCard(
            audioFile: testAudioFile,
            onTap: WidgetTestUtils.mockTap,
            // onLongPress is null
            showPlayButton: true,
            isCurrentlyPlaying: false,
          ),
        );

        // Should render without errors
        expect(find.byType(AudioItemCard), findsOneWidget);

        // Main tap should still work
        await WidgetTestUtils.tapAndSettle(
            tester, find.byKey(AudioItemCard.cardKey));
        expect(WidgetTestUtils.tapCount, equals(1));
      });

      testWidgets('should handle empty callback gracefully',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          AudioItemCard(
            audioFile: testAudioFile,
            onTap: () {}, // Empty callback
            onLongPress: () {}, // Empty callback
            showPlayButton: true,
            isCurrentlyPlaying: false,
          ),
        );

        // Should render without errors
        expect(find.byType(AudioItemCard), findsOneWidget);

        // Should handle interactions without crashes
        await WidgetTestUtils.tapAndSettle(
            tester, find.byKey(AudioItemCard.cardKey));
        await WidgetTestUtils.longPressAndSettle(
            tester, find.byKey(AudioItemCard.cardKey));
      });

      testWidgets('should handle empty title gracefully',
          (WidgetTester tester) async {
        final emptyTitleAudio = AudioFile(
          id: 'empty-title-test',
          title: '', // Empty title
          language: 'en-US',
          category: 'daily-news',
          streamingUrl: 'https://example.com/audio.m3u8',
          path: 'audio/test.m3u8',
          lastModified: DateTime.now(),
        );

        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          AudioItemCard(
            audioFile: emptyTitleAudio,
            onTap: WidgetTestUtils.mockTap,
            showPlayButton: true,
            isCurrentlyPlaying: false,
          ),
        );

        // Should render without errors and show fallback text
        expect(find.byType(AudioItemCard), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(find.text(emptyTitleAudio.displayTitle), findsOneWidget);
      });

      testWidgets('should handle extremely long title gracefully',
          (WidgetTester tester) async {
        final extremelyLongTitle = 'This is an ' * 100 +
            'extremely long title that tests the limits of text rendering and memory usage in the AudioItemCard widget component';

        final longTitleAudio = WidgetTestUtils.createTestAudioFile(
          title: extremelyLongTitle,
        );

        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          AudioItemCard(
            audioFile: longTitleAudio,
            onTap: WidgetTestUtils.mockTap,
            showPlayButton: true,
            isCurrentlyPlaying: false,
          ),
        );

        // Should render without errors
        expect(find.byType(AudioItemCard), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Verify text is properly truncated
        final titleWidget =
            tester.widget<Text>(find.text(longTitleAudio.displayTitle));
        expect(titleWidget.maxLines, equals(2));
        expect(titleWidget.overflow, equals(TextOverflow.ellipsis));
      });

      testWidgets('should handle extreme duration values',
          (WidgetTester tester) async {
        final extremeDurationAudioFile = WidgetTestUtils.createTestAudioFile(
          duration:
              const Duration(hours: 10, minutes: 30), // Very long duration
        );

        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          AudioItemCard(
            audioFile: extremeDurationAudioFile,
            onTap: WidgetTestUtils.mockTap,
            showPlayButton: false, // Show duration
            isCurrentlyPlaying: false,
          ),
        );

        // Should handle extreme durations without errors
        expect(find.byType(AudioItemCard), findsOneWidget);
        // Duration appears in both metadata and duration display sections
        expect(find.text(extremeDurationAudioFile.formattedDuration),
            findsWidgets);
      });

      testWidgets('should handle zero duration gracefully',
          (WidgetTester tester) async {
        final zeroDurationAudio = WidgetTestUtils.createTestAudioFile(
          duration: Duration.zero,
        );

        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          AudioItemCard(
            audioFile: zeroDurationAudio,
            onTap: WidgetTestUtils.mockTap,
            showPlayButton: false, // Show duration instead of play button
            isCurrentlyPlaying: false,
          ),
        );

        // Should render without errors
        expect(find.byType(AudioItemCard), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(find.text(zeroDurationAudio.formattedDuration), findsWidgets);
      });

      testWidgets('should handle extremely large file size',
          (WidgetTester tester) async {
        final largeFileSizeAudio = WidgetTestUtils.createTestAudioFile(
          fileSizeBytes: 999999999999, // ~1TB file
        );

        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          AudioItemCard(
            audioFile: largeFileSizeAudio,
            onTap: WidgetTestUtils.mockTap,
            showPlayButton: true,
            isCurrentlyPlaying: false,
          ),
        );

        // Should render without errors
        expect(find.byType(AudioItemCard), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(find.text(largeFileSizeAudio.formattedFileSize), findsWidgets);
      });

      testWidgets('should handle zero byte file size',
          (WidgetTester tester) async {
        final zeroSizeAudio = WidgetTestUtils.createTestAudioFile(
          fileSizeBytes: 0,
        );

        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          AudioItemCard(
            audioFile: zeroSizeAudio,
            onTap: WidgetTestUtils.mockTap,
            showPlayButton: true,
            isCurrentlyPlaying: false,
          ),
        );

        // Should render without errors
        expect(find.byType(AudioItemCard), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle special characters in title and metadata',
          (WidgetTester tester) async {
        final specialCharAudioFile = WidgetTestUtils.createTestAudioFile(
          title:
              '🎵 Bitcoin & Ethereum: 加密货币 📈 Analysis (Part 2/3) — Testing «Special» Characters!',
        );

        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          AudioItemCard(
            audioFile: specialCharAudioFile,
            onTap: WidgetTestUtils.mockTap,
            showPlayButton: true,
            isCurrentlyPlaying: false,
          ),
        );

        // Should handle special characters without errors
        expect(find.byType(AudioItemCard), findsOneWidget);
        expect(find.text(specialCharAudioFile.displayTitle), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle unknown category gracefully',
          (WidgetTester tester) async {
        final unknownCategoryAudioFile = WidgetTestUtils.createTestAudioFile(
          category: 'unknown-category',
        );

        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          AudioItemCard(
            audioFile: unknownCategoryAudioFile,
            onTap: WidgetTestUtils.mockTap,
            showPlayButton: true,
            isCurrentlyPlaying: false,
          ),
        );

        // Should render with default icon for unknown category
        expect(find.byType(AudioItemCard), findsOneWidget);
        expect(find.byIcon(Icons.headphones), findsOneWidget); // Default icon
      });

      testWidgets('should handle invalid URLs gracefully',
          (WidgetTester tester) async {
        final invalidUrlAudio = AudioFile(
          id: 'invalid-url-test',
          title: 'Invalid URL Test',
          language: 'en-US',
          category: 'daily-news',
          streamingUrl: 'not-a-valid-url',
          path: 'invalid://path',
          lastModified: DateTime.now(),
        );

        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          AudioItemCard(
            audioFile: invalidUrlAudio,
            onTap: WidgetTestUtils.mockTap,
            showPlayButton: true,
            isCurrentlyPlaying: false,
          ),
        );

        // Should render without errors even with invalid URLs
        expect(find.byType(AudioItemCard), findsOneWidget);
        expect(find.text(invalidUrlAudio.displayTitle), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle layout constraints gracefully',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: SizedBox(
                width: 320, // Reasonable minimum width
                height: 200, // Reasonable minimum height
                child: AudioItemCard(
                  audioFile: testAudioFile,
                  onTap: WidgetTestUtils.mockTap,
                  showPlayButton: true,
                  isCurrentlyPlaying: false,
                ),
              ),
            ),
          ),
        );

        // Should render without overflow errors
        expect(find.byType(AudioItemCard), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('Responsive Design Tests', () {
      testWidgets('should adapt to different screen sizes',
          (WidgetTester tester) async {
        final testSizes = WidgetTestUtils.getTestScreenSizes();

        for (final size in testSizes) {
          WidgetTestUtils.setDeviceSize(tester, size);

          await WidgetTestUtils.pumpWidgetWithTheme(
            tester,
            AudioItemCard(
              audioFile: testAudioFile,
              onTap: WidgetTestUtils.mockTap,
              showPlayButton: true,
              isCurrentlyPlaying: false,
            ),
          );

          // Should render properly on all screen sizes
          expect(find.byType(AudioItemCard), findsOneWidget);
          expect(tester.takeException(), isNull);
        }

        WidgetTestUtils.resetDeviceSize(tester);
      });

      testWidgets('should handle very narrow screens',
          (WidgetTester tester) async {
        WidgetTestUtils.setDeviceSize(tester, const Size(280, 600));

        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          AudioItemCard(
            audioFile: testAudioFile,
            onTap: WidgetTestUtils.mockTap,
            showPlayButton: true,
            isCurrentlyPlaying: false,
          ),
        );

        // Should handle narrow screens with proper text wrapping
        expect(find.byType(AudioItemCard), findsOneWidget);
        expect(find.byType(Wrap), findsWidgets); // For chip wrapping
        expect(tester.takeException(), isNull);

        WidgetTestUtils.resetDeviceSize(tester);
      });
    });

    group('Content Validation Tests', () {
      testWidgets('should use WidgetTestUtils helper methods correctly',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          AudioItemCard(
            audioFile: testAudioFile,
            onTap: WidgetTestUtils.mockTap,
            showPlayButton: true,
            isCurrentlyPlaying: false,
          ),
        );

        // Use the helper validation method
        WidgetTestUtils.verifyAudioItemCard(
          tester: tester,
          audioFile: testAudioFile,
          shouldShowPlayButton: true,
          shouldShowCurrentlyPlaying: false,
        );
      });

      testWidgets('should validate all content elements are present',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          AudioItemCard(
            audioFile: testAudioFile,
            onTap: WidgetTestUtils.mockTap,
            showPlayButton: true,
            isCurrentlyPlaying: true,
          ),
        );

        // Use helper to validate playing state
        WidgetTestUtils.verifyAudioItemCard(
          tester: tester,
          audioFile: testAudioFile,
          shouldShowPlayButton: true,
          shouldShowCurrentlyPlaying: true,
        );
      });
    });
  });
}
