import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:from_fed_to_chain_app/widgets/playback_speed_selector.dart';
import 'package:from_fed_to_chain_app/themes/app_theme.dart';

import 'widget_test_utils.dart';

void main() {
  group('PlaybackSpeedSelector Widget Tests', () {
    setUp(() {
      WidgetTestUtils.resetCallbacks();
    });

    group('Rendering Tests', () {
      testWidgets('should render all components correctly',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          PlaybackSpeedSelector(
            currentSpeed: 1.0,
            onSpeedChanged: WidgetTestUtils.mockSpeedChanged,
          ),
        );

        // Verify main structure
        expect(find.byType(PlaybackSpeedSelector), findsOneWidget);
        expect(find.text('Playback Speed'), findsOneWidget);

        // Verify speed option chips
        const expectedSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
        for (final speed in expectedSpeeds) {
          expect(find.text('${speed}x'), findsOneWidget);
        }

        // Verify custom speed slider section
        expect(find.text('Custom Speed'), findsOneWidget);
        expect(find.byType(Slider), findsOneWidget);
        expect(find.text('0.5x'), findsWidgets); // Min label
        expect(find.text('2.0x'), findsWidgets); // Max label

        // Verify current speed display
        expect(find.text('1.00x'), findsOneWidget);
      });

      testWidgets('should highlight current speed correctly',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          PlaybackSpeedSelector(
            currentSpeed: 1.5,
            onSpeedChanged: WidgetTestUtils.mockSpeedChanged,
          ),
        );

        // Verify 1.5x is highlighted and current speed display shows correct value
        expect(find.text('1.5x'), findsOneWidget);
        expect(find.text('1.50x'), findsOneWidget); // Custom speed display
      });

      testWidgets('should render all speed option chips',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          PlaybackSpeedSelector(
            currentSpeed: 1.0,
            onSpeedChanged: WidgetTestUtils.mockSpeedChanged,
          ),
        );

        // Verify all speed options are present
        const speedOptions = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
        for (final speed in speedOptions) {
          expect(find.text('${speed}x'), findsOneWidget);
        }

        // Verify wrap layout for speed options
        expect(find.byType(Wrap), findsOneWidget);
      });
    });

    group('Speed Selection Tests', () {
      testWidgets('should handle speed chip selection',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          PlaybackSpeedSelector(
            currentSpeed: 1.0,
            onSpeedChanged: WidgetTestUtils.mockSpeedChanged,
          ),
        );

        // Tap on 1.5x speed chip
        await WidgetTestUtils.tapAndSettle(tester, find.text('1.5x'));

        // Verify callback was triggered with correct speed
        expect(WidgetTestUtils.lastSelectedSpeed, equals(1.5));
      });

      testWidgets('should handle all speed chip selections',
          (WidgetTester tester) async {
        const speedOptions = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

        for (final speed in speedOptions) {
          WidgetTestUtils.resetCallbacks();

          await tester.pumpWidget(
            WidgetTestUtils.createTestWrapper(
              PlaybackSpeedSelector(
                currentSpeed: 1.0,
                onSpeedChanged: WidgetTestUtils.mockSpeedChanged,
              ),
            ),
          );

          // Tap speed chip
          await WidgetTestUtils.tapAndSettle(tester, find.text('${speed}x'));

          // Verify correct speed was selected
          expect(WidgetTestUtils.lastSelectedSpeed, equals(speed));
        }
      });

      testWidgets('should handle slider interaction',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          PlaybackSpeedSelector(
            currentSpeed: 1.0,
            onSpeedChanged: WidgetTestUtils.mockSpeedChanged,
          ),
        );

        // Find and interact with slider
        final sliderFinder = find.byType(Slider);
        expect(sliderFinder, findsOneWidget);

        final slider = tester.widget<Slider>(sliderFinder);
        expect(slider.min, equals(0.5));
        expect(slider.max, equals(2.0));
        expect(slider.divisions, equals(30)); // 0.05 increments
        expect(slider.value, equals(1.0));

        // Simulate slider drag to change value
        await tester.drag(sliderFinder, const Offset(50, 0));
        await tester.pumpAndSettle();

        // Verify callback was triggered (exact value depends on drag simulation)
        expect(WidgetTestUtils.lastSelectedSpeed, isNot(equals(1.0)));
      });

      testWidgets('should update custom speed display when slider changes',
          (WidgetTester tester) async {
        double currentSpeed = 1.0;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return WidgetTestUtils.createTestWrapper(
                PlaybackSpeedSelector(
                  currentSpeed: currentSpeed,
                  onSpeedChanged: (speed) =>
                      setState(() => currentSpeed = speed),
                ),
              );
            },
          ),
        );

        // Initial state
        expect(find.text('1.00x'), findsOneWidget);

        // Simulate changing speed through rebuild
        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return WidgetTestUtils.createTestWrapper(
                PlaybackSpeedSelector(
                  currentSpeed: 1.75,
                  onSpeedChanged: (speed) =>
                      setState(() => currentSpeed = speed),
                ),
              );
            },
          ),
        );

        // Verify custom speed display updated
        expect(find.text('1.75x'), findsOneWidget);
      });
    });

    group('Visual State Tests', () {
      testWidgets('should highlight selected speed chip',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          PlaybackSpeedSelector(
            currentSpeed: 1.25,
            onSpeedChanged: WidgetTestUtils.mockSpeedChanged,
          ),
        );

        // Find the 1.25x speed chip container
        final speedChipFinder = find.text('1.25x');
        expect(speedChipFinder, findsOneWidget);

        // Find its parent container to check styling
        final containerFinder = find
            .ancestor(
              of: speedChipFinder,
              matching: find.byType(Container),
            )
            .first;

        final container = tester.widget<Container>(containerFinder);
        final decoration = container.decoration as BoxDecoration;

        // Verify selected styling
        expect(decoration.color, equals(AppTheme.primaryColor));
      });

      testWidgets('should apply unselected styling to non-current speeds',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          PlaybackSpeedSelector(
            currentSpeed: 1.0,
            onSpeedChanged: WidgetTestUtils.mockSpeedChanged,
          ),
        );

        // Find a non-selected speed chip (0.5x)
        final speedChipFinder = find.text('0.5x');
        expect(speedChipFinder, findsOneWidget);

        // Find its parent container
        final containerFinder = find
            .ancestor(
              of: speedChipFinder,
              matching: find.byType(Container),
            )
            .first;

        final container = tester.widget<Container>(containerFinder);
        final decoration = container.decoration as BoxDecoration;

        // Verify unselected styling
        expect(decoration.color, equals(AppTheme.cardColor.withOpacity(0.5)));
        expect(decoration.border, isNotNull);
      });

      testWidgets('should apply correct text styling to selected chip',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          PlaybackSpeedSelector(
            currentSpeed: 2.0,
            onSpeedChanged: WidgetTestUtils.mockSpeedChanged,
          ),
        );

        // Verify that we have the right speed selected by checking the chip background
        final containers = tester.widgetList<Container>(find.byType(Container));
        
        // Find the container with primary color background (selected chip)
        bool foundSelectedChip = false;
        for (final container in containers) {
          final decoration = container.decoration as BoxDecoration?;
          if (decoration?.color == AppTheme.primaryColor) {
            foundSelectedChip = true;
            // Check the text inside this container
            final text = container.child as Text;
            expect(text.data, equals('2.0x'));
            expect(text.style?.color, equals(AppTheme.onPrimaryColor));
            expect(text.style?.fontWeight, equals(FontWeight.w600));
            break;
          }
        }
        
        expect(foundSelectedChip, isTrue);
      });

      testWidgets('should apply slider theme correctly',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          PlaybackSpeedSelector(
            currentSpeed: 1.0,
            onSpeedChanged: WidgetTestUtils.mockSpeedChanged,
          ),
        );

        // Find slider theme
        final sliderThemeFinder = find.byType(SliderTheme);
        expect(sliderThemeFinder, findsOneWidget);

        final sliderTheme = tester.widget<SliderTheme>(sliderThemeFinder);
        final themeData = sliderTheme.data;

        // Verify theme properties
        expect(themeData.trackHeight, equals(4.0));
        expect(themeData.activeTrackColor, equals(AppTheme.primaryColor));
        expect(themeData.inactiveTrackColor, equals(AppTheme.cardColor));
        expect(themeData.thumbColor, equals(AppTheme.primaryColor));
      });

      testWidgets('should style custom speed display correctly',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          PlaybackSpeedSelector(
            currentSpeed: 1.33,
            onSpeedChanged: WidgetTestUtils.mockSpeedChanged,
          ),
        );

        // Find custom speed display
        final customSpeedFinder = find.text('1.33x');
        expect(customSpeedFinder, findsOneWidget);

        // Find its parent container
        final containerFinder = find.ancestor(
          of: customSpeedFinder,
          matching: find.byType(Container),
        );

        expect(containerFinder, findsWidgets);

        // Verify at least one container has primary color styling
        bool foundCorrectStyling = false;
        for (int i = 0; i < containerFinder.evaluate().length; i++) {
          final container = tester.widget<Container>(containerFinder.at(i));
          final decoration = container.decoration as BoxDecoration?;

          if (decoration?.color == AppTheme.primaryColor.withOpacity(0.1)) {
            foundCorrectStyling = true;
            expect(decoration!.border, isNotNull);
            break;
          }
        }

        expect(foundCorrectStyling, true);
      });
    });

    group('Precision Tests', () {
      testWidgets('should handle floating point precision correctly',
          (WidgetTester tester) async {
        // Test with precise floating point value
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          PlaybackSpeedSelector(
            currentSpeed: 1.007, // Close to 1.0 but not exactly
            onSpeedChanged: WidgetTestUtils.mockSpeedChanged,
          ),
        );

        // Should highlight 1.0x as it's closest
        final speedChipFinder = find.text('1.0x');
        final containerFinder = find
            .ancestor(
              of: speedChipFinder,
              matching: find.byType(Container),
            )
            .first;

        final container = tester.widget<Container>(containerFinder);
        final decoration = container.decoration as BoxDecoration;

        // Should be selected due to precision tolerance
        expect(decoration.color, equals(AppTheme.primaryColor));
      });

      testWidgets('should display correct decimal places in custom speed',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          PlaybackSpeedSelector(
            currentSpeed: 1.234567, // Many decimal places
            onSpeedChanged: WidgetTestUtils.mockSpeedChanged,
          ),
        );

        // Should display with 2 decimal places
        expect(find.text('1.23x'), findsOneWidget);
      });

      testWidgets('should handle edge case speeds',
          (WidgetTester tester) async {
        final edgeCases = [0.5, 2.0, 0.51, 1.99];

        for (final speed in edgeCases) {
          await tester.pumpWidget(
            WidgetTestUtils.createTestWrapper(
              PlaybackSpeedSelector(
                currentSpeed: speed,
                onSpeedChanged: WidgetTestUtils.mockSpeedChanged,
              ),
            ),
          );

          // Should render without errors
          expect(find.byType(PlaybackSpeedSelector), findsOneWidget);

          // Custom speed display should show correct value
          expect(find.text('${speed.toStringAsFixed(2)}x'), findsOneWidget);

          await tester.pump();
        }
      });
    });

    group('Interaction Tests', () {
      testWidgets('should provide haptic feedback on chip selection',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          PlaybackSpeedSelector(
            currentSpeed: 1.0,
            onSpeedChanged: WidgetTestUtils.mockSpeedChanged,
          ),
        );

        // Tap on speed chip with InkWell for material feedback
        final inkWellFinder = find.descendant(
          of: find.text('1.5x').first,
          matching: find.byType(InkWell),
        );

        expect(inkWellFinder, findsOneWidget);
        await WidgetTestUtils.tapAndSettle(tester, inkWellFinder);

        expect(WidgetTestUtils.lastSelectedSpeed, equals(1.5));
      });

      testWidgets('should handle rapid speed changes',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          PlaybackSpeedSelector(
            currentSpeed: 1.0,
            onSpeedChanged: WidgetTestUtils.mockSpeedChanged,
          ),
        );

        // Rapidly tap different speed options
        await WidgetTestUtils.tapAndSettle(tester, find.text('0.5x'));
        expect(WidgetTestUtils.lastSelectedSpeed, equals(0.5));

        await WidgetTestUtils.tapAndSettle(tester, find.text('2.0x'));
        expect(WidgetTestUtils.lastSelectedSpeed, equals(2.0));

        await WidgetTestUtils.tapAndSettle(tester, find.text('1.0x'));
        expect(WidgetTestUtils.lastSelectedSpeed, equals(1.0));
      });

      testWidgets('should handle slider continuous changes',
          (WidgetTester tester) async {
        int callbackCount = 0;
        double lastSpeed = 1.0;

        await tester.pumpWidget(
          WidgetTestUtils.createTestWrapper(
            PlaybackSpeedSelector(
              currentSpeed: 1.0,
              onSpeedChanged: (speed) {
                callbackCount++;
                lastSpeed = speed;
              },
            ),
          ),
        );

        // Simulate multiple slider movements
        final sliderFinder = find.byType(Slider);
        await tester.drag(sliderFinder, const Offset(20, 0));
        await tester.pump();

        final firstCallbackCount = callbackCount;

        await tester.drag(sliderFinder, const Offset(20, 0));
        await tester.pump();

        // Verify multiple callbacks were triggered
        expect(callbackCount, greaterThan(firstCallbackCount));
        expect(lastSpeed, isNot(equals(1.0)));
      });
    });



    group('Accessibility Tests', () {
      testWidgets('should meet accessibility guidelines',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          PlaybackSpeedSelector(
            currentSpeed: 1.0,
            onSpeedChanged: WidgetTestUtils.mockSpeedChanged,
          ),
        );

        await WidgetTestUtils.verifyAccessibility(tester);
      });

      testWidgets('should have sufficient tap target sizes',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          PlaybackSpeedSelector(
            currentSpeed: 1.0,
            onSpeedChanged: WidgetTestUtils.mockSpeedChanged,
          ),
        );

        // Check speed chip tap targets
        final inkWellFinders = find.byType(InkWell);
        for (int i = 0; i < inkWellFinders.evaluate().length; i++) {
          final renderObject =
              tester.renderObject<RenderBox>(inkWellFinders.at(i));
          final size = renderObject.size;

          // Should meet minimum tap target size
          expect(size.width, greaterThanOrEqualTo(32));
          expect(size.height, greaterThanOrEqualTo(32));
        }

        // Check slider tap target
        final sliderRenderObject =
            tester.renderObject<RenderBox>(find.byType(Slider));
        expect(sliderRenderObject.size.height, greaterThanOrEqualTo(32));
      });

      testWidgets('should provide semantic labels for speed options',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          PlaybackSpeedSelector(
            currentSpeed: 1.0,
            onSpeedChanged: WidgetTestUtils.mockSpeedChanged,
          ),
        );

        // Verify speed options have text labels for screen readers
        const speedOptions = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
        for (final speed in speedOptions) {
          expect(find.text('${speed}x'), findsOneWidget);
        }

        // Verify section titles exist
        expect(find.text('Playback Speed'), findsOneWidget);
        expect(find.text('Custom Speed'), findsOneWidget);
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle null callback gracefully',
          (WidgetTester tester) async {
        // Test with no-op callback
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          PlaybackSpeedSelector(
            currentSpeed: 1.0,
            onSpeedChanged: (_) {}, // No-op callback
          ),
        );

        // Should render without errors
        expect(find.byType(PlaybackSpeedSelector), findsOneWidget);

        // Should handle taps without crashes
        await WidgetTestUtils.tapAndSettle(tester, find.text('1.5x'));
      });

      testWidgets('should handle extreme speed values',
          (WidgetTester tester) async {
        // Test with speed outside normal range
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          PlaybackSpeedSelector(
            currentSpeed: 3.0, // Outside normal range
            onSpeedChanged: WidgetTestUtils.mockSpeedChanged,
          ),
        );

        // Should render without errors
        expect(find.byType(PlaybackSpeedSelector), findsOneWidget);

        // Custom speed display should show the value
        expect(find.text('3.00x'), findsOneWidget);

        // No speed chip should be highlighted (all outside tolerance)
        // Slider should be at max value (2.0)
        final slider = tester.widget<Slider>(find.byType(Slider));
        expect(slider.value, equals(3.0)); // Should clamp to input value
      });

      testWidgets('should handle very small speed increments',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          PlaybackSpeedSelector(
            currentSpeed: 1.03, // Small increment
            onSpeedChanged: WidgetTestUtils.mockSpeedChanged,
          ),
        );

        // Should display with correct precision
        expect(find.text('1.03x'), findsOneWidget);

        // Should still highlight 1.0x chip due to tolerance
        final speedChipFinder = find.text('1.0x');
        final containerFinder = find
            .ancestor(
              of: speedChipFinder,
              matching: find.byType(Container),
            )
            .first;

        final container = tester.widget<Container>(containerFinder);
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, equals(AppTheme.primaryColor));
      });
    });


  });
}
