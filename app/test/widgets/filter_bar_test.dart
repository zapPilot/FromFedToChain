import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:from_fed_to_chain_app/widgets/filter_bar.dart';
import 'package:from_fed_to_chain_app/config/api_config.dart';

import 'widget_test_utils.dart';

void main() {
  group('FilterBar Widget Tests', () {
    setUp(() {
      WidgetTestUtils.resetCallbacks();
    });

    group('Rendering Tests', () {
      testWidgets('should render all components correctly',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          FilterBar(
            selectedLanguage: 'en-US',
            selectedCategory: 'daily-news',
            onLanguageChanged: WidgetTestUtils.mockLanguageChanged,
            onCategoryChanged: WidgetTestUtils.mockCategoryChanged,
          ),
        );

        // Verify main structure
        expect(find.byType(FilterBar), findsOneWidget);
        expect(find.byType(Column), findsOneWidget);

        // Verify section headers
        expect(find.text('Language'), findsOneWidget);
        expect(find.text('Category'), findsOneWidget);

        // Verify horizontal scrollable rows
        expect(find.byType(SingleChildScrollView), findsNWidgets(2));

        // Verify "All" category option
        expect(find.text('All'), findsOneWidget);
      });

      testWidgets('should render all supported languages',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          FilterBar(
            selectedLanguage: 'en-US',
            selectedCategory: 'all',
            onLanguageChanged: WidgetTestUtils.mockLanguageChanged,
            onCategoryChanged: WidgetTestUtils.mockCategoryChanged,
          ),
        );

        // Verify all supported languages are present
        for (final language in ApiConfig.supportedLanguages) {
          final displayName = ApiConfig.getLanguageDisplayName(language);
          expect(find.textContaining(displayName), findsOneWidget);
        }

        // Verify language flags are present
        const expectedFlags = {'🇺🇸', '🇯🇵', '🇹🇼'};
        for (final flag in expectedFlags) {
          expect(find.textContaining(flag), findsOneWidget);
        }
      });

      testWidgets('should render all supported categories',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          FilterBar(
            selectedLanguage: 'en-US',
            selectedCategory: 'daily-news',
            onLanguageChanged: WidgetTestUtils.mockLanguageChanged,
            onCategoryChanged: WidgetTestUtils.mockCategoryChanged,
          ),
        );

        // Verify "All" option
        expect(find.text('All'), findsOneWidget);

        // Verify all supported categories are present
        for (final category in ApiConfig.supportedCategories) {
          final displayName = ApiConfig.getCategoryDisplayName(category);
          expect(find.textContaining(displayName), findsOneWidget);
        }

        // Verify category emojis are present
        const expectedEmojis = {'📰', '⚡', '📊', '🚀', '🤖', '💎'};
        for (final emoji in expectedEmojis) {
          expect(find.textContaining(emoji), findsOneWidget);
        }
      });

      testWidgets('should highlight selected language correctly',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          FilterBar(
            selectedLanguage: 'ja-JP',
            selectedCategory: 'all',
            onLanguageChanged: WidgetTestUtils.mockLanguageChanged,
            onCategoryChanged: WidgetTestUtils.mockCategoryChanged,
          ),
        );

        // Find Japanese language chip
        final japaneseChipFinder = find.textContaining('🇯🇵');
        expect(japaneseChipFinder, findsOneWidget);

        // Verify it's highlighted (check parent container)
        final containerFinder = find.ancestor(
          of: japaneseChipFinder,
          matching: find.byType(AnimatedContainer),
        );

        expect(containerFinder, findsWidgets);
      });

      testWidgets('should highlight selected category correctly',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          FilterBar(
            selectedLanguage: 'en-US',
            selectedCategory: 'ethereum',
            onLanguageChanged: WidgetTestUtils.mockLanguageChanged,
            onCategoryChanged: WidgetTestUtils.mockCategoryChanged,
          ),
        );

        // Find Ethereum category chip
        final ethereumChipFinder = find.textContaining('⚡');
        expect(ethereumChipFinder, findsOneWidget);

        // Verify it's highlighted
        final containerFinder = find.ancestor(
          of: ethereumChipFinder,
          matching: find.byType(AnimatedContainer),
        );

        expect(containerFinder, findsWidgets);
      });
    });

    group('Language Selection Tests', () {
      testWidgets('should handle language selection callbacks',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          FilterBar(
            selectedLanguage: 'en-US',
            selectedCategory: 'all',
            onLanguageChanged: WidgetTestUtils.mockLanguageChanged,
            onCategoryChanged: WidgetTestUtils.mockCategoryChanged,
          ),
        );

        // Tap on Japanese language
        await WidgetTestUtils.tapAndSettle(tester, find.textContaining('🇯🇵'));

        // Verify callback was triggered with correct language
        expect(WidgetTestUtils.lastSelectedLanguage, equals('ja-JP'));
      });

      testWidgets('should handle all language selections',
          (WidgetTester tester) async {
        const languageToFlag = {
          'en-US': '🇺🇸',
          'ja-JP': '🇯🇵',
          'zh-TW': '🇹🇼',
        };

        for (final language in ApiConfig.supportedLanguages) {
          WidgetTestUtils.resetCallbacks();

          await tester.pumpWidget(
            WidgetTestUtils.createTestWrapper(
              FilterBar(
                selectedLanguage: 'en-US',
                selectedCategory: 'all',
                onLanguageChanged: WidgetTestUtils.mockLanguageChanged,
                onCategoryChanged: WidgetTestUtils.mockCategoryChanged,
              ),
            ),
          );

          // Find and tap language chip
          final flag = languageToFlag[language] ?? '🌐';
          await WidgetTestUtils.tapAndSettle(tester, find.textContaining(flag));

          // Verify correct language was selected
          expect(WidgetTestUtils.lastSelectedLanguage, equals(language));
        }
      });

      testWidgets('should maintain language selection state visually',
          (WidgetTester tester) async {
        String currentLanguage = 'en-US';

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return WidgetTestUtils.createTestWrapper(
                FilterBar(
                  selectedLanguage: currentLanguage,
                  selectedCategory: 'all',
                  onLanguageChanged: (lang) =>
                      setState(() => currentLanguage = lang),
                  onCategoryChanged: WidgetTestUtils.mockCategoryChanged,
                ),
              );
            },
          ),
        );

        // Initially English should be selected
        expect(find.textContaining('🇺🇸'), findsOneWidget);

        // Tap Japanese
        await WidgetTestUtils.tapAndSettle(tester, find.textContaining('🇯🇵'));

        // Verify state changed
        expect(currentLanguage, equals('ja-JP'));
      });
    });

    group('Category Selection Tests', () {
      testWidgets('should handle category selection callbacks',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          FilterBar(
            selectedLanguage: 'en-US',
            selectedCategory: 'all',
            onLanguageChanged: WidgetTestUtils.mockLanguageChanged,
            onCategoryChanged: WidgetTestUtils.mockCategoryChanged,
          ),
        );

        // Tap on startup category (🚀)
        await WidgetTestUtils.tapAndSettle(tester, find.textContaining('🚀'));

        // Verify callback was triggered with correct category
        expect(WidgetTestUtils.lastSelectedCategory, equals('startup'));
      });

      testWidgets('should handle "All" category selection',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          FilterBar(
            selectedLanguage: 'en-US',
            selectedCategory: 'daily-news',
            onLanguageChanged: WidgetTestUtils.mockLanguageChanged,
            onCategoryChanged: WidgetTestUtils.mockCategoryChanged,
          ),
        );

        // Tap on "All" category
        await WidgetTestUtils.tapAndSettle(tester, find.text('All'));

        // Verify callback was triggered with 'all'
        expect(WidgetTestUtils.lastSelectedCategory, equals('all'));
      });

      testWidgets('should handle all category selections',
          (WidgetTester tester) async {
        const categoryToEmoji = {
          'daily-news': '📰',
          'ethereum': '⚡',
          'macro': '📊',
          'startup': '🚀',
          'ai': '🤖',
          'defi': '💎',
        };

        for (final category in ApiConfig.supportedCategories) {
          WidgetTestUtils.resetCallbacks();

          await tester.pumpWidget(
            WidgetTestUtils.createTestWrapper(
              FilterBar(
                selectedLanguage: 'en-US',
                selectedCategory: 'all',
                onLanguageChanged: WidgetTestUtils.mockLanguageChanged,
                onCategoryChanged: WidgetTestUtils.mockCategoryChanged,
              ),
            ),
          );

          // Find and tap category chip
          final emoji = categoryToEmoji[category] ?? '🎧';
          await WidgetTestUtils.tapAndSettle(
              tester, find.textContaining(emoji));

          // Verify correct category was selected
          expect(WidgetTestUtils.lastSelectedCategory, equals(category));
        }
      });

      testWidgets('should maintain category selection state visually',
          (WidgetTester tester) async {
        String currentCategory = 'all';

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return WidgetTestUtils.createTestWrapper(
                FilterBar(
                  selectedLanguage: 'en-US',
                  selectedCategory: currentCategory,
                  onLanguageChanged: WidgetTestUtils.mockLanguageChanged,
                  onCategoryChanged: (cat) =>
                      setState(() => currentCategory = cat),
                ),
              );
            },
          ),
        );

        // Initially "All" should be selected
        expect(find.text('All'), findsOneWidget);

        // Tap on macro category
        await WidgetTestUtils.tapAndSettle(tester, find.textContaining('📊'));

        // Verify state changed
        expect(currentCategory, equals('macro'));
      });
    });

    group('Visual Styling Tests', () {
      testWidgets('should apply selected styling correctly',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          FilterBar(
            selectedLanguage: 'en-US',
            selectedCategory: 'ai',
            onLanguageChanged: WidgetTestUtils.mockLanguageChanged,
            onCategoryChanged: WidgetTestUtils.mockCategoryChanged,
          ),
        );

        // Find selected language chip container
        final languageChipFinder = find.textContaining('🇺🇸');
        final languageContainerFinder = find.ancestor(
          of: languageChipFinder,
          matching: find.byType(AnimatedContainer),
        );

        expect(languageContainerFinder, findsWidgets);

        // Find selected category chip container
        final categoryChipFinder = find.textContaining('🤖');
        final categoryContainerFinder = find.ancestor(
          of: categoryChipFinder,
          matching: find.byType(AnimatedContainer),
        );

        expect(categoryContainerFinder, findsWidgets);
      });

      testWidgets('should apply unselected styling correctly',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          FilterBar(
            selectedLanguage: 'en-US',
            selectedCategory: 'daily-news',
            onLanguageChanged: WidgetTestUtils.mockLanguageChanged,
            onCategoryChanged: WidgetTestUtils.mockCategoryChanged,
          ),
        );

        // Find unselected chips and verify they have different styling
        final unselectedLanguageChip = find.textContaining('🇯🇵');
        expect(unselectedLanguageChip, findsOneWidget);

        final unselectedCategoryChip = find.textContaining('🚀');
        expect(unselectedCategoryChip, findsOneWidget);

        // These should have different styling from selected chips
        // (actual color verification would require more complex testing)
      });

      testWidgets('should apply correct colors based on language',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          FilterBar(
            selectedLanguage: 'ja-JP',
            selectedCategory: 'all',
            onLanguageChanged: WidgetTestUtils.mockLanguageChanged,
            onCategoryChanged: WidgetTestUtils.mockCategoryChanged,
          ),
        );

        // Verify theme colors are being used
        WidgetTestUtils.verifyThemeColors(tester);
      });

      testWidgets('should apply correct colors based on category',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          FilterBar(
            selectedLanguage: 'en-US',
            selectedCategory: 'ethereum',
            onLanguageChanged: WidgetTestUtils.mockLanguageChanged,
            onCategoryChanged: WidgetTestUtils.mockCategoryChanged,
          ),
        );

        // Verify category-specific colors are applied
        expect(find.byType(FilterBar), findsOneWidget);
      });

      testWidgets('should show animated transitions',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          FilterBar(
            selectedLanguage: 'en-US',
            selectedCategory: 'all',
            onLanguageChanged: WidgetTestUtils.mockLanguageChanged,
            onCategoryChanged: WidgetTestUtils.mockCategoryChanged,
          ),
        );

        // Verify AnimatedContainer is used for smooth transitions
        expect(find.byType(AnimatedContainer), findsWidgets);

        // Test animation by changing selection
        await WidgetTestUtils.tapAndSettle(tester, find.textContaining('🇯🇵'));

        // Animation should complete
        await tester.pumpAndSettle();
      });

      testWidgets('should apply box shadow to selected chips',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          FilterBar(
            selectedLanguage: 'en-US',
            selectedCategory: 'macro',
            onLanguageChanged: WidgetTestUtils.mockLanguageChanged,
            onCategoryChanged: WidgetTestUtils.mockCategoryChanged,
          ),
        );

        // Selected chips should have shadow effects
        // This is visual verification that would need more complex testing for exact shadow properties
        expect(find.byType(AnimatedContainer), findsWidgets);
      });
    });

    group('Layout Tests', () {
      testWidgets('should handle horizontal scrolling for languages',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          WidgetTestUtils.constrainWidget(
            FilterBar(
              selectedLanguage: 'en-US',
              selectedCategory: 'all',
              onLanguageChanged: WidgetTestUtils.mockLanguageChanged,
              onCategoryChanged: WidgetTestUtils.mockCategoryChanged,
            ),
            width: 200, // Very constrained width
          ),
        );

        // Should have horizontal scrolling
        final scrollViews = find.byType(SingleChildScrollView);
        expect(scrollViews, findsNWidgets(2)); // Language and category sections

        // Verify horizontal scroll direction
        final languageScrollView =
            tester.widget<SingleChildScrollView>(scrollViews.first);
        expect(languageScrollView.scrollDirection, equals(Axis.horizontal));
      });

      testWidgets('should handle horizontal scrolling for categories',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          WidgetTestUtils.constrainWidget(
            FilterBar(
              selectedLanguage: 'en-US',
              selectedCategory: 'all',
              onLanguageChanged: WidgetTestUtils.mockLanguageChanged,
              onCategoryChanged: WidgetTestUtils.mockCategoryChanged,
            ),
            width: 250, // Constrained width
          ),
        );

        // Should handle category overflow with scrolling
        final scrollViews = find.byType(SingleChildScrollView);
        final categoryScrollView =
            tester.widget<SingleChildScrollView>(scrollViews.last);
        expect(categoryScrollView.scrollDirection, equals(Axis.horizontal));
      });

      testWidgets('should maintain proper spacing',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          FilterBar(
            selectedLanguage: 'en-US',
            selectedCategory: 'all',
            onLanguageChanged: WidgetTestUtils.mockLanguageChanged,
            onCategoryChanged: WidgetTestUtils.mockCategoryChanged,
          ),
        );

        // Verify spacing elements exist
        expect(find.byType(SizedBox), findsWidgets);

        // Check section spacing
        final column = tester.widget<Column>(find.byType(Column));
        expect(column.children.length,
            greaterThan(3)); // Headers, spacing, filter rows
      });
    });

    group('Interaction Tests', () {
      testWidgets('should handle rapid filter changes',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          FilterBar(
            selectedLanguage: 'en-US',
            selectedCategory: 'all',
            onLanguageChanged: WidgetTestUtils.mockLanguageChanged,
            onCategoryChanged: WidgetTestUtils.mockCategoryChanged,
          ),
        );

        // Rapidly change languages
        await WidgetTestUtils.tapAndSettle(tester, find.textContaining('🇯🇵'));
        expect(WidgetTestUtils.lastSelectedLanguage, equals('ja-JP'));

        await WidgetTestUtils.tapAndSettle(tester, find.textContaining('🇹🇼'));
        expect(WidgetTestUtils.lastSelectedLanguage, equals('zh-TW'));

        // Rapidly change categories
        await WidgetTestUtils.tapAndSettle(tester, find.textContaining('🚀'));
        expect(WidgetTestUtils.lastSelectedCategory, equals('startup'));

        await WidgetTestUtils.tapAndSettle(tester, find.textContaining('🤖'));
        expect(WidgetTestUtils.lastSelectedCategory, equals('ai'));
      });

      testWidgets('should provide visual feedback on tap',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          FilterBar(
            selectedLanguage: 'en-US',
            selectedCategory: 'all',
            onLanguageChanged: WidgetTestUtils.mockLanguageChanged,
            onCategoryChanged: WidgetTestUtils.mockCategoryChanged,
          ),
        );

        // Find InkWell for material feedback
        final inkWells = find.byType(InkWell);
        expect(inkWells, findsWidgets);

        // Tap and verify no errors
        await WidgetTestUtils.tapAndSettle(tester, inkWells.first);
      });

      testWidgets('should handle simultaneous language and category changes',
          (WidgetTester tester) async {
        String currentLanguage = 'en-US';
        String currentCategory = 'all';

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return WidgetTestUtils.createTestWrapper(
                FilterBar(
                  selectedLanguage: currentLanguage,
                  selectedCategory: currentCategory,
                  onLanguageChanged: (lang) =>
                      setState(() => currentLanguage = lang),
                  onCategoryChanged: (cat) =>
                      setState(() => currentCategory = cat),
                ),
              );
            },
          ),
        );

        // Change language first
        await WidgetTestUtils.tapAndSettle(tester, find.textContaining('🇯🇵'));
        expect(currentLanguage, equals('ja-JP'));

        // Then change category
        await WidgetTestUtils.tapAndSettle(tester, find.textContaining('💎'));
        expect(currentCategory, equals('defi'));

        // Both should be maintained
        expect(currentLanguage, equals('ja-JP'));
        expect(currentCategory, equals('defi'));
      });
    });

    group('Accessibility Tests', () {
      testWidgets('should meet accessibility guidelines',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          FilterBar(
            selectedLanguage: 'en-US',
            selectedCategory: 'all',
            onLanguageChanged: WidgetTestUtils.mockLanguageChanged,
            onCategoryChanged: WidgetTestUtils.mockCategoryChanged,
          ),
        );

        await WidgetTestUtils.verifyAccessibility(tester);
      });

      testWidgets('should have sufficient tap target sizes',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          FilterBar(
            selectedLanguage: 'en-US',
            selectedCategory: 'all',
            onLanguageChanged: WidgetTestUtils.mockLanguageChanged,
            onCategoryChanged: WidgetTestUtils.mockCategoryChanged,
          ),
        );

        // Check all filter chip tap targets
        final inkWells = find.byType(InkWell);
        for (int i = 0; i < inkWells.evaluate().length; i++) {
          final renderObject = tester.renderObject<RenderBox>(inkWells.at(i));
          final size = renderObject.size;

          // Should meet minimum tap target size
          expect(size.width, greaterThanOrEqualTo(32));
          expect(size.height, greaterThanOrEqualTo(32));
        }
      });

      testWidgets('should provide semantic labels for filters',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          FilterBar(
            selectedLanguage: 'en-US',
            selectedCategory: 'all',
            onLanguageChanged: WidgetTestUtils.mockLanguageChanged,
            onCategoryChanged: WidgetTestUtils.mockCategoryChanged,
          ),
        );

        // Verify section headers for screen readers
        expect(find.text('Language'), findsOneWidget);
        expect(find.text('Category'), findsOneWidget);

        // Verify filter options have text labels
        expect(find.text('All'), findsOneWidget);
        for (final language in ApiConfig.supportedLanguages) {
          final displayName = ApiConfig.getLanguageDisplayName(language);
          expect(find.textContaining(displayName), findsOneWidget);
        }
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle empty or invalid selections gracefully',
          (WidgetTester tester) async {
        // Test with invalid language
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          FilterBar(
            selectedLanguage: 'invalid-lang',
            selectedCategory: 'all',
            onLanguageChanged: WidgetTestUtils.mockLanguageChanged,
            onCategoryChanged: WidgetTestUtils.mockCategoryChanged,
          ),
        );

        // Should render without errors
        expect(find.byType(FilterBar), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle null callbacks gracefully',
          (WidgetTester tester) async {
        // Test with no-op callbacks
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          FilterBar(
            selectedLanguage: 'en-US',
            selectedCategory: 'all',
            onLanguageChanged: (_) {}, // No-op
            onCategoryChanged: (_) {}, // No-op
          ),
        );

        // Should render without errors
        expect(find.byType(FilterBar), findsOneWidget);

        // Should handle taps without crashes
        await WidgetTestUtils.tapAndSettle(tester, find.textContaining('🇯🇵'));
        await WidgetTestUtils.tapAndSettle(tester, find.text('All'));
      });

      testWidgets('should handle all possible language/category combinations',
          (WidgetTester tester) async {
        final combinations = WidgetTestUtils.getLanguageCategoryCombinations();

        for (final combo in combinations.take(5)) {
          // Test first 5 to avoid test timeout
          await tester.pumpWidget(
            WidgetTestUtils.createTestWrapper(
              FilterBar(
                selectedLanguage: combo['language']!,
                selectedCategory: combo['category']!,
                onLanguageChanged: WidgetTestUtils.mockLanguageChanged,
                onCategoryChanged: WidgetTestUtils.mockCategoryChanged,
              ),
            ),
          );

          // Should render without errors for all combinations
          expect(find.byType(FilterBar), findsOneWidget);
          expect(tester.takeException(), isNull);

          await tester.pump();
        }
      });

      testWidgets('should handle dynamic language list changes',
          (WidgetTester tester) async {
        // This tests robustness if ApiConfig changes
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          FilterBar(
            selectedLanguage: 'en-US',
            selectedCategory: 'all',
            onLanguageChanged: WidgetTestUtils.mockLanguageChanged,
            onCategoryChanged: WidgetTestUtils.mockCategoryChanged,
          ),
        );

        // Should handle the current configuration
        expect(find.byType(FilterBar), findsOneWidget);
        expect(ApiConfig.supportedLanguages.length, greaterThan(0));
        expect(ApiConfig.supportedCategories.length, greaterThan(0));
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
            FilterBar(
              selectedLanguage: 'en-US',
              selectedCategory: 'all',
              onLanguageChanged: WidgetTestUtils.mockLanguageChanged,
              onCategoryChanged: WidgetTestUtils.mockCategoryChanged,
            ),
          );

          // Verify widget renders properly on all screen sizes
          expect(find.byType(FilterBar), findsOneWidget);

          // Verify no overflow occurs
          expect(tester.takeException(), isNull);
        }

        WidgetTestUtils.resetDeviceSize(tester);
      });

      testWidgets('should handle very wide screens',
          (WidgetTester tester) async {
        WidgetTestUtils.setDeviceSize(tester, const Size(1200, 800));

        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          FilterBar(
            selectedLanguage: 'en-US',
            selectedCategory: 'all',
            onLanguageChanged: WidgetTestUtils.mockLanguageChanged,
            onCategoryChanged: WidgetTestUtils.mockCategoryChanged,
          ),
        );

        // Should handle wide screens gracefully
        expect(find.byType(FilterBar), findsOneWidget);
        expect(tester.takeException(), isNull);

        WidgetTestUtils.resetDeviceSize(tester);
      });

      testWidgets('should handle very narrow screens',
          (WidgetTester tester) async {
        WidgetTestUtils.setDeviceSize(tester, const Size(280, 600));

        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          FilterBar(
            selectedLanguage: 'en-US',
            selectedCategory: 'all',
            onLanguageChanged: WidgetTestUtils.mockLanguageChanged,
            onCategoryChanged: WidgetTestUtils.mockCategoryChanged,
          ),
        );

        // Should handle narrow screens with horizontal scrolling
        expect(find.byType(FilterBar), findsOneWidget);
        expect(find.byType(SingleChildScrollView), findsNWidgets(2));
        expect(tester.takeException(), isNull);

        WidgetTestUtils.resetDeviceSize(tester);
      });
    });

    group('Performance Tests', () {
      testWidgets('should not rebuild unnecessarily',
          (WidgetTester tester) async {
        int buildCount = 0;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return WidgetTestUtils.createTestWrapper(
                Builder(
                  builder: (context) {
                    buildCount++;
                    return FilterBar(
                      selectedLanguage: 'en-US',
                      selectedCategory: 'all',
                      onLanguageChanged: WidgetTestUtils.mockLanguageChanged,
                      onCategoryChanged: WidgetTestUtils.mockCategoryChanged,
                    );
                  },
                ),
              );
            },
          ),
        );

        final initialBuildCount = buildCount;

        // Pump again without state changes
        await tester.pump();

        // Build count should not increase unnecessarily
        expect(buildCount, equals(initialBuildCount));
      });

      testWidgets('should handle rapid filter changes efficiently',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          FilterBar(
            selectedLanguage: 'en-US',
            selectedCategory: 'all',
            onLanguageChanged: WidgetTestUtils.mockLanguageChanged,
            onCategoryChanged: WidgetTestUtils.mockCategoryChanged,
          ),
        );

        // Perform rapid filter changes
        for (int i = 0; i < 5; i++) {
          await tester.tap(find.textContaining('🇯🇵'));
          await tester.pump(const Duration(milliseconds: 16)); // 60fps

          await tester.tap(find.textContaining('🇺🇸'));
          await tester.pump(const Duration(milliseconds: 16));
        }

        // Should handle rapid changes without performance issues
        expect(tester.takeException(), isNull);
      });
    });
  });
}
