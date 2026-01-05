/// Utility class for duration formatting.
///
/// Provides static methods for converting [Duration] objects
/// into human-readable strings for display in the UI.
class DurationUtils {
  /// Formats a [Duration] for display as a time string.
  ///
  /// Returns a string in the format "H:MM:SS" if the duration is an hour or more,
  /// or "M:SS" for shorter durations.
  ///
  /// Example: `Duration(minutes: 5, seconds: 30)` returns "5:30".
  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '$minutes:${twoDigits(seconds)}';
    }
  }

  /// Formats a [Duration] as descriptive text.
  ///
  /// Returns a string like "1h 23m" for durations with hours,
  /// or "45m" for shorter durations.
  ///
  /// Example: `Duration(hours: 1, minutes: 23)` returns "1h 23m".
  static String formatDurationText(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}
