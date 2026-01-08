import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:from_fed_to_chain_app/features/content/data/episode_repository.dart';
import 'package:from_fed_to_chain_app/features/content/domain/use_cases/load_episodes_use_case.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';

@GenerateMocks([EpisodeRepository])
import 'load_episodes_use_case_test.mocks.dart';

void main() {
  group('LoadEpisodesUseCase', () {
    late LoadEpisodesUseCase useCase;
    late MockEpisodeRepository mockRepository;

    setUp(() {
      mockRepository = MockEpisodeRepository();
      useCase = LoadEpisodesUseCase(mockRepository);
    });

    test('loadAll should delegate to repository', () async {
      // Arrange
      final List<AudioFile> mockEpisodes = [
        AudioFile(
            id: '1',
            title: 'Ep 1',
            path: 'p1',
            language: 'en-US',
            category: 'news',
            streamingUrl: 'url1',
            lastModified: DateTime.now())
      ];
      when(mockRepository.loadAllEpisodes())
          .thenAnswer((_) async => mockEpisodes);

      // Act
      final result = await useCase.loadAll();

      // Assert
      expect(result, mockEpisodes);
      verify(mockRepository.loadAllEpisodes()).called(1);
    });

    test('loadForLanguage should delegate to repository', () async {
      // Arrange
      final List<AudioFile> mockEpisodes = [
        AudioFile(
            id: '1',
            title: 'Ep 1',
            path: 'p1',
            language: 'en-US',
            category: 'news',
            streamingUrl: 'url1',
            lastModified: DateTime.now())
      ];
      const lang = 'en-US';
      when(mockRepository.loadEpisodesForLanguage(lang))
          .thenAnswer((_) async => mockEpisodes);

      // Act
      final result = await useCase.loadForLanguage(lang);

      // Assert
      expect(result, mockEpisodes);
      verify(mockRepository.loadEpisodesForLanguage(lang)).called(1);
    });

    test('search should delegate to repository', () async {
      // Arrange
      final List<AudioFile> mockEpisodes = [
        AudioFile(
            id: '1',
            title: 'Ep 1',
            path: 'p1',
            language: 'en-US',
            category: 'news',
            streamingUrl: 'url1',
            lastModified: DateTime.now())
      ];
      const query = 'test';
      when(mockRepository.searchEpisodes(query))
          .thenAnswer((_) async => mockEpisodes);

      // Act
      final result = await useCase.search(query);

      // Assert
      expect(result, mockEpisodes);
      verify(mockRepository.searchEpisodes(query)).called(1);
    });

    test('getById should delegate to repository', () async {
      // Arrange
      final mockEpisode = AudioFile(
          id: '1',
          title: 'Ep 1',
          path: 'p1',
          language: 'en-US',
          category: 'news',
          streamingUrl: 'url1',
          lastModified: DateTime.now());
      const id = '1';
      when(mockRepository.getEpisodeById(id,
              preferredLanguage: anyNamed('preferredLanguage')))
          .thenAnswer((_) async => mockEpisode);

      // Act
      final result = await useCase.getById(id);

      // Assert
      expect(result, mockEpisode);
      verify(mockRepository.getEpisodeById(id)).called(1);
    });
  });
}
