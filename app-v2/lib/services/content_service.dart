import 'package:dio/dio.dart';
import '../models/audio_file.dart';
import '../models/audio_content.dart';
import '../config/api_config.dart';

/// Service for loading and managing audio content from Cloudflare R2
/// Consolidates ContentFacadeService + repositories from v1
class ContentService {
  final Dio _dio;
  final Map<String, List<AudioContent>> _cache = {};

  ContentService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 30),
              ),
            );

  /// Load content for a specific language and optional category
  /// Returns list of AudioContent with streaming URLs
  Future<List<AudioContent>> loadContent({
    required String language,
    String? category,
  }) async {
    final cacheKey = _getCacheKey(language, category);

    // Return cached data if available
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      // Use ApiConfig.getListUrl() for proper URL construction
      final categoryParam = category != null && category != 'all' ? category : '';
      final url = categoryParam.isNotEmpty
          ? ApiConfig.getListUrl(language, categoryParam)
          : '${ApiConfig.streamingBaseUrl}?prefix=audio/$language/';

      final response = await _dio.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;

        // Parse JSON to AudioFile objects using fromApiResponse
        final files = data
            .map((json) => AudioFile.fromApiResponse(json as Map<String, dynamic>))
            .toList();

        // Convert AudioFile objects to AudioContent objects
        final content = _convertFilesToContent(files);

        // Cache the result
        _cache[cacheKey] = content;

        return content;
      } else {
        throw Exception(
          'Failed to load content: HTTP ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Unexpected error loading content: $e');
    }
  }

  /// Search content by query across title and description
  Future<List<AudioContent>> searchContent({
    required String language,
    required String query,
  }) async {
    final allContent = await loadContent(language: language);
    final lowerQuery = query.toLowerCase().trim();

    if (lowerQuery.isEmpty) {
      return allContent;
    }

    return allContent.where((content) {
      return content.title.toLowerCase().contains(lowerQuery) ||
          (content.description?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  /// Clear all cached content
  void clearCache() {
    _cache.clear();
  }

  /// Clear cache for specific language/category
  void clearCacheFor({required String language, String? category}) {
    final key = _getCacheKey(language, category);
    _cache.remove(key);
  }

  /// Convert AudioFile objects to AudioContent objects
  /// Filters for M3U8 streaming URLs only
  List<AudioContent> _convertFilesToContent(List<AudioFile> files) {
    final List<AudioContent> contentList = [];
    final Set<String> processedIds = {};

    // Filter and convert M3U8 files to AudioContent
    for (final file in files) {
      // Only process M3U8 files and avoid duplicates
      if (file.isHlsStream && !processedIds.contains(file.id)) {
        contentList.add(AudioContent(
          id: file.id,
          title: file.title,
          language: file.language,
          category: file.category,
          date: file.publishDate,
          status: 'm3u8', // Files from API have completed M3U8 conversion
          description: file.metadata?.description,
          references: file.metadata?.references ?? [],
          socialHook: file.metadata?.socialHook,
          streamingUrl: file.streamingUrl,
          duration: file.duration,
          updatedAt: file.lastModified,
        ));
        processedIds.add(file.id);
      }
    }

    return contentList;
  }

  /// Generate cache key for language/category combination
  String _getCacheKey(String language, String? category) {
    return category != null && category != 'all'
        ? '$language:$category'
        : language;
  }

  /// Handle Dio errors with user-friendly messages
  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Connection timeout. Please check your internet connection.');

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        return Exception('Server error: HTTP $statusCode');

      case DioExceptionType.cancel:
        return Exception('Request cancelled');

      case DioExceptionType.connectionError:
        return Exception('No internet connection');

      case DioExceptionType.badCertificate:
        return Exception('Security certificate error');

      case DioExceptionType.unknown:
        return Exception('Network error: ${error.message}');
    }
  }

  /// Dispose resources
  void dispose() {
    _dio.close();
    _cache.clear();
  }
}
