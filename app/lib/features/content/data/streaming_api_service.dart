import 'dart:async' as dart_async;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:from_fed_to_chain_app/core/config/api_config.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';
import 'package:from_fed_to_chain_app/core/services/logger_service.dart';
import 'package:from_fed_to_chain_app/core/exceptions/app_exceptions.dart';

/// Service for interacting with the Cloudflare R2 streaming API
/// Handles episode discovery and streaming URL generation
///
/// This service supports both static and instance-based usage:
///
/// **Static usage (backward compatible):**
/// ```dart
/// final episodes = await StreamingApiService.getEpisodeList('zh-TW', 'startup');
/// ```
///
/// **Instance usage (recommended for DI/testing):**
/// ```dart
/// final service = StreamingApiService(client: mockHttpClient);
/// final episodes = await service.fetchEpisodeList('zh-TW', 'startup');
/// ```
class StreamingApiService {
  /// Instance-based HTTP client for dependency injection
  final http.Client _client;

  /// Logger instance
  final _log = LoggerService.getLogger('StreamingApiService');

  /// Singleton instance for backward compatibility during migration
  static StreamingApiService? _instance;

  /// Static HTTP client for backward compatibility
  static http.Client? _staticClient;

  /// Default singleton instance (created lazily)
  static StreamingApiService get instance =>
      _instance ??= StreamingApiService(client: _staticClient);

  /// Create a new StreamingApiService instance.
  ///
  /// [client] - Optional HTTP client for dependency injection.
  ///            If not provided, a default http.Client is used.
  ///
  /// Example:
  /// ```dart
  /// // For production
  /// final service = StreamingApiService();
  ///
  /// // For testing with mock client
  /// final mockClient = MockClient();
  /// final service = StreamingApiService(client: mockClient);
  /// ```
  StreamingApiService({http.Client? client})
      : _client = client ?? http.Client();

  // ============================================================================
  // INSTANCE METHODS - Use these for DI-based code
  // Method names prefixed with 'fetch' to distinguish from static methods
  // ============================================================================

  /// Get list of episodes for a specific language and category (instance method)
  /// Returns list of AudioFile objects with streaming URLs
  Future<List<AudioFile>> fetchEpisodeList(
      String language, String category) async {
    // Validate input parameters
    if (!ApiConfig.isValidLanguage(language)) {
      throw ArgumentError('Unsupported language: $language');
    }
    if (!ApiConfig.isValidCategory(category)) {
      throw ArgumentError('Unsupported category: $category');
    }

    final url = Uri.parse(ApiConfig.getListUrl(language, category));

    try {
      _log.fine('Fetching episodes for $language/$category at $url');

      final response = await _client.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'User-Agent': 'FromFedToChain/1.0.0 (Flutter)',
        },
      ).timeout(ApiConfig.apiTimeout);

      _log.fine('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        return _parseEpisodesResponse(responseData, language, category);
      } else {
        throw ApiException(
            'Failed to load episodes: ${response.statusCode} - ${response.reasonPhrase}',
            statusCode: response.statusCode);
      }
    } on http.ClientException catch (e) {
      _log.warning('ClientException: ${e.message} (likely network/CORS issue)');
      throw NetworkException('Network connection error: ${e.message}',
          originalError: e);
    } on dart_async.TimeoutException catch (e) {
      _log.warning(
          'Request timed out after ${ApiConfig.apiTimeout.inSeconds}s');
      throw TimeoutException('Request timed out: ${e.message}');
    } on FormatException catch (e) {
      _log.severe('FormatException parsing response: $e');
      rethrow;
    } on StateError catch (e) {
      _log.severe('StateError: $e');
      rethrow;
    } on RangeError catch (e) {
      _log.severe('RangeError: $e');
      rethrow;
    } catch (e) {
      _log.severe('Unexpected error: $e');
      if (e is AppException) rethrow;
      throw UnknownException('Unexpected error: $e', originalError: e);
    }
  }

  /// Parse episodes response from API into AudioFile objects
  List<AudioFile> _parseEpisodesResponse(
      dynamic responseData, String language, String category) {
    List<Map<String, dynamic>> episodeData;

    // Handle both array and object responses
    if (responseData is List) {
      episodeData = responseData.cast<Map<String, dynamic>>();
    } else if (responseData is Map<String, dynamic>) {
      // If the API returns an object with episodes array
      final List<dynamic>? episodes = responseData['episodes'] ??
          responseData['data'] ??
          responseData['files'];
      if (episodes != null) {
        episodeData = episodes.cast<Map<String, dynamic>>();
      } else {
        // If the response is a single episode object
        episodeData = [responseData];
      }
    } else {
      throw FormatException(
          'Unexpected response format: ${responseData.runtimeType}');
    }

    // Convert to AudioFile objects
    final audioFiles = <AudioFile>[];
    for (final episodeJson in episodeData) {
      try {
        // Ensure required fields are present
        final path = episodeJson['path'] as String?;
        if (path == null || path.isEmpty) {
          _log.warning('Skipping episode with missing path: $episodeJson');
          continue;
        }

        // Build streaming URL
        final streamingUrl = ApiConfig.getStreamUrl(path);

        // Create enhanced episode data
        final enhancedEpisodeData = Map<String, dynamic>.from(episodeJson);
        enhancedEpisodeData['streaming_url'] = streamingUrl;
        enhancedEpisodeData['language'] = language;
        enhancedEpisodeData['category'] = category;

        // Create AudioFile object
        final audioFile = AudioFile.fromApiResponse(enhancedEpisodeData);
        audioFiles.add(audioFile);

        if (audioFiles.length == 1) {
          _log.finer('Sample AudioFile created: ${audioFile.toString()}');
        }
      } catch (e) {
        _log.warning('Failed to parse episode: $episodeJson, error: $e');
      }
    }

    _log.info('Parsed ${audioFiles.length} episodes for $language/$category');

    return audioFiles;
  }

  /// Get all episodes for a specific language across all categories (instance method)
  Future<List<AudioFile>> fetchAllEpisodesForLanguage(String language) async {
    if (!ApiConfig.isValidLanguage(language)) {
      throw ArgumentError('Unsupported language: $language');
    }

    final allEpisodes = <AudioFile>[];
    final errors = <String>[];

    // Load episodes from all categories in parallel
    final futures = ApiConfig.supportedCategories.map((category) async {
      try {
        final episodes = await fetchEpisodeList(language, category);
        return episodes;
      } catch (e) {
        errors.add('$category: $e');
        return <AudioFile>[];
      }
    });

    final results = await Future.wait(futures);

    // Flatten results
    for (final episodeList in results) {
      allEpisodes.addAll(episodeList);
    }

    if (errors.isNotEmpty) {
      _log.warning(
          'Some categories failed for $language: ${errors.join(', ')}');
    }

    // Sort by date (newest first)
    allEpisodes.sort((a, b) => b.lastModified.compareTo(a.lastModified));

    return allEpisodes;
  }

  /// Get all episodes across all languages and categories (instance method)
  Future<List<AudioFile>> fetchAllEpisodes() async {
    _log.info('Starting parallel loading of all episodes...');

    final allEpisodes = <AudioFile>[];
    final errors = <String>[];

    // Create all API calls upfront for parallel execution
    final futures = <Future<List<AudioFile>>>[];

    for (final language in ApiConfig.supportedLanguages) {
      for (final category in ApiConfig.supportedCategories) {
        final future = fetchEpisodeList(language, category).catchError((error) {
          errors.add('$language/$category: $error');
          return <AudioFile>[];
        });
        futures.add(future);
      }
    }

    _log.fine('Created ${futures.length} parallel requests');

    // Wait for all requests to complete (parallel execution)
    final results = await Future.wait(futures);

    // Flatten results
    for (final episodeList in results) {
      allEpisodes.addAll(episodeList);
    }

    if (errors.isNotEmpty) {
      _log.warning('Some requests failed: ${errors.join(', ')}');
    }

    // Sort by date (newest first)
    allEpisodes.sort((a, b) => b.lastModified.compareTo(a.lastModified));

    _log.info(
        'Parallel loading completed, got ${allEpisodes.length} total episodes');
    return allEpisodes;
  }

  /// Get episodes filtered by search query (instance method)
  Future<List<AudioFile>> fetchSearchEpisodes(
    String query, {
    String? language,
    String? category,
  }) async {
    // If language and category specified, search within that subset
    if (language != null && category != null) {
      final episodes = await fetchEpisodeList(language, category);
      return _filterEpisodesByQuery(episodes, query);
    }

    // If only language specified, search within that language
    if (language != null) {
      final episodes = await fetchAllEpisodesForLanguage(language);
      return _filterEpisodesByQuery(episodes, query);
    }

    // Search across all episodes
    final episodes = await fetchAllEpisodes();
    return _filterEpisodesByQuery(episodes, query);
  }

  /// Filter episodes by search query
  List<AudioFile> _filterEpisodesByQuery(
      List<AudioFile> episodes, String query) {
    if (query.trim().isEmpty) return episodes;

    final lowerQuery = query.toLowerCase();
    return episodes.where((episode) {
      return episode.title.toLowerCase().contains(lowerQuery) ||
          episode.id.toLowerCase().contains(lowerQuery) ||
          episode.category.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Test connectivity to the streaming API (instance method)
  Future<bool> checkConnectivity() async {
    try {
      // Try to get episodes for a common language/category combination
      final episodes = await fetchEpisodeList('zh-TW', 'startup');
      return episodes.isNotEmpty;
    } catch (e) {
      _log.severe('API connectivity test failed: $e');
      return false;
    }
  }

  /// Get API status information (instance method)
  Map<String, dynamic> fetchApiStatus() {
    return {
      'baseUrl': ApiConfig.streamingBaseUrl,
      'environment': ApiConfig.currentEnvironment,
      'isProduction': ApiConfig.isProduction,
      'supportedLanguages': ApiConfig.supportedLanguages,
      'supportedCategories': ApiConfig.supportedCategories,
      'apiTimeout': ApiConfig.apiTimeout.inSeconds,
      'streamTimeout': ApiConfig.streamTimeout.inSeconds,
    };
  }

  /// Validate streaming URL accessibility (instance method)
  Future<bool> checkStreamingUrl(String url) async {
    try {
      final response = await _client
          .head(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      _log.warning('URL validation failed for $url: $e');
      return false;
    }
  }

  /// Clean up HTTP client resources (instance method)
  void close() {
    _client.close();
  }

  // ============================================================================
  // STATIC METHODS - For backward compatibility with existing code
  // These delegate to the singleton instance
  // ============================================================================

  /// Set HTTP client for dependency injection (mainly for testing)
  /// This also updates the singleton instance to use the new client.
  static void setHttpClient(http.Client? client) {
    _staticClient?.close();
    _staticClient = client;
    // Update singleton to use the new client
    if (client != null) {
      _instance?.close();
      _instance = StreamingApiService(client: client);
    } else {
      _instance = null;
    }
  }

  /// Get current HTTP client instance (mainly for testing)
  static http.Client get httpClient => _staticClient ??= http.Client();

  /// Get list of episodes for a specific language and category
  static Future<List<AudioFile>> getEpisodeList(
      String language, String category) async {
    return instance.fetchEpisodeList(language, category);
  }

  /// Get all episodes for a specific language across all categories
  static Future<List<AudioFile>> getAllEpisodesForLanguage(
      String language) async {
    return instance.fetchAllEpisodesForLanguage(language);
  }

  /// Get all episodes across all languages and categories (parallel loading)
  static Future<List<AudioFile>> getAllEpisodes() async {
    return instance.fetchAllEpisodes();
  }

  /// Get episodes filtered by search query
  static Future<List<AudioFile>> searchEpisodes(
    String query, {
    String? language,
    String? category,
  }) async {
    return instance.fetchSearchEpisodes(query,
        language: language, category: category);
  }

  /// Test connectivity to the streaming API
  static Future<bool> testConnectivity() async {
    return instance.checkConnectivity();
  }

  /// Get API status information
  static Map<String, dynamic> getApiStatus() {
    return instance.fetchApiStatus();
  }

  /// Validate streaming URL accessibility
  static Future<bool> validateStreamingUrl(String url) async {
    return instance.checkStreamingUrl(url);
  }

  /// Clean up HTTP client resources
  static void dispose() {
    _staticClient?.close();
    _staticClient = null;
    _instance?.close();
    _instance = null;
  }

  /// Reset singleton instance (mainly for testing)
  static void resetInstance() {
    _instance?.close();
    _instance = null;
    _staticClient?.close();
    _staticClient = null;
  }
}
