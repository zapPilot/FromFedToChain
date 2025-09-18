import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:from_fed_to_chain_app/services/content_facade_service.dart';
import 'package:from_fed_to_chain_app/repositories/repository_factory.dart';
import '../test_utils.dart';

void main() {
  group('ContentFacadeService Enhanced Tests', () {
    late ContentFacadeService contentService;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      // Reset the repository factory to ensure clean state between tests
      RepositoryFactory.reset();
      contentService = ContentFacadeService();
      // Allow services to initialize
      await Future.delayed(const Duration(milliseconds: 10));
    });

    tearDown(() async {
      // Wait for any pending operations to complete before disposal
      await Future.delayed(const Duration(milliseconds: 5));
      contentService.dispose();
      // Reset repository factory to prevent shared state issues
      RepositoryFactory.reset();
    });

    group('Listen History Management', () {
      test('should add episode to listen history', () async {
        final episode = TestDataFactory.createMockAudioFile(id: 'test-episode');
        final timestamp = DateTime.parse('2025-01-20T10:00:00Z');

        await contentService.addToListenHistory(episode, at: timestamp);

        expect(contentService.listenHistory['test-episode'], equals(timestamp));
      });

      test('should cap listen history to 100 entries', () async {
        // Clear any existing history to ensure clean start
        await contentService.clearListenHistory();
        expect(contentService.listenHistory.length, equals(0));

        // Add 101 episodes to history
        for (int i = 0; i < 101; i++) {
          final episode =
              TestDataFactory.createMockAudioFile(id: 'test-cap-episode-$i');
          final timestamp = DateTime.now().add(Duration(minutes: i));
          await contentService.addToListenHistory(episode, at: timestamp);
        }

        // Allow final save operations to complete and multiple processing cycles
        await Future.delayed(const Duration(milliseconds: 50));

        expect(contentService.listenHistory.length, equals(100));
      });

      test('should remove episode from listen history', () async {
        final episode = TestDataFactory.createMockAudioFile(id: 'test-episode');
        await contentService.addToListenHistory(episode);

        await contentService.removeFromListenHistory('test-episode');

        expect(
            contentService.listenHistory.containsKey('test-episode'), isFalse);
      });

      test('should clear all listen history', () async {
        final episode1 = TestDataFactory.createMockAudioFile(id: 'episode-1');
        final episode2 = TestDataFactory.createMockAudioFile(id: 'episode-2');

        await contentService.addToListenHistory(episode1);
        await contentService.addToListenHistory(episode2);

        await contentService.clearListenHistory();

        expect(contentService.listenHistory, isEmpty);
      });
    });

    group('Episode Completion Tracking', () {
      test('should update episode completion', () async {
        await contentService.updateEpisodeCompletion('test-episode', 0.65);
        // Allow save operation to complete
        await Future.delayed(const Duration(milliseconds: 10));

        expect(
            contentService.getEpisodeCompletion('test-episode'), equals(0.65));
        expect(contentService.isEpisodeUnfinished('test-episode'), isTrue);
        expect(contentService.isEpisodeFinished('test-episode'), isFalse);
      });

      test('should mark episode as finished', () async {
        await contentService.markEpisodeAsFinished('test-episode');
        // Allow save operation to complete
        await Future.delayed(const Duration(milliseconds: 10));

        expect(
            contentService.getEpisodeCompletion('test-episode'), equals(1.0));
        expect(contentService.isEpisodeFinished('test-episode'), isTrue);
        expect(contentService.isEpisodeUnfinished('test-episode'), isFalse);
      });

      test('should identify finished episodes correctly', () async {
        await contentService.updateEpisodeCompletion('finished-episode', 0.95);
        await contentService.updateEpisodeCompletion('unfinished-episode', 0.5);
        await contentService.updateEpisodeCompletion('barely-started', 0.1);
        // Allow save operations to complete
        await Future.delayed(const Duration(milliseconds: 10));

        expect(contentService.isEpisodeFinished('finished-episode'), isTrue);
        expect(contentService.isEpisodeFinished('unfinished-episode'), isFalse);
        expect(
            contentService.isEpisodeUnfinished('unfinished-episode'), isTrue);
        expect(contentService.isEpisodeUnfinished('barely-started'), isTrue);
      });

      test('should handle completion values correctly', () async {
        await contentService.updateEpisodeCompletion('test', 1.5); // Over 1.0
        // Allow save operation to complete
        await Future.delayed(const Duration(milliseconds: 10));

        expect(contentService.getEpisodeCompletion('test'),
            equals(1.0)); // Clamped to 1.0
        expect(contentService.isEpisodeFinished('test'), isTrue);
      });
    });

    group('Playlist Management', () {
      test('should create playlist from episodes', () {
        final episodes = [
          TestDataFactory.createMockAudioFile(id: 'episode-1'),
          TestDataFactory.createMockAudioFile(id: 'episode-2'),
        ];

        contentService.createPlaylist('Test Playlist', episodes);

        expect(contentService.currentPlaylist, isNotNull);
        expect(contentService.currentPlaylist!.name, equals('Test Playlist'));
        expect(contentService.currentPlaylist!.episodes, equals(episodes));
      });

      test('should clear current playlist', () {
        final episodes = [TestDataFactory.createMockAudioFile()];
        contentService.createPlaylist('Test Playlist', episodes);

        contentService.clearCurrentPlaylist();

        expect(contentService.currentPlaylist, isNull);
      });
    });

    group('Basic State Management', () {
      test('should handle search query updates', () async {
        const query = 'bitcoin';
        contentService.setSearchQuery(query);
        // Allow repository sync to complete
        await Future.delayed(const Duration(milliseconds: 10));

        expect(contentService.searchQuery, equals(query));
      });

      test('should handle language selection', () async {
        await contentService.setLanguage('en-US');

        expect(contentService.selectedLanguage, equals('en-US'));
      });

      test('should handle category selection', () async {
        // Ensure we start with the default category
        expect(contentService.selectedCategory, equals('all'));

        await contentService.setCategory('ethereum');

        // Allow some time for the async operation to complete
        await Future.delayed(const Duration(milliseconds: 10));

        expect(contentService.selectedCategory, equals('ethereum'));
      });

      test('should provide statistics', () {
        final stats = contentService.getStatistics();

        expect(stats, containsPair('totalEpisodes', isA<int>()));
        expect(stats, containsPair('filteredEpisodes', isA<int>()));
        expect(stats, containsPair('cacheStats', isA<Map>()));
        expect(stats, containsPair('listeningStats', isA<Map>()));
      });
    });

    group('Preferences Integration', () {
      test('should handle preference loading errors gracefully', () async {
        // Create service with potentially corrupted preferences
        SharedPreferences.setMockInitialValues({
          'episode_completion': 'invalid-json',
          'listen_history': 'invalid-json',
        });

        // Should not throw when creating service
        expect(() => ContentFacadeService(), returnsNormally);
      });

      test('should handle invalid dates in history gracefully', () async {
        SharedPreferences.setMockInitialValues({
          'listen_history': json.encode({
            'episode-1': 'invalid-date',
            'episode-2': '2025-01-20T11:00:00.000Z',
          }),
        });

        final testService = ContentFacadeService();
        await Future.delayed(const Duration(milliseconds: 50));

        // Should only load valid dates
        expect(testService.listenHistory.length, lessThanOrEqualTo(1));
        testService.dispose();
      });
    });

    group('Edge Cases and Error Handling', () {
      test('should handle unknown episode completion queries', () {
        expect(contentService.getEpisodeCompletion('unknown-episode'),
            equals(0.0));
        expect(contentService.isEpisodeFinished('unknown-episode'), isFalse);
        expect(contentService.isEpisodeUnfinished('unknown-episode'), isFalse);
      });

      test('should handle empty statistics gracefully', () {
        final stats = contentService.getStatistics();

        expect(stats['totalEpisodes'], equals(0));
        expect(stats['filteredEpisodes'], equals(0));
        expect(stats['cacheStats'], isA<Map>());
        expect(stats['listeningStats'], isA<Map>());
      });

      test('should handle disposal correctly', () {
        // Create a separate instance for disposal test
        final testService = ContentFacadeService();
        expect(() => testService.dispose(), returnsNormally);
      });
    });
  });
}
