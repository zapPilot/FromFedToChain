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

    test('pause calls player.pause', () async {
      when(mockPlayer.pause()).thenAnswer((_) async {});
      await controller.pause();
      verify(mockPlayer.pause()).called(1);
    });

    test('stop calls player.stop', () async {
      when(mockPlayer.stop()).thenAnswer((_) async {});
      await controller.stop();
      verify(mockPlayer.stop()).called(1);
    });

    test('seek calls player.seek', () async {
      when(mockPlayer.seek(any)).thenAnswer((_) async {});
      await controller.seek(Duration.zero);
      verify(mockPlayer.seek(Duration.zero)).called(1);
    });

    test('skipForward calls player.skipForward', () async {
      when(mockPlayer.skipForward(any)).thenAnswer((_) async {});
      await controller.skipForward();
      verify(mockPlayer.skipForward(any)).called(1);
    });

    test('play handles error', () async {
      final audioFile = TestUtils.createSampleAudioFile();
      // Stub setAudioSource to succeed (to get to play)
      when(mockPlayer.setAudioSource(any,
              initialPosition: anyNamed('initialPosition')))
          .thenAnswer((_) async {});
      // Stub play to throw
      when(mockPlayer.play()).thenThrow(Exception('Failed'));

      try {
        await controller.play(audioFile);
      } catch (e) {
        // Expected
      }

      verify(mockPlayer.setAudioSource(any,
              initialPosition: anyNamed('initialPosition')))
          .called(1);
      verify(mockPlayer.play()).called(1);
      verify(mockNotifier.setError(any)).called(1);
    });
  });
}
