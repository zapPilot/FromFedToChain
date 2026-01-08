import 'package:from_fed_to_chain_app/features/content/data/episode_repository.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';

/// Use case for loading episodes from the repository.
///
/// This use case encapsulates the episode loading logic, making it
/// easily testable and reusable. It depends on [EpisodeRepository]
/// which can be mocked for testing.
///
/// Example:
/// ```dart
/// final useCase = LoadEpisodesUseCase(repository);
/// final episodes = await useCase.loadAll();
/// ```
class LoadEpisodesUseCase {
  final EpisodeRepository _repository;

  /// Create a LoadEpisodesUseCase with the given repository.
  LoadEpisodesUseCase(this._repository);

  /// Load all episodes from all languages and categories.
  ///
  /// Returns a list of all available episodes, sorted by date (newest first).
  Future<List<AudioFile>> loadAll() async {
    return await _repository.loadAllEpisodes();
  }

  /// Load episodes for a specific language.
  ///
  /// [language] - The language code (e.g., 'zh-TW', 'en-US', 'ja-JP')
  ///
  /// Returns a list of episodes for the specified language.
  Future<List<AudioFile>> loadForLanguage(String language) async {
    return await _repository.loadEpisodesForLanguage(language);
  }

  /// Search for episodes matching a query.
  ///
  /// [query] - The search query string
  ///
  /// Returns a list of episodes matching the query.
  Future<List<AudioFile>> search(String query) async {
    return await _repository.searchEpisodes(query);
  }

  /// Get an episode by its ID.
  ///
  /// [contentId] - The episode content ID
  /// [preferredLanguage] - Optional preferred language for multi-language content
  ///
  /// Returns the episode if found, null otherwise.
  Future<AudioFile?> getById(String contentId,
      {String? preferredLanguage}) async {
    return await _repository.getEpisodeById(contentId,
        preferredLanguage: preferredLanguage);
  }
}
