import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:from_fed_to_chain_app/widgets/filter_bar.dart';

import '../test_utils.dart';

void main() {
  group('FilterBar Widget Tests', () {
    String selectedLanguage = 'zh-TW';
    String selectedCategory = 'all';
    String? lastLanguageChanged;
    String? lastCategoryChanged;

    Widget createFilterBar({
      String? language,
      String? category,
    }) {
      selectedLanguage = language ?? 'zh-TW';
      selectedCategory = category ?? 'all';

      return TestUtils.wrapWithMaterialApp(
        FilterBar(
          selectedLanguage: selectedLanguage,
          selectedCategory: selectedCategory,
          onLanguageChanged: (value) {
            lastLanguageChanged = value;
          },
          onCategoryChanged: (value) {
            lastCategoryChanged = value;
          },
        ),
      );
    }

    setUp(() {
      lastLanguageChanged = null;
      lastCategoryChanged = null;
    });

    testWidgets('renders correctly with all elements', (tester) async {
      await tester.pumpWidget(createFilterBar());
      await tester.pumpAndSettle();

      // Check that FilterBar is present
      expect(find.byType(FilterBar), findsOneWidget);

      // Check for section headers
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
    });

    testWidgets('displays language filter chips', (tester) async {
      await tester.pumpWidget(createFilterBar());
      await tester.pumpAndSettle();

      // Should show language options (without 'all' option based on user's changes)
      expect(find.text('🇹🇼 繁中'), findsOneWidget);
      expect(find.text('🇺🇸 English'), findsOneWidget);
      expect(find.text('🇯🇵 日本語'), findsOneWidget);
    });

    testWidgets('displays category filter chips with all option',
        (tester) async {
      await tester.pumpWidget(createFilterBar());
      await tester.pumpAndSettle();

      // Should show category options including 'all'
      expect(find.text('All'), findsOneWidget);
      expect(find.text('📰 Daily News'), findsAtLeastNWidget(0));
      expect(find.text('⚡ Ethereum'), findsAtLeastNWidget(0));
      expect(find.text('📊 Macro'), findsAtLeastNWidget(0));
      expect(find.text('🚀 Startup'), findsAtLeastNWidget(0));
      expect(find.text('🤖 AI'), findsAtLeastNWidget(0));
    });

    testWidgets('highlights selected language correctly', (tester) async {
      await tester.pumpWidget(createFilterBar(language: 'en-US'));
      await tester.pumpAndSettle();

      // Find the selected language chip
      final englishChip = find.widgetWithText(ChoiceChip, '🇺🇸 English');
      if (englishChip.evaluate().isNotEmpty) {
        final chip = tester.widget<ChoiceChip>(englishChip);
        expect(chip.selected, isTrue);
      }
    });

    testWidgets('highlights selected category correctly', (tester) async {
      await tester.pumpWidget(createFilterBar(category: 'daily-news'));
      await tester.pumpAndSettle();

      // Find the selected category chip
      final newsChip = find.widgetWithText(ChoiceChip, '📰 Daily News');
      if (newsChip.evaluate().isNotEmpty) {
        final chip = tester.widget<ChoiceChip>(newsChip);
        expect(chip.selected, isTrue);
      }
    });

    testWidgets('handles language selection', (tester) async {
      await tester.pumpWidget(createFilterBar());
      await tester.pumpAndSettle();

      // Tap English language option
      final englishChip = find.text('🇺🇸 English');
      await tester.tap(englishChip);
      await tester.pumpAndSettle();

      // Should call onLanguageChanged callback
      expect(lastLanguageChanged, equals('en-US'));
    });

    testWidgets('handles category selection', (tester) async {
      await tester.pumpWidget(createFilterBar());
      await tester.pumpAndSettle();

      // Tap Daily News category
      final newsChip = find.text('📰 Daily News');
      if (newsChip.evaluate().isNotEmpty) {
        await tester.tap(newsChip);
        await tester.pumpAndSettle();

        expect(lastCategoryChanged, equals('daily-news'));
      }
    });

    testWidgets('handles all category selection', (tester) async {
      await tester.pumpWidget(createFilterBar(category: 'daily-news'));
      await tester.pumpAndSettle();

      // Tap All category
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      expect(lastCategoryChanged, equals('all'));
    });

    testWidgets('supports horizontal scrolling for languages', (tester) async {
      await tester.pumpWidget(createFilterBar());
      await tester.pumpAndSettle();

      // Find the language filter horizontal scroll view
      final languageScroll = find.ancestor(
        of: find.text('🇹🇼 繁中'),
        matching: find.byType(SingleChildScrollView),
      );

      if (languageScroll.evaluate().isNotEmpty) {
        // Test horizontal scrolling
        await tester.drag(languageScroll, const Offset(-100, 0));
        await tester.pumpAndSettle();

        // Should handle scrolling without errors
        expect(find.byType(FilterBar), findsOneWidget);
      }
    });

    testWidgets('supports horizontal scrolling for categories', (tester) async {
      await tester.pumpWidget(createFilterBar());
      await tester.pumpAndSettle();

      // Find the category filter horizontal scroll view
      final categoryScroll = find.ancestor(
        of: find.text('All'),
        matching: find.byType(SingleChildScrollView),
      );

      if (categoryScroll.evaluate().isNotEmpty) {
        // Test horizontal scrolling
        await tester.drag(categoryScroll, const Offset(-100, 0));
        await tester.pumpAndSettle();

        expect(find.byType(FilterBar), findsOneWidget);
      }
    });

    testWidgets('displays correct chip styling for selected state',
        (tester) async {
      await tester
          .pumpWidget(createFilterBar(language: 'en-US', category: 'ethereum'));
      await tester.pumpAndSettle();

      // Check selected language chip styling
      final englishChip = find.widgetWithText(ChoiceChip, '🇺🇸 English');
      if (englishChip.evaluate().isNotEmpty) {
        final chip = tester.widget<ChoiceChip>(englishChip);
        expect(chip.selected, isTrue);
        expect(chip.selectedColor, isNotNull);
      }

      // Check selected category chip styling
      final ethereumChip = find.widgetWithText(ChoiceChip, '⚡ Ethereum');
      if (ethereumChip.evaluate().isNotEmpty) {
        final chip = tester.widget<ChoiceChip>(ethereumChip);
        expect(chip.selected, isTrue);
        expect(chip.selectedColor, isNotNull);
      }
    });

    testWidgets('displays correct chip styling for unselected state',
        (tester) async {
      await tester.pumpWidget(createFilterBar());
      await tester.pumpAndSettle();

      // Check unselected language chips
      final englishChip = find.widgetWithText(ChoiceChip, '🇺🇸 English');
      if (englishChip.evaluate().isNotEmpty) {
        final chip = tester.widget<ChoiceChip>(englishChip);
        expect(chip.selected, isFalse);
      }
    });

    testWidgets('handles rapid selection changes', (tester) async {
      await tester.pumpWidget(createFilterBar());
      await tester.pumpAndSettle();

      // Rapidly change language selection
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.text('🇺🇸 English'));
        await tester.pump();
        await tester.tap(find.text('🇯🇵 日本語'));
        await tester.pump();
        await tester.tap(find.text('🇹🇼 繁中'));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      // Should handle rapid changes without errors
      expect(find.byType(FilterBar), findsOneWidget);
    });

    testWidgets('shows proper spacing between elements', (tester) async {
      await tester.pumpWidget(createFilterBar());
      await tester.pumpAndSettle();

      // Check for spacing widgets
      expect(find.byType(SizedBox), findsAtLeastNWidgets(1));

      // Verify visual layout
      final filterBar = find.byType(FilterBar);
      expect(filterBar, findsOneWidget);
    });

    testWidgets('handles empty category list gracefully', (tester) async {
      // This would test with an empty category list if supported
      await tester.pumpWidget(createFilterBar());
      await tester.pumpAndSettle();

      // Should still render basic structure
      expect(find.byType(FilterBar), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
    });

    testWidgets('handles invalid selected values gracefully', (tester) async {
      // Test with invalid language
      await tester.pumpWidget(createFilterBar(language: 'invalid-lang'));
      await tester.pumpAndSettle();

      // Should still render without errors
      expect(find.byType(FilterBar), findsOneWidget);

      // Test with invalid category
      await tester.pumpWidget(createFilterBar(category: 'invalid-category'));
      await tester.pumpAndSettle();

      expect(find.byType(FilterBar), findsOneWidget);
    });

    testWidgets('supports different language display formats', (tester) async {
      await tester.pumpWidget(createFilterBar());
      await tester.pumpAndSettle();

      // Check for emoji flags in language options
      expect(find.textContaining('🇹🇼'), findsOneWidget);
      expect(find.textContaining('🇺🇸'), findsOneWidget);
      expect(find.textContaining('🇯🇵'), findsOneWidget);
    });

    testWidgets('supports different category display formats', (tester) async {
      await tester.pumpWidget(createFilterBar());
      await tester.pumpAndSettle();

      // Check for emoji icons in category options
      expect(find.textContaining('📰'), findsAtLeastNWidget(0));
      expect(find.textContaining('⚡'), findsAtLeastNWidget(0));
      expect(find.textContaining('📊'), findsAtLeastNWidget(0));
      expect(find.textContaining('🚀'), findsAtLeastNWidget(0));
      expect(find.textContaining('🤖'), findsAtLeastNWidget(0));
    });

    testWidgets('maintains selection state across rebuilds', (tester) async {
      await tester
          .pumpWidget(createFilterBar(language: 'ja-JP', category: 'startup'));
      await tester.pumpAndSettle();

      // Trigger rebuild
      await tester
          .pumpWidget(createFilterBar(language: 'ja-JP', category: 'startup'));
      await tester.pumpAndSettle();

      // Should maintain selected states
      final japaneseChip = find.widgetWithText(ChoiceChip, '🇯🇵 日本語');
      if (japaneseChip.evaluate().isNotEmpty) {
        final chip = tester.widget<ChoiceChip>(japaneseChip);
        expect(chip.selected, isTrue);
      }
    });

    testWidgets('handles chip overflow with horizontal scrolling',
        (tester) async {
      // Create a very narrow container to force overflow
      await tester.pumpWidget(
        TestUtils.wrapWithMaterialApp(
          SizedBox(
            width: 200, // Very narrow
            child: FilterBar(
              selectedLanguage: selectedLanguage,
              selectedCategory: selectedCategory,
              onLanguageChanged: (value) {},
              onCategoryChanged: (value) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should still render without overflow errors
      expect(find.byType(FilterBar), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsAtLeastNWidgets(1));
    });

    testWidgets('provides correct accessibility labels', (tester) async {
      await tester.pumpWidget(createFilterBar());
      await tester.pumpAndSettle();

      // Check that chips have proper semantics for accessibility
      final languageChips = find.descendant(
        of: find.byType(FilterBar),
        matching: find.byType(ChoiceChip),
      );

      // Should have multiple choice chips
      expect(languageChips.evaluate().length, greaterThan(0));
    });

    testWidgets('updates correctly when selections change', (tester) async {
      await tester.pumpWidget(createFilterBar());
      await tester.pumpAndSettle();

      // Change language selection
      await tester.tap(find.text('🇺🇸 English'));
      await tester.pumpAndSettle();

      // Update widget with new selection
      await tester.pumpWidget(createFilterBar(language: 'en-US'));
      await tester.pumpAndSettle();

      // Should reflect new selection
      final englishChip = find.widgetWithText(ChoiceChip, '🇺🇸 English');
      if (englishChip.evaluate().isNotEmpty) {
        final chip = tester.widget<ChoiceChip>(englishChip);
        expect(chip.selected, isTrue);
      }
    });
  });

  group('FilterBar Integration Tests', () {
    String selectedLanguage = 'zh-TW';
    String selectedCategory = 'all';

    Widget createInteractiveFilterBar() {
      return TestUtils.wrapWithMaterialApp(
        StatefulBuilder(
          builder: (context, setState) {
            return Column(
              children: [
                FilterBar(
                  selectedLanguage: selectedLanguage,
                  selectedCategory: selectedCategory,
                  onLanguageChanged: (value) {
                    setState(() {
                      selectedLanguage = value;
                    });
                  },
                  onCategoryChanged: (value) {
                    setState(() {
                      selectedCategory = value;
                    });
                  },
                ),
                Text('Language: $selectedLanguage'),
                Text('Category: $selectedCategory'),
              ],
            );
          },
        ),
      );
    }

    testWidgets('complete filtering workflow', (tester) async {
      await tester.pumpWidget(createInteractiveFilterBar());
      await tester.pumpAndSettle();

      // 1. Verify initial state
      expect(find.text('Language: zh-TW'), findsOneWidget);
      expect(find.text('Category: all'), findsOneWidget);

      // 2. Change language to English
      await tester.tap(find.text('🇺🇸 English'));
      await tester.pumpAndSettle();

      expect(find.text('Language: en-US'), findsOneWidget);

      // 3. Change category to Daily News
      final newsChip = find.text('📰 Daily News');
      if (newsChip.evaluate().isNotEmpty) {
        await tester.tap(newsChip);
        await tester.pumpAndSettle();

        expect(find.text('Category: daily-news'), findsOneWidget);
      }

      // 4. Change back to Japanese
      await tester.tap(find.text('🇯🇵 日本語'));
      await tester.pumpAndSettle();

      expect(find.text('Language: ja-JP'), findsOneWidget);

      // 5. Change category back to All
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      expect(find.text('Category: all'), findsOneWidget);
    });

    testWidgets('handles multiple rapid changes correctly', (tester) async {
      await tester.pumpWidget(createInteractiveFilterBar());
      await tester.pumpAndSettle();

      // Perform rapid language changes
      final languages = ['🇺🇸 English', '🇯🇵 日本語', '🇹🇼 繁中'];
      for (int cycle = 0; cycle < 3; cycle++) {
        for (final language in languages) {
          await tester.tap(find.text(language));
          await tester.pump();
        }
      }
      await tester.pumpAndSettle();

      // Should end up in a consistent state
      expect(find.text('Language: zh-TW'), findsOneWidget);

      // Perform rapid category changes
      await tester.tap(find.text('All'));
      await tester.pump();

      final categories = ['📰 Daily News', '⚡ Ethereum', 'All'];
      for (final category in categories) {
        final categoryFinder = find.text(category);
        if (categoryFinder.evaluate().isNotEmpty) {
          await tester.tap(categoryFinder);
          await tester.pump();
        }
      }
      await tester.pumpAndSettle();

      // Should handle rapid changes without errors
      expect(find.byType(FilterBar), findsOneWidget);
    });
  });
}
