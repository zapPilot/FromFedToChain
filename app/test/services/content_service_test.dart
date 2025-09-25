import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;

import 'package:from_fed_to_chain_app/services/content_facade_service.dart';
import 'package:from_fed_to_chain_app/services/streaming_api_service.dart';
import 'package:from_fed_to_chain_app/models/audio_file.dart';
import 'package:from_fed_to_chain_app/models/audio_content.dart';
import 'package:from_fed_to_chain_app/repositories/repository_factory.dart';

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
  group('ContentFacadeService Comprehensive Tests', () {
    late ContentFacadeService contentService;
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

    tearDownAll(() async {
      // Clear dotenv to prevent state contamination between test suites
      dotenv.clean();
    });

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();

      // CRITICAL: Reset the singleton RepositoryFactory to ensure clean state
      RepositoryFactory.reset();

      // Reset SharedPreferences with clean state
      SharedPreferences.setMockInitialValues({});

      // Create and set up mock HTTP client
      mockHttpClient = MockClient();
      // Note: ContentFacadeService uses repositories, mock setup may need adjustment

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

      // Create fresh service instance with clean repositories
      contentService = ContentFacadeService();

      // Allow async initialization to complete
      await Future.delayed(Duration(milliseconds: 10));

      // Reset ContentFacadeService to testing state
      contentService.setEpisodesForTesting([]);
      contentService.setLoadingForTesting(false);
      contentService.setErrorForTesting(null);

      // Reset preferences to defaults to avoid state leakage between tests
      contentService.setSelectedLanguage('zh-TW');
      contentService.setSelectedCategory('all');
      contentService.setSearchQuery('');

      // Ensure state is fully propagated
      await Future.delayed(Duration(milliseconds: 5));
    });

    tearDown(() async {
      // Dispose service first
      contentService.dispose();

      // Reset RepositoryFactory to clean up all singletons
      RepositoryFactory.reset();

      // Allow cleanup to complete
      await Future.delayed(Duration(milliseconds: 5));
    });

    group('Initialization', () {
      test('loads preferences from SharedPreferences', () async {
        SharedPreferences.setMockInitialValues({
          'selected_language': 'en-US',
          'selected_category': 'ethereum',
        });

        final service = ContentFacadeService();
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
        contentService.setSelectedLanguage('en-US');

        expect(contentService.filteredEpisodes, hasLength(1));
        expect(contentService.filteredEpisodes.first.language, 'en-US');
      });
    });

    group('Statistics and Content Retrieval', () {
      test('getStatistics returns accurate counts', () {
        contentService.setEpisodesForTesting(sampleEpisodes);

        final stats = contentService.getStatistics();

        expect(stats['totalEpisodes'], 3);
        expect(stats['filteredEpisodes'], greaterThan(0));
        expect(stats['selectedLanguage'], isNotNull);
        expect(stats['selectedCategory'], isNotNull);
        expect(stats['searchQuery'], isNotNull);
        expect(stats['listeningStats'], isNotNull);
        expect(stats['cacheStats'], isNotNull);

        // Verify basic structure
        expect(stats, contains('totalEpisodes'));
        expect(stats, contains('filteredEpisodes'));
        expect(stats, contains('selectedLanguage'));
        expect(stats, contains('selectedCategory'));
      });

      test('getEpisodesByLanguage filters correctly', () {
        contentService.setEpisodesForTesting(sampleEpisodes);

        final zhEpisodes = contentService.getEpisodesByLanguage('zh-TW');
        expect(zhEpisodes.length, 1);
        expect(zhEpisodes.first.language, 'zh-TW');

        final enEpisodes = contentService.getEpisodesByLanguage('en-US');
        expect(enEpisodes.length, 1);
        expect(enEpisodes.first.language, 'en-US');
      });

      test('getEpisodesByCategory filters correctly', () {
        contentService.setEpisodesForTesting(sampleEpisodes);

        final dailyNews = contentService.getEpisodesByCategory('daily-news');
        expect(dailyNews.length, 1);
        expect(dailyNews.first.category, 'daily-news');

        final ethereum = contentService.getEpisodesByCategory('ethereum');
        expect(ethereum.length, 1);
        expect(ethereum.first.category, 'ethereum');
      });

      test('getEpisodesByLanguageAndCategory filters by both criteria', () {
        contentService.setEpisodesForTesting(sampleEpisodes);

        final result = contentService.getEpisodesByLanguageAndCategory(
            'en-US', 'ethereum');
        expect(result.length, 1);
        expect(result.first.language, 'en-US');
        expect(result.first.category, 'ethereum');

        // Test combination that should return no results
        final noResults = contentService.getEpisodesByLanguageAndCategory(
            'zh-TW', 'ethereum');
        expect(noResults.length, 0);
      });

      test('getDebugInfo provides comprehensive debug information', () {
        contentService.setEpisodesForTesting(sampleEpisodes);

        final debugInfo = contentService.getDebugInfo(sampleEpisodes.first);

        expect(debugInfo['id'], sampleEpisodes.first.id);
        expect(debugInfo['title'], sampleEpisodes.first.title);
        expect(debugInfo['language'], sampleEpisodes.first.language);
        expect(debugInfo['category'], sampleEpisodes.first.category);
        expect(debugInfo['totalEpisodes'], 3);
        expect(debugInfo['selectedLanguage'], isA<String>());
        expect(debugInfo['selectedCategory'], isA<String>());
        expect(debugInfo['isLoading'], false);
        expect(debugInfo['hasError'], false);
      });

      test('getDebugInfo handles null audio file', () {
        final debugInfo = contentService.getDebugInfo(null);
        expect(debugInfo['error'], 'No audio file provided');
      });

      test('getCachedContent returns cached content synchronously', () {
        final content = sampleAudioContent;
        contentService.cacheContent(
            'test-content-1', 'en-US', 'daily-news', content);

        final cachedContent = contentService.getCachedContent(
            'test-content-1', 'en-US', 'daily-news');
        expect(cachedContent, isNotNull);
        expect(cachedContent!.id, 'test-content-1');
      });

      test('getCachedContent returns null for non-existent cache', () {
        final cachedContent = contentService.getCachedContent(
            'non-existent', 'en-US', 'daily-news');
        expect(cachedContent, isNull);
      });
    });

    group('Filtering and Search', () {
      setUp(() async {
        // CRITICAL: Reset singleton to avoid state leakage
        RepositoryFactory.reset();

        // Create a fresh service instance for this group to avoid state leakage
        contentService.dispose();
        contentService = ContentFacadeService();

        // Allow async initialization to complete
        await Future.delayed(Duration(milliseconds: 10));

        // Reset to clean state
        contentService.setEpisodesForTesting(sampleEpisodes);
        contentService.setLoadingForTesting(false);
        contentService.setErrorForTesting(null);
        contentService.setSelectedLanguage('zh-TW');
        contentService.setSelectedCategory('all');
        contentService.setSearchQuery('');

        // Ensure state is fully propagated
        await Future.delayed(Duration(milliseconds: 5));
      });

      test('filters episodes by language', () {
        contentService.setSelectedLanguage('en-US');
        expect(contentService.filteredEpisodes.first.language, 'en-US');
      });

      test('filters episodes by category', () {
        contentService.setSelectedLanguage('en-US');
        contentService.setSelectedCategory('ethereum');
        expect(contentService.filteredEpisodes.first.category, 'ethereum');
      });

      test('searches episodes by query', () async {
        // Set language to zh-TW to access episode with "Bitcoin 市場分析"
        contentService.setSelectedLanguage('zh-TW');

        // Wait for language setting to be applied
        await Future.delayed(Duration(milliseconds: 10));

        contentService.setSearchQuery('bitcoin');

        // Wait for filters to be applied
        await Future.delayed(Duration(milliseconds: 10));

        expect(contentService.filteredEpisodes.isNotEmpty, true);
        expect(contentService.filteredEpisodes.first.title.toLowerCase(),
            contains('bitcoin'));
      });

      test('filters by "all" category shows all episodes', () {
        contentService.setSelectedLanguage('zh-TW');
        contentService.setSelectedCategory('all');
        expect(contentService.filteredEpisodes.length, 1); // One zh-TW episode
      });

      test('search query filters by title', () async {
        // Set language to zh-TW to access episode with "Bitcoin 市場分析"
        contentService.setSelectedLanguage('zh-TW');

        // Wait for language setting to be applied
        await Future.delayed(Duration(milliseconds: 10));

        contentService.setSearchQuery('Bitcoin');

        // Wait for filters to be applied
        await Future.delayed(Duration(milliseconds: 10));

        expect(contentService.filteredEpisodes.length, 1);
        expect(
            contentService.filteredEpisodes.first.title, contains('Bitcoin'));
      });

      test('search query filters by id', () async {
        // Search for zh-TW episode and set language appropriately
        contentService.setSelectedLanguage('zh-TW');

        // Wait for language setting to be applied
        await Future.delayed(Duration(milliseconds: 10));

        contentService.setSearchQuery('episode-1-zh-TW');

        // Wait for filters to be applied
        await Future.delayed(Duration(milliseconds: 10));

        expect(contentService.filteredEpisodes.length, 1);
        expect(contentService.filteredEpisodes.first.id, 'episode-1-zh-TW');
      });

      test('search query filters by category', () async {
        // Set language to zh-TW to access episode with daily-news category
        contentService.setSelectedLanguage('zh-TW');

        // Wait for language setting to be applied
        await Future.delayed(Duration(milliseconds: 10));

        contentService.setSearchQuery('daily');

        // Wait for filters to be applied
        await Future.delayed(Duration(milliseconds: 10));

        expect(contentService.filteredEpisodes.length, 1);
        expect(
            contentService.filteredEpisodes.first.category, contains('daily'));
      });

      test('empty search query shows all filtered episodes', () {
        // First apply language filter to get expected count
        contentService.setSelectedLanguage('zh-TW');

        contentService.setSearchQuery('');
        expect(
            contentService.filteredEpisodes.length, 1); // Only zh-TW episodes

        contentService.setSearchQuery('   '); // Whitespace
        expect(contentService.filteredEpisodes.length, 1);
      });

      test('case insensitive search', () async {
        // Set language to show zh-TW episodes which contain Bitcoin
        contentService.setSelectedLanguage('zh-TW');

        // Wait for language setting to be applied
        await Future.delayed(Duration(milliseconds: 10));

        contentService.setSearchQuery('BITCOIN');

        // Wait for filters to be applied
        await Future.delayed(Duration(milliseconds: 10));

        expect(contentService.filteredEpisodes.length, 1);
        expect(contentService.filteredEpisodes.first.title.toLowerCase(),
            contains('bitcoin'));
      });

      test('combined filters work together', () {
        contentService.setSelectedLanguage('en-US');
        contentService.setSelectedCategory('ethereum');
        contentService.setSearchQuery('Update');

        expect(contentService.filteredEpisodes.length, 1);
        expect(contentService.filteredEpisodes.first.language, 'en-US');
        expect(contentService.filteredEpisodes.first.category, 'ethereum');
        expect(contentService.filteredEpisodes.first.title, contains('Update'));
      });

      test('_applyFilters method processes all filters correctly', () {
        // Test internal _applyFilters by changing filters and checking results
        contentService.setSelectedLanguage('ja-JP');
        expect(contentService.filteredEpisodes.length, 1);
        expect(contentService.filteredEpisodes.first.language, 'ja-JP');
      });
    });

    group('Sorting', () {
      setUp(() async {
        // CRITICAL: Reset singleton to avoid state leakage
        RepositoryFactory.reset();

        // Create a fresh service instance for this group to avoid state leakage
        contentService.dispose();
        contentService = ContentFacadeService();

        // Allow async initialization to complete
        await Future.delayed(Duration(milliseconds: 10));

        // Reset to clean state
        contentService.setLoadingForTesting(false);
        contentService.setErrorForTesting(null);
        contentService.setSelectedLanguage('zh-TW');
        contentService.setSelectedCategory('all');
        contentService.setSearchQuery('');

        // Ensure state is fully propagated
        await Future.delayed(Duration(milliseconds: 5));
      });

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

        contentService.setSelectedLanguage('zh-TW');
        contentService.setSelectedCategory('all');
        await contentService.setSortOrder('alphabetical');

        // Wait for filters to be applied
        await Future.delayed(Duration(milliseconds: 10));

        expect(contentService.filteredEpisodes.isNotEmpty, true);
        expect(contentService.filteredEpisodes[0].title, 'Apple Episode');
      });

      test('sorts episodes by newest first (default)', () async {
        contentService.setEpisodesForTesting([
          AudioFile(
            id: '2025-01-10-old-episode',
            title: 'Old Episode',
            language: 'zh-TW',
            category: 'daily-news',
            streamingUrl: 'https://test.com/old.m3u8',
            path: 'audio/zh-TW/daily-news/old.m3u8',
            lastModified: DateTime(2025, 1, 10),
          ),
          AudioFile(
            id: '2025-01-20-new-episode',
            title: 'New Episode',
            language: 'zh-TW',
            category: 'daily-news',
            streamingUrl: 'https://test.com/new.m3u8',
            path: 'audio/zh-TW/daily-news/new.m3u8',
            lastModified: DateTime(2025, 1, 20),
          ),
        ]);

        contentService.setSelectedLanguage('zh-TW');
        contentService.setSelectedCategory('all');
        await contentService.setSortOrder('newest');

        // Wait for filters to be applied
        await Future.delayed(Duration(milliseconds: 10));

        expect(contentService.filteredEpisodes.isNotEmpty, true);
        expect(contentService.filteredEpisodes[0].title, 'New Episode');
      });

      test('sorts episodes by oldest first', () async {
        contentService.setEpisodesForTesting([
          AudioFile(
            id: '2025-01-10-old-episode',
            title: 'Old Episode',
            language: 'zh-TW',
            category: 'daily-news',
            streamingUrl: 'https://test.com/old.m3u8',
            path: 'audio/zh-TW/daily-news/old.m3u8',
            lastModified: DateTime(2025, 1, 10),
          ),
          AudioFile(
            id: '2025-01-20-new-episode',
            title: 'New Episode',
            language: 'zh-TW',
            category: 'daily-news',
            streamingUrl: 'https://test.com/new.m3u8',
            path: 'audio/zh-TW/daily-news/new.m3u8',
            lastModified: DateTime(2025, 1, 20),
          ),
        ]);

        contentService.setSelectedLanguage('zh-TW');
        contentService.setSelectedCategory('all');
        await contentService.setSortOrder('oldest');

        // Wait for filters to be applied
        await Future.delayed(Duration(milliseconds: 10));

        expect(contentService.filteredEpisodes.isNotEmpty, true);
        expect(contentService.filteredEpisodes[0].title, 'Old Episode');
      });

      test('does not change sort order if same value is set', () async {
        final initialSortOrder = contentService.sortOrder;
        await contentService.setSortOrder(initialSortOrder);
        expect(contentService.sortOrder, initialSortOrder);
      });

      test('_applySorting method works correctly', () async {
        contentService.setEpisodesForTesting([
          AudioFile(
            id: '2025-01-15-episode-b',
            title: 'B Episode',
            language: 'zh-TW',
            category: 'daily-news',
            streamingUrl: 'https://test.com/b.m3u8',
            path: 'audio/zh-TW/daily-news/b.m3u8',
            lastModified: DateTime(2025, 1, 15),
          ),
          AudioFile(
            id: '2025-01-16-episode-a',
            title: 'A Episode',
            language: 'zh-TW',
            category: 'daily-news',
            streamingUrl: 'https://test.com/a.m3u8',
            path: 'audio/zh-TW/daily-news/a.m3u8',
            lastModified: DateTime(2025, 1, 16),
          ),
        ]);

        contentService.setSelectedLanguage('zh-TW');
        contentService.setSelectedCategory('all');

        // Wait for filters to be applied
        await Future.delayed(Duration(milliseconds: 10));

        // Test that _applySorting is called when setting episodes
        expect(contentService.filteredEpisodes.isNotEmpty, true);
        expect(contentService.filteredEpisodes[0].title,
            'A Episode'); // Newest first by default
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

      test('updates episode completion percentage', () async {
        await contentService.updateEpisodeCompletion('episode-1', 0.5);
        expect(contentService.getEpisodeCompletion('episode-1'), 0.5);
      });

      test('clamps completion percentage to valid range', () async {
        await contentService.updateEpisodeCompletion(
            'episode-1', 1.5); // Above 1.0
        expect(contentService.getEpisodeCompletion('episode-1'), 1.0);

        await contentService.updateEpisodeCompletion(
            'episode-1', -0.5); // Below 0.0
        expect(contentService.getEpisodeCompletion('episode-1'), 0.0);
      });

      test('identifies finished episodes', () async {
        await contentService.updateEpisodeCompletion('episode-1', 0.95);
        expect(contentService.isEpisodeFinished('episode-1'), true);

        await contentService.updateEpisodeCompletion('episode-2', 0.8);
        expect(contentService.isEpisodeFinished('episode-2'), false);
      });

      test('identifies unfinished episodes', () async {
        await contentService.updateEpisodeCompletion('episode-1', 0.5);
        expect(contentService.isEpisodeUnfinished('episode-1'), true);

        await contentService.updateEpisodeCompletion('episode-2', 1.0);
        expect(contentService.isEpisodeUnfinished('episode-2'), false);

        // Not started episode
        expect(contentService.isEpisodeUnfinished('episode-3'), false);
      });

      test('gets unfinished episodes from filtered list', () async {
        contentService.setEpisodesForTesting(sampleEpisodes);

        // Create episodes that all match the same language for this test
        final testEpisodes = [
          AudioFile(
            id: 'test-episode-1',
            title: 'Test Episode 1',
            language: 'zh-TW', // Use default filter language
            category: 'daily-news',
            streamingUrl: 'https://test.com/episode1.m3u8',
            path: 'audio/zh-TW/daily-news/episode1.m3u8',
            lastModified: DateTime(2025, 1, 15),
            duration: Duration(minutes: 10),
          ),
          AudioFile(
            id: 'test-episode-2',
            title: 'Test Episode 2',
            language: 'zh-TW', // Use default filter language
            category: 'daily-news',
            streamingUrl: 'https://test.com/episode2.m3u8',
            path: 'audio/zh-TW/daily-news/episode2.m3u8',
            lastModified: DateTime(2025, 1, 14),
            duration: Duration(minutes: 15),
          ),
          AudioFile(
            id: 'test-episode-3',
            title: 'Test Episode 3',
            language: 'zh-TW', // Use default filter language
            category: 'daily-news',
            streamingUrl: 'https://test.com/episode3.m3u8',
            path: 'audio/zh-TW/daily-news/episode3.m3u8',
            lastModified: DateTime(2025, 1, 13),
            duration: Duration(minutes: 8),
          ),
        ];

        contentService.setEpisodesForTesting(testEpisodes);

        // Set up some completion data
        await contentService.updateEpisodeCompletion(testEpisodes[0].id, 0.3);
        await contentService.updateEpisodeCompletion(testEpisodes[1].id, 0.7);
        await contentService.updateEpisodeCompletion(testEpisodes[2].id, 1.0);

        final unfinished = contentService.getUnfinishedEpisodes();
        expect(unfinished.length, 2);
        expect(unfinished.any((e) => e.id == testEpisodes[0].id), true);
        expect(unfinished.any((e) => e.id == testEpisodes[1].id), true);
        expect(unfinished.any((e) => e.id == testEpisodes[2].id), false);
      });

      test('setEpisodeCompletion alias works correctly', () async {
        await contentService.setEpisodeCompletion('episode-1', 0.75);
        expect(contentService.getEpisodeCompletion('episode-1'), 0.75);
      });
    });

    group('Advanced Listen History', () {
      test('getListenHistoryEpisodes sorts by timestamp correctly', () async {
        contentService.setEpisodesForTesting(sampleEpisodes);

        final now = DateTime.now();

        // Add episodes to history with different timestamps
        await contentService.addToListenHistory(sampleEpisodes[0],
            at: now.subtract(Duration(hours: 2)));
        await contentService.addToListenHistory(sampleEpisodes[1],
            at: now.subtract(Duration(hours: 1)));
        await contentService.addToListenHistory(sampleEpisodes[2], at: now);

        final historyEpisodes = contentService.getListenHistoryEpisodes();

        // Should be sorted by most recent first
        expect(historyEpisodes.length, 3);
        expect(historyEpisodes[0].id, sampleEpisodes[2].id); // Most recent
        expect(historyEpisodes[1].id, sampleEpisodes[1].id); // Middle
        expect(historyEpisodes[2].id, sampleEpisodes[0].id); // Oldest
      });

      test('getListenHistoryEpisodes respects limit parameter', () async {
        contentService.setEpisodesForTesting(sampleEpisodes);

        // Add all episodes to history
        for (int i = 0; i < sampleEpisodes.length; i++) {
          await contentService.addToListenHistory(sampleEpisodes[i]);
        }

        // Test with limit of 2
        final limitedHistory =
            contentService.getListenHistoryEpisodes(limit: 2);
        expect(limitedHistory.length, 2);

        // Test with limit of 1
        final singleHistory = contentService.getListenHistoryEpisodes(limit: 1);
        expect(singleHistory.length, 1);
      });

      test('getListenHistoryEpisodes handles missing episodes gracefully',
          () async {
        // Set up episodes but only include some in allEpisodes
        contentService
            .setEpisodesForTesting([sampleEpisodes[0], sampleEpisodes[1]]);

        // Add all three to history (including one that's not in allEpisodes)
        await contentService.addToListenHistory(sampleEpisodes[0]);
        await contentService.addToListenHistory(sampleEpisodes[1]);
        await contentService
            .addToListenHistory(sampleEpisodes[2]); // This won't be found

        final historyEpisodes = contentService.getListenHistoryEpisodes();

        // Should only return the two that exist in allEpisodes
        expect(historyEpisodes.length, 2);
        expect(historyEpisodes.any((e) => e.id == sampleEpisodes[0].id), true);
        expect(historyEpisodes.any((e) => e.id == sampleEpisodes[1].id), true);
        expect(historyEpisodes.any((e) => e.id == sampleEpisodes[2].id), false);
      });

      test(
          'getListenHistoryEpisodes returns empty list when no episodes loaded',
          () {
        // Don't load any episodes
        contentService.setEpisodesForTesting([]);

        final historyEpisodes = contentService.getListenHistoryEpisodes();
        expect(historyEpisodes.length, 0);
      });
    });

    group('Listen History', () {
      test('adds episode to listen history', () async {
        await contentService.addToListenHistory(sampleEpisodes.first);
        expect(
            contentService.listenHistory.containsKey(sampleEpisodes.first.id),
            true);
      });

      test('adds episode with custom timestamp', () async {
        final customTime = DateTime(2025, 1, 10);
        await contentService.addToListenHistory(sampleEpisodes.first,
            at: customTime);
        expect(
            contentService.listenHistory[sampleEpisodes.first.id], customTime);
      });

      test('caps listen history to 100 entries', () async {
        // Add 105 episodes to history (reduced for faster test)
        for (int i = 0; i < 105; i++) {
          final episode = AudioFile(
            id: 'episode-$i',
            title: 'Episode $i',
            language: 'zh-TW',
            category: 'daily-news',
            streamingUrl: 'https://test.com/episode$i.m3u8',
            path: 'audio/zh-TW/daily-news/episode$i.m3u8',
            lastModified: DateTime(2025, 1, 15).subtract(Duration(days: i)),
          );
          await contentService.addToListenHistory(episode);
        }

        expect(contentService.listenHistory.length, 100);
      });

      test('removes episode from listen history', () async {
        await contentService.addToListenHistory(sampleEpisodes.first);
        await contentService.removeFromListenHistory(sampleEpisodes.first.id);
        expect(
            contentService.listenHistory.containsKey(sampleEpisodes.first.id),
            false);
      });

      test('clears all listen history', () async {
        await contentService.addToListenHistory(sampleEpisodes.first);
        await contentService.addToListenHistory(sampleEpisodes[1]);
        await contentService.clearListenHistory();
        expect(contentService.listenHistory.isEmpty, true);
      });

      test('gets listen history episodes sorted by timestamp', () async {
        contentService.setEpisodesForTesting(sampleEpisodes);

        // Mock listen history with different timestamps
        final now = DateTime.now();
        await contentService.addToListenHistory(sampleEpisodes[0],
            at: now.subtract(Duration(hours: 1)));
        await contentService.addToListenHistory(sampleEpisodes[1],
            at: now.subtract(Duration(hours: 2)));
        await contentService.addToListenHistory(sampleEpisodes[2], at: now);

        final historyEpisodes =
            contentService.getListenHistoryEpisodes(limit: 10);

        expect(historyEpisodes.length, 3);
        expect(historyEpisodes.first.id, sampleEpisodes[2].id); // Most recent
      });

      test('respects limit parameter in getListenHistoryEpisodes', () async {
        contentService.setEpisodesForTesting(sampleEpisodes);

        for (final episode in sampleEpisodes) {
          await contentService.addToListenHistory(episode);
        }

        final limitedHistory =
            contentService.getListenHistoryEpisodes(limit: 2);
        expect(limitedHistory.length, 2);
      });

      test('handles missing episodes in getListenHistoryEpisodes', () async {
        contentService
            .setEpisodesForTesting([sampleEpisodes.first]); // Only one episode

        // Add history for episodes that don't exist in allEpisodes
        await contentService.addToListenHistory(sampleEpisodes[0]);
        await contentService
            .addToListenHistory(sampleEpisodes[1]); // This won't be found

        final historyEpisodes = contentService.getListenHistoryEpisodes();
        expect(historyEpisodes.length, 1); // Only the existing episode
        expect(historyEpisodes.first.id, sampleEpisodes.first.id);
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

        // Ensure proper language and category filters
        contentService.setSelectedLanguage('zh-TW');
        contentService.setSelectedCategory('all');

        expect(contentService.filteredEpisodes,
            hasLength(greaterThanOrEqualTo(2)));
        final currentEpisode = contentService.filteredEpisodes[0];
        final nextEpisode = contentService.getNextEpisode(currentEpisode);
        expect(nextEpisode?.id, contentService.filteredEpisodes[1].id);
      });
    });

    group('Additional Coverage Tests', () {
      test('hasEpisodes returns correct boolean', () {
        expect(contentService.hasEpisodes, false);

        contentService.setEpisodesForTesting(sampleEpisodes);
        expect(contentService.hasEpisodes, true);
      });

      test('hasFilteredResults returns correct boolean', () {
        contentService.setEpisodesForTesting([]);
        expect(contentService.hasFilteredResults, false);

        contentService.setEpisodesForTesting(sampleEpisodes);
        // Need to ensure language filter includes sample episodes
        contentService.setSelectedLanguage('zh-TW');
        expect(contentService.hasFilteredResults, true);

        contentService
            .setSearchQuery('absolutely-non-existent-search-term-xyz123');
        expect(contentService.hasFilteredResults, false);
      });

      test('error handling methods work correctly', () {
        expect(contentService.hasError, false);
        expect(contentService.errorMessage, isNull);

        contentService.setErrorForTesting('Test error');
        expect(contentService.hasError, true);
        expect(contentService.errorMessage, 'Test error');
      });

      test('clearContentCache clears the content cache', () {
        // Add some content to cache
        contentService.cacheContent(
            'test-content-1', 'en-US', 'daily-news', sampleAudioContent);

        // Verify it's cached
        final cachedContent = contentService.getCachedContent(
            'test-content-1', 'en-US', 'daily-news');
        expect(cachedContent, isNotNull);

        // Clear the cache
        contentService.clearContentCache();

        // Verify it's cleared
        final clearedContent = contentService.getCachedContent(
            'test-content-1', 'en-US', 'daily-news');
        expect(clearedContent, isNull);
      });

      test('clear removes all content and resets state', () {
        contentService.setEpisodesForTesting(sampleEpisodes);
        contentService.createPlaylist('Test Playlist', sampleEpisodes);
        contentService.setErrorForTesting('Test error');

        expect(contentService.allEpisodes.length, 3);
        expect(contentService.currentPlaylist, isNotNull);
        expect(contentService.hasError, true);

        contentService.clear();

        expect(contentService.allEpisodes.length, 0);
        expect(contentService.filteredEpisodes.length, 0);
        expect(contentService.currentPlaylist, isNull);
        expect(contentService.hasError, false);
      });
    });
  });
}
