import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_content.dart';
import 'package:from_fed_to_chain_app/features/content/models/playlist.dart';
import 'package:from_fed_to_chain_app/core/theme/app_theme.dart';
import 'package:from_fed_to_chain_app/features/audio/services/player_state_notifier.dart';

/// Custom matchers for testing
/// Matches at least N widgets
Matcher findsAtLeastNWidget(int count) => _FindsAtLeastNWidget(count);

class _FindsAtLeastNWidget extends Matcher {
  const _FindsAtLeastNWidget(this.count);
  final int count;

  @override
  bool matches(covariant Finder finder, Map<dynamic, dynamic> matchState) {
    matchState['count'] = finder.evaluate().length;
    return finder.evaluate().length >= count;
  }

  @override
  Description describe(Description description) {
    return description.add('finds at least $count widgets');
  }

  @override
  Description describeMismatch(
    covariant Finder finder,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    return mismatchDescription.add('found ${matchState['count']} widgets');
  }
}

/// Comprehensive test utilities for Flutter testing
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

  /// Create sample AudioFile for testing
  static AudioFile createSampleAudioFile({
    String id = 'test-audio-file',
    String title = 'Test Audio File',
    String language = 'en-US',
    String category = 'daily-news',
    String streamingUrl = 'https://example.com/test.m3u8',
    Duration? duration,
    int? fileSizeBytes,
    DateTime? lastModified,
    DateTime? publishDate,
  }) {
    return AudioFile(
      id: id,
      title: title,
      language: language,
      category: category,
      streamingUrl: streamingUrl,
      path: '$id.m3u8',
      duration: duration,
      fileSizeBytes: fileSizeBytes ?? 1024 * 1024,
      lastModified: lastModified ?? DateTime.now(),
    );
  }

  /// Create sample AudioContent for testing
  static AudioContent createSampleAudioContent({
    String id = 'test-content',
    String title = 'Test Content',
    String language = 'en-US',
    String category = 'daily-news',
    String status = 'published',
    String? description,
    List<String>? references,
    String? socialHook,
    Duration? duration,
    DateTime? date,
    DateTime? updatedAt,
  }) {
    return AudioContent(
      id: id,
      title: title,
      language: language,
      category: category,
      status: status,
      description: description ?? 'Test description for $title',
      references: references ?? ['Test Reference 1', 'Test Reference 2'],
      socialHook: socialHook ?? 'Test social hook',
      duration: duration ?? const Duration(minutes: 5),
      date: date ?? DateTime.now(),
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Create sample Playlist for testing
  static Playlist createSamplePlaylist({
    String id = 'test-playlist',
    String name = 'Test Playlist',
    List<AudioFile>? episodes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Playlist(
      id: id,
      name: name,
      episodes: episodes ??
          [createSampleAudioFile(duration: const Duration(minutes: 5))],
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Create a list of sample AudioFiles
  static List<AudioFile> createSampleAudioFileList(int count) {
    return List.generate(count, (index) {
      return createSampleAudioFile(
        id: 'test-audio-$index',
        title: 'Test Audio Title $index',
        category: testCategories[index % testCategories.length],
        language: testLanguages[index % testLanguages.length],
        duration: Duration(minutes: 5 + index),
      );
    });
  }

  /// Create a list of sample AudioFiles (alias for createSampleAudioFileList)
  static List<AudioFile> createSampleAudioFiles(int count) {
    return createSampleAudioFileList(count);
  }

  /// Create test widget wrapper with MaterialApp and theme
  static Widget wrapWithMaterialApp(
    Widget child, {
    ThemeData? theme,
    Locale? locale,
    List<NavigatorObserver>? navigatorObservers,
  }) {
    return MaterialApp(
      theme: theme ?? createTestTheme(),
      locale: locale,
      navigatorObservers: navigatorObservers ?? [],
      home: Scaffold(body: child),
    );
  }

  /// Create test widget wrapper with full app structure
  static Widget wrapWithFullApp(
    Widget child, {
    ThemeData? theme,
    Locale? locale,
  }) {
    return MaterialApp(
      theme: theme ?? AppTheme.darkTheme,
      locale: locale,
      home: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: child,
      ),
    );
  }

  /// Pump widget with common setup
  static Future<void> pumpWidgetWithMaterialApp(
    WidgetTester tester,
    Widget child, {
    ThemeData? theme,
    Locale? locale,
  }) async {
    await tester
        .pumpWidget(wrapWithMaterialApp(child, theme: theme, locale: locale));
  }

  /// Find widget by type and optional key
  static Finder findWidgetByType<T extends Widget>([Key? key]) {
    return key != null ? find.byKey(key) : find.byType(T);
  }

  /// Find text widget with specific text
  static Finder findTextWidget(String text) {
    return find.text(text);
  }

  /// Find icon widget with specific icon
  static Finder findIconWidget(IconData icon) {
    return find.byIcon(icon);
  }

  /// Assert widget exists
  static void expectWidgetExists(Finder finder) {
    expect(finder, findsOneWidget);
  }

  /// Assert widget doesn't exist
  static void expectWidgetNotExists(Finder finder) {
    expect(finder, findsNothing);
  }

  /// Assert text exists
  static void expectTextExists(String text) {
    expectWidgetExists(findTextWidget(text));
  }

  /// Assert icon exists
  static void expectIconExists(IconData icon) {
    expectWidgetExists(findIconWidget(icon));
  }

  /// Simulate scroll
  static Future<void> scrollWidget(
    WidgetTester tester,
    Finder scrollable,
    Offset offset,
  ) async {
    await tester.drag(scrollable, offset);
    await tester.pumpAndSettle();
  }

  /// Simulate tap with settling
  static Future<void> tapWidget(
    WidgetTester tester,
    Finder widget,
  ) async {
    await tester.tap(widget);
    await tester.pumpAndSettle();
  }

  /// Simulate long press with settling
  static Future<void> longPressWidget(
    WidgetTester tester,
    Finder widget,
  ) async {
    await tester.longPress(widget);
    await tester.pumpAndSettle();
  }

  /// Enter text with settling
  static Future<void> enterTextInWidget(
    WidgetTester tester,
    Finder widget,
    String text,
  ) async {
    await tester.enterText(widget, text);
    await tester.pumpAndSettle();
  }

  /// Wait for animation completion
  static Future<void> waitForAnimation(
    WidgetTester tester, [
    Duration duration = const Duration(milliseconds: 500),
  ]) async {
    await tester.pump(duration);
    await tester.pumpAndSettle();
  }

  /// Generate test error scenarios
  static List<Map<String, dynamic>> generateErrorScenarios() {
    return [
      {
        'type': 'network',
        'message': 'Network connection failed',
        'code': 'NETWORK_ERROR',
      },
      {
        'type': 'loading',
        'message': 'Failed to load content',
        'code': 'LOADING_ERROR',
      },
      {
        'type': 'audio',
        'message': 'Audio playback error',
        'code': 'AUDIO_ERROR',
      },
      {
        'type': 'auth',
        'message': 'Authentication failed',
        'code': 'AUTH_ERROR',
      },
    ];
  }

  /// Create test statistics with various scenarios
  static Map<String, int> generateVariedTestStatistics({
    int totalEpisodes = 100,
    int filteredEpisodes = 50,
    int recentEpisodes = 20,
    int unfinishedEpisodes = 5,
  }) {
    return {
      'totalEpisodes': totalEpisodes,
      'filteredEpisodes': filteredEpisodes,
      'recentEpisodes': recentEpisodes,
      'unfinishedEpisodes': unfinishedEpisodes,
    };
  }

  /// Create realistic audio file sizes for different durations
  static int calculateAudioFileSize(Duration duration) {
    // Approximate HLS stream size calculation (320kbps)
    const int bitrateKbps = 320;
    final int durationSeconds = duration.inSeconds;
    return (bitrateKbps * 1024 * durationSeconds) ~/ 8;
  }

  /// Generate test streaming URLs
  static Map<String, String> generateTestStreamingUrls(String id) {
    return {
      'hls': 'https://example.com/streams/$id.m3u8',
      'mp3': 'https://example.com/audio/$id.mp3',
      'opus': 'https://example.com/audio/$id.opus',
    };
  }

  /// Generate test timestamps for different scenarios
  static List<DateTime> generateTestTimestamps({
    int count = 10,
    Duration? spacing,
    DateTime? startDate,
  }) {
    final start =
        startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final interval = spacing ?? const Duration(days: 3);

    return List.generate(count, (index) {
      return start.add(Duration(milliseconds: interval.inMilliseconds * index));
    });
  }

  /// Create test completion percentages
  static Map<String, double> generateTestCompletions(List<String> episodeIds) {
    return Map.fromEntries(
      episodeIds.asMap().entries.map((entry) {
        final index = entry.key;
        final id = entry.value;
        // Create varied completion percentages
        return MapEntry(id, (index * 0.1) % 1.0);
      }),
    );
  }

  /// Test data validation helpers
  static void validateAudioFile(AudioFile audioFile) {
    expect(audioFile.id, isNotEmpty);
    expect(audioFile.title, isNotEmpty);
    expect(audioFile.language, isIn(testLanguages));
    expect(audioFile.category, isIn(testCategories));
    expect(audioFile.streamingUrl, isNotEmpty);
    expect(audioFile.path, isNotEmpty);
  }

  static void validateAudioContent(AudioContent content) {
    expect(content.id, isNotEmpty);
    expect(content.title, isNotEmpty);
    expect(content.language, isIn(testLanguages));
    expect(content.category, isIn(testCategories));
    expect(content.status, isNotEmpty);
  }

  /// Mock async operation results
  static Future<T> mockAsyncSuccess<T>(T result, {Duration? delay}) async {
    await Future.delayed(delay ?? const Duration(milliseconds: 100));
    return result;
  }

  static Future<T> mockAsyncError<T>(String message, {Duration? delay}) async {
    await Future.delayed(delay ?? const Duration(milliseconds: 100));
    throw Exception(message);
  }

  /// Convert AppPlaybackState enum to MiniPlayer boolean parameters
  /// Helper method for MiniPlayer test migration after API refactor
  static Map<String, dynamic> convertPlaybackStateToMiniPlayerParams(
      AppPlaybackState playbackState) {
    String stateText;
    bool isPlaying = false;
    bool isPaused = false;
    bool isLoading = false;
    bool hasError = false;

    switch (playbackState) {
      case AppPlaybackState.playing:
        isPlaying = true;
        stateText = 'Playing';
        break;
      case AppPlaybackState.paused:
        isPaused = true;
        stateText = 'Paused';
        break;
      case AppPlaybackState.loading:
        isLoading = true;
        stateText = 'Loading';
        break;
      case AppPlaybackState.error:
        hasError = true;
        stateText = 'Error';
        break;
      case AppPlaybackState.stopped:
        stateText = 'Stopped';
        break;
      case AppPlaybackState.completed:
        stateText = 'Completed';
        break;
    }

    return {
      'isPlaying': isPlaying,
      'isPaused': isPaused,
      'isLoading': isLoading,
      'hasError': hasError,
      'stateText': stateText,
    };
  }
}

/// Test data factory class for creating mock objects
class TestDataFactory {
  /// Create mock AudioFile for testing
  static AudioFile createMockAudioFile({
    String? id,
    String? title,
    String? language,
    String? category,
    String? streamingUrl,
    String? path,
    Duration? duration,
    int? fileSizeBytes,
    DateTime? lastModified,
  }) {
    return TestUtils.createSampleAudioFile(
      id: id ?? 'mock-audio-${DateTime.now().millisecondsSinceEpoch}',
      title: title ?? 'Mock Audio File',
      language: language ?? 'en-US',
      category: category ?? 'daily-news',
      streamingUrl: streamingUrl ?? 'https://example.com/mock.m3u8',
      duration: duration,
      fileSizeBytes: fileSizeBytes ?? 1024 * 1024,
      lastModified: lastModified ?? DateTime.now(),
    );
  }

  /// Create mock AudioContent for testing
  static AudioContent createMockAudioContent({
    String? id,
    String? title,
    String? language,
    String? category,
    String? status,
    String? description,
    List<String>? references,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return AudioContent(
      id: id ?? 'mock-content-${now.millisecondsSinceEpoch}',
      title: title ?? 'Mock Audio Content',
      language: language ?? 'en-US',
      category: category ?? 'daily-news',
      date: now,
      status: status ?? 'published',
      description: description ?? 'Mock content text',
      references: references ?? ['Mock Reference'],
      updatedAt: updatedAt ?? now,
    );
  }

  /// Create mock Playlist for testing
  static Playlist createMockPlaylist({
    String? id,
    String? name,
    List<AudioFile>? episodes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Playlist(
      id: id ?? 'mock-playlist-${DateTime.now().millisecondsSinceEpoch}',
      name: name ?? 'Mock Playlist',
      episodes: episodes ?? [createMockAudioFile()],
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

// Extension to add testing methods to ContentService for integration tests
// Note: These methods would need to be implemented in the actual ContentService class
// extension ContentServiceTesting on ContentService {
//   void setEpisodesForTesting(List<AudioFile> episodes) {
//     // This would be implemented in the actual ContentService class
//     // to allow setting test data for integration tests
//   }
//
//   void setLoadingForTesting(bool isLoading) {
//     // This would be implemented in the actual ContentService class
//     // to simulate loading states in tests
//   }
//
//   void setErrorForTesting(String error) {
//     // This would be implemented in the actual ContentService class
//     // to simulate error states in tests
//   }
//
//   List<AudioFile> getFilteredEpisodesByLanguage() {
//     // This would be implemented in the actual ContentService class
//     // to return episodes filtered by selected language
//     return [];
//   }
//
//   List<AudioFile> getFilteredEpisodesByCategory() {
//     // This would be implemented in the actual ContentService class
//     // to return episodes filtered by selected category
//     return [];
//   }
//
//   void setLanguage(String language) {
//     // This would be implemented in the actual ContentService class
//     // to set the selected language
//   }
//
//   void setCategory(String category) {
//     // This would be implemented in the actual ContentService class
//     // to set the selected category
//   }
//
//   void setSortOrder(String sortOrder) {
//     // This would be implemented in the actual ContentService class
//     // to set the sort order
//   }
// }
