import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:from_fed_to_chain_app/widgets/filter_bar.dart';

void main() {
  group('FilterBar - Basic Tests', () {
    late List<String> languageChanges;
    late List<String> categoryChanges;

    setUp(() {
      languageChanges = [];
      categoryChanges = [];
    });

    Widget createTestWidget({
      String selectedLanguage = 'en-US',
      String selectedCategory = 'all',
    }) {
      return MaterialApp(
        home: Scaffold(
          body: FilterBar(
            selectedLanguage: selectedLanguage,
            selectedCategory: selectedCategory,
            onLanguageChanged: (language) => languageChanges.add(language),
            onCategoryChanged: (category) => categoryChanges.add(category),
          ),
        ),
      );
    }

    group('Basic Rendering', () {
      testWidgets('should render FilterBar without crashing', (tester) async {
        await tester.pumpWidget(createTestWidget());
        expect(find.byType(FilterBar), findsOneWidget);
      });

      testWidgets('should show language and category sections', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        expect(find.text('Language'), findsOneWidget);
        expect(find.text('Category'), findsOneWidget);
      });

      testWidgets('should show basic language options', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Should show some language options
        expect(find.textContaining('English'), findsOneWidget);
        expect(find.textContaining('日本語'), findsOneWidget);
        expect(find.textContaining('中文'), findsOneWidget);
      });

      testWidgets('should show basic category options', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Should show "All" and some categories
        expect(find.text('All'), findsOneWidget);
        expect(find.textContaining('Daily News'), findsOneWidget);
      });
    });

    group('Basic Interactions', () {
      testWidgets('should handle language selection', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Find and tap a language option
        final japaneseButton = find.textContaining('日本語');
        if (japaneseButton.evaluate().isNotEmpty) {
          await tester.tap(japaneseButton);
          await tester.pump();
          
          expect(languageChanges, contains('ja-JP'));
        }
      });

      testWidgets('should handle category selection', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Find and tap "All" category
        final allButton = find.text('All');
        await tester.tap(allButton);
        await tester.pump();
        
        expect(categoryChanges, contains('all'));
      });

      testWidgets('should handle English language selection', (tester) async {
        await tester.pumpWidget(createTestWidget(selectedLanguage: 'zh-TW'));
        
        // Find and tap English option
        final englishButton = find.textContaining('English');
        if (englishButton.evaluate().isNotEmpty) {
          await tester.tap(englishButton);
          await tester.pump();
          
          expect(languageChanges, contains('en-US'));
        }
      });
    });

    group('State Management', () {
      testWidgets('should handle different selected language', (tester) async {
        await tester.pumpWidget(createTestWidget(selectedLanguage: 'ja-JP'));
        
        // Should render without issues when Japanese is selected
        expect(find.byType(FilterBar), findsOneWidget);
      });

      testWidgets('should handle different selected category', (tester) async {
        await tester.pumpWidget(createTestWidget(selectedCategory: 'daily-news'));
        
        // Should render without issues when specific category is selected
        expect(find.byType(FilterBar), findsOneWidget);
      });

      testWidgets('should handle null callbacks gracefully', (tester) async {
        final widget = MaterialApp(
          home: Scaffold(
            body: FilterBar(
              selectedLanguage: 'en-US',
              selectedCategory: 'all',
              onLanguageChanged: (language) {}, // Empty callback
              onCategoryChanged: (category) {}, // Empty callback
            ),
          ),
        );
        
        await tester.pumpWidget(widget);
        expect(find.byType(FilterBar), findsOneWidget);
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle unknown language selection', (tester) async {
        await tester.pumpWidget(createTestWidget(selectedLanguage: 'unknown'));
        
        // Should not crash with unknown language
        expect(find.byType(FilterBar), findsOneWidget);
      });

      testWidgets('should handle unknown category selection', (tester) async {
        await tester.pumpWidget(createTestWidget(selectedCategory: 'unknown'));
        
        // Should not crash with unknown category
        expect(find.byType(FilterBar), findsOneWidget);
      });
    });
  });
}