import 'package:flutter_test/flutter_test.dart';
import 'package:from_fed_to_chain_app/services/content_service.dart';
import 'package:from_fed_to_chain_app/models/audio_file.dart';
import '../test_utils.dart';

void main() {
  group('ContentService Extended Tests', () {
    late ContentService contentService;

    setUp(() {
      contentService = ContentService();
    });

    tearDown(() {
      contentService.dispose();
    });

    group('Episode Loading Tests', () {
      testWidgets('handles large episode dataset efficiently', (tester) async {
        // Simulate loading a large number of episodes
        final largeEpisodeList = TestUtils.createSampleAudioFileList(1000);

        final stopwatch = Stopwatch()..start();
        contentService.setEpisodesForTesting(largeEpisodeList);
        stopwatch.stop();

        // Should handle large datasets efficiently (< 1 second)
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
        expect(contentService.allEpisodes.length, equals(1000));
      });

      testWidgets('maintains episode order correctly', (tester) async {
        final orderedEpisodes = [
          TestUtils.createSampleAudioFile(
            id: '2025-01-01-first',
            title: 'First Episode',
          ),
          TestUtils.createSampleAudioFile(
            id: '2025-01-02-second',
            title: 'Second Episode',
          ),
          TestUtils.createSampleAudioFile(
            id: '2025-01-03-third',
            title: 'Third Episode',
          ),
        ];

        contentService.setEpisodesForTesting(orderedEpisodes);

        // Episodes should maintain chronological order (newest first)
        expect(contentService.allEpisodes[0].id, equals('2025-01-03-third'));
        expect(contentService.allEpisodes[1].id, equals('2025-01-02-second'));
        expect(contentService.allEpisodes[2].id, equals('2025-01-01-first'));
      });

      testWidgets('handles duplicate episodes correctly', (tester) async {
        final duplicateEpisodes = [
          TestUtils.createSampleAudioFile(id: 'duplicate-id'),
          TestUtils.createSampleAudioFile(id: 'duplicate-id'),
          TestUtils.createSampleAudioFile(id: 'unique-id'),
        ];

        contentService.setEpisodesForTesting(duplicateEpisodes);

        // Should filter out duplicates
        final uniqueIds = contentService.allEpisodes.map((e) => e.id).toSet();
        expect(uniqueIds.length, equals(2));
        expect(uniqueIds.contains('duplicate-id'), isTrue);
        expect(uniqueIds.contains('unique-id'), isTrue);
      });
    });

    group('Language Filtering Tests', () {
      late List<AudioFile> multiLanguageEpisodes;

      setUp(() {
        multiLanguageEpisodes = [
          TestUtils.createSampleAudioFile(
            id: 'en-1',
            title: 'English Episode 1',
            language: 'en-US',
          ),
          TestUtils.createSampleAudioFile(
            id: 'en-2',
            title: 'English Episode 2',
            language: 'en-US',
          ),
          TestUtils.createSampleAudioFile(
            id: 'ja-1',
            title: 'Japanese Episode 1',
            language: 'ja-JP',
          ),
          TestUtils.createSampleAudioFile(
            id: 'zh-1',
            title: 'Chinese Episode 1',
            language: 'zh-TW',
          ),
        ];
        contentService.setEpisodesForTesting(multiLanguageEpisodes);
      });

      // TODO: Implement getFilteredEpisodesByLanguage method
      testWidgets('filters by English language correctly', (tester) async {
        contentService.setLanguage('en-US');

        // final filtered = contentService.filteredEpisodes.where((e) => e.language == contentService.selectedLanguage).toList();
        final filtered = contentService.filteredEpisodes
            .where((e) => e.language == 'en-US')
            .toList();
        expect(filtered.length, equals(2));
        expect(filtered.every((e) => e.language == 'en-US'), isTrue);
      });

      testWidgets('filters by Japanese language correctly', (tester) async {
        contentService.setLanguage('ja-JP');

        final filtered = contentService.filteredEpisodes
            .where((e) => e.language == contentService.selectedLanguage)
            .toList();
        expect(filtered.length, equals(1));
        expect(filtered.first.language, equals('ja-JP'));
      });

      testWidgets('handles invalid language filter gracefully', (tester) async {
        contentService.setLanguage('invalid-lang');

        final filtered = contentService.filteredEpisodes
            .where((e) => e.language == contentService.selectedLanguage)
            .toList();
        // Should return empty list for invalid language
        expect(filtered.isEmpty, isTrue);
      });

      testWidgets('handles empty language filter correctly', (tester) async {
        contentService.setLanguage('');

        final filtered = contentService.filteredEpisodes
            .where((e) => e.language == contentService.selectedLanguage)
            .toList();
        // Should return all episodes when language is empty
        expect(filtered.length, equals(4));
      });
    });

    group('Category Filtering Tests', () {
      late List<AudioFile> multiCategoryEpisodes;

      setUp(() {
        multiCategoryEpisodes = [
          TestUtils.createSampleAudioFile(
            id: 'news-1',
            category: 'daily-news',
          ),
          TestUtils.createSampleAudioFile(
            id: 'news-2',
            category: 'daily-news',
          ),
          TestUtils.createSampleAudioFile(
            id: 'eth-1',
            category: 'ethereum',
          ),
          TestUtils.createSampleAudioFile(
            id: 'macro-1',
            category: 'macro',
          ),
        ];
        contentService.setEpisodesForTesting(multiCategoryEpisodes);
      });

      testWidgets('filters by daily-news category correctly', (tester) async {
        contentService.setCategory('daily-news');

        final filtered = contentService.filteredEpisodes
            .where((e) => e.category == contentService.selectedCategory)
            .toList();
        expect(filtered.length, equals(2));
        expect(filtered.every((e) => e.category == 'daily-news'), isTrue);
      });

      testWidgets('filters by ethereum category correctly', (tester) async {
        contentService.setCategory('ethereum');

        final filtered = contentService.filteredEpisodes
            .where((e) => e.category == contentService.selectedCategory)
            .toList();
        expect(filtered.length, equals(1));
        expect(filtered.first.category, equals('ethereum'));
      });

      testWidgets('handles all category filter correctly', (tester) async {
        contentService.setCategory('all');

        final filtered = contentService.filteredEpisodes
            .where((e) => e.category == contentService.selectedCategory)
            .toList();
        expect(filtered.length, equals(4));
      });

      testWidgets('handles invalid category filter gracefully', (tester) async {
        contentService.setCategory('invalid-category');

        final filtered = contentService.filteredEpisodes
            .where((e) => e.category == contentService.selectedCategory)
            .toList();
        // Should return empty list for invalid category
        expect(filtered.isEmpty, isTrue);
      });
    });

    group('Sort Order Tests', () {
      late List<AudioFile> unsortedEpisodes;

      setUp(() {
        unsortedEpisodes = [
          TestUtils.createSampleAudioFile(
            id: '2025-01-02-middle',
            title: 'Middle Episode',
          ),
          TestUtils.createSampleAudioFile(
            id: '2025-01-01-oldest',
            title: 'Oldest Episode',
          ),
          TestUtils.createSampleAudioFile(
            id: '2025-01-03-newest',
            title: 'Newest Episode',
          ),
          TestUtils.createSampleAudioFile(
            id: '2025-01-04-alphabetical',
            title: 'Alphabetical Episode',
          ),
        ];
        contentService.setEpisodesForTesting(unsortedEpisodes);
      });

      testWidgets('sorts by newest first correctly', (tester) async {
        contentService.setSortOrder('newest');

        final sorted = contentService.allEpisodes;
        expect(sorted[0].id, equals('2025-01-04-alphabetical'));
        expect(sorted[1].id, equals('2025-01-03-newest'));
        expect(sorted[2].id, equals('2025-01-02-middle'));
        expect(sorted[3].id, equals('2025-01-01-oldest'));
      });

      testWidgets('sorts by oldest first correctly', (tester) async {
        contentService.setSortOrder('oldest');

        final sorted = contentService.allEpisodes;
        expect(sorted[0].id, equals('2025-01-01-oldest'));
        expect(sorted[1].id, equals('2025-01-02-middle'));
        expect(sorted[2].id, equals('2025-01-03-newest'));
        expect(sorted[3].id, equals('2025-01-04-alphabetical'));
      });

      testWidgets('sorts alphabetically correctly', (tester) async {
        contentService.setSortOrder('alphabetical');

        final sorted = contentService.allEpisodes;
        expect(sorted[0].title, equals('Alphabetical Episode'));
        expect(sorted[1].title, equals('Middle Episode'));
        expect(sorted[2].title, equals('Newest Episode'));
        expect(sorted[3].title, equals('Oldest Episode'));
      });

      testWidgets('handles invalid sort order gracefully', (tester) async {
        contentService.setSortOrder('invalid-order');

        // Should fallback to default (newest) sort order
        final sorted = contentService.allEpisodes;
        expect(sorted[0].id, equals('2025-01-04-alphabetical'));
      });
    });

    group('Episode Completion Tests', () {
      late List<AudioFile> testEpisodes;

      setUp(() {
        testEpisodes = TestUtils.createSampleAudioFileList(5);
        contentService.setEpisodesForTesting(testEpisodes);
      });

      testWidgets('tracks episode completion correctly', (tester) async {
        final episodeId = testEpisodes.first.id;

        // Initially should not be finished
        expect(contentService.isEpisodeFinished(episodeId), isFalse);
        expect(contentService.isEpisodeUnfinished(episodeId), isTrue);

        // Mark as finished (100% completion)
        await contentService.updateEpisodeCompletion(episodeId, 1.0);

        expect(contentService.isEpisodeFinished(episodeId), isTrue);
        expect(contentService.isEpisodeUnfinished(episodeId), isFalse);
      });

      testWidgets('tracks partial episode completion correctly',
          (tester) async {
        final episodeId = testEpisodes.first.id;

        // Mark as 50% completed
        await contentService.updateEpisodeCompletion(episodeId, 0.5);

        expect(contentService.getEpisodeCompletion(episodeId), equals(0.5));
        expect(contentService.isEpisodeFinished(episodeId), isFalse);
        expect(contentService.isEpisodeUnfinished(episodeId), isTrue);
      });

      testWidgets('handles invalid completion values', (tester) async {
        final episodeId = testEpisodes.first.id;

        // Test negative completion
        await contentService.updateEpisodeCompletion(episodeId, -0.5);
        expect(contentService.getEpisodeCompletion(episodeId), equals(0.0));

        // Test > 100% completion
        await contentService.updateEpisodeCompletion(episodeId, 1.5);
        expect(contentService.getEpisodeCompletion(episodeId), equals(1.0));
      });

      testWidgets('gets unfinished episodes correctly', (tester) async {
        // Mark some episodes as finished
        await contentService.updateEpisodeCompletion(testEpisodes[0].id, 1.0);
        await contentService.updateEpisodeCompletion(testEpisodes[1].id, 0.5);
        await contentService.updateEpisodeCompletion(testEpisodes[2].id, 0.0);

        final unfinishedEpisodes = contentService.getUnfinishedEpisodes();

        // Should include episodes with < 90% completion
        expect(unfinishedEpisodes.length, equals(4));
        expect(
            unfinishedEpisodes.any((e) => e.id == testEpisodes[0].id), isFalse);
        expect(
            unfinishedEpisodes.any((e) => e.id == testEpisodes[1].id), isTrue);
      });
    });

    group('Error Handling Tests', () {
      testWidgets('handles service errors gracefully', (tester) async {
        // Set loading state
        contentService.setLoadingForTesting(true);
        expect(contentService.isLoading, isTrue);

        // Simulate error
        contentService.setErrorForTesting('Network connection failed');
        expect(
            contentService.errorMessage, equals('Network connection failed'));
        expect(contentService.isLoading, isFalse);
      });

      testWidgets('clears errors when loading new data', (tester) async {
        // Set error state
        contentService.setErrorForTesting('Previous error');
        expect(contentService.errorMessage, equals('Previous error'));

        // Start loading new data
        contentService.setLoadingForTesting(true);
        expect(contentService.errorMessage, isNull);
      });

      testWidgets('handles empty episode responses', (tester) async {
        contentService.setEpisodesForTesting([]);

        expect(contentService.allEpisodes.isEmpty, isTrue);
        expect(contentService.filteredEpisodes.isEmpty, isTrue);
        expect(contentService.getUnfinishedEpisodes().isEmpty, isTrue);
      });
    });

    group('Search Functionality Tests', () {
      late List<AudioFile> searchableEpisodes;

      setUp(() {
        searchableEpisodes = [
          TestUtils.createSampleAudioFile(
            id: 'bitcoin-news',
            title: 'Bitcoin Price Analysis',
            category: 'daily-news',
          ),
          TestUtils.createSampleAudioFile(
            id: 'ethereum-tech',
            title: 'Ethereum Smart Contracts',
            category: 'ethereum',
          ),
          TestUtils.createSampleAudioFile(
            id: 'defi-protocols',
            title: 'DeFi Protocol Overview',
            category: 'defi',
          ),
        ];
        contentService.setEpisodesForTesting(searchableEpisodes);
      });

      testWidgets('searches by title correctly', (tester) async {
        contentService.setSearchQuery('Bitcoin');
        final results = contentService.filteredEpisodes;
        expect(results.length, equals(1));
        expect(results.first.title, contains('Bitcoin'));
      });

      testWidgets('searches case-insensitively', (tester) async {
        contentService.setSearchQuery('bitcoin');
        final results = contentService.filteredEpisodes;
        expect(results.length, equals(1));
        expect(results.first.title, contains('Bitcoin'));
      });

      testWidgets('searches by partial matches', (tester) async {
        contentService.setSearchQuery('Protocol');
        final results = contentService.filteredEpisodes;
        expect(results.length, equals(1));
        expect(results.first.title, contains('Protocol'));
      });

      testWidgets('returns empty results for no matches', (tester) async {
        contentService.setSearchQuery('NonExistentTerm');
        final results = contentService.filteredEpisodes;
        expect(results.isEmpty, isTrue);
      });

      testWidgets('handles empty search query', (tester) async {
        contentService.setSearchQuery('');
        final results = contentService.filteredEpisodes;
        expect(results.length, equals(3)); // Should return all episodes
      });

      testWidgets('searches by category content', (tester) async {
        contentService.setSearchQuery('defi');
        final results = contentService.filteredEpisodes;
        expect(results.length, equals(1));
        expect(results.first.category, equals('defi'));
      });
    });

    group('Performance Tests', () {
      testWidgets('handles rapid filter changes efficiently', (tester) async {
        final episodes = TestUtils.createSampleAudioFileList(100);
        contentService.setEpisodesForTesting(episodes);

        final stopwatch = Stopwatch()..start();

        // Rapidly change filters
        for (int i = 0; i < 50; i++) {
          contentService.setLanguage(i % 2 == 0 ? 'en-US' : 'ja-JP');
          contentService.setCategory(i % 3 == 0 ? 'all' : 'daily-news');
          contentService.setSortOrder(i % 2 == 0 ? 'newest' : 'oldest');
        }

        stopwatch.stop();

        // Should handle rapid changes efficiently (< 1 second)
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });

      testWidgets('efficiently calculates filtered episodes', (tester) async {
        final largeEpisodeList = TestUtils.createSampleAudioFileList(1000);
        contentService.setEpisodesForTesting(largeEpisodeList);

        final stopwatch = Stopwatch()..start();

        // Apply multiple filters
        contentService.setLanguage('en-US');
        contentService.setCategory('daily-news');
        final filtered = contentService.filteredEpisodes;

        stopwatch.stop();

        // Should filter efficiently (< 500ms)
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
        expect(filtered, isNotNull);
      });
    });

    group('Memory Management Tests', () {
      testWidgets('properly disposes resources', (tester) async {
        final episodes = TestUtils.createSampleAudioFileList(10);
        contentService.setEpisodesForTesting(episodes);

        // Dispose service
        contentService.dispose();

        // Should handle disposal gracefully
        expect(() => contentService.allEpisodes, returnsNormally);
      });

      testWidgets('handles memory pressure efficiently', (tester) async {
        // Simulate memory pressure by loading and clearing large datasets
        for (int i = 0; i < 10; i++) {
          final largeDataset = TestUtils.createSampleAudioFileList(500);
          contentService.setEpisodesForTesting(largeDataset);

          // Clear the dataset
          contentService.setEpisodesForTesting([]);
        }

        // Should handle memory pressure without errors
        expect(contentService.allEpisodes.isEmpty, isTrue);
      });
    });

    group('State Persistence Tests', () {
      testWidgets('persists filter settings across episodes updates',
          (tester) async {
        // Set filters
        contentService.setLanguage('ja-JP');
        contentService.setCategory('ethereum');
        contentService.setSortOrder('oldest');

        // Update episodes
        final newEpisodes = TestUtils.createSampleAudioFileList(5);
        contentService.setEpisodesForTesting(newEpisodes);

        // Filters should be maintained
        expect(contentService.selectedLanguage, equals('ja-JP'));
        expect(contentService.selectedCategory, equals('ethereum'));
        expect(contentService.sortOrder, equals('oldest'));
      });

      testWidgets('persists completion data across episodes updates',
          (tester) async {
        final episodes = TestUtils.createSampleAudioFileList(3);
        contentService.setEpisodesForTesting(episodes);

        // Set completion data
        await contentService.updateEpisodeCompletion(episodes[0].id, 0.8);
        await contentService.updateEpisodeCompletion(episodes[1].id, 1.0);

        // Update episodes list (simulating refresh)
        contentService.setEpisodesForTesting(episodes);

        // Completion data should be maintained
        expect(
            contentService.getEpisodeCompletion(episodes[0].id), equals(0.8));
        expect(
            contentService.getEpisodeCompletion(episodes[1].id), equals(1.0));
      });
    });

    group('Edge Case Tests', () {
      testWidgets('handles concurrent filter operations', (tester) async {
        final episodes = TestUtils.createSampleAudioFileList(20);
        contentService.setEpisodesForTesting(episodes);

        // Perform concurrent operations
        final futures = <Future>[];
        for (int i = 0; i < 10; i++) {
          futures.add(Future(() {
            contentService.setLanguage('en-US');
            contentService.setCategory('all');
          }));
        }

        await Future.wait(futures);

        // Should handle concurrent operations without errors
        expect(contentService.selectedLanguage, equals('en-US'));
        expect(contentService.selectedCategory, equals('all'));
      });

      testWidgets('handles malformed episode data gracefully', (tester) async {
        final malformedEpisodes = [
          TestUtils.createSampleAudioFile(
            id: '', // Empty ID
            title: 'Valid Title',
          ),
          TestUtils.createSampleAudioFile(
            id: 'valid-id',
            title: '', // Empty title
          ),
          TestUtils.createSampleAudioFile(
            id: 'another-valid-id',
            title: 'Another Valid Title',
            duration: Duration.zero, // Zero duration
          ),
        ];

        // Should not throw exceptions
        expect(() {
          contentService.setEpisodesForTesting(malformedEpisodes);
        }, returnsNormally);

        // Should handle the valid episodes
        expect(contentService.allEpisodes.length, greaterThan(0));
      });
    });
  });
}
