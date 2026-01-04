import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';

/// Helper class to calculate listening analytics and statistics
class ListeningAnalyticsCalculator {
  /// Calculate all listening statistics
  static Map<String, dynamic> calculateStatistics({
    required List<AudioFile> allEpisodes,
    required Map<String, double> episodeCompletion,
    required Map<String, DateTime> listenHistory,
  }) {
    final totalEpisodes = allEpisodes.length;
    final finishedCount = allEpisodes
        .where((e) => _isEpisodeFinished(e.id, episodeCompletion))
        .length;
    final unfinishedCount = allEpisodes
        .where((e) => _isEpisodeUnfinished(e.id, episodeCompletion))
        .length;
    final unstartedCount = totalEpisodes - finishedCount - unfinishedCount;

    // Calculate total listening time estimate
    final totalDuration = allEpisodes.fold<Duration>(
      Duration.zero,
      (sum, episode) => sum + (episode.duration ?? Duration.zero),
    );

    final finishedDuration = allEpisodes
        .where((e) => _isEpisodeFinished(e.id, episodeCompletion))
        .fold<Duration>(
          Duration.zero,
          (sum, episode) => sum + (episode.duration ?? Duration.zero),
        );

    // Average completion for unfinished episodes
    final unfinishedEpisodes =
        allEpisodes.where((e) => _isEpisodeUnfinished(e.id, episodeCompletion));

    final double avgUnfinishedCompletion;
    if (unfinishedEpisodes.isEmpty) {
      avgUnfinishedCompletion = 0.0;
    } else {
      final totalCompletion = unfinishedEpisodes
          .map((e) => episodeCompletion[e.id] ?? 0.0)
          .reduce((a, b) => a + b);
      avgUnfinishedCompletion = totalCompletion / unfinishedEpisodes.length;
    }

    return {
      'totalEpisodes': totalEpisodes,
      'finishedCount': finishedCount,
      'unfinishedCount': unfinishedCount,
      'unstartedCount': unstartedCount,
      'completionRate': totalEpisodes > 0 ? finishedCount / totalEpisodes : 0.0,
      'totalDuration': totalDuration,
      'finishedDuration': finishedDuration,
      'averageUnfinishedCompletion': avgUnfinishedCompletion,
      'listenHistorySize': listenHistory.length,
      'currentStreak': _calculateListeningStreak(listenHistory),
      'favoriteDayOfWeek': _calculateFavoriteDayOfWeek(listenHistory),
      'averageSessionLength': _calculateAverageSessionLength(episodeCompletion),
    };
  }

  static bool _isEpisodeFinished(
      String episodeId, Map<String, double> completion) {
    return (completion[episodeId] ?? 0.0) >= 0.9;
  }

  static bool _isEpisodeUnfinished(
      String episodeId, Map<String, double> completion) {
    final val = completion[episodeId] ?? 0.0;
    return val > 0.0 && val < 0.9;
  }

  /// Calculate current listening streak (consecutive days)
  static int _calculateListeningStreak(Map<String, DateTime> listenHistory) {
    if (listenHistory.isEmpty) return 0;

    final sortedDates = listenHistory.values
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
        // Allow missing ONE day (today) if we listened yesterday
        if (i == 0 &&
            sortedDates[i] == todayDate.subtract(const Duration(days: 1))) {
          // Shift expected date logic?
          // Implementation in original code was strictly checking today, yesterday, etc.
          // If we haven't listened today yet, but listened yesterday, streak should be active?
          // Original logic:
          // todayDate - 0 days = today. If not found, break.
          // So if user hasn't listened TODAY, streak is 0? That seems strict.
          // But I will stick to the original logic for now to avoid logic changes.
          break;
        }
        break;
      }
    }

    return streak;
  }

  /// Calculate favorite day of the week for listening
  static String _calculateFavoriteDayOfWeek(
      Map<String, DateTime> listenHistory) {
    if (listenHistory.isEmpty) return 'Unknown';

    final dayCount = <int, int>{};
    for (final date in listenHistory.values) {
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
  static Duration _calculateAverageSessionLength(
      Map<String, double> episodeCompletion) {
    if (episodeCompletion.isEmpty) return Duration.zero;

    final totalCompletionMinutes = episodeCompletion.values.fold<double>(
        0.0,
        (sum, completion) =>
            sum + completion * 30); // Assume 30 min average episode

    final avgMinutes = totalCompletionMinutes / episodeCompletion.length;
    return Duration(minutes: avgMinutes.round());
  }
}
