import 'package:flutter/material.dart';

/// Simple test utilities without complex dependencies
class TestUtils {
  /// Create sample data for testing
  static Map<String, dynamic> createSampleData({
    String id = 'test-id',
    String title = 'Test Title',
    String category = 'test-category',
    String language = 'en-US',
  }) {
    return {
      'id': id,
      'title': title,
      'category': category,
      'language': language,
      'date': '2025-01-01',
      'status': 'published',
      'content': 'Test content for $title',
      'streamingUrls': {
        'hls': 'https://example.com/test.m3u8',
        'mp3': 'https://example.com/test.mp3',
      },
    };
  }

  /// Create a list of sample data
  static List<Map<String, dynamic>> createSampleDataList(int count) {
    return List.generate(count, (index) {
      return createSampleData(
        id: 'test-$index',
        title: 'Test Title $index',
        category: index % 2 == 0 ? 'daily-news' : 'ethereum',
        language: index % 3 == 0 ? 'en-US' : 'ja-JP',
      );
    });
  }

  /// Delay for testing async operations
  static Future<void> delay(
      [Duration duration = const Duration(milliseconds: 100)]) {
    return Future.delayed(duration);
  }

  /// Create a simple test widget
  static Widget createTestWidget({
    String text = 'Test Widget',
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text),
      ),
    );
  }

  /// Create a test list widget
  static Widget createTestList(List<String> items) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(items[index]),
          leading: const Icon(Icons.list),
        );
      },
    );
  }

  /// Test categories
  static const List<String> testCategories = [
    'daily-news',
    'ethereum',
    'macro',
    'startup',
    'ai',
  ];

  /// Test languages
  static const List<String> testLanguages = [
    'en-US',
    'ja-JP',
    'zh-TW',
  ];

  /// Test sort orders
  static const List<String> testSortOrders = [
    'newest',
    'oldest',
    'alphabetical',
  ];

  /// Generate test statistics
  static Map<String, int> generateTestStatistics() {
    return {
      'totalEpisodes': 100,
      'filteredEpisodes': 50,
      'recentEpisodes': 20,
      'unfinishedEpisodes': 5,
    };
  }

  /// Validate test data structure
  static bool isValidTestData(Map<String, dynamic> data) {
    final requiredFields = ['id', 'title', 'category', 'language'];
    return requiredFields.every((field) => data.containsKey(field));
  }

  /// Create formatted time string for testing
  static String formatTestDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Test error messages
  static const Map<String, String> testErrorMessages = {
    'network': 'Network connection failed',
    'loading': 'Failed to load content',
    'audio': 'Audio playback error',
    'auth': 'Authentication failed',
  };

  /// Create test theme
  static ThemeData createTestTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: Colors.black,
    );
  }
}
