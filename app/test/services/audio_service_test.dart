import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:audio_service/audio_service.dart' as audio_service_pkg;
import 'dart:async';
import 'package:rxdart/rxdart.dart';

import 'package:from_fed_to_chain_app/services/audio_service.dart';
import 'package:from_fed_to_chain_app/services/background_audio_handler.dart';
import 'package:from_fed_to_chain_app/services/content_service.dart';
import 'package:from_fed_to_chain_app/models/audio_file.dart';

// Generate mocks for dependencies
@GenerateMocks([BackgroundAudioHandler, ContentService])
import 'audio_service_test.mocks.dart';

void main() {
  // Initialize Flutter binding for AudioPlayer tests
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudioService Tests', () {
    late AudioService audioService;
    late MockBackgroundAudioHandler mockAudioHandler;
    late MockContentService mockContentService;
    late AudioFile testAudioFile;
    late AudioFile testAudioFile2;
    late AudioFile invalidAudioFile;
    late AudioFile hlsAudioFile;
    late AudioFile mp3AudioFile;

    // Test helper to track notifyListeners calls
    int notificationCount = 0;

    setUp(() {
      // Reset notification counter
      notificationCount = 0;

      // Create mock dependencies
      mockAudioHandler = MockBackgroundAudioHandler();
      mockContentService = MockContentService();

      // Set up mock streams for BackgroundAudioHandler
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

      final mediaItemStream =
          BehaviorSubject<audio_service_pkg.MediaItem?>.seeded(null);

      when(mockAudioHandler.playbackState)
          .thenAnswer((_) => playbackStateStream);
      when(mockAudioHandler.mediaItem).thenAnswer((_) => mediaItemStream);
      when(mockAudioHandler.duration).thenReturn(Duration.zero);
      when(mockAudioHandler.setEpisodeNavigationCallbacks(
        onNext: anyNamed('onNext'),
        onPrevious: anyNamed('onPrevious'),
      )).thenReturn(null);

      // Set up additional method stubs
      when(mockAudioHandler.setAudioSource(
        any,
        title: anyNamed('title'),
        artist: anyNamed('artist'),
        initialPosition: anyNamed('initialPosition'),
        audioFile: anyNamed('audioFile'),
      )).thenAnswer((_) async => {});

      when(mockAudioHandler.play()).thenAnswer((_) async => {});
      when(mockAudioHandler.pause()).thenAnswer((_) async => {});
      when(mockAudioHandler.stop()).thenAnswer((_) async => {});
      when(mockAudioHandler.seek(any)).thenAnswer((_) async => {});
      when(mockAudioHandler.skipToNext()).thenAnswer((_) async => {});
      when(mockAudioHandler.skipToPrevious()).thenAnswer((_) async => {});
      when(mockAudioHandler.fastForward()).thenAnswer((_) async => {});
      when(mockAudioHandler.rewind()).thenAnswer((_) async => {});

      // Mock customAction for speed changes and other operations
      when(mockAudioHandler.customAction(any, any)).thenAnswer((_) async => {});
      when(mockAudioHandler.customAction('setSpeed', any))
          .thenAnswer((_) async => {});
      when(mockAudioHandler.customAction('getPosition'))
          .thenAnswer((_) async => Duration.zero);
      when(mockAudioHandler.customAction('getDuration'))
          .thenAnswer((_) async => Duration.zero);

      // Mock ContentService methods (synchronous)
      when(mockContentService.getNextEpisode(any)).thenReturn(null);
      when(mockContentService.getPreviousEpisode(any)).thenReturn(null);

      // Create test audio files with different formats and properties
      testAudioFile = AudioFile(
        id: '2025-01-01-test-episode',
        title: 'Test Episode 1',
        language: 'en-US',
        category: 'daily-news',
        streamingUrl: 'https://example.com/audio1.m3u8',
        path: 'test-episode-1.m3u8',
        duration: const Duration(minutes: 5),
        lastModified: DateTime.now(),
      );

      testAudioFile2 = AudioFile(
        id: '2025-01-02-test-episode-2',
        title: 'Test Episode 2',
        language: 'en-US',
        category: 'ethereum',
        streamingUrl: 'https://example.com/audio2.m3u8',
        path: 'test-episode-2.m3u8',
        duration: const Duration(minutes: 8),
        lastModified: DateTime.now(),
      );

      // Invalid audio file for testing error cases
      invalidAudioFile = AudioFile(
        id: 'invalid-episode',
        title: 'Invalid Episode',
        language: 'en-US',
        category: 'daily-news',
        streamingUrl: '',
        path: 'invalid.m3u8',
        duration: Duration.zero,
        lastModified: DateTime.now(),
      );

      // HLS streaming audio file
      hlsAudioFile = AudioFile(
        id: '2025-01-03-hls-episode',
        title: 'HLS Streaming Episode',
        language: 'ja-JP',
        category: 'macro',
        streamingUrl: 'https://example.com/hls/playlist.m3u8',
        path: 'hls-playlist.m3u8',
        duration: const Duration(minutes: 12),
        lastModified: DateTime.now(),
      );

      // Direct MP3 audio file
      mp3AudioFile = AudioFile(
        id: '2025-01-04-mp3-episode',
        title: 'Direct MP3 Episode',
        language: 'zh-TW',
        category: 'startup',
        streamingUrl: 'https://example.com/direct/audio.mp3',
        path: 'direct-audio.mp3',
        duration: const Duration(minutes: 15),
        lastModified: DateTime.now(),
      );

      // Initialize AudioService with mocks
      audioService = AudioService(mockAudioHandler, mockContentService);

      // Track notifyListeners calls
      audioService.addListener(() {
        notificationCount++;
      });
    });

    tearDown(() {
      // Don't dispose - let tests manage their own lifecycle
      // Avoids "used after dispose" errors in shared test setup
    });

    group('Initialization Tests', () {
      test('should initialize with default state', () {
        expect(audioService.playbackState, PlaybackState.stopped);
        expect(audioService.currentAudioFile, isNull);
        expect(audioService.currentPosition, Duration.zero);
        expect(audioService.totalDuration, Duration.zero);
        expect(audioService.playbackSpeed, 1.0);
        expect(audioService.autoplayEnabled, isTrue);
        expect(audioService.repeatEnabled, isFalse);
        expect(audioService.errorMessage, isNull);
      });

      test('should initialize with null audio handler (fallback mode)',
          () async {
        final fallbackService = AudioService(null, mockContentService);

        // Wait for async initialization to complete
        await Future.delayed(Duration(milliseconds: 10));

        expect(fallbackService.playbackState, PlaybackState.stopped);
        expect(fallbackService.currentAudioFile, isNull);

        fallbackService.dispose();

        // Wait for dispose to complete
        await Future.delayed(Duration(milliseconds: 10));
      });

      test('should initialize without content service', () async {
        final serviceWithoutContent = AudioService(mockAudioHandler, null);

        // Wait for async initialization to complete
        await Future.delayed(Duration(milliseconds: 10));

        expect(serviceWithoutContent.playbackState, PlaybackState.stopped);
        expect(serviceWithoutContent.autoplayEnabled, isTrue);

        serviceWithoutContent.dispose();

        // Wait for dispose to complete
        await Future.delayed(Duration(milliseconds: 10));
      });

      test('should initialize with both dependencies null', () async {
        final minimalService = AudioService(null, null);

        // Wait for async initialization to complete
        await Future.delayed(Duration(milliseconds: 10));

        expect(minimalService.playbackState, PlaybackState.stopped);
        expect(minimalService.autoplayEnabled, isTrue);
        expect(minimalService.repeatEnabled, isFalse);

        minimalService.dispose();

        // Wait for dispose to complete
        await Future.delayed(Duration(milliseconds: 10));
      });

      test('should set up navigation callbacks when handler is present', () {
        verify(mockAudioHandler.setEpisodeNavigationCallbacks(
          onNext: anyNamed('onNext'),
          onPrevious: anyNamed('onPrevious'),
        )).called(1);
      });
    });

    group('Computed Properties Tests', () {
      test('should correctly calculate computed boolean properties', () {
        audioService.setPlaybackStateForTesting(PlaybackState.playing);
        expect(audioService.isPlaying, isTrue);
        expect(audioService.isPaused, isFalse);
        expect(audioService.isLoading, isFalse);
        expect(audioService.hasError, isFalse);
        expect(audioService.isIdle, isFalse);

        audioService.setPlaybackStateForTesting(PlaybackState.paused);
        expect(audioService.isPlaying, isFalse);
        expect(audioService.isPaused, isTrue);

        audioService.setPlaybackStateForTesting(PlaybackState.loading);
        expect(audioService.isLoading, isTrue);

        audioService.setPlaybackStateForTesting(PlaybackState.error);
        expect(audioService.hasError, isTrue);

        audioService.setPlaybackStateForTesting(PlaybackState.stopped);
        expect(audioService.isIdle, isTrue);
      });

      test('should calculate progress correctly', () {
        audioService.setDurationForTesting(const Duration(minutes: 10));
        audioService.setPositionForTesting(const Duration(minutes: 2));

        expect(audioService.progress, 0.2);
      });

      test('should handle zero duration in progress calculation', () {
        audioService.setDurationForTesting(Duration.zero);
        audioService.setPositionForTesting(const Duration(minutes: 2));

        expect(audioService.progress, 0.0);
      });

      test('should handle negative duration in progress calculation', () {
        audioService.setDurationForTesting(const Duration(milliseconds: -1000));
        audioService.setPositionForTesting(const Duration(minutes: 2));

        expect(audioService.progress, 0.0);
      });

      test('should calculate progress at boundaries correctly', () {
        audioService.setDurationForTesting(const Duration(minutes: 10));

        // Test at start
        audioService.setPositionForTesting(Duration.zero);
        expect(audioService.progress, 0.0);

        // Test at end
        audioService.setPositionForTesting(const Duration(minutes: 10));
        expect(audioService.progress, 1.0);

        // Test beyond end (should be clamped)
        audioService.setPositionForTesting(const Duration(minutes: 12));
        expect(audioService.progress, 1.0); // Progress is now clamped to 1.0
      });

      test('should format position and duration correctly', () {
        audioService
            .setPositionForTesting(const Duration(minutes: 2, seconds: 30));
        audioService.setDurationForTesting(
            const Duration(hours: 1, minutes: 15, seconds: 45));

        expect(audioService.formattedCurrentPosition, '2:30');
        expect(audioService.formattedTotalDuration, '1:15:45');
      });

      test('should format zero duration correctly', () {
        audioService.setPositionForTesting(Duration.zero);
        audioService.setDurationForTesting(Duration.zero);

        expect(audioService.formattedCurrentPosition, '0:00');
        expect(audioService.formattedTotalDuration, '0:00');
      });

      test('should format single digit seconds correctly', () {
        audioService
            .setPositionForTesting(const Duration(minutes: 2, seconds: 5));

        expect(audioService.formattedCurrentPosition, '2:05');
      });

      test('should return current audio ID', () {
        audioService.setCurrentAudioFileForTesting(testAudioFile);
        expect(audioService.currentAudioId, testAudioFile.id);

        audioService.setCurrentAudioFileForTesting(null);
        expect(audioService.currentAudioId, isNull);
      });
    });

    group('Playback Control Tests', () {
      setUp(() {
        // Setup mock behavior for audio handler
        when(mockAudioHandler.setAudioSource(any,
                title: anyNamed('title'),
                artist: anyNamed('artist'),
                audioFile: anyNamed('audioFile')))
            .thenAnswer((_) async {});
        when(mockAudioHandler.play()).thenAnswer((_) async {});
        when(mockAudioHandler.pause()).thenAnswer((_) async {});
        when(mockAudioHandler.stop()).thenAnswer((_) async {});
        when(mockAudioHandler.seek(any)).thenAnswer((_) async {});
        when(mockAudioHandler.fastForward()).thenAnswer((_) async {});
        when(mockAudioHandler.rewind()).thenAnswer((_) async {});

        when(mockContentService.addToListenHistory(any))
            .thenAnswer((_) async {});
      });

      test('should play audio successfully', () async {
        await audioService.playAudio(testAudioFile);

        expect(audioService.currentAudioFile, testAudioFile);
        expect(audioService.errorMessage, isNull);

        verify(mockAudioHandler.setAudioSource(
          testAudioFile.streamingUrl,
          title: testAudioFile.title,
          artist: 'From Fed to Chain',
          audioFile: testAudioFile,
        )).called(1);
        verify(mockAudioHandler.play()).called(1);
        verify(mockContentService.addToListenHistory(testAudioFile)).called(1);
      });

      test('should play different audio formats successfully', () async {
        // Test HLS stream
        await audioService.playAudio(hlsAudioFile);
        expect(audioService.currentAudioFile, hlsAudioFile);

        // Test direct MP3
        await audioService.playAudio(mp3AudioFile);
        expect(audioService.currentAudioFile, mp3AudioFile);

        verify(mockAudioHandler.setAudioSource(any,
                title: anyNamed('title'),
                artist: anyNamed('artist'),
                audioFile: anyNamed('audioFile')))
            .called(2);
      });

      test('should handle playAudio error gracefully', () async {
        when(mockAudioHandler.setAudioSource(any,
                title: anyNamed('title'),
                artist: anyNamed('artist'),
                audioFile: anyNamed('audioFile')))
            .thenThrow(Exception('Network error'));

        expect(audioService.playAudio(testAudioFile), throwsException);

        // Wait for async operations
        await Future.delayed(Duration.zero);

        expect(audioService.playbackState, PlaybackState.error);
        expect(audioService.errorMessage, contains('Failed to play audio'));
      });

      test('should handle specific audio codec errors', () async {
        when(mockAudioHandler.setAudioSource(any,
                title: anyNamed('title'),
                artist: anyNamed('artist'),
                audioFile: anyNamed('audioFile')))
            .thenThrow(Exception('Codec not supported'));

        expect(audioService.playAudio(testAudioFile), throwsException);

        await Future.delayed(Duration.zero);

        expect(audioService.playbackState, PlaybackState.error);
        expect(audioService.errorMessage, contains('Codec not supported'));
      });

      test('should handle network connectivity errors', () async {
        when(mockAudioHandler.setAudioSource(any,
                title: anyNamed('title'),
                artist: anyNamed('artist'),
                audioFile: anyNamed('audioFile')))
            .thenThrow(Exception('No internet connection'));

        expect(audioService.playAudio(testAudioFile), throwsException);

        await Future.delayed(Duration.zero);

        expect(audioService.playbackState, PlaybackState.error);
        expect(audioService.errorMessage, contains('No internet connection'));
      });

      test('should set loading state before playing', () async {
        bool wasLoading = false;
        audioService.addListener(() {
          if (audioService.playbackState == PlaybackState.loading) {
            wasLoading = true;
          }
        });

        await audioService.playAudio(testAudioFile);

        expect(wasLoading, isTrue);
      });

      test('should clear error message on successful play', () async {
        audioService.setErrorForTesting('Previous error');

        await audioService.playAudio(testAudioFile);

        expect(audioService.errorMessage, isNull);
      });

      test('should handle listen history error gracefully', () async {
        when(mockContentService.addToListenHistory(any))
            .thenThrow(Exception('History service error'));

        // Should still play audio successfully despite history error
        await audioService.playAudio(testAudioFile);

        expect(audioService.currentAudioFile, testAudioFile);
        expect(audioService.playbackState, isNot(PlaybackState.error));
      });

      test('should toggle play/pause when playing', () async {
        audioService.setPlaybackStateForTesting(PlaybackState.playing);

        await audioService.togglePlayPause();

        verify(mockAudioHandler.pause()).called(1);
      });

      test('should toggle play/pause when paused', () async {
        audioService.setPlaybackStateForTesting(PlaybackState.paused);

        await audioService.togglePlayPause();

        verify(mockAudioHandler.play()).called(1);
      });

      test('should toggle play/pause when stopped', () async {
        audioService.setPlaybackStateForTesting(PlaybackState.stopped);

        await audioService.togglePlayPause();

        verify(mockAudioHandler.play()).called(1);
      });

      test('should handle toggle play/pause during loading', () async {
        audioService.setPlaybackStateForTesting(PlaybackState.loading);

        // Should not crash and should call play
        await audioService.togglePlayPause();

        verify(mockAudioHandler.play()).called(1);
      });

      test('should seek to specific position', () async {
        const seekPosition = Duration(minutes: 2);

        await audioService.seekTo(seekPosition);

        verify(mockAudioHandler.seek(seekPosition)).called(1);
      });

      test('should seek to zero position', () async {
        await audioService.seekTo(Duration.zero);

        verify(mockAudioHandler.seek(Duration.zero)).called(1);
      });

      test('should seek to end position', () async {
        const endPosition = Duration(hours: 2);

        await audioService.seekTo(endPosition);

        verify(mockAudioHandler.seek(endPosition)).called(1);
      });

      test('should skip forward by 30 seconds', () async {
        await audioService.skipForward();

        verify(mockAudioHandler.fastForward()).called(1);
      });

      test('should skip backward by 10 seconds', () async {
        await audioService.skipBackward();

        verify(mockAudioHandler.rewind()).called(1);
      });

      test('should stop playback and reset state', () async {
        audioService.setPlaybackStateForTesting(PlaybackState.playing);
        audioService.setPositionForTesting(const Duration(minutes: 2));

        await audioService.stop();

        expect(audioService.playbackState, PlaybackState.stopped);
        expect(audioService.currentPosition, Duration.zero);
        verify(mockAudioHandler.stop()).called(1);
      });

      test('should pause playback', () async {
        await audioService.pause();
        verify(mockAudioHandler.pause()).called(1);
      });

      test('should resume playback', () async {
        await audioService.resume();
        verify(mockAudioHandler.play()).called(1);
      });

      test('should handle audio handler errors in playback controls', () async {
        when(mockAudioHandler.play()).thenThrow(Exception('Playback error'));

        // Should throw exception when handler fails
        await expectLater(audioService.resume(), throwsA(isA<Exception>()));

        // Verify the handler was called
        verify(mockAudioHandler.play()).called(1);
      });
    });

    group('Playback Speed Tests', () {
      test('should set playback speed successfully', () async {
        when(mockAudioHandler.customAction('setSpeed', {'speed': 1.5}))
            .thenAnswer((_) async {});

        await audioService.setPlaybackSpeed(1.5);

        expect(audioService.playbackSpeed, 1.5);
        verify(mockAudioHandler.customAction('setSpeed', {'speed': 1.5}))
            .called(1);
      });

      test('should notify listeners when speed changes', () async {
        when(mockAudioHandler.customAction('setSpeed', {'speed': 2.0}))
            .thenAnswer((_) async {});

        notificationCount = 0;
        await audioService.setPlaybackSpeed(2.0);

        expect(notificationCount, greaterThan(0));
      });

      test('should handle various speed values', () async {
        final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

        for (final speed in speeds) {
          when(mockAudioHandler.customAction('setSpeed', {'speed': speed}))
              .thenAnswer((_) async {});

          await audioService.setPlaybackSpeed(speed);
          expect(audioService.playbackSpeed, speed);
        }
      });

      test('should handle extreme speed values', () async {
        final extremeSpeeds = [0.1, 5.0, 10.0];

        for (final speed in extremeSpeeds) {
          when(mockAudioHandler.customAction('setSpeed', {'speed': speed}))
              .thenAnswer((_) async {});

          await audioService.setPlaybackSpeed(speed);
          expect(audioService.playbackSpeed, speed);
        }
      });

      test('should handle speed setting errors gracefully', () async {
        when(mockAudioHandler.customAction('setSpeed', {'speed': 1.5}))
            .thenThrow(Exception('Speed not supported'));

        // Should still update internal speed even if handler fails
        await audioService.setPlaybackSpeed(1.5);

        expect(audioService.playbackSpeed, 1.5);
        verify(mockAudioHandler.customAction('setSpeed', {'speed': 1.5}))
            .called(1);
      });

      test('should handle zero speed gracefully', () async {
        when(mockAudioHandler.customAction('setSpeed', {'speed': 0.0}))
            .thenAnswer((_) async {});

        await audioService.setPlaybackSpeed(0.0);

        expect(audioService.playbackSpeed, 0.0);
      });

      test('should handle negative speed gracefully', () async {
        when(mockAudioHandler.customAction('setSpeed', {'speed': -1.0}))
            .thenAnswer((_) async {});

        await audioService.setPlaybackSpeed(-1.0);

        expect(audioService.playbackSpeed, -1.0);
      });
    });

    group('Episode Navigation Tests', () {
      setUp(() {
        when(mockContentService.getNextEpisode(any)).thenReturn(testAudioFile2);
        when(mockContentService.getPreviousEpisode(any))
            .thenReturn(testAudioFile);
        when(mockAudioHandler.setAudioSource(any,
                title: anyNamed('title'),
                artist: anyNamed('artist'),
                audioFile: anyNamed('audioFile')))
            .thenAnswer((_) async {});
        when(mockAudioHandler.play()).thenAnswer((_) async {});
        when(mockContentService.addToListenHistory(any))
            .thenAnswer((_) async {});
      });

      test('should skip to next episode successfully', () async {
        audioService.setCurrentAudioFileForTesting(testAudioFile);

        await audioService.skipToNextEpisode();

        verify(mockContentService.getNextEpisode(testAudioFile)).called(1);
        verify(mockAudioHandler.setAudioSource(
          testAudioFile2.streamingUrl,
          title: testAudioFile2.title,
          artist: 'From Fed to Chain',
          audioFile: testAudioFile2,
        )).called(1);
      });

      test('should skip to previous episode successfully', () async {
        audioService.setCurrentAudioFileForTesting(testAudioFile2);

        await audioService.skipToPreviousEpisode();

        verify(mockContentService.getPreviousEpisode(testAudioFile2)).called(1);
        verify(mockAudioHandler.setAudioSource(
          testAudioFile.streamingUrl,
          title: testAudioFile.title,
          artist: 'From Fed to Chain',
          audioFile: testAudioFile,
        )).called(1);
      });

      test('should handle navigation across different categories', () async {
        audioService.setCurrentAudioFileForTesting(testAudioFile); // daily-news
        when(mockContentService.getNextEpisode(testAudioFile))
            .thenReturn(hlsAudioFile); // macro

        await audioService.skipToNextEpisode();

        expect(audioService.currentAudioFile, hlsAudioFile);
        verify(mockContentService.getNextEpisode(testAudioFile)).called(1);
      });

      test('should handle navigation across different languages', () async {
        audioService.setCurrentAudioFileForTesting(testAudioFile); // en-US
        when(mockContentService.getNextEpisode(testAudioFile))
            .thenReturn(mp3AudioFile); // zh-TW

        await audioService.skipToNextEpisode();

        expect(audioService.currentAudioFile, mp3AudioFile);
        verify(mockContentService.getNextEpisode(testAudioFile)).called(1);
      });

      test('should handle no next episode available', () async {
        when(mockContentService.getNextEpisode(any)).thenReturn(null);
        audioService.setCurrentAudioFileForTesting(testAudioFile);

        await audioService.skipToNextEpisode();

        verify(mockContentService.getNextEpisode(testAudioFile)).called(1);
        verifyNever(mockAudioHandler.setAudioSource(any,
            title: anyNamed('title'),
            artist: anyNamed('artist'),
            audioFile: anyNamed('audioFile')));
      });

      test('should handle no previous episode available', () async {
        when(mockContentService.getPreviousEpisode(any)).thenReturn(null);
        audioService.setCurrentAudioFileForTesting(testAudioFile);

        await audioService.skipToPreviousEpisode();

        verify(mockContentService.getPreviousEpisode(testAudioFile)).called(1);
        verifyNever(mockAudioHandler.setAudioSource(any,
            title: anyNamed('title'),
            artist: anyNamed('artist'),
            audioFile: anyNamed('audioFile')));
      });

      test('should handle navigation error gracefully', () async {
        when(mockContentService.getNextEpisode(any))
            .thenThrow(Exception('Navigation error'));
        audioService.setCurrentAudioFileForTesting(testAudioFile);

        await audioService.skipToNextEpisode();

        expect(audioService.playbackState, PlaybackState.error);
        expect(audioService.errorMessage,
            contains('Failed to skip to next episode'));
      });

      test('should handle content service timeout during navigation', () async {
        when(mockContentService.getNextEpisode(any)).thenThrow(
            TimeoutException('Navigation timeout', const Duration(seconds: 5)));
        audioService.setCurrentAudioFileForTesting(testAudioFile);

        await audioService.skipToNextEpisode();

        expect(audioService.playbackState, PlaybackState.error);
        expect(audioService.errorMessage, contains('Navigation timeout'));
      });

      test('should not navigate without content service', () async {
        final serviceWithoutContent = AudioService(mockAudioHandler, null);
        serviceWithoutContent.setCurrentAudioFileForTesting(testAudioFile);

        await serviceWithoutContent.skipToNextEpisode();

        verifyNever(mockAudioHandler.setAudioSource(any,
            title: anyNamed('title'),
            artist: anyNamed('artist'),
            audioFile: anyNamed('audioFile')));

        serviceWithoutContent.dispose();
      });

      test('should not navigate without current audio file', () async {
        await audioService.skipToNextEpisode();

        verifyNever(mockContentService.getNextEpisode(any));
        verifyNever(mockAudioHandler.setAudioSource(any,
            title: anyNamed('title'),
            artist: anyNamed('artist'),
            audioFile: anyNamed('audioFile')));
      });

      test('should handle audio handler failure during navigation', () async {
        when(mockAudioHandler.setAudioSource(any,
                title: anyNamed('title'),
                artist: anyNamed('artist'),
                audioFile: anyNamed('audioFile')))
            .thenThrow(Exception('Audio handler failed'));

        audioService.setCurrentAudioFileForTesting(testAudioFile);

        await audioService.skipToNextEpisode();

        expect(audioService.playbackState, PlaybackState.error);
        expect(audioService.errorMessage,
            contains('Failed to skip to next episode'));
      });
    });

    group('User Preferences Tests', () {
      test('should set autoplay enabled', () {
        notificationCount = 0;
        audioService.setAutoplayEnabled(false);

        expect(audioService.autoplayEnabled, isFalse);
        expect(notificationCount, greaterThan(0));
      });

      test('should not notify if autoplay setting unchanged', () {
        audioService.setAutoplayEnabled(true); // Already true by default
        notificationCount = 0;
        audioService.setAutoplayEnabled(true);

        expect(notificationCount, 0);
      });

      test('should set repeat enabled', () {
        notificationCount = 0;
        audioService.setRepeatEnabled(true);

        expect(audioService.repeatEnabled, isTrue);
        expect(notificationCount, greaterThan(0));
      });

      test('should not notify if repeat setting unchanged', () {
        audioService.setRepeatEnabled(false); // Already false by default
        notificationCount = 0;
        audioService.setRepeatEnabled(false);

        expect(notificationCount, 0);
      });

      test('should toggle autoplay', () {
        expect(audioService.autoplayEnabled, isTrue);

        audioService.toggleAutoplay();
        expect(audioService.autoplayEnabled, isFalse);

        audioService.toggleAutoplay();
        expect(audioService.autoplayEnabled, isTrue);
      });

      test('should toggle repeat', () {
        expect(audioService.repeatEnabled, isFalse);

        audioService.toggleRepeat();
        expect(audioService.repeatEnabled, isTrue);

        audioService.toggleRepeat();
        expect(audioService.repeatEnabled, isFalse);
      });

      test('should use enableAutoplay alias', () {
        audioService.enableAutoplay(false);
        expect(audioService.autoplayEnabled, isFalse);

        audioService.enableAutoplay(true);
        expect(audioService.autoplayEnabled, isTrue);
      });

      test('should handle multiple rapid preference changes', () {
        notificationCount = 0;

        // Rapid changes should all notify
        audioService.setAutoplayEnabled(false);
        audioService.setAutoplayEnabled(true);
        audioService.setAutoplayEnabled(false);

        expect(audioService.autoplayEnabled, isFalse);
        expect(notificationCount, 3);
      });

      test('should handle preference state consistency', () {
        // Set both preferences
        audioService.setAutoplayEnabled(false);
        audioService.setRepeatEnabled(true);

        expect(audioService.autoplayEnabled, isFalse);
        expect(audioService.repeatEnabled, isTrue);

        // Toggle both
        audioService.toggleAutoplay();
        audioService.toggleRepeat();

        expect(audioService.autoplayEnabled, isTrue);
        expect(audioService.repeatEnabled, isFalse);
      });
    });

    group('Audio Completion Handling Tests', () {
      setUp(() {
        when(mockContentService.markEpisodeAsFinished(any))
            .thenAnswer((_) async {});
        when(mockContentService.getNextEpisode(any)).thenReturn(testAudioFile2);
        when(mockAudioHandler.setAudioSource(any,
                title: anyNamed('title'),
                artist: anyNamed('artist'),
                audioFile: anyNamed('audioFile')))
            .thenAnswer((_) async {});
        when(mockAudioHandler.play()).thenAnswer((_) async {});
        when(mockContentService.addToListenHistory(any))
            .thenAnswer((_) async {});
      });

      test('should handle repeat mode on completion', () async {
        audioService.setCurrentAudioFileForTesting(testAudioFile);
        audioService.setRepeatEnabled(true);

        await audioService.onEpisodeCompleted();

        verify(mockContentService.markEpisodeAsFinished(testAudioFile.id))
            .called(1);
        // Should replay current episode
        verify(mockAudioHandler.setAudioSource(
          testAudioFile.streamingUrl,
          title: testAudioFile.title,
          artist: 'From Fed to Chain',
          audioFile: testAudioFile,
        )).called(1);
      });

      test('should handle autoplay on completion', () async {
        audioService.setCurrentAudioFileForTesting(testAudioFile);
        audioService.setAutoplayEnabled(true);
        audioService.setRepeatEnabled(false);

        await audioService.onEpisodeCompleted();

        verify(mockContentService.markEpisodeAsFinished(testAudioFile.id))
            .called(1);
        verify(mockContentService.getNextEpisode(testAudioFile)).called(1);
        // Should play next episode
        verify(mockAudioHandler.setAudioSource(
          testAudioFile2.streamingUrl,
          title: testAudioFile2.title,
          artist: 'From Fed to Chain',
          audioFile: testAudioFile2,
        )).called(1);
      });

      test('should stop when autoplay disabled', () async {
        audioService.setCurrentAudioFileForTesting(testAudioFile);
        audioService.setAutoplayEnabled(false);
        audioService.setRepeatEnabled(false);

        await audioService.onEpisodeCompleted();

        verify(mockContentService.markEpisodeAsFinished(testAudioFile.id))
            .called(1);
        verifyNever(mockContentService.getNextEpisode(any));
        verifyNever(mockAudioHandler.setAudioSource(any,
            title: anyNamed('title'),
            artist: anyNamed('artist'),
            audioFile: anyNamed('audioFile')));
      });

      test('should handle repeat taking precedence over autoplay', () async {
        audioService.setCurrentAudioFileForTesting(testAudioFile);
        audioService.setAutoplayEnabled(true);
        audioService.setRepeatEnabled(true);

        await audioService.onEpisodeCompleted();

        verify(mockContentService.markEpisodeAsFinished(testAudioFile.id))
            .called(1);
        // Should not check for next episode when repeat is enabled
        verifyNever(mockContentService.getNextEpisode(any));
        // Should replay current episode
        verify(mockAudioHandler.setAudioSource(
          testAudioFile.streamingUrl,
          title: testAudioFile.title,
          artist: 'From Fed to Chain',
          audioFile: testAudioFile,
        )).called(1);
      });

      test('should handle completion without content service', () async {
        final serviceWithoutContent = AudioService(mockAudioHandler, null);
        serviceWithoutContent.setCurrentAudioFileForTesting(testAudioFile);
        serviceWithoutContent.setAutoplayEnabled(true);

        // Should complete without error
        await serviceWithoutContent.onEpisodeCompleted();

        // No content service calls should be made
        verifyNever(mockContentService.markEpisodeAsFinished(any));
        verifyNever(mockContentService.getNextEpisode(any));

        serviceWithoutContent.dispose();
      });

      test('should handle completion without current audio file', () async {
        audioService.setAutoplayEnabled(true);

        // Should complete without error
        await audioService.onEpisodeCompleted();

        // No content service calls should be made
        verifyNever(mockContentService.markEpisodeAsFinished(any));
        verifyNever(mockContentService.getNextEpisode(any));
      });

      test('should handle repeat error gracefully', () async {
        when(mockAudioHandler.setAudioSource(any,
                title: anyNamed('title'),
                artist: anyNamed('artist'),
                audioFile: anyNamed('audioFile')))
            .thenThrow(Exception('Repeat failed'));

        audioService.setCurrentAudioFileForTesting(testAudioFile);
        audioService.setRepeatEnabled(true);

        await audioService.onEpisodeCompleted();

        expect(audioService.playbackState, PlaybackState.error);
        expect(audioService.errorMessage, contains('Repeat failed'));
      });

      test('should handle autoplay error gracefully', () async {
        when(mockAudioHandler.setAudioSource(any,
                title: anyNamed('title'),
                artist: anyNamed('artist'),
                audioFile: anyNamed('audioFile')))
            .thenThrow(Exception('Autoplay failed'));

        audioService.setCurrentAudioFileForTesting(testAudioFile);
        audioService.setAutoplayEnabled(true);
        audioService.setRepeatEnabled(false);

        await audioService.onEpisodeCompleted();

        expect(audioService.playbackState, PlaybackState.error);
        expect(audioService.errorMessage, contains('Autoplay failed'));
      });

      test('should handle no next episode for autoplay', () async {
        when(mockContentService.getNextEpisode(any)).thenReturn(null);

        audioService.setCurrentAudioFileForTesting(testAudioFile);
        audioService.setAutoplayEnabled(true);
        audioService.setRepeatEnabled(false);

        await audioService.onEpisodeCompleted();

        verify(mockContentService.markEpisodeAsFinished(testAudioFile.id))
            .called(1);
        verify(mockContentService.getNextEpisode(testAudioFile)).called(1);
        // Should not attempt to play any episode
        verifyNever(mockAudioHandler.setAudioSource(any,
            title: anyNamed('title'),
            artist: anyNamed('artist'),
            audioFile: anyNamed('audioFile')));
      });

      test('should handle completion with different audio formats', () async {
        audioService.setCurrentAudioFileForTesting(hlsAudioFile);
        audioService.setRepeatEnabled(true);

        await audioService.onEpisodeCompleted();

        verify(mockContentService.markEpisodeAsFinished(hlsAudioFile.id))
            .called(1);
        verify(mockAudioHandler.setAudioSource(
          hlsAudioFile.streamingUrl,
          title: hlsAudioFile.title,
          artist: 'From Fed to Chain',
          audioFile: hlsAudioFile,
        )).called(1);
      });

      test('should handle content service failure during completion marking',
          () async {
        when(mockContentService.markEpisodeAsFinished(any))
            .thenThrow(Exception('Service unavailable'));

        audioService.setCurrentAudioFileForTesting(testAudioFile);
        audioService.setRepeatEnabled(true);

        // Should still proceed with repeat despite marking failure
        await audioService.onEpisodeCompleted();

        verify(mockContentService.markEpisodeAsFinished(testAudioFile.id))
            .called(1);
        verify(mockAudioHandler.setAudioSource(any,
                title: anyNamed('title'),
                artist: anyNamed('artist'),
                audioFile: anyNamed('audioFile')))
            .called(1);
      });

      test('should handle completion timing and delays properly', () async {
        audioService.setCurrentAudioFileForTesting(testAudioFile);
        audioService.setRepeatEnabled(true);

        final stopwatch = Stopwatch()..start();
        await audioService.onEpisodeCompleted();
        stopwatch.stop();

        // Should include the 500ms delay for repeat
        expect(stopwatch.elapsedMilliseconds, greaterThan(400));

        verify(mockAudioHandler.setAudioSource(any,
                title: anyNamed('title'),
                artist: anyNamed('artist'),
                audioFile: anyNamed('audioFile')))
            .called(1);
      });
    });

    group('Progress Tracking Tests', () {
      setUp(() {
        // updateEpisodeCompletion is void, no setup needed
      });

      test('should update progress manually', () {
        audioService.setCurrentAudioFileForTesting(testAudioFile);
        audioService.setDurationForTesting(const Duration(minutes: 10));

        notificationCount = 0;
        audioService.updateProgress(const Duration(minutes: 2));

        expect(audioService.currentPosition, const Duration(minutes: 2));
        expect(notificationCount, greaterThan(0));
      });

      test('should save playback state', () {
        audioService.setCurrentAudioFileForTesting(testAudioFile);
        audioService.setDurationForTesting(const Duration(minutes: 10));
        audioService.setPositionForTesting(const Duration(minutes: 2));

        audioService.savePlaybackState();

        verify(mockContentService.updateEpisodeCompletion(
                testAudioFile.id, 0.2))
            .called(1);
      });

      test('should handle save without content service', () async {
        final serviceWithoutContent = AudioService(mockAudioHandler, null);

        // Wait for async initialization to complete
        await Future.delayed(Duration(milliseconds: 10));

        serviceWithoutContent.setCurrentAudioFileForTesting(testAudioFile);

        // Should complete without error
        serviceWithoutContent.savePlaybackState();

        verifyNever(mockContentService.updateEpisodeCompletion(any, any));

        serviceWithoutContent.dispose();

        // Wait for dispose to complete
        await Future.delayed(Duration(milliseconds: 10));
      });

      test('should restore playback position', () async {
        when(mockContentService.getEpisodeCompletion(testAudioFile.id))
            .thenReturn(0.3);

        audioService.setDurationForTesting(const Duration(minutes: 10));
        notificationCount = 0;

        await audioService.restorePlaybackPosition(testAudioFile);

        expect(audioService.currentPosition, const Duration(minutes: 3));
        expect(notificationCount, greaterThan(0));
      });

      test('should handle restore without content service', () async {
        final serviceWithoutContent = AudioService(mockAudioHandler, null);

        // Should complete without error
        await serviceWithoutContent.restorePlaybackPosition(testAudioFile);

        verifyNever(mockContentService.getEpisodeCompletion(any));

        serviceWithoutContent.dispose();
      });

      test('should not restore position for zero completion', () async {
        when(mockContentService.getEpisodeCompletion(testAudioFile.id))
            .thenReturn(0.0);

        audioService.setDurationForTesting(const Duration(minutes: 10));
        audioService.setPositionForTesting(const Duration(minutes: 1));

        await audioService.restorePlaybackPosition(testAudioFile);

        // Position should remain unchanged
        expect(audioService.currentPosition, const Duration(minutes: 1));
      });

      test('should handle extreme progress values', () {
        audioService.setCurrentAudioFileForTesting(testAudioFile);
        audioService.setDurationForTesting(const Duration(minutes: 10));

        // Test beyond 100% progress
        audioService.updateProgress(const Duration(minutes: 15));
        expect(audioService.currentPosition, const Duration(minutes: 15));

        // Test negative progress
        audioService.updateProgress(const Duration(minutes: -1));
        expect(audioService.currentPosition, const Duration(minutes: -1));
      });

      test('should handle save state with zero duration', () {
        audioService.setCurrentAudioFileForTesting(testAudioFile);
        audioService.setDurationForTesting(Duration.zero);
        audioService.setPositionForTesting(const Duration(minutes: 2));

        audioService.savePlaybackState();

        verify(mockContentService.updateEpisodeCompletion(
                testAudioFile.id, 0.0))
            .called(1);
      });

      test('should handle save state without current audio', () {
        audioService.setDurationForTesting(const Duration(minutes: 10));
        audioService.setPositionForTesting(const Duration(minutes: 2));

        // Should complete without error
        audioService.savePlaybackState();

        verifyNever(mockContentService.updateEpisodeCompletion(any, any));
      });

      test('should restore position with boundary values', () async {
        when(mockContentService.getEpisodeCompletion(testAudioFile.id))
            .thenReturn(1.0); // 100% completion

        audioService.setDurationForTesting(const Duration(minutes: 10));

        await audioService.restorePlaybackPosition(testAudioFile);

        expect(audioService.currentPosition, const Duration(minutes: 10));
      });

      test('should handle restore with invalid completion values', () async {
        when(mockContentService.getEpisodeCompletion(testAudioFile.id))
            .thenReturn(-0.5); // Invalid negative completion

        audioService.setDurationForTesting(const Duration(minutes: 10));
        audioService.setPositionForTesting(Duration.zero);

        await audioService.restorePlaybackPosition(testAudioFile);

        // Should not restore negative position
        expect(audioService.currentPosition, Duration.zero);
      });
    });

    group('Error Handling Tests', () {
      test('should handle playback error', () {
        const errorMessage = 'Network connection failed';
        notificationCount = 0;

        audioService.handlePlaybackError(errorMessage);

        expect(audioService.playbackState, PlaybackState.error);
        expect(audioService.errorMessage, errorMessage);
        expect(notificationCount, greaterThan(0));
      });

      test('should handle network timeout', () {
        notificationCount = 0;

        audioService.handleNetworkTimeout();

        expect(audioService.playbackState, PlaybackState.error);
        expect(audioService.errorMessage, 'Network timeout occurred');
        expect(notificationCount, greaterThan(0));
      });

      test('should handle invalid URL', () {
        notificationCount = 0;

        audioService.handleInvalidUrl(testAudioFile);

        expect(audioService.playbackState, PlaybackState.error);
        expect(audioService.errorMessage,
            'Invalid audio URL: ${testAudioFile.streamingUrl}');
        expect(notificationCount, greaterThan(0));
      });

      test('should handle SSL certificate errors', () {
        const sslError = 'SSL certificate verification failed';

        audioService.handlePlaybackError(sslError);

        expect(audioService.playbackState, PlaybackState.error);
        expect(audioService.errorMessage, sslError);
      });

      test('should handle audio format not supported errors', () {
        const formatError = 'Audio format not supported by platform';

        audioService.handlePlaybackError(formatError);

        expect(audioService.playbackState, PlaybackState.error);
        expect(audioService.errorMessage, formatError);
      });

      test('should handle insufficient storage errors', () {
        const storageError = 'Insufficient storage for buffering';

        audioService.handlePlaybackError(storageError);

        expect(audioService.playbackState, PlaybackState.error);
        expect(audioService.errorMessage, storageError);
      });

      test('should clear error for testing', () {
        audioService.setErrorForTesting('Test error');
        expect(audioService.playbackState, PlaybackState.error);
        expect(audioService.errorMessage, 'Test error');

        notificationCount = 0;
        audioService.clearErrorForTesting();

        expect(audioService.playbackState, PlaybackState.stopped);
        expect(audioService.errorMessage, isNull);
        expect(notificationCount, greaterThan(0));
      });

      test('should handle multiple consecutive errors', () {
        audioService.handlePlaybackError('Error 1');
        expect(audioService.errorMessage, 'Error 1');

        audioService.handlePlaybackError('Error 2');
        expect(audioService.errorMessage, 'Error 2');

        audioService.handleNetworkTimeout();
        expect(audioService.errorMessage, 'Network timeout occurred');
      });

      test('should handle empty error messages', () {
        audioService.handlePlaybackError('');

        expect(audioService.playbackState, PlaybackState.error);
        expect(audioService.errorMessage, '');
      });

      test('should handle null-like error conditions', () {
        audioService.handleInvalidUrl(invalidAudioFile);

        expect(audioService.playbackState, PlaybackState.error);
        expect(audioService.errorMessage, contains('Invalid audio URL: '));
      });
    });

    group('Audio File Validation Tests', () {
      test('should validate valid audio file', () {
        expect(audioService.isValidAudioFile(testAudioFile), isTrue);
      });

      test('should validate HLS audio file', () {
        expect(audioService.isValidAudioFile(hlsAudioFile), isTrue);
      });

      test('should validate MP3 audio file', () {
        expect(audioService.isValidAudioFile(mp3AudioFile), isTrue);
      });

      test('should invalidate null audio file', () {
        expect(audioService.isValidAudioFile(null), isFalse);
      });

      test('should invalidate audio file with empty URL', () {
        expect(audioService.isValidAudioFile(invalidAudioFile), isFalse);
      });

      test('should invalidate audio file with whitespace-only URL', () {
        final whitespaceAudioFile = testAudioFile.copyWith(streamingUrl: '   ');
        expect(audioService.isValidAudioFile(whitespaceAudioFile), isFalse);
      });

      test('should validate audio files with different URL schemes', () {
        final httpFile = testAudioFile.copyWith(
            streamingUrl: 'http://example.com/audio.m3u8');
        final httpsFile = testAudioFile.copyWith(
            streamingUrl: 'https://example.com/audio.m3u8');
        final fileFile =
            testAudioFile.copyWith(streamingUrl: 'file:///local/audio.mp3');

        expect(audioService.isValidAudioFile(httpFile), isTrue);
        expect(audioService.isValidAudioFile(httpsFile), isTrue);
        expect(audioService.isValidAudioFile(fileFile), isTrue);
      });

      test('should handle validation of malformed URL gracefully', () {
        final malformedFile = testAudioFile.copyWith(streamingUrl: 'not-a-url');

        // Should still be considered valid if non-empty (URL validation is not the responsibility of this method)
        expect(audioService.isValidAudioFile(malformedFile), isTrue);
      });
    });

    group('Method Aliases Tests', () {
      setUp(() {
        when(mockAudioHandler.setAudioSource(any,
                title: anyNamed('title'),
                artist: anyNamed('artist'),
                audioFile: anyNamed('audioFile')))
            .thenAnswer((_) async {});
        when(mockAudioHandler.play()).thenAnswer((_) async {});
        when(mockContentService.addToListenHistory(any))
            .thenAnswer((_) async {});
      });

      test('should use play alias for playAudio', () async {
        await audioService.play(testAudioFile);

        verify(mockAudioHandler.setAudioSource(
          testAudioFile.streamingUrl,
          title: testAudioFile.title,
          artist: 'From Fed to Chain',
          audioFile: testAudioFile,
        )).called(1);
      });

      test('should use skipToNext alias', () async {
        when(mockContentService.getNextEpisode(any)).thenReturn(testAudioFile2);
        audioService.setCurrentAudioFileForTesting(testAudioFile);

        await audioService.skipToNext();

        verify(mockContentService.getNextEpisode(testAudioFile)).called(1);
      });

      test('should use skipToPrevious alias', () async {
        when(mockContentService.getPreviousEpisode(any))
            .thenReturn(testAudioFile);
        audioService.setCurrentAudioFileForTesting(testAudioFile2);

        await audioService.skipToPrevious();

        verify(mockContentService.getPreviousEpisode(testAudioFile2)).called(1);
      });

      test('should use seekForward alias', () async {
        await audioService.seekForward();

        verify(mockAudioHandler.fastForward()).called(1);
      });

      test('should use seekBackward alias', () async {
        await audioService.seekBackward();

        verify(mockAudioHandler.rewind()).called(1);
      });

      test('should verify all aliases work consistently', () async {
        // Test that aliases behave identically to their main methods
        when(mockContentService.getNextEpisode(any)).thenReturn(testAudioFile2);
        audioService.setCurrentAudioFileForTesting(testAudioFile);

        await audioService.skipToNext();
        await audioService.skipToNextEpisode();

        verify(mockContentService.getNextEpisode(testAudioFile)).called(2);
      });
    });

    group('State Notification Tests', () {
      test('should notify listeners on state changes', () {
        notificationCount = 0;

        audioService.setPlaybackStateForTesting(PlaybackState.playing);
        expect(notificationCount, greaterThan(0));

        notificationCount = 0;
        audioService.setCurrentAudioFileForTesting(testAudioFile);
        expect(notificationCount, greaterThan(0));

        notificationCount = 0;
        audioService.setDurationForTesting(const Duration(minutes: 5));
        expect(notificationCount, greaterThan(0));

        notificationCount = 0;
        audioService.setPositionForTesting(const Duration(minutes: 1));
        expect(notificationCount, greaterThan(0));
      });

      test('should notify on error state changes', () {
        notificationCount = 0;

        audioService.setErrorForTesting('Test error');
        expect(notificationCount, greaterThan(0));

        notificationCount = 0;
        audioService.clearErrorForTesting();
        expect(notificationCount, greaterThan(0));
      });

      test('should notify on preference changes', () {
        notificationCount = 0;

        audioService.setAutoplayEnabled(false);
        expect(notificationCount, greaterThan(0));

        notificationCount = 0;
        audioService.setRepeatEnabled(true);
        expect(notificationCount, greaterThan(0));
      });

      test('should handle rapid state changes without losing notifications',
          () {
        notificationCount = 0;

        // Rapid state changes
        audioService.setPlaybackStateForTesting(PlaybackState.loading);
        audioService.setPlaybackStateForTesting(PlaybackState.playing);
        audioService.setPlaybackStateForTesting(PlaybackState.paused);
        audioService.setPlaybackStateForTesting(PlaybackState.stopped);

        expect(notificationCount, 4);
      });

      test('should notify on all testing helper methods', () {
        notificationCount = 0;

        audioService.setPlaybackStateForTesting(PlaybackState.playing);
        final playingNotifications = notificationCount;

        audioService.setCurrentAudioFileForTesting(testAudioFile);
        final audioFileNotifications = notificationCount - playingNotifications;

        audioService.setDurationForTesting(const Duration(minutes: 5));
        final durationNotifications =
            notificationCount - playingNotifications - audioFileNotifications;

        audioService.setPositionForTesting(const Duration(minutes: 1));
        final positionNotifications = notificationCount -
            playingNotifications -
            audioFileNotifications -
            durationNotifications;

        // Each method should trigger exactly one notification
        expect(playingNotifications, 1);
        expect(audioFileNotifications, 1);
        expect(durationNotifications, 1);
        expect(positionNotifications, 1);
      });
    });

    group('Background Audio Handler Integration Tests', () {
      test('should call testMediaSession on handler', () async {
        when(mockAudioHandler.testMediaSession()).thenAnswer((_) async {});

        await audioService.testMediaSession();

        verify(mockAudioHandler.testMediaSession()).called(1);
      });

      test('should handle testMediaSession without handler', () async {
        final serviceWithoutHandler = AudioService(null, mockContentService);

        // Should complete without error
        await serviceWithoutHandler.testMediaSession();

        verifyNever(mockAudioHandler.testMediaSession());

        serviceWithoutHandler.dispose();
      });

      test('should handle background handler initialization properly', () {
        // Verify that the handler streams are properly subscribed
        verify(mockAudioHandler.playbackState).called(1);
        verify(mockAudioHandler.mediaItem).called(1);
      });

      test('should handle background handler stream errors', () {
        // Create a service with error-prone streams
        final errorSubject = BehaviorSubject<audio_service_pkg.PlaybackState>();
        errorSubject.addError(Exception('Stream error'));

        when(mockAudioHandler.playbackState).thenAnswer((_) => errorSubject);

        // Should not crash during initialization
        final errorProneService =
            AudioService(mockAudioHandler, mockContentService);

        expect(errorProneService.playbackState, PlaybackState.stopped);

        errorProneService.dispose();
      });

      test('should handle media session integration robustly', () async {
        when(mockAudioHandler.testMediaSession())
            .thenThrow(Exception('Media session error'));

        // Should handle the error gracefully
        await audioService.testMediaSession();

        verify(mockAudioHandler.testMediaSession()).called(1);
      });
    });

    group('Fallback Mode Tests (No Background Handler)', () {
      late AudioService fallbackService;

      setUp(() {
        fallbackService = AudioService(null, mockContentService);
      });

      tearDown(() {
        fallbackService.dispose();
      });

      test('should initialize in fallback mode', () {
        expect(fallbackService.playbackState, PlaybackState.stopped);
        expect(fallbackService.currentAudioFile, isNull);
      });

      test('should handle playback controls without handler', () async {
        // These should complete without throwing exceptions
        await fallbackService.togglePlayPause();
        await fallbackService.pause();
        await fallbackService.resume();
        await fallbackService.stop();
        await fallbackService.seekTo(const Duration(minutes: 1));
        await fallbackService.skipForward();
        await fallbackService.skipBackward();
        await fallbackService.setPlaybackSpeed(1.5);
      });

      test('should handle fallback mode with different audio formats',
          () async {
        // Should handle all audio formats in fallback mode
        fallbackService.setCurrentAudioFileForTesting(hlsAudioFile);
        expect(fallbackService.currentAudioFile, hlsAudioFile);

        fallbackService.setCurrentAudioFileForTesting(mp3AudioFile);
        expect(fallbackService.currentAudioFile, mp3AudioFile);
      });

      test('should handle state management in fallback mode', () {
        fallbackService.setPlaybackStateForTesting(PlaybackState.playing);
        expect(fallbackService.isPlaying, isTrue);

        fallbackService.setPlaybackStateForTesting(PlaybackState.paused);
        expect(fallbackService.isPaused, isTrue);
      });

      test('should handle preferences in fallback mode', () {
        fallbackService.setAutoplayEnabled(false);
        expect(fallbackService.autoplayEnabled, isFalse);

        fallbackService.setRepeatEnabled(true);
        expect(fallbackService.repeatEnabled, isTrue);
      });

      test('should handle completion logic in fallback mode', () async {
        fallbackService.setCurrentAudioFileForTesting(testAudioFile);
        fallbackService.setAutoplayEnabled(true);

        when(mockContentService.markEpisodeAsFinished(any))
            .thenAnswer((_) async {});
        when(mockContentService.getNextEpisode(any)).thenReturn(null);

        // Should complete without error
        await fallbackService.onEpisodeCompleted();

        verify(mockContentService.markEpisodeAsFinished(testAudioFile.id))
            .called(1);
      });
    });

    group('Edge Cases and Race Conditions', () {
      test('should handle multiple concurrent playAudio calls', () async {
        when(mockAudioHandler.setAudioSource(any,
                title: anyNamed('title'),
                artist: anyNamed('artist'),
                audioFile: anyNamed('audioFile')))
            .thenAnswer(
                (_) async => Future.delayed(const Duration(milliseconds: 100)));
        when(mockAudioHandler.play()).thenAnswer((_) async {});
        when(mockContentService.addToListenHistory(any))
            .thenAnswer((_) async {});

        // Start multiple concurrent plays
        final futures = [
          audioService.playAudio(testAudioFile),
          audioService.playAudio(testAudioFile2),
        ];

        await Future.wait(futures);

        // Should handle without crashing
        expect(audioService.currentAudioFile, isNotNull);
      });

      test('should handle dispose during async operations', () async {
        when(mockAudioHandler.setAudioSource(any,
                title: anyNamed('title'),
                artist: anyNamed('artist'),
                audioFile: anyNamed('audioFile')))
            .thenAnswer(
                (_) async => Future.delayed(const Duration(milliseconds: 100)));
        when(mockAudioHandler.play()).thenAnswer((_) async {});
        when(mockContentService.addToListenHistory(any))
            .thenAnswer((_) async {});

        // Start async operation
        final future = audioService.playAudio(testAudioFile);

        // Wait a bit for operation to start
        await Future.delayed(const Duration(milliseconds: 50));

        // Dispose immediately
        audioService.dispose();

        // Should handle error gracefully
        try {
          await future;
        } catch (e) {
          // Expected to throw due to dispose or other async cancellation
          expect(e, isA<Exception>());
        }
      });

      test('should handle null current audio file during navigation', () async {
        // Should complete without error
        await audioService.skipToNextEpisode();
        await audioService.skipToPreviousEpisode();

        verifyNever(mockContentService.getNextEpisode(any));
        verifyNever(mockContentService.getPreviousEpisode(any));
      });

      test('should handle zero duration in various calculations', () {
        audioService.setDurationForTesting(Duration.zero);
        audioService.setPositionForTesting(const Duration(minutes: 1));

        expect(audioService.progress, 0.0);
        expect(audioService.formattedTotalDuration, '0:00');

        audioService.savePlaybackState();

        // Should handle zero duration without error
        expect(audioService.currentPosition, const Duration(minutes: 1));
      });

      test('should handle concurrent state changes', () async {
        // Simulate concurrent state modifications
        final futures = <Future>[];

        for (int i = 0; i < 10; i++) {
          futures.add(Future.delayed(Duration(milliseconds: i * 10), () {
            audioService.setPlaybackStateForTesting(
                i.isEven ? PlaybackState.playing : PlaybackState.paused);
          }));
        }

        await Future.wait(futures);

        // Should end up in a valid state
        expect(
            [PlaybackState.playing, PlaybackState.paused]
                .contains(audioService.playbackState),
            isTrue);
      });

      test('should handle rapid preference changes', () {
        // Rapid toggle operations
        for (int i = 0; i < 100; i++) {
          audioService.toggleAutoplay();
          audioService.toggleRepeat();
        }

        // Should end up in valid state
        expect(audioService.autoplayEnabled,
            isFalse); // Started true, toggled even number of times
        expect(audioService.repeatEnabled,
            isFalse); // Started false, toggled even number of times
      });

      test('should handle playback control race conditions', () async {
        when(mockAudioHandler.play()).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 50));
        });
        when(mockAudioHandler.pause()).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 50));
        });

        // Rapid play/pause operations
        final futures = [
          audioService.resume(),
          audioService.pause(),
          audioService.togglePlayPause(),
          audioService.resume(),
        ];

        // Should handle without deadlock or crash
        await Future.wait(futures);

        // All operations should have been attempted
        verify(mockAudioHandler.play()).called(greaterThan(0));
        verify(mockAudioHandler.pause()).called(greaterThan(0));
      });

      test('should handle memory pressure scenarios', () {
        // Simulate many audio file changes to test memory handling
        final audioFiles = List.generate(
            1000,
            (index) => AudioFile(
                  id: 'test-$index',
                  title: 'Test Episode $index',
                  language: 'en-US',
                  category: 'test',
                  streamingUrl: 'https://example.com/test-$index.m3u8',
                  path: 'test-$index.m3u8',
                  duration: Duration(minutes: index % 60),
                  lastModified: DateTime.now(),
                ));

        // Rapidly change current audio file
        for (final file in audioFiles) {
          audioService.setCurrentAudioFileForTesting(file);
        }

        // Should handle without memory leaks or performance issues
        expect(audioService.currentAudioFile, audioFiles.last);
      });

      test('should handle extreme duration values', () {
        // Test with very large duration
        audioService.setDurationForTesting(const Duration(days: 365));
        audioService.setPositionForTesting(const Duration(days: 100));

        expect(audioService.progress, closeTo(100 / 365, 0.001));

        // Test with very small duration
        audioService.setDurationForTesting(const Duration(milliseconds: 1));
        audioService.setPositionForTesting(Duration.zero);

        expect(audioService.progress, 0.0);
      });

      test('should handle system interruptions simulation', () async {
        // Simulate system audio interruption scenario
        audioService.setPlaybackStateForTesting(PlaybackState.playing);
        audioService.setCurrentAudioFileForTesting(testAudioFile);

        // Simulate interruption
        audioService.handlePlaybackError('Audio session interrupted');
        expect(audioService.playbackState, PlaybackState.error);

        // Simulate recovery
        audioService.clearErrorForTesting();
        expect(audioService.playbackState, PlaybackState.stopped);
        expect(audioService.currentAudioFile,
            testAudioFile); // Should retain current audio
      });
    });

    group('Audio Format and Codec Specific Tests', () {
      test('should handle HLS stream playback', () async {
        when(mockAudioHandler.setAudioSource(any,
                title: anyNamed('title'),
                artist: anyNamed('artist'),
                audioFile: anyNamed('audioFile')))
            .thenAnswer((_) async {});
        when(mockAudioHandler.play()).thenAnswer((_) async {});
        when(mockContentService.addToListenHistory(any))
            .thenAnswer((_) async {});

        await audioService.playAudio(hlsAudioFile);

        expect(audioService.currentAudioFile, hlsAudioFile);
        verify(mockAudioHandler.setAudioSource(
          hlsAudioFile.streamingUrl,
          title: hlsAudioFile.title,
          artist: 'From Fed to Chain',
          audioFile: hlsAudioFile,
        )).called(1);
      });

      test('should handle direct MP3 playback', () async {
        when(mockAudioHandler.setAudioSource(any,
                title: anyNamed('title'),
                artist: anyNamed('artist'),
                audioFile: anyNamed('audioFile')))
            .thenAnswer((_) async {});
        when(mockAudioHandler.play()).thenAnswer((_) async {});
        when(mockContentService.addToListenHistory(any))
            .thenAnswer((_) async {});

        await audioService.playAudio(mp3AudioFile);

        expect(audioService.currentAudioFile, mp3AudioFile);
        verify(mockAudioHandler.setAudioSource(
          mp3AudioFile.streamingUrl,
          title: mp3AudioFile.title,
          artist: 'From Fed to Chain',
          audioFile: mp3AudioFile,
        )).called(1);
      });

      test('should handle codec errors for unsupported formats', () async {
        when(mockAudioHandler.setAudioSource(any,
                title: anyNamed('title'),
                artist: anyNamed('artist'),
                audioFile: anyNamed('audioFile')))
            .thenThrow(Exception('Unsupported audio codec'));

        expect(audioService.playAudio(testAudioFile), throwsException);

        await Future.delayed(Duration.zero);
        expect(audioService.playbackState, PlaybackState.error);
        expect(audioService.errorMessage, contains('Unsupported audio codec'));
      });

      test('should handle streaming interruption gracefully', () {
        const streamingError = 'Stream interrupted due to network issues';

        audioService.handlePlaybackError(streamingError);

        expect(audioService.playbackState, PlaybackState.error);
        expect(audioService.errorMessage, streamingError);
      });

      test('should handle adaptive bitrate streaming', () async {
        // Test with HLS file that supports adaptive bitrate
        final adaptiveHlsFile = hlsAudioFile.copyWith(
            streamingUrl: 'https://example.com/adaptive-stream/playlist.m3u8');

        when(mockAudioHandler.setAudioSource(any,
                title: anyNamed('title'),
                artist: anyNamed('artist'),
                audioFile: anyNamed('audioFile')))
            .thenAnswer((_) async {});
        when(mockAudioHandler.play()).thenAnswer((_) async {});
        when(mockContentService.addToListenHistory(any))
            .thenAnswer((_) async {});

        await audioService.playAudio(adaptiveHlsFile);

        expect(audioService.currentAudioFile, adaptiveHlsFile);
      });

      test('should handle audio format switching during playback', () async {
        when(mockAudioHandler.setAudioSource(any,
                title: anyNamed('title'),
                artist: anyNamed('artist'),
                audioFile: anyNamed('audioFile')))
            .thenAnswer((_) async {});
        when(mockAudioHandler.play()).thenAnswer((_) async {});
        when(mockContentService.addToListenHistory(any))
            .thenAnswer((_) async {});

        // Start with HLS
        await audioService.playAudio(hlsAudioFile);
        expect(audioService.currentAudioFile, hlsAudioFile);

        // Switch to MP3
        await audioService.playAudio(mp3AudioFile);
        expect(audioService.currentAudioFile, mp3AudioFile);

        // Both should have been called
        verify(mockAudioHandler.setAudioSource(any,
                title: anyNamed('title'),
                artist: anyNamed('artist'),
                audioFile: anyNamed('audioFile')))
            .called(2);
      });
    });

    group('Media Session and Lock Screen Integration Tests', () {
      test('should handle media session initialization', () async {
        // Verify that navigation callbacks are set up
        verify(mockAudioHandler.setEpisodeNavigationCallbacks(
          onNext: anyNamed('onNext'),
          onPrevious: anyNamed('onPrevious'),
        )).called(1);
      });

      test('should handle media control from lock screen', () async {
        when(mockAudioHandler.play()).thenAnswer((_) async {});
        when(mockAudioHandler.pause()).thenAnswer((_) async {});

        // Simulate lock screen controls
        await audioService.togglePlayPause(); // Play
        await audioService.togglePlayPause(); // Pause

        verify(mockAudioHandler.play()).called(1);
        verify(mockAudioHandler.pause()).called(1);
      });

      test('should handle media session artwork and metadata', () async {
        when(mockAudioHandler.setAudioSource(any,
                title: anyNamed('title'),
                artist: anyNamed('artist'),
                audioFile: anyNamed('audioFile')))
            .thenAnswer((_) async {});
        when(mockAudioHandler.play()).thenAnswer((_) async {});
        when(mockContentService.addToListenHistory(any))
            .thenAnswer((_) async {});

        await audioService.playAudio(testAudioFile);

        // Verify that proper metadata is passed
        verify(mockAudioHandler.setAudioSource(
          testAudioFile.streamingUrl,
          title: testAudioFile.title,
          artist: 'From Fed to Chain',
          audioFile: testAudioFile,
        )).called(1);
      });

      test('should handle notification controls', () async {
        // Test skip controls from notification
        await audioService.skipForward();
        await audioService.skipBackward();

        verify(mockAudioHandler.fastForward()).called(1);
        verify(mockAudioHandler.rewind()).called(1);
      });

      test('should handle media session cleanup on dispose', () {
        // Dispose should not crash and should clean up properly
        expect(() => audioService.dispose(), returnsNormally);
      });
    });

    group('Performance and Resource Management Tests', () {
      test('should handle large playlist navigation efficiently', () async {
        // Create many audio files to simulate large playlist
        final largePlaylist = List.generate(
            1000,
            (index) => AudioFile(
                  id: 'episode-$index',
                  title: 'Episode $index',
                  language: 'en-US',
                  category: 'daily-news',
                  streamingUrl: 'https://example.com/episode-$index.m3u8',
                  path: 'episode-$index.m3u8',
                  duration: Duration(minutes: 10 + index % 50),
                  lastModified: DateTime.now().subtract(Duration(days: index)),
                ));

        when(mockContentService.getNextEpisode(any))
            .thenReturn(largePlaylist[1]);
        when(mockContentService.addToListenHistory(any))
            .thenAnswer((_) async {});
        when(mockAudioHandler.setAudioSource(any,
                title: anyNamed('title'),
                artist: anyNamed('artist'),
                audioFile: anyNamed('audioFile')))
            .thenAnswer((_) async {});
        when(mockAudioHandler.play()).thenAnswer((_) async {});

        audioService.setCurrentAudioFileForTesting(largePlaylist[0]);

        final stopwatch = Stopwatch()..start();
        await audioService.skipToNextEpisode();
        stopwatch.stop();

        // Navigation should be reasonably fast even with large playlists
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
        expect(audioService.currentAudioFile, largePlaylist[1]);
      });

      test('should handle memory efficiently during long sessions', () {
        // Simulate long listening session with many position updates
        audioService.setCurrentAudioFileForTesting(testAudioFile);
        audioService.setDurationForTesting(const Duration(hours: 1));

        // Many position updates (simulating real playback)
        for (int i = 0; i < 3600; i++) {
          // One update per second for an hour
          audioService.updateProgress(Duration(seconds: i));
        }

        expect(audioService.currentPosition, const Duration(seconds: 3599));
        expect(audioService.progress, closeTo(3599 / 3600, 0.001));
      });

      test('should handle rapid state changes efficiently', () {
        final stopwatch = Stopwatch()..start();

        // Rapid state changes
        for (int i = 0; i < 1000; i++) {
          audioService.setPlaybackStateForTesting(
              PlaybackState.values[i % PlaybackState.values.length]);
        }

        stopwatch.stop();

        // Should handle rapid changes efficiently
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });

      test('should handle dispose cleanup properly', () {
        // Verify that dispose can be called multiple times safely
        expect(() => audioService.dispose(), returnsNormally);
        expect(() => audioService.dispose(), returnsNormally);
      });
    });

    group('Comprehensive Integration Tests', () {
      test('should handle complete podcast episode lifecycle', () async {
        when(mockAudioHandler.setAudioSource(any,
                title: anyNamed('title'),
                artist: anyNamed('artist'),
                audioFile: anyNamed('audioFile')))
            .thenAnswer((_) async {});
        when(mockAudioHandler.play()).thenAnswer((_) async {});
        when(mockAudioHandler.pause()).thenAnswer((_) async {});
        when(mockContentService.addToListenHistory(any))
            .thenAnswer((_) async {});
        when(mockContentService.markEpisodeAsFinished(any))
            .thenAnswer((_) async {});
        when(mockContentService.getNextEpisode(any)).thenReturn(testAudioFile2);

        // 1. Start playback
        await audioService.playAudio(testAudioFile);
        expect(audioService.currentAudioFile, testAudioFile);
        expect(audioService.playbackState, isNot(PlaybackState.error));

        // 2. Pause and resume
        await audioService.pause();
        await audioService.resume();

        // 3. Seek and skip
        await audioService.seekTo(const Duration(minutes: 2));
        await audioService.skipForward();
        await audioService.skipBackward();

        // 4. Change speed
        await audioService.setPlaybackSpeed(1.5);
        expect(audioService.playbackSpeed, 1.5);

        // 5. Complete episode (should trigger autoplay)
        audioService.setAutoplayEnabled(true);
        await audioService.onEpisodeCompleted();

        // Verify complete lifecycle
        verify(mockAudioHandler.setAudioSource(any,
                title: anyNamed('title'),
                artist: anyNamed('artist'),
                audioFile: anyNamed('audioFile')))
            .called(2); // Original + autoplay
        verify(mockContentService.markEpisodeAsFinished(testAudioFile.id))
            .called(1);
        expect(audioService.currentAudioFile, testAudioFile2);
      });

      test('should handle multi-language episode switching', () async {
        final episodes = [
          testAudioFile,
          hlsAudioFile,
          mp3AudioFile
        ]; // en-US, ja-JP, zh-TW

        when(mockAudioHandler.setAudioSource(any,
                title: anyNamed('title'),
                artist: anyNamed('artist'),
                audioFile: anyNamed('audioFile')))
            .thenAnswer((_) async {});
        when(mockAudioHandler.play()).thenAnswer((_) async {});
        when(mockContentService.addToListenHistory(any))
            .thenAnswer((_) async {});

        // Switch between different language episodes
        for (final episode in episodes) {
          await audioService.playAudio(episode);
          expect(audioService.currentAudioFile, episode);
        }

        verify(mockAudioHandler.setAudioSource(any,
                title: anyNamed('title'),
                artist: anyNamed('artist'),
                audioFile: anyNamed('audioFile')))
            .called(3);
      });

      test('should handle complex error recovery scenarios', () async {
        when(mockAudioHandler.setAudioSource(any,
                title: anyNamed('title'),
                artist: anyNamed('artist'),
                audioFile: anyNamed('audioFile')))
            .thenThrow(Exception('Network error'));

        // 1. Initial failure
        expect(audioService.playAudio(testAudioFile), throwsException);
        await Future.delayed(Duration.zero);
        expect(audioService.playbackState, PlaybackState.error);

        // 2. Clear error and retry with success
        when(mockAudioHandler.setAudioSource(any,
                title: anyNamed('title'),
                artist: anyNamed('artist'),
                audioFile: anyNamed('audioFile')))
            .thenAnswer((_) async {});
        when(mockAudioHandler.play()).thenAnswer((_) async {});
        when(mockContentService.addToListenHistory(any))
            .thenAnswer((_) async {});

        await audioService.playAudio(testAudioFile2);
        expect(audioService.playbackState, isNot(PlaybackState.error));
        expect(audioService.currentAudioFile, testAudioFile2);
        expect(audioService.errorMessage, isNull);
      });
    });
  });
}
