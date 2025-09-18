import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/audio_file.dart';
import '../repositories/progress_repository.dart';

/// Service for tracking episode progress and listen history
/// Handles completion percentages, listen history, and user progress analytics
class ProgressTrackingService extends ChangeNotifier
    implements ProgressRepository {
  // Episode completion tracking (episodeId -> completion percentage 0.0-1.0)
  final Map<String, double> _episodeCompletion = {};

  // Listen history (episodeId -> last listened timestamp)
  final Map<String, DateTime> _listenHistory = {};

  // Session tracking for current listening session
  String? _currentEpisodeId;
  DateTime? _sessionStartTime;
  Duration _sessionDuration = Duration.zero;

  bool _disposed = false;

  // Getters
  Map<String, double> get episodeCompletion =>
      Map.unmodifiable(_episodeCompletion);
  Map<String, DateTime> get listenHistory => Map.unmodifiable(_listenHistory);
  String? get currentEpisodeId => _currentEpisodeId;
  DateTime? get sessionStartTime => _sessionStartTime;
  Duration get sessionDuration => _sessionDuration;

  /// Initialize and load progress data
  Future<void> initialize() async {
    if (_disposed) return;
    await _loadProgressData();
  }

  /// Load progress data from SharedPreferences
  Future<void> _loadProgressData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load episode completion data
      final completionJson = prefs.getString('episode_completion');
      if (completionJson != null) {
        final completionData =
            json.decode(completionJson) as Map<String, dynamic>;
        _episodeCompletion.clear();
        completionData.forEach((key, value) {
          _episodeCompletion[key] = (value as num).toDouble();
        });
      }

      // Load listen history
      final historyJson = prefs.getString('listen_history');
      if (historyJson != null) {
        final historyData = json.decode(historyJson) as Map<String, dynamic>;
        _listenHistory.clear();
        historyData.forEach((key, value) {
          try {
            _listenHistory[key] = DateTime.parse(value as String);
          } catch (_) {
            // Skip invalid timestamps
          }
        });
      }

      if (kDebugMode) {
        print(
            'ProgressTrackingService: Loaded ${_episodeCompletion.length} completion records and ${_listenHistory.length} history entries');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ProgressTrackingService: Failed to load progress data: $e');
      }
    }
  }

  /// Save progress data to SharedPreferences
  Future<void> _saveProgressData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save episode completion data
      final completionJson = json.encode(_episodeCompletion);
      await prefs.setString('episode_completion', completionJson);

      // Save listen history (as id -> ISO8601 string)
      final historyMap = <String, String>{
        for (final e in _listenHistory.entries) e.key: e.value.toIso8601String()
      };
      await prefs.setString('listen_history', json.encode(historyMap));

      if (kDebugMode) {
        print('ProgressTrackingService: Saved progress data successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ProgressTrackingService: Failed to save progress data: $e');
      }
    }
  }

  /// Get episode completion percentage (0.0 to 1.0)
  @override
  double getEpisodeCompletion(String episodeId) {
    return _episodeCompletion[episodeId] ?? 0.0;
  }

  /// Check if episode is considered finished (>= 90% completion)
  bool isEpisodeFinished(String episodeId) {
    return getEpisodeCompletion(episodeId) >= 0.9;
  }

  /// Check if episode is unfinished (started but not completed)
  bool isEpisodeUnfinished(String episodeId) {
    final completion = getEpisodeCompletion(episodeId);
    return completion > 0.0 && completion < 0.9;
  }

  /// Update episode completion percentage (0.0 to 1.0)
  @override
  Future<void> updateEpisodeCompletion(
      String episodeId, double completion) async {
    if (_disposed) return;

    final clampedCompletion = completion.clamp(0.0, 1.0);

    if (_episodeCompletion[episodeId] != clampedCompletion) {
      _episodeCompletion[episodeId] = clampedCompletion;
      await _saveProgressData();

      if (!_disposed) {
        notifyListeners();
      }

      if (kDebugMode) {
        print(
            'ProgressTrackingService: Updated completion for $episodeId to ${(clampedCompletion * 100).toStringAsFixed(1)}%');
      }
    }
  }

  /// Mark episode as finished (completion = 1.0)
  Future<void> markEpisodeAsFinished(String episodeId) async {
    await updateEpisodeCompletion(episodeId, 1.0);
  }

  /// Reset episode progress
  Future<void> resetEpisodeProgress(String episodeId) async {
    if (_episodeCompletion.containsKey(episodeId)) {
      _episodeCompletion.remove(episodeId);
      await _saveProgressData();
      notifyListeners();

      if (kDebugMode) {
        print('ProgressTrackingService: Reset progress for $episodeId');
      }
    }
  }

  /// Record an episode in listen history (update timestamp, cap size)
  @override
  Future<void> addToListenHistory(AudioFile episode, {DateTime? at}) async {
    if (_disposed) return;

    final timestamp = at ?? DateTime.now();
    _listenHistory[episode.id] = timestamp;

    // Cap history size to last 100 entries
    if (_listenHistory.length > 100) {
      final sorted = _listenHistory.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final keep = sorted.take(100);
      _listenHistory
        ..clear()
        ..addEntries(keep);
    }

    await _saveProgressData();

    if (!_disposed) {
      notifyListeners();
    }

    if (kDebugMode) {
      print(
          'ProgressTrackingService: Added ${episode.title} to listen history');
    }
  }

  /// Remove an episode from listen history
  @override
  Future<void> removeFromListenHistory(String episodeId) async {
    if (_listenHistory.containsKey(episodeId)) {
      _listenHistory.remove(episodeId);
      await _saveProgressData();
      notifyListeners();

      if (kDebugMode) {
        print(
            'ProgressTrackingService: Removed $episodeId from listen history');
      }
    }
  }

  /// Clear all listen history
  @override
  Future<void> clearListenHistory() async {
    _listenHistory.clear();
    await _saveProgressData();
    notifyListeners();

    if (kDebugMode) {
      print('ProgressTrackingService: Cleared all listen history');
    }
  }

  /// Get listen history episodes with optional limit
  @override
  List<AudioFile> getListenHistoryEpisodes(List<AudioFile> allEpisodes,
      {int limit = 50}) {
    final entries = _listenHistory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Map IDs to episodes; skip missing
    final byId = {for (final e in allEpisodes) e.id: e};
    final episodes = <AudioFile>[];

    for (final entry in entries) {
      final episode = byId[entry.key];
      if (episode != null) {
        episodes.add(episode);
      }
      if (episodes.length >= limit) break;
    }

    return episodes;
  }

  /// Get unfinished episodes from a list
  List<AudioFile> getUnfinishedEpisodes(List<AudioFile> episodes) {
    return episodes
        .where((episode) => isEpisodeUnfinished(episode.id))
        .toList();
  }

  /// Get finished episodes from a list
  List<AudioFile> getFinishedEpisodes(List<AudioFile> episodes) {
    return episodes.where((episode) => isEpisodeFinished(episode.id)).toList();
  }

  /// Start tracking a listening session
  void startListeningSession(String episodeId) {
    _currentEpisodeId = episodeId;
    _sessionStartTime = DateTime.now();
    _sessionDuration = Duration.zero;

    if (kDebugMode) {
      print(
          'ProgressTrackingService: Started listening session for $episodeId');
    }
  }

  /// Update current session duration
  void updateSessionDuration(Duration duration) {
    _sessionDuration = duration;
  }

  /// End listening session and record progress
  Future<void> endListeningSession({double? finalCompletion}) async {
    if (_currentEpisodeId != null) {
      // Record in history
      final dummyEpisode = AudioFile(
        id: _currentEpisodeId!,
        title: '',
        language: '',
        category: '',
        streamingUrl: '',
        path: '',
        lastModified: DateTime.now(),
      );
      await addToListenHistory(dummyEpisode);

      // Update completion if provided
      if (finalCompletion != null) {
        await updateEpisodeCompletion(_currentEpisodeId!, finalCompletion);
      }

      if (kDebugMode) {
        print(
            'ProgressTrackingService: Ended listening session for $_currentEpisodeId (duration: $_sessionDuration)');
      }

      _currentEpisodeId = null;
      _sessionStartTime = null;
      _sessionDuration = Duration.zero;
    }
  }

  /// Get listening statistics
  Map<String, dynamic> getListeningStatistics(List<AudioFile> allEpisodes) {
    final totalEpisodes = allEpisodes.length;
    final finishedCount =
        allEpisodes.where((e) => isEpisodeFinished(e.id)).length;
    final unfinishedCount =
        allEpisodes.where((e) => isEpisodeUnfinished(e.id)).length;
    final unstartedCount = totalEpisodes - finishedCount - unfinishedCount;

    // Calculate total listening time estimate
    final totalDuration = allEpisodes.fold<Duration>(
      Duration.zero,
      (sum, episode) => sum + (episode.duration ?? Duration.zero),
    );

    final finishedDuration =
        allEpisodes.where((e) => isEpisodeFinished(e.id)).fold<Duration>(
              Duration.zero,
              (sum, episode) => sum + (episode.duration ?? Duration.zero),
            );

    // Average completion for unfinished episodes
    final unfinishedEpisodes =
        allEpisodes.where((e) => isEpisodeUnfinished(e.id));
    final avgUnfinishedCompletion = unfinishedEpisodes.isEmpty
        ? 0.0
        : unfinishedEpisodes
                .map((e) => getEpisodeCompletion(e.id))
                .reduce((a, b) => a + b) /
            unfinishedEpisodes.length;

    return {
      'totalEpisodes': totalEpisodes,
      'finishedCount': finishedCount,
      'unfinishedCount': unfinishedCount,
      'unstartedCount': unstartedCount,
      'completionRate': totalEpisodes > 0 ? finishedCount / totalEpisodes : 0.0,
      'totalDuration': totalDuration,
      'finishedDuration': finishedDuration,
      'averageUnfinishedCompletion': avgUnfinishedCompletion,
      'listenHistorySize': _listenHistory.length,
      'currentStreak': _calculateListeningStreak(),
      'favoriteDayOfWeek': _calculateFavoriteDayOfWeek(),
      'averageSessionLength': _calculateAverageSessionLength(),
    };
  }

  /// Calculate current listening streak (consecutive days)
  int _calculateListeningStreak() {
    if (_listenHistory.isEmpty) return 0;

    final sortedDates = _listenHistory.values
        .map((date) => DateTime(date.year, date.month, date.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    for (int i = 0; i < sortedDates.length; i++) {
      final expectedDate = todayDate.subtract(Duration(days: i));
      if (sortedDates[i] == expectedDate) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  /// Calculate favorite day of the week for listening
  String _calculateFavoriteDayOfWeek() {
    if (_listenHistory.isEmpty) return 'Unknown';

    final dayCount = <int, int>{};
    for (final date in _listenHistory.values) {
      dayCount[date.weekday] = (dayCount[date.weekday] ?? 0) + 1;
    }

    final favoriteDayNum =
        dayCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    const dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];

    return dayNames[favoriteDayNum - 1];
  }

  /// Calculate average session length
  Duration _calculateAverageSessionLength() {
    // This would be more accurate with session duration tracking
    // For now, estimate based on completion data
    if (_episodeCompletion.isEmpty) return Duration.zero;

    final totalCompletionMinutes = _episodeCompletion.values.fold<double>(
        0.0,
        (sum, completion) =>
            sum + completion * 30); // Assume 30 min average episode

    final avgMinutes = totalCompletionMinutes / _episodeCompletion.length;
    return Duration(minutes: avgMinutes.round());
  }

  /// Export progress data
  Map<String, dynamic> exportProgressData() {
    return {
      'episodeCompletion': _episodeCompletion,
      'listenHistory': {
        for (final entry in _listenHistory.entries)
          entry.key: entry.value.toIso8601String()
      },
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Import progress data
  Future<void> importProgressData(Map<String, dynamic> data) async {
    try {
      // Import completion data
      final completionData = data['episodeCompletion'] as Map<String, dynamic>?;
      if (completionData != null) {
        _episodeCompletion.clear();
        completionData.forEach((key, value) {
          _episodeCompletion[key] = (value as num).toDouble();
        });
      }

      // Import history data
      final historyData = data['listenHistory'] as Map<String, dynamic>?;
      if (historyData != null) {
        _listenHistory.clear();
        historyData.forEach((key, value) {
          try {
            _listenHistory[key] = DateTime.parse(value as String);
          } catch (_) {
            // Skip invalid timestamps
          }
        });
      }

      await _saveProgressData();
      notifyListeners();

      if (kDebugMode) {
        print('ProgressTrackingService: Imported progress data successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ProgressTrackingService: Failed to import progress data: $e');
      }
    }
  }

  /// Clear all progress data
  @override
  Future<void> clearAllProgress() async {
    _episodeCompletion.clear();
    _listenHistory.clear();
    await _saveProgressData();
    notifyListeners();

    if (kDebugMode) {
      print('ProgressTrackingService: Cleared all progress data');
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    _episodeCompletion.clear();
    _listenHistory.clear();
    super.dispose();
  }

  // Testing methods
  @visibleForTesting
  void setCompletionForTesting(String episodeId, double completion) {
    _episodeCompletion[episodeId] = completion;
    notifyListeners();
  }

  @visibleForTesting
  void setHistoryForTesting(String episodeId, DateTime timestamp) {
    _listenHistory[episodeId] = timestamp;
    notifyListeners();
  }

  @visibleForTesting
  void clearDataForTesting() {
    _episodeCompletion.clear();
    _listenHistory.clear();
    notifyListeners();
  }
}
