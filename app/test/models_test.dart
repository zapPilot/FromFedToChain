import 'package:flutter_test/flutter_test.dart';
import 'package:from_fed_to_chain_app/models/audio_file.dart';
import 'package:from_fed_to_chain_app/models/audio_content.dart';
import 'package:from_fed_to_chain_app/models/playlist.dart';

void main() {
  group('AudioFile Tests', () {
    test('creates AudioFile with required fields', () {
      final audioFile = AudioFile(
        id: 'test-id',
        title: 'Test Title',
        language: 'en-US',
        category: 'daily-news',
        streamingUrl: 'https://example.com/test.m3u8',
        path: 'test.m3u8',
        lastModified: DateTime.now(),
      );

      expect(audioFile.id, 'test-id');
      expect(audioFile.title, 'Test Title');
      expect(audioFile.language, 'en-US');
      expect(audioFile.category, 'daily-news');
      expect(audioFile.streamingUrl, 'https://example.com/test.m3u8');
    });

    test('generates title from ID when empty', () {
      final audioFile = AudioFile(
        id: '2025-01-01-bitcoin-news',
        title: '',
        language: 'en-US',
        category: 'daily-news',
        streamingUrl: 'https://example.com/test.m3u8',
        path: 'test.m3u8',
        lastModified: DateTime.now(),
      );

      expect(audioFile.displayTitle, '2025 01 01 Bitcoin News');
    });

    test('parses publish date from ID', () {
      final audioFile = AudioFile(
        id: '2025-01-15-test-article',
        title: 'Test',
        language: 'en-US',
        category: 'daily-news',
        streamingUrl: 'https://example.com/test.m3u8',
        path: 'test.m3u8',
        lastModified: DateTime.now(),
      );

      expect(audioFile.publishDate.year, 2025);
      expect(audioFile.publishDate.month, 1);
      expect(audioFile.publishDate.day, 15);
    });

    test('formats duration correctly', () {
      final audioFile = AudioFile(
        id: 'test-id',
        title: 'Test',
        language: 'en-US',
        category: 'daily-news',
        streamingUrl: 'https://example.com/test.m3u8',
        path: 'test.m3u8',
        duration: const Duration(minutes: 5, seconds: 30),
        lastModified: DateTime.now(),
      );

      expect(audioFile.formattedDuration, '5:30');
    });

    test('returns correct category emoji', () {
      final audioFile = AudioFile(
        id: 'test-id',
        title: 'Test',
        language: 'en-US',
        category: 'daily-news',
        streamingUrl: 'https://example.com/test.m3u8',
        path: 'test.m3u8',
        lastModified: DateTime.now(),
      );

      expect(audioFile.categoryEmoji, '📰');
    });
  });

  group('AudioContent Tests', () {
    test('creates AudioContent with required fields', () {
      final content = AudioContent(
        id: 'test-content',
        title: 'Test Content',
        language: 'en-US',
        category: 'daily-news',
        status: 'published',
        date: DateTime.now(),
        description: 'Test description here',
        updatedAt: DateTime.now(),
      );

      expect(content.id, 'test-content');
      expect(content.title, 'Test Content');
      expect(content.language, 'en-US');
      expect(content.category, 'daily-news');
      expect(content.status, 'published');
    });

    test('handles optional fields gracefully', () {
      final content = AudioContent(
        id: 'test-content',
        title: 'Test Content',
        language: 'en-US',
        category: 'daily-news',
        status: 'draft',
        date: DateTime.now(),
        description: null,
        updatedAt: DateTime.now(),
      );

      expect(content.description, null);
      expect(content.references, isEmpty);
    });
  });

  group('Playlist Tests', () {
    late AudioFile testEpisode1;
    late AudioFile testEpisode2;

    setUp(() {
      testEpisode1 = AudioFile(
        id: 'episode-1',
        title: 'Episode 1',
        language: 'en-US',
        category: 'daily-news',
        streamingUrl: 'https://example.com/episode1.m3u8',
        path: 'episode1.m3u8',
        lastModified: DateTime.now(),
      );

      testEpisode2 = AudioFile(
        id: 'episode-2',
        title: 'Episode 2',
        language: 'en-US',
        category: 'daily-news',
        streamingUrl: 'https://example.com/episode2.m3u8',
        path: 'episode2.m3u8',
        lastModified: DateTime.now(),
      );
    });

    test('creates empty playlist', () {
      final playlist = Playlist.empty('Test Playlist');

      expect(playlist.name, 'Test Playlist');
      expect(playlist.episodes, isEmpty);
      expect(playlist.isEmpty, true);
      expect(playlist.currentEpisode, null);
    });

    test('creates playlist from episodes', () {
      final playlist =
          Playlist.fromEpisodes('Test Playlist', [testEpisode1, testEpisode2]);

      expect(playlist.name, 'Test Playlist');
      expect(playlist.episodes.length, 2);
      expect(playlist.currentEpisode, testEpisode1);
      expect(playlist.nextEpisode, testEpisode2);
    });

    test('navigates to next episode correctly', () {
      final playlist =
          Playlist.fromEpisodes('Test Playlist', [testEpisode1, testEpisode2]);
      final nextPlaylist = playlist.moveToNext();

      expect(nextPlaylist.currentEpisode, testEpisode2);
    });

    test('handles playlist repeat modes', () {
      var playlist = Playlist.fromEpisodes('Test Playlist', [testEpisode1]);

      // Test repeat single mode
      playlist = playlist.setRepeatMode(PlaylistRepeatMode.single);
      expect(playlist.repeatMode, PlaylistRepeatMode.single);
      expect(playlist.nextEpisode, testEpisode1); // Should repeat same episode

      // Test repeat playlist mode
      playlist = playlist.setRepeatMode(PlaylistRepeatMode.playlist);
      expect(playlist.repeatMode, PlaylistRepeatMode.playlist);
    });

    test('adds and removes episodes', () {
      var playlist = Playlist.empty('Test Playlist');

      // Add episode
      playlist = playlist.addEpisode(testEpisode1);
      expect(playlist.episodes.length, 1);
      expect(playlist.currentEpisode, testEpisode1);

      // Remove episode
      playlist = playlist.removeEpisode(testEpisode1);
      expect(playlist.episodes.length, 0);
      expect(playlist.isEmpty, true);
    });
  });

  group('PlaylistRepeatMode Tests', () {
    test('creates from string correctly', () {
      expect(PlaylistRepeatMode.fromString('none'), PlaylistRepeatMode.none);
      expect(PlaylistRepeatMode.fromString('playlist'),
          PlaylistRepeatMode.playlist);
      expect(
          PlaylistRepeatMode.fromString('single'), PlaylistRepeatMode.single);
      expect(PlaylistRepeatMode.fromString('invalid'), PlaylistRepeatMode.none);
    });

    test('converts to string correctly', () {
      expect(PlaylistRepeatMode.none.toString(), 'none');
      expect(PlaylistRepeatMode.playlist.toString(), 'playlist');
      expect(PlaylistRepeatMode.single.toString(), 'single');
    });

    test('provides correct display names', () {
      expect(PlaylistRepeatMode.none.displayName, 'No Repeat');
      expect(PlaylistRepeatMode.playlist.displayName, 'Repeat All');
      expect(PlaylistRepeatMode.single.displayName, 'Repeat One');
    });
  });
}
