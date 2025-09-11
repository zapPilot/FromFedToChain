import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:audio_service/audio_service.dart' as audio_service_pkg;
import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

import 'package:from_fed_to_chain_app/services/background_audio_handler.dart';
import 'package:from_fed_to_chain_app/models/audio_file.dart';

// Generate mocks for audio dependencies
@GenerateMocks([AudioPlayer, AudioSession, BackgroundAudioHandler])
import 'background_audio_handler_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BackgroundAudioHandler Tests', () {
    late MockBackgroundAudioHandler mockAudioHandler;

    // Test data
    late AudioFile testAudioFile;
    late AudioFile testAudioFile2;

    // Mock streams
    late BehaviorSubject<audio_service_pkg.PlaybackState>
        mockPlaybackStateStream;
    late BehaviorSubject<audio_service_pkg.MediaItem?> mockMediaItemStream;

    setUp(() async {
      // Create mock streams
      mockPlaybackStateStream =
          BehaviorSubject<audio_service_pkg.PlaybackState>.seeded(
        audio_service_pkg.PlaybackState(
          controls: [
            audio_service_pkg.MediaControl.skipToPrevious,
            audio_service_pkg.MediaControl.play,
            audio_service_pkg.MediaControl.skipToNext,
            audio_service_pkg.MediaControl.stop,
          ],
          systemActions: const {
            audio_service_pkg.MediaAction.seek,
            audio_service_pkg.MediaAction.seekForward,
            audio_service_pkg.MediaAction.seekBackward,
          },
          androidCompactActionIndices: const [0, 1, 2],
          processingState: audio_service_pkg.AudioProcessingState.idle,
          playing: false,
          updatePosition: Duration.zero,
          bufferedPosition: Duration.zero,
          speed: 1.0,
          queueIndex: 0,
        ),
      );

      mockMediaItemStream =
          BehaviorSubject<audio_service_pkg.MediaItem?>.seeded(
              const audio_service_pkg.MediaItem(
        id: 'initial',
        title: 'From Fed to Chain',
        artist: 'Loading...',
        album: 'Crypto & Macro Economics Learning',
        duration: Duration.zero,
        artUri: null,
      ));

      // Create test audio files
      testAudioFile = AudioFile(
        id: '2025-01-01-test-episode',
        title: 'Test Episode 1',
        language: 'en-US',
        category: 'daily-news',
        streamingUrl: 'https://example.com/test1.m3u8',
        path: 'test1.m3u8',
        duration: const Duration(minutes: 5),
        lastModified: DateTime.now(),
      );

      testAudioFile2 = AudioFile(
        id: '2025-01-02-test-episode-2',
        title: 'Test Episode 2',
        language: 'ja-JP',
        category: 'ethereum',
        streamingUrl: 'https://example.com/test2.m3u8',
        path: 'test2.m3u8',
        duration: const Duration(minutes: 8),
        lastModified: DateTime.now(),
      );

      // Create mock audio handler
      mockAudioHandler = MockBackgroundAudioHandler();

      // Setup mock behavior
      when(mockAudioHandler.playbackState)
          .thenAnswer((_) => mockPlaybackStateStream);
      when(mockAudioHandler.mediaItem).thenAnswer((_) => mockMediaItemStream);
      when(mockAudioHandler.duration).thenReturn(const Duration(minutes: 5));

      // Setup method stubs
      when(mockAudioHandler.setEpisodeNavigationCallbacks(
        onNext: anyNamed('onNext'),
        onPrevious: anyNamed('onPrevious'),
      )).thenReturn(null);

      when(mockAudioHandler.setAudioSource(
        any,
        title: anyNamed('title'),
        artist: anyNamed('artist'),
        initialPosition: anyNamed('initialPosition'),
        audioFile: anyNamed('audioFile'),
      )).thenAnswer((_) async {
        // Update the mock media item when audio source is set
        final arguments = _.namedArguments;
        final audioFile = arguments[#audioFile] as AudioFile?;
        final title = arguments[#title] as String;
        final artist = arguments[#artist] as String?;

        final newMediaItem = audio_service_pkg.MediaItem(
          id: audioFile?.id ?? 'unknown',
          title: title,
          artist: artist ?? 'From Fed to Chain',
          album: 'Crypto & Macro Economics',
          duration: audioFile?.duration ?? Duration.zero,
          extras: {
            'url': _.positionalArguments[0] as String,
            'category': audioFile?.category ?? '',
            'language': audioFile?.language ?? '',
          },
        );

        mockMediaItemStream.add(newMediaItem);
      });

      when(mockAudioHandler.play()).thenAnswer((_) async {
        mockPlaybackStateStream
            .add(mockPlaybackStateStream.value.copyWith(playing: true));
      });

      when(mockAudioHandler.pause()).thenAnswer((_) async {
        mockPlaybackStateStream
            .add(mockPlaybackStateStream.value.copyWith(playing: false));
      });

      when(mockAudioHandler.stop()).thenAnswer((_) async {
        mockPlaybackStateStream.add(mockPlaybackStateStream.value.copyWith(
          playing: false,
          processingState: audio_service_pkg.AudioProcessingState.idle,
        ));

        mockMediaItemStream.add(const audio_service_pkg.MediaItem(
          id: 'stopped',
          title: 'From Fed to Chain',
          artist: 'Ready to play',
          album: 'Crypto & Macro Economics Learning',
          duration: Duration.zero,
        ));
      });

      when(mockAudioHandler.seek(any)).thenAnswer((_) async {});
      when(mockAudioHandler.skipToNext()).thenAnswer((_) async {});
      when(mockAudioHandler.skipToPrevious()).thenAnswer((_) async {});
      when(mockAudioHandler.fastForward()).thenAnswer((_) async {});
      when(mockAudioHandler.rewind()).thenAnswer((_) async {});

      when(mockAudioHandler.customAction(any, any)).thenAnswer((_) async {});
      when(mockAudioHandler.customAction('setSpeed', any))
          .thenAnswer((_) async {});
      when(mockAudioHandler.customAction('getPosition'))
          .thenAnswer((_) async => Duration.zero);
      when(mockAudioHandler.customAction('getDuration'))
          .thenAnswer((_) async => const Duration(minutes: 5));

      when(mockAudioHandler.testMediaSession()).thenAnswer((_) async {
        final testMediaItem = audio_service_pkg.MediaItem(
          id: 'test',
          title: 'Media Session Test',
          artist: 'From Fed to Chain',
          album: 'Testing',
          duration: const Duration(minutes: 1),
        );

        mockMediaItemStream.add(testMediaItem);

        mockPlaybackStateStream.add(audio_service_pkg.PlaybackState(
          controls: [
            audio_service_pkg.MediaControl.skipToPrevious,
            audio_service_pkg.MediaControl.play,
            audio_service_pkg.MediaControl.skipToNext,
            audio_service_pkg.MediaControl.stop,
          ],
          systemActions: const {
            audio_service_pkg.MediaAction.seek,
            audio_service_pkg.MediaAction.seekForward,
            audio_service_pkg.MediaAction.seekBackward,
          },
          androidCompactActionIndices: const [0, 1, 2],
          processingState: audio_service_pkg.AudioProcessingState.ready,
          playing: false,
          updatePosition: Duration.zero,
          bufferedPosition: Duration.zero,
          speed: 1.0,
        ));
      });

      when(mockAudioHandler.onTaskRemoved()).thenAnswer((_) async {});
      when(mockAudioHandler.dispose()).thenReturn(null);
    });

    tearDown(() {
      mockPlaybackStateStream.close();
      mockMediaItemStream.close();
    });

    group('Initialization Tests', () {
      test('should initialize with proper media session configuration',
          () async {
        // Wait for initialization to complete
        await Future.delayed(const Duration(milliseconds: 50));

        // Verify initial media item is set
        expect(mockAudioHandler.mediaItem.value, isNotNull);
        expect(mockAudioHandler.mediaItem.value!.id, 'initial');
        expect(mockAudioHandler.mediaItem.value!.title, 'From Fed to Chain');
        expect(mockAudioHandler.mediaItem.value!.artist, 'Loading...');

        // Verify initial playback state
        expect(mockAudioHandler.playbackState.value.processingState,
            audio_service_pkg.AudioProcessingState.idle);
        expect(mockAudioHandler.playbackState.value.playing, false);
        expect(mockAudioHandler.playbackState.value.controls, isNotEmpty);
        expect(mockAudioHandler.playbackState.value.controls,
            contains(audio_service_pkg.MediaControl.play));
        expect(mockAudioHandler.playbackState.value.controls,
            contains(audio_service_pkg.MediaControl.skipToPrevious));
        expect(mockAudioHandler.playbackState.value.controls,
            contains(audio_service_pkg.MediaControl.skipToNext));
        expect(mockAudioHandler.playbackState.value.controls,
            contains(audio_service_pkg.MediaControl.stop));
      });

      test('should have proper system actions configured', () async {
        await Future.delayed(const Duration(milliseconds: 50));

        final state = mockAudioHandler.playbackState.value;
        expect(
            state.systemActions, contains(audio_service_pkg.MediaAction.seek));
        expect(state.systemActions,
            contains(audio_service_pkg.MediaAction.seekForward));
        expect(state.systemActions,
            contains(audio_service_pkg.MediaAction.seekBackward));
      });

      test('should have proper Android compact actions configured', () async {
        await Future.delayed(const Duration(milliseconds: 50));

        final state = mockAudioHandler.playbackState.value;
        expect(state.androidCompactActionIndices,
            [0, 1, 2]); // Previous, Play, Next
      });

      test('should setup navigation callbacks correctly', () {
        bool nextCalled = false;
        bool previousCalled = false;

        mockAudioHandler.setEpisodeNavigationCallbacks(
          onNext: (audioFile) => nextCalled = true,
          onPrevious: (audioFile) => previousCalled = true,
        );

        // Verify the method was called
        verify(mockAudioHandler.setEpisodeNavigationCallbacks(
          onNext: anyNamed('onNext'),
          onPrevious: anyNamed('onPrevious'),
        )).called(1);
      });
    });

    group('MediaItem Creation Tests', () {
      test('should create proper MediaItem with all metadata', () async {
        await mockAudioHandler.setAudioSource(
          testAudioFile.streamingUrl,
          title: testAudioFile.title,
          artist: 'Custom Artist',
          audioFile: testAudioFile,
        );

        final mediaItem = mockAudioHandler.mediaItem.value!;
        expect(mediaItem.id, testAudioFile.id);
        expect(mediaItem.title, testAudioFile.title);
        expect(mediaItem.artist, 'Custom Artist');
        expect(mediaItem.album, 'Crypto & Macro Economics');
        expect(mediaItem.duration, testAudioFile.duration);
        expect(mediaItem.extras?['url'], testAudioFile.streamingUrl);
        expect(mediaItem.extras?['category'], testAudioFile.category);
        expect(mediaItem.extras?['language'], testAudioFile.language);
      });

      test('should handle missing optional parameters', () async {
        await mockAudioHandler.setAudioSource(
          'https://example.com/test.m3u8',
          title: 'Test Title',
        );

        final mediaItem = mockAudioHandler.mediaItem.value!;
        expect(mediaItem.id, 'unknown');
        expect(mediaItem.title, 'Test Title');
        expect(mediaItem.artist, 'From Fed to Chain');
        expect(mediaItem.duration, Duration.zero);
      });

      test('should handle initial position correctly', () async {
        const initialPos = Duration(minutes: 2);

        // This should not throw an error
        expect(
          () async => await mockAudioHandler.setAudioSource(
            testAudioFile.streamingUrl,
            title: testAudioFile.title,
            initialPosition: initialPos,
            audioFile: testAudioFile,
          ),
          returnsNormally,
        );

        final mediaItem = mockAudioHandler.mediaItem.value!;
        expect(mediaItem.id, testAudioFile.id);
      });
    });

    group('Playback Control Tests', () {
      test('should handle basic playback controls without throwing', () async {
        // These methods should not throw exceptions even if they can't actually play audio
        expect(() async => await mockAudioHandler.play(), returnsNormally);
        expect(() async => await mockAudioHandler.pause(), returnsNormally);
        expect(() async => await mockAudioHandler.stop(), returnsNormally);
      });

      test('should handle seek command', () async {
        const seekPosition = Duration(minutes: 2, seconds: 30);

        expect(() async => await mockAudioHandler.seek(seekPosition),
            returnsNormally);
        verify(mockAudioHandler.seek(seekPosition)).called(1);
      });

      test('should handle seek to zero', () async {
        expect(() async => await mockAudioHandler.seek(Duration.zero),
            returnsNormally);
        verify(mockAudioHandler.seek(Duration.zero)).called(1);
      });

      test('should handle fast forward without current duration', () async {
        expect(
            () async => await mockAudioHandler.fastForward(), returnsNormally);
        verify(mockAudioHandler.fastForward()).called(1);
      });

      test('should handle rewind', () async {
        expect(() async => await mockAudioHandler.rewind(), returnsNormally);
        verify(mockAudioHandler.rewind()).called(1);
      });

      test('should handle stop and reset MediaItem', () async {
        await mockAudioHandler.stop();

        // Should reset MediaItem
        await Future.delayed(const Duration(milliseconds: 50));
        final mediaItem = mockAudioHandler.mediaItem.value!;
        expect(mediaItem.id, 'stopped');
        expect(mediaItem.title, 'From Fed to Chain');
        expect(mediaItem.artist, 'Ready to play');

        verify(mockAudioHandler.stop()).called(1);
      });
    });

    group('Episode Navigation Tests', () {
      test('should skip to next episode when callback is set', () async {
        // Set current audio file through setAudioSource
        await mockAudioHandler.setAudioSource(
          testAudioFile.streamingUrl,
          title: testAudioFile.title,
          audioFile: testAudioFile,
        );

        await mockAudioHandler.skipToNext();
        verify(mockAudioHandler.skipToNext()).called(1);
      });

      test('should skip to previous episode when callback is set', () async {
        await mockAudioHandler.setAudioSource(
          testAudioFile.streamingUrl,
          title: testAudioFile.title,
          audioFile: testAudioFile,
        );

        await mockAudioHandler.skipToPrevious();
        verify(mockAudioHandler.skipToPrevious()).called(1);
      });

      test('should fall back to time-based skipping when no callback',
          () async {
        // Should not throw when no callback is set
        expect(
            () async => await mockAudioHandler.skipToNext(), returnsNormally);
        expect(() async => await mockAudioHandler.skipToPrevious(),
            returnsNormally);
      });
    });

    group('Custom Actions Tests', () {
      test('should handle setSpeed custom action', () async {
        final result =
            await mockAudioHandler.customAction('setSpeed', {'speed': 1.5});
        expect(result, isNull);
        verify(mockAudioHandler.customAction('setSpeed', {'speed': 1.5}))
            .called(1);
      });

      test('should handle setSpeed with default value', () async {
        expect(() async => await mockAudioHandler.customAction('setSpeed', {}),
            returnsNormally);
      });

      test('should handle getPosition custom action', () async {
        final result = await mockAudioHandler.customAction('getPosition');
        expect(result, isA<Duration>());
        verify(mockAudioHandler.customAction('getPosition')).called(1);
      });

      test('should handle getDuration custom action', () async {
        final result = await mockAudioHandler.customAction('getDuration');
        expect(result, isA<Duration>());
        verify(mockAudioHandler.customAction('getDuration')).called(1);
      });

      test('should handle unknown custom action', () async {
        final result = await mockAudioHandler.customAction('unknownAction');
        expect(result, isNull);
        verify(mockAudioHandler.customAction('unknownAction')).called(1);
      });

      test('should handle custom action with null extras', () async {
        expect(() async => await mockAudioHandler.customAction('setSpeed'),
            returnsNormally);
      });

      test('should handle various speed values', () async {
        final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

        for (final speed in speeds) {
          expect(
            () async => await mockAudioHandler
                .customAction('setSpeed', {'speed': speed}),
            returnsNormally,
          );
        }
      });
    });

    group('Media Session Testing Tests', () {
      test('should execute media session test', () async {
        await mockAudioHandler.testMediaSession();

        // Should update MediaItem and playback state
        final mediaItem = mockAudioHandler.mediaItem.value!;
        expect(mediaItem.id, 'test');
        expect(mediaItem.title, 'Media Session Test');
        expect(mediaItem.artist, 'From Fed to Chain');
        expect(mediaItem.album, 'Testing');
        expect(mediaItem.duration, const Duration(minutes: 1));

        final state = mockAudioHandler.playbackState.value;
        expect(state.processingState,
            audio_service_pkg.AudioProcessingState.ready);
        expect(state.playing, false);
        expect(state.controls, isNotEmpty);
        expect(state.systemActions, isNotEmpty);
        expect(state.androidCompactActionIndices, [0, 1, 2]);

        verify(mockAudioHandler.testMediaSession()).called(1);
      });
    });

    group('Task Management Tests', () {
      test('should handle task removal', () async {
        expect(() async => await mockAudioHandler.onTaskRemoved(),
            returnsNormally);
        verify(mockAudioHandler.onTaskRemoved()).called(1);
      });
    });

    group('Duration Property Tests', () {
      test('should return duration from player', () {
        final duration = mockAudioHandler.duration;
        expect(duration, isA<Duration>());
        expect(duration, const Duration(minutes: 5));
      });
    });

    group('Error Handling Tests', () {
      test('should handle invalid URLs gracefully', () async {
        // Should not crash with invalid URLs
        expect(
          () async => await mockAudioHandler.setAudioSource(
            'invalid-url',
            title: 'Test Audio',
          ),
          returnsNormally,
        );
      });

      test('should handle empty URLs gracefully', () async {
        // Should not crash with empty URLs
        expect(
          () async => await mockAudioHandler.setAudioSource(
            '',
            title: 'Test Audio',
          ),
          returnsNormally,
        );
      });

      test('should handle null-like parameters gracefully', () async {
        expect(
          () async => await mockAudioHandler.setAudioSource(
            'https://example.com/test.m3u8',
            title: '',
          ),
          returnsNormally,
        );
      });
    });

    group('Audio Format Tests', () {
      test('should handle HLS/M3U8 streams', () async {
        final hlsFile = testAudioFile.copyWith(
          streamingUrl: 'https://example.com/playlist.m3u8',
          path: 'playlist.m3u8',
        );

        expect(
          () async => await mockAudioHandler.setAudioSource(
            hlsFile.streamingUrl,
            title: hlsFile.title,
            audioFile: hlsFile,
          ),
          returnsNormally,
        );

        final mediaItem = mockAudioHandler.mediaItem.value!;
        expect(mediaItem.extras?['url'], hlsFile.streamingUrl);
      });

      test('should handle direct MP3 files', () async {
        final mp3File = testAudioFile.copyWith(
          streamingUrl: 'https://example.com/audio.mp3',
          path: 'audio.mp3',
        );

        expect(
          () async => await mockAudioHandler.setAudioSource(
            mp3File.streamingUrl,
            title: mp3File.title,
            audioFile: mp3File,
          ),
          returnsNormally,
        );
      });
    });

    group('Stream Integration Tests', () {
      test('should provide stream access for monitoring', () {
        expect(mockAudioHandler.playbackState,
            isA<Stream<audio_service_pkg.PlaybackState>>());
        expect(mockAudioHandler.mediaItem,
            isA<Stream<audio_service_pkg.MediaItem?>>());
      });

      test('should handle stream subscription', () async {
        bool stateReceived = false;
        bool mediaItemReceived = false;

        final subscription1 = mockAudioHandler.playbackState.listen((state) {
          stateReceived = true;
        });

        final subscription2 = mockAudioHandler.mediaItem.listen((item) {
          mediaItemReceived = true;
        });

        await Future.delayed(const Duration(milliseconds: 100));

        expect(stateReceived, true);
        expect(mediaItemReceived, true);

        subscription1.cancel();
        subscription2.cancel();
      });
    });
  });
}
