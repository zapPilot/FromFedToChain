import 'dart:async';
import '../models/audio_file.dart';

/// Abstract repository interface for progress and history data access
/// Handles episode completion tracking and listen history persistence
abstract class ProgressRepository {
  /// Initialize and load progress data
  Future<void> initialize();

  /// Get listen history map (episode ID -> timestamp)
  Map<String, DateTime> get listenHistory;

  /// Get episode completion percentage (0.0 to 1.0)
  double getEpisodeCompletion(String episodeId);

  /// Check if episode is considered finished (>= 90% completion)
  bool isEpisodeFinished(String episodeId);

  /// Check if episode is unfinished (started but not completed)
  bool isEpisodeUnfinished(String episodeId);

  /// Update episode completion percentage
  Future<void> updateEpisodeCompletion(String episodeId, double completion);

  /// Mark episode as finished
  Future<void> markEpisodeAsFinished(String episodeId);

  /// Reset episode progress
  Future<void> resetEpisodeProgress(String episodeId);

  /// Record an episode in listen history
  Future<void> addToListenHistory(AudioFile episode, {DateTime? at});

  /// Remove an episode from listen history
  Future<void> removeFromListenHistory(String episodeId);

  /// Clear all listen history
  Future<void> clearListenHistory();

  /// Get listen history episodes with optional limit
  List<AudioFile> getListenHistoryEpisodes(List<AudioFile> allEpisodes,
      {int limit = 50});

  /// Get unfinished episodes from a list
  List<AudioFile> getUnfinishedEpisodes(List<AudioFile> episodes);

  /// Get finished episodes from a list
  List<AudioFile> getFinishedEpisodes(List<AudioFile> episodes);

  /// Start tracking a listening session
  void startListeningSession(String episodeId);

  /// Update current session duration
  void updateSessionDuration(Duration duration);

  /// End listening session and record progress
  Future<void> endListeningSession({double? finalCompletion});

  /// Get listening statistics
  Map<String, dynamic> getListeningStatistics(List<AudioFile> allEpisodes);

  /// Export progress data
  Map<String, dynamic> exportProgressData();

  /// Import progress data
  Future<void> importProgressData(Map<String, dynamic> data);

  /// Clear all progress data
  Future<void> clearAllProgress();

  /// Dispose of resources
  void dispose();
}
