import 'package:flutter_test/flutter_test.dart';

import 'package:from_fed_to_chain_app/services/content_service.dart';

import '../test_utils.dart';

void main() {
  group('Error Handling and Edge Cases', () {
    group('ContentService Error Handling', () {
      late ContentService contentService;

      setUp(() {
        contentService = ContentService();
      });

      tearDown(() {
        contentService.dispose();
      });

      test('handles loading errors gracefully', () async {
        // Test actual loading behavior
        await contentService.loadAllEpisodes();

        // ContentService should handle errors gracefully
        expect(contentService.isLoading, isFalse);
        expect(contentService.allEpisodes, isNotNull);
      });

      test('handles empty episode list', () async {
        // Initially, episodes should be empty
        expect(contentService.allEpisodes, isEmpty);
        expect(contentService.filteredEpisodes, isEmpty);
        expect(contentService.hasError, isFalse);
      });

      test('handles filter operations on empty list', () async {
        // Apply filters to empty list
        await contentService.setLanguage('en-US');
        await contentService.setCategory('daily-news');
        contentService.setSearchQuery('test');

        // Should handle gracefully
        expect(contentService.selectedLanguage, equals('en-US'));
        expect(contentService.selectedCategory, equals('daily-news'));
        expect(contentService.searchQuery, equals('test'));
        expect(contentService.filteredEpisodes, isEmpty);
      });

      test('handles rapid state changes', () async {
        // Rapid state changes should not cause errors
        for (int i = 0; i < 10; i++) {
          await contentService.setLanguage(i % 2 == 0 ? 'en-US' : 'zh-TW');
          await contentService
              .setCategory(i % 3 == 0 ? 'daily-news' : 'ethereum');
          contentService.setSearchQuery('query $i');
        }

        // State should be consistent
        expect(contentService.selectedLanguage, isNotNull);
        expect(contentService.selectedCategory, isNotNull);
        expect(contentService.searchQuery, isNotNull);
      });

      test('handles invalid language and category values', () async {
        // Invalid values should be handled gracefully
        await contentService.setLanguage('invalid-language');
        await contentService.setCategory('invalid-category');

        expect(contentService.selectedLanguage, equals('invalid-language'));
        expect(contentService.selectedCategory, equals('invalid-category'));
      });

      test('handles concurrent operations', () async {
        // Start multiple concurrent operations
        final futures = <Future<void>>[];

        for (int i = 0; i < 5; i++) {
          futures.add(contentService.setLanguage('en-US'));
          futures.add(contentService.setCategory('daily-news'));
        }

        await Future.wait(futures);

        // Should handle concurrent operations gracefully
        expect(contentService.selectedLanguage, equals('en-US'));
        expect(contentService.selectedCategory, equals('daily-news'));
      });
    });

    group('AudioFile Model Edge Cases', () {
      test('handles missing or null duration', () {
        final episodeWithoutDuration =
            TestUtils.createSampleAudioFile(duration: null);

        expect(episodeWithoutDuration.formattedDuration, equals('--:--'));
        expect(episodeWithoutDuration.duration, isNull);
      });

      test('handles very long durations', () {
        final veryLongEpisode = TestUtils.createSampleAudioFile(
          duration: const Duration(days: 1), // 24 hours
        );

        expect(veryLongEpisode.formattedDuration, contains('24:00:00'));
      });

      test('handles zero duration', () {
        final zeroDurationEpisode = TestUtils.createSampleAudioFile(
          duration: Duration.zero,
        );

        expect(zeroDurationEpisode.formattedDuration, equals('0:00'));
      });

      test('handles empty or whitespace titles', () {
        final emptyTitleEpisode = TestUtils.createSampleAudioFile(title: '');
        final whitespaceTitleEpisode =
            TestUtils.createSampleAudioFile(title: '   ');

        // Should use display title fallback
        expect(emptyTitleEpisode.displayTitle, isNotEmpty);
        expect(whitespaceTitleEpisode.displayTitle, isNotEmpty);
      });

      test('handles file size edge cases', () {
        final episodes = [
          TestUtils.createSampleAudioFile(fileSizeBytes: 0),
          TestUtils.createSampleAudioFile(fileSizeBytes: null),
          TestUtils.createSampleAudioFile(
              fileSizeBytes: 1024 * 1024 * 1024 * 5), // 5GB
        ];

        for (final episode in episodes) {
          expect(episode.formattedFileSize, isNotNull);
          expect(episode.formattedFileSize, isNotEmpty);
        }
      });

      test('handles invalid date parsing in episode ID', () {
        final invalidDateEpisodes = [
          TestUtils.createSampleAudioFile(id: 'invalid-date-format'),
          TestUtils.createSampleAudioFile(
              id: '2025-13-45-invalid-date'), // Invalid month/day
          TestUtils.createSampleAudioFile(id: 'abcd-ef-gh-not-a-date'),
        ];

        for (final episode in invalidDateEpisodes) {
          expect(episode.publishDate, isNotNull);
          expect(episode.publishDate,
              equals(episode.lastModified)); // Should fallback
        }
      });

      test('handles unknown categories and languages', () {
        final unknownEpisode = TestUtils.createSampleAudioFile(
          category: 'unknown-category',
          language: 'unknown-lang',
        );

        expect(unknownEpisode.categoryEmoji, equals('🎧')); // Default emoji
        expect(unknownEpisode.languageFlag, equals('🌐')); // Default flag
      });
    });

    group('ContentService State Management', () {
      late ContentService contentService;

      setUp(() {
        contentService = ContentService();
      });

      tearDown(() {
        contentService.dispose();
      });

      test('handles episode completion tracking', () async {
        const episodeId = 'test-episode-123';

        // Initially no completion
        expect(contentService.getEpisodeCompletion(episodeId), equals(0.0));
        expect(contentService.isEpisodeFinished(episodeId), isFalse);
        expect(contentService.isEpisodeUnfinished(episodeId), isFalse);

        // Set partial completion
        await contentService.updateEpisodeCompletion(episodeId, 0.5);
        expect(contentService.getEpisodeCompletion(episodeId), equals(0.5));
        expect(contentService.isEpisodeUnfinished(episodeId), isTrue);
        expect(contentService.isEpisodeFinished(episodeId), isFalse);

        // Mark as finished
        await contentService.markEpisodeAsFinished(episodeId);
        expect(contentService.getEpisodeCompletion(episodeId), equals(1.0));
        expect(contentService.isEpisodeFinished(episodeId), isTrue);
        expect(contentService.isEpisodeUnfinished(episodeId), isFalse);
      });

      test('handles listen history', () async {
        final testEpisode = TestUtils.createSampleAudioFile(id: 'test-episode');

        // Initially empty history
        expect(contentService.getListenHistoryEpisodes(), isEmpty);

        // Add to history
        await contentService.addToListenHistory(testEpisode);

        // History should be updated (though episode may not be in filtered list)
        expect(contentService.listenHistory, isNotEmpty);
        expect(
            contentService.listenHistory.containsKey(testEpisode.id), isTrue);

        // Remove from history
        await contentService.removeFromListenHistory(testEpisode.id);
        expect(
            contentService.listenHistory.containsKey(testEpisode.id), isFalse);

        // Clear history
        await contentService.addToListenHistory(testEpisode);
        await contentService.clearListenHistory();
        expect(contentService.getListenHistoryEpisodes(), isEmpty);
      });

      test('handles sorting', () async {
        final testEpisodes = TestUtils.createSampleAudioFileList(5);
        contentService.setEpisodesForTesting(testEpisodes);

        // Test different sort orders
        await contentService.setSortOrder('newest');
        expect(contentService.sortOrder, equals('newest'));

        await contentService.setSortOrder('oldest');
        expect(contentService.sortOrder, equals('oldest'));

        await contentService.setSortOrder('alphabetical');
        expect(contentService.sortOrder, equals('alphabetical'));
      });

      test('handles statistics calculation', () {
        final stats = contentService.getStatistics();

        expect(stats, isA<Map<String, dynamic>>());
        expect(stats.containsKey('totalEpisodes'), isTrue);
        expect(stats.containsKey('filteredEpisodes'), isTrue);
        expect(stats.containsKey('languages'), isTrue);
        expect(stats.containsKey('categories'), isTrue);
      });

      test('handles search functionality', () {
        contentService.setSearchQuery('bitcoin');
        expect(contentService.searchQuery, equals('bitcoin'));

        contentService.setSearchQuery('');
        expect(contentService.searchQuery, equals(''));

        // Very long search query
        final longQuery = 'a' * 1000;
        contentService.setSearchQuery(longQuery);
        expect(contentService.searchQuery, equals(longQuery));
      });
    });

    group('Resource Cleanup', () {
      test('properly disposes of resources', () {
        final contentService = ContentService();

        // Add a listener
        void listener() {}

        contentService.addListener(listener);

        // Dispose should clean up resources
        contentService.dispose();

        // Verify cleanup occurred without errors
        expect(() => contentService.dispose(), returnsNormally);
      });

      test('handles multiple dispose calls', () {
        final contentService = ContentService();

        // Multiple dispose calls should not cause errors
        contentService.dispose();
        expect(() => contentService.dispose(), returnsNormally);
        expect(() => contentService.dispose(), returnsNormally);
      });
    });
  });
}
