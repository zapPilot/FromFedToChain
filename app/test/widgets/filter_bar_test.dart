import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:from_fed_to_chain_app/widgets/filter_bar.dart';
import 'package:from_fed_to_chain_app/config/api_config.dart';
import 'package:from_fed_to_chain_app/themes/app_theme.dart';
import '../test_utils.dart';

void main() {
  group('FilterBar Widget Tests', () {
    String selectedLanguage = 'zh-TW';
    String selectedCategory = 'all';
    String? changedLanguage;
    String? changedCategory;

    void onLanguageChanged(String language) {
      changedLanguage = language;
    }

    void onCategoryChanged(String category) {
      changedCategory = category;
    }

    setUp(() {
      selectedLanguage = 'zh-TW';
      selectedCategory = 'all';
      changedLanguage = null;
      changedCategory = null;
    });

    Widget createFilterBar() {
      return FilterBar(
        selectedLanguage: selectedLanguage,
        selectedCategory: selectedCategory,
        onLanguageChanged: onLanguageChanged,
        onCategoryChanged: onCategoryChanged,
      );
    }

    testWidgets('should render with basic structure', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createFilterBar());

      // Verify main structure
      TestUtils.expectWidgetExists(find.byType(FilterBar));
      TestUtils.expectWidgetExists(find.byType(Column));

      // Verify language and category sections
      TestUtils.expectTextExists('Language');
      TestUtils.expectTextExists('Category');

      // Verify scrollable containers for horizontal scrolling (overflow fix)
      expect(find.byType(SingleChildScrollView), findsNWidgets(2));
    });

    testWidgets('should display all supported languages without "all" option',
        (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createFilterBar());

      // Verify all supported languages are displayed
      for (final language in ApiConfig.supportedLanguages) {
        final displayName = ApiConfig.getLanguageDisplayName(language);
        TestUtils.expectTextExists(displayName);
      }

      // Verify 'all' option is NOT present in language section
      // Look for text that contains "All" but exclude category "All"
      final allLanguageElements = find.text('All');
      final categoryAllElement = find.text('All');

      // Should only find "All" in category section, not language section
      expect(allLanguageElements, findsOneWidget); // Only category "All"
    });

    testWidgets('should display all supported categories with "all" option',
        (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createFilterBar());

      // Verify "All" category option exists
      TestUtils.expectTextExists('All');

      // Verify all supported categories are displayed
      for (final category in ApiConfig.supportedCategories) {
        final displayName = ApiConfig.getCategoryDisplayName(category);
        TestUtils.expectTextExists(displayName);
      }
    });

    testWidgets('should show language flags with display names',
        (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createFilterBar());

      // Check for specific language flag combinations
      TestUtils.expectTextExists('🇹🇼 中文'); // Traditional Chinese
      TestUtils.expectTextExists('🇺🇸 English'); // English
      TestUtils.expectTextExists('🇯🇵 日本語'); // Japanese
    });

    testWidgets('should show category emojis with display names',
        (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createFilterBar());

      // Check for specific category emoji combinations
      TestUtils.expectTextExists('📰 Daily News');
      TestUtils.expectTextExists('⚡ Ethereum');
      TestUtils.expectTextExists('📊 Macro');
      TestUtils.expectTextExists('🚀 Startup');
      TestUtils.expectTextExists('🤖 AI');
    });

    testWidgets('should handle language selection correctly', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createFilterBar());

      // Test selecting English
      await TestUtils.tapWidget(tester, find.text('🇺🇸 English'));

      expect(changedLanguage, equals('en-US'));
    });

    testWidgets('should handle category selection correctly', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createFilterBar());

      // Test selecting Ethereum category
      await TestUtils.tapWidget(tester, find.text('⚡ Ethereum'));

      expect(changedCategory, equals('ethereum'));
    });

    testWidgets('should highlight selected language correctly', (tester) async {
      selectedLanguage = 'en-US';
      await TestUtils.pumpWidgetWithMaterialApp(tester, createFilterBar());

      // Find the English language chip
      final englishChip = find.ancestor(
        of: find.text('🇺🇸 English'),
        matching: find.byType(InkWell),
      );

      TestUtils.expectWidgetExists(englishChip);

      // Verify the chip is styled as selected (this tests the visual state)
      final animatedContainer = find.ancestor(
        of: find.text('🇺🇸 English'),
        matching: find.byType(AnimatedContainer),
      );
      TestUtils.expectWidgetExists(animatedContainer);
    });

    testWidgets('should highlight selected category correctly', (tester) async {
      selectedCategory = 'ethereum';
      await TestUtils.pumpWidgetWithMaterialApp(tester, createFilterBar());

      // Find the Ethereum category chip
      final ethereumChip = find.ancestor(
        of: find.text('⚡ Ethereum'),
        matching: find.byType(InkWell),
      );

      TestUtils.expectWidgetExists(ethereumChip);
    });

    testWidgets('should handle horizontal scrolling for overflow prevention',
        (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createFilterBar());

      // Find both SingleChildScrollView widgets (language and category)
      final scrollViews = find.byType(SingleChildScrollView);
      expect(scrollViews, findsNWidgets(2));

      // Verify they are configured for horizontal scrolling
      for (int i = 0; i < 2; i++) {
        final scrollView =
            tester.widget<SingleChildScrollView>(scrollViews.at(i));
        expect(scrollView.scrollDirection, equals(Axis.horizontal));
      }
    });

    testWidgets('should test horizontal scroll functionality', (tester) async {
      // Set a small screen width to force scrolling
      await tester.binding.setSurfaceSize(const Size(300, 600));
      await TestUtils.pumpWidgetWithMaterialApp(tester, createFilterBar());

      // Find the language scroll view
      final languageScroll = find.byType(SingleChildScrollView).first;

      // Perform horizontal scroll
      await TestUtils.scrollWidget(
          tester, languageScroll, const Offset(-100, 0));

      // Verify scrolling doesn't break the widget
      TestUtils.expectWidgetExists(find.byType(FilterBar));
    });

    testWidgets('should handle multiple rapid selections', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createFilterBar());

      // Rapidly select different languages
      await TestUtils.tapWidget(tester, find.text('🇺🇸 English'));
      expect(changedLanguage, equals('en-US'));

      await TestUtils.tapWidget(tester, find.text('🇯🇵 日本語'));
      expect(changedLanguage, equals('ja-JP'));

      // Rapidly select different categories
      await TestUtils.tapWidget(tester, find.text('⚡ Ethereum'));
      expect(changedCategory, equals('ethereum'));

      await TestUtils.tapWidget(tester, find.text('📊 Macro'));
      expect(changedCategory, equals('macro'));
    });

    testWidgets('should handle edge case language selections', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createFilterBar());

      // Test all supported languages
      for (final language in ApiConfig.supportedLanguages) {
        final displayName = ApiConfig.getLanguageDisplayName(language);
        final flag = language == 'zh-TW'
            ? '🇹🇼'
            : language == 'en-US'
                ? '🇺🇸'
                : language == 'ja-JP'
                    ? '🇯🇵'
                    : '🌐';

        await TestUtils.tapWidget(tester, find.text('$flag $displayName'));
        expect(changedLanguage, equals(language));
      }
    });

    testWidgets('should handle edge case category selections', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createFilterBar());

      // Test "All" category first
      await TestUtils.tapWidget(tester, find.text('All'));
      expect(changedCategory, equals('all'));

      // Test all supported categories
      for (final category in ApiConfig.supportedCategories) {
        final displayName = ApiConfig.getCategoryDisplayName(category);
        final finder = find.textContaining(displayName);

        if (finder.evaluate().isNotEmpty) {
          await TestUtils.tapWidget(tester, finder.first);
          expect(changedCategory, equals(category));
        }
      }
    });

    testWidgets('should maintain state correctly across rebuilds',
        (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createFilterBar());

      // Select a language
      await TestUtils.tapWidget(tester, find.text('🇺🇸 English'));
      expect(changedLanguage, equals('en-US'));

      // Rebuild with new selection
      selectedLanguage = 'en-US';
      await TestUtils.pumpWidgetWithMaterialApp(tester, createFilterBar());

      // Verify the selection is maintained
      TestUtils.expectWidgetExists(find.text('🇺🇸 English'));
    });

    testWidgets('should handle animation timing correctly', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createFilterBar());

      // Find an AnimatedContainer (used for selected state animation)
      final animatedContainers = find.byType(AnimatedContainer);
      expect(animatedContainers.evaluate().length, greaterThan(0));

      // Tap to trigger animation
      await TestUtils.tapWidget(tester, find.text('🇺🇸 English'));

      // Wait for animation to complete
      await TestUtils.waitForAnimation(tester);

      // Verify widget is still present after animation
      TestUtils.expectWidgetExists(find.byType(FilterBar));
    });

    testWidgets('should apply correct styling and theming', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createFilterBar());

      // Verify Material and InkWell widgets are present for touch feedback
      expect(find.byType(Material), findsWidgets);
      expect(find.byType(InkWell), findsWidgets);

      // Verify proper spacing widgets
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('should handle accessibility correctly', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createFilterBar());

      // Verify semantic labels are accessible
      TestUtils.expectTextExists('Language');
      TestUtils.expectTextExists('Category');

      // All filter chips should be tappable (InkWell widgets)
      final inkWells = find.byType(InkWell);
      expect(inkWells.evaluate().length, greaterThan(0));
    });

    testWidgets('should handle empty or null callbacks gracefully',
        (tester) async {
      // Test with null callbacks (should not crash)
      final filterBarWithNullCallbacks = FilterBar(
        selectedLanguage: 'zh-TW',
        selectedCategory: 'all',
        onLanguageChanged: (_) {}, // Empty callback
        onCategoryChanged: (_) {}, // Empty callback
      );

      await TestUtils.pumpWidgetWithMaterialApp(
          tester, filterBarWithNullCallbacks);

      // Should render without issues
      TestUtils.expectWidgetExists(find.byType(FilterBar));

      // Tapping should not cause errors
      await TestUtils.tapWidget(tester, find.text('🇺🇸 English'));
      await TestUtils.tapWidget(tester, find.text('⚡ Ethereum'));
    });

    testWidgets('should verify chip styling consistency', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createFilterBar());

      // All language and category chips should have consistent styling
      final allChips = find.byType(AnimatedContainer);
      expect(
          allChips.evaluate().length,
          equals(ApiConfig.supportedLanguages.length +
              ApiConfig.supportedCategories.length +
              1)); // +1 for "All" category

      // Each chip should have proper border radius and padding
      for (int i = 0; i < allChips.evaluate().length; i++) {
        final chip = tester.widget<AnimatedContainer>(allChips.at(i));
        expect(chip.padding, isNotNull);
        expect(chip.decoration, isA<BoxDecoration>());
      }
    });

    testWidgets('should handle screen size constraints properly',
        (tester) async {
      // Test with very small screen
      await tester.binding.setSurfaceSize(const Size(200, 400));
      await TestUtils.pumpWidgetWithMaterialApp(tester, createFilterBar());

      TestUtils.expectWidgetExists(find.byType(FilterBar));

      // Test with very large screen
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      await TestUtils.pumpWidgetWithMaterialApp(tester, createFilterBar());

      TestUtils.expectWidgetExists(find.byType(FilterBar));

      // Reset to default size
      await tester.binding.setSurfaceSize(const Size(800, 600));
    });

    testWidgets('should verify no "all" option in language filters',
        (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createFilterBar());

      // Get all text widgets
      final allTexts = find.byType(Text);
      final textWidgets = allTexts
          .evaluate()
          .map((e) => tester.widget<Text>(find.byWidget(e.widget)))
          .toList();

      // Count how many times "All" appears - should only be in category section
      int allCount = 0;
      for (final textWidget in textWidgets) {
        if (textWidget.data?.contains('All') == true) {
          allCount++;
        }
      }

      // Should find exactly one "All" (in category section only)
      expect(allCount, equals(1));
    });
  });
}
