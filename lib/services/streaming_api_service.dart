import 'dart:convert';
import 'package:flutter/foundation.dart';
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
        
        if (kDebugMode) {
          print('StreamingApiService: API response for $language/$category: $responseData');
        }
        
        // Handle both array and object responses
        if (responseData is List) {
          final episodes = responseData.cast<Map<String, dynamic>>();
          if (kDebugMode && episodes.isNotEmpty) {
            print('StreamingApiService: Sample episode data: ${episodes.first}');
          }
          return episodes;
        } else if (responseData is Map<String, dynamic>) {
          // If the API returns an object with episodes array
          final List<dynamic>? episodes = responseData['episodes'] ?? responseData['data'];
          if (episodes != null) {
            final episodeList = episodes.cast<Map<String, dynamic>>();
            if (kDebugMode && episodeList.isNotEmpty) {
              print('StreamingApiService: Sample episode data: ${episodeList.first}');
            }
            return episodeList;
          }
          // If the response is a single episode object
          if (kDebugMode) {
            print('StreamingApiService: Single episode data: $responseData');
          }
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

  /// Get all episodes across all languages and categories (parallel loading)
  static Future<List<Map<String, dynamic>>> getAllEpisodes() async {
    print('StreamingApiService: Starting parallel loading of all episodes...');
    
    // Create all API calls upfront
    final futures = <Future<List<Map<String, dynamic>>>>[];
    
    for (final language in ApiConfig.supportedLanguages) {
      for (final category in ApiConfig.supportedCategories) {
        final future = getEpisodeList(language, category).then((episodes) {
          // Add metadata to each episode
          for (final episode in episodes) {
            episode['category'] = category;
            episode['language'] = language;
          }
          return episodes;
        }).catchError((error) {
          print('Warning: Failed to load $language/$category: $error');
          return <Map<String, dynamic>>[]; // Return empty list on error
        });
        futures.add(future);
      }
    }
    
    print('StreamingApiService: Created ${futures.length} parallel requests');
    
    // Wait for all requests to complete (parallel execution)
    final results = await Future.wait(futures);
    
    // Flatten results
    final allEpisodes = <Map<String, dynamic>>[];
    for (final episodeList in results) {
      allEpisodes.addAll(episodeList);
    }
    
    print('StreamingApiService: Parallel loading completed, got ${allEpisodes.length} total episodes');
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