import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;

import 'package:from_fed_to_chain_app/services/content_service.dart';
import 'package:from_fed_to_chain_app/services/streaming_api_service.dart';
import 'package:from_fed_to_chain_app/models/audio_file.dart';
import 'package:from_fed_to_chain_app/models/audio_content.dart';

// Generate mocks for dependencies
@GenerateMocks([http.Client, StreamingApiService])
import 'content_service_test.mocks.dart';

// Simple test helpers
class ContentServiceTestUtils {
  static AudioContent createSampleContent() {
    return AudioContent(
      id: 'test-content',
      title: 'Test Content',
      language: 'en-US',
      category: 'daily-news',
      date: DateTime(2025, 1, 15),
      status: 'published',
      description: 'Test content description',
      references: ['Source 1', 'Source 2'],
      socialHook: 'Test social hook',
      duration: Duration(minutes: 10),
      updatedAt: DateTime(2025, 1, 15),
    );
  }
}

void main() {
  group('ContentService Comprehensive Tests', () {
    late ContentService contentService;
    late List<AudioFile> sampleEpisodes;
    late MockClient mockHttpClient;

    // Test data
    final sampleAudioContent = AudioContent(
      id: 'test-content-1',
      title: 'Test Content 1',
      language: 'en-US',
      category: 'daily-news',
      date: DateTime(2025, 1, 15),
      status: 'published',
      description: 'Test content description',
      references: ['Source 1', 'Source 2'],
      socialHook: 'Test social hook',
      duration: Duration(minutes: 10),
      updatedAt: DateTime(2025, 1, 15),
    );

    setUpAll(() async {
      // Initialize dotenv with test environment variables
      dotenv.testLoad(fileInput: '''
STREAMING_BASE_URL=https://test-api.example.com
ENVIRONMENT=test
API_TIMEOUT_SECONDS=10
STREAM_TIMEOUT_SECONDS=10
''');
    });

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      
      // Create and set up mock HTTP client
      mockHttpClient = MockClient();
      ContentService.setHttpClientForTesting(mockHttpClient);
      
      // Set up default mock responses to prevent network calls
      when(mockHttpClient.get(any, headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response('[]', 200));
      when(mockHttpClient.head(any))
          .thenAnswer((_) async => http.Response('', 200));

      // Set up sample episodes
      sampleEpisodes = [
        AudioFile(
          id: 'episode-1-zh-TW',
          title: 'Bitcoin 市場分析',
          language: 'zh-TW',
          category: 'daily-news',
          streamingUrl: 'https://test.com/episode1.m3u8',
          path: 'audio/zh-TW/daily-news/episode1.m3u8',
          lastModified: DateTime(2025, 1, 15),
          duration: Duration(minutes: 10),
        ),
        AudioFile(
          id: 'episode-2-en-US',
          title: 'Ethereum Update',
          language: 'en-US',
          category: 'ethereum',
          streamingUrl: 'https://test.com/episode2.m3u8',
          path: 'audio/en-US/ethereum/episode2.m3u8',
          lastModified: DateTime(2025, 1, 14),
          duration: Duration(minutes: 15),
        ),
        AudioFile(
          id: 'episode-3-ja-JP',
          title: 'マクロ経済分析',
          language: 'ja-JP',
          category: 'macro',
          streamingUrl: 'https://test.com/episode3.m3u8',
          path: 'audio/ja-JP/macro/episode3.m3u8',
          lastModified: DateTime(2025, 1, 13),
          duration: Duration(minutes: 8),
        ),
      ];

      contentService = ContentService();

      // Reset ContentService to testing state
      contentService.setEpisodesForTesting([]);
      contentService.setLoadingForTesting(false);
      contentService.setErrorForTesting(null);
    });

    tearDown(() {
      contentService.dispose();
      // Reset HTTP client after each test
      ContentService.setHttpClientForTesting(null);
    });

    group('Initialization', () {
      test('loads preferences from SharedPreferences', () async {
        SharedPreferences.setMockInitialValues({
          'selected_language': 'en-US',
          'selected_category': 'ethereum',
        });

        final service = ContentService();
        await Future.delayed(Duration(milliseconds: 50));

        expect(service.selectedLanguage, 'en-US');
        expect(service.selectedCategory, 'ethereum');

        service.dispose();
      });
    });

    group('Episode Loading', () {
      test('loads episodes successfully', () {
        contentService.setEpisodesForTesting(sampleEpisodes);

        expect(contentService.allEpisodes, hasLength(3));
        expect(contentService.hasEpisodes, true);
      });

      test('filters episodes by language', () async {
        contentService.setEpisodesForTesting(sampleEpisodes);
        await contentService.setLanguage('en-US');

        expect(contentService.filteredEpisodes, hasLength(1));
        expect(contentService.filteredEpisodes.first.language, 'en-US');
      });
    });

    group('Filtering and Search', () {
      setUp(() {
        contentService.setEpisodesForTesting(sampleEpisodes);
      });

      test('filters episodes by language', () async {
        await contentService.setLanguage('en-US');
        expect(contentService.filteredEpisodes.first.language, 'en-US');
      });

      test('filters episodes by category', () async {
        await contentService.setLanguage('en-US');
        await contentService.setCategory('ethereum');
        expect(contentService.filteredEpisodes.first.category, 'ethereum');
      });

      test('searches episodes by query', () {
        contentService.setSearchQuery('bitcoin');
        expect(contentService.filteredEpisodes.first.title.toLowerCase(), contains('bitcoin'));
      });
    });

    group('Sorting', () {
      test('sorts episodes alphabetically', () async {
        contentService.setEpisodesForTesting([
          AudioFile(
            id: 'episode-z',
            title: 'Zebra Episode',
            language: 'zh-TW',
            category: 'daily-news',
            streamingUrl: 'https://test.com/z.m3u8',
            path: 'audio/zh-TW/daily-news/z.m3u8',
            lastModified: DateTime(2025, 1, 15),
          ),
          AudioFile(
            id: 'episode-a',
            title: 'Apple Episode',
            language: 'zh-TW',
            category: 'macro',
            streamingUrl: 'https://test.com/a.m3u8',
            path: 'audio/zh-TW/macro/a.m3u8',
            lastModified: DateTime(2025, 1, 14),
          ),
        ]);

        await contentService.setSortOrder('alphabetical');
        expect(contentService.filteredEpisodes[0].title, 'Apple Episode');
      });
    });

    group('Content Caching', () {
      test('caches and retrieves content', () async {
        contentService.cacheContent(
            'test-content-1', 'en-US', 'daily-news', sampleAudioContent);

        final result = await contentService.fetchContentById(
            'test-content-1', 'en-US', 'daily-news');

        expect(result?.id, 'test-content-1');
      });
    });


    group('Episode Progress', () {
      test('marks episode as finished', () async {
        await contentService.markEpisodeAsFinished('episode-1');
        expect(contentService.getEpisodeCompletion('episode-1'), 1.0);
      });
    });

    group('Listen History', () {
      test('adds episode to listen history', () async {
        await contentService.addToListenHistory(sampleEpisodes.first);
        expect(contentService.listenHistory.containsKey(sampleEpisodes.first.id), true);
      });
    });

    group('Playlist Management', () {
      setUp(() {
        contentService.setEpisodesForTesting(sampleEpisodes);
      });

      test('creates playlist with episodes', () {
        contentService.createPlaylist('Test Playlist', [sampleEpisodes.first]);
        expect(contentService.currentPlaylist?.name, 'Test Playlist');
      });
    });

    group('Episode Navigation', () {
      test('gets next episode', () {
        contentService.setEpisodesForTesting([
          AudioFile(
            id: 'episode-1',
            title: 'Episode 1',
            language: 'zh-TW',
            category: 'daily-news',
            streamingUrl: 'https://test.com/episode1.m3u8',
            path: 'audio/zh-TW/daily-news/episode1.m3u8',
            lastModified: DateTime(2025, 1, 15),
          ),
          AudioFile(
            id: 'episode-2',
            title: 'Episode 2',
            language: 'zh-TW',
            category: 'macro',
            streamingUrl: 'https://test.com/episode2.m3u8',
            path: 'audio/zh-TW/macro/episode2.m3u8',
            lastModified: DateTime(2025, 1, 14),
          ),
        ]);

        final currentEpisode = contentService.filteredEpisodes[0];
        final nextEpisode = contentService.getNextEpisode(currentEpisode);
        expect(nextEpisode?.id, contentService.filteredEpisodes[1].id);
      });
    });















  });
}
