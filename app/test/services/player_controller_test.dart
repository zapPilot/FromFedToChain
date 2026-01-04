import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:from_fed_to_chain_app/features/audio/services/player_controller.dart';
import 'package:from_fed_to_chain_app/features/audio/services/player_adapter.dart';
import 'package:from_fed_to_chain_app/features/audio/services/player_state_notifier.dart';
import '../test_utils.dart';

@GenerateMocks([IPlayerAdapter, PlayerStateNotifier])
import 'player_controller_test.mocks.dart';

void main() {
  group('PlayerController', () {
    late MockIPlayerAdapter mockPlayer;
    late MockPlayerStateNotifier mockNotifier;
    late PlayerController controller;

    // Stream controllers to simulate player events
    late StreamController<AppPlaybackState> stateController;
    late StreamController<Duration> positionController;
    late StreamController<Duration?> durationController;
    late StreamController<double> speedController;

    setUp(() {
      mockPlayer = MockIPlayerAdapter();
      mockNotifier = MockPlayerStateNotifier();

      stateController = StreamController<AppPlaybackState>.broadcast();
      positionController = StreamController<Duration>.broadcast();
      durationController = StreamController<Duration?>.broadcast();
      speedController = StreamController<double>.broadcast();

      when(mockPlayer.playbackStateStream)
          .thenAnswer((_) => stateController.stream);
      when(mockPlayer.positionStream)
          .thenAnswer((_) => positionController.stream);
      when(mockPlayer.durationStream)
          .thenAnswer((_) => durationController.stream);
      when(mockPlayer.speedStream).thenAnswer((_) => speedController.stream);

      controller = PlayerController(mockPlayer, mockNotifier);
    });

    tearDown(() {
      stateController.close();
      positionController.close();
      durationController.close();
      speedController.close();
      controller.dispose();
    });

    test('initialization sets up subscriptions', () async {
      // Verify no initial interaction (subscriptions are active but waiting for events)
      verifyZeroInteractions(mockNotifier);

      // Emit events
      stateController.add(AppPlaybackState.playing);
      await pumpEventQueue();
      verify(mockNotifier.updateState(AppPlaybackState.playing)).called(1);

      positionController.add(const Duration(seconds: 10));
      await pumpEventQueue();
      verify(mockNotifier.updatePosition(const Duration(seconds: 10)))
          .called(1);

      durationController.add(const Duration(minutes: 5));
      await pumpEventQueue();
      verify(mockNotifier.updateDuration(const Duration(minutes: 5))).called(1);

      speedController.add(1.5);
      await pumpEventQueue();
      verify(mockNotifier.updateSpeed(1.5)).called(1);
    });

    test('play logic sequence', () async {
      final audioFile = TestUtils.createSampleAudioFile();

      when(mockPlayer.setAudioSource(any,
              initialPosition: anyNamed('initialPosition')))
          .thenAnswer((_) async {});
      when(mockPlayer.play()).thenAnswer((_) async {});

      await controller.play(audioFile);

      verify(mockNotifier.clearError()).called(1);
      verify(mockPlayer.setAudioSource(audioFile, initialPosition: null))
          .called(1);
      verify(mockPlayer.play()).called(1);
    });

    test('resume calls player.play', () async {
      when(mockPlayer.play()).thenAnswer((_) async {});
      await controller.resume();
      verify(mockPlayer.play()).called(1);
    });

    test('setSpeed calls player.setSpeed', () async {
      when(mockPlayer.setSpeed(any)).thenAnswer((_) async {});
      await controller.setSpeed(2.0);
      verify(mockPlayer.setSpeed(2.0)).called(1);
    });

    test('setSpeed handles error gracefully (doesn\'t set error state)',
        () async {
      when(mockPlayer.setSpeed(any)).thenThrow(Exception('Speed failed'));
      await controller.setSpeed(2.0);
      verify(mockPlayer.setSpeed(2.0)).called(1);
      verifyNever(mockNotifier.setError(any));
    });

    test('skipBackward calls player.skipBackward', () async {
      when(mockPlayer.skipBackward(any)).thenAnswer((_) async {});
      await controller.skipBackward();
      verify(mockPlayer.skipBackward(any)).called(1);
    });

    test('isValidAudioFile validation', () {
      final valid = TestUtils.createSampleAudioFile();
      final invalid = valid.copyWith(streamingUrl: '');
      final withSpace = valid.copyWith(streamingUrl: ' ');

      expect(controller.isValidAudioFile(valid), isTrue);
      expect(controller.isValidAudioFile(invalid), isFalse);
      expect(controller.isValidAudioFile(withSpace), isFalse);
      expect(controller.isValidAudioFile(null), isFalse);
    });

    test('synchronous getters delegate to player', () {
      when(mockPlayer.currentState).thenReturn(AppPlaybackState.playing);
      when(mockPlayer.currentPosition).thenReturn(const Duration(seconds: 5));
      when(mockPlayer.currentDuration).thenReturn(const Duration(seconds: 10));
      when(mockPlayer.currentSpeed).thenReturn(1.5);

      expect(controller.currentState, AppPlaybackState.playing);
      expect(controller.currentPosition, const Duration(seconds: 5));
      expect(controller.currentDuration, const Duration(seconds: 10));
      expect(controller.currentSpeed, 1.5);
    });

    group('Command Error Handling', () {
      test('pause handles error', () async {
        when(mockPlayer.pause()).thenThrow(Exception('Fail'));
        expect(() => controller.pause(), throwsException);
        verify(mockNotifier.setError(any)).called(1);
      });

      test('resume handles error', () async {
        when(mockPlayer.play()).thenThrow(Exception('Fail'));
        expect(() => controller.resume(), throwsException);
        verify(mockNotifier.setError(any)).called(1);
      });

      test('stop handles error', () async {
        when(mockPlayer.stop()).thenThrow(Exception('Fail'));
        expect(() => controller.stop(), throwsException);
        verify(mockNotifier.setError(any)).called(1);
      });

      test('seek handles error', () async {
        when(mockPlayer.seek(any)).thenThrow(Exception('Fail'));
        expect(() => controller.seek(Duration.zero), throwsException);
        verify(mockNotifier.setError(any)).called(1);
      });

      test('skipForward handles error', () async {
        when(mockPlayer.skipForward(any)).thenThrow(Exception('Fail'));
        expect(() => controller.skipForward(), throwsException);
        verify(mockNotifier.setError(any)).called(1);
      });

      test('skipBackward handles error', () async {
        when(mockPlayer.skipBackward(any)).thenThrow(Exception('Fail'));
        expect(() => controller.skipBackward(), throwsException);
        verify(mockNotifier.setError(any)).called(1);
      });

      test('play handles source setup error', () async {
        final audioFile = TestUtils.createSampleAudioFile();
        when(mockPlayer.setAudioSource(any,
                initialPosition: anyNamed('initialPosition')))
            .thenAnswer((_) async => throw Exception('Source fail'));

        await expectLater(
            controller.play(audioFile), throwsA(isA<PlayerAdapterException>()));

        verify(mockNotifier.clearError()).called(1);
        verify(mockNotifier.setError(argThat(contains('Source fail'))))
            .called(1);
      });
    });

    test('dispose cancels subscriptions and disposes player', () async {
      await controller.dispose();

      // Emit events after dispose - should NOT update notifier
      stateController.add(AppPlaybackState.paused);
      await pumpEventQueue();
      verifyNever(mockNotifier.updateState(any));

      verify(mockPlayer.dispose()).called(1);
    });
  });
}
