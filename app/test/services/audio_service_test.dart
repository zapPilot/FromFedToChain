import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:from_fed_to_chain_app/services/audio_service.dart';
import 'package:from_fed_to_chain_app/services/background_audio_handler.dart';
import 'package:from_fed_to_chain_app/services/content_service.dart';
import 'package:from_fed_to_chain_app/models/audio_file.dart';
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

    group('Playback State Management', () {
      test('should transition to loading state when starting playback',
          () async {
        // Mock the play method to simulate loading
        when(mockAudioHandler.play()).thenAnswer((_) async {
          // Simulate async loading
          await Future.delayed(const Duration(milliseconds: 10));
        });

        audioService.play(sampleAudioFile);

        // Should transition to loading state
        expect(audioService.playbackState, equals(PlaybackState.loading));
        expect(audioService.isLoading, isTrue);
        expect(audioService.currentAudioFile, equals(sampleAudioFile));
      });

      test('should handle pause correctly', () {
        // Set up playing state first
        audioService.setPlaybackStateForTesting(PlaybackState.playing);

        audioService.pause();

        expect(audioService.playbackState, equals(PlaybackState.paused));
        expect(audioService.isPaused, isTrue);
        expect(audioService.isPlaying, isFalse);
      });

      test('should handle resume correctly', () {
        // Set up paused state first
        audioService.setPlaybackStateForTesting(PlaybackState.paused);
        audioService.setCurrentAudioFileForTesting(sampleAudioFile);

        audioService.resume();

        expect(audioService.playbackState, equals(PlaybackState.playing));
        expect(audioService.isPlaying, isTrue);
        expect(audioService.isPaused, isFalse);
      });

      test('should handle stop correctly', () {
        // Set up playing state first
        audioService.setPlaybackStateForTesting(PlaybackState.playing);
        audioService.setCurrentAudioFileForTesting(sampleAudioFile);

        audioService.stop();

        expect(audioService.playbackState, equals(PlaybackState.stopped));
        expect(audioService.isIdle, isTrue);
        expect(audioService.currentPosition, equals(Duration.zero));
      });

      test('should handle error state correctly', () {
        const errorMessage = 'Test error message';

        audioService.setErrorForTesting(errorMessage);

        expect(audioService.playbackState, equals(PlaybackState.error));
        expect(audioService.hasError, isTrue);
        expect(audioService.errorMessage, equals(errorMessage));
      });
    });

    group('Progress and Duration Tracking', () {
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

    group('Playback Speed Control', () {
      test('should set playback speed correctly', () {
        audioService.setPlaybackSpeed(1.5);

        expect(audioService.playbackSpeed, equals(1.5));
      });

      test('should handle valid speed range', () {
        final validSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

        for (final speed in validSpeeds) {
          audioService.setPlaybackSpeed(speed);
          expect(audioService.playbackSpeed, equals(speed));
        }
      });

      test('should clamp invalid speeds to valid range', () {
        // Test below minimum
        audioService.setPlaybackSpeed(0.1);
        expect(audioService.playbackSpeed, equals(0.5)); // Minimum allowed

        // Test above maximum
        audioService.setPlaybackSpeed(5.0);
        expect(audioService.playbackSpeed, equals(2.0)); // Maximum allowed
      });
    });

    group('Seek Operations', () {
      test('should handle seeking to specific position', () {
        audioService.setDurationForTesting(const Duration(minutes: 10));
        const newPosition = Duration(minutes: 3);

        audioService.seekTo(newPosition);

        expect(audioService.currentPosition, equals(newPosition));
      });

      test('should handle seek forward', () {
        audioService.setDurationForTesting(const Duration(minutes: 10));
        audioService.setPositionForTesting(const Duration(minutes: 2));

        audioService.seekForward(); // Default 30 seconds

        expect(audioService.currentPosition,
            equals(const Duration(minutes: 2, seconds: 30)));
      });

      test('should handle seek backward', () {
        audioService.setDurationForTesting(const Duration(minutes: 10));
        audioService.setPositionForTesting(const Duration(minutes: 2));

        audioService.seekBackward(); // Default 10 seconds

        expect(audioService.currentPosition,
            equals(const Duration(minutes: 1, seconds: 50)));
      });

      test('should not seek beyond duration limits', () {
        audioService.setDurationForTesting(const Duration(minutes: 5));
        audioService
            .setPositionForTesting(const Duration(minutes: 4, seconds: 50));

        audioService.seekForward(); // Would go beyond duration

        expect(
            audioService.currentPosition, equals(const Duration(minutes: 5)));
      });

      test('should not seek before start', () {
        audioService.setDurationForTesting(const Duration(minutes: 5));
        audioService.setPositionForTesting(const Duration(seconds: 5));

        audioService.seekBackward(); // Would go before start

        expect(audioService.currentPosition, equals(Duration.zero));
      });
    });

    group('Episode Navigation', () {
      test('should skip to next episode', () {
        final episodes = TestUtils.createSampleAudioFileList(3);
        when(mockContentService.getNextEpisode(any)).thenReturn(episodes[1]);

        audioService.setCurrentAudioFileForTesting(episodes[0]);
        audioService.skipToNext();

        verify(mockContentService.getNextEpisode(episodes[0])).called(1);
      });

      test('should skip to previous episode', () {
        final episodes = TestUtils.createSampleAudioFileList(3);
        when(mockContentService.getPreviousEpisode(any))
            .thenReturn(episodes[0]);

        audioService.setCurrentAudioFileForTesting(episodes[1]);
        audioService.skipToPrevious();

        verify(mockContentService.getPreviousEpisode(episodes[1])).called(1);
      });

      test('should handle no next episode gracefully', () {
        when(mockContentService.getNextEpisode(any)).thenReturn(null);

        audioService.setCurrentAudioFileForTesting(sampleAudioFile);
        audioService.skipToNext();

        // Should not crash when no next episode is available
        expect(audioService.currentAudioFile, equals(sampleAudioFile));
      });

      test('should handle no previous episode gracefully', () {
        when(mockContentService.getPreviousEpisode(any)).thenReturn(null);

        audioService.setCurrentAudioFileForTesting(sampleAudioFile);
        audioService.skipToPrevious();

        // Should not crash when no previous episode is available
        expect(audioService.currentAudioFile, equals(sampleAudioFile));
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

      test('should handle episode completion with autoplay enabled', () {
        final episodes = TestUtils.createSampleAudioFileList(2);
        when(mockContentService.getNextEpisode(any)).thenReturn(episodes[1]);

        audioService.setCurrentAudioFileForTesting(episodes[0]);
        audioService.enableAutoplay(true);

        audioService.onEpisodeCompleted();

        verify(mockContentService.getNextEpisode(episodes[0])).called(1);
      });

      test('should handle episode completion with repeat enabled', () {
        audioService.setCurrentAudioFileForTesting(sampleAudioFile);
        audioService.toggleRepeat(); // Enable repeat

        audioService.onEpisodeCompleted();

        // Should restart the same episode
        expect(audioService.currentPosition, equals(Duration.zero));
      });

      test('should not autoplay when disabled', () {
        audioService.setCurrentAudioFileForTesting(sampleAudioFile);
        audioService.enableAutoplay(false);

        audioService.onEpisodeCompleted();

        // Should not request next episode
        verifyNever(mockContentService.getNextEpisode(any));
      });
    });

    group('Background Audio Integration', () {
      test('should delegate play calls to background handler', () {
        audioService.play(sampleAudioFile);

        verify(mockAudioHandler.play()).called(1);
      });

      test('should delegate pause calls to background handler', () {
        audioService.pause();

        verify(mockAudioHandler.pause()).called(1);
      });

      test('should delegate stop calls to background handler', () {
        audioService.stop();

        verify(mockAudioHandler.stop()).called(1);
      });

      test('should delegate seek calls to background handler', () {
        const position = Duration(minutes: 2);

        audioService.seekTo(position);

        verify(mockAudioHandler.seek(position)).called(1);
      });

      test('should set episode navigation callbacks on handler', () {
        // This should have been called during initialization
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

      test('should clear error when playing new audio', () {
        // Set error state first
        audioService.setErrorForTesting('Previous error');
        expect(audioService.hasError, isTrue);

        // Play new audio
        audioService.play(sampleAudioFile);

        expect(audioService.hasError, isFalse);
        expect(audioService.errorMessage, isNull);
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

    group('Progress Reporting', () {
      test('should report progress updates', () {
        bool progressReported = false;
        audioService.addListener(() {
          progressReported = true;
        });

        audioService.updateProgress(const Duration(minutes: 1));

        expect(progressReported, isTrue);
        expect(
            audioService.currentPosition, equals(const Duration(minutes: 1)));
      });

      test('should throttle rapid progress updates', () {
        int updateCount = 0;
        audioService.addListener(() {
          updateCount++;
        });

        // Rapidly update progress
        for (int i = 0; i < 10; i++) {
          audioService.updateProgress(Duration(seconds: i));
        }

        // Should have throttled some updates
        expect(updateCount, lessThan(10));
      });

      test('should report completion when progress reaches end', () {
        audioService.setDurationForTesting(const Duration(minutes: 5));
        audioService.setCurrentAudioFileForTesting(sampleAudioFile);

        // Mock content service to track completion
        when(mockContentService.setEpisodeCompletion(any, any))
            .thenAnswer((_) async {});

        audioService.updateProgress(const Duration(minutes: 5));

        verify(mockContentService.setEpisodeCompletion(sampleAudioFile.id, 1.0))
            .called(1);
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

    group('State Persistence', () {
      test('should save playback position', () {
        audioService.setCurrentAudioFileForTesting(sampleAudioFile);
        audioService.setPositionForTesting(const Duration(minutes: 2));

        audioService.savePlaybackState();

        verify(mockContentService.setEpisodeCompletion(
          sampleAudioFile.id,
          any,
        )).called(1);
      });

      test('should restore playback position', () async {
        when(mockContentService.getEpisodeCompletion(sampleAudioFile.id))
            .thenReturn(0.4); // 40% complete

        audioService.setDurationForTesting(const Duration(minutes: 10));

        await audioService.restorePlaybackPosition(sampleAudioFile);

        expect(
            audioService.currentPosition, equals(const Duration(minutes: 4)));
      });
    });

    group('Change Notification', () {
      test('should notify listeners on state changes', () {
        bool wasNotified = false;
        audioService.addListener(() {
          wasNotified = true;
        });

        audioService.setPlaybackStateForTesting(PlaybackState.playing);

        expect(wasNotified, isTrue);
      });

      test('should not notify on identical state', () {
        int notificationCount = 0;
        audioService.addListener(() {
          notificationCount++;
        });

        // Set same state multiple times
        audioService.setPlaybackStateForTesting(PlaybackState.stopped);
        audioService.setPlaybackStateForTesting(PlaybackState.stopped);

        expect(notificationCount, equals(0)); // No change, no notification
      });
    });

    group('Disposal and Cleanup', () {
      test('should dispose resources correctly', () {
        audioService.dispose();

        // Should not throw errors after disposal
        expect(() => audioService.play(sampleAudioFile), returnsNormally);
      });

      test('should stop playback on disposal', () {
        audioService.setPlaybackStateForTesting(PlaybackState.playing);

        audioService.dispose();

        verify(mockAudioHandler.stop()).called(1);
      });
    });

    group('Edge Cases and Stress Tests', () {
      test('should handle rapid play/pause operations', () {
        for (int i = 0; i < 10; i++) {
          audioService.play(sampleAudioFile);
          audioService.pause();
        }

        // Should handle rapid operations without errors
        expect(
            audioService.playbackState,
            anyOf([
              PlaybackState.paused,
              PlaybackState.loading,
              PlaybackState.playing,
            ]));
      });

      test('should handle null current audio file gracefully', () {
        audioService.setCurrentAudioFileForTesting(null);

        expect(() => audioService.pause(), returnsNormally);
        expect(() => audioService.stop(), returnsNormally);
        expect(() => audioService.skipToNext(), returnsNormally);
      });

      test('should handle very long audio files', () {
        audioService.setDurationForTesting(const Duration(hours: 10));
        audioService.setPositionForTesting(const Duration(hours: 5));

        expect(audioService.progress, closeTo(0.5, 0.01));
        expect(audioService.formattedTotalDuration, equals('10:00:00'));
      });

      test('should handle zero-duration audio files', () {
        audioService.setDurationForTesting(Duration.zero);

        expect(audioService.progress, equals(0.0));
        expect(audioService.formattedTotalDuration, equals('0:00'));
      });
    });

    group('Accessibility and User Preferences', () {
      test('should respect user playback speed preferences', () {
        audioService.setPlaybackSpeed(1.5);

        // When playing new audio, should maintain user preference
        audioService.play(sampleAudioFile);

        expect(audioService.playbackSpeed, equals(1.5));
      });

      test('should handle accessibility features', () {
        // Enable features that might be used for accessibility
        audioService.enableAutoplay(true);
        audioService.setPlaybackSpeed(0.75); // Slower for comprehension

        expect(audioService.autoplayEnabled, isTrue);
        expect(audioService.playbackSpeed, equals(0.75));
      });
    });
  });
}

// Extension to add testing methods to AudioService
extension AudioServiceTesting on AudioService {
  void setPlaybackStateForTesting(PlaybackState state) {
    // This would be implemented in the actual AudioService class
    // for testing purposes only
  }

  void setCurrentAudioFileForTesting(AudioFile? audioFile) {
    // This would be implemented in the actual AudioService class
  }

  void setDurationForTesting(Duration duration) {
    // This would be implemented in the actual AudioService class
  }

  void setPositionForTesting(Duration position) {
    // This would be implemented in the actual AudioService class
  }

  void setErrorForTesting(String error) {
    // This would be implemented in the actual AudioService class
  }
}
