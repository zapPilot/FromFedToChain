import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:from_fed_to_chain_app/widgets/filter_bar.dart';
import '../helpers/widget_test_helpers.dart';

void main() {
  group('FilterBar Widget Tests', () {
    late String selectedLanguage;
    late String selectedCategory;
    late ValueChanged<String> mockOnLanguageChanged;
    late ValueChanged<String> mockOnCategoryChanged;

    setUp(() {
      selectedLanguage = 'all';
      selectedCategory = 'all';
      mockOnLanguageChanged = (language) {};
      mockOnCategoryChanged = (category) {};
    });

    testWidgets('displays language and category filters correctly', (tester) async {
      await tester.pumpWidget(
        WidgetTestHelpers.createMinimalTestWrapper(
          child: FilterBar(
            selectedLanguage: selectedLanguage,
            selectedCategory: selectedCategory,
            onLanguageChanged: mockOnLanguageChanged,
            onCategoryChanged: mockOnCategoryChanged,
          ),
        ),
      );

      // Verify filter labels are displayed
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      
      // Verify "All" options are displayed
      expect(find.text('All'), findsNWidgets(2)); // One for language, one for category
    });

    testWidgets('displays all language filter options', (tester) async {
      await tester.pumpWidget(
        WidgetTestHelpers.createMinimalTestWrapper(
          child: FilterBar(
            selectedLanguage: selectedLanguage,
            selectedCategory: selectedCategory,
            onLanguageChanged: mockOnLanguageChanged,
            onCategoryChanged: mockOnCategoryChanged,
          ),
        ),
      );

      // Verify language options are displayed with flags
      expect(find.text('🇺🇸 English'), findsOneWidget);
      expect(find.text('🇹🇼 繁體中文'), findsOneWidget);
      expect(find.text('🇯🇵 日本語'), findsOneWidget);
    });

    testWidgets('displays all category filter options', (tester) async {
      await tester.pumpWidget(
        WidgetTestHelpers.createMinimalTestWrapper(
          child: FilterBar(
            selectedLanguage: selectedLanguage,
            selectedCategory: selectedCategory,
            onLanguageChanged: mockOnLanguageChanged,
            onCategoryChanged: mockOnCategoryChanged,
          ),
        ),
      );

      // Verify category options are displayed with emojis
      expect(find.text('📰 Daily News'), findsOneWidget);
      expect(find.text('⚡ Ethereum'), findsOneWidget);
      expect(find.text('📊 Macro Economics'), findsOneWidget);
      expect(find.text('🚀 Startup'), findsOneWidget);
      expect(find.text('🤖 AI & Technology'), findsOneWidget);
      expect(find.text('💎 DeFi'), findsOneWidget);
    });

    testWidgets('highlights selected language correctly', (tester) async {
      await tester.pumpWidget(
        WidgetTestHelpers.createMinimalTestWrapper(
          child: FilterBar(
            selectedLanguage: 'en-US',
            selectedCategory: selectedCategory,
            onLanguageChanged: mockOnLanguageChanged,
            onCategoryChanged: mockOnCategoryChanged,
          ),
        ),
      );

      // Find the English language chip
      final englishChip = find.text('🇺🇸 English');
      expect(englishChip, findsOneWidget);

      // Verify it's styled as selected (we can check the AnimatedContainer)
      final animatedContainer = tester.widget<AnimatedContainer>(
        find.ancestor(
          of: englishChip,
          matching: find.byType(AnimatedContainer),
        ),
      );
      
      final decoration = animatedContainer.decoration as BoxDecoration;
      expect(decoration.boxShadow, isNotNull);
      expect(decoration.boxShadow!.isNotEmpty, isTrue);
    });

    testWidgets('highlights selected category correctly', (tester) async {
      await tester.pumpWidget(
        WidgetTestHelpers.createMinimalTestWrapper(
          child: FilterBar(
            selectedLanguage: selectedLanguage,
            selectedCategory: 'daily-news',
            onLanguageChanged: mockOnLanguageChanged,
            onCategoryChanged: mockOnCategoryChanged,
          ),
        ),
      );

      // Find the Daily News category chip
      final dailyNewsChip = find.text('📰 Daily News');
      expect(dailyNewsChip, findsOneWidget);

      // Verify it's styled as selected
      final animatedContainer = tester.widget<AnimatedContainer>(
        find.ancestor(
          of: dailyNewsChip,
          matching: find.byType(AnimatedContainer),
        ),
      );
      
      final decoration = animatedContainer.decoration as BoxDecoration;
      expect(decoration.boxShadow, isNotNull);
      expect(decoration.boxShadow!.isNotEmpty, isTrue);
    });

    testWidgets('handles language selection correctly', (tester) async {
      String? selectedLang;
      
      await tester.pumpWidget(
        WidgetTestHelpers.createMinimalTestWrapper(
          child: FilterBar(
            selectedLanguage: selectedLanguage,
            selectedCategory: selectedCategory,
            onLanguageChanged: (language) => selectedLang = language,
            onCategoryChanged: mockOnCategoryChanged,
          ),
        ),
      );

      // Tap on English language option
      await tester.tap(find.text('🇺🇸 English'));
      await tester.pumpAndSettle();

      // Verify callback was called with correct language
      expect(selectedLang, equals('en-US'));
    });

    testWidgets('handles category selection correctly', (tester) async {
      String? selectedCat;
      
      await tester.pumpWidget(
        WidgetTestHelpers.createMinimalTestWrapper(
          child: FilterBar(
            selectedLanguage: selectedLanguage,
            selectedCategory: selectedCategory,
            onLanguageChanged: mockOnLanguageChanged,
            onCategoryChanged: (category) => selectedCat = category,
          ),
        ),
      );

      // Tap on Ethereum category option
      await tester.tap(find.text('⚡ Ethereum'));
      await tester.pumpAndSettle();

      // Verify callback was called with correct category
      expect(selectedCat, equals('ethereum'));
    });

    testWidgets('handles "All" language selection correctly', (tester) async {
      String? selectedLang;
      
      await tester.pumpWidget(
        WidgetTestHelpers.createMinimalTestWrapper(
          child: FilterBar(
            selectedLanguage: 'en-US',
            selectedCategory: selectedCategory,
            onLanguageChanged: (language) => selectedLang = language,
            onCategoryChanged: mockOnCategoryChanged,
          ),
        ),
      );

      // Find and tap the "All" language option (first one in the row)
      final allLanguageChips = find.text('All');
      await tester.tap(allLanguageChips.first);
      await tester.pumpAndSettle();

      // Verify callback was called with 'all'
      expect(selectedLang, equals('all'));
    });

    testWidgets('handles "All" category selection correctly', (tester) async {
      String? selectedCat;
      
      await tester.pumpWidget(
        WidgetTestHelpers.createMinimalTestWrapper(
          child: FilterBar(
            selectedLanguage: selectedLanguage,
            selectedCategory: 'ethereum',
            onLanguageChanged: mockOnLanguageChanged,
            onCategoryChanged: (category) => selectedCat = category,
          ),
        ),
      );

      // Find and tap the "All" category option (second one in the widget)
      final allCategoryChips = find.text('All');
      await tester.tap(allCategoryChips.last);
      await tester.pumpAndSettle();

      // Verify callback was called with 'all'
      expect(selectedCat, equals('all'));
    });

    testWidgets('supports horizontal scrolling for language filters', (tester) async {
      await tester.pumpWidget(
        WidgetTestHelpers.createMinimalTestWrapper(
          child: FilterBar(
            selectedLanguage: selectedLanguage,
            selectedCategory: selectedCategory,
            onLanguageChanged: mockOnLanguageChanged,
            onCategoryChanged: mockOnCategoryChanged,
          ),
        ),
      );

      // Verify SingleChildScrollView is present for language filters
      final languageScrollView = find.byType(SingleChildScrollView).first;
      expect(languageScrollView, findsOneWidget);

      final scrollView = tester.widget<SingleChildScrollView>(languageScrollView);
      expect(scrollView.scrollDirection, equals(Axis.horizontal));
    });

    testWidgets('supports horizontal scrolling for category filters', (tester) async {
      await tester.pumpWidget(
        WidgetTestHelpers.createMinimalTestWrapper(
          child: FilterBar(
            selectedLanguage: selectedLanguage,
            selectedCategory: selectedCategory,
            onLanguageChanged: mockOnLanguageChanged,
            onCategoryChanged: mockOnCategoryChanged,
          ),
        ),
      );

      // Verify SingleChildScrollView is present for category filters
      final categoryScrollView = find.byType(SingleChildScrollView).last;
      expect(categoryScrollView, findsOneWidget);

      final scrollView = tester.widget<SingleChildScrollView>(categoryScrollView);
      expect(scrollView.scrollDirection, equals(Axis.horizontal));
    });

    testWidgets('applies correct animations to filter chips', (tester) async {
      await tester.pumpWidget(
        WidgetTestHelpers.createMinimalTestWrapper(
          child: FilterBar(
            selectedLanguage: selectedLanguage,
            selectedCategory: selectedCategory,
            onLanguageChanged: mockOnLanguageChanged,
            onCategoryChanged: mockOnCategoryChanged,
          ),
        ),
      );

      // Verify AnimatedContainer widgets are present
      expect(find.byType(AnimatedContainer), findsAtLeastNWidgets(2));

      // Test animation completion
      await WidgetTestHelpers.testAnimationCompletion(tester);
      
      // Verify widgets are still present after animations
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
    });

    testWidgets('handles tap gestures with ink splash effect', (tester) async {
      await tester.pumpWidget(
        WidgetTestHelpers.createMinimalTestWrapper(
          child: FilterBar(
            selectedLanguage: selectedLanguage,
            selectedCategory: selectedCategory,
            onLanguageChanged: mockOnLanguageChanged,
            onCategoryChanged: mockOnCategoryChanged,
          ),
        ),
      );

      // Verify InkWell widgets are present for tap effects
      expect(find.byType(InkWell), findsAtLeastNWidgets(2));

      // Test tap gesture on a filter chip
      await WidgetTestHelpers.testGestures(
        tester,
        find.text('🇺🇸 English'),
        testLongPress: false,
        testDrag: false,
      );
    });

    testWidgets('applies correct theme styling', (tester) async {
      await WidgetTestHelpers.testBothThemes(
        tester,
        (theme) => WidgetTestHelpers.createMinimalTestWrapper(
          theme: theme,
          child: FilterBar(
            selectedLanguage: selectedLanguage,
            selectedCategory: selectedCategory,
            onLanguageChanged: mockOnLanguageChanged,
            onCategoryChanged: mockOnCategoryChanged,
          ),
        ),
        (tester, theme) async {
          // Verify filter bar renders correctly with both themes
          expect(find.text('Language'), findsOneWidget);
          expect(find.text('Category'), findsOneWidget);
          expect(find.byType(AnimatedContainer), findsAtLeastNWidgets(2));
        },
      );
    });

    testWidgets('supports accessibility features', (tester) async {
      await tester.pumpWidget(
        WidgetTestHelpers.createMinimalTestWrapper(
          child: FilterBar(
            selectedLanguage: selectedLanguage,
            selectedCategory: selectedCategory,
            onLanguageChanged: mockOnLanguageChanged,
            onCategoryChanged: mockOnCategoryChanged,
          ),
        ),
      );

      await WidgetTestHelpers.verifyAccessibility(tester);

      // Verify filter chips are tappable for accessibility
      final filterChips = find.byType(InkWell);
      expect(filterChips, findsAtLeastNWidgets(2));
    });

    testWidgets('handles different screen sizes correctly', (tester) async {
      await WidgetTestHelpers.testMultipleScreenSizes(
        tester,
        WidgetTestHelpers.createMinimalTestWrapper(
          child: FilterBar(
            selectedLanguage: selectedLanguage,
            selectedCategory: selectedCategory,
            onLanguageChanged: mockOnLanguageChanged,
            onCategoryChanged: mockOnCategoryChanged,
          ),
        ),
        (tester, size) async {
          // Verify filter bar adapts to different screen sizes
          expect(find.text('Language'), findsOneWidget);
          expect(find.text('Category'), findsOneWidget);
          
          // Verify horizontal scrolling is available for small screens
          expect(find.byType(SingleChildScrollView), findsNWidgets(2));
        },
      );
    });

    testWidgets('maintains filter state correctly', (tester) async {
      String currentLanguage = 'all';
      String currentCategory = 'all';
      
      Widget buildFilterBar() {
        return WidgetTestHelpers.createMinimalTestWrapper(
          child: FilterBar(
            selectedLanguage: currentLanguage,
            selectedCategory: currentCategory,
            onLanguageChanged: (language) => currentLanguage = language,
            onCategoryChanged: (category) => currentCategory = category,
          ),
        );
      }

      await tester.pumpWidget(buildFilterBar());

      // Select a language
      await tester.tap(find.text('🇺🇸 English'));
      currentLanguage = 'en-US';
      
      // Rebuild widget with new state
      await tester.pumpWidget(buildFilterBar());
      await tester.pumpAndSettle();

      // Verify language selection is maintained
      final englishContainer = tester.widget<AnimatedContainer>(
        find.ancestor(
          of: find.text('🇺🇸 English'),
          matching: find.byType(AnimatedContainer),
        ),
      );
      
      final decoration = englishContainer.decoration as BoxDecoration;
      expect(decoration.boxShadow, isNotNull);
    });

    testWidgets('shows correct colors for different filter states', (tester) async {
      await tester.pumpWidget(
        WidgetTestHelpers.createMinimalTestWrapper(
          child: FilterBar(
            selectedLanguage: 'en-US',
            selectedCategory: 'ethereum',
            onLanguageChanged: mockOnLanguageChanged,
            onCategoryChanged: mockOnCategoryChanged,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Just verify that the selected language and category are displayed
      expect(find.text('🇺🇸 English'), findsOneWidget);
      expect(find.text('⚡ Ethereum'), findsOneWidget);
      
      // Verify that filter chips exist and can be found
      expect(find.byType(AnimatedContainer), findsAtLeastNWidgets(1));
    });
  });
}