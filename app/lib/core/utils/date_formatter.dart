import 'package:intl/intl.dart';

/// Utility class for friendly date formatting
class DateFormatter {
  /// Format date for display with localization (e.g. "Today", "Yesterday", "2 days ago")
  static String formatFriendlyDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else {
      // Use localized date format for older dates (without time)
      return DateFormat.yMMMd().format(date);
    }
  }
}
