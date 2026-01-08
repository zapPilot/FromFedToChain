import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';

/// Use case for filtering episodes based on various criteria.
///
/// This is a pure function class that takes episodes and filter parameters,
/// returning filtered and sorted results. It has no state and no dependencies
/// on ChangeNotifier, making it highly testable.
///
/// Example:
/// ```dart
/// final useCase = FilterEpisodesUseCase();
/// final filtered = useCase(
///   episodes: allEpisodes,
///   language: 'zh-TW',
///   category: 'startup',
///   searchQuery: 'bitcoin',
///   sortOrder: 'newest',
/// );
/// ```
class FilterEpisodesUseCase {
  /// Filter and sort episodes based on the provided criteria.
  ///
  /// [episodes] - The complete list of episodes to filter
  /// [language] - Language filter (e.g., 'zh-TW', 'en-US', 'all')
  /// [category] - Category filter (e.g., 'startup', 'daily-news', 'all')
  /// [searchQuery] - Text to search for in title, id, and category
  /// [sortOrder] - Sort order: 'newest', 'oldest', or 'alphabetical'
  ///
  /// Returns a new filtered and sorted list (does not modify input).
  List<AudioFile> call({
    required List<AudioFile> episodes,
    String language = 'all',
    String category = 'all',
    String searchQuery = '',
    String sortOrder = 'newest',
  }) {
    var filtered = List<AudioFile>.from(episodes);

    // Apply language filter
    if (language != 'all') {
      filtered = _filterByLanguage(filtered, language);
    }

    // Apply category filter
    if (category != 'all') {
      filtered = _filterByCategory(filtered, category);
    }

    // Apply search query filter
    if (searchQuery.trim().isNotEmpty) {
      filtered = _filterBySearchQuery(filtered, searchQuery);
    }

    // Apply sorting
    filtered = _applySorting(filtered, sortOrder);

    return filtered;
  }

  /// Filter episodes by language.
  List<AudioFile> filterByLanguage(List<AudioFile> episodes, String language) {
    if (language == 'all') return List.from(episodes);
    return _filterByLanguage(episodes, language);
  }

  /// Filter episodes by category.
  List<AudioFile> filterByCategory(List<AudioFile> episodes, String category) {
    if (category == 'all') return List.from(episodes);
    return _filterByCategory(episodes, category);
  }

  /// Filter episodes by search query (case-insensitive).
  List<AudioFile> filterBySearchQuery(List<AudioFile> episodes, String query) {
    return _filterBySearchQuery(episodes, query);
  }

  /// Sort episodes by the specified order.
  List<AudioFile> sortEpisodes(List<AudioFile> episodes, String sortOrder) {
    return _applySorting(List.from(episodes), sortOrder);
  }

  // Private helper methods

  List<AudioFile> _filterByLanguage(List<AudioFile> episodes, String language) {
    return episodes.where((episode) => episode.language == language).toList();
  }

  List<AudioFile> _filterByCategory(List<AudioFile> episodes, String category) {
    return episodes.where((episode) => episode.category == category).toList();
  }

  List<AudioFile> _filterBySearchQuery(List<AudioFile> episodes, String query) {
    if (query.trim().isEmpty) return episodes;

    final lowerQuery = query.toLowerCase();
    return episodes.where((episode) {
      return episode.title.toLowerCase().contains(lowerQuery) ||
          episode.id.toLowerCase().contains(lowerQuery) ||
          episode.category.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  List<AudioFile> _applySorting(List<AudioFile> episodes, String sortOrder) {
    final sorted = List<AudioFile>.from(episodes);

    switch (sortOrder) {
      case 'oldest':
        sorted.sort((a, b) => a.publishDate.compareTo(b.publishDate));
        break;
      case 'alphabetical':
        sorted.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case 'newest':
      default:
        sorted.sort((a, b) => b.publishDate.compareTo(a.publishDate));
        break;
    }

    return sorted;
  }

  /// Advanced filtering with multiple criteria including date ranges and duration.
  List<AudioFile> advancedFilter(
    List<AudioFile> episodes, {
    String? query,
    List<String>? languages,
    List<String>? categories,
    DateTime? dateFrom,
    DateTime? dateTo,
    Duration? minDuration,
    Duration? maxDuration,
    String sortOrder = 'newest',
  }) {
    var results = List<AudioFile>.from(episodes);

    if (query != null && query.trim().isNotEmpty) {
      results = _filterBySearchQuery(results, query);
    }

    if (languages != null && languages.isNotEmpty) {
      results = results
          .where((episode) => languages.contains(episode.language))
          .toList();
    }

    if (categories != null && categories.isNotEmpty) {
      results = results
          .where((episode) => categories.contains(episode.category))
          .toList();
    }

    if (dateFrom != null) {
      results = results
          .where((episode) =>
              episode.publishDate.isAfter(dateFrom) ||
              episode.publishDate.isAtSameMomentAs(dateFrom))
          .toList();
    }
    if (dateTo != null) {
      results = results
          .where((episode) =>
              episode.publishDate.isBefore(dateTo.add(const Duration(days: 1))))
          .toList();
    }

    if (minDuration != null) {
      results = results
          .where((episode) =>
              episode.duration != null && episode.duration! >= minDuration)
          .toList();
    }
    if (maxDuration != null) {
      results = results
          .where((episode) =>
              episode.duration != null && episode.duration! <= maxDuration)
          .toList();
    }

    results = _applySorting(results, sortOrder);

    return results;
  }
}
