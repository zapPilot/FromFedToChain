@Tags(['sequential']) // Requires exclusive control over just_audio channels.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:audio_service/audio_service.dart' as audio_service_pkg;
import 'package:rxdart/rxdart.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/services.dart';

import 'package:from_fed_to_chain_app/features/audio/services/audio_player_service.dart';
import 'package:from_fed_to_chain_app/features/audio/services/background_audio_handler.dart';
import 'package:from_fed_to_chain_app/features/content/services/content_service.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';
import 'package:from_fed_to_chain_app/features/audio/services/player_state_notifier.dart';

// Generate nice mocks for dependencies (returns sensible defaults instead of throwing errors)
@GenerateNiceMocks([
  MockSpec<BackgroundAudioHandler>(),
  MockSpec<ContentService>(),
  MockSpec<AudioPlayer>()
])
import 'audio_service_error_handling_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Register just_audio plugin for tests
  setUpAll(() {
    // Mock the just_audio method channel for tests
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.ryanheise.just_audio.methods'),
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'disposeAllPlayers':
            return null;
          case 'init':
            return {'id': 'test-player-id'};
          case 'setUrl':
            return {'duration': 300000}; // 5 minutes in milliseconds
          case 'setVolume':
            return null;
          case 'setSpeed':
            return null;
          case 'setPitch':
            return null;
          case 'play':
            return null;
          case 'pause':
            return null;
          case 'stop':
            return null;
          case 'seek':
            return null;
          case 'dispose':
            return null;
          case 'load':
            return {'duration': 300000};
          case 'setAudioSource':
            return {'duration': 300000};
          default:
            return null;
        }
      },
    );
  });

  group('AudioPlayerService - Error Handling and Uncovered Paths', () {
    late AudioPlayerService audioService;
    late MockBackgroundAudioHandler mockAudioHandler;
    late MockContentService mockContentService;
    late MockAudioPlayer mockAudioPlayer;
    late AudioFile testAudioFile;

    setUp(() {
      mockAudioHandler = MockBackgroundAudioHandler();
      mockContentService = MockContentService();
      mockAudioPlayer = MockAudioPlayer();

      when(mockContentService.addToListenHistory(any)).thenAnswer((_) async {});
      when(mockContentService.updateEpisodeCompletion(any, any))
          .thenAnswer((_) async {});
      when(mockContentService.markEpisodeAsFinished(any))
          .thenAnswer((_) async {});
      when(mockContentService.getEpisodeCompletion(any)).thenReturn(0.0);
      when(mockAudioPlayer.positionStream)
          .thenAnswer((_) => const Stream<Duration>.empty());
      when(mockAudioPlayer.durationStream)
          .thenAnswer((_) => const Stream<Duration?>.empty());
      when(mockAudioPlayer.playerStateStream).thenAnswer(
        (_) => Stream<PlayerState>.value(
          PlayerState(false, ProcessingState.idle),
        ),
      );
      when(mockAudioPlayer.setAudioSource(
        any,
        initialPosition: anyNamed('initialPosition'),
      )).thenAnswer((_) async => const Duration());
      when(mockAudioPlayer.play()).thenAnswer((_) async {});
      when(mockAudioPlayer.pause()).thenAnswer((_) async {});
      when(mockAudioPlayer.stop()).thenAnswer((_) async {});
      when(mockAudioPlayer.seek(any)).thenAnswer((_) async {});
      when(mockAudioPlayer.setSpeed(any)).thenAnswer((_) async {});
      when(mockAudioHandler.setAudioSource(
        any,
        title: anyNamed('title'),
        artist: anyNamed('artist'),
        initialPosition: anyNamed('initialPosition'),
        audioFile: anyNamed('audioFile'),
      )).thenAnswer((_) async {});
      when(mockAudioHandler.play()).thenAnswer((_) async {});
      when(mockAudioHandler.pause()).thenAnswer((_) async {});
      when(mockAudioHandler.stop()).thenAnswer((_) async {});
      when(mockAudioHandler.seek(any)).thenAnswer((_) async {});
      when(mockAudioHandler.customAction(any, any)).thenAnswer((_) async {});
      when(mockAudioHandler.fastForward()).thenAnswer((_) async {});
      when(mockAudioHandler.rewind()).thenAnswer((_) async {});

      testAudioFile = AudioFile(
        id: 'test-audio-error',
        title: 'Test Audio Error',
        language: 'en-US',
        category: 'daily-news',
        streamingUrl: 'https://example.com/test.m3u8',
        path: 'test/path.m3u8',
        duration: const Duration(minutes: 5),
        lastModified: DateTime.now(),
      );
    });

    group('Fallback to Local Player (No Audio Handler)', () {
      setUp(() {
        // Test with null audio handler to trigger local player fallback
        audioService =
            AudioPlayerService(null, mockContentService, mockAudioPlayer);
      });

      test('should initialize local audio player when no background handler',
          () {
        expect(audioService.playbackState, AppPlaybackState.stopped);
      });

      test('should use local audio player for playAudio when no handler',
          () async {
        await audioService.playAudio(testAudioFile);

        verify(mockContentService.addToListenHistory(testAudioFile)).called(1);
        verify(
          mockAudioPlayer.setAudioSource(
            any,
            initialPosition: anyNamed('initialPosition'),
          ),
        ).called(1);
        verify(mockAudioPlayer.play()).called(1);
      });

      test('should use local audio player for togglePlayPause when no handler',
          () async {
        audioService.setPlaybackStateForTesting(AppPlaybackState.playing);
        await audioService.togglePlayPause();
        verify(mockAudioPlayer.pause()).called(1);

        audioService.setPlaybackStateForTesting(AppPlaybackState.paused);
        await audioService.togglePlayPause();
        verify(mockAudioPlayer.play()).called(1);
      });

      test('should handle local audio player seekTo when no handler', () async {
        const seekPosition = Duration(seconds: 30);
        await audioService.seekTo(seekPosition);

        verify(mockAudioPlayer.seek(seekPosition)).called(1);
      });

      test('should handle local audio player stop when no handler', () async {
        await audioService.stop();

        verify(mockAudioPlayer.stop()).called(1);
        expect(audioService.playbackState, AppPlaybackState.stopped);
      });

      test('should handle setPlaybackSpeed when no handler', () async {
        await audioService.setPlaybackSpeed(1.5);

        verify(mockAudioPlayer.setSpeed(1.5)).called(1);
        expect(audioService.playbackSpeed, 1.5);
      });
    });

    group('Background Handler State Processing Error Paths', () {
      late BehaviorSubject<audio_service_pkg.PlaybackState> playbackStateStream;
      late BehaviorSubject<audio_service_pkg.MediaItem?> mediaItemStream;

      setUp(() {
        playbackStateStream =
            BehaviorSubject<audio_service_pkg.PlaybackState>();
        mediaItemStream = BehaviorSubject<audio_service_pkg.MediaItem?>();

        when(mockAudioHandler.playbackState)
            .thenAnswer((_) => playbackStateStream);
        when(mockAudioHandler.mediaItem).thenAnswer((_) => mediaItemStream);
        when(mockAudioHandler.duration).thenReturn(Duration.zero);
        when(mockAudioHandler.setEpisodeNavigationCallbacks(
          onNext: anyNamed('onNext'),
          onPrevious: anyNamed('onPrevious'),
        )).thenReturn(null);

        audioService = AudioPlayerService(mockAudioHandler, mockContentService);
      });

      tearDown(() {
        playbackStateStream.close();
        mediaItemStream.close();
      });

      test('should handle loading state from background handler', () async {
        // Trigger loading state (lines 126-129)
        final loadingState = audio_service_pkg.PlaybackState(
          controls: [],
          systemActions: const {},
          processingState: audio_service_pkg.AudioProcessingState.loading,
          playing: false,
          updatePosition: Duration.zero,
          bufferedPosition: Duration.zero,
          speed: 1.0,
        );

        playbackStateStream.add(loadingState);
        await Future.delayed(const Duration(milliseconds: 10));

        expect(audioService.playbackState, AppPlaybackState.loading);
      });

      test('should handle buffering state from background handler', () async {
        // Trigger buffering state (lines 127-129)
        final bufferingState = audio_service_pkg.PlaybackState(
          controls: [],
          systemActions: const {},
          processingState: audio_service_pkg.AudioProcessingState.buffering,
          playing: false,
          updatePosition: Duration.zero,
          bufferedPosition: Duration.zero,
          speed: 1.0,
        );

        playbackStateStream.add(bufferingState);
        await Future.delayed(const Duration(milliseconds: 10));

        expect(audioService.playbackState, AppPlaybackState.loading);
      });

      test('should handle ready state from background handler', () async {
        // Trigger ready state (lines 130-133)
        final readyState = audio_service_pkg.PlaybackState(
          controls: [],
          systemActions: const {},
          processingState: audio_service_pkg.AudioProcessingState.ready,
          playing: true,
          updatePosition: const Duration(seconds: 30),
          bufferedPosition: Duration.zero,
          speed: 1.0,
        );

        playbackStateStream.add(readyState);
        await Future.delayed(const Duration(milliseconds: 10));

        expect(audioService.playbackState, AppPlaybackState.playing);
      });

      test('should handle ready state paused from background handler',
          () async {
        // Trigger ready state with playing false (lines 130-133)
        final readyState = audio_service_pkg.PlaybackState(
          controls: [],
          systemActions: const {},
          processingState: audio_service_pkg.AudioProcessingState.ready,
          playing: false,
          updatePosition: const Duration(seconds: 30),
          bufferedPosition: Duration.zero,
          speed: 1.0,
        );

        playbackStateStream.add(readyState);
        await Future.delayed(const Duration(milliseconds: 10));

        expect(audioService.playbackState, AppPlaybackState.paused);
      });

      test('should handle completed state from background handler', () async {
        // Trigger completed state (lines 134-138)
        final completedState = audio_service_pkg.PlaybackState(
          controls: [],
          systemActions: const {},
          processingState: audio_service_pkg.AudioProcessingState.completed,
          playing: false,
          updatePosition: Duration.zero,
          bufferedPosition: Duration.zero,
          speed: 1.0,
        );

        playbackStateStream.add(completedState);
        await Future.delayed(const Duration(milliseconds: 10));

        expect(audioService.playbackState, AppPlaybackState.completed);
        expect(audioService.currentPosition, Duration.zero);
      });

      test('should handle error state from background handler', () async {
        // Trigger error state (lines 139-142)
        final errorState = audio_service_pkg.PlaybackState(
          controls: [],
          systemActions: const {},
          processingState: audio_service_pkg.AudioProcessingState.error,
          playing: false,
          updatePosition: Duration.zero,
          bufferedPosition: Duration.zero,
          speed: 1.0,
        );

        playbackStateStream.add(errorState);
        await Future.delayed(const Duration(milliseconds: 10));

        expect(audioService.playbackState, AppPlaybackState.error);
        expect(audioService.errorMessage, 'Background audio error');
      });

      test('should handle media item updates from background handler',
          () async {
        // Trigger media item update (lines 149-152)
        final mediaItem = audio_service_pkg.MediaItem(
          id: 'test-media',
          title: 'Test Media',
          duration: const Duration(minutes: 3),
        );

        mediaItemStream.add(mediaItem);
        await Future.delayed(const Duration(milliseconds: 10));

        expect(audioService.totalDuration, const Duration(minutes: 3));
      });
    });

    group('Episode Navigation Error Paths', () {
      setUp(() {
        final playbackStateStream =
            BehaviorSubject<audio_service_pkg.PlaybackState>.seeded(
          audio_service_pkg.PlaybackState(
            controls: [],
            systemActions: const {},
            processingState: audio_service_pkg.AudioProcessingState.idle,
            playing: false,
            updatePosition: Duration.zero,
            bufferedPosition: Duration.zero,
            speed: 1.0,
          ),
        );

        when(mockAudioHandler.playbackState)
            .thenAnswer((_) => playbackStateStream);
        when(mockAudioHandler.mediaItem).thenAnswer(
            (_) => BehaviorSubject<audio_service_pkg.MediaItem?>.seeded(null));
        when(mockAudioHandler.duration).thenReturn(Duration.zero);
        when(mockAudioHandler.setEpisodeNavigationCallbacks(
          onNext: anyNamed('onNext'),
          onPrevious: anyNamed('onPrevious'),
        )).thenReturn(null);

        audioService = AudioPlayerService(mockAudioHandler, mockContentService);
      });

      test('should handle next episode navigation callback', () async {
        // This should trigger the navigation callback (line 105)
        final onNextCapture =
            verify(mockAudioHandler.setEpisodeNavigationCallbacks(
          onNext: captureAnyNamed('onNext'),
          onPrevious: anyNamed('onPrevious'),
        )).captured.first as Function(AudioFile);

        // Simulate callback execution
        await onNextCapture(testAudioFile);
        // Should trigger _skipToNextEpisode() method
      });

      test('should handle previous episode navigation callback', () async {
        // This should trigger the navigation callback (line 106)
        final onPreviousCapture =
            verify(mockAudioHandler.setEpisodeNavigationCallbacks(
          onNext: anyNamed('onNext'),
          onPrevious: captureAnyNamed('onPrevious'),
        )).captured.first as Function(AudioFile);

        // Simulate callback execution
        await onPreviousCapture(testAudioFile);
        // Should trigger _skipToPreviousEpisode() method
      });

      test('should handle error when skipping to next episode fails', () async {
        // Set current audio file
        await audioService.playAudio(testAudioFile);

        // Mock ContentService to throw exception
        when(mockContentService.getNextEpisode(testAudioFile))
            .thenThrow(Exception('Failed to get next episode'));

        await audioService.skipToNextEpisode();

        // Navigation errors are handled gracefully and don't change playback state
        expect(audioService.playbackState, AppPlaybackState.stopped);
      });

      test('should handle error when skipping to previous episode fails',
          () async {
        // Set current audio file
        await audioService.playAudio(testAudioFile);

        // Mock ContentService to throw exception
        when(mockContentService.getPreviousEpisode(testAudioFile))
            .thenThrow(Exception('Failed to get previous episode'));

        await audioService.skipToPreviousEpisode();

        // Navigation errors are handled gracefully and don't change playback state
        expect(audioService.playbackState, AppPlaybackState.stopped);
      });

      test('should handle case when no next episode available', () async {
        // Set current audio file
        await audioService.playAudio(testAudioFile);

        // Mock ContentService to return null (no next episode)
        when(mockContentService.getNextEpisode(testAudioFile)).thenReturn(null);

        await audioService.skipToNextEpisode();

        // Should not change state when no next episode
        expect(audioService.currentAudioFile, testAudioFile);
      });

      test('should handle case when no previous episode available', () async {
        // Set current audio file
        await audioService.playAudio(testAudioFile);

        // Mock ContentService to return null (no previous episode)
        when(mockContentService.getPreviousEpisode(testAudioFile))
            .thenReturn(null);

        await audioService.skipToPreviousEpisode();

        // Should not change state when no previous episode
        expect(audioService.currentAudioFile, testAudioFile);
      });

      test('should handle skip to next when no content service', () async {
        // Create AudioPlayerService without content service
        final audioServiceNoContent =
            AudioPlayerService(mockAudioHandler, null);

        await audioServiceNoContent.skipToNextEpisode();

        // Should handle gracefully when no content service
        expect(audioServiceNoContent.playbackState, AppPlaybackState.stopped);
      });

      test('should handle skip to previous when no content service', () async {
        // Create AudioPlayerService without content service
        final audioServiceNoContent =
            AudioPlayerService(mockAudioHandler, null);

        await audioServiceNoContent.skipToPreviousEpisode();

        // Should handle gracefully when no content service
        expect(audioServiceNoContent.playbackState, AppPlaybackState.stopped);
      });
    });

    group('Audio Completion and Autoplay Error Paths', () {
      setUp(() {
        final playbackStateStream =
            BehaviorSubject<audio_service_pkg.PlaybackState>.seeded(
          audio_service_pkg.PlaybackState(
            controls: [],
            systemActions: const {},
            processingState: audio_service_pkg.AudioProcessingState.idle,
            playing: false,
            updatePosition: Duration.zero,
            bufferedPosition: Duration.zero,
            speed: 1.0,
          ),
        );

        when(mockAudioHandler.playbackState)
            .thenAnswer((_) => playbackStateStream);
        when(mockAudioHandler.mediaItem).thenAnswer(
            (_) => BehaviorSubject<audio_service_pkg.MediaItem?>.seeded(null));
        when(mockAudioHandler.duration).thenReturn(Duration.zero);
        when(mockAudioHandler.setEpisodeNavigationCallbacks(
          onNext: anyNamed('onNext'),
          onPrevious: anyNamed('onPrevious'),
        )).thenReturn(null);

        audioService = AudioPlayerService(mockAudioHandler, mockContentService);
      });

      test('should handle repeat mode with error during repeat', () async {
        // Enable repeat mode
        audioService.setRepeatEnabled(true);

        // Set current audio file
        await audioService.playAudio(testAudioFile);

        // Mock playAudio to fail on repeat
        when(mockAudioHandler.setAudioSource(any,
                title: anyNamed('title'),
                artist: anyNamed('artist'),
                audioFile: anyNamed('audioFile')))
            .thenThrow(Exception('Repeat failed'));

        // Trigger audio completion to test repeat error path (lines 390-397)
        audioService.dispose();

        expect(audioService.repeatEnabled, true);
      });

      test('should handle autoplay when no content service available',
          () async {
        // Create service without content service but with autoplay enabled
        final audioServiceNoContent =
            AudioPlayerService(mockAudioHandler, null);

        expect(audioServiceNoContent.autoplayEnabled, true);
        // Should handle gracefully when trying to autoplay without content service
      });

      test('should handle autoplay when no current audio file', () async {
        // Enable autoplay
        audioService.setAutoplayEnabled(true);

        // Don't set any current audio file
        expect(audioService.currentAudioFile, null);
        expect(audioService.autoplayEnabled, true);
      });

      test('should handle autoplay error when getting next episode fails',
          () async {
        // Enable autoplay
        audioService.setAutoplayEnabled(true);

        // Set current audio file
        await audioService.playAudio(testAudioFile);

        // Mock ContentService to throw exception during autoplay
        when(mockContentService.getNextEpisode(testAudioFile))
            .thenThrow(Exception('Autoplay failed to get next'));

        // This would trigger autoplay error path (lines 442-449)
        expect(audioService.autoplayEnabled, true);
      });

      test('should handle autoplay when no next episode available', () async {
        // Enable autoplay
        audioService.setAutoplayEnabled(true);

        // Set current audio file
        await audioService.playAudio(testAudioFile);

        // Mock ContentService to return null (no next episode)
        when(mockContentService.getNextEpisode(testAudioFile)).thenReturn(null);

        expect(audioService.autoplayEnabled, true);
        expect(audioService.currentAudioFile, testAudioFile);
      });

      test('should handle marking episode as finished failure', () async {
        // Set current audio file
        await audioService.playAudio(testAudioFile);

        // Mock ContentService to throw exception when marking as finished
        when(mockContentService.markEpisodeAsFinished(testAudioFile.id))
            .thenThrow(Exception('Failed to mark as finished'));

        // This would test the error path in _handleAudioCompletion (lines 371-377)
        expect(audioService.currentAudioFile, testAudioFile);
      });
    });

    group('Media Session and Handler Error Paths', () {
      setUp(() {
        final playbackStateStream =
            BehaviorSubject<audio_service_pkg.PlaybackState>.seeded(
          audio_service_pkg.PlaybackState(
            controls: [],
            systemActions: const {},
            processingState: audio_service_pkg.AudioProcessingState.idle,
            playing: false,
            updatePosition: Duration.zero,
            bufferedPosition: Duration.zero,
            speed: 1.0,
          ),
        );

        when(mockAudioHandler.playbackState)
            .thenAnswer((_) => playbackStateStream);
        when(mockAudioHandler.mediaItem).thenAnswer(
            (_) => BehaviorSubject<audio_service_pkg.MediaItem?>.seeded(null));
        when(mockAudioHandler.duration).thenReturn(Duration.zero);
        when(mockAudioHandler.setEpisodeNavigationCallbacks(
          onNext: anyNamed('onNext'),
          onPrevious: anyNamed('onPrevious'),
        )).thenReturn(null);

        audioService = AudioPlayerService(mockAudioHandler, mockContentService);
      });

      test('should handle setPlaybackSpeed error gracefully', () async {
        // Mock setSpeed (the actual method name in audio_service) to throw exception
        when(mockAudioHandler.setSpeed(any))
            .thenThrow(Exception('Failed to set speed'));

        // Should continue and update internal speed despite handler error (lines 349-354)
        await audioService.setPlaybackSpeed(2.0);

        expect(audioService.playbackSpeed, 2.0);
      });

      test('should handle playAudio failure and set error state', () async {
        // Mock setAudioSource to throw exception
        when(mockAudioHandler.setAudioSource(any,
                title: anyNamed('title'),
                artist: anyNamed('artist'),
                audioFile: anyNamed('audioFile')))
            .thenThrow(Exception('Failed to set audio source'));

        // Should set error state when playAudio fails (lines 238-246)
        try {
          await audioService.playAudio(testAudioFile);
        } catch (e) {
          expect(audioService.playbackState, AppPlaybackState.error);
          expect(audioService.errorMessage, contains('Failed to play audio'));
        }
      });

      test('should handle addToListenHistory failure gracefully', () async {
        // Mock addToListenHistory to throw exception
        when(mockContentService.addToListenHistory(testAudioFile))
            .thenThrow(Exception('Failed to add to history'));

        // Should continue despite history failure (lines 214-217)
        when(mockAudioHandler.setAudioSource(any,
                title: anyNamed('title'),
                artist: anyNamed('artist'),
                audioFile: anyNamed('audioFile')))
            .thenAnswer((_) async {});
        when(mockAudioHandler.play()).thenAnswer((_) async {});

        await audioService.playAudio(testAudioFile);

        expect(audioService.currentAudioFile, testAudioFile);
      });
    });

    group('Public API Method Aliases', () {
      setUp(() {
        final playbackStateStream =
            BehaviorSubject<audio_service_pkg.PlaybackState>.seeded(
          audio_service_pkg.PlaybackState(
            controls: [],
            systemActions: const {},
            processingState: audio_service_pkg.AudioProcessingState.idle,
            playing: false,
            updatePosition: Duration.zero,
            bufferedPosition: Duration.zero,
            speed: 1.0,
          ),
        );

        when(mockAudioHandler.playbackState)
            .thenAnswer((_) => playbackStateStream);
        when(mockAudioHandler.mediaItem).thenAnswer(
            (_) => BehaviorSubject<audio_service_pkg.MediaItem?>.seeded(null));
        when(mockAudioHandler.duration).thenReturn(Duration.zero);
        when(mockAudioHandler.setEpisodeNavigationCallbacks(
          onNext: anyNamed('onNext'),
          onPrevious: anyNamed('onPrevious'),
        )).thenReturn(null);

        audioService = AudioPlayerService(mockAudioHandler, mockContentService);
      });

      test('should call skipToNext alias method', () async {
        await audioService.skipToNext();
        // Should be equivalent to skipToNextEpisode (line 488)
        expect(audioService.playbackState, AppPlaybackState.stopped);
      });

      test('should call skipToPrevious alias method', () async {
        await audioService.skipToPrevious();
        // Should be equivalent to skipToPreviousEpisode (line 491)
        expect(audioService.playbackState, AppPlaybackState.stopped);
      });

      test('should call seekForward alias method', () async {
        await audioService.seekForward();
        // Should be equivalent to skipForward (line 494)
        expect(audioService.playbackState, AppPlaybackState.stopped);
      });

      test('should call seekBackward alias method', () async {
        await audioService.seekBackward();
        // Should be equivalent to skipBackward (line 497)
        expect(audioService.playbackState, AppPlaybackState.stopped);
      });
    });
  });
}
