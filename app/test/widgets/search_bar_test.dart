import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:from_fed_to_chain_app/widgets/search_bar.dart';
import 'package:from_fed_to_chain_app/themes/app_theme.dart';
import '../test_utils.dart';

void main() {
  group('SearchBarWidget Tests', () {
    String? changedText;
    List<String> allChanges = [];

    void onSearchChanged(String text) {
      changedText = text;
      allChanges.add(text);
    }

    setUp(() {
      changedText = null;
      allChanges.clear();
    });

    Widget createSearchBar({
      ValueChanged<String>? onSearchChangedCallback,
      String hintText = 'Search...',
      String? initialValue,
    }) {
      return SearchBarWidget(
        onSearchChanged: onSearchChangedCallback ?? onSearchChanged,
        hintText: hintText,
        initialValue: initialValue,
      );
    }

    testWidgets('should render with basic structure', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createSearchBar());

      // Verify main structure
      TestUtils.expectWidgetExists(find.byType(SearchBarWidget));
      TestUtils.expectWidgetExists(find.byType(Container));
      TestUtils.expectWidgetExists(find.byType(TextField));
    });

    testWidgets('should display default hint text', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createSearchBar());

      // Verify default hint text
      TestUtils.expectTextExists('Search...');
    });

    testWidgets('should display custom hint text', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createSearchBar(hintText: 'Search episodes...'));

      // Verify custom hint text
      TestUtils.expectTextExists('Search episodes...');
    });

    testWidgets('should display initial value when provided', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createSearchBar(initialValue: 'Initial search'));

      // Verify initial value is displayed
      TestUtils.expectTextExists('Initial search');
    });

    testWidgets('should show search icon as prefix', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createSearchBar());

      // Verify search icon is present
      TestUtils.expectIconExists(Icons.search);
    });

    testWidgets('should not show clear button initially', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createSearchBar());

      // Clear button should not be visible when empty
      TestUtils.expectWidgetNotExists(find.byIcon(Icons.clear));
    });

    testWidgets('should show clear button when text is entered',
        (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createSearchBar());

      // Enter some text
      await TestUtils.enterTextInWidget(tester, find.byType(TextField), 'test');

      // Clear button should now be visible
      TestUtils.expectIconExists(Icons.clear);
    });

    testWidgets('should handle text input correctly', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createSearchBar());

      // Enter text
      await TestUtils.enterTextInWidget(
          tester, find.byType(TextField), 'Bitcoin');

      // Verify callback was called with correct text
      expect(changedText, equals('Bitcoin'));
    });

    testWidgets('should handle text changes in real-time', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createSearchBar());

      // Type text character by character
      await tester.enterText(find.byType(TextField), 'B');
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Bi');
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Bit');
      await tester.pump();

      // Should have received multiple change notifications
      expect(allChanges, isNotEmpty);
    });

    testWidgets('should clear text when clear button is tapped',
        (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createSearchBar());

      // Enter some text first
      await TestUtils.enterTextInWidget(
          tester, find.byType(TextField), 'test text');

      // Verify clear button appears
      TestUtils.expectIconExists(Icons.clear);

      // Tap clear button
      await TestUtils.tapWidget(tester, find.byIcon(Icons.clear));

      // Verify text is cleared
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);

      // Verify callback was called with empty string
      expect(changedText, equals(''));

      // Clear button should be hidden again
      TestUtils.expectWidgetNotExists(find.byIcon(Icons.clear));
    });

    testWidgets('should handle submit action correctly', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createSearchBar());

      // Enter text
      await TestUtils.enterTextInWidget(
          tester, find.byType(TextField), 'search term');

      // Submit by pressing enter
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      // Verify callback was called
      expect(changedText, equals('search term'));
    });

    testWidgets('should unfocus when submitted', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createSearchBar());

      // Focus the text field
      await TestUtils.tapWidget(tester, find.byType(TextField));
      await tester.pumpAndSettle();

      // Enter text and submit
      await TestUtils.enterTextInWidget(tester, find.byType(TextField), 'test');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      // Field should lose focus after submit
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.focusNode?.hasFocus, isFalse);
    });

    testWidgets('should apply correct styling and decoration', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createSearchBar());

      // Verify container decoration
      final container = tester.widget<Container>(find.byType(Container));
      expect(container.decoration, equals(AppTheme.cardDecoration));

      // Verify text field styling
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.style, equals(AppTheme.bodyMedium));
      expect(textField.textInputAction, equals(TextInputAction.search));
    });

    testWidgets('should show focus border when focused', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createSearchBar());

      // Focus the text field
      await TestUtils.tapWidget(tester, find.byType(TextField));
      await tester.pumpAndSettle();

      // Field should be focused
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.focusNode?.hasFocus, isTrue);
    });

    testWidgets('should handle long text input without overflow',
        (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createSearchBar());

      const longText =
          'This is a very long search query that might cause overflow issues if not handled properly in the text field widget';

      // Enter very long text
      await TestUtils.enterTextInWidget(
          tester, find.byType(TextField), longText);

      // Verify text is handled correctly
      expect(changedText, equals(longText));

      // Widget should render without overflow
      TestUtils.expectWidgetExists(find.byType(SearchBarWidget));
    });

    testWidgets('should handle special characters correctly', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createSearchBar());

      const specialText = 'Search: @#\$%^&*()_+-=[]{}|;":,./<>?`~';

      // Enter text with special characters
      await TestUtils.enterTextInWidget(
          tester, find.byType(TextField), specialText);

      // Verify special characters are handled
      expect(changedText, equals(specialText));
    });

    testWidgets('should handle empty string correctly', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createSearchBar());

      // Enter empty string
      await TestUtils.enterTextInWidget(tester, find.byType(TextField), '');

      // Verify empty string callback
      expect(changedText, equals(''));

      // Clear button should not be visible
      TestUtils.expectWidgetNotExists(find.byIcon(Icons.clear));
    });

    testWidgets('should handle whitespace correctly', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createSearchBar());

      // Enter text with whitespace
      await TestUtils.enterTextInWidget(
          tester, find.byType(TextField), '  test  ');

      // Verify whitespace is preserved
      expect(changedText, equals('  test  '));
    });

    testWidgets('should handle rapid text changes correctly', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createSearchBar());

      // Rapidly change text
      const texts = ['a', 'ab', 'abc', 'abcd', 'abcde'];

      for (final text in texts) {
        await tester.enterText(find.byType(TextField), text);
        await tester.pump(const Duration(milliseconds: 10));
      }

      // Should have received all changes
      expect(allChanges.length, greaterThan(0));
      expect(changedText, equals('abcde'));
    });

    testWidgets('should handle initial value with clear button',
        (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createSearchBar(initialValue: 'Initial text'));

      // Clear button should be visible with initial text
      TestUtils.expectIconExists(Icons.clear);

      // Tap clear button
      await TestUtils.tapWidget(tester, find.byIcon(Icons.clear));

      // Text should be cleared
      expect(changedText, equals(''));
    });

    testWidgets('should maintain focus correctly during interactions',
        (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createSearchBar());

      // Focus the field
      await TestUtils.tapWidget(tester, find.byType(TextField));
      await tester.pumpAndSettle();

      // Enter text while focused
      await TestUtils.enterTextInWidget(
          tester, find.byType(TextField), 'focused text');

      // Should maintain focus until explicitly unfocused
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.focusNode?.hasFocus, isTrue);
    });

    testWidgets('should handle keyboard actions correctly', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createSearchBar());

      // Focus and enter text
      await TestUtils.tapWidget(tester, find.byType(TextField));
      await TestUtils.enterTextInWidget(
          tester, find.byType(TextField), 'keyboard test');

      // Simulate various keyboard actions
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      // Should handle keyboard input correctly
      expect(changedText, equals('keyboard test'));
    });

    testWidgets('should handle null or empty callbacks gracefully',
        (tester) async {
      // Test with empty callback
      final searchBarWithEmptyCallback = SearchBarWidget(
        onSearchChanged: (_) {}, // Empty callback
      );

      await TestUtils.pumpWidgetWithMaterialApp(
          tester, searchBarWithEmptyCallback);

      // Should render without issues
      TestUtils.expectWidgetExists(find.byType(SearchBarWidget));

      // Should handle text input without errors
      await TestUtils.enterTextInWidget(tester, find.byType(TextField), 'test');
    });

    testWidgets('should properly dispose resources', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createSearchBar());

      // Widget should render correctly
      TestUtils.expectWidgetExists(find.byType(SearchBarWidget));

      // Remove widget to trigger dispose
      await tester.pumpWidget(Container());

      // Should complete without errors (dispose called)
      expect(true, isTrue);
    });

    testWidgets('should handle widget rebuilds correctly', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createSearchBar(hintText: 'Original hint'));

      // Verify original hint
      TestUtils.expectTextExists('Original hint');

      // Rebuild with different hint
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createSearchBar(hintText: 'Updated hint'));

      // Should show updated hint
      TestUtils.expectTextExists('Updated hint');
    });

    testWidgets('should apply correct input decoration styling',
        (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createSearchBar());

      // Verify InputDecoration properties
      final textField = tester.widget<TextField>(find.byType(TextField));
      final decoration = textField.decoration!;

      expect(decoration.filled, isTrue);
      expect(decoration.border, isA<OutlineInputBorder>());
      expect(decoration.focusedBorder, isA<OutlineInputBorder>());
    });

    testWidgets('should handle edge case with very small screen',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(200, 400));

      await TestUtils.pumpWidgetWithMaterialApp(tester, createSearchBar());

      // Should render without overflow on small screens
      TestUtils.expectWidgetExists(find.byType(SearchBarWidget));

      // Reset screen size
      await tester.binding.setSurfaceSize(const Size(800, 600));
    });

    testWidgets('should handle multiple rapid clear button taps',
        (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createSearchBar());

      // Enter text
      await TestUtils.enterTextInWidget(
          tester, find.byType(TextField), 'test text');

      // Rapidly tap clear button multiple times
      for (int i = 0; i < 3; i++) {
        if (find.byIcon(Icons.clear).evaluate().isNotEmpty) {
          await TestUtils.tapWidget(tester, find.byIcon(Icons.clear));
        }
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Text should be cleared
      expect(changedText, equals(''));
    });

    testWidgets('should maintain consistent appearance across states',
        (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createSearchBar());

      // Test empty state
      TestUtils.expectWidgetExists(find.byType(Container));
      TestUtils.expectWidgetExists(find.byType(TextField));

      // Test with text
      await TestUtils.enterTextInWidget(tester, find.byType(TextField), 'test');

      // Should maintain consistent structure
      TestUtils.expectWidgetExists(find.byType(Container));
      TestUtils.expectWidgetExists(find.byType(TextField));

      // Clear button should be present
      TestUtils.expectIconExists(Icons.clear);
    });

    testWidgets('should handle accessibility correctly', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createSearchBar());

      // Text field should be accessible
      TestUtils.expectWidgetExists(find.byType(TextField));

      // Icons should be accessible as buttons
      TestUtils.expectIconExists(Icons.search);

      // When clear button appears, it should be accessible
      await TestUtils.enterTextInWidget(tester, find.byType(TextField), 'test');
      TestUtils.expectWidgetExists(find.byType(IconButton));
    });

    testWidgets('should handle text selection correctly', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createSearchBar());

      // Enter text
      await TestUtils.enterTextInWidget(
          tester, find.byType(TextField), 'selectable text');

      // Text should be selectable
      TestUtils.expectTextExists('selectable text');
    });

    testWidgets('should handle focus changes correctly', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createSearchBar());

      // Initially not focused
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.focusNode?.hasFocus, isFalse);

      // Focus by tapping
      await TestUtils.tapWidget(tester, find.byType(TextField));
      await tester.pumpAndSettle();

      // Should be focused
      expect(textField.focusNode?.hasFocus, isTrue);

      // Unfocus by tapping outside
      await tester.tap(find.byType(Scaffold));
      await tester.pumpAndSettle();

      // Should lose focus
      expect(textField.focusNode?.hasFocus, isFalse);
    });
  });
}
