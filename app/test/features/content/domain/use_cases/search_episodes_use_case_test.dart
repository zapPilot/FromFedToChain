import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:from_fed_to_chain_app/features/content/data/streaming_api_service.dart';
import 'package:from_fed_to_chain_app/features/content/domain/use_cases/search_episodes_use_case.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';

@GenerateMocks([StreamingApiService])
import 'search_episodes_use_case_test.mocks.dart';

void main() {
  group('SearchEpisodesUseCase', () {
    late SearchEpisodesUseCase useCase;
    late MockStreamingApiService mockApiService;

    setUp(() {
      mockApiService = MockStreamingApiService();
      useCase = SearchEpisodesUseCase(mockApiService, maxCacheSize: 2);
    });

    final List<AudioFile> mockEpisodes = [
      AudioFile(
          id: '1',
          title: 'Bitcoin',
          path: 'p1',
          category: 'crypto',
          language: 'en-US',
          streamingUrl: 'url1',
          lastModified: DateTime.now()),
      AudioFile(
          id: '2',
          title: 'Ethereum',
          path: 'p2',
          category: 'crypto',
          language: 'en-US',
          streamingUrl: 'url2',
          lastModified: DateTime.now()),
    ];

    test('should return local results if query is found in localData',
        () async {
      final result = await useCase(
        query: 'Bitcoin',
        localEpisodes: mockEpisodes,
      );

      expect(result.length, 1);
      expect(result.first.id, '1');
      // Should NOT call API
      verifyNever(mockApiService.fetchSearchEpisodes(any));
    });

    test('should cache local results', () async {
      await useCase(query: 'Bitcoin', localEpisodes: mockEpisodes);

      // Clear interactions to ensure next call uses cache
      verifyNever(mockApiService.fetchSearchEpisodes(any));

      // Second call should return cached result immediately
      expect(useCase.cacheSize, 1);
    });

    test('should call API if local search returns empty', () async {
      final List<AudioFile> apiResults = [
        AudioFile(
            id: '3',
            title: 'Litecoin',
            path: 'p3',
            language: 'en-US',
            category: 'crypto',
            streamingUrl: 'url3',
            lastModified: DateTime.now())
      ];
      when(mockApiService.fetchSearchEpisodes('Litecoin'))
          .thenAnswer((_) async => apiResults);

      final result = await useCase(
        query: 'Litecoin',
        localEpisodes: mockEpisodes, // No Litecoin here
      );

      expect(result, apiResults);
      verify(mockApiService.fetchSearchEpisodes('Litecoin')).called(1);
      expect(useCase.cacheSize, 1);
    });

    test('should return cached result on second call', () async {
      final List<AudioFile> apiResults = [
        AudioFile(
            id: '3',
            title: 'Litecoin',
            path: 'p3',
            language: 'en-US',
            category: 'crypto',
            streamingUrl: 'url3',
            lastModified: DateTime.now())
      ];
      when(mockApiService.fetchSearchEpisodes('Litecoin'))
          .thenAnswer((_) async => apiResults);

      // First call -> hits API
      await useCase(query: 'Litecoin', localEpisodes: mockEpisodes);
      verify(mockApiService.fetchSearchEpisodes('Litecoin')).called(1);

      // Second call -> hits Cache
      await useCase(query: 'Litecoin', localEpisodes: mockEpisodes);
      // API call count should still be 1
      verifyNoMoreInteractions(mockApiService);
    });

    test('should respect max cache size', () async {
      final List<AudioFile> apiResults = [];
      when(mockApiService.fetchSearchEpisodes(any))
          .thenAnswer((_) async => apiResults);

      // Cache size is 2
      await useCase(query: '1', localEpisodes: []);
      await useCase(query: '2', localEpisodes: []);
      expect(useCase.cacheSize, 2);

      // Add 3rd item -> should evict 1st
      await useCase(query: '3', localEpisodes: []);
      expect(useCase.cacheSize, 2);
    });

    test('should handle API errors gracefully', () async {
      when(mockApiService.fetchSearchEpisodes(any))
          .thenThrow(Exception('API Error'));

      final result = await useCase(
        query: 'Unknown',
        localEpisodes: [],
      );

      expect(result, isEmpty);
    });
  });
}
