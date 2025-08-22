import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:from_fed_to_chain_app/widgets/filter_bar.dart';
import 'package:from_fed_to_chain_app/widgets/audio_list.dart';
import 'package:from_fed_to_chain_app/widgets/audio_item_card.dart';
import 'package:from_fed_to_chain_app/models/audio_file.dart';

import '../test_utils.dart';

void main() {
  group('Edge Cases and Boundary Tests', () {
    testWidgets('empty and null data handling', (tester) async {
      // Test with empty episodes list
      await tester.pumpWidget(
        TestUtils.wrapWithMaterialApp(
          AudioList(
            episodes: const [],
            onEpisodeTap: (episode) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AudioList), findsOneWidget);
      expect(find.byType(AudioItemCard), findsNothing);

      // Test with single episode
      final singleEpisode = [TestUtils.createSampleAudioFile()];
      await tester.pumpWidget(
        TestUtils.wrapWithMaterialApp(
          AudioList(
            episodes: singleEpisode,
            onEpisodeTap: (episode) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AudioItemCard), findsOneWidget);
    });

    testWidgets('extreme string lengths in filter bar', (tester) async {
      // Test with very long language codes
      await tester.pumpWidget(
        TestUtils.wrapWithMaterialApp(
          FilterBar(
            selectedLanguage:
                'extremely-long-language-code-that-should-not-break-the-ui',
            selectedCategory:
                'extremely-long-category-name-that-tests-overflow-behavior',
            onLanguageChanged: (value) {},
            onCategoryChanged: (value) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should handle long strings gracefully
      expect(find.byType(FilterBar), findsOneWidget);

      // Test with empty strings
      await tester.pumpWidget(
        TestUtils.wrapWithMaterialApp(
          FilterBar(
            selectedLanguage: '',
            selectedCategory: '',
            onLanguageChanged: (value) {},
            onCategoryChanged: (value) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FilterBar), findsOneWidget);
    });

    testWidgets('unicode and special characters handling', (tester) async {
      final unicodeEpisodes = [
        TestUtils.createSampleAudioFile(
          title: '测试标题 🎵 📻 音频内容',
          language: 'zh-CN',
          category: 'test-unicode',
        ),
        TestUtils.createSampleAudioFile(
          title: 'Тест заголовок 🇷🇺 аудио контент',
          language: 'ru-RU',
          category: 'test-cyrillic',
        ),
        TestUtils.createSampleAudioFile(
          title: 'اختبار العنوان 🇦🇪 محتوى صوتي',
          language: 'ar-AE',
          category: 'test-arabic',
        ),
        TestUtils.createSampleAudioFile(
          title: 'Test title with emojis 🎭🎪🎨🎬🎸',
          language: 'en-US',
          category: 'test-emojis',
        ),
      ];

      await tester.pumpWidget(
        TestUtils.wrapWithMaterialApp(
          AudioList(
            episodes: unicodeEpisodes,
            onEpisodeTap: (episode) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should render unicode content correctly
      expect(find.byType(AudioList), findsOneWidget);
      expect(find.byType(AudioItemCard), findsNWidgets(unicodeEpisodes.length));

      // Verify specific unicode content is displayed
      expect(find.textContaining('测试标题'), findsOneWidget);
      expect(find.textContaining('Тест заголовок'), findsOneWidget);
      expect(find.textContaining('اختبار العنوان'), findsOneWidget);
      expect(find.textContaining('🎭🎪🎨🎬🎸'), findsOneWidget);
    });

    testWidgets('maximum data load stress test', (tester) async {
      // Test with maximum realistic data size
      const maxEpisodes = 10000;
      final episodes = TestUtils.createSampleAudioFileList(maxEpisodes);

      await tester.pumpWidget(
        TestUtils.wrapWithMaterialApp(
          AudioList(
            episodes: episodes,
            onEpisodeTap: (episode) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should handle large datasets without crashing
      expect(find.byType(AudioList), findsOneWidget);

      // Only visible items should be rendered due to lazy loading
      final renderedCards = find.byType(AudioItemCard);
      expect(
          renderedCards.evaluate().length, lessThan(100)); // Much less than 10k
    });

    testWidgets('invalid callback handling', (tester) async {
      // Test with null callbacks (should not crash)
      await tester.pumpWidget(
        TestUtils.wrapWithMaterialApp(
          AudioList(
            episodes: TestUtils.createSampleAudioFileList(3),
            onEpisodeTap: (episode) {
              // Simulate callback that might throw
              throw Exception('Test exception in callback');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AudioList), findsOneWidget);

      // Tapping should be handled gracefully even if callback throws
      final audioCards = find.byType(AudioItemCard);
      if (audioCards.evaluate().isNotEmpty) {
        // This might throw but shouldn't crash the widget
        try {
          await tester.tap(audioCards.first);
          await tester.pump();
        } catch (e) {
          // Expected to catch the exception
        }
      }

      // Widget should still be functional
      expect(find.byType(AudioList), findsOneWidget);
    });

    testWidgets('memory boundary conditions', (tester) async {
      // Test rapid widget creation and disposal
      for (int i = 0; i < 50; i++) {
        await tester.pumpWidget(
          TestUtils.wrapWithMaterialApp(
            AudioList(
              episodes: TestUtils.createSampleAudioFileList(20),
              onEpisodeTap: (episode) {},
            ),
          ),
        );
        await tester.pump();

        // Immediately replace with new widget
        await tester.pumpWidget(
          TestUtils.wrapWithMaterialApp(
            Text('Cycle $i'),
          ),
        );
        await tester.pump();
      }

      // Should handle rapid creation/disposal without memory leaks
      expect(find.text('Cycle 49'), findsOneWidget);
    });

    testWidgets('zero and negative dimensions', (tester) async {
      // Test with zero width container
      await tester.pumpWidget(
        TestUtils.wrapWithMaterialApp(
          SizedBox(
            width: 0,
            child: FilterBar(
              selectedLanguage: 'zh-TW',
              selectedCategory: 'all',
              onLanguageChanged: (value) {},
              onCategoryChanged: (value) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should handle zero width gracefully
      expect(find.byType(FilterBar), findsOneWidget);

      // Test with zero height container
      await tester.pumpWidget(
        TestUtils.wrapWithMaterialApp(
          SizedBox(
            height: 0,
            child: AudioList(
              episodes: TestUtils.createSampleAudioFileList(3),
              onEpisodeTap: (episode) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AudioList), findsOneWidget);
    });

    testWidgets('extremely long audio file properties', (tester) async {
      final extremeEpisode = AudioFile(
        id: 'a' * 1000, // Very long ID
        title:
            'This is an extremely long title that should test how the UI handles very long text content that might overflow or cause layout issues in the audio item cards and other components',
        language: 'extremely-long-language-code-that-tests-boundaries',
        category: 'extremely-long-category-name-for-boundary-testing',
        streamingUrl: 'https://example.com/${'very-long-path/' * 50}audio.m3u8',
        path:
            '/extremely/long/file/path/that/tests/how/the/system/handles/very/long/file/paths/audio.m3u8',
        duration: const Duration(
            hours: 999, minutes: 59, seconds: 59), // Extreme duration
        fileSizeBytes: 999999999999, // Very large file size
        lastModified: DateTime(1900), // Very old date
      );

      await tester.pumpWidget(
        TestUtils.wrapWithMaterialApp(
          AudioList(
            episodes: [extremeEpisode],
            onEpisodeTap: (episode) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should handle extreme values gracefully
      expect(find.byType(AudioList), findsOneWidget);
      expect(find.byType(AudioItemCard), findsOneWidget);
    });

    testWidgets('concurrent state modifications', (tester) async {
      String selectedLanguage = 'zh-TW';
      String selectedCategory = 'all';
      bool isModifying = false;

      await tester.pumpWidget(
        TestUtils.wrapWithMaterialApp(
          StatefulBuilder(
            builder: (context, setState) {
              return FilterBar(
                selectedLanguage: selectedLanguage,
                selectedCategory: selectedCategory,
                onLanguageChanged: (language) {
                  if (!isModifying) {
                    isModifying = true;
                    setState(() {
                      selectedLanguage = language;
                      // Simulate concurrent modification
                      selectedCategory = 'daily-news';
                    });
                    isModifying = false;
                  }
                },
                onCategoryChanged: (category) {
                  if (!isModifying) {
                    isModifying = true;
                    setState(() {
                      selectedCategory = category;
                      // Simulate concurrent modification
                      selectedLanguage = 'en-US';
                    });
                    isModifying = false;
                  }
                },
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Test concurrent modifications
      final englishChip = find.text('🇺🇸 English');
      if (englishChip.evaluate().isNotEmpty) {
        await tester.tap(englishChip.first);
        await tester.pumpAndSettle();
      }

      // Should handle concurrent state changes without crashing
      expect(find.byType(FilterBar), findsOneWidget);
    });

    testWidgets('invalid episode data structures', (tester) async {
      // Create episodes with edge case data
      final invalidEpisodes = [
        AudioFile(
          id: '', // Empty ID
          title: '', // Empty title
          language: '',
          category: '',
          streamingUrl: '',
          path: '',
          duration: Duration.zero,
          fileSizeBytes: 0,
          lastModified: DateTime(1970), // Unix epoch
        ),
        AudioFile(
          id: 'null-test',
          title: 'null', // String "null"
          language: 'undefined',
          category: 'null',
          streamingUrl: 'null',
          path: 'null',
          duration: const Duration(seconds: -1), // Negative duration
          fileSizeBytes: -1, // Negative file size
          lastModified: DateTime(2100), // Future date
        ),
      ];

      await tester.pumpWidget(
        TestUtils.wrapWithMaterialApp(
          AudioList(
            episodes: invalidEpisodes,
            onEpisodeTap: (episode) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should handle invalid data gracefully
      expect(find.byType(AudioList), findsOneWidget);
      expect(find.byType(AudioItemCard), findsNWidgets(invalidEpisodes.length));
    });

    testWidgets('filter state persistence under extreme conditions',
        (tester) async {
      String selectedLanguage = 'zh-TW';
      String selectedCategory = 'all';

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
                  Text('State: $selectedLanguage - $selectedCategory'),
                ],
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Perform extreme number of state changes rapidly
      for (int i = 0; i < 1000; i++) {
        final languages = ['🇺🇸 English', '🇯🇵 日本語', '🇹🇼 繁中'];
        final language = languages[i % languages.length];

        final langFinder = find.text(language);
        if (langFinder.evaluate().isNotEmpty) {
          await tester.tap(langFinder.first);
          await tester.pump();
        }

        // Every 100 iterations, verify state is consistent
        if (i % 100 == 0) {
          expect(find.byType(FilterBar), findsOneWidget);
          expect(find.textContaining('State:'), findsOneWidget);
        }
      }

      await tester.pumpAndSettle();

      // Final verification
      expect(find.byType(FilterBar), findsOneWidget);
      expect(find.textContaining('State:'), findsOneWidget);
    });

    testWidgets('widget rebuilding under memory pressure', (tester) async {
      // Simulate memory pressure by creating many large objects
      final largeDataSets = <List<AudioFile>>[];

      for (int i = 0; i < 20; i++) {
        largeDataSets.add(TestUtils.createSampleAudioFileList(500));
      }

      // Test widget performance under memory pressure
      await tester.pumpWidget(
        TestUtils.wrapWithMaterialApp(
          StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  Text('Dataset count: ${largeDataSets.length}'),
                  Expanded(
                    child: AudioList(
                      episodes:
                          largeDataSets.isNotEmpty ? largeDataSets.first : [],
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

      // Should handle memory pressure gracefully
      expect(find.textContaining('Dataset count:'), findsOneWidget);
      expect(find.byType(AudioList), findsOneWidget);

      // Clear large data sets
      largeDataSets.clear();
    });

    testWidgets('rapid widget disposal and recreation', (tester) async {
      // Test rapid disposal and recreation cycles
      for (int cycle = 0; cycle < 100; cycle++) {
        await tester.pumpWidget(
          TestUtils.wrapWithMaterialApp(
            AudioList(
              episodes: TestUtils.createSampleAudioFileList(10),
              onEpisodeTap: (episode) {},
            ),
          ),
        );
        await tester.pump();

        // Immediately dispose and recreate
        await tester.pumpWidget(
          TestUtils.wrapWithMaterialApp(
            const SizedBox.shrink(),
          ),
        );
        await tester.pump();

        // Verify no crashes occur
        if (cycle % 20 == 0) {
          expect(find.byType(SizedBox), findsOneWidget);
        }
      }

      // Final verification
      await tester.pumpWidget(
        TestUtils.wrapWithMaterialApp(
          const Text('Test completed'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test completed'), findsOneWidget);
    });

    testWidgets('boundary values for numeric properties', (tester) async {
      final boundaryEpisode = AudioFile(
        id: '0',
        title: 'Boundary Test',
        language: 'test',
        category: 'test',
        streamingUrl: 'test://boundary',
        path: '/boundary/test',
        duration: const Duration(
          days: 365 * 100, // 100 years
          hours: 23,
          minutes: 59,
          seconds: 59,
          milliseconds: 999,
        ),
        fileSizeBytes: 9223372036854775807, // Max int64
        lastModified:
            DateTime.fromMillisecondsSinceEpoch(0), // Unix epoch start
      );

      await tester.pumpWidget(
        TestUtils.wrapWithMaterialApp(
          AudioList(
            episodes: [boundaryEpisode],
            onEpisodeTap: (episode) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should handle boundary numeric values
      expect(find.byType(AudioList), findsOneWidget);
      expect(find.byType(AudioItemCard), findsOneWidget);

      // Test interaction with boundary value episode
      await tester.tap(find.byType(AudioItemCard));
      await tester.pump();
    });
  });
}
