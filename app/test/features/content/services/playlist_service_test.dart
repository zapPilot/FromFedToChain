import 'package:flutter_test/flutter_test.dart';
import 'package:from_fed_to_chain_app/features/content/services/playlist_service.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';
import 'package:from_fed_to_chain_app/features/content/models/playlist.dart';

void main() {
  group('PlaylistService Tests', () {
    late PlaylistService playlistService;
    late List<AudioFile> sampleEpisodes;

    setUp(() {
      playlistService = PlaylistService();

      sampleEpisodes = [
        AudioFile(
          id: 'episode-1-zh-TW',
          title: 'Bitcoin 市場分析',
          language: 'zh-TW',
          category: 'daily-news',
          streamingUrl: 'https://test.com/episode1.m3u8',
          path: 'audio/zh-TW/daily-news/episode1.m3u8',
          lastModified: DateTime(2025, 1, 15),
          duration: const Duration(minutes: 10),
        ),
        AudioFile(
          id: 'episode-2-en-US',
          title: 'Ethereum Update',
          language: 'en-US',
          category: 'ethereum',
          streamingUrl: 'https://test.com/episode2.m3u8',
          path: 'audio/en-US/ethereum/episode2.m3u8',
          lastModified: DateTime(2025, 1, 14),
          duration: const Duration(minutes: 15),
        ),
        AudioFile(
          id: 'episode-3-ja-JP',
          title: 'マクロ経済分析',
          language: 'ja-JP',
          category: 'macro',
          streamingUrl: 'https://test.com/episode3.m3u8',
          path: 'audio/ja-JP/macro/episode3.m3u8',
          lastModified: DateTime(2025, 1, 13),
          duration: const Duration(minutes: 8),
        ),
      ];
    });

    group('Playlist Management', () {
      test('creates playlist with episodes', () {
        playlistService.createPlaylist('Test Playlist', [sampleEpisodes.first]);
        expect(playlistService.currentPlaylist?.name, 'Test Playlist');
        expect(playlistService.currentPlaylist?.episodes.length, 1);
        expect(playlistService.currentPlaylist?.episodes.first,
            sampleEpisodes.first);
      });

      test('addToPlaylist adds episode to current playlist', () {
        playlistService.createPlaylist('Test Playlist', [sampleEpisodes.first]);
        playlistService.addToPlaylist(sampleEpisodes[1]);

        expect(playlistService.currentPlaylist?.episodes.length, 2);
        expect(
            playlistService.currentPlaylist?.episodes.last, sampleEpisodes[1]);
      });

      test('createPlaylistFromFiltered creates playlist from list', () {
        playlistService.setQueue(sampleEpisodes, name: 'Filtered Playlist');
        expect(playlistService.currentPlaylist, isNotNull);
        expect(playlistService.currentPlaylist?.episodes.length,
            sampleEpisodes.length);
      });
    });

    group('Episode Navigation', () {
      test('gets next episode', () {
        playlistService.setQueue(sampleEpisodes);

        final currentEpisode = sampleEpisodes[0];
        final nextEpisode = playlistService.getNextEpisode(currentEpisode);

        expect(nextEpisode?.id, sampleEpisodes[1].id);
      });

      test('gets previous episode', () {
        playlistService.setQueue(sampleEpisodes);

        final currentEpisode = sampleEpisodes[1];
        final previousEpisode =
            playlistService.getPreviousEpisode(currentEpisode);

        expect(previousEpisode?.id, sampleEpisodes[0].id);
      });

      test('returns null for next episode when at end', () {
        playlistService.setQueue(sampleEpisodes);

        final currentEpisode = sampleEpisodes.last;
        final nextEpisode = playlistService.getNextEpisode(currentEpisode);

        expect(nextEpisode, isNull);
      });

      test('returns null for previous episode when at start', () {
        playlistService.setQueue(sampleEpisodes);

        final currentEpisode = sampleEpisodes.first;
        final previousEpisode =
            playlistService.getPreviousEpisode(currentEpisode);

        expect(previousEpisode, isNull);
      });
    });
  });
}
