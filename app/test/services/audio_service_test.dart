import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:from_fed_to_chain_app/services/audio_service.dart';
import 'package:from_fed_to_chain_app/services/background_audio_handler.dart';
import 'package:from_fed_to_chain_app/services/content_service.dart';
import 'package:from_fed_to_chain_app/models/audio_file.dart';
import 'package:audio_service/audio_service.dart' as audio_service_pkg;
import 'package:rxdart/rxdart.dart';
import '../test_utils.dart';

// Generate mocks for the dependencies
@GenerateMocks([
  BackgroundAudioHandler,
  ContentService,
])
import 'audio_service_test.mocks.dart';

void main() {
  group('AudioService Tests', () {
    late AudioService audioService;
    late MockBackgroundAudioHandler mockAudioHandler;
    late MockContentService mockContentService;
    late AudioFile sampleAudioFile;

    setUp(() {
      mockAudioHandler = MockBackgroundAudioHandler();
      mockContentService = MockContentService();
      sampleAudioFile = TestUtils.createSampleAudioFile(
        title: 'Test Audio',
        streamingUrl: 'https://example.com/test.m3u8',
      );

      // Set up mock streams for background audio handler
      final playbackStateSubject =
          BehaviorSubject<audio_service_pkg.PlaybackState>.seeded(
        audio_service_pkg.PlaybackState(
          playing: false,
          updatePosition: Duration.zero,
          speed: 1.0,
          processingState: audio_service_pkg.AudioProcessingState.idle,
        ),
      );
      final mediaItemSubject =
          BehaviorSubject<audio_service_pkg.MediaItem?>.seeded(null);

      when(mockAudioHandler.playbackState).thenReturn(playbackStateSubject);
      when(mockAudioHandler.mediaItem).thenReturn(mediaItemSubject);
      when(mockAudioHandler.duration).thenReturn(Duration.zero);

      // Mock the setEpisodeNavigationCallbacks method
      when(mockAudioHandler.setEpisodeNavigationCallbacks(
        onNext: anyNamed('onNext'),
        onPrevious: anyNamed('onPrevious'),
      )).thenReturn(null);

      // Create AudioService with mocked dependencies
      audioService = AudioService(mockAudioHandler, mockContentService);
    });

    tearDown(() {
      audioService.dispose();
    });

    group('Initialization', () {
      test('should initialize with correct default state', () {
        expect(audioService.playbackState, equals(PlaybackState.stopped));
        expect(audioService.currentAudioFile, isNull);
        expect(audioService.currentPosition, equals(Duration.zero));
        expect(audioService.totalDuration, equals(Duration.zero));
        expect(audioService.playbackSpeed, equals(1.0));
        expect(audioService.autoplayEnabled, isTrue);
        expect(audioService.repeatEnabled, isFalse);
        expect(audioService.hasError, isFalse);
        expect(audioService.isPlaying, isFalse);
        expect(audioService.isPaused, isFalse);
        expect(audioService.isLoading, isFalse);
        expect(audioService.isIdle, isTrue);
      });

      test('should handle null audio handler gracefully', () {
        final audioServiceWithoutHandler =
            AudioService(null, mockContentService);
        expect(audioServiceWithoutHandler.playbackState,
            equals(PlaybackState.stopped));
        audioServiceWithoutHandler.dispose();
      });

      test('should handle null content service gracefully', () {
        final audioServiceWithoutContent = AudioService(mockAudioHandler, null);
        expect(audioServiceWithoutContent.playbackState,
            equals(PlaybackState.stopped));
        audioServiceWithoutContent.dispose();
      });
    });

    group('Audio File Validation', () {
      test('should validate audio file before playing', () {
        final validFile = TestUtils.createSampleAudioFile(
          streamingUrl: 'https://example.com/valid.m3u8',
        );
        expect(audioService.isValidAudioFile(validFile), isTrue);
      });

      test('should reject audio file with invalid URL', () {
        final invalidFile = TestUtils.createSampleAudioFile(
          streamingUrl: '',
        );
        expect(audioService.isValidAudioFile(invalidFile), isFalse);
      });

      test('should reject null audio file', () {
        expect(audioService.isValidAudioFile(null), isFalse);
      });
    });

    group('Playback Control (Testing Methods)', () {
      test('should set playback state for testing', () {
        audioService.setPlaybackStateForTesting(PlaybackState.playing);
        expect(audioService.playbackState, equals(PlaybackState.playing));
        expect(audioService.isPlaying, isTrue);
      });

      test('should set current audio file for testing', () {
        audioService.setCurrentAudioFileForTesting(sampleAudioFile);
        expect(audioService.currentAudioFile, equals(sampleAudioFile));
      });

      test('should set duration for testing', () {
        audioService.setDurationForTesting(const Duration(minutes: 10));
        expect(audioService.totalDuration, equals(const Duration(minutes: 10)));
      });

      test('should set position for testing', () {
        audioService.setPositionForTesting(const Duration(minutes: 2));
        expect(
            audioService.currentPosition, equals(const Duration(minutes: 2)));
      });

      test('should set error for testing', () {
        const errorMessage = 'Test error';
        audioService.setErrorForTesting(errorMessage);
        expect(audioService.playbackState, equals(PlaybackState.error));
        expect(audioService.errorMessage, equals(errorMessage));
        expect(audioService.hasError, isTrue);
      });
    });

    group('Progress and Duration Calculation', () {
      test('should calculate progress correctly', () {
        audioService.setDurationForTesting(const Duration(minutes: 10));
        audioService.setPositionForTesting(const Duration(minutes: 2));
        expect(audioService.progress, closeTo(0.2, 0.01));
      });

      test('should return zero progress when duration is zero', () {
        audioService.setDurationForTesting(Duration.zero);
        audioService.setPositionForTesting(const Duration(minutes: 2));
        expect(audioService.progress, equals(0.0));
      });

      test('should format duration correctly', () {
        audioService.setDurationForTesting(
            const Duration(hours: 1, minutes: 23, seconds: 45));
        audioService
            .setPositionForTesting(const Duration(minutes: 5, seconds: 30));
        expect(audioService.formattedTotalDuration, equals('1:23:45'));
        expect(audioService.formattedCurrentPosition, equals('5:30'));
      });

      test('should handle short durations correctly', () {
        audioService
            .setDurationForTesting(const Duration(minutes: 2, seconds: 15));
        audioService.setPositionForTesting(const Duration(seconds: 45));
        expect(audioService.formattedTotalDuration, equals('2:15'));
        expect(audioService.formattedCurrentPosition, equals('0:45'));
      });
    });

    group('Auto-play and Repeat Features', () {
      test('should toggle autoplay correctly', () {
        expect(audioService.autoplayEnabled, isTrue);
        audioService.toggleAutoplay();
        expect(audioService.autoplayEnabled, isFalse);
        audioService.toggleAutoplay();
        expect(audioService.autoplayEnabled, isTrue);
      });

      test('should toggle repeat correctly', () {
        expect(audioService.repeatEnabled, isFalse);
        audioService.toggleRepeat();
        expect(audioService.repeatEnabled, isTrue);
        audioService.toggleRepeat();
        expect(audioService.repeatEnabled, isFalse);
      });

      test('should set autoplay enabled', () {
        audioService.enableAutoplay(false);
        expect(audioService.autoplayEnabled, isFalse);
        audioService.enableAutoplay(true);
        expect(audioService.autoplayEnabled, isTrue);
      });

      test('should set repeat enabled', () {
        audioService.setRepeatEnabled(true);
        expect(audioService.repeatEnabled, isTrue);
        audioService.setRepeatEnabled(false);
        expect(audioService.repeatEnabled, isFalse);
      });
    });

    group('Background Audio Integration', () {
      test('should delegate play calls to background handler', () async {
        await audioService.playAudio(sampleAudioFile);
        verify(mockAudioHandler.setAudioSource(any,
                title: anyNamed('title'),
                artist: anyNamed('artist'),
                audioFile: anyNamed('audioFile')))
            .called(1);
        verify(mockAudioHandler.play()).called(1);
      });

      test('should delegate pause calls to background handler', () async {
        await audioService.pause();
        verify(mockAudioHandler.pause()).called(1);
      });

      test('should delegate stop calls to background handler', () async {
        await audioService.stop();
        verify(mockAudioHandler.stop()).called(1);
      });

      test('should delegate seek calls to background handler', () async {
        const position = Duration(minutes: 2);
        await audioService.seekTo(position);
        verify(mockAudioHandler.seek(position)).called(1);
      });

      test('should set episode navigation callbacks on handler', () {
        verify(mockAudioHandler.setEpisodeNavigationCallbacks(
          onNext: anyNamed('onNext'),
          onPrevious: anyNamed('onPrevious'),
        )).called(1);
      });
    });

    group('Error Handling', () {
      test('should handle playback errors gracefully', () {
        const errorMessage = 'Network error';
        audioService.handlePlaybackError(errorMessage);
        expect(audioService.playbackState, equals(PlaybackState.error));
        expect(audioService.errorMessage, equals(errorMessage));
        expect(audioService.hasError, isTrue);
      });

      test('should handle network timeouts', () {
        audioService.handleNetworkTimeout();
        expect(audioService.playbackState, equals(PlaybackState.error));
        expect(audioService.errorMessage, contains('timeout'));
      });

      test('should handle invalid audio URLs', () {
        final invalidAudioFile = TestUtils.createSampleAudioFile(
          streamingUrl: 'invalid-url',
        );
        audioService.handleInvalidUrl(invalidAudioFile);
        expect(audioService.playbackState, equals(PlaybackState.error));
        expect(audioService.errorMessage, contains('invalid'));
      });
    });

    group('Episode Navigation', () {
      test('should skip to next episode', () async {
        final episodes = TestUtils.createSampleAudioFileList(3);
        when(mockContentService.getNextEpisode(any)).thenReturn(episodes[1]);
        audioService.setCurrentAudioFileForTesting(episodes[0]);

        await audioService.skipToNext();
        verify(mockContentService.getNextEpisode(episodes[0])).called(1);
      });

      test('should skip to previous episode', () async {
        final episodes = TestUtils.createSampleAudioFileList(3);
        when(mockContentService.getPreviousEpisode(any))
            .thenReturn(episodes[0]);
        audioService.setCurrentAudioFileForTesting(episodes[1]);

        await audioService.skipToPrevious();
        verify(mockContentService.getPreviousEpisode(episodes[1])).called(1);
      });

      test('should handle no next episode gracefully', () async {
        when(mockContentService.getNextEpisode(any)).thenReturn(null);
        audioService.setCurrentAudioFileForTesting(sampleAudioFile);

        await audioService.skipToNext();
        expect(audioService.currentAudioFile, equals(sampleAudioFile));
      });
    });

    group('State Persistence', () {
      test('should save playback state', () {
        audioService.setCurrentAudioFileForTesting(sampleAudioFile);
        audioService.setDurationForTesting(const Duration(minutes: 10));
        audioService.setPositionForTesting(const Duration(minutes: 2));

        audioService.savePlaybackState();
        verify(mockContentService.updateEpisodeCompletion(
                sampleAudioFile.id, any))
            .called(1);
      });

      test('should restore playback position', () async {
        when(mockContentService.getEpisodeCompletion(sampleAudioFile.id))
            .thenReturn(0.4);
        audioService.setDurationForTesting(const Duration(minutes: 10));

        await audioService.restorePlaybackPosition(sampleAudioFile);
        expect(
            audioService.currentPosition, equals(const Duration(minutes: 4)));
      });
    });

    group('Disposal and Cleanup', () {
      test('should dispose resources correctly', () {
        audioService.dispose();
        // Should not throw errors after disposal
        expect(() => audioService.playAudio(sampleAudioFile), returnsNormally);
      });
    });
  });
}
