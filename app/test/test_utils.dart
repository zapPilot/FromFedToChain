import 'package:from_fed_to_chain_app/models/audio_content.dart';
import 'package:from_fed_to_chain_app/models/audio_file.dart';
import 'package:from_fed_to_chain_app/models/playlist.dart';

/// Test utilities for consistent test data across all test files
class TestUtils {
  /// Create sample AudioContent for testing
  static AudioContent createSampleAudioContent({
    String id = '2025-01-15-bitcoin-analysis',
    String title = 'Bitcoin Analysis',
    String language = 'en-US',
    String category = 'daily-news',
    String status = 'published',
    String? description = 'Sample content description',
    List<String> references = const ['Source 1', 'Source 2'],
    String? socialHook = '🚀 Bitcoin breaking news!',
    Duration? duration = const Duration(minutes: 5),
  }) {
    final date = DateTime.parse('2025-01-15');
    final updatedAt = DateTime.parse('2025-01-15T10:00:00Z');

    return AudioContent(
      id: id,
      title: title,
      language: language,
      category: category,
      date: date,
      status: status,
      description: description,
      references: references,
      socialHook: socialHook,
      duration: duration,
      updatedAt: updatedAt,
    );
  }

  /// Create sample AudioFile for testing
  static AudioFile createSampleAudioFile({
    String id = '2025-01-15-bitcoin-analysis',
    String title = 'Bitcoin Analysis',
    String language = 'en-US',
    String category = 'daily-news',
    String streamingUrl = 'https://example.com/audio.m3u8',
    String path = 'audio/en-US/2025-01-15-bitcoin-analysis.m3u8',
    Duration? duration = const Duration(minutes: 5),
    int? fileSizeBytes = 1024000,
  }) {
    final lastModified = DateTime.parse('2025-01-15T10:00:00Z');

    return AudioFile(
      id: id,
      title: title,
      language: language,
      category: category,
      streamingUrl: streamingUrl,
      path: path,
      duration: duration,
      fileSizeBytes: fileSizeBytes,
      lastModified: lastModified,
    );
  }

  /// Create sample Playlist for testing
  static Playlist createSamplePlaylist({
    String id = 'playlist_test',
    String name = 'Test Playlist',
    List<AudioFile>? episodes,
    int currentIndex = 0,
    bool shuffleEnabled = false,
    PlaylistRepeatMode repeatMode = PlaylistRepeatMode.none,
  }) {
    final now = DateTime.now();
    final testEpisodes = episodes ??
        [
          createSampleAudioFile(id: 'episode-1', title: 'Episode 1'),
          createSampleAudioFile(id: 'episode-2', title: 'Episode 2'),
          createSampleAudioFile(id: 'episode-3', title: 'Episode 3'),
        ];

    return Playlist(
      id: id,
      name: name,
      episodes: testEpisodes,
      currentIndex: currentIndex,
      shuffleEnabled: shuffleEnabled,
      repeatMode: repeatMode,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create API response JSON for AudioContent
  static Map<String, dynamic> createAudioContentJson({
    String id = '2025-01-15-bitcoin-analysis',
    String title = 'Bitcoin Analysis',
    String language = 'en-US',
    String category = 'daily-news',
    String status = 'published',
    String? content = 'Sample content description',
    List<String> references = const ['Source 1', 'Source 2'],
    String? socialHook = '🚀 Bitcoin breaking news!',
    int? duration = 300, // 5 minutes in seconds
  }) {
    return {
      'id': id,
      'title': title,
      'language': language,
      'category': category,
      'date': '2025-01-15',
      'status': status,
      'content': content,
      'references': references,
      'social_hook': socialHook,
      'duration': duration,
      'updated_at': '2025-01-15T10:00:00Z',
    };
  }

  /// Create API response JSON for AudioFile
  static Map<String, dynamic> createAudioFileJson({
    String id = '2025-01-15-bitcoin-analysis',
    String? title = 'Bitcoin Analysis',
    String language = 'en-US',
    String category = 'daily-news',
    String streamingUrl = 'https://example.com/audio.m3u8',
    String path = 'audio/en-US/2025-01-15-bitcoin-analysis.m3u8',
    int? duration = 300, // 5 minutes in seconds
    int? size = 1024000,
  }) {
    return {
      'id': id,
      'title': title,
      'language': language,
      'category': category,
      'streaming_url': streamingUrl,
      'path': path,
      'duration': duration,
      'size': size,
      'last_modified': '2025-01-15T10:00:00Z',
    };
  }

  /// Create invalid JSON for negative testing
  static Map<String, dynamic> createInvalidAudioContentJson() {
    return {
      'id': null, // Invalid - required field
      'title': '',
      'language': 'invalid-lang',
      'category': '',
      'date': 'invalid-date',
      'status': '',
      'updated_at': 'invalid-date',
    };
  }

  /// Test categories for validation
  static const List<String> validCategories = [
    'daily-news',
    'ethereum',
    'macro',
    'startup',
    'ai',
    'defi',
  ];

  /// Test languages for validation
  static const List<String> validLanguages = [
    'zh-TW',
    'en-US',
    'ja-JP',
  ];

  /// Test statuses for validation
  static const List<String> validStatuses = [
    'draft',
    'reviewed',
    'published',
  ];

  /// Expected emojis for categories
  static const Map<String, String> categoryEmojis = {
    'daily-news': '📰',
    'ethereum': '⚡',
    'macro': '📊',
    'startup': '🚀',
    'ai': '🤖',
    'defi': '💎',
  };

  /// Expected emojis for languages
  static const Map<String, String> languageEmojis = {
    'zh-TW': '🇹🇼',
    'en-US': '🇺🇸',
    'ja-JP': '🇯🇵',
  };

  /// Helper to create edge case data
  static AudioContent createEdgeCaseAudioContent() {
    return AudioContent(
      id: '',
      title: '',
      language: 'unknown',
      category: 'unknown',
      date: DateTime.now(),
      status: 'unknown',
      description: null,
      references: [],
      socialHook: null,
      duration: null,
      updatedAt: DateTime.now(),
    );
  }

  /// Helper to create edge case AudioFile
  static AudioFile createEdgeCaseAudioFile() {
    return AudioFile(
      id: '',
      title: '',
      language: 'unknown',
      category: 'unknown',
      streamingUrl: '',
      path: '',
      duration: null,
      fileSizeBytes: null,
      lastModified: DateTime.now(),
    );
  }
}
