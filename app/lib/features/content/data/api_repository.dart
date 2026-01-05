import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:from_fed_to_chain_app/core/config/api_config.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_content.dart';
import 'package:from_fed_to_chain_app/core/services/logger_service.dart';
import 'package:from_fed_to_chain_app/features/content/data/interceptors/interceptors.dart';

/// Centralized repository for all HTTP API operations
/// Provides consistent error handling, retry logic, and request management
class ApiRepository {
  static ApiRepository? _instance;
  static final _log = LoggerService.getLogger('ApiRepository');
  static ApiRepository get instance => _instance ??= ApiRepository._internal();

  late Dio _dio;
  final Map<String, CancelToken> _activeCalls = {};

  ApiRepository._internal() {
    _initializeDio();
  }

  /// Initialize Dio with default configuration
  void _initializeDio() {
    _dio = Dio(BaseOptions(
      connectTimeout: ApiConfig.apiTimeout,
      receiveTimeout: ApiConfig.apiTimeout,
      sendTimeout: ApiConfig.apiTimeout,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'User-Agent': 'FromFedToChain/1.0.0 (Flutter)',
      },
    ));

    // Add interceptors for logging and error handling
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (object) => _log.fine(object.toString()),
    ));

    // Add retry interceptor
    _dio.interceptors.add(RetryInterceptor());

    // Add error handling interceptor
    _dio.interceptors.add(ErrorHandlingInterceptor());
  }

  /// Get all episodes across all languages and categories
  Future<List<AudioFile>> getAllEpisodes() async {
    const callId = 'getAllEpisodes';

    try {
      _cancelPreviousCall(callId);
      final cancelToken = CancelToken();
      _activeCalls[callId] = cancelToken;

      _log.info('Fetching all episodes...');

      final allEpisodes = <AudioFile>[];
      final errors = <String>[];

      // Get episodes from all language/category combinations
      for (final language in ApiConfig.supportedLanguages) {
        for (final category in ApiConfig.supportedCategories) {
          try {
            final episodes =
                await getEpisodesForLanguageAndCategory(language, category);
            allEpisodes.addAll(episodes);
          } catch (e) {
            errors.add('$language/$category: $e');
          }
        }
      }

      if (errors.isNotEmpty) {
        _log.warning('Some requests failed: ${errors.join(', ')}');
      }

      // Sort by date (newest first)
      allEpisodes.sort((a, b) => b.lastModified.compareTo(a.lastModified));

      _log.info('Successfully fetched ${allEpisodes.length} episodes');

      return allEpisodes;
    } catch (e) {
      _log.severe('Failed to fetch all episodes: $e');
      rethrow;
    } finally {
      _activeCalls.remove(callId);
    }
  }

  /// Get episodes for a specific language across all categories
  Future<List<AudioFile>> getEpisodesForLanguage(String language) async {
    final callId = 'getEpisodesForLanguage_$language';

    try {
      _cancelPreviousCall(callId);

      _log.info('Fetching episodes for language: $language');

      final allEpisodes = <AudioFile>[];
      final errors = <String>[];

      // Get episodes from all categories for this language
      for (final category in ApiConfig.supportedCategories) {
        try {
          final episodes =
              await getEpisodesForLanguageAndCategory(language, category);
          allEpisodes.addAll(episodes);
        } catch (e) {
          errors.add('$category: $e');
        }
      }

      if (errors.isNotEmpty) {
        _log.warning(
            'Some categories failed for $language: ${errors.join(', ')}');
      }

      // Sort by date (newest first)
      allEpisodes.sort((a, b) => b.lastModified.compareTo(a.lastModified));

      _log.info(
          'Successfully fetched ${allEpisodes.length} episodes for $language');

      return allEpisodes;
    } catch (e) {
      _log.severe('Failed to fetch episodes for $language: $e');
      rethrow;
    } finally {
      _activeCalls.remove(callId);
    }
  }

  /// Get episodes for a specific language and category
  Future<List<AudioFile>> getEpisodesForLanguageAndCategory(
      String language, String category) async {
    final callId = 'getEpisodes_${language}_$category';

    try {
      _cancelPreviousCall(callId);
      final cancelToken = CancelToken();
      _activeCalls[callId] = cancelToken;

      _log.info('Fetching episodes for $language/$category');

      final response = await _dio.get(
        ApiConfig.getListUrl(language, category),
        cancelToken: cancelToken,
      );

      final audioFiles = <AudioFile>[];
      if (response.data is List) {
        for (final item in response.data) {
          if (item is Map<String, dynamic>) {
            try {
              // Ensure required fields
              final path = item['path'] as String?;
              if (path == null || path.isEmpty) continue;

              // Build streaming URL and add metadata
              final enhancedItem = Map<String, dynamic>.from(item);
              enhancedItem['streaming_url'] = ApiConfig.getStreamUrl(path);
              enhancedItem['language'] = language;
              enhancedItem['category'] = category;

              audioFiles.add(AudioFile.fromApiResponse(enhancedItem));
            } catch (e) {
              _log.warning('Failed to parse episode: $e');
            }
          }
        }
      }

      _log.info(
          'Successfully fetched ${audioFiles.length} episodes for $language/$category');

      return audioFiles;
    } catch (e) {
      _log.severe('Failed to fetch episodes for $language/$category: $e');
      rethrow;
    } finally {
      _activeCalls.remove(callId);
    }
  }

  /// Search episodes by query (client-side filtering)
  Future<List<AudioFile>> searchEpisodes(String query) async {
    _log.info('Searching episodes for: $query');

    // Get all episodes and filter them client-side
    final allEpisodes = await getAllEpisodes();

    if (query.trim().isEmpty) return allEpisodes;

    final lowerQuery = query.toLowerCase();
    final filteredEpisodes = allEpisodes.where((episode) {
      return episode.title.toLowerCase().contains(lowerQuery) ||
          episode.id.toLowerCase().contains(lowerQuery) ||
          episode.category.toLowerCase().contains(lowerQuery);
    }).toList();

    _log.info('Found ${filteredEpisodes.length} episodes for query: $query');

    return filteredEpisodes;
  }

  /// Fetch content by ID, language, and category
  Future<AudioContent?> fetchContent(
      String id, String language, String category) async {
    final callId = 'fetchContent_${id}_${language}_$category';

    try {
      _cancelPreviousCall(callId);
      final cancelToken = CancelToken();
      _activeCalls[callId] = cancelToken;

      _log.info('Fetching content for $language/$category/$id');

      final response = await _dio.get(
        ApiConfig.getContentUrl(language, category, id),
        cancelToken: cancelToken,
      );

      if (response.statusCode == 200 && response.data != null) {
        final content = AudioContent.fromJson(response.data);

        if (kDebugMode) {
          print('ApiRepository: Successfully fetched content for $id');
        }

        return content;
      } else {
        if (kDebugMode) {
          print(
              'ApiRepository: Content not found for $id (HTTP ${response.statusCode})');
        }
        return null;
      }
    } catch (e) {
      _log.severe('Failed to fetch content for $id: $e');
      return null;
    } finally {
      _activeCalls.remove(callId);
    }
  }

  /// Cancel a specific API call
  void cancelCall(String callId) {
    final cancelToken = _activeCalls[callId];
    if (cancelToken != null && !cancelToken.isCancelled) {
      cancelToken.cancel('Cancelled by user');
      _activeCalls.remove(callId);

      _log.info('Cancelled call: $callId');
    }
  }

  /// Cancel all active API calls
  void cancelAllCalls() {
    for (final entry in _activeCalls.entries) {
      if (!entry.value.isCancelled) {
        entry.value.cancel('Cancelled all calls');
      }
    }
    _activeCalls.clear();

    _log.info('Cancelled all active calls');
  }

  /// Cancel previous call with the same ID
  void _cancelPreviousCall(String callId) {
    final existingToken = _activeCalls[callId];
    if (existingToken != null && !existingToken.isCancelled) {
      existingToken.cancel('Superseded by new call');
    }
  }

  /// Get API statistics
  Map<String, dynamic> getApiStatistics() {
    return {
      'activeCalls': _activeCalls.length,
      'activeCallIds': _activeCalls.keys.toList(),
      'dioConfig': {
        'connectTimeout': _dio.options.connectTimeout?.inMilliseconds,
        'receiveTimeout': _dio.options.receiveTimeout?.inMilliseconds,
        'baseUrl': _dio.options.baseUrl,
      },
    };
  }

  /// Dispose of resources
  void dispose() {
    cancelAllCalls();
    _dio.close();

    _log.info('Disposed');
  }

  /// Reset instance (for testing)
  static void reset() {
    _instance?.dispose();
    _instance = null;
  }

  /// Set custom Dio instance (for testing)
  void setDioForTesting(Dio dio) {
    _dio.close();
    _dio = dio;
  }
}
