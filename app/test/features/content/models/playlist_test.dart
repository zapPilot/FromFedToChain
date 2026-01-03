import 'package:flutter_test/flutter_test.dart';
import 'package:from_fed_to_chain_app/features/content/models/playlist.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';
import '../../../test_utils.dart';

void main() {
  group('PlaylistRepeatMode', () {
    test('fromString returns correct mode', () {
      expect(PlaylistRepeatMode.fromString('none'), PlaylistRepeatMode.none);
      expect(PlaylistRepeatMode.fromString('playlist'),
          PlaylistRepeatMode.playlist);
      expect(
          PlaylistRepeatMode.fromString('single'), PlaylistRepeatMode.single);
      expect(PlaylistRepeatMode.fromString('unknown'), PlaylistRepeatMode.none);
    });

    test('toString returns correct string', () {
      expect(PlaylistRepeatMode.none.toString(), 'none');
      expect(PlaylistRepeatMode.playlist.toString(), 'playlist');
      expect(PlaylistRepeatMode.single.toString(), 'single');
    });

    test('displayName returns user friendly name', () {
      expect(PlaylistRepeatMode.none.displayName, 'No Repeat');
      expect(PlaylistRepeatMode.playlist.displayName, 'Repeat All');
      expect(PlaylistRepeatMode.single.displayName, 'Repeat One');
    });
  });

  group('Playlist', () {
    late AudioFile ep1;
    late AudioFile ep2;
    late AudioFile ep3;

    setUp(() {
      ep1 = TestUtils.createSampleAudioFile(
          id: '1', title: 'Ep 1', duration: const Duration(minutes: 5));
      ep2 = TestUtils.createSampleAudioFile(
          id: '2', title: 'Ep 2', duration: const Duration(minutes: 10));
      ep3 = TestUtils.createSampleAudioFile(
          id: '3', title: 'Ep 3', duration: const Duration(minutes: 15));
    });

    test('empty factory creates empty playlist', () {
      final p = Playlist.empty('My List');
      expect(p.name, 'My List');
      expect(p.episodes, isEmpty);
      expect(p.isEmpty, isTrue);
    });

    test('fromEpisodes factory creates populated playlist', () {
      final p = Playlist.fromEpisodes('My List', [ep1, ep2]);
      expect(p.episodes.length, 2);
      expect(p.isNotEmpty, isTrue);
    });

    test('toJson/fromJson roundtrip works', () {
      final original = Playlist(
        id: 'test-id',
        name: 'Test List',
        episodes: [ep1],
        currentIndex: 0,
        shuffleEnabled: true,
        repeatMode: PlaylistRepeatMode.playlist,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final json = original.toJson();
      final restored = Playlist.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.episodes.length, original.episodes.length);
      expect(restored.shuffleEnabled, original.shuffleEnabled);
      expect(restored.repeatMode, original.repeatMode);
    });

    test('navigation logic - None mode', () {
      var p = Playlist.fromEpisodes('Test', [ep1, ep2, ep3]);
      // Mode: None (default)

      expect(p.currentIndex, 0);
      expect(p.currentEpisode!.id, ep1.id);
      expect(p.nextEpisode!.id, ep2.id);
      expect(p.previousEpisode, isNull);

      p = p.moveToNext();
      expect(p.currentIndex, 1);
      expect(p.currentEpisode!.id, ep2.id);
      expect(p.previousEpisode!.id, ep1.id);

      p = p.moveToNext();
      expect(p.currentIndex, 2);
      expect(p.currentEpisode!.id, ep3.id);
      expect(p.nextEpisode, isNull);

      // Attempt moving past end usually stays at end?
      final pNext = p.moveToNext();
      expect(pNext.currentIndex, 2); // Stays at last
    });

    test('navigation logic - Playlist Repeat mode', () {
      var p = Playlist.fromEpisodes('Test', [ep1, ep2, ep3])
          .setRepeatMode(PlaylistRepeatMode.playlist);

      // At start (index 0)
      expect(p.previousEpisode!.id, ep3.id); // Wraps around

      // Move to end (index 2)
      p = p.moveToNext().moveToNext();
      expect(p.currentIndex, 2);

      expect(p.nextEpisode!.id, ep1.id); // Wraps around

      // Move next properly wraps
      p = p.moveToNext();
      expect(p.currentIndex, 0);
    });

    test('navigation logic - Single Repeat mode', () {
      var p = Playlist.fromEpisodes('Test', [ep1, ep2])
          .setRepeatMode(PlaylistRepeatMode.single);

      expect(p.nextEpisode!.id, ep1.id);
      expect(p.previousEpisode!.id, ep1.id);

      // Moving next stays on current in logic?
      // Implementation: case single: newIndex = currentIndex;
      p = p.moveToNext();
      expect(p.currentIndex, 0);
    });

    test('modification methods work', () {
      var p = Playlist.empty('Test');
      p = p.addEpisode(ep1);
      expect(p.episodeCount, 1);

      p = p.addEpisode(ep2);
      expect(p.episodeCount, 2);

      p = p.moveToEpisode(ep2);
      expect(p.currentIndex, 1);

      p = p.removeEpisode(ep1);
      expect(p.episodeCount, 1);
      expect(p.currentIndex, 0); // Should adjust since 1 >= length 1
      expect(p.currentEpisode!.id, ep2.id);
    });

    test('duration getters work', () {
      final p = Playlist.fromEpisodes('Test', [ep1, ep2, ep3]);
      // 5 + 10 + 15 = 30 min
      expect(p.totalDuration.inMinutes, 30);
      expect(p.formattedTotalDuration, '30m');

      final longP = Playlist.fromEpisodes('Test', [
        TestUtils.createSampleAudioFile(
            duration: const Duration(hours: 1, minutes: 30))
      ]);
      expect(longP.formattedTotalDuration, '1h 30m');
    });
  });
}
