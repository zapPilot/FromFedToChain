import 'dart:async' as dart_async;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:from_fed_to_chain_app/core/config/api_config.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';

/// Service for interacting with the Cloudflare R2 streaming API
/// Handles episode discovery and streaming URL generation
class StreamingApiService {
  static http.Client? _staticClient;
  static http.Client get _client => _staticClient ??= http.Client();

  /// Set HTTP client for dependency injection (mainly for testing)
  static void setHttpClient(http.Client? client) {
    _staticClient?.close();
    _staticClient = client;
  }

  /// Get current HTTP client instance (mainly for testing)
  static http.Client get httpClient => _client;

  /// Get list of episodes for a specific language and category
  /// Returns list of AudioFile objects with streaming URLs
  static Future<List<AudioFile>> getEpisodeList(
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
      final response = await _client.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'User-Agent': 'FromFedToChain/1.0.0 (Flutter)',
        },
      ).timeout(ApiConfig.apiTimeout);

      if (kDebugMode) {
        print('StreamingApiService: Response status: ${response.statusCode}');
        print('StreamingApiService: Response headers: ${response.headers}');
      }

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        return _parseEpisodesResponse(responseData, language, category);
      } else {
        throw ApiException(
            'Failed to load episodes: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } on http.ClientException catch (e) {
      if (kDebugMode) {
        print('StreamingApiService: ClientException: ${e.message}');
        print(
            'StreamingApiService: This usually indicates CORS or network issues');
      }
      throw NetworkException('Network connection error: ${e.message}');
    } on dart_async.TimeoutException catch (e) {
      if (kDebugMode) {
        print(
            'StreamingApiService: Request timed out after ${ApiConfig.apiTimeout.inSeconds} seconds');
      }
      throw TimeoutException('Request timed out: ${e.message}');
    } on FormatException catch (e) {
      // Let FormatException pass through for JSON parsing errors
      if (kDebugMode) {
        print('StreamingApiService: FormatException: $e');
      }
      rethrow;
    } on StateError catch (e) {
      // Let StateError pass through for collection operations (.first, .single on empty)
      if (kDebugMode) {
        print('StreamingApiService: StateError: $e');
      }
      rethrow;
    } on RangeError catch (e) {
      // Let RangeError pass through for string manipulation issues
      if (kDebugMode) {
        print('StreamingApiService: RangeError: $e');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('StreamingApiService: Unexpected error: $e');
        print('StreamingApiService: Error type: ${e.runtimeType}');
      }
      if (e is StreamingApiException) rethrow;
      throw UnknownException('Unexpected error: $e');
    }
  }

  /// Parse episodes response from API into AudioFile objects
  static List<AudioFile> _parseEpisodesResponse(
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
          if (kDebugMode) {
            print('Warning: Skipping episode with missing path: $episodeJson');
          }
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

        if (kDebugMode && audioFiles.length == 1) {
          print(
              'StreamingApiService: Sample AudioFile created: ${audioFile.toString()}');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Warning: Failed to parse episode: $episodeJson, error: $e');
        }
      }
    }

    if (kDebugMode) {
      print(
          'StreamingApiService: Parsed ${audioFiles.length} episodes for $language/$category');
    }

    return audioFiles;
  }

  /// Get all episodes for a specific language across all categories
  static Future<List<AudioFile>> getAllEpisodesForLanguage(
      String language) async {
    if (!ApiConfig.isValidLanguage(language)) {
      throw ArgumentError('Unsupported language: $language');
    }

    final allEpisodes = <AudioFile>[];
    final errors = <String>[];

    // Load episodes from all categories in parallel
    final futures = ApiConfig.supportedCategories.map((category) async {
      try {
        final episodes = await getEpisodeList(language, category);
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

    if (errors.isNotEmpty && kDebugMode) {
      print(
          'StreamingApiService: Some categories failed for $language: ${errors.join(', ')}');
    }

    // Sort by date (newest first)
    allEpisodes.sort((a, b) => b.lastModified.compareTo(a.lastModified));

    return allEpisodes;
  }

  /// Get all episodes across all languages and categories (parallel loading)
  static Future<List<AudioFile>> getAllEpisodes() async {
    if (kDebugMode) {
      print(
          'StreamingApiService: Starting parallel loading of all episodes...');
    }

    final allEpisodes = <AudioFile>[];
    final errors = <String>[];

    // Create all API calls upfront for parallel execution
    final futures = <Future<List<AudioFile>>>[];

    for (final language in ApiConfig.supportedLanguages) {
      for (final category in ApiConfig.supportedCategories) {
        final future = getEpisodeList(language, category).catchError((error) {
          errors.add('$language/$category: $error');
          return <AudioFile>[];
        });
        futures.add(future);
      }
    }

    if (kDebugMode) {
      print('StreamingApiService: Created ${futures.length} parallel requests');
    }

    // Wait for all requests to complete (parallel execution)
    final results = await Future.wait(futures);

    // Flatten results
    for (final episodeList in results) {
      allEpisodes.addAll(episodeList);
    }

    if (errors.isNotEmpty && kDebugMode) {
      print('StreamingApiService: Some requests failed: ${errors.join(', ')}');
    }

    // Sort by date (newest first)
    allEpisodes.sort((a, b) => b.lastModified.compareTo(a.lastModified));

    if (kDebugMode) {
      print(
          'StreamingApiService: Parallel loading completed, got ${allEpisodes.length} total episodes');
    }
    return allEpisodes;
  }

  /// Get episodes filtered by search query
  static Future<List<AudioFile>> searchEpisodes(
    String query, {
    String? language,
    String? category,
  }) async {
    // If language and category specified, search within that subset
    if (language != null && category != null) {
      final episodes = await getEpisodeList(language, category);
      return _filterEpisodesByQuery(episodes, query);
    }

    // If only language specified, search within that language
    if (language != null) {
      final episodes = await getAllEpisodesForLanguage(language);
      return _filterEpisodesByQuery(episodes, query);
    }

    // Search across all episodes
    final episodes = await getAllEpisodes();
    return _filterEpisodesByQuery(episodes, query);
  }

  /// Filter episodes by search query
  static List<AudioFile> _filterEpisodesByQuery(
      List<AudioFile> episodes, String query) {
    if (query.trim().isEmpty) return episodes;

    final lowerQuery = query.toLowerCase();
    return episodes.where((episode) {
      return episode.title.toLowerCase().contains(lowerQuery) ||
          episode.id.toLowerCase().contains(lowerQuery) ||
          episode.category.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Test connectivity to the streaming API
  static Future<bool> testConnectivity() async {
    try {
      // Try to get episodes for a common language/category combination
      final episodes = await getEpisodeList('zh-TW', 'startup');
      return episodes.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('API connectivity test failed: $e');
      }
      return false;
    }
  }

  /// Get API status information
  static Map<String, dynamic> getApiStatus() {
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

  /// Validate streaming URL accessibility
  static Future<bool> validateStreamingUrl(String url) async {
    try {
      final response = await _client
          .head(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('StreamingApiService: URL validation failed for $url: $e');
      }
      return false;
    }
  }

  /// Clean up HTTP client resources
  static void dispose() {
    _staticClient?.close();
    _staticClient = null;
  }
}

/// Base exception class for streaming API errors
abstract class StreamingApiException implements Exception {
  final String message;
  const StreamingApiException(this.message);

  @override
  String toString() => 'StreamingApiException: $message';
}

/// Network-related errors (connectivity, timeouts, etc.)
class NetworkException extends StreamingApiException {
  const NetworkException(super.message);

  @override
  String toString() => 'NetworkException: $message';
}

/// API-related errors (HTTP status codes, invalid responses)
class ApiException extends StreamingApiException {
  final int? statusCode;
  const ApiException(super.message, [this.statusCode]);

  @override
  String toString() =>
      'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

/// Timeout-specific errors
class TimeoutException extends StreamingApiException {
  const TimeoutException(super.message);

  @override
  String toString() => 'TimeoutException: $message';
}

/// Unknown or unexpected errors
class UnknownException extends StreamingApiException {
  const UnknownException(super.message);

  @override
  String toString() => 'UnknownException: $message';
}
