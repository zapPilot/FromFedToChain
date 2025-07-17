import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class StreamingApiService {
  /// Get list of episodes for a specific language and category
  /// Returns list of episodes with id and path information
  static Future<List<Map<String, dynamic>>> getEpisodeList(
    String language, 
    String category
  ) async {
    // Validate input parameters
    if (!ApiConfig.isValidLanguage(language)) {
      throw ArgumentError('Unsupported language: $language');
    }
    if (!ApiConfig.isValidCategory(category)) {
      throw ArgumentError('Unsupported category: $category');
    }

    final url = Uri.parse(ApiConfig.getListUrl(language, category));
    
    try {
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(ApiConfig.apiTimeout);
      
      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        
        // Handle both array and object responses
        if (responseData is List) {
          return responseData.cast<Map<String, dynamic>>();
        } else if (responseData is Map<String, dynamic>) {
          // If the API returns an object with episodes array
          final List<dynamic>? episodes = responseData['episodes'] ?? responseData['data'];
          if (episodes != null) {
            return episodes.cast<Map<String, dynamic>>();
          }
          // If the response is a single episode object
          return [responseData];
        }
        
        throw Exception('Unexpected response format: ${responseData.runtimeType}');
      } else {
        throw Exception('Failed to load episodes: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Network connection error: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unexpected error: $e');
    }
  }

  /// Get all episodes for a specific language across all categories
  static Future<List<Map<String, dynamic>>> getAllEpisodesForLanguage(String language) async {
    final allEpisodes = <Map<String, dynamic>>[];
    
    for (final category in ApiConfig.supportedCategories) {
      try {
        final episodes = await getEpisodeList(language, category);
        // Add category information to each episode
        for (final episode in episodes) {
          episode['category'] = category;
          episode['language'] = language;
        }
        allEpisodes.addAll(episodes);
      } catch (e) {
        // Log category-specific errors but continue loading others
        print('Warning: Failed to load episodes for $language/$category: $e');
      }
    }
    
    return allEpisodes;
  }

  /// Get all episodes across all languages and categories
  static Future<List<Map<String, dynamic>>> getAllEpisodes() async {
    final allEpisodes = <Map<String, dynamic>>[];
    
    for (final language in ApiConfig.supportedLanguages) {
      try {
        final languageEpisodes = await getAllEpisodesForLanguage(language);
        allEpisodes.addAll(languageEpisodes);
      } catch (e) {
        print('Warning: Failed to load episodes for language $language: $e');
      }
    }
    
    return allEpisodes;
  }

  /// Get streaming URL for a specific episode path
  /// This returns the full URL that can be used with audio players
  static String getStreamingUrl(String path) {
    if (path.isEmpty) {
      throw ArgumentError('Episode path cannot be empty');
    }
    return ApiConfig.getStreamUrl(path);
  }

  /// Test connectivity to the streaming API
  static Future<bool> testConnectivity() async {
    try {
      // Try to get episodes for a common language/category combination
      await getEpisodeList('zh-TW', 'startup');
      return true;
    } catch (e) {
      print('API connectivity test failed: $e');
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
    };
  }
}