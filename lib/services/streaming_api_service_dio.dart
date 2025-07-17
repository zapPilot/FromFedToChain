import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../config/api_config.dart';

class StreamingApiServiceDio {
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: ApiConfig.apiTimeout,
    receiveTimeout: ApiConfig.apiTimeout,
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  ));

  /// Get list of episodes for a specific language and category
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

    final url = ApiConfig.getListUrl(language, category);
    
    if (kDebugMode) {
      print('StreamingApiServiceDio: Environment: ${ApiConfig.currentEnvironment}');
      print('StreamingApiServiceDio: Base URL: ${ApiConfig.streamingBaseUrl}');
      print('StreamingApiServiceDio: Making request to: $url');
      print('StreamingApiServiceDio: Platform: ${kIsWeb ? 'Web' : 'Mobile'}');
    }
    
    try {
      final response = await _dio.get(url);
      
      if (kDebugMode) {
        print('StreamingApiServiceDio: Response status: ${response.statusCode}');
        print('StreamingApiServiceDio: Response headers: ${response.headers}');
      }
      
      if (response.statusCode == 200) {
        final dynamic responseData = response.data;
        
        if (kDebugMode) {
          print('StreamingApiServiceDio: API response for $language/$category: $responseData');
        }
        
        // Handle both array and object responses
        if (responseData is List) {
          final episodes = responseData.cast<Map<String, dynamic>>();
          if (kDebugMode && episodes.isNotEmpty) {
            print('StreamingApiServiceDio: Sample episode data: ${episodes.first}');
          }
          return episodes;
        } else if (responseData is Map<String, dynamic>) {
          // If the API returns an object with episodes array
          final List<dynamic>? episodes = responseData['episodes'] ?? responseData['data'];
          if (episodes != null) {
            final episodeList = episodes.cast<Map<String, dynamic>>();
            if (kDebugMode && episodeList.isNotEmpty) {
              print('StreamingApiServiceDio: Sample episode data: ${episodeList.first}');
            }
            return episodeList;
          }
          // If the response is a single episode object
          if (kDebugMode) {
            print('StreamingApiServiceDio: Single episode data: $responseData');
          }
          return [responseData];
        }
        
        throw Exception('Unexpected response format: ${responseData.runtimeType}');
      } else {
        if (kDebugMode) {
          print('StreamingApiServiceDio: HTTP Error ${response.statusCode}');
          print('StreamingApiServiceDio: Response body: ${response.data}');
        }
        throw Exception('Failed to load episodes: ${response.statusCode} - ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('StreamingApiServiceDio: DioException: ${e.message}');
        print('StreamingApiServiceDio: Error type: ${e.type}');
        if (e.response != null) {
          print('StreamingApiServiceDio: Response data: ${e.response!.data}');
          print('StreamingApiServiceDio: Response headers: ${e.response!.headers}');
        }
      }
      
      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Request timed out: ${e.message}');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Network connection error: ${e.message}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('StreamingApiServiceDio: Unexpected error: $e');
        print('StreamingApiServiceDio: Error type: ${e.runtimeType}');
      }
      if (e is Exception) rethrow;
      throw Exception('Unexpected error: $e');
    }
  }

  /// Get streaming URL for a specific episode path
  static String getStreamingUrl(String path) {
    if (path.isEmpty) {
      throw ArgumentError('Episode path cannot be empty');
    }
    return ApiConfig.getStreamUrl(path);
  }

  /// Test connectivity to the streaming API
  static Future<bool> testConnectivity() async {
    try {
      await getEpisodeList('zh-TW', 'startup');
      return true;
    } catch (e) {
      print('API connectivity test failed: $e');
      return false;
    }
  }
}