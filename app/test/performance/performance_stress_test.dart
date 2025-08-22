import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:from_fed_to_chain_app/widgets/filter_bar.dart';
import 'package:from_fed_to_chain_app/widgets/audio_list.dart';
import 'package:from_fed_to_chain_app/widgets/audio_item_card.dart';
import 'package:from_fed_to_chain_app/models/audio_file.dart';

import '../test_utils.dart';

void main() {
  group('Performance and Stress Tests', () {
    testWidgets('large dataset rendering performance', (tester) async {
      const int largeDatasetSize = 1000;
      final episodes = TestUtils.createSampleAudioFileList(largeDatasetSize);

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        TestUtils.wrapWithMaterialApp(
          AudioList(
            episodes: episodes,
            onEpisodeTap: (episode) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      stopwatch.stop();

      // Performance assertion - should render large list efficiently
      expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // 5 seconds max
      expect(find.byType(AudioList), findsOneWidget);

      // Only visible items should be rendered (lazy loading)
      final renderedCards = find.byType(AudioItemCard);
      expect(renderedCards.evaluate().length, lessThan(largeDatasetSize));
    });

    testWidgets('rapid scrolling performance test', (tester) async {
      final episodes = TestUtils.createSampleAudioFileList(500);

      await tester.pumpWidget(
        TestUtils.wrapWithMaterialApp(
          SizedBox(
            height: 600,
            child: AudioList(
              episodes: episodes,
              onEpisodeTap: (episode) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final audioList = find.byType(AudioList);
      final stopwatch = Stopwatch()..start();

      // Perform rapid scrolling
      for (int i = 0; i < 20; i++) {
        await tester.drag(audioList, const Offset(0, -100));
        await tester.pump();
        await tester.drag(audioList, const Offset(0, 100));
        await tester.pump();
      }

      await tester.pumpAndSettle();
      stopwatch.stop();

      // Should handle rapid scrolling without performance degradation
      expect(stopwatch.elapsedMilliseconds, lessThan(3000)); // 3 seconds max
      expect(find.byType(AudioList), findsOneWidget);
    });

    testWidgets('filter switching stress test', (tester) async {
      String selectedLanguage = 'zh-TW';
      String selectedCategory = 'all';
      int totalOperations = 0;

      await tester.pumpWidget(
        TestUtils.wrapWithMaterialApp(
          StatefulBuilder(
            builder: (context, setState) {
              return FilterBar(
                selectedLanguage: selectedLanguage,
                selectedCategory: selectedCategory,
                onLanguageChanged: (language) {
                  setState(() {
                    selectedLanguage = language;
                    totalOperations++;
                  });
                },
                onCategoryChanged: (category) {
                  setState(() {
                    selectedCategory = category;
                    totalOperations++;
                  });
                },
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final stopwatch = Stopwatch()..start();

      // Perform rapid filter switching
      final languages = ['🇺🇸 English', '🇯🇵 日本語', '🇹🇼 繁中'];
      final categories = ['📰', '⚡', '📊', 'All'];

      for (int cycle = 0; cycle < 50; cycle++) {
        // Language switching
        for (final language in languages) {
          final langFinder = find.text(language);
          if (langFinder.evaluate().isNotEmpty) {
            await tester.tap(langFinder.first);
            await tester.pump();
          }
        }

        // Category switching
        for (final category in categories) {
          final catFinder = find.textContaining(category);
          if (catFinder.evaluate().isNotEmpty) {
            await tester.tap(catFinder.first);
            await tester.pump();
          }
        }
      }

      await tester.pumpAndSettle();
      stopwatch.stop();

      // Should handle rapid filter switching efficiently
      expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // 10 seconds max
      expect(totalOperations, greaterThan(100)); // Many operations performed
      expect(find.byType(FilterBar), findsOneWidget);
    });

    testWidgets('memory stress test with widget recreation', (tester) async {
      // Test memory efficiency by creating and destroying many widgets
      for (int iteration = 0; iteration < 10; iteration++) {
        final episodes = TestUtils.createSampleAudioFileList(100);

        await tester.pumpWidget(
          TestUtils.wrapWithMaterialApp(
            Column(
              children: [
                Text('Iteration $iteration'),
                FilterBar(
                  selectedLanguage: 'zh-TW',
                  selectedCategory: 'all',
                  onLanguageChanged: (value) {},
                  onCategoryChanged: (value) {},
                ),
                Expanded(
                  child: AudioList(
                    episodes: episodes,
                    onEpisodeTap: (episode) {},
                  ),
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Perform some interactions
        await tester.drag(find.byType(AudioList), const Offset(0, -200));
        await tester.pump();

        final englishChip = find.text('🇺🇸 English');
        if (englishChip.evaluate().isNotEmpty) {
          await tester.tap(englishChip.first);
          await tester.pump();
        }

        // Verify widgets are rendered correctly
        expect(find.text('Iteration $iteration'), findsOneWidget);
        expect(find.byType(FilterBar), findsOneWidget);
        expect(find.byType(AudioList), findsOneWidget);
      }

      // Final verification
      expect(find.text('Iteration 9'), findsOneWidget);
    });

    testWidgets('concurrent user interactions stress test', (tester) async {
      String selectedLanguage = 'zh-TW';
      String selectedCategory = 'all';
      final episodes = TestUtils.createSampleAudioFileList(100);
      int tapCount = 0;

      await tester.pumpWidget(
        TestUtils.wrapWithMaterialApp(
          StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  FilterBar(
                    selectedLanguage: selectedLanguage,
                    selectedCategory: selectedCategory,
                    onLanguageChanged: (language) {
                      setState(() {
                        selectedLanguage = language;
                      });
                    },
                    onCategoryChanged: (category) {
                      setState(() {
                        selectedCategory = category;
                      });
                    },
                  ),
                  Text('Taps: $tapCount'),
                  Expanded(
                    child: AudioList(
                      episodes: episodes,
                      onEpisodeTap: (episode) {
                        setState(() {
                          tapCount++;
                        });
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final stopwatch = Stopwatch()..start();

      // Simulate concurrent user interactions
      for (int i = 0; i < 50; i++) {
        // Filter change
        final englishChip = find.text('🇺🇸 English');
        if (englishChip.evaluate().isNotEmpty) {
          await tester.tap(englishChip.first);
          await tester.pump();
        }

        // List interaction
        final audioCards = find.byType(AudioItemCard);
        if (audioCards.evaluate().isNotEmpty) {
          await tester.tap(audioCards.first);
          await tester.pump();
        }

        // Scroll
        await tester.drag(find.byType(AudioList), const Offset(0, -50));
        await tester.pump();

        // Category change
        final newsChip = find.textContaining('📰');
        if (newsChip.evaluate().isNotEmpty) {
          await tester.tap(newsChip.first);
          await tester.pump();
        }
      }

      await tester.pumpAndSettle();
      stopwatch.stop();

      // Should handle concurrent interactions without issues
      expect(stopwatch.elapsedMilliseconds, lessThan(15000)); // 15 seconds max
      expect(tapCount, greaterThan(0));
      expect(find.byType(FilterBar), findsOneWidget);
      expect(find.byType(AudioList), findsOneWidget);
    });

    testWidgets('animation performance under load', (tester) async {
      final episodes = TestUtils.createSampleAudioFileList(50);

      await tester.pumpWidget(
        TestUtils.wrapWithMaterialApp(
          AudioList(
            episodes: episodes,
            onEpisodeTap: (episode) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final stopwatch = Stopwatch()..start();

      // Trigger animations by scrolling and interactions
      for (int i = 0; i < 20; i++) {
        // Fast scrolling to trigger list animations
        await tester.drag(find.byType(AudioList), const Offset(0, -300));
        await tester.pump();

        // Tap to trigger card animations
        final audioCards = find.byType(AudioItemCard);
        if (audioCards.evaluate().isNotEmpty) {
          await tester.tap(audioCards.first);
          await tester.pump();
        }

        await tester.drag(find.byType(AudioList), const Offset(0, 300));
        await tester.pump();
      }

      await tester.pumpAndSettle();
      stopwatch.stop();

      // Should handle animations efficiently
      expect(stopwatch.elapsedMilliseconds, lessThan(8000)); // 8 seconds max
      expect(find.byType(AudioList), findsOneWidget);
    });

    testWidgets('edge case performance with minimal data', (tester) async {
      // Test performance with edge cases
      final testCases = [
        <AudioFile>[], // Empty list
        TestUtils.createSampleAudioFileList(1), // Single item
        TestUtils.createSampleAudioFileList(2), // Minimal items
      ];

      for (int i = 0; i < testCases.length; i++) {
        final episodes = testCases[i];

        await tester.pumpWidget(
          TestUtils.wrapWithMaterialApp(
            Column(
              children: [
                Text('Test case $i: ${episodes.length} episodes'),
                Expanded(
                  child: AudioList(
                    episodes: episodes,
                    onEpisodeTap: (episode) {},
                  ),
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Should render efficiently even with edge cases
        expect(find.text('Test case $i: ${episodes.length} episodes'),
            findsOneWidget);
        expect(find.byType(AudioList), findsOneWidget);

        // Test interactions
        if (episodes.isNotEmpty) {
          final audioCards = find.byType(AudioItemCard);
          expect(audioCards, findsNWidgets(episodes.length));

          await tester.tap(audioCards.first);
          await tester.pump();
        }

        // Test scrolling even with minimal content
        await tester.drag(find.byType(AudioList), const Offset(0, -100));
        await tester.pump();
        await tester.drag(find.byType(AudioList), const Offset(0, 100));
        await tester.pump();
      }
    });

    testWidgets('layout performance with different screen sizes',
        (tester) async {
      final episodes = TestUtils.createSampleAudioFileList(20);

      // Test different screen dimensions
      final screenSizes = [
        const Size(360, 640), // Small phone
        const Size(414, 896), // Large phone
        const Size(768, 1024), // Tablet portrait
        const Size(1024, 768), // Tablet landscape
      ];

      for (final size in screenSizes) {
        await tester.binding.setSurfaceSize(size);

        await tester.pumpWidget(
          TestUtils.wrapWithMaterialApp(
            Column(
              children: [
                Text('Screen: ${size.width}x${size.height}'),
                FilterBar(
                  selectedLanguage: 'zh-TW',
                  selectedCategory: 'all',
                  onLanguageChanged: (value) {},
                  onCategoryChanged: (value) {},
                ),
                Expanded(
                  child: AudioList(
                    episodes: episodes,
                    onEpisodeTap: (episode) {},
                  ),
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Should adapt to different screen sizes efficiently
        expect(find.textContaining('Screen:'), findsOneWidget);
        expect(find.byType(FilterBar), findsOneWidget);
        expect(find.byType(AudioList), findsOneWidget);

        // Test interactions at different screen sizes
        final englishChip = find.text('🇺🇸 English');
        if (englishChip.evaluate().isNotEmpty) {
          await tester.tap(englishChip.first);
          await tester.pump();
        }

        await tester.drag(find.byType(AudioList), const Offset(0, -100));
        await tester.pump();
      }

      // Reset to default size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('state management performance under pressure', (tester) async {
      String selectedLanguage = 'zh-TW';
      String selectedCategory = 'all';
      final episodes = TestUtils.createSampleAudioFileList(200);
      int stateUpdates = 0;

      await tester.pumpWidget(
        TestUtils.wrapWithMaterialApp(
          StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  Text('State updates: $stateUpdates'),
                  FilterBar(
                    selectedLanguage: selectedLanguage,
                    selectedCategory: selectedCategory,
                    onLanguageChanged: (language) {
                      setState(() {
                        selectedLanguage = language;
                        stateUpdates++;
                      });
                    },
                    onCategoryChanged: (category) {
                      setState(() {
                        selectedCategory = category;
                        stateUpdates++;
                      });
                    },
                  ),
                  Text(
                      'Language: $selectedLanguage, Category: $selectedCategory'),
                  Expanded(
                    child: AudioList(
                      episodes: episodes.where((e) {
                        return (selectedLanguage == 'all' ||
                                e.language == selectedLanguage) &&
                            (selectedCategory == 'all' ||
                                e.category == selectedCategory);
                      }).toList(),
                      onEpisodeTap: (episode) {},
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final stopwatch = Stopwatch()..start();

      // Rapidly change filters to stress state management
      for (int i = 0; i < 100; i++) {
        final filters = ['🇺🇸 English', '🇯🇵 日本語', '🇹🇼 繁中'];
        final categories = ['📰', '⚡', 'All'];

        for (final filter in filters) {
          final filterFinder = find.text(filter);
          if (filterFinder.evaluate().isNotEmpty) {
            await tester.tap(filterFinder.first);
            await tester.pump();
          }
        }

        for (final category in categories) {
          final categoryFinder = find.textContaining(category);
          if (categoryFinder.evaluate().isNotEmpty) {
            await tester.tap(categoryFinder.first);
            await tester.pump();
          }
        }
      }

      await tester.pumpAndSettle();
      stopwatch.stop();

      // Should handle rapid state changes efficiently
      expect(stopwatch.elapsedMilliseconds, lessThan(20000)); // 20 seconds max
      expect(stateUpdates, greaterThan(100));
      expect(find.textContaining('State updates:'), findsOneWidget);
    });
  });
}
