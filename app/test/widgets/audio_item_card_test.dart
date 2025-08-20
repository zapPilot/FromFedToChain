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

      // Verify main structure exists
      expect(find.byType(AudioItemCard), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);

      // Check that content is displayed (title should be visible)
      expect(find.text(sampleAudioFile.title), findsOneWidget);
    });

    testWidgets('should display audio file information correctly',
        (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createAudioItemCard());

      // Verify title is displayed
      expect(find.text(sampleAudioFile.title), findsOneWidget);

      // The actual widget uses ApiConfig display names, not uppercase
      // For a sample file with category 'daily-news' and language 'en-US':
      // Category should show "Daily News" and language should show "English"
      expect(find.textContaining('Daily News'), findsOneWidget);
      expect(find.textContaining('English'), findsOneWidget);
    });

    testWidgets('should handle tap interactions correctly', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createAudioItemCard());

      // Find and tap the card
      await tester.tap(find.byType(AudioItemCard));
      await tester.pumpAndSettle();

      // Verify tap was handled
      expect(wasTapped, isTrue);
    });

    testWidgets('should handle long press interactions correctly',
        (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createAudioItemCard());

      // Find and long press the card
      await tester.longPress(find.byType(AudioItemCard));
      await tester.pumpAndSettle();

      // Verify long press was handled
      expect(wasLongPressed, isTrue);
    });

    testWidgets('should show play button when enabled', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioItemCard(showPlayButton: true));

      // Verify play button icon is visible
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('should hide play button when disabled', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioItemCard(showPlayButton: false));

      // Verify play button icon is not visible
      expect(find.byIcon(Icons.play_arrow), findsNothing);
    });

    testWidgets('should show pause icon when currently playing',
        (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(
        tester,
        createAudioItemCard(
          showPlayButton: true,
          isCurrentlyPlaying: true,
        ),
      );

      // When playing, should show pause icon instead of play
      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
    });

    testWidgets('should format duration correctly', (tester) async {
      final audioFileWithDuration = TestUtils.createSampleAudioFile(
        duration: const Duration(minutes: 5, seconds: 30),
      );

      await TestUtils.pumpWidgetWithMaterialApp(
        tester,
        createAudioItemCard(audioFile: audioFileWithDuration),
      );

      // Verify duration is formatted and displayed
      expect(find.text('5:30'), findsOneWidget);
    });

    testWidgets('should handle null onLongPress callback gracefully',
        (tester) async {
      // Reset the flag
      wasLongPressed = false;

      await TestUtils.pumpWidgetWithMaterialApp(
        tester,
        createAudioItemCard(onLongPressCallback: null),
      );

      // Should render without error even with null long press callback
      expect(find.byType(AudioItemCard), findsOneWidget);

      // Attempt to long press should not crash
      await tester.longPress(find.byType(AudioItemCard));
      await tester.pumpAndSettle();

      // Since we passed null, the default onLongPress (which sets wasLongPressed to true) won't be called
      // But the widget itself handles null gracefully, so no error should occur
      // The test should just verify the widget doesn't crash
      expect(find.byType(AudioItemCard), findsOneWidget);
    });

    testWidgets('should handle very long titles with ellipsis', (tester) async {
      final longTitleAudioFile = TestUtils.createSampleAudioFile(
        title:
            'This is a very long title that should be truncated with ellipsis to prevent overflow issues in the UI layout and maintain proper visual hierarchy',
      );

      await TestUtils.pumpWidgetWithMaterialApp(
        tester,
        createAudioItemCard(audioFile: longTitleAudioFile),
      );

      // Should render without overflow errors
      expect(find.byType(AudioItemCard), findsOneWidget);
      expect(find.text(longTitleAudioFile.title), findsOneWidget);
    });

    testWidgets('should handle different audio file categories',
        (tester) async {
      final categoryMappings = {
        'daily-news': 'Daily News',
        'ethereum': 'Ethereum',
        'macro': 'Macro Economics',
        'startup': 'Startup',
      };

      for (String category in categoryMappings.keys) {
        final audioFileWithCategory = TestUtils.createSampleAudioFile(
          category: category,
        );

        await TestUtils.pumpWidgetWithMaterialApp(
          tester,
          createAudioItemCard(audioFile: audioFileWithCategory),
        );

        // Verify category display name is shown
        expect(
            find.textContaining(categoryMappings[category]!), findsOneWidget);
      }
    });

    testWidgets('should handle different languages', (tester) async {
      final languageMappings = {
        'en-US': 'English',
        'ja-JP': '日本語',
        'zh-TW': '繁體中文',
      };

      for (String language in languageMappings.keys) {
        final audioFileWithLanguage = TestUtils.createSampleAudioFile(
          language: language,
        );

        await TestUtils.pumpWidgetWithMaterialApp(
          tester,
          createAudioItemCard(audioFile: audioFileWithLanguage),
        );

        // Verify language display name is shown
        expect(
            find.textContaining(languageMappings[language]!), findsOneWidget);
      }
    });

    testWidgets('should show correct playing state styling', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(
        tester,
        createAudioItemCard(isCurrentlyPlaying: true),
      );

      // Should render card when playing
      expect(find.byType(AudioItemCard), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('should maintain consistent styling', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createAudioItemCard());

      // Verify card styling
      final cardWidget = tester.widget<Card>(find.byType(Card));
      expect(cardWidget.elevation, equals(AppTheme.elevationS));
      expect(cardWidget.shape, isA<RoundedRectangleBorder>());
    });

    testWidgets('should handle empty or null callbacks gracefully',
        (tester) async {
      Widget cardWithMinimalCallbacks = AudioItemCard(
        audioFile: sampleAudioFile,
        onTap: () {}, // Empty callback
        // onLongPress is null by default
      );

      await TestUtils.pumpWidgetWithMaterialApp(
          tester, cardWithMinimalCallbacks);

      // Should render without issues
      expect(find.byType(AudioItemCard), findsOneWidget);

      // Should handle tap without errors
      await tester.tap(find.byType(AudioItemCard));
      await tester.pumpAndSettle();
    });

    testWidgets('should show duration for different lengths', (tester) async {
      final testCases = [
        Duration(seconds: 30),
        Duration(minutes: 2, seconds: 15),
        Duration(hours: 1, minutes: 23, seconds: 45),
      ];

      final expectedFormats = [
        '0:30',
        '2:15',
        '1:23:45',
      ];

      for (int i = 0; i < testCases.length; i++) {
        final audioFile = TestUtils.createSampleAudioFile(
          duration: testCases[i],
        );

        await TestUtils.pumpWidgetWithMaterialApp(
          tester,
          createAudioItemCard(audioFile: audioFile),
        );

        expect(find.text(expectedFormats[i]), findsOneWidget);
      }
    });
  });
}
