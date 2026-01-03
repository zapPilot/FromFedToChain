import 'package:flutter_test/flutter_test.dart';

import 'package:from_fed_to_chain_app/features/audio/services/player_state_notifier.dart';

void main() {
  late PlayerStateNotifier notifier;

  setUp(() {
    notifier = PlayerStateNotifier();
  });

  group('PlayerStateNotifier - Initial State', () {
    test('should have stopped playback state initially', () {
      expect(notifier.playbackState, AppPlaybackState.stopped);
    });

    test('should have zero position initially', () {
      expect(notifier.currentPosition, Duration.zero);
    });

    test('should have zero duration initially', () {
      expect(notifier.totalDuration, Duration.zero);
    });

    test('should have 1.0 playback speed initially', () {
      expect(notifier.playbackSpeed, 1.0);
    });

    test('should have no error initially', () {
      expect(notifier.errorMessage, isNull);
    });
  });

  group('PlayerStateNotifier - Computed Properties', () {
    test('isPlaying should be true when playing', () {
      notifier.setPlaybackStateForTesting(AppPlaybackState.playing);
      expect(notifier.isPlaying, isTrue);
      expect(notifier.isPaused, isFalse);
      expect(notifier.isLoading, isFalse);
    });

    test('isPaused should be true when paused', () {
      notifier.setPlaybackStateForTesting(AppPlaybackState.paused);
      expect(notifier.isPaused, isTrue);
      expect(notifier.isPlaying, isFalse);
    });

    test('isLoading should be true when loading', () {
      notifier.setPlaybackStateForTesting(AppPlaybackState.loading);
      expect(notifier.isLoading, isTrue);
    });

    test('hasError should be true when in error state', () {
      notifier.setErrorForTesting('Test error');
      expect(notifier.hasError, isTrue);
    });

    test('isIdle should be true when stopped', () {
      notifier.setPlaybackStateForTesting(AppPlaybackState.stopped);
      expect(notifier.isIdle, isTrue);
    });

    test('isCompleted should be true when completed', () {
      notifier.setPlaybackStateForTesting(AppPlaybackState.completed);
      expect(notifier.isCompleted, isTrue);
    });
  });

  group('PlayerStateNotifier - Progress', () {
    test('progress should return 0 when duration is 0', () {
      expect(notifier.progress, 0.0);
    });

    test('progress should calculate correctly', () {
      notifier.setDurationForTesting(const Duration(seconds: 100));
      notifier.setPositionForTesting(const Duration(seconds: 50));
      expect(notifier.progress, 0.5);
    });

    test('progress should clamp to 1.0 max', () {
      notifier.setDurationForTesting(const Duration(seconds: 100));
      notifier.setPositionForTesting(const Duration(seconds: 150));
      expect(notifier.progress, 1.0);
    });

    test('progress should clamp to 0.0 min', () {
      notifier.setDurationForTesting(const Duration(seconds: 100));
      notifier.setPositionForTesting(Duration.zero);
      expect(notifier.progress, 0.0);
    });
  });

  group('PlayerStateNotifier - Duration Formatting', () {
    test('should format short duration correctly', () {
      notifier.setPositionForTesting(const Duration(minutes: 3, seconds: 25));
      expect(notifier.formattedCurrentPosition, '3:25');
    });

    test('should format duration with hours', () {
      notifier.setDurationForTesting(
          const Duration(hours: 1, minutes: 5, seconds: 30));
      expect(notifier.formattedTotalDuration, '1:05:30');
    });

    test('should pad seconds with leading zero', () {
      notifier.setPositionForTesting(const Duration(minutes: 1, seconds: 5));
      expect(notifier.formattedCurrentPosition, '1:05');
    });

    test('should format zero duration correctly', () {
      expect(notifier.formattedCurrentPosition, '0:00');
    });

    test('should format duration just under an hour', () {
      notifier.setPositionForTesting(const Duration(minutes: 59, seconds: 59));
      expect(notifier.formattedCurrentPosition, '59:59');
    });

    test('should format duration exactly one hour', () {
      notifier.setPositionForTesting(const Duration(hours: 1));
      expect(notifier.formattedCurrentPosition, '1:00:00');
    });
  });

  group('PlayerStateNotifier - updateState', () {
    test('should update state and notify listeners', () {
      int notifyCount = 0;
      notifier.addListener(() => notifyCount++);

      notifier.updateState(AppPlaybackState.playing);
      expect(notifier.playbackState, AppPlaybackState.playing);
      expect(notifyCount, 1);
    });

    test('should not notify when state is unchanged', () {
      int notifyCount = 0;
      notifier.addListener(() => notifyCount++);

      notifier.updateState(AppPlaybackState.stopped);
      expect(notifyCount, 0); // Already stopped initially
    });

    test('should clear error when transitioning from error state', () {
      notifier.setError('Test error');
      expect(notifier.errorMessage, isNotNull);

      notifier.updateState(AppPlaybackState.playing);
      expect(notifier.errorMessage, isNull);
    });
  });

  group('PlayerStateNotifier - updatePosition', () {
    test('should update position and notify listeners', () {
      int notifyCount = 0;
      notifier.addListener(() => notifyCount++);

      notifier.updatePosition(const Duration(seconds: 30));
      expect(notifier.currentPosition, const Duration(seconds: 30));
      expect(notifyCount, 1);
    });

    test('should not notify when position is unchanged', () {
      notifier.updatePosition(const Duration(seconds: 10));

      int notifyCount = 0;
      notifier.addListener(() => notifyCount++);

      notifier.updatePosition(const Duration(seconds: 10));
      expect(notifyCount, 0);
    });
  });

  group('PlayerStateNotifier - updateDuration', () {
    test('should update duration and notify listeners', () {
      int notifyCount = 0;
      notifier.addListener(() => notifyCount++);

      notifier.updateDuration(const Duration(minutes: 5));
      expect(notifier.totalDuration, const Duration(minutes: 5));
      expect(notifyCount, 1);
    });

    test('should not notify when duration is unchanged', () {
      notifier.updateDuration(const Duration(minutes: 3));

      int notifyCount = 0;
      notifier.addListener(() => notifyCount++);

      notifier.updateDuration(const Duration(minutes: 3));
      expect(notifyCount, 0);
    });
  });

  group('PlayerStateNotifier - updateSpeed', () {
    test('should update speed and notify listeners', () {
      int notifyCount = 0;
      notifier.addListener(() => notifyCount++);

      notifier.updateSpeed(1.5);
      expect(notifier.playbackSpeed, 1.5);
      expect(notifyCount, 1);
    });

    test('should not notify when speed is unchanged', () {
      int notifyCount = 0;
      notifier.addListener(() => notifyCount++);

      notifier.updateSpeed(1.0); // Already 1.0 initially
      expect(notifyCount, 0);
    });
  });

  group('PlayerStateNotifier - Error Handling', () {
    test('setError should set error state and message', () {
      notifier.setError('Network error');

      expect(notifier.playbackState, AppPlaybackState.error);
      expect(notifier.errorMessage, 'Network error');
      expect(notifier.hasError, isTrue);
    });

    test('clearError should clear error and reset to stopped', () {
      notifier.setError('Test error');
      notifier.clearError();

      expect(notifier.errorMessage, isNull);
      expect(notifier.playbackState, AppPlaybackState.stopped);
      expect(notifier.hasError, isFalse);
    });

    test('clearError should not notify if no error exists', () {
      int notifyCount = 0;
      notifier.addListener(() => notifyCount++);

      notifier.clearError();
      expect(notifyCount, 0);
    });
  });

  group('PlayerStateNotifier - Playback Completion', () {
    test('onPlaybackCompleted should set completed and reset position', () {
      notifier.setPositionForTesting(const Duration(minutes: 5));

      notifier.onPlaybackCompleted();

      expect(notifier.playbackState, AppPlaybackState.completed);
      expect(notifier.currentPosition, Duration.zero);
      expect(notifier.isCompleted, isTrue);
    });
  });

  group('PlayerStateNotifier - Reset', () {
    test('reset should restore all state to initial values', () {
      // Set up some state
      notifier.setPlaybackStateForTesting(AppPlaybackState.playing);
      notifier.setPositionForTesting(const Duration(minutes: 2));
      notifier.setDurationForTesting(const Duration(minutes: 10));
      notifier.setSpeedForTesting(2.0);
      notifier.setErrorForTesting('Test error');

      // Reset
      notifier.reset();

      // Verify all initial values
      expect(notifier.playbackState, AppPlaybackState.stopped);
      expect(notifier.currentPosition, Duration.zero);
      expect(notifier.totalDuration, Duration.zero);
      expect(notifier.playbackSpeed, 1.0);
      expect(notifier.errorMessage, isNull);
    });
  });

  group('PlayerStateNotifier - Testing Methods', () {
    test('setPlaybackStateForTesting should update state', () {
      notifier.setPlaybackStateForTesting(AppPlaybackState.loading);
      expect(notifier.playbackState, AppPlaybackState.loading);
    });

    test('setPositionForTesting should update position', () {
      notifier.setPositionForTesting(const Duration(seconds: 45));
      expect(notifier.currentPosition, const Duration(seconds: 45));
    });

    test('setDurationForTesting should update duration', () {
      notifier.setDurationForTesting(const Duration(minutes: 8));
      expect(notifier.totalDuration, const Duration(minutes: 8));
    });

    test('setSpeedForTesting should update speed', () {
      notifier.setSpeedForTesting(0.75);
      expect(notifier.playbackSpeed, 0.75);
    });

    test('setErrorForTesting should set error', () {
      notifier.setErrorForTesting('Test error message');
      expect(notifier.errorMessage, 'Test error message');
      expect(notifier.hasError, isTrue);
    });

    test('clearErrorForTesting should clear error', () {
      notifier.setErrorForTesting('Some error');
      notifier.clearErrorForTesting();

      expect(notifier.errorMessage, isNull);
      expect(notifier.playbackState, AppPlaybackState.stopped);
    });
  });

  group('PlayerStateNotifier - ChangeNotifier', () {
    test('should notify listeners on all state changes', () {
      int notifyCount = 0;
      notifier.addListener(() => notifyCount++);

      notifier.updateState(AppPlaybackState.playing);
      notifier.updatePosition(const Duration(seconds: 10));
      notifier.updateDuration(const Duration(minutes: 5));
      notifier.updateSpeed(1.5);
      notifier.setError('Error');
      notifier.clearError();
      notifier.reset();

      expect(notifyCount, 7);
    });
  });
}
