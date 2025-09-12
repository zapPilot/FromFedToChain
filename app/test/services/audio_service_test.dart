import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:audio_service/audio_service.dart' as audio_service_pkg;
import 'package:rxdart/rxdart.dart';

import 'package:from_fed_to_chain_app/services/audio_service.dart';
import 'package:from_fed_to_chain_app/services/background_audio_handler.dart';
import 'package:from_fed_to_chain_app/services/content_service.dart';
import 'package:from_fed_to_chain_app/models/audio_file.dart';

// Generate mocks for dependencies
@GenerateMocks([BackgroundAudioHandler, ContentService])
import 'audio_service_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudioService - Simplified Unit Tests', () {
    late AudioService audioService;
    late MockBackgroundAudioHandler mockAudioHandler;
    late MockContentService mockContentService;
    late AudioFile testAudioFile;

    setUp(() {
      mockAudioHandler = MockBackgroundAudioHandler();
      mockContentService = MockContentService();

      // Simple stream setup
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

      // Basic method stubs
      when(mockAudioHandler.setAudioSource(any,
              title: anyNamed('title'),
              artist: anyNamed('artist'),
              initialPosition: anyNamed('initialPosition'),
              audioFile: anyNamed('audioFile')))
          .thenAnswer((_) async => {});
      when(mockAudioHandler.play()).thenAnswer((_) async => {});
      when(mockAudioHandler.pause()).thenAnswer((_) async => {});
      when(mockAudioHandler.stop()).thenAnswer((_) async => {});
      when(mockAudioHandler.seek(any)).thenAnswer((_) async => {});

      testAudioFile = AudioFile(
        id: 'test-episode',
        title: 'Test Episode',
        language: 'en-US',
        category: 'daily-news',
        streamingUrl: 'https://example.com/audio.m3u8',
        path: 'test-episode.m3u8',
        duration: const Duration(minutes: 5),
        lastModified: DateTime.now(),
      );

      audioService = AudioService(mockAudioHandler, mockContentService);
    });

    tearDown(() {
      reset(mockAudioHandler);
      reset(mockContentService);
    });

    group('Basic State Management', () {
      test('should initialize with default state', () {
        expect(audioService.playbackState, PlaybackState.stopped);
        expect(audioService.currentAudioFile, isNull);
        expect(audioService.autoplayEnabled, isTrue);
        expect(audioService.repeatEnabled, isFalse);
      });

      test('should calculate computed properties correctly', () {
        audioService.setPlaybackStateForTesting(PlaybackState.playing);
        expect(audioService.isPlaying, isTrue);
        expect(audioService.isPaused, isFalse);

        audioService.setPlaybackStateForTesting(PlaybackState.paused);
        expect(audioService.isPlaying, isFalse);
        expect(audioService.isPaused, isTrue);

        audioService.setPlaybackStateForTesting(PlaybackState.loading);
        expect(audioService.isLoading, isTrue);
      });
    });

    group('Basic Playback Control', () {
      test('should call handler play method', () async {
        await audioService.playAudio(testAudioFile);
        verify(mockAudioHandler.setAudioSource(
          testAudioFile.streamingUrl,
          title: testAudioFile.title,
          artist: anyNamed('artist'),
          initialPosition: anyNamed('initialPosition'),
          audioFile: testAudioFile,
        )).called(1);
        verify(mockAudioHandler.play()).called(1);
      });

      test('should call handler pause method', () async {
        // Set up state to be playing so togglePlayPause calls pause
        audioService.setPlaybackStateForTesting(PlaybackState.playing);
        await audioService.togglePlayPause();
        verify(mockAudioHandler.pause()).called(1);
      });

      test('should call handler stop method', () async {
        await audioService.stop();
        verify(mockAudioHandler.stop()).called(1);
      });

      test('should call handler seek method', () async {
        const position = Duration(seconds: 30);
        await audioService.seekTo(position);
        verify(mockAudioHandler.seek(position)).called(1);
      });
    });

    group('User Preferences', () {
      test('should toggle autoplay setting', () {
        expect(audioService.autoplayEnabled, isTrue);
        audioService.toggleAutoplay();
        expect(audioService.autoplayEnabled, isFalse);
        audioService.toggleAutoplay();
        expect(audioService.autoplayEnabled, isTrue);
      });

      test('should toggle repeat setting', () {
        expect(audioService.repeatEnabled, isFalse);
        audioService.toggleRepeat();
        expect(audioService.repeatEnabled, isTrue);
        audioService.toggleRepeat();
        expect(audioService.repeatEnabled, isFalse);
      });

      test('should set playback speed', () async {
        when(mockAudioHandler.customAction('setSpeed', any))
            .thenAnswer((_) async => {});

        await audioService.setPlaybackSpeed(1.5);
        expect(audioService.playbackSpeed, 1.5);
        verify(mockAudioHandler.customAction('setSpeed', {'speed': 1.5}))
            .called(1);
      });
    });

    group('Navigation - Basic Tests', () {
      test('should attempt to skip to next episode', () async {
        when(mockContentService.getNextEpisode(any)).thenReturn(testAudioFile);
        when(mockAudioHandler.setEpisodeNavigationCallbacks(
                onNext: anyNamed('onNext'), onPrevious: anyNamed('onPrevious')))
            .thenReturn(null);

        audioService.setCurrentAudioFileForTesting(testAudioFile);
        await audioService.skipToNext();

        // Verify that we attempted to get next episode
        verify(mockContentService.getNextEpisode(testAudioFile)).called(1);
      });

      test('should attempt to skip to previous episode', () async {
        when(mockContentService.getPreviousEpisode(any))
            .thenReturn(testAudioFile);

        audioService.setCurrentAudioFileForTesting(testAudioFile);
        await audioService.skipToPrevious();

        // Verify that we attempted to get previous episode
        verify(mockContentService.getPreviousEpisode(testAudioFile)).called(1);
      });

      test('should handle no next episode available', () async {
        when(mockContentService.getNextEpisode(any)).thenReturn(null);

        audioService.setCurrentAudioFileForTesting(testAudioFile);
        await audioService.skipToNext();

        verify(mockContentService.getNextEpisode(testAudioFile)).called(1);
        // Should not crash when no next episode available
      });
    });

    group('Error Handling', () {
      test('should handle playback errors gracefully', () async {
        when(mockAudioHandler.setAudioSource(any,
                title: anyNamed('title'),
                artist: anyNamed('artist'),
                initialPosition: anyNamed('initialPosition'),
                audioFile: anyNamed('audioFile')))
            .thenThrow(Exception('Network error'));

        // Expect the exception to be rethrown
        expect(() => audioService.playAudio(testAudioFile),
            throwsA(isA<Exception>()));

        // Wait for the future to complete and check error state
        try {
          await audioService.playAudio(testAudioFile);
        } catch (e) {
          // Exception is expected, check that error state was set
          expect(audioService.hasError, isTrue);
          expect(audioService.errorMessage, contains('Network error'));
        }
      });

      test('should clear error on successful play', () async {
        // First set an error state
        audioService.setErrorForTesting('Previous error');
        expect(audioService.hasError, isTrue);

        // Then play successfully
        await audioService.playAudio(testAudioFile);

        expect(audioService.hasError, isFalse);
        expect(audioService.errorMessage, isNull);
      });
    });
  });
}
