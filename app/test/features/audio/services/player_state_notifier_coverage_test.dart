import 'package:flutter_test/flutter_test.dart';
import 'package:from_fed_to_chain_app/features/audio/services/player_state_notifier.dart';

void main() {
  group('PlayerStateNotifier Coverage Tests', () {
    late PlayerStateNotifier notifier;

    setUp(() {
      notifier = PlayerStateNotifier();
    });

    test('Initial state correctness', () {
      expect(notifier.playbackState, AppPlaybackState.stopped);
      expect(notifier.currentPosition, Duration.zero);
      expect(notifier.totalDuration, Duration.zero);
      expect(notifier.playbackSpeed, 1.0);
      expect(notifier.errorMessage, isNull);
      expect(notifier.isIdle, isTrue);
      expect(notifier.isPlaying, isFalse);
      expect(notifier.progress, 0.0);
    });

    test('updateState notifications and computed props', () {
      bool notified = false;
      notifier.addListener(() => notified = true);

      notifier.updateState(AppPlaybackState.playing);
      expect(notified, isTrue);
      expect(notifier.isPlaying, isTrue);
      expect(notifier.isPaused, isFalse);

      notified = false;
      notifier.updateState(AppPlaybackState.playing); // No change
      expect(notified, isFalse);
    });

    test('updateState clears error', () {
      notifier.setError('test error');
      expect(notifier.hasError, isTrue);
      expect(notifier.errorMessage, 'test error');

      notifier.updateState(AppPlaybackState.playing);
      expect(notifier.hasError, isFalse);
      expect(notifier.errorMessage, isNull);
    });

    test('updatePosition notifications', () {
      bool notified = false;
      notifier.addListener(() => notified = true);

      notifier.updatePosition(const Duration(seconds: 10));
      expect(notified, isTrue);
      expect(notifier.currentPosition.inSeconds, 10);

      notified = false;
      notifier.updatePosition(const Duration(seconds: 10));
      expect(notified, isFalse);
    });

    test('updateDuration notifications', () {
      bool notified = false;
      notifier.addListener(() => notified = true);

      notifier.updateDuration(const Duration(minutes: 5));
      expect(notified, isTrue);
      expect(notifier.totalDuration.inMinutes, 5);

      notified = false;
      notifier.updateDuration(const Duration(minutes: 5));
      expect(notified, isFalse);
    });

    test('updateSpeed notifications', () {
      bool notified = false;
      notifier.addListener(() => notified = true);

      notifier.updateSpeed(1.5);
      expect(notified, isTrue);
      expect(notifier.playbackSpeed, 1.5);

      notified = false;
      notifier.updateSpeed(1.5);
      expect(notified, isFalse);
    });

    test('setError notifications', () {
      notifier.setError('Fatal error');
      expect(notifier.hasError, isTrue);
      expect(notifier.errorMessage, 'Fatal error');
      expect(notifier.playbackState, AppPlaybackState.error);
    });

    test('clearError notifications', () {
      notifier.setError('Fatal error');
      notifier.clearError();
      expect(notifier.hasError, isFalse);
      expect(notifier.errorMessage, isNull);
      expect(notifier.playbackState, AppPlaybackState.stopped);

      // Calling clearError when no error should do nothing?
      bool notified = false;
      notifier.addListener(() => notified = true);
      notifier.clearError();
      expect(notified, isFalse);
    });

    test('onPlaybackCompleted', () {
      notifier.updatePosition(const Duration(seconds: 100));
      notifier.onPlaybackCompleted();
      expect(notifier.isCompleted, isTrue);
      expect(notifier.currentPosition, Duration.zero);
    });

    test('reset', () {
      notifier.updateState(AppPlaybackState.playing);
      notifier.updatePosition(const Duration(seconds: 50));
      notifier.updateDuration(const Duration(minutes: 2));
      notifier.updateSpeed(2.0);

      notifier.reset();
      expect(notifier.isIdle, isTrue);
      expect(notifier.currentPosition, Duration.zero);
      expect(notifier.totalDuration, Duration.zero);
      expect(notifier.playbackSpeed, 1.0);
    });

    test('progress calculation', () {
      expect(notifier.progress, 0.0); // duration 0

      notifier.updateDuration(const Duration(seconds: 100));
      expect(notifier.progress, 0.0);

      notifier.updatePosition(const Duration(seconds: 50));
      expect(notifier.progress, 0.5);

      notifier.updatePosition(const Duration(seconds: 150)); // over duration
      expect(notifier.progress, 1.0);
    });

    test('formatted strings', () {
      notifier.updatePosition(const Duration(minutes: 1, seconds: 30));
      expect(notifier.formattedCurrentPosition, '1:30');

      notifier.updatePosition(const Duration(hours: 1, minutes: 1, seconds: 5));
      expect(notifier.formattedCurrentPosition, '1:01:05');

      notifier
          .updateDuration(const Duration(minutes: 65, seconds: 0)); // 1:05:00
      expect(notifier.formattedTotalDuration, '1:05:00');

      notifier.updateDuration(const Duration(seconds: 45));
      expect(notifier.formattedTotalDuration, '0:45');
    });

    // Test testing methods
    test('Testing methods work', () {
      notifier.setPlaybackStateForTesting(AppPlaybackState.loading);
      expect(notifier.isLoading, isTrue);

      notifier.setPositionForTesting(const Duration(seconds: 1));
      expect(notifier.currentPosition.inSeconds, 1);

      notifier.setDurationForTesting(const Duration(seconds: 10));
      expect(notifier.totalDuration.inSeconds, 10);

      notifier.setSpeedForTesting(0.5);
      expect(notifier.playbackSpeed, 0.5);

      notifier.setErrorForTesting('Test E');
      expect(notifier.hasError, isTrue);

      notifier.clearErrorForTesting();
      expect(notifier.hasError, isFalse);
    });
  });
}
