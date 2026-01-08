import 'package:flutter_test/flutter_test.dart';
import 'package:from_fed_to_chain_app/features/content/domain/use_cases/filter_episodes_use_case.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';

void main() {
  group('FilterEpisodesUseCase', () {
    late FilterEpisodesUseCase useCase;
    late List<AudioFile> testEpisodes;

    setUp(() {
      useCase = FilterEpisodesUseCase();
      testEpisodes = [
        // English Episodes
        AudioFile(
          id: 'en-1',
          path: 'path/en/1',
          title: 'Bitcoin News',
          category: 'daily-news',
          language: 'en-US',
          streamingUrl: 'url',
          lastModified: DateTime(2025, 1, 10), // Newest
        ),
        AudioFile(
          id: 'en-2',
          path: 'path/en/2',
          title: 'Ethereum Update',
          category: 'ethereum',
          language: 'en-US',
          streamingUrl: 'url',
          lastModified: DateTime(2025, 1, 8),
        ),
        // Chinese Episodes
        AudioFile(
          id: 'zh-1',
          path: 'path/zh/1',
          title: 'Bitcoin Analysis (ZH)',
          category: 'daily-news',
          language: 'zh-TW',
          streamingUrl: 'url',
          lastModified: DateTime(2025, 1, 9),
        ),
        AudioFile(
          id: 'zh-2',
          path: 'path/zh/2',
          title: 'Startup Talk',
          category: 'startup',
          language: 'zh-TW',
          streamingUrl: 'url',
          lastModified: DateTime(2025, 1, 5), // Oldest
        ),
      ];
    });

    test('should return all episodes when no filters applied', () {
      final result = useCase(episodes: testEpisodes);
      expect(result.length, 4);
      // specific order check - default is newest first
      expect(result[0].id, 'en-1'); // Jan 10
      expect(result[1].id, 'zh-1'); // Jan 9
      expect(result[2].id, 'en-2'); // Jan 8
      expect(result[3].id, 'zh-2'); // Jan 5
    });

    test('should filter by language', () {
      final result = useCase(episodes: testEpisodes, language: 'en-US');
      expect(result.length, 2);
      expect(result.every((e) => e.language == 'en-US'), isTrue);
    });

    test('should filter by category', () {
      final result = useCase(episodes: testEpisodes, category: 'daily-news');
      expect(result.length, 2);
      expect(result.every((e) => e.category == 'daily-news'), isTrue);
    });

    test('should filter by language and category', () {
      final result = useCase(
        episodes: testEpisodes,
        language: 'zh-TW',
        category: 'startup',
      );
      expect(result.length, 1);
      expect(result.first.id, 'zh-2');
    });

    test('should filter by search query', () {
      final result = useCase(episodes: testEpisodes, searchQuery: 'Bitcoin');
      expect(result.length, 2);
      expect(result.any((e) => e.id == 'en-1'), isTrue);
      expect(result.any((e) => e.id == 'zh-1'), isTrue);
    });

    test('should sort by oldest', () {
      final result = useCase(episodes: testEpisodes, sortOrder: 'oldest');
      expect(result.first.id, 'zh-2'); // Jan 5
      expect(result.last.id, 'en-1'); // Jan 10
    });

    test('should sort alphabetically', () {
      final result = useCase(episodes: testEpisodes, sortOrder: 'alphabetical');
      expect(result.first.title, 'Bitcoin Analysis (ZH)'); // 'B'
      expect(result.last.title, 'Startup Talk'); // 'S'
    });

    test('should return empty list when no matches found', () {
      final result = useCase(
        episodes: testEpisodes,
        language: 'ja-JP', // None
      );
      expect(result, isEmpty);
    });
  });
}
