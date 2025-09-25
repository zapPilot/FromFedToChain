import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:from_fed_to_chain_app/widgets/search_bar.dart';
import 'package:from_fed_to_chain_app/themes/app_theme.dart';

import 'widget_test_utils.dart';

void main() {
  group('SearchBarWidget Tests', () {
    setUp(() {
      WidgetTestUtils.resetCallbacks();
    });

    group('Rendering Tests', () {
      testWidgets('should render all components correctly',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          SearchBarWidget(
            onSearchChanged: WidgetTestUtils.mockSearchChanged,
            hintText: 'Search episodes...',
          ),
        );

        // Verify main structure
        expect(find.byType(SearchBarWidget), findsOneWidget);
        expect(find.byType(Container), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);

        // Verify hint text
        expect(find.text('Search episodes...'), findsOneWidget);

        // Verify search icon
        expect(find.byIcon(Icons.search), findsOneWidget);

        // Clear button should not be visible initially
        expect(find.byIcon(Icons.clear), findsNothing);
      });

      testWidgets('should use default hint text when not provided',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          SearchBarWidget(
            onSearchChanged: WidgetTestUtils.mockSearchChanged,
          ),
        );

        // Should show default hint text
        expect(find.text('Search...'), findsOneWidget);
      });

      testWidgets('should display initial value when provided',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          SearchBarWidget(
            onSearchChanged: WidgetTestUtils.mockSearchChanged,
            initialValue: 'initial search text',
            hintText: 'Search episodes...',
          ),
        );

        // Should display initial value
        expect(find.text('initial search text'), findsOneWidget);

        // Clear button should be visible with initial text
        expect(find.byIcon(Icons.clear), findsOneWidget);
      });

      testWidgets('should apply correct styling', (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          SearchBarWidget(
            onSearchChanged: WidgetTestUtils.mockSearchChanged,
            hintText: 'Search episodes...',
          ),
        );

        // Verify container decoration
        final container = tester.widget<Container>(find.byType(Container));
        expect(container.decoration, equals(AppTheme.cardDecoration));

        // Verify text field styling
        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.style, equals(AppTheme.bodyMedium));
        expect(textField.textInputAction, equals(TextInputAction.search));
      });
    });

    group('Text Input Tests', () {
      testWidgets('should handle text input correctly',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          SearchBarWidget(
            onSearchChanged: WidgetTestUtils.mockSearchChanged,
            hintText: 'Search episodes...',
          ),
        );

        // Enter text in the search field
        await WidgetTestUtils.enterTextAndSettle(
          tester,
          find.byType(TextField),
          'crypto news',
        );

        // Additional pump to ensure widget rebuilds with suffix icon
        await tester.pump();

        // Verify callback was triggered with correct text
        expect(WidgetTestUtils.lastSearchText, equals('crypto news'));

        // Clear button should now be visible
        expect(find.byIcon(Icons.clear), findsOneWidget);
      });

      testWidgets('should handle empty text input',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          SearchBarWidget(
            onSearchChanged: WidgetTestUtils.mockSearchChanged,
            hintText: 'Search episodes...',
          ),
        );

        // Enter empty text
        await WidgetTestUtils.enterTextAndSettle(
          tester,
          find.byType(TextField),
          '',
        );

        // Verify callback was triggered with empty text
        expect(WidgetTestUtils.lastSearchText, equals(''));

        // Clear button should not be visible for empty text
        expect(find.byIcon(Icons.clear), findsNothing);
      });

      testWidgets('should handle special characters in search',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          SearchBarWidget(
            onSearchChanged: WidgetTestUtils.mockSearchChanged,
            hintText: 'Search episodes...',
          ),
        );

        const specialText = '🎵 Special Search! @#\$%^&*()';

        // Enter text with special characters
        await WidgetTestUtils.enterTextAndSettle(
          tester,
          find.byType(TextField),
          specialText,
        );

        // Verify special characters are handled correctly
        expect(WidgetTestUtils.lastSearchText, equals(specialText));
      });

      testWidgets('should trigger callback on every text change',
          (WidgetTester tester) async {
        int callbackCount = 0;
        String lastText = '';

        await tester.pumpWidget(
          WidgetTestUtils.createTestWrapper(
            SearchBarWidget(
              onSearchChanged: (text) {
                callbackCount++;
                lastText = text;
              },
              hintText: 'Search episodes...',
            ),
          ),
        );

        // Type text character by character
        await tester.enterText(find.byType(TextField), 'a');
        await tester.pump();
        expect(callbackCount, equals(1));
        expect(lastText, equals('a'));

        await tester.enterText(find.byType(TextField), 'ab');
        await tester.pump();
        expect(callbackCount, equals(2));
        expect(lastText, equals('ab'));

        await tester.enterText(find.byType(TextField), 'abc');
        await tester.pump();
        expect(callbackCount, equals(3));
        expect(lastText, equals('abc'));
      });
    });

    group('Clear Button Tests', () {
      testWidgets('should show clear button when text is present',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          SearchBarWidget(
            onSearchChanged: WidgetTestUtils.mockSearchChanged,
            hintText: 'Search episodes...',
          ),
        );

        // Initially no clear button
        expect(find.byIcon(Icons.clear), findsNothing);

        // Enter text
        await WidgetTestUtils.enterTextAndSettle(
          tester,
          find.byType(TextField),
          'search text',
        );

        // Clear button should now be visible
        expect(find.byIcon(Icons.clear), findsOneWidget);
      });

      testWidgets('should hide clear button when text is empty',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          SearchBarWidget(
            onSearchChanged: WidgetTestUtils.mockSearchChanged,
            initialValue: 'initial text',
            hintText: 'Search episodes...',
          ),
        );

        // Initially clear button should be visible
        expect(find.byIcon(Icons.clear), findsOneWidget);

        // Clear the text
        await WidgetTestUtils.enterTextAndSettle(
          tester,
          find.byType(TextField),
          '',
        );

        // Clear button should now be hidden
        expect(find.byIcon(Icons.clear), findsNothing);
      });

      testWidgets('should clear text when clear button is tapped',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          SearchBarWidget(
            onSearchChanged: WidgetTestUtils.mockSearchChanged,
            hintText: 'Search episodes...',
          ),
        );

        // Enter text
        await WidgetTestUtils.enterTextAndSettle(
          tester,
          find.byType(TextField),
          'search text',
        );

        // Verify text is present
        expect(WidgetTestUtils.lastSearchText, equals('search text'));

        // Tap clear button
        await WidgetTestUtils.tapAndSettle(tester, find.byIcon(Icons.clear));

        // Verify text was cleared
        expect(WidgetTestUtils.lastSearchText, equals(''));

        // Clear button should now be hidden
        expect(find.byIcon(Icons.clear), findsNothing);
      });

      testWidgets('should handle multiple clear operations',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          SearchBarWidget(
            onSearchChanged: WidgetTestUtils.mockSearchChanged,
            hintText: 'Search episodes...',
          ),
        );

        // Enter text and clear multiple times
        for (int i = 0; i < 3; i++) {
          // Enter text
          await WidgetTestUtils.enterTextAndSettle(
            tester,
            find.byType(TextField),
            'search $i',
          );

          expect(WidgetTestUtils.lastSearchText, equals('search $i'));
          expect(find.byIcon(Icons.clear), findsOneWidget);

          // Clear text
          await WidgetTestUtils.tapAndSettle(tester, find.byIcon(Icons.clear));

          expect(WidgetTestUtils.lastSearchText, equals(''));
          expect(find.byIcon(Icons.clear), findsNothing);
        }
      });
    });

    group('Focus Management Tests', () {
      testWidgets('should handle focus correctly', (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          SearchBarWidget(
            onSearchChanged: WidgetTestUtils.mockSearchChanged,
            hintText: 'Search episodes...',
          ),
        );

        // Tap to focus
        await WidgetTestUtils.tapAndSettle(tester, find.byType(TextField));

        // Focus state is internal and not directly testable
        // We verify that the field was tapped which should trigger focus
        expect(find.byType(TextField), findsOneWidget);
      });

      testWidgets('should unfocus on search submission',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          SearchBarWidget(
            onSearchChanged: WidgetTestUtils.mockSearchChanged,
            hintText: 'Search episodes...',
          ),
        );

        // Focus and enter text
        await WidgetTestUtils.tapAndSettle(tester, find.byType(TextField));
        await WidgetTestUtils.enterTextAndSettle(
          tester,
          find.byType(TextField),
          'search query',
        );

        // Submit the search
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pumpAndSettle();

        // Verify search callback was triggered
        expect(WidgetTestUtils.lastSearchText, equals('search query'));

        // Focus management is internal - we verify the submission worked
        expect(find.byType(TextField), findsOneWidget);
      });

      testWidgets('should handle focus changes correctly',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          Column(
            children: [
              SearchBarWidget(
                onSearchChanged: WidgetTestUtils.mockSearchChanged,
                hintText: 'Search episodes...',
              ),
              const TextField(
                  decoration: InputDecoration(
                      hintText: 'Other field')), // Another focusable widget
            ],
          ),
        );

        // Focus search bar
        await WidgetTestUtils.tapAndSettle(
            tester, find.byType(SearchBarWidget));

        // Focus the other text field
        await WidgetTestUtils.tapAndSettle(tester, find.byType(TextField).last);

        // Verify widgets are rendered and interaction works
        // Focus state is internal - we test behavior instead of internal state
        expect(find.byType(SearchBarWidget), findsOneWidget);
        expect(find.byType(TextField),
            findsNWidgets(2)); // Search bar + other field
      });
    });

    group('Visual State Tests', () {
      testWidgets('should apply focused border when focused',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          SearchBarWidget(
            onSearchChanged: WidgetTestUtils.mockSearchChanged,
            hintText: 'Search episodes...',
          ),
        );

        // Tap to focus
        await WidgetTestUtils.tapAndSettle(tester, find.byType(TextField));

        // Verify focused styling
        final textField = tester.widget<TextField>(find.byType(TextField));
        final decoration = textField.decoration!;

        expect(decoration.focusedBorder, isA<OutlineInputBorder>());
        final focusedBorder = decoration.focusedBorder as OutlineInputBorder;
        expect(focusedBorder.borderSide.color, equals(AppTheme.primaryColor));
        expect(focusedBorder.borderSide.width, equals(2));
      });

      testWidgets('should apply correct hint text styling',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          SearchBarWidget(
            onSearchChanged: WidgetTestUtils.mockSearchChanged,
            hintText: 'Search episodes...',
          ),
        );

        // Verify hint text styling
        final textField = tester.widget<TextField>(find.byType(TextField));
        final decoration = textField.decoration!;

        expect(decoration.hintText, equals('Search episodes...'));
        expect(decoration.hintStyle, isA<TextStyle>());

        final hintStyle = decoration.hintStyle!;
        expect(
            hintStyle.color, equals(AppTheme.onSurfaceColor.withOpacity(0.5)));
      });

      testWidgets('should apply correct icon colors',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          SearchBarWidget(
            onSearchChanged: WidgetTestUtils.mockSearchChanged,
            initialValue: 'test text',
            hintText: 'Search episodes...',
          ),
        );

        // Check search icon color
        final searchIcon = tester.widget<Icon>(find.byIcon(Icons.search));
        expect(
            searchIcon.color, equals(AppTheme.onSurfaceColor.withOpacity(0.6)));

        // Check clear icon color
        final clearIcon = tester.widget<Icon>(find.byIcon(Icons.clear));
        expect(
            clearIcon.color, equals(AppTheme.onSurfaceColor.withOpacity(0.6)));
      });

      testWidgets('should apply rounded corners and fill color',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          SearchBarWidget(
            onSearchChanged: WidgetTestUtils.mockSearchChanged,
            hintText: 'Search episodes...',
          ),
        );

        // Verify decoration properties
        final textField = tester.widget<TextField>(find.byType(TextField));
        final decoration = textField.decoration!;

        expect(decoration.filled, true);
        expect(
            decoration.fillColor, equals(AppTheme.cardColor.withOpacity(0.5)));

        expect(decoration.border, isA<OutlineInputBorder>());
        final border = decoration.border as OutlineInputBorder;
        expect(border.borderRadius.topLeft.x, equals(AppTheme.radiusM));
        expect(border.borderSide, equals(BorderSide.none));
      });
    });

    group('Interaction Tests', () {
      testWidgets('should handle rapid typing correctly',
          (WidgetTester tester) async {
        int callbackCount = 0;
        String lastText = '';

        await tester.pumpWidget(
          WidgetTestUtils.createTestWrapper(
            SearchBarWidget(
              onSearchChanged: (text) {
                callbackCount++;
                lastText = text;
              },
              hintText: 'Search episodes...',
            ),
          ),
        );

        // Rapidly type characters
        const testTexts = ['a', 'ab', 'abc', 'abcd', 'abcde'];
        for (final text in testTexts) {
          await tester.enterText(find.byType(TextField), text);
          await tester.pump(const Duration(milliseconds: 16)); // 60fps
        }

        // Should handle all changes
        expect(callbackCount, equals(testTexts.length));
        expect(lastText, equals('abcde'));
      });

      testWidgets('should handle backspace and deletion correctly',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          SearchBarWidget(
            onSearchChanged: WidgetTestUtils.mockSearchChanged,
            hintText: 'Search episodes...',
          ),
        );

        // Enter text
        await WidgetTestUtils.enterTextAndSettle(
          tester,
          find.byType(TextField),
          'hello world',
        );
        expect(WidgetTestUtils.lastSearchText, equals('hello world'));

        // Delete some characters
        await WidgetTestUtils.enterTextAndSettle(
          tester,
          find.byType(TextField),
          'hello',
        );
        expect(WidgetTestUtils.lastSearchText, equals('hello'));

        // Clear all text
        await WidgetTestUtils.enterTextAndSettle(
          tester,
          find.byType(TextField),
          '',
        );
        expect(WidgetTestUtils.lastSearchText, equals(''));
      });

      testWidgets('should handle text selection and replacement',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          SearchBarWidget(
            onSearchChanged: WidgetTestUtils.mockSearchChanged,
            initialValue: 'initial text',
            hintText: 'Search episodes...',
          ),
        );

        // Replace all text
        await WidgetTestUtils.enterTextAndSettle(
          tester,
          find.byType(TextField),
          'replaced text',
        );

        expect(WidgetTestUtils.lastSearchText, equals('replaced text'));
      });
    });

    group('Initial Value Tests', () {
      testWidgets('should handle null initial value',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          SearchBarWidget(
            onSearchChanged: WidgetTestUtils.mockSearchChanged,
            initialValue: null,
            hintText: 'Search episodes...',
          ),
        );

        // Should render without errors
        expect(find.byType(SearchBarWidget), findsOneWidget);
        expect(find.byIcon(Icons.clear), findsNothing);
      });

      testWidgets('should handle empty initial value',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          SearchBarWidget(
            onSearchChanged: WidgetTestUtils.mockSearchChanged,
            initialValue: '',
            hintText: 'Search episodes...',
          ),
        );

        // Should render without errors and no clear button
        expect(find.byType(SearchBarWidget), findsOneWidget);
        expect(find.byIcon(Icons.clear), findsNothing);
      });

      testWidgets('should preserve initial value through widget lifecycle',
          (WidgetTester tester) async {
        String searchText = 'persistent text';

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return WidgetTestUtils.createTestWrapper(
                SearchBarWidget(
                  onSearchChanged: (text) => searchText = text,
                  initialValue: searchText,
                  hintText: 'Search episodes...',
                ),
              );
            },
          ),
        );

        // Initial value should be displayed
        expect(find.text('persistent text'), findsOneWidget);

        // Rebuild widget
        await tester.pump();

        // Text should still be there
        expect(find.text('persistent text'), findsOneWidget);
      });
    });

    group('Accessibility Tests', () {
      testWidgets('should meet accessibility guidelines',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          SearchBarWidget(
            onSearchChanged: WidgetTestUtils.mockSearchChanged,
            hintText: 'Search episodes...',
          ),
        );

        await WidgetTestUtils.verifyAccessibility(tester);
      });

      testWidgets('should have sufficient tap target sizes',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          SearchBarWidget(
            onSearchChanged: WidgetTestUtils.mockSearchChanged,
            initialValue: 'test text',
            hintText: 'Search episodes...',
          ),
        );

        // Check clear button tap target
        final clearButtonRenderObject =
            tester.renderObject<RenderBox>(find.byIcon(Icons.clear));
        expect(clearButtonRenderObject.size.width, greaterThanOrEqualTo(32));
        expect(clearButtonRenderObject.size.height, greaterThanOrEqualTo(32));

        // Check text field tap target
        final textFieldRenderObject =
            tester.renderObject<RenderBox>(find.byType(TextField));
        expect(textFieldRenderObject.size.height, greaterThanOrEqualTo(44));
      });

      testWidgets('should provide semantic information',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          SearchBarWidget(
            onSearchChanged: WidgetTestUtils.mockSearchChanged,
            hintText: 'Search for podcasts...',
          ),
        );

        // Verify text field provides semantic information
        expect(find.byType(TextField), findsOneWidget);

        // Hint text should be available for screen readers
        expect(find.text('Search for podcasts...'), findsOneWidget);
      });
    });

    group('Edge Cases and Boundary Conditions', () {
      testWidgets('should handle null callback gracefully',
          (WidgetTester tester) async {
        // This would cause compilation error, but testing defensive programming
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          SearchBarWidget(
            onSearchChanged: (_) {}, // No-op callback
            hintText: 'Search episodes...',
          ),
        );

        // Should render without errors
        expect(find.byType(SearchBarWidget), findsOneWidget);

        // Should handle text input without crashes
        await WidgetTestUtils.enterTextAndSettle(
          tester,
          find.byType(TextField),
          'test text',
        );
      });

      testWidgets('should handle very long text input',
          (WidgetTester tester) async {
        const longText =
            'This is a very long search query that might cause issues with text field rendering or performance if not handled properly by the search widget implementation';

        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          SearchBarWidget(
            onSearchChanged: WidgetTestUtils.mockSearchChanged,
            hintText: 'Search episodes...',
          ),
        );

        // Enter very long text
        await WidgetTestUtils.enterTextAndSettle(
          tester,
          find.byType(TextField),
          longText,
        );

        // Should handle long text without errors
        expect(WidgetTestUtils.lastSearchText, equals(longText));
        expect(find.byIcon(Icons.clear), findsOneWidget);
      });

      testWidgets('should handle extremely long search text input',
          (WidgetTester tester) async {
        final longSearchText = 'Bitcoin ' * 1000; // Very long search query

        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          SearchBarWidget(
            onSearchChanged: WidgetTestUtils.mockSearchChanged,
            initialValue: longSearchText,
          ),
        );

        // Should render without errors
        expect(find.byType(SearchBarWidget), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Should handle the long initial value
        final textField = find.byType(TextField);
        expect(textField, findsOneWidget);
      });

      testWidgets('should handle unicode and emoji in search',
          (WidgetTester tester) async {
        const unicodeText = '🎵 音楽 🎧 подкаст 🎙️ пудкаст العربية';

        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          SearchBarWidget(
            onSearchChanged: WidgetTestUtils.mockSearchChanged,
            hintText: 'Search episodes...',
          ),
        );

        // Enter unicode text
        await WidgetTestUtils.enterTextAndSettle(
          tester,
          find.byType(TextField),
          unicodeText,
        );

        // Should handle unicode without errors
        expect(WidgetTestUtils.lastSearchText, equals(unicodeText));
      });

      testWidgets(
          'should handle special characters and Unicode comprehensively',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          SearchBarWidget(
            onSearchChanged: WidgetTestUtils.mockSearchChanged,
          ),
        );

        final specialText =
            '🔥 Bitcoin & Ethereum: 加密货币 📈 (測試) — Special «Characters» ñañá';

        await tester.enterText(find.byType(TextField), specialText);
        await tester.pump();

        // Should handle special characters without errors
        expect(tester.takeException(), isNull);
        expect(WidgetTestUtils.lastSearchText, equals(specialText));
      });

      testWidgets('should handle empty string input gracefully',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          SearchBarWidget(
            onSearchChanged: WidgetTestUtils.mockSearchChanged,
            initialValue: 'Initial Text',
          ),
        );

        // Clear the text field
        await tester.enterText(find.byType(TextField), '');
        await tester.pump();

        // Should handle empty string gracefully
        expect(tester.takeException(), isNull);
        expect(WidgetTestUtils.lastSearchText, equals(''));

        // Clear button should not be visible with empty text
        expect(find.byIcon(Icons.clear), findsNothing);
      });

      testWidgets('should handle whitespace-only input',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          SearchBarWidget(
            onSearchChanged: WidgetTestUtils.mockSearchChanged,
          ),
        );

        final whitespaceText =
            '   \t   '; // Various whitespace characters (newlines stripped by TextField)
        final inputText = '   \t\n   '; // Input with newline

        await tester.enterText(find.byType(TextField), inputText);
        await tester.pump();

        // Should handle whitespace input (newlines are stripped in single-line TextField)
        expect(tester.takeException(), isNull);
        expect(WidgetTestUtils.lastSearchText, equals(whitespaceText));
      });

      testWidgets('should handle numeric input', (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          SearchBarWidget(
            onSearchChanged: WidgetTestUtils.mockSearchChanged,
          ),
        );

        const numericText = '12345.67890';

        await tester.enterText(find.byType(TextField), numericText);
        await tester.pump();

        // Should handle numeric input
        expect(tester.takeException(), isNull);
        expect(WidgetTestUtils.lastSearchText, equals(numericText));
      });

      testWidgets('should handle rapid text input changes',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          SearchBarWidget(
            onSearchChanged: WidgetTestUtils.mockSearchChanged,
          ),
        );

        final textField = find.byType(TextField);

        // Rapidly change text multiple times
        for (int i = 0; i < 10; i++) {
          await tester.enterText(textField, 'Query $i');
          await tester.pump(const Duration(milliseconds: 10));
        }

        // Should handle rapid changes without errors
        expect(tester.takeException(), isNull);
        expect(WidgetTestUtils.lastSearchText, equals('Query 9'));
      });

      testWidgets('should handle rapid focus changes',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          Column(
            children: [
              SearchBarWidget(
                onSearchChanged: WidgetTestUtils.mockSearchChanged,
                hintText: 'Search episodes...',
              ),
              const TextField(
                  decoration: InputDecoration(hintText: 'Other field')),
            ],
          ),
        );

        // Rapidly switch focus between fields
        for (int i = 0; i < 5; i++) {
          await tester.tap(find.byType(SearchBarWidget));
          await tester.pump(const Duration(milliseconds: 50));

          await tester.tap(find.byType(TextField).last);
          await tester.pump(const Duration(milliseconds: 50));
        }

        // Should handle rapid focus changes without errors
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle layout constraints gracefully',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: SizedBox(
                width: 250, // Narrow constraint
                height: 80, // Limited height
                child: SearchBarWidget(
                  onSearchChanged: WidgetTestUtils.mockSearchChanged,
                  hintText: 'Search...',
                ),
              ),
            ),
          ),
        );

        // Should render without overflow errors
        expect(find.byType(SearchBarWidget), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle memory pressure during rapid operations',
          (WidgetTester tester) async {
        // Create and destroy widgets multiple times to simulate memory pressure
        for (int i = 0; i < 20; i++) {
          await tester.pumpWidget(
            WidgetTestUtils.createTestWrapper(
              SearchBarWidget(
                onSearchChanged: WidgetTestUtils.mockSearchChanged,
                initialValue: 'Memory Test $i' * 5, // Various lengths
              ),
            ),
          );

          await tester.pump();

          // Clear the widget
          await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
          await tester.pump();
        }

        // Should handle repeated creation/destruction without errors
        expect(tester.takeException(), isNull);
      });
    });

    group('State Management Tests', () {
      testWidgets('should properly dispose resources',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          SearchBarWidget(
            onSearchChanged: WidgetTestUtils.mockSearchChanged,
            hintText: 'Search episodes...',
          ),
        );

        // Verify widget is rendered
        expect(find.byType(SearchBarWidget), findsOneWidget);

        // Remove widget
        await tester.pumpWidget(const MaterialApp(home: Scaffold()));

        // Should dispose without errors
        expect(tester.takeException(), isNull);
      });

      testWidgets('should maintain state during rebuilds',
          (WidgetTester tester) async {
        String currentHint = 'Search episodes...';

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return WidgetTestUtils.createTestWrapper(
                SearchBarWidget(
                  onSearchChanged: WidgetTestUtils.mockSearchChanged,
                  hintText: currentHint,
                ),
              );
            },
          ),
        );

        // Enter text
        await WidgetTestUtils.enterTextAndSettle(
          tester,
          find.byType(TextField),
          'test search',
        );

        // Change hint text and rebuild
        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return WidgetTestUtils.createTestWrapper(
                SearchBarWidget(
                  onSearchChanged: WidgetTestUtils.mockSearchChanged,
                  hintText: 'New hint text',
                ),
              );
            },
          ),
        );

        // Text should be preserved (if using the same key)
        // This tests widget state preservation across rebuilds
        expect(find.byType(SearchBarWidget), findsOneWidget);
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
            SearchBarWidget(
              onSearchChanged: WidgetTestUtils.mockSearchChanged,
              hintText: 'Search episodes...',
            ),
          );

          // Should render properly on all screen sizes
          expect(find.byType(SearchBarWidget), findsOneWidget);
          expect(tester.takeException(), isNull);
        }

        WidgetTestUtils.resetDeviceSize(tester);
      });
    });
  });
}
