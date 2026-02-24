import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:from_fed_to_chain_app/features/content/data/progress_repository.dart';
import 'package:from_fed_to_chain_app/features/content/data/preferences_repository.dart';
import 'package:from_fed_to_chain_app/features/content/domain/use_cases/use_cases.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';
import 'package:from_fed_to_chain_app/features/content/services/content_service.dart';

import 'content_service_ui_test.mocks.dart';

@GenerateMocks([
  LoadEpisodesUseCase,
  FilterEpisodesUseCase,
  SearchEpisodesUseCase,
  ProgressRepository,
  PreferencesRepository
])
void main() {
  late ContentService contentService;
  late MockLoadEpisodesUseCase mockLoadEpisodes;
  late MockFilterEpisodesUseCase mockFilterEpisodes;
  late MockSearchEpisodesUseCase mockSearchEpisodes;
  late MockProgressRepository mockProgress;
  late MockPreferencesRepository mockPreferences;

  setUp(() {
    mockLoadEpisodes = MockLoadEpisodesUseCase();
    mockFilterEpisodes = MockFilterEpisodesUseCase();
    mockSearchEpisodes = MockSearchEpisodesUseCase();
    mockProgress = MockProgressRepository();
    mockPreferences = MockPreferencesRepository();

    when(mockPreferences.selectedLanguage).thenReturn('zh-TW');
    when(mockPreferences.selectedCategory).thenReturn('all');
    when(mockPreferences.searchQuery).thenReturn('');
    when(mockPreferences.sortOrder).thenReturn('newest');
    when(mockProgress.initialize()).thenAnswer((_) async {});
    when(mockPreferences.initialize()).thenAnswer((_) async {});
    when(mockProgress.listenHistory).thenReturn({});

    when(mockFilterEpisodes.call(
      episodes: anyNamed('episodes'),
      language: anyNamed('language'),
      category: anyNamed('category'),
      searchQuery: anyNamed('searchQuery'),
      sortOrder: anyNamed('sortOrder'),
    )).thenAnswer((invocation) =>
        invocation.namedArguments[#episodes] as List<AudioFile>);

    contentService = ContentService(
      loadEpisodesUseCase: mockLoadEpisodes,
      filterEpisodesUseCase: mockFilterEpisodes,
      searchEpisodesUseCase: mockSearchEpisodes,
      progressRepository: mockProgress,
      preferencesRepository: mockPreferences,
    );
  });

  group('ContentService - New UI Features', () {
    final episodes = [
      AudioFile(
        id: '2025-01-01-ep1',
        title: 'Episode 1 ZH',
        language: 'zh-TW',
        category: 'daily-news',
        streamingUrl: 'url1_zh',
        path: 'path1_zh',
        lastModified: DateTime(2025, 1, 1),
      ),
      AudioFile(
        id: '2025-01-01-ep1',
        title: 'Episode 1 EN',
        language: 'en-US',
        category: 'daily-news',
        streamingUrl: 'url1_en',
        path: 'path1_en',
        lastModified: DateTime(2025, 1, 1),
      ),
      AudioFile(
        id: '2025-01-02-ep2',
        title: 'Episode 2 ZH',
        language: 'zh-TW',
        category: 'ethereum',
        streamingUrl: 'url2_zh',
        path: 'path2_zh',
        lastModified: DateTime(2025, 1, 2),
      ),
    ];

    test('getEpisodeVersions returns all language versions for an ID', () {
      contentService.setEpisodesForTesting(episodes);

      final versions = contentService.getEpisodeVersions('2025-01-01-ep1');

      expect(versions.length, 2);
      expect(versions.any((e) => e.language == 'zh-TW'), isTrue);
      expect(versions.any((e) => e.language == 'en-US'), isTrue);
    });

    test('getAudioFileById prioritizes preferred language', () async {
      contentService.setEpisodesForTesting(episodes);

      final result = await contentService.getAudioFileById(
        '2025-01-01-ep1',
        preferredLanguage: 'en-US',
      );

      expect(result?.language, 'en-US');
    });

    test('getFocusQueue separates in-progress and unplayed episodes', () {
      contentService.setEpisodesForTesting(episodes);

      // Ep 1 ZH is in progress
      when(mockProgress.isEpisodeUnfinished('2025-01-01-ep1')).thenReturn(true);
      when(mockProgress.getEpisodeCompletion('2025-01-01-ep1')).thenReturn(0.5);
      when(mockProgress.isEpisodeFinished('2025-01-01-ep1')).thenReturn(false);

      // Ep 2 ZH is unplayed
      when(mockProgress.isEpisodeUnfinished('2025-01-02-ep2'))
          .thenReturn(false);
      when(mockProgress.getEpisodeCompletion('2025-01-02-ep2')).thenReturn(0.0);
      when(mockProgress.isEpisodeFinished('2025-01-02-ep2')).thenReturn(false);

      final queue = contentService.getFocusQueue('zh-TW');

      expect(queue.length, 2);
      expect(queue[0].id, '2025-01-01-ep1'); // In progress first
      expect(queue[1].id, '2025-01-02-ep2'); // Unplayed second
    });

    test('loadEpisodesForLanguage refreshes all episodes from repository',
        () async {
      when(mockLoadEpisodes.loadForLanguage('en-US'))
          .thenAnswer((_) async => [episodes[1]]);
      when(mockLoadEpisodes.loadAll()).thenAnswer((_) async => episodes);

      await contentService.loadEpisodesForLanguage('en-US');

      verify(mockLoadEpisodes.loadForLanguage('en-US')).called(1);
      verify(mockLoadEpisodes.loadAll()).called(1);
      expect(contentService.allEpisodes.length, 3);
    });
  });
}
