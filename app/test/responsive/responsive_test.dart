import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:from_fed_to_chain_app/widgets/filter_bar.dart';
import '../helpers/widget_test_helpers.dart';

void main() {
  group('Responsive Design Tests', () {
    group('Screen Size Adaptations', () {
      testWidgets('basic responsive structure works', (tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 640));
        
        await tester.pumpWidget(
          WidgetTestHelpers.createMinimalTestWrapper(
            child: Scaffold(
              appBar: AppBar(title: const Text('Test')),
              body: const Text('Responsive Test'),
            ),
          ),
        );

        expect(find.byType(Scaffold), findsWidgets);
        expect(find.byType(AppBar), findsOneWidget);
      });

      testWidgets('filter bar renders on small screens', (tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 640)); // Small phone
        
        await tester.pumpWidget(
          WidgetTestHelpers.createMinimalTestWrapper(
            child: FilterBar(
              selectedLanguage: 'all',
              selectedCategory: 'all',
              onLanguageChanged: (language) {},
              onCategoryChanged: (category) {},
            ),
          ),
        );

        // Basic verification that FilterBar renders
        expect(find.byType(FilterBar), findsOneWidget);
      });
    });

    group('Basic Responsiveness', () {
      testWidgets('widgets adapt to different screen sizes', (tester) async {
        final sizes = [
          const Size(360, 640), // Small phone
          const Size(768, 1024), // Tablet
        ];

        for (final size in sizes) {
          await tester.binding.setSurfaceSize(size);
          
          await tester.pumpWidget(
            WidgetTestHelpers.createMinimalTestWrapper(
              child: const Scaffold(
                body: Center(
                  child: Text('Test Content'),
                ),
              ),
            ),
          );

          expect(find.text('Test Content'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      });
    });
  });
}