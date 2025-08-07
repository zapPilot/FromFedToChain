import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/audio_content.dart';
import '../models/audio_file.dart';
import '../services/streaming_api_service.dart'; // For exception types

class ContentRepository {
  final Dio _dio;
  final Map<String, AudioContent> _contentCache = {};

  ContentRepository(this._dio);

  /// Fetches content/script for a specific episode from the API.
  /// Provides the actual content text for language learning.
  Future<AudioContent?> fetchContentById(
      String id, String language, String category) async {
    final cacheKey = '$language/$category/$id';

    if (_contentCache.containsKey(cacheKey)) {
      if (kDebugMode) {
        print('ContentRepository: Returning cached content for $cacheKey');
      }
      return _contentCache[cacheKey];
    }

    try {
      final path = '/api/content/$language/$category/$id';
      if (kDebugMode) {
        print('ContentRepository: Fetching content from $path');
      }

      final response = await _dio.get(path);
      final content = AudioContent.fromJson(response.data);
      _contentCache[cacheKey] = content;

      if (kDebugMode) {
        print('ContentRepository: Successfully fetched and cached content for $cacheKey');
      }
      return content;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('ContentRepository: Failed to fetch content for $cacheKey: $e');
      }
      // We don't rethrow here, just return null for content fetching failures
      // as it's not a critical failure for the app to function.
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('ContentRepository: Unexpected error fetching content for $cacheKey: $e');
      }
      return null;
    }
  }

  /// Gets cached content without making a network request.
  AudioContent? getCachedContent(String id, String language, String category) {
    final cacheKey = '$language/$category/$id';
    return _contentCache[cacheKey];
  }

  /// Pre-fetches content for a list of audio files to populate the cache.
  Future<void> prefetchContent(List<AudioFile> audioFiles) async {
    if (audioFiles.isEmpty) return;

    if (kDebugMode) {
      print('ContentRepository: Pre-fetching content for ${audioFiles.length} episodes');
    }

    final futures = audioFiles.map((file) =>
        fetchContentById(file.id, file.language, file.category));

    try {
      await Future.wait(futures);
      if (kDebugMode) {
        print('ContentRepository: Pre-fetch completed, cached ${_contentCache.length} content items');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ContentRepository: Pre-fetch failed with error: $e');
      }
    }
  }

  /// Clears the content cache.
  void clearContentCache() {
    _contentCache.clear();
    if (kDebugMode) {
      print('ContentRepository: Content cache cleared');
    }
  }
}
