import 'package:from_fed_to_chain_app/features/content/data/streaming_api_service.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';

/// Use case for searching episodes with caching.
///
/// This use case implements a local-first search strategy:
/// 1. First searches within the provided local episodes
/// 2. Falls back to API search if no local results found
///
/// Example:
/// ```dart
/// final useCase = SearchEpisodesUseCase(apiService);
/// final results = await useCase(
///   query: 'bitcoin',
///   localEpisodes: allEpisodes,
/// );
/// ```
class SearchEpisodesUseCase {
  final StreamingApiService _apiService;

  /// Search result cache (query -> results)
  final Map<String, List<AudioFile>> _cache = {};

  /// Maximum number of cached queries
  final int maxCacheSize;

  /// Create a SearchEpisodesUseCase with the given API service.
  ///
  /// [apiService] - The streaming API service for remote search
  /// [maxCacheSize] - Maximum number of search queries to cache (default: 20)
  SearchEpisodesUseCase(this._apiService, {this.maxCacheSize = 20});

  /// Search for episodes matching the query.
  ///
  /// [query] - The search query string
  /// [localEpisodes] - Local episodes to search first
  /// [useCache] - Whether to use cached results (default: true)
  ///
  /// Returns a list of matching episodes.
  Future<List<AudioFile>> call({
    required String query,
    required List<AudioFile> localEpisodes,
    bool useCache = true,
  }) async {
    if (query.trim().isEmpty) {
      return localEpisodes;
    }

    final cacheKey = query.toLowerCase().trim();

    // Check cache first
    if (useCache && _cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    // Search locally first
    final localResults = filterByQuery(localEpisodes, query);

    if (localResults.isNotEmpty) {
      _cacheResult(cacheKey, localResults);
      return localResults;
    }

    // Fall back to API search
    try {
      final apiResults = await _apiService.fetchSearchEpisodes(query);
      _cacheResult(cacheKey, apiResults);
      return apiResults;
    } catch (e) {
      // On API failure, return empty results
      return [];
    }
  }

  /// Filter episodes by search query (pure function).
  ///
  /// Searches in title, id, and category fields (case-insensitive).
  List<AudioFile> filterByQuery(List<AudioFile> episodes, String query) {
    if (query.trim().isEmpty) return episodes;

    final lowerQuery = query.toLowerCase();
    return episodes.where((episode) {
      return episode.title.toLowerCase().contains(lowerQuery) ||
          episode.id.toLowerCase().contains(lowerQuery) ||
          episode.category.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Clear the search cache.
  void clearCache() {
    _cache.clear();
  }

  /// Get the current cache size.
  int get cacheSize => _cache.length;

  void _cacheResult(String cacheKey, List<AudioFile> results) {
    // Evict oldest entry if cache is full
    if (_cache.length >= maxCacheSize) {
      final firstKey = _cache.keys.first;
      _cache.remove(firstKey);
    }
    _cache[cacheKey] = results;
  }
}
