import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/audio_file.dart';

/// Service for interacting with the Cloudflare R2 streaming API
/// Handles episode discovery and streaming URL generation
class StreamingApiService {
  final Dio _dio;

  StreamingApiService(this._dio);

  /// Get list of episodes for a specific language and category
  /// Returns list of AudioFile objects with streaming URLs
  Future<List<AudioFile>> getEpisodeList(
      String language, String category) async {
    // Validate input parameters
    if (!ApiConfig.isValidLanguage(language)) {
      throw ArgumentError('Unsupported language: $language');
    }
    if (!ApiConfig.isValidCategory(category)) {
      throw ArgumentError('Unsupported category: $category');
    }

    final path = '/';
    final queryParameters = {'prefix': 'audio/$language/$category/'};

    if (kDebugMode) {
      print(
          'StreamingApiService: Making request to path: $path with query: $queryParameters');
    }

    try {
      final response =
          await _dio.get(path, queryParameters: queryParameters);

      return _parseEpisodesResponse(response.data, language, category);
    } on DioException catch (e) {
      _handleDioException(e);
      rethrow; // Rethrow to allow caller to handle
    } catch (e) {
      if (kDebugMode) {
        print('StreamingApiService: Unexpected error: $e');
      }
      throw UnknownException('Unexpected error: $e');
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
  Future<List<AudioFile>> getAllEpisodesForLanguage(String language) async {
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
  Future<List<AudioFile>> getAllEpisodes() async {
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

    return allEpisodes;
  }

  /// Get episodes filtered by search query
  Future<List<AudioFile>> searchEpisodes(
    String query, {
    String? language,
    String? category,
  }) async {
    // This implementation is simplified. A real-world app might have a dedicated search API endpoint.
    // For now, we fetch all relevant episodes and filter locally.
    List<AudioFile> episodesToSearch;
    if (language != null && category != null) {
      episodesToSearch = await getEpisodeList(language, category);
    } else if (language != null) {
      episodesToSearch = await getAllEpisodesForLanguage(language);
    } else {
      episodesToSearch = await getAllEpisodes();
    }
    return _filterEpisodesByQuery(episodesToSearch, query);
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

  /// Test connectivity to the streaming API
  Future<bool> testConnectivity() async {
    try {
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
  Future<bool> validateStreamingUrl(String url) async {
    try {
      final response = await _dio.head(url);
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('StreamingApiService: URL validation failed for $url: $e');
      }
      return false;
    }
  }

  /// Handles Dio exceptions and throws custom exceptions.
  Never _handleDioException(DioException e) {
    if (kDebugMode) {
      print('StreamingApiService: DioException: ${e.message}');
      print('StreamingApiService: Type: ${e.type}');
      if (e.response != null) {
        print(
            'StreamingApiService: Response: ${e.response?.statusCode} ${e.response?.statusMessage}');
      }
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw TimeoutException('Request timed out: ${e.message}');
      case DioExceptionType.badResponse:
        throw ApiException(
            'Failed to load episodes: ${e.response?.statusCode} - ${e.response?.statusMessage}',
            e.response?.statusCode);
      case DioExceptionType.cancel:
        throw NetworkException('Request was cancelled.');
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
      default:
        throw NetworkException('Network connection error: ${e.message}');
    }
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
