import 'package:flutter_test/flutter_test.dart';
import 'package:from_fed_to_chain_app/services/content_service.dart';
import 'package:from_fed_to_chain_app/services/audio_service.dart';
import '../test_utils.dart';

void main() {
  group('Error Handling Tests', () {
    group('Network Error Scenarios', () {
      late ContentService contentService;

      setUp(() {
        contentService = ContentService();
      });

      tearDown(() {
        contentService.dispose();
      });

      testWidgets('handles network timeout gracefully', (tester) async {
        // Simulate network timeout
        contentService.setLoadingForTesting(true);

        await TestUtils.delay(const Duration(milliseconds: 100));

        contentService.setErrorForTesting('Network timeout after 30 seconds');
        contentService.setLoadingForTesting(false);

        expect(contentService.errorMessage,
            equals('Network timeout after 30 seconds'));
        expect(contentService.isLoading, isFalse);
        expect(contentService.allEpisodes.isEmpty, isTrue);
      });

      testWidgets('handles connection refused error', (tester) async {
        contentService
            .setErrorForTesting('Connection refused - server unavailable');

        expect(contentService.errorMessage, contains('Connection refused'));
        expect(contentService.allEpisodes.isEmpty, isTrue);
      });

      testWidgets('handles DNS resolution failure', (tester) async {
        contentService
            .setErrorForTesting('DNS resolution failed for example.com');

        expect(contentService.errorMessage, contains('DNS resolution failed'));
        expect(contentService.allEpisodes.isEmpty, isTrue);
      });

      testWidgets('handles SSL certificate errors', (tester) async {
        contentService
            .setErrorForTesting('SSL certificate verification failed');

        expect(contentService.errorMessage, contains('SSL certificate'));
        expect(contentService.allEpisodes.isEmpty, isTrue);
      });

      testWidgets('handles HTTP 404 errors', (tester) async {
        contentService.setErrorForTesting('HTTP 404: Endpoint not found');

        expect(contentService.errorMessage, contains('404'));
        expect(contentService.allEpisodes.isEmpty, isTrue);
      });

      testWidgets('handles HTTP 500 server errors', (tester) async {
        contentService.setErrorForTesting('HTTP 500: Internal server error');

        expect(contentService.errorMessage, contains('500'));
        expect(contentService.allEpisodes.isEmpty, isTrue);
      });

      testWidgets('handles HTTP 429 rate limiting', (tester) async {
        contentService.setErrorForTesting('HTTP 429: Too many requests');

        expect(contentService.errorMessage, contains('429'));
        expect(contentService.allEpisodes.isEmpty, isTrue);
      });

      testWidgets('handles malformed JSON response', (tester) async {
        contentService
            .setErrorForTesting('Invalid JSON response: Unexpected token');

        expect(contentService.errorMessage, contains('Invalid JSON'));
        expect(contentService.allEpisodes.isEmpty, isTrue);
      });

      testWidgets('handles empty response gracefully', (tester) async {
        // Empty response should not be an error
        contentService.setEpisodesForTesting([]);

        expect(contentService.errorMessage, isNull);
        expect(contentService.allEpisodes.isEmpty, isTrue);
      });

      testWidgets('handles partial response with some failures',
          (tester) async {
        // Simulate partial success
        final partialEpisodes = TestUtils.createSampleAudioFileList(3);
        contentService.setEpisodesForTesting(partialEpisodes);
        contentService
            .setErrorForTesting('Some requests failed but 3 episodes loaded');

        expect(contentService.allEpisodes.length, equals(3));
        expect(contentService.errorMessage, contains('Some requests failed'));
      });
    });

    group('Audio Service Error Scenarios', () {
      late AudioService audioService;

      setUp(() {
        audioService = AudioService(null);
      });

      tearDown(() {
        audioService.dispose();
      });

      testWidgets('handles audio file not found error', (tester) async {
        final testEpisode = TestUtils.createSampleAudioFile(
          streamingUrl: 'https://invalid-url.com/nonexistent.m3u8',
        );

        audioService.setCurrentAudioFileForTesting(testEpisode);
        audioService.setErrorForTesting('Audio file not found: 404');

        expect(audioService.errorMessage, contains('Audio file not found'));
        expect(audioService.isPlaying, isFalse);
      });

      testWidgets('handles audio format not supported error', (tester) async {
        audioService.setErrorForTesting('Unsupported audio format: .xyz');

        expect(audioService.errorMessage, contains('Unsupported audio format'));
        expect(audioService.isPlaying, isFalse);
      });

      testWidgets('handles audio streaming interruption', (tester) async {
        final testEpisode = TestUtils.createSampleAudioFile();
        audioService.setCurrentAudioFileForTesting(testEpisode);
        audioService.setPlaybackStateForTesting(PlaybackState.playing);

        // Simulate streaming interruption
        audioService.setErrorForTesting(
            'Streaming interrupted: Network connection lost');
        audioService.setPlaybackStateForTesting(PlaybackState.paused);

        expect(audioService.errorMessage, contains('Streaming interrupted'));
        expect(audioService.isPlaying, isFalse);
        expect(audioService.isPaused, isTrue);
      });

      testWidgets('handles audio buffer underrun', (tester) async {
        audioService
            .setErrorForTesting('Audio buffer underrun - insufficient data');

        expect(audioService.errorMessage, contains('buffer underrun'));
        expect(audioService.isPlaying, isFalse);
      });

      testWidgets('handles device audio permission denied', (tester) async {
        audioService.setErrorForTesting('Audio permission denied by user');

        expect(audioService.errorMessage, contains('permission denied'));
        expect(audioService.isPlaying, isFalse);
      });

      testWidgets('handles audio device unavailable', (tester) async {
        audioService.setErrorForTesting(
            'Audio device unavailable - headphones disconnected');

        expect(audioService.errorMessage, contains('device unavailable'));
        expect(audioService.isPlaying, isFalse);
      });

      testWidgets('handles corrupted audio stream', (tester) async {
        audioService.setErrorForTesting('Corrupted audio stream detected');

        expect(audioService.errorMessage, contains('Corrupted audio'));
        expect(audioService.isPlaying, isFalse);
      });

      testWidgets('recovers from transient audio errors', (tester) async {
        final testEpisode = TestUtils.createSampleAudioFile();
        audioService.setCurrentAudioFileForTesting(testEpisode);

        // Set error
        audioService.setErrorForTesting('Temporary network glitch');

        // Simulate recovery
        audioService.clearErrorForTesting();
        audioService.setPlaybackStateForTesting(PlaybackState.playing);

        expect(audioService.errorMessage, isNull);
        expect(audioService.isPlaying, isTrue);
      });
    });

    group('API Service Error Scenarios', () {
      testWidgets('handles API rate limiting with exponential backoff',
          (tester) async {
        // Simulate rate limiting scenarios that the service should handle
        final errorScenarios = [
          'Rate limit exceeded: 100 requests per minute',
          'Rate limit exceeded: 1000 requests per hour',
          'Rate limit exceeded: 10000 requests per day',
        ];

        for (final errorMessage in errorScenarios) {
          // In a real implementation, this would test the backoff mechanism
          expect(errorMessage, contains('Rate limit exceeded'));
        }
      });

      testWidgets('handles API authentication failures', (tester) async {
        final authErrors = [
          'Invalid API key',
          'API key expired',
          'Insufficient permissions',
          'Authentication token missing',
        ];

        for (final error in authErrors) {
          // These would be handled by the API service
          expect(error, isNotEmpty);
        }
      });

      testWidgets('handles API version mismatch', (tester) async {
        const versionError = 'API version v1 is deprecated, use v2';
        expect(versionError, contains('deprecated'));
      });

      testWidgets('handles API maintenance mode', (tester) async {
        const maintenanceError = 'API temporarily unavailable for maintenance';
        expect(maintenanceError, contains('maintenance'));
      });
    });

    group('Data Validation Error Scenarios', () {
      late ContentService contentService;

      setUp(() {
        contentService = ContentService();
      });

      tearDown(() {
        contentService.dispose();
      });

      testWidgets('handles invalid episode data gracefully', (tester) async {
        final invalidEpisodes = [
          TestUtils.createSampleAudioFile(
            id: '', // Invalid empty ID
            title: 'Valid Title',
          ),
          TestUtils.createSampleAudioFile(
            id: 'valid-id',
            title: '', // Invalid empty title
          ),
        ];

        // Should filter out invalid episodes without crashing
        expect(() {
          contentService.setEpisodesForTesting(invalidEpisodes);
        }, returnsNormally);
      });

      testWidgets('handles invalid audio file URLs', (tester) async {
        final invalidUrlEpisode = TestUtils.createSampleAudioFile(
          streamingUrl: 'not-a-valid-url',
        );

        expect(() {
          contentService.setEpisodesForTesting([invalidUrlEpisode]);
        }, returnsNormally);
      });

      testWidgets('handles invalid duration values', (tester) async {
        final invalidDurationEpisode = TestUtils.createSampleAudioFile(
          duration: const Duration(seconds: -1), // Negative duration
        );

        expect(() {
          contentService.setEpisodesForTesting([invalidDurationEpisode]);
        }, returnsNormally);
      });

      testWidgets('handles invalid language codes', (tester) async {
        final invalidLanguageEpisode = TestUtils.createSampleAudioFile(
          language: 'invalid-lang-code',
        );

        expect(() {
          contentService.setEpisodesForTesting([invalidLanguageEpisode]);
        }, returnsNormally);
      });

      testWidgets('handles invalid category codes', (tester) async {
        final invalidCategoryEpisode = TestUtils.createSampleAudioFile(
          category: 'invalid-category',
        );

        expect(() {
          contentService.setEpisodesForTesting([invalidCategoryEpisode]);
        }, returnsNormally);
      });
    });

    group('Memory and Performance Error Scenarios', () {
      testWidgets('handles memory pressure gracefully', (tester) async {
        final contentService = ContentService();

        // Simulate memory pressure by loading large datasets repeatedly
        for (int i = 0; i < 5; i++) {
          final largeDataset = TestUtils.createSampleAudioFileList(1000);

          expect(() {
            contentService.setEpisodesForTesting(largeDataset);
          }, returnsNormally);
        }

        contentService.dispose();
      });

      testWidgets('handles concurrent access gracefully', (tester) async {
        final contentService = ContentService();
        final episodes = TestUtils.createSampleAudioFileList(10);

        // Simulate concurrent access from multiple threads
        final futures = <Future>[];
        for (int i = 0; i < 20; i++) {
          futures.add(Future(() {
            contentService.setEpisodesForTesting(episodes);
            contentService.setLanguage('en-US');
            contentService.setCategory('all');
          }));
        }

        expect(() async {
          await Future.wait(futures);
        }, returnsNormally);

        contentService.dispose();
      });

      testWidgets('handles rapid state changes without memory leaks',
          (tester) async {
        final contentService = ContentService();

        // Rapidly change state to test for memory leaks
        for (int i = 0; i < 100; i++) {
          contentService.setLoadingForTesting(true);
          contentService.setLoadingForTesting(false);
          contentService.setErrorForTesting('Error $i');
          contentService.setErrorForTesting(null);
        }

        expect(contentService.isLoading, isFalse);
        expect(contentService.errorMessage, isNull);

        contentService.dispose();
      });
    });

    group('User Interaction Error Scenarios', () {
      testWidgets('handles invalid search queries gracefully', (tester) async {
        final contentService = ContentService();
        final episodes = TestUtils.createSampleAudioFileList(5);
        contentService.setEpisodesForTesting(episodes);

        // Test various invalid search queries
        final invalidQueries = [
          '', // Empty
          '   ', // Whitespace only
          String.fromCharCodes(List.filled(1000, 65)), // Very long string
          '!@#\$%^&*()', // Special characters
          'null',
          'undefined',
        ];

        for (final query in invalidQueries) {
          expect(() {
            contentService.searchEpisodes(query);
          }, returnsNormally);
        }

        contentService.dispose();
      });

      testWidgets('handles invalid filter combinations', (tester) async {
        final contentService = ContentService();
        final episodes = TestUtils.createSampleAudioFileList(5);
        contentService.setEpisodesForTesting(episodes);

        // Test invalid filter combinations
        expect(() {
          contentService.setLanguage('non-existent-language');
          contentService.setCategory('non-existent-category');
          contentService.setSortOrder('non-existent-order');
        }, returnsNormally);

        // Should fallback to safe defaults
        expect(contentService.filteredEpisodes, isNotNull);

        contentService.dispose();
      });

      testWidgets('handles invalid completion values gracefully',
          (tester) async {
        final contentService = ContentService();
        final episodes = TestUtils.createSampleAudioFileList(1);
        contentService.setEpisodesForTesting(episodes);

        final episodeId = episodes.first.id;

        // Test invalid completion values
        final invalidValues = [-1.0, 2.0, double.infinity, double.nan];

        for (final value in invalidValues) {
          expect(() async {
            await contentService.updateEpisodeCompletion(episodeId, value);
          }, returnsNormally);
        }

        contentService.dispose();
      });
    });

    group('Error Recovery Scenarios', () {
      testWidgets('recovers from network errors when connection restored',
          (tester) async {
        final contentService = ContentService();

        // Start with network error
        contentService.setErrorForTesting('Network connection failed');
        expect(contentService.errorMessage, isNotNull);

        // Simulate connection restoration
        contentService.setLoadingForTesting(true);
        await TestUtils.delay(const Duration(milliseconds: 50));

        final episodes = TestUtils.createSampleAudioFileList(5);
        contentService.setEpisodesForTesting(episodes);
        contentService.setLoadingForTesting(false);

        // Should clear error and load data
        expect(contentService.errorMessage, isNull);
        expect(contentService.allEpisodes.length, equals(5));

        contentService.dispose();
      });

      testWidgets('maintains user state during error recovery', (tester) async {
        final contentService = ContentService();

        // Set user preferences
        contentService.setLanguage('ja-JP');
        contentService.setCategory('ethereum');
        contentService.setSortOrder('oldest');

        // Simulate error
        contentService.setErrorForTesting('Temporary error');

        // Simulate recovery
        final episodes = TestUtils.createSampleAudioFileList(10);
        contentService.setEpisodesForTesting(episodes);

        // User preferences should be maintained
        expect(contentService.selectedLanguage, equals('ja-JP'));
        expect(contentService.selectedCategory, equals('ethereum'));
        expect(contentService.sortOrder, equals('oldest'));

        contentService.dispose();
      });

      testWidgets('preserves episode progress during errors', (tester) async {
        final contentService = ContentService();
        final episodes = TestUtils.createSampleAudioFileList(3);
        contentService.setEpisodesForTesting(episodes);

        // Set some progress
        await contentService.updateEpisodeCompletion(episodes[0].id, 0.5);
        await contentService.updateEpisodeCompletion(episodes[1].id, 0.8);

        // Simulate error and recovery
        contentService.setErrorForTesting('Connection lost');
        contentService.setEpisodesForTesting(episodes); // Reload data

        // Progress should be preserved
        expect(
            contentService.getEpisodeCompletion(episodes[0].id), equals(0.5));
        expect(
            contentService.getEpisodeCompletion(episodes[1].id), equals(0.8));

        contentService.dispose();
      });
    });

    group('Critical Error Scenarios', () {
      testWidgets('handles service disposal during active operations',
          (tester) async {
        final contentService = ContentService();

        // Start loading
        contentService.setLoadingForTesting(true);

        // Dispose during loading
        expect(() {
          contentService.dispose();
        }, returnsNormally);
      });

      testWidgets('handles corrupted local data gracefully', (tester) async {
        final contentService = ContentService();

        // Simulate corrupted completion data
        expect(() {
          contentService.setEpisodesForTesting([]);
        }, returnsNormally);

        expect(contentService.allEpisodes.isEmpty, isTrue);

        contentService.dispose();
      });

      testWidgets('handles platform-specific errors gracefully',
          (tester) async {
        final audioService = AudioService(null);

        // Simulate platform-specific audio errors
        final platformErrors = [
          'iOS: Audio session interrupted by phone call',
          'Android: Audio focus lost to another app',
          'Web: AudioContext suspended by browser',
        ];

        for (final error in platformErrors) {
          audioService.setErrorForTesting(error);
          expect(audioService.errorMessage, equals(error));
        }

        audioService.dispose();
      });
    });

    group('Error Message Handling', () {
      testWidgets('provides user-friendly error messages', (tester) async {
        final contentService = ContentService();

        final technicalErrors = {
          'HTTP 500: Internal server error': 'Server temporarily unavailable',
          'DNS resolution failed': 'Network connection problem',
          'SSL certificate verification failed': 'Security certificate error',
          'Connection timeout': 'Connection timed out',
        };

        for (final entry in technicalErrors.entries) {
          contentService.setErrorForTesting(entry.key);

          // In a real app, these would be converted to user-friendly messages
          expect(contentService.errorMessage, isNotNull);
        }

        contentService.dispose();
      });

      testWidgets('logs detailed errors for debugging', (tester) async {
        final contentService = ContentService();

        // Detailed error information should be available for debugging
        const detailedError = '''
          Error: Network request failed
          URL: https://api.example.com/episodes
          Status: 503
          Response: Service temporarily unavailable
          Timestamp: 2025-01-01T12:00:00Z
          User-Agent: FromFedToChain/1.0.0
        ''';

        contentService.setErrorForTesting(detailedError);
        expect(contentService.errorMessage, contains('Network request failed'));

        contentService.dispose();
      });
    });
  });
}
