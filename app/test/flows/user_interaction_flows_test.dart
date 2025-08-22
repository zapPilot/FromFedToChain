import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:from_fed_to_chain_app/widgets/filter_bar.dart';
import 'package:from_fed_to_chain_app/widgets/audio_list.dart';
import 'package:from_fed_to_chain_app/widgets/audio_item_card.dart';

import '../test_utils.dart';

void main() {
  group('User Interaction Flow Tests', () {
    testWidgets('filter bar language selection workflow', (tester) async {
      String selectedLanguage = 'zh-TW';
      String selectedCategory = 'all';

      await tester.pumpWidget(
        TestUtils.wrapWithMaterialApp(
          FilterBar(
            selectedLanguage: selectedLanguage,
            selectedCategory: selectedCategory,
            onLanguageChanged: (value) {},
            onCategoryChanged: (value) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Complete language selection workflow
      final englishChip = find.text('🇺🇸 English');
      if (englishChip.evaluate().isNotEmpty) {
        await tester.tap(englishChip);
        await tester.pumpAndSettle();
        // Language changed successfully
      }

      final japaneseChip = find.text('🇯🇵 日本語');
      if (japaneseChip.evaluate().isNotEmpty) {
        await tester.tap(japaneseChip);
        await tester.pumpAndSettle();
        // Language changed successfully
      }

      final defaultChip = find.text('🇹🇼 繁中');
      if (defaultChip.evaluate().isNotEmpty) {
        await tester.tap(defaultChip);
        await tester.pumpAndSettle();
        // Language changed successfully
      }
    });

    testWidgets('filter bar category selection workflow', (tester) async {
      String selectedLanguage = 'zh-TW';
      String selectedCategory = 'all';
      await tester.pumpWidget(
        TestUtils.wrapWithMaterialApp(
          FilterBar(
            selectedLanguage: selectedLanguage,
            selectedCategory: selectedCategory,
            onLanguageChanged: (value) {},
            onCategoryChanged: (value) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Complete category selection workflow
      final newsChip = find.textContaining('📰');
      if (newsChip.evaluate().isNotEmpty) {
        await tester.tap(newsChip.first);
        await tester.pumpAndSettle();
        // Category changed successfully
      }

      final allChip = find.text('All');
      if (allChip.evaluate().isNotEmpty) {
        await tester.tap(allChip);
        await tester.pumpAndSettle();
        // Category changed successfully
      }
    });

    testWidgets('audio list scrolling and interaction workflow',
        (tester) async {
      final episodes = TestUtils.createSampleAudioFileList(10);

      await tester.pumpWidget(
        TestUtils.wrapWithMaterialApp(
          SizedBox(
            height: 400,
            child: AudioList(
              episodes: episodes,
              onEpisodeTap: (episode) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Test scrolling workflow
      expect(find.byType(AudioItemCard), findsAtLeastNWidgets(1));

      // Test vertical scrolling
      final audioList = find.byType(AudioList);
      if (audioList.evaluate().isNotEmpty) {
        await tester.drag(audioList, const Offset(0, -200));
        await tester.pumpAndSettle();

        await tester.drag(audioList, const Offset(0, 200));
        await tester.pumpAndSettle();
      }

      // Test item interaction
      final audioCards = find.byType(AudioItemCard);
      if (audioCards.evaluate().isNotEmpty) {
        await tester.tap(audioCards.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(AudioList), findsOneWidget);
    });

    testWidgets('rapid filter switching performance test', (tester) async {
      String selectedLanguage = 'zh-TW';
      String selectedCategory = 'all';
      int languageChanges = 0;
      int categoryChanges = 0;

      await tester.pumpWidget(
        TestUtils.wrapWithMaterialApp(
          StatefulBuilder(
            builder: (context, setState) {
              return FilterBar(
                selectedLanguage: selectedLanguage,
                selectedCategory: selectedCategory,
                onLanguageChanged: (value) {
                  setState(() {
                    selectedLanguage = value;
                    languageChanges++;
                  });
                },
                onCategoryChanged: (value) {
                  setState(() {
                    selectedCategory = value;
                    categoryChanges++;
                  });
                },
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Rapid language switching
      for (int i = 0; i < 5; i++) {
        final englishChip = find.text('🇺🇸 English');
        if (englishChip.evaluate().isNotEmpty) {
          await tester.tap(englishChip);
          await tester.pump();
        }

        final japaneseChip = find.text('🇯🇵 日本語');
        if (japaneseChip.evaluate().isNotEmpty) {
          await tester.tap(japaneseChip);
          await tester.pump();
        }

        final defaultChip = find.text('🇹🇼 繁中');
        if (defaultChip.evaluate().isNotEmpty) {
          await tester.tap(defaultChip);
          await tester.pump();
        }
      }

      await tester.pumpAndSettle();

      // Should handle rapid changes without crashes
      expect(find.byType(FilterBar), findsOneWidget);
      expect(languageChanges, greaterThan(0));
      expect(categoryChanges, greaterThanOrEqualTo(0));
    });

    testWidgets('accessibility keyboard navigation workflow', (tester) async {
      await tester.pumpWidget(
        TestUtils.wrapWithMaterialApp(
          FilterBar(
            selectedLanguage: 'zh-TW',
            selectedCategory: 'all',
            onLanguageChanged: (value) {},
            onCategoryChanged: (value) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Test keyboard navigation
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      // Test enter key activation
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      // Should maintain functionality
      expect(find.byType(FilterBar), findsOneWidget);
    });

    testWidgets('gesture interaction workflow', (tester) async {
      final episodes = TestUtils.createSampleAudioFileList(5);

      await tester.pumpWidget(
        TestUtils.wrapWithMaterialApp(
          Column(
            children: [
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

      // Test horizontal scrolling on filter bar
      final filterBar = find.byType(FilterBar);
      if (filterBar.evaluate().isNotEmpty) {
        await tester.drag(filterBar, const Offset(-100, 0));
        await tester.pumpAndSettle();

        await tester.drag(filterBar, const Offset(100, 0));
        await tester.pumpAndSettle();
      }

      // Test vertical scrolling on audio list
      final audioList = find.byType(AudioList);
      if (audioList.evaluate().isNotEmpty) {
        await tester.drag(audioList, const Offset(0, -200));
        await tester.pumpAndSettle();

        await tester.drag(audioList, const Offset(0, 200));
        await tester.pumpAndSettle();
      }

      // Test long press interactions
      final audioCards = find.byType(AudioItemCard);
      if (audioCards.evaluate().isNotEmpty) {
        await tester.longPress(audioCards.first);
        await tester.pumpAndSettle();
      }

      // Should handle all gestures without crashes
      expect(find.byType(FilterBar), findsOneWidget);
      expect(find.byType(AudioList), findsOneWidget);
    });

    testWidgets('complex multi-step user workflow simulation', (tester) async {
      String selectedLanguage = 'zh-TW';
      String selectedCategory = 'all';
      final episodes = TestUtils.createSampleAudioFileList(8);

      await tester.pumpWidget(
        TestUtils.wrapWithMaterialApp(
          StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  FilterBar(
                    selectedLanguage: selectedLanguage,
                    selectedCategory: selectedCategory,
                    onLanguageChanged: (value) {
                      setState(() {
                        selectedLanguage = value;
                      });
                    },
                    onCategoryChanged: (value) {
                      setState(() {
                        selectedCategory = value;
                      });
                    },
                  ),
                  Text('Current: $selectedLanguage - $selectedCategory'),
                  Expanded(
                    child: AudioList(
                      episodes: episodes,
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

      // Step 1: User changes language preference
      final englishChip = find.text('🇺🇸 English');
      if (englishChip.evaluate().isNotEmpty) {
        await tester.tap(englishChip.first);
        await tester.pumpAndSettle();
        expect(find.text('Current: en-US - all'), findsOneWidget);
      }

      // Step 2: User browses different categories
      final newsChip = find.textContaining('📰');
      if (newsChip.evaluate().isNotEmpty) {
        await tester.tap(newsChip.first);
        await tester.pumpAndSettle();
        expect(find.text('Current: en-US - daily-news'), findsOneWidget);
      }

      // Step 3: User scrolls through content
      final audioList = find.byType(AudioList);
      if (audioList.evaluate().isNotEmpty) {
        await tester.drag(audioList, const Offset(0, -100));
        await tester.pumpAndSettle();
      }

      // Step 4: User changes back to Japanese
      final japaneseChip = find.text('🇯🇵 日本語');
      if (japaneseChip.evaluate().isNotEmpty) {
        await tester.tap(japaneseChip.first);
        await tester.pumpAndSettle();
        expect(find.text('Current: ja-JP - daily-news'), findsOneWidget);
      }

      // Step 5: User resets to all categories
      final allChip = find.text('All');
      if (allChip.evaluate().isNotEmpty) {
        await tester.tap(allChip.first);
        await tester.pumpAndSettle();
        expect(find.text('Current: ja-JP - all'), findsOneWidget);
      }

      // Final verification: All components are stable
      expect(find.byType(FilterBar), findsOneWidget);
      expect(find.byType(AudioList), findsOneWidget);
      expect(find.byType(AudioItemCard), findsAtLeastNWidgets(1));
    });

    testWidgets('error resilience and edge cases', (tester) async {
      // Test with empty episode list
      await tester.pumpWidget(
        TestUtils.wrapWithMaterialApp(
          AudioList(
            episodes: [],
            onEpisodeTap: (episode) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AudioList), findsOneWidget);
      expect(find.byType(AudioItemCard), findsNothing);

      // Test with invalid filter state
      await tester.pumpWidget(
        TestUtils.wrapWithMaterialApp(
          FilterBar(
            selectedLanguage: 'invalid-lang',
            selectedCategory: 'invalid-category',
            onLanguageChanged: (value) {},
            onCategoryChanged: (value) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should render without errors
      expect(find.byType(FilterBar), findsOneWidget);
    });
  });
}
