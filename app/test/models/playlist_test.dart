import 'package:flutter_test/flutter_test.dart';
import 'package:from_fed_to_chain_app/features/content/models/playlist.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';
import '../test_utils.dart';

void main() {
  group('Playlist Model Tests', () {
    late List<AudioFile> testEpisodes;

    setUp(() {
      testEpisodes = [
        TestDataFactory.createMockAudioFile(
          id: 'episode-1',
          title: 'Episode 1',
          category: 'daily-news',
          language: 'zh-TW',
          duration: const Duration(minutes: 5),
        ),
        TestDataFactory.createMockAudioFile(
          id: 'episode-2',
          title: 'Episode 2',
          category: 'startup',
          language: 'en-US',
          duration: const Duration(minutes: 8),
        ),
        TestDataFactory.createMockAudioFile(
          id: 'episode-3',
          title: 'Episode 3',
          category: 'ethereum',
          language: 'ja-JP',
          duration: const Duration(minutes: 12),
        ),
      ];
    });

    group('Constructor Tests', () {
      test('should create playlist with all required fields', () {
        final now = DateTime.now();
        final playlist = Playlist(
          id: 'test-playlist',
          name: 'Test Playlist',
          episodes: testEpisodes,
          currentIndex: 1,
          shuffleEnabled: true,
          repeatMode: PlaylistRepeatMode.playlist,
          createdAt: now,
          updatedAt: now,
        );

        expect(playlist.id, equals('test-playlist'));
        expect(playlist.name, equals('Test Playlist'));
        expect(playlist.episodes, equals(testEpisodes));
        expect(playlist.currentIndex, equals(1));
        expect(playlist.shuffleEnabled, isTrue);
        expect(playlist.repeatMode, equals(PlaylistRepeatMode.playlist));
        expect(playlist.createdAt, equals(now));
        expect(playlist.updatedAt, equals(now));
      });

      test('should create playlist with default values', () {
        final now = DateTime.now();
        final playlist = Playlist(
          id: 'test-playlist',
          name: 'Test Playlist',
          episodes: testEpisodes,
          createdAt: now,
          updatedAt: now,
        );

        expect(playlist.currentIndex, equals(0));
        expect(playlist.shuffleEnabled, isFalse);
        expect(playlist.repeatMode, equals(PlaylistRepeatMode.none));
      });
    });

    group('Factory Constructor Tests', () {
      test('should create empty playlist', () {
        final playlist = Playlist.empty('Empty Playlist');

        expect(playlist.name, equals('Empty Playlist'));
        expect(playlist.episodes, isEmpty);
        expect(playlist.currentIndex, equals(0));
        expect(playlist.shuffleEnabled, isFalse);
        expect(playlist.repeatMode, equals(PlaylistRepeatMode.none));
        expect(playlist.id, startsWith('playlist_'));
        expect(playlist.createdAt, isNotNull);
        expect(playlist.updatedAt, isNotNull);
      });

      test('should create playlist from episodes', () {
        final playlist = Playlist.fromEpisodes('Test Playlist', testEpisodes);

        expect(playlist.name, equals('Test Playlist'));
        expect(playlist.episodes, equals(testEpisodes));
        expect(playlist.currentIndex, equals(0));
        expect(playlist.shuffleEnabled, isFalse);
        expect(playlist.repeatMode, equals(PlaylistRepeatMode.none));
        expect(playlist.id, startsWith('playlist_'));
        expect(playlist.createdAt, isNotNull);
        expect(playlist.updatedAt, isNotNull);
      });
    });

    group('JSON Serialization Tests', () {
      test('should serialize to JSON correctly', () {
        final now = DateTime.parse('2025-01-20T10:00:00Z');
        final playlist = Playlist(
          id: 'test-playlist',
          name: 'Test Playlist',
          episodes: [testEpisodes.first],
          currentIndex: 1,
          shuffleEnabled: true,
          repeatMode: PlaylistRepeatMode.single,
          createdAt: now,
          updatedAt: now,
        );

        final json = playlist.toJson();

        expect(json['id'], equals('test-playlist'));
        expect(json['name'], equals('Test Playlist'));
        expect(json['episodes'], isA<List>());
        expect(json['current_index'], equals(1));
        expect(json['shuffle_enabled'], isTrue);
        expect(json['repeat_mode'], equals('single'));
        expect(json['created_at'], equals('2025-01-20T10:00:00.000Z'));
        expect(json['updated_at'], equals('2025-01-20T10:00:00.000Z'));
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'id': 'test-playlist',
          'name': 'Test Playlist',
          'episodes': [
            {
              'id': '2025-01-01-test',
              'path': 'zh-TW/daily-news/2025-01-01-test.m3u8',
              'title': 'Test Episode',
              'streaming_url':
                  'https://test-api.example.com/zh-TW/daily-news/2025-01-01-test.m3u8',
              'category': 'daily-news',
              'language': 'zh-TW',
              'size': 1024,
              'last_modified': '2025-01-01T10:00:00Z',
              'duration': 300,
            }
          ],
          'current_index': 2,
          'shuffle_enabled': true,
          'repeat_mode': 'playlist',
          'created_at': '2025-01-20T10:00:00.000Z',
          'updated_at': '2025-01-20T11:00:00.000Z',
        };

        final playlist = Playlist.fromJson(json);

        expect(playlist.id, equals('test-playlist'));
        expect(playlist.name, equals('Test Playlist'));
        expect(playlist.episodes, hasLength(1));
        expect(playlist.currentIndex, equals(2));
        expect(playlist.shuffleEnabled, isTrue);
        expect(playlist.repeatMode, equals(PlaylistRepeatMode.playlist));
        expect(playlist.createdAt,
            equals(DateTime.parse('2025-01-20T10:00:00.000Z')));
        expect(playlist.updatedAt,
            equals(DateTime.parse('2025-01-20T11:00:00.000Z')));
      });

      test('should handle JSON with default values', () {
        final json = {
          'id': 'test-playlist',
          'name': 'Test Playlist',
          'episodes': [],
          'created_at': '2025-01-20T10:00:00.000Z',
          'updated_at': '2025-01-20T11:00:00.000Z',
        };

        final playlist = Playlist.fromJson(json);

        expect(playlist.currentIndex, equals(0));
        expect(playlist.shuffleEnabled, isFalse);
        expect(playlist.repeatMode, equals(PlaylistRepeatMode.none));
      });

      test('should handle JSON serialization roundtrip', () {
        final originalPlaylist =
            Playlist.fromEpisodes('Test Playlist', testEpisodes);
        final json = originalPlaylist.toJson();
        final deserializedPlaylist = Playlist.fromJson(json);

        expect(deserializedPlaylist.id, equals(originalPlaylist.id));
        expect(deserializedPlaylist.name, equals(originalPlaylist.name));
        expect(deserializedPlaylist.episodes.length,
            equals(originalPlaylist.episodes.length));
        expect(deserializedPlaylist.currentIndex,
            equals(originalPlaylist.currentIndex));
        expect(deserializedPlaylist.shuffleEnabled,
            equals(originalPlaylist.shuffleEnabled));
        expect(deserializedPlaylist.repeatMode,
            equals(originalPlaylist.repeatMode));
      });
    });

    group('copyWith Tests', () {
      test('should create copy with updated fields', () {
        final originalPlaylist =
            Playlist.fromEpisodes('Original', testEpisodes);
        final updatedTime = DateTime.now().add(const Duration(hours: 1));

        final updatedPlaylist = originalPlaylist.copyWith(
          name: 'Updated Playlist',
          currentIndex: 2,
          shuffleEnabled: true,
          repeatMode: PlaylistRepeatMode.single,
          updatedAt: updatedTime,
        );

        expect(updatedPlaylist.id, equals(originalPlaylist.id));
        expect(updatedPlaylist.name, equals('Updated Playlist'));
        expect(updatedPlaylist.episodes, equals(originalPlaylist.episodes));
        expect(updatedPlaylist.currentIndex, equals(2));
        expect(updatedPlaylist.shuffleEnabled, isTrue);
        expect(updatedPlaylist.repeatMode, equals(PlaylistRepeatMode.single));
        expect(updatedPlaylist.createdAt, equals(originalPlaylist.createdAt));
        expect(updatedPlaylist.updatedAt, equals(updatedTime));
      });

      test('should preserve original values when not specified', () {
        final originalPlaylist =
            Playlist.fromEpisodes('Original', testEpisodes);
        final copiedPlaylist = originalPlaylist.copyWith();

        expect(copiedPlaylist.id, equals(originalPlaylist.id));
        expect(copiedPlaylist.name, equals(originalPlaylist.name));
        expect(copiedPlaylist.episodes, equals(originalPlaylist.episodes));
        expect(
            copiedPlaylist.currentIndex, equals(originalPlaylist.currentIndex));
        expect(copiedPlaylist.shuffleEnabled,
            equals(originalPlaylist.shuffleEnabled));
        expect(copiedPlaylist.repeatMode, equals(originalPlaylist.repeatMode));
        expect(copiedPlaylist.createdAt, equals(originalPlaylist.createdAt));
        expect(copiedPlaylist.updatedAt, equals(originalPlaylist.updatedAt));
      });
    });

    group('Current Episode Tests', () {
      test('should return current episode correctly', () {
        final playlist = Playlist.fromEpisodes('Test', testEpisodes)
            .copyWith(currentIndex: 1);

        expect(playlist.currentEpisode, equals(testEpisodes[1]));
      });

      test('should return null for empty playlist', () {
        final playlist = Playlist.empty('Empty');

        expect(playlist.currentEpisode, isNull);
      });

      test('should return null for invalid current index (negative)', () {
        final playlist = Playlist.fromEpisodes('Test', testEpisodes)
            .copyWith(currentIndex: -1);

        expect(playlist.currentEpisode, isNull);
      });

      test('should return null for invalid current index (too large)', () {
        final playlist = Playlist.fromEpisodes('Test', testEpisodes)
            .copyWith(currentIndex: 10);

        expect(playlist.currentEpisode, isNull);
      });
    });

    group('Next Episode Tests', () {
      test('should return next episode with none repeat mode', () {
        final playlist = Playlist.fromEpisodes('Test', testEpisodes)
            .copyWith(currentIndex: 0, repeatMode: PlaylistRepeatMode.none);

        expect(playlist.nextEpisode, equals(testEpisodes[1]));
      });

      test('should return null when at end with none repeat mode', () {
        final playlist = Playlist.fromEpisodes('Test', testEpisodes)
            .copyWith(currentIndex: 2, repeatMode: PlaylistRepeatMode.none);

        expect(playlist.nextEpisode, isNull);
      });

      test('should wrap around with playlist repeat mode', () {
        final playlist = Playlist.fromEpisodes('Test', testEpisodes)
            .copyWith(currentIndex: 2, repeatMode: PlaylistRepeatMode.playlist);

        expect(playlist.nextEpisode, equals(testEpisodes[0]));
      });

      test('should return same episode with single repeat mode', () {
        final playlist = Playlist.fromEpisodes('Test', testEpisodes)
            .copyWith(currentIndex: 1, repeatMode: PlaylistRepeatMode.single);

        expect(playlist.nextEpisode, equals(testEpisodes[1]));
      });

      test('should return null for empty playlist', () {
        final playlist = Playlist.empty('Empty');

        expect(playlist.nextEpisode, isNull);
      });
    });

    group('Previous Episode Tests', () {
      test('should return previous episode with none repeat mode', () {
        final playlist = Playlist.fromEpisodes('Test', testEpisodes)
            .copyWith(currentIndex: 2, repeatMode: PlaylistRepeatMode.none);

        expect(playlist.previousEpisode, equals(testEpisodes[1]));
      });

      test('should return null when at beginning with none repeat mode', () {
        final playlist = Playlist.fromEpisodes('Test', testEpisodes)
            .copyWith(currentIndex: 0, repeatMode: PlaylistRepeatMode.none);

        expect(playlist.previousEpisode, isNull);
      });

      test('should wrap around with playlist repeat mode', () {
        final playlist = Playlist.fromEpisodes('Test', testEpisodes)
            .copyWith(currentIndex: 0, repeatMode: PlaylistRepeatMode.playlist);

        expect(playlist.previousEpisode, equals(testEpisodes[2]));
      });

      test('should return same episode with single repeat mode', () {
        final playlist = Playlist.fromEpisodes('Test', testEpisodes)
            .copyWith(currentIndex: 1, repeatMode: PlaylistRepeatMode.single);

        expect(playlist.previousEpisode, equals(testEpisodes[1]));
      });

      test('should return null for empty playlist', () {
        final playlist = Playlist.empty('Empty');

        expect(playlist.previousEpisode, isNull);
      });
    });

    group('Property Tests', () {
      test('should check if playlist is empty', () {
        final emptyPlaylist = Playlist.empty('Empty');
        final nonEmptyPlaylist =
            Playlist.fromEpisodes('NonEmpty', testEpisodes);

        expect(emptyPlaylist.isEmpty, isTrue);
        expect(emptyPlaylist.isNotEmpty, isFalse);
        expect(nonEmptyPlaylist.isEmpty, isFalse);
        expect(nonEmptyPlaylist.isNotEmpty, isTrue);
      });

      test('should calculate total duration correctly', () {
        final playlist = Playlist.fromEpisodes('Test', testEpisodes);
        // Episodes: 5min + 8min + 12min = 25min
        expect(playlist.totalDuration, equals(const Duration(minutes: 25)));
      });

      test('should handle episodes with null duration in total calculation',
          () {
        final episodesWithNullDuration = <AudioFile>[
          TestDataFactory.createMockAudioFile(
            id: 'episode-1',
            title: 'Episode 1',
            duration: const Duration(minutes: 5),
          ),
          TestDataFactory.createMockAudioFile(
            id: 'episode-2',
            title: 'Episode 2',
            duration: null,
          ),
        ];

        final playlist =
            Playlist.fromEpisodes('Test', episodesWithNullDuration);
        expect(playlist.totalDuration, equals(const Duration(minutes: 5)));
      });

      test('should format total duration correctly', () {
        final playlist = Playlist.fromEpisodes('Test', testEpisodes);
        expect(playlist.formattedTotalDuration, equals('25m'));
      });

      test('should format total duration with hours correctly', () {
        final longEpisodes = <AudioFile>[
          TestDataFactory.createMockAudioFile(
            id: 'long-episode',
            title: 'Long Episode',
            duration: const Duration(hours: 1, minutes: 30),
          ),
        ];

        final playlist = Playlist.fromEpisodes('Test', longEpisodes);
        expect(playlist.formattedTotalDuration, equals('1h 30m'));
      });

      test('should return correct episode count', () {
        final playlist = Playlist.fromEpisodes('Test', testEpisodes);
        expect(playlist.episodeCount, equals(3));

        final emptyPlaylist = Playlist.empty('Empty');
        expect(emptyPlaylist.episodeCount, equals(0));
      });
    });

    group('Episode Management Tests', () {
      test('should add episode to playlist', () {
        final playlist = Playlist.fromEpisodes('Test', testEpisodes);
        final newEpisode = TestDataFactory.createMockAudioFile(
          id: 'new-episode',
          title: 'New Episode',
        );

        final updatedPlaylist = playlist.addEpisode(newEpisode);

        expect(updatedPlaylist.episodes.length, equals(4));
        expect(updatedPlaylist.episodes.last, equals(newEpisode));
        expect(updatedPlaylist.updatedAt.isAfter(playlist.updatedAt), isTrue);
      });

      test('should remove episode from playlist', () {
        final playlist = Playlist.fromEpisodes('Test', testEpisodes);
        final episodeToRemove = testEpisodes[1];

        final updatedPlaylist = playlist.removeEpisode(episodeToRemove);

        expect(updatedPlaylist.episodes.length, equals(2));
        expect(updatedPlaylist.episodes.contains(episodeToRemove), isFalse);
        expect(updatedPlaylist.updatedAt.isAfter(playlist.updatedAt), isTrue);
      });

      test('should adjust current index when removing episode before current',
          () {
        final playlist = Playlist.fromEpisodes('Test', testEpisodes)
            .copyWith(currentIndex: 2);
        final episodeToRemove = testEpisodes[0];

        final updatedPlaylist = playlist.removeEpisode(episodeToRemove);

        expect(updatedPlaylist.currentIndex, equals(1)); // Adjusted from 2 to 1
      });

      test('should adjust current index when removing current episode', () {
        final playlist = Playlist.fromEpisodes('Test', testEpisodes)
            .copyWith(currentIndex: 2);
        final episodeToRemove = testEpisodes[2];

        final updatedPlaylist = playlist.removeEpisode(episodeToRemove);

        expect(updatedPlaylist.currentIndex,
            equals(1)); // Adjusted to last valid index
      });

      test('should handle removing non-existent episode', () {
        final playlist = Playlist.fromEpisodes('Test', testEpisodes);
        final nonExistentEpisode = TestDataFactory.createMockAudioFile(
          id: 'non-existent',
          title: 'Non-existent',
        );

        final updatedPlaylist = playlist.removeEpisode(nonExistentEpisode);

        expect(updatedPlaylist.episodes.length, equals(3));
        expect(updatedPlaylist.episodes, equals(testEpisodes));
      });
    });

    group('Navigation Tests', () {
      test('should move to specific episode', () {
        final playlist = Playlist.fromEpisodes('Test', testEpisodes);
        final targetEpisode = testEpisodes[2];

        final updatedPlaylist = playlist.moveToEpisode(targetEpisode);

        expect(updatedPlaylist.currentIndex, equals(2));
        expect(updatedPlaylist.updatedAt.isAfter(playlist.updatedAt), isTrue);
      });

      test('should handle moving to non-existent episode', () {
        final playlist = Playlist.fromEpisodes('Test', testEpisodes);
        final nonExistentEpisode = TestDataFactory.createMockAudioFile(
          id: 'non-existent',
          title: 'Non-existent',
        );

        final updatedPlaylist = playlist.moveToEpisode(nonExistentEpisode);

        expect(updatedPlaylist.currentIndex, equals(playlist.currentIndex));
        expect(updatedPlaylist, equals(playlist));
      });

      test('should move to next episode with none repeat mode', () {
        final playlist = Playlist.fromEpisodes('Test', testEpisodes)
            .copyWith(currentIndex: 0, repeatMode: PlaylistRepeatMode.none);

        final updatedPlaylist = playlist.moveToNext();

        expect(updatedPlaylist.currentIndex, equals(1));
        expect(updatedPlaylist.updatedAt.isAfter(playlist.updatedAt), isTrue);
      });

      test('should stay at current when at end with none repeat mode', () {
        final playlist = Playlist.fromEpisodes('Test', testEpisodes)
            .copyWith(currentIndex: 2, repeatMode: PlaylistRepeatMode.none);

        final updatedPlaylist = playlist.moveToNext();

        expect(updatedPlaylist.currentIndex, equals(2)); // Stay at current
      });

      test('should wrap to beginning with playlist repeat mode', () {
        final playlist = Playlist.fromEpisodes('Test', testEpisodes)
            .copyWith(currentIndex: 2, repeatMode: PlaylistRepeatMode.playlist);

        final updatedPlaylist = playlist.moveToNext();

        expect(updatedPlaylist.currentIndex, equals(0));
      });

      test('should stay at current with single repeat mode', () {
        final playlist = Playlist.fromEpisodes('Test', testEpisodes)
            .copyWith(currentIndex: 1, repeatMode: PlaylistRepeatMode.single);

        final updatedPlaylist = playlist.moveToNext();

        expect(updatedPlaylist.currentIndex, equals(1));
      });

      test('should move to previous episode with none repeat mode', () {
        final playlist = Playlist.fromEpisodes('Test', testEpisodes)
            .copyWith(currentIndex: 2, repeatMode: PlaylistRepeatMode.none);

        final updatedPlaylist = playlist.moveToPrevious();

        expect(updatedPlaylist.currentIndex, equals(1));
        expect(updatedPlaylist.updatedAt.isAfter(playlist.updatedAt), isTrue);
      });

      test('should stay at current when at beginning with none repeat mode',
          () {
        final playlist = Playlist.fromEpisodes('Test', testEpisodes)
            .copyWith(currentIndex: 0, repeatMode: PlaylistRepeatMode.none);

        final updatedPlaylist = playlist.moveToPrevious();

        expect(updatedPlaylist.currentIndex, equals(0)); // Stay at current
      });

      test('should wrap to end with playlist repeat mode', () {
        final playlist = Playlist.fromEpisodes('Test', testEpisodes)
            .copyWith(currentIndex: 0, repeatMode: PlaylistRepeatMode.playlist);

        final updatedPlaylist = playlist.moveToPrevious();

        expect(updatedPlaylist.currentIndex, equals(2));
      });

      test('should handle navigation with empty playlist', () {
        final emptyPlaylist = Playlist.empty('Empty');

        final nextPlaylist = emptyPlaylist.moveToNext();
        final previousPlaylist = emptyPlaylist.moveToPrevious();

        expect(nextPlaylist, equals(emptyPlaylist));
        expect(previousPlaylist, equals(emptyPlaylist));
      });
    });

    group('Mode Toggle Tests', () {
      test('should toggle shuffle mode', () {
        final playlist = Playlist.fromEpisodes('Test', testEpisodes);

        final shuffledPlaylist = playlist.toggleShuffle();
        expect(shuffledPlaylist.shuffleEnabled, isTrue);
        expect(shuffledPlaylist.updatedAt.isAfter(playlist.updatedAt), isTrue);

        final unshuffledPlaylist = shuffledPlaylist.toggleShuffle();
        expect(unshuffledPlaylist.shuffleEnabled, isFalse);
      });

      test('should set repeat mode', () {
        final playlist = Playlist.fromEpisodes('Test', testEpisodes);

        final playlistRepeat =
            playlist.setRepeatMode(PlaylistRepeatMode.playlist);
        expect(playlistRepeat.repeatMode, equals(PlaylistRepeatMode.playlist));
        expect(playlistRepeat.updatedAt.isAfter(playlist.updatedAt), isTrue);

        final singleRepeat =
            playlistRepeat.setRepeatMode(PlaylistRepeatMode.single);
        expect(singleRepeat.repeatMode, equals(PlaylistRepeatMode.single));

        final noRepeat = singleRepeat.setRepeatMode(PlaylistRepeatMode.none);
        expect(noRepeat.repeatMode, equals(PlaylistRepeatMode.none));
      });
    });

    group('Equatable Tests', () {
      test('should compare playlists correctly', () {
        final playlist1 = Playlist.fromEpisodes('Test', testEpisodes);
        final playlist2 = Playlist.fromEpisodes('Test', testEpisodes);
        final playlist3 = playlist1.copyWith(name: 'Different Name');

        expect(playlist1 == playlist2, isFalse); // Different IDs
        expect(playlist1 == playlist3, isFalse); // Different names
        expect(playlist1 == playlist1, isTrue); // Same object
      });

      test('should have consistent hash codes', () {
        final playlist = Playlist.fromEpisodes('Test', testEpisodes);
        final samePlaylist = playlist.copyWith();

        expect(playlist.hashCode, equals(samePlaylist.hashCode));
      });
    });

    group('toString Tests', () {
      test('should format toString correctly', () {
        final playlist = Playlist.fromEpisodes('Test Playlist', testEpisodes)
            .copyWith(currentIndex: 1);

        final stringRepresentation = playlist.toString();

        expect(stringRepresentation, contains('Test Playlist'));
        expect(stringRepresentation, contains('episodes: 3'));
        expect(stringRepresentation, contains('currentIndex: 1'));
      });
    });
  });

  group('PlaylistRepeatMode Tests', () {
    test('should create from string correctly', () {
      expect(PlaylistRepeatMode.fromString('none'),
          equals(PlaylistRepeatMode.none));
      expect(PlaylistRepeatMode.fromString('playlist'),
          equals(PlaylistRepeatMode.playlist));
      expect(PlaylistRepeatMode.fromString('single'),
          equals(PlaylistRepeatMode.single));
      expect(PlaylistRepeatMode.fromString('PLAYLIST'),
          equals(PlaylistRepeatMode.playlist));
      expect(PlaylistRepeatMode.fromString('invalid'),
          equals(PlaylistRepeatMode.none));
      expect(
          PlaylistRepeatMode.fromString(''), equals(PlaylistRepeatMode.none));
    });

    test('should convert to string correctly', () {
      expect(PlaylistRepeatMode.none.toString(), equals('none'));
      expect(PlaylistRepeatMode.playlist.toString(), equals('playlist'));
      expect(PlaylistRepeatMode.single.toString(), equals('single'));
    });

    test('should have correct display names', () {
      expect(PlaylistRepeatMode.none.displayName, equals('No Repeat'));
      expect(PlaylistRepeatMode.playlist.displayName, equals('Repeat All'));
      expect(PlaylistRepeatMode.single.displayName, equals('Repeat One'));
    });

    test('should have correct icons', () {
      expect(PlaylistRepeatMode.none.icon, equals('🔁'));
      expect(PlaylistRepeatMode.playlist.icon, equals('🔂'));
      expect(PlaylistRepeatMode.single.icon, equals('🔂'));
    });

    test('should have correct enum values', () {
      expect(PlaylistRepeatMode.values, hasLength(3));
      expect(PlaylistRepeatMode.values, contains(PlaylistRepeatMode.none));
      expect(PlaylistRepeatMode.values, contains(PlaylistRepeatMode.playlist));
      expect(PlaylistRepeatMode.values, contains(PlaylistRepeatMode.single));
    });
  });
}
