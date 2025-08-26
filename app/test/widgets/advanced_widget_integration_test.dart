import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:from_fed_to_chain_app/widgets/filter_bar.dart';
import 'package:from_fed_to_chain_app/widgets/audio_list.dart';
import 'package:from_fed_to_chain_app/widgets/audio_item_card.dart';
import 'package:from_fed_to_chain_app/models/audio_file.dart';

import '../test_utils.dart';

void main() {
  group('Advanced Widget Integration Tests', () {
    testWidgets('filter bar and audio list coordination', (tester) async {
      String selectedLanguage = 'zh-TW';
      String selectedCategory = 'all';
      List<AudioFile> currentEpisodes = TestUtils.createSampleAudioFileList(10);
      List<AudioFile> filteredEpisodes = currentEpisodes;

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
                        // Simulate filtering by language
                        filteredEpisodes = currentEpisodes
                            .where((e) => e.language == language)
                            .toList();
                      });
                    },
                    onCategoryChanged: (category) {
                      setState(() {
                        selectedCategory = category;
                        // Simulate filtering by category
                        if (category == 'all') {
                          filteredEpisodes = currentEpisodes
                              .where((e) => e.language == selectedLanguage)
                              .toList();
                        } else {
                          filteredEpisodes = currentEpisodes
                              .where((e) =>
                                  e.language == selectedLanguage &&
                                  e.category == category)
                              .toList();
                        }
                      });
                    },
                  ),
                  Text('Showing ${filteredEpisodes.length} episodes'),
                  Text(
                      'Language: $selectedLanguage, Category: $selectedCategory'),
                  Expanded(
                    child: AudioList(
                      episodes: filteredEpisodes,
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

      // Test initial state
      expect(find.text('Language: zh-TW, Category: all'), findsOneWidget);
      expect(find.textContaining('Showing'), findsOneWidget);

      // Test language change affects list
      final englishChip = find.text('🇺🇸 English');
      if (englishChip.evaluate().isNotEmpty) {
        await tester.tap(englishChip.first);
        await tester.pumpAndSettle();

        expect(find.text('Language: en-US, Category: all'), findsOneWidget);
        // List should update based on language filter
        expect(find.byType(AudioList), findsOneWidget);
      }

      // Test category change affects list
      final newsChip = find.textContaining('📰');
      if (newsChip.evaluate().isNotEmpty) {
        await tester.tap(newsChip.first);
        await tester.pumpAndSettle();

        expect(
            find.text('Language: en-US, Category: daily-news'), findsOneWidget);
        // List should update based on category filter
        expect(find.byType(AudioList), findsOneWidget);
      }
    });

    testWidgets('audio item card interaction with parent list', (tester) async {
      final episodes = TestUtils.createSampleAudioFileList(3);
      AudioFile? selectedEpisode;
      bool longPressTriggered = false;

      await tester.pumpWidget(
        TestUtils.wrapWithMaterialApp(
          AudioList(
            episodes: episodes,
            onEpisodeTap: (episode) {
              selectedEpisode = episode;
            },
            onEpisodeLongPress: (episode) {
              longPressTriggered = true;
              selectedEpisode = episode;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Test tap interaction
      final audioCards = find.byType(AudioItemCard);
      expect(audioCards, findsAtLeastNWidgets(1));

      await tester.tap(audioCards.first);
      await tester.pumpAndSettle();

      expect(selectedEpisode, isNotNull);
      expect(selectedEpisode?.id, equals(episodes.first.id));

      // Test long press interaction
      selectedEpisode = null;
      await tester.longPress(audioCards.first);
      await tester.pumpAndSettle();

      expect(longPressTriggered, isTrue);
      expect(selectedEpisode, isNotNull);
    });

    testWidgets('scrollable list with dynamic content updates', (tester) async {
      List<AudioFile> episodes = TestUtils.createSampleAudioFileList(20);

      await tester.pumpWidget(
        TestUtils.wrapWithMaterialApp(
          StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        episodes.addAll(TestUtils.createSampleAudioFileList(5));
                      });
                    },
                    child: const Text('Load More'),
                  ),
                  Text('Total: ${episodes.length} episodes'),
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

      // Test initial state
      expect(find.text('Total: 20 episodes'), findsOneWidget);

      // Test scrolling
      final audioList = find.byType(AudioList);
      await tester.drag(audioList, const Offset(0, -300));
      await tester.pumpAndSettle();

      // Test dynamic content addition
      await tester.tap(find.text('Load More'));
      await tester.pumpAndSettle();

      expect(find.text('Total: 25 episodes'), findsOneWidget);

      // Test scroll to top after content update
      await tester.drag(audioList, const Offset(0, 300));
      await tester.pumpAndSettle();
    });

    testWidgets('filter bar language persistence during category changes',
        (tester) async {
      String selectedLanguage = 'en-US';
      String selectedCategory = 'all';
      List<String> categoryChangeLog = [];
      List<String> languageChangeLog = [];

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
                        languageChangeLog.add(language);
                      });
                    },
                    onCategoryChanged: (category) {
                      setState(() {
                        selectedCategory = category;
                        categoryChangeLog.add(category);
                      });
                    },
                  ),
                  Text('Language: $selectedLanguage'),
                  Text('Category: $selectedCategory'),
                  Text('Language changes: ${languageChangeLog.length}'),
                  Text('Category changes: ${categoryChangeLog.length}'),
                ],
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Set initial language to English
      final englishChip = find.text('🇺🇸 English');
      if (englishChip.evaluate().isNotEmpty) {
        await tester.tap(englishChip.first);
        await tester.pumpAndSettle();
      }

      // Change categories multiple times
      final categories = ['📰', '⚡', '📊', 'All'];
      for (final category in categories) {
        final categoryFinder = find.textContaining(category);
        if (categoryFinder.evaluate().isNotEmpty) {
          await tester.tap(categoryFinder.first);
          await tester.pumpAndSettle();
        }
      }

      // Language should remain English throughout
      expect(find.text('Language: en-US'), findsOneWidget);
      expect(find.textContaining('Category changes:'), findsOneWidget);

      // Language should not have changed during category switches
      expect(languageChangeLog.length,
          lessThanOrEqualTo(1)); // Only the initial change
    });

    testWidgets('audio list empty state and reload', (tester) async {
      List<AudioFile> episodes = [];
      bool isLoading = false;

      await tester.pumpWidget(
        TestUtils.wrapWithMaterialApp(
          StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  if (isLoading)
                    const CircularProgressIndicator()
                  else
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isLoading = true;
                        });
                        Future.delayed(const Duration(milliseconds: 500), () {
                          setState(() {
                            episodes = TestUtils.createSampleAudioFileList(5);
                            isLoading = false;
                          });
                        });
                      },
                      child: const Text('Load Episodes'),
                    ),
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

      // Test empty state
      expect(find.byType(AudioItemCard), findsNothing);
      expect(find.text('Load Episodes'), findsOneWidget);

      // Test loading state
      await tester.tap(find.text('Load Episodes'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for episodes to load
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Test loaded state
      expect(find.byType(AudioItemCard), findsAtLeastNWidgets(1));
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('filter bar responsive design', (tester) async {
      await tester.pumpWidget(
        TestUtils.wrapWithMaterialApp(
          SizedBox(
            width: 300, // Narrow width
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

      // Should render without overflow in narrow width
      expect(find.byType(FilterBar), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsAtLeastNWidgets(1));

      // Test horizontal scrolling
      final scrollView = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollView, const Offset(-50, 0));
      await tester.pumpAndSettle();

      expect(find.byType(FilterBar), findsOneWidget);
    });

    testWidgets('widget memory management under stress', (tester) async {
      // Create and destroy many widgets to test memory management
      for (int i = 0; i < 5; i++) {
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

        // Scroll through content
        await tester.drag(find.byType(AudioList), const Offset(0, -500));
        await tester.pumpAndSettle();

        await tester.drag(find.byType(AudioList), const Offset(0, 500));
        await tester.pumpAndSettle();

        // Replace with new widget
        await tester.pumpWidget(
          TestUtils.wrapWithMaterialApp(
            Text('Iteration $i'),
          ),
        );
        await tester.pumpAndSettle();
      }

      // Final verification
      expect(find.text('Iteration 4'), findsOneWidget);
    });

    testWidgets('complex nested widget interactions', (tester) async {
      String selectedLanguage = 'zh-TW';
      String selectedCategory = 'all';
      AudioFile? selectedEpisode;
      final episodes = TestUtils.createSampleAudioFileList(8);

      await tester.pumpWidget(
        TestUtils.wrapWithMaterialApp(
          StatefulBuilder(
            builder: (context, setState) {
              final filteredEpisodes = episodes.where((episode) {
                final languageMatch = selectedLanguage == 'all' ||
                    episode.language == selectedLanguage;
                final categoryMatch = selectedCategory == 'all' ||
                    episode.category == selectedCategory;
                return languageMatch && categoryMatch;
              }).toList();

              return Column(
                children: [
                  FilterBar(
                    selectedLanguage: selectedLanguage,
                    selectedCategory: selectedCategory,
                    onLanguageChanged: (language) {
                      setState(() {
                        selectedLanguage = language;
                        selectedEpisode =
                            null; // Clear selection on filter change
                      });
                    },
                    onCategoryChanged: (category) {
                      setState(() {
                        selectedCategory = category;
                        selectedEpisode =
                            null; // Clear selection on filter change
                      });
                    },
                  ),
                  if (selectedEpisode != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.blue.withOpacity(0.1),
                      child: Text('Selected: ${selectedEpisode!.title}'),
                    ),
                  Text(
                      'Showing ${filteredEpisodes.length} of ${episodes.length} episodes'),
                  Expanded(
                    child: AudioList(
                      episodes: filteredEpisodes,
                      onEpisodeTap: (episode) {
                        setState(() {
                          selectedEpisode = episode;
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

      // Test initial state
      expect(find.textContaining('Showing'), findsOneWidget);

      // Select an episode
      final audioCards = find.byType(AudioItemCard);
      if (audioCards.evaluate().isNotEmpty) {
        await tester.tap(audioCards.first);
        await tester.pumpAndSettle();

        expect(find.textContaining('Selected:'), findsOneWidget);
      }

      // Change filter and verify selection is cleared
      final englishChip = find.text('🇺🇸 English');
      if (englishChip.evaluate().isNotEmpty) {
        await tester.tap(englishChip.first);
        await tester.pumpAndSettle();

        expect(find.textContaining('Selected:'), findsNothing);
      }
    });

    testWidgets('widget lifecycle and cleanup', (tester) async {
      await tester.pumpWidget(
        TestUtils.wrapWithMaterialApp(
          StatefulBuilder(
            builder: (context, setState) {
              return AudioList(
                episodes: TestUtils.createSampleAudioFileList(3),
                onEpisodeTap: (episode) {},
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AudioList), findsOneWidget);

      // Replace widget to trigger disposal
      await tester.pumpWidget(
        TestUtils.wrapWithMaterialApp(
          const Text('Replaced'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AudioList), findsNothing);
      expect(find.text('Replaced'), findsOneWidget);
    });
  });
}
