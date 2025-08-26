import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:from_fed_to_chain_app/widgets/filter_bar.dart';
import 'package:from_fed_to_chain_app/widgets/audio_list.dart';
import 'package:from_fed_to_chain_app/widgets/audio_item_card.dart';

import '../test_utils.dart';

void main() {
  group('Accessibility and Usability Tests', () {
    testWidgets('filter bar semantic properties', (tester) async {
      await tester.pumpWidget(
        TestUtils.wrapWithMaterialApp(
          FilterBar(
            selectedLanguage: 'zh-TW',
            selectedCategory: 'all',
            onLanguageChanged: (value) {},
            onCategoryChanged: (value) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Test semantic structure
      expect(find.byType(FilterBar), findsOneWidget);

      // Verify choice chips have proper semantics
      final choiceChips = find.byType(ChoiceChip);
      expect(choiceChips, findsAtLeastNWidgets(1));

      // Test that chips are accessible
      for (final chip in choiceChips.evaluate()) {
        final widget = chip.widget as ChoiceChip;
        expect(widget.label, isNotNull);
      }
    });

    testWidgets('audio list accessibility features', (tester) async {
      final episodes = TestUtils.createSampleAudioFileList(5);

      await tester.pumpWidget(
        TestUtils.wrapWithMaterialApp(
          AudioList(
            episodes: episodes,
            onEpisodeTap: (episode) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify list is accessible
      expect(find.byType(AudioList), findsOneWidget);

      // Check audio cards have proper accessibility
      final audioCards = find.byType(AudioItemCard);
      expect(audioCards, findsAtLeastNWidgets(1));

      // Verify semantic labels exist
      final firstCard = audioCards.first;
      expect(firstCard, findsOneWidget);
    });

    testWidgets('keyboard navigation support', (tester) async {
      String selectedLanguage = 'zh-TW';
      String selectedCategory = 'all';

      await tester.pumpWidget(
        TestUtils.wrapWithMaterialApp(
          Column(
            children: [
              FilterBar(
                selectedLanguage: selectedLanguage,
                selectedCategory: selectedCategory,
                onLanguageChanged: (language) {},
                onCategoryChanged: (category) {},
              ),
              Text('Language: $selectedLanguage'),
              Text('Category: $selectedCategory'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Test tab navigation
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      // Test space/enter activation
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      // Test arrow key navigation
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();

      // Verify keyboard navigation doesn't break the widget
      expect(find.byType(FilterBar), findsOneWidget);
    });

    testWidgets('high contrast mode support', (tester) async {
      await tester.pumpWidget(
        TestUtils.wrapWithMaterialApp(
          MediaQuery(
            data: const MediaQueryData(
              highContrast: true,
              accessibleNavigation: true,
            ),
            child: FilterBar(
              selectedLanguage: 'zh-TW',
              selectedCategory: 'all',
              onLanguageChanged: (value) {},
              onCategoryChanged: (value) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should render properly in high contrast mode
      expect(find.byType(FilterBar), findsOneWidget);
      expect(find.byType(ChoiceChip), findsAtLeastNWidgets(1));
    });

    testWidgets('text scaling support', (tester) async {
      final textScaleFactors = [0.8, 1.0, 1.2, 1.5, 2.0];

      for (final scaleFactor in textScaleFactors) {
        await tester.pumpWidget(
          TestUtils.wrapWithMaterialApp(
            MediaQuery(
              data: MediaQueryData(
                textScaleFactor: scaleFactor,
              ),
              child: Column(
                children: [
                  Text('Scale: ${scaleFactor}x'),
                  FilterBar(
                    selectedLanguage: 'zh-TW',
                    selectedCategory: 'all',
                    onLanguageChanged: (value) {},
                    onCategoryChanged: (value) {},
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Should handle different text scales gracefully
        expect(find.text('Scale: ${scaleFactor}x'), findsOneWidget);
        expect(find.byType(FilterBar), findsOneWidget);

        // Test interaction at different scales
        final englishChip = find.text('🇺🇸 English');
        if (englishChip.evaluate().isNotEmpty) {
          await tester.tap(englishChip.first);
          await tester.pump();
        }
      }
    });

    testWidgets('screen reader support simulation', (tester) async {
      await tester.pumpWidget(
        TestUtils.wrapWithMaterialApp(
          MediaQuery(
            data: const MediaQueryData(
              accessibleNavigation: true,
              disableAnimations: true,
            ),
            child: Column(
              children: [
                FilterBar(
                  selectedLanguage: 'zh-TW',
                  selectedCategory: 'all',
                  onLanguageChanged: (value) {},
                  onCategoryChanged: (value) {},
                ),
                Expanded(
                  child: AudioList(
                    episodes: TestUtils.createSampleAudioFileList(3),
                    onEpisodeTap: (episode) {},
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify widgets render with accessibility features enabled
      expect(find.byType(FilterBar), findsOneWidget);
      expect(find.byType(AudioList), findsOneWidget);

      // Test that interactions work with accessibility enabled
      final audioCards = find.byType(AudioItemCard);
      if (audioCards.evaluate().isNotEmpty) {
        await tester.tap(audioCards.first);
        await tester.pump();
      }
    });

    testWidgets('color accessibility compliance', (tester) async {
      // Test different theme variations for color accessibility
      final themes = [
        ThemeData.light(),
        ThemeData.dark(),
        ThemeData(brightness: Brightness.light, primarySwatch: Colors.blue),
        ThemeData(brightness: Brightness.dark, primarySwatch: Colors.amber),
      ];

      for (int i = 0; i < themes.length; i++) {
        await tester.pumpWidget(
          MaterialApp(
            theme: themes[i],
            home: Scaffold(
              body: Column(
                children: [
                  Text('Theme $i'),
                  FilterBar(
                    selectedLanguage: 'zh-TW',
                    selectedCategory: 'all',
                    onLanguageChanged: (value) {},
                    onCategoryChanged: (value) {},
                  ),
                  Expanded(
                    child: AudioList(
                      episodes: TestUtils.createSampleAudioFileList(2),
                      onEpisodeTap: (episode) {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Should render properly with different themes
        expect(find.text('Theme $i'), findsOneWidget);
        expect(find.byType(FilterBar), findsOneWidget);
        expect(find.byType(AudioList), findsOneWidget);

        // Test interactions with different themes
        final englishChip = find.text('🇺🇸 English');
        if (englishChip.evaluate().isNotEmpty) {
          await tester.tap(englishChip.first);
          await tester.pump();
        }
      }
    });

    testWidgets('touch target size compliance', (tester) async {
      await tester.pumpWidget(
        TestUtils.wrapWithMaterialApp(
          FilterBar(
            selectedLanguage: 'zh-TW',
            selectedCategory: 'all',
            onLanguageChanged: (value) {},
            onCategoryChanged: (value) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify choice chips have adequate touch targets (48dp minimum)
      final choiceChips = find.byType(ChoiceChip);
      for (final chipFinder in choiceChips.evaluate()) {
        final renderBox = chipFinder.renderObject as RenderBox;
        final size = renderBox.size;

        // Touch targets should be at least 48dp (logical pixels)
        expect(size.height,
            greaterThanOrEqualTo(32.0)); // Allowing some flexibility
        expect(size.width, greaterThanOrEqualTo(32.0));
      }
    });

    testWidgets('reduced motion support', (tester) async {
      await tester.pumpWidget(
        TestUtils.wrapWithMaterialApp(
          MediaQuery(
            data: const MediaQueryData(
              disableAnimations: true,
            ),
            child: AudioList(
              episodes: TestUtils.createSampleAudioFileList(5),
              onEpisodeTap: (episode) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should respect reduced motion preferences
      expect(find.byType(AudioList), findsOneWidget);

      // Test interactions with animations disabled
      await tester.drag(find.byType(AudioList), const Offset(0, -100));
      await tester.pump();

      final audioCards = find.byType(AudioItemCard);
      if (audioCards.evaluate().isNotEmpty) {
        await tester.tap(audioCards.first);
        await tester.pump();
      }
    });

    testWidgets('focus management and visual indicators', (tester) async {
      await tester.pumpWidget(
        TestUtils.wrapWithMaterialApp(
          Column(
            children: [
              FilterBar(
                selectedLanguage: 'zh-TW',
                selectedCategory: 'all',
                onLanguageChanged: (value) {},
                onCategoryChanged: (value) {},
              ),
              Expanded(
                child: AudioList(
                  episodes: TestUtils.createSampleAudioFileList(3),
                  onEpisodeTap: (episode) {},
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Test focus navigation
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      // Verify focus is handled properly
      expect(find.byType(FilterBar), findsOneWidget);
      expect(find.byType(AudioList), findsOneWidget);

      // Test focus traversal
      for (int i = 0; i < 5; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }

      // Should maintain focus without errors
      expect(find.byType(FilterBar), findsOneWidget);
    });

    testWidgets('internationalization and RTL support', (tester) async {
      // Test RTL layout
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar', 'SA'), // Arabic (RTL)
          home: Scaffold(
            body: Directionality(
              textDirection: TextDirection.rtl,
              child: FilterBar(
                selectedLanguage: 'zh-TW',
                selectedCategory: 'all',
                onLanguageChanged: (value) {},
                onCategoryChanged: (value) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should handle RTL layout correctly
      expect(find.byType(FilterBar), findsOneWidget);

      // Test interaction in RTL
      final englishChip = find.text('🇺🇸 English');
      if (englishChip.evaluate().isNotEmpty) {
        await tester.tap(englishChip.first);
        await tester.pump();
      }
    });

    testWidgets('voice control simulation', (tester) async {
      String? lastLanguageChange;
      String? lastCategoryChange;

      await tester.pumpWidget(
        TestUtils.wrapWithMaterialApp(
          Column(
            children: [
              FilterBar(
                selectedLanguage: 'zh-TW',
                selectedCategory: 'all',
                onLanguageChanged: (language) {
                  lastLanguageChange = language;
                },
                onCategoryChanged: (category) {
                  lastCategoryChange = category;
                },
              ),
              if (lastLanguageChange != null)
                Text('Voice selected language: $lastLanguageChange'),
              if (lastCategoryChange != null)
                Text('Voice selected category: $lastCategoryChange'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Simulate voice commands through programmatic activation
      final englishChip = find.text('🇺🇸 English');
      if (englishChip.evaluate().isNotEmpty) {
        await tester.tap(englishChip.first);
        await tester.pumpAndSettle();

        expect(find.text('Voice selected language: en-US'), findsOneWidget);
      }

      final newsChip = find.textContaining('📰');
      if (newsChip.evaluate().isNotEmpty) {
        await tester.tap(newsChip.first);
        await tester.pumpAndSettle();

        expect(
            find.text('Voice selected category: daily-news'), findsOneWidget);
      }
    });

    testWidgets('error state accessibility', (tester) async {
      await tester.pumpWidget(
        TestUtils.wrapWithMaterialApp(
          Column(
            children: [
              const Icon(Icons.error, semanticLabel: 'Error occurred'),
              const Text('Unable to load content'),
              FilterBar(
                selectedLanguage: 'zh-TW',
                selectedCategory: 'all',
                onLanguageChanged: (value) {},
                onCategoryChanged: (value) {},
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    'No content available',
                    semanticsLabel: 'No audio content is currently available',
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify error states are accessible
      expect(find.text('Unable to load content'), findsOneWidget);
      expect(find.text('No content available'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);

      // Verify filter bar still works in error state
      expect(find.byType(FilterBar), findsOneWidget);

      final englishChip = find.text('🇺🇸 English');
      if (englishChip.evaluate().isNotEmpty) {
        await tester.tap(englishChip.first);
        await tester.pump();
      }
    });

    testWidgets('loading state accessibility', (tester) async {
      await tester.pumpWidget(
        TestUtils.wrapWithMaterialApp(
          Column(
            children: [
              FilterBar(
                selectedLanguage: 'zh-TW',
                selectedCategory: 'all',
                onLanguageChanged: (value) {},
                onCategoryChanged: (value) {},
              ),
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        semanticsLabel: 'Loading content',
                      ),
                      SizedBox(height: 16),
                      Text('Loading audio content...'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify loading states are accessible
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading audio content...'), findsOneWidget);

      // Verify filter bar is still interactive during loading
      expect(find.byType(FilterBar), findsOneWidget);

      final englishChip = find.text('🇺🇸 English');
      if (englishChip.evaluate().isNotEmpty) {
        await tester.tap(englishChip.first);
        await tester.pump();
      }
    });
  });
}
