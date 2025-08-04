import 'package:flutter_test/flutter_test.dart';
import 'package:from_fed_to_chain_app/services/audio_service.dart';
import 'package:from_fed_to_chain_app/models/audio_file.dart';
import '../test_utils.dart';

void main() {
  group('AudioService', () {
    late AudioService audioService;

    setUp(() {
      // Create AudioService with null dependencies for basic testing
      audioService = AudioService(null, null);
    });

    tearDown(() {
      audioService.dispose();
    });

    group('Initial State', () {
      test('has correct initial state', () {
        expect(audioService.playbackState, PlaybackState.stopped);
        expect(audioService.currentAudioFile, isNull);
        expect(audioService.currentPosition, Duration.zero);
        expect(audioService.totalDuration, Duration.zero);
        expect(audioService.playbackSpeed, 1.0);
        expect(audioService.errorMessage, isNull);
        expect(audioService.autoplayEnabled, isTrue);
        expect(audioService.repeatEnabled, isFalse);
      });

      test('computed properties return correct values', () {
        expect(audioService.isPlaying, isFalse);
        expect(audioService.isPaused, isFalse);
        expect(audioService.isLoading, isFalse);
        expect(audioService.hasError, isFalse);
        expect(audioService.isIdle, isTrue);
      });

      test('progress returns 0.0 initially', () {
        expect(audioService.progress, 0.0);
      });

      test('formatted durations return correct format initially', () {
        expect(audioService.formattedCurrentPosition, '0:00');
        expect(audioService.formattedTotalDuration, '0:00');
      });

      test('currentAudioId returns null initially', () {
        expect(audioService.currentAudioId, isNull);
      });
    });

    group('PlaybackState Enum', () {
      test('has all expected values', () {
        expect(PlaybackState.values, hasLength(5));
        expect(PlaybackState.values, contains(PlaybackState.stopped));
        expect(PlaybackState.values, contains(PlaybackState.playing));
        expect(PlaybackState.values, contains(PlaybackState.paused));
        expect(PlaybackState.values, contains(PlaybackState.loading));
        expect(PlaybackState.values, contains(PlaybackState.error));
      });
    });

    group('Settings', () {
      test('setPlaybackSpeed updates speed', () {
        audioService.setPlaybackSpeed(1.5);
        expect(audioService.playbackSpeed, 1.5);
      });

      test('setPlaybackSpeed notifies listeners', () {
        var notified = false;
        audioService.addListener(() => notified = true);

        audioService.setPlaybackSpeed(2.0);
        expect(notified, isTrue);
      });

      test('setPlaybackSpeed clamps speed to valid range', () {
        audioService.setPlaybackSpeed(0.1); // Below minimum
        expect(audioService.playbackSpeed, greaterThanOrEqualTo(0.25));

        audioService.setPlaybackSpeed(5.0); // Above maximum
        expect(audioService.playbackSpeed, lessThanOrEqualTo(3.0));
      });
    });

    group('Computed Properties', () {
      test('isPlaying returns false when state is stopped', () {
        expect(audioService.isPlaying, isFalse);
      });

      test('isPaused returns false when state is stopped', () {
        expect(audioService.isPaused, isFalse);
      });

      test('isLoading returns false when state is stopped', () {
        expect(audioService.isLoading, isFalse);
      });

      test('hasError returns false when state is stopped', () {
        expect(audioService.hasError, isFalse);
      });

      test('isIdle returns true when state is stopped', () {
        expect(audioService.isIdle, isTrue);
      });
    });

    group('Dispose', () {
      test('dispose cleans up resources', () {
        audioService.dispose();

        // Should not throw when accessing properties after dispose
        expect(() => audioService.playbackState, returnsNormally);
        expect(() => audioService.currentAudioFile, returnsNormally);
      });
    });

    group('Audio Playback Methods', () {
      test('playAudio accepts AudioFile parameter', () {
        final audioFile = TestUtils.createSampleAudioFile();

        // Should not throw - just testing method signature
        expect(() => audioService.playAudio(audioFile), returnsNormally);
      });

      test('pause method exists and can be called', () {
        expect(() => audioService.pause(), returnsNormally);
      });

      test('resume method exists and can be called', () {
        expect(() => audioService.resume(), returnsNormally);
      });

      test('stop method exists and can be called', () {
        expect(() => audioService.stop(), returnsNormally);
      });
    });

    group('Edge Cases', () {
      test('handles extreme playback speeds gracefully', () {
        audioService.setPlaybackSpeed(0.0);
        expect(audioService.playbackSpeed, greaterThan(0.0));

        audioService.setPlaybackSpeed(10.0);
        expect(audioService.playbackSpeed, lessThan(10.0));

        audioService.setPlaybackSpeed(double.infinity);
        expect(audioService.playbackSpeed.isFinite, isTrue);

        audioService.setPlaybackSpeed(double.nan);
        expect(audioService.playbackSpeed.isNaN, isFalse);
      });
    });
  });

  group('AudioService Integration', () {
    test('can be created with null dependencies', () {
      expect(() => AudioService(null, null), returnsNormally);
    });

    test('maintains initial state consistency', () {
      final audioService = AudioService(null, null);

      // Verify all initial state is consistent
      expect(audioService.playbackState, PlaybackState.stopped);
      expect(audioService.isIdle, isTrue);
      expect(audioService.isPlaying, isFalse);
      expect(audioService.currentAudioFile, isNull);
      expect(audioService.currentAudioId, isNull);
      expect(audioService.progress, 0.0);

      audioService.dispose();
    });

    test('can handle multiple setting changes', () {
      final audioService = AudioService(null, null);

      // Make multiple changes
      audioService.setPlaybackSpeed(1.5);

      // Verify changes are applied
      expect(audioService.playbackSpeed, 1.5);

      audioService.dispose();
    });
  });
}
