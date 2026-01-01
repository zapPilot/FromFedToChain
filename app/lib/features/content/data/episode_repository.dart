import 'dart:async';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';

/// Abstract repository interface for episode data access
/// Follows Repository pattern for clean separation of data access logic
abstract class EpisodeRepository {
  /// Load all available episodes from the data source
  Future<List<AudioFile>> loadAllEpisodes();

  /// Load episodes for a specific language
  Future<List<AudioFile>> loadEpisodesForLanguage(String language);

  /// Search episodes by query across all content
  Future<List<AudioFile>> searchEpisodes(String query);

  /// Get episode by ID with optional language preference
  Future<AudioFile?> getEpisodeById(String contentId,
      {String? preferredLanguage});

  /// Get episodes filtered by language
  List<AudioFile> getEpisodesByLanguage(
      List<AudioFile> episodes, String language);

  /// Get episodes filtered by category
  List<AudioFile> getEpisodesByCategory(
      List<AudioFile> episodes, String category);

  /// Get episodes filtered by both language and category
  List<AudioFile> getEpisodesByLanguageAndCategory(
    List<AudioFile> episodes,
    String language,
    String category,
  );

  /// Apply search filtering to episodes list
  List<AudioFile> filterEpisodesByQuery(List<AudioFile> episodes, String query);

  /// Get statistics about episodes
  Map<String, dynamic> getEpisodeStatistics(List<AudioFile> episodes);

  /// Dispose of any resources
  void dispose();
}
