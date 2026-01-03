import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:just_audio/just_audio.dart';
import 'package:from_fed_to_chain_app/features/audio/services/local_player_adapter.dart';
import 'package:from_fed_to_chain_app/features/audio/services/player_adapter.dart';
import 'package:from_fed_to_chain_app/features/audio/services/player_state_notifier.dart';
import '../test_utils.dart';

@GenerateMocks([AudioPlayer])
import 'local_player_adapter_test.mocks.dart';

void main() {
  group('LocalPlayerAdapter', () {
    late MockAudioPlayer mockAudioPlayer;
    late LocalPlayerAdapter adapter;

    setUp(() {
      mockAudioPlayer = MockAudioPlayer();

      // Setup default stream behaviors
      when(mockAudioPlayer.playerStateStream).thenAnswer((_) => Stream.value(
            PlayerState(true, ProcessingState.ready),
          ));
      when(mockAudioPlayer.positionStream)
          .thenAnswer((_) => Stream.value(Duration.zero));
      when(mockAudioPlayer.durationStream)
          .thenAnswer((_) => Stream.value(const Duration(minutes: 5)));
      when(mockAudioPlayer.speedStream).thenAnswer((_) => Stream.value(1.0));
      when(mockAudioPlayer.speed).thenReturn(1.0);

      adapter = LocalPlayerAdapter(audioPlayer: mockAudioPlayer);
    });

    test('initial state is correct', () {
      expect(adapter.currentState,
          AppPlaybackState.playing); // Because we mocked ready/playing
      expect(adapter.currentPosition, Duration.zero);
      expect(adapter.currentSpeed, 1.0);
    });

    test('play calls player.play', () async {
      when(mockAudioPlayer.play()).thenAnswer((_) async {});
      await adapter.play();
      verify(mockAudioPlayer.play()).called(1);
    });

    test('pause calls player.pause', () async {
      when(mockAudioPlayer.pause()).thenAnswer((_) async {});
      await adapter.pause();
      verify(mockAudioPlayer.pause()).called(1);
    });

    test('stop calls player.stop', () async {
      when(mockAudioPlayer.stop()).thenAnswer((_) async {});
      await adapter.stop();
      verify(mockAudioPlayer.stop()).called(1);
    });

    test('seek calls player.seek', () async {
      const position = Duration(seconds: 10);
      when(mockAudioPlayer.seek(position)).thenAnswer((_) async {});
      await adapter.seek(position);
      verify(mockAudioPlayer.seek(position)).called(1);
    });

    test('setSpeed calls player.setSpeed and updates stream', () async {
      when(mockAudioPlayer.setSpeed(any)).thenAnswer((_) async {});

      final futureStep = expectLater(adapter.speedStream, emits(1.5));

      await adapter.setSpeed(1.5);

      await futureStep;

      verify(mockAudioPlayer.setSpeed(1.5)).called(1);
      expect(adapter.currentSpeed, 1.5);
    });

    test('setAudioSource calls player.setAudioSource', () async {
      final audioFile = TestUtils.createSampleAudioFile();
      when(mockAudioPlayer.setAudioSource(any,
              initialPosition: anyNamed('initialPosition')))
          .thenAnswer((_) async => null);

      await adapter.setAudioSource(audioFile);

      verify(mockAudioPlayer.setAudioSource(any,
              initialPosition: anyNamed('initialPosition')))
          .called(1);
    });

    test('skipForward calculates correct position', () async {
      // Mock current position as 10s via stream update or internal state
      // Since adapter listens to stream in constructor, we might need to push a value.
      // However, we can't push to the mocked stream easily after constructor unless we used a StreamController.
      // Refactoring test setup to use Controllers.
    });

    test('dispose cleans up resources', () async {
      when(mockAudioPlayer.dispose()).thenAnswer((_) async {});
      await adapter.dispose();
      verify(mockAudioPlayer.dispose()).called(1);
    });
  });

  group('LocalPlayerAdapter - Stream Logic', () {
    late MockAudioPlayer mockAudioPlayer;
    late StreamController<PlayerState> playerStateController;
    late StreamController<Duration> positionController;
    late StreamController<Duration?> durationController;

    setUp(() {
      mockAudioPlayer = MockAudioPlayer();
      playerStateController = StreamController<PlayerState>.broadcast();
      positionController = StreamController<Duration>.broadcast();
      durationController = StreamController<Duration?>.broadcast();

      when(mockAudioPlayer.playerStateStream)
          .thenAnswer((_) => playerStateController.stream);
      when(mockAudioPlayer.positionStream)
          .thenAnswer((_) => positionController.stream);
      when(mockAudioPlayer.durationStream)
          .thenAnswer((_) => durationController.stream);
      when(mockAudioPlayer.speed).thenReturn(1.0);
    });

    tearDown(() {
      playerStateController.close();
      positionController.close();
      durationController.close();
    });

    test('maps ProcessingState correctly', () async {
      final adapter = LocalPlayerAdapter(audioPlayer: mockAudioPlayer);

      expectLater(
          adapter.playbackStateStream,
          emitsInOrder([
            AppPlaybackState.loading,
            AppPlaybackState.playing,
            AppPlaybackState.paused,
            AppPlaybackState.completed,
            AppPlaybackState.stopped,
          ]));

      playerStateController.add(PlayerState(false, ProcessingState.loading));
      playerStateController.add(PlayerState(true, ProcessingState.ready));
      playerStateController.add(PlayerState(false, ProcessingState.ready));
      playerStateController.add(PlayerState(false, ProcessingState.completed));
      playerStateController.add(PlayerState(false, ProcessingState.idle));
    });

    test('updates duration', () async {
      final adapter = LocalPlayerAdapter(audioPlayer: mockAudioPlayer);
      const duration = Duration(minutes: 3);

      expectLater(adapter.durationStream, emits(duration));

      durationController.add(duration);
    });

    test('updates position', () async {
      final adapter = LocalPlayerAdapter(audioPlayer: mockAudioPlayer);
      const position = Duration(seconds: 45);

      expectLater(adapter.positionStream, emits(position));

      positionController.add(position);
    });
  });

  group('LocalPlayerAdapter - Skip Operations', () {
    late MockAudioPlayer mockAudioPlayer;
    late StreamController<PlayerState> playerStateController;
    late StreamController<Duration> positionController;
    late StreamController<Duration?> durationController;
    late LocalPlayerAdapter adapter;

    setUp(() {
      mockAudioPlayer = MockAudioPlayer();
      playerStateController = StreamController<PlayerState>.broadcast();
      positionController = StreamController<Duration>.broadcast();
      durationController = StreamController<Duration?>.broadcast();

      when(mockAudioPlayer.playerStateStream)
          .thenAnswer((_) => playerStateController.stream);
      when(mockAudioPlayer.positionStream)
          .thenAnswer((_) => positionController.stream);
      when(mockAudioPlayer.durationStream)
          .thenAnswer((_) => durationController.stream);
      when(mockAudioPlayer.speed).thenReturn(1.0);
      when(mockAudioPlayer.seek(any)).thenAnswer((_) async {});

      adapter = LocalPlayerAdapter(audioPlayer: mockAudioPlayer);
    });

    tearDown(() {
      playerStateController.close();
      positionController.close();
      durationController.close();
    });

    test('skipForward seeks correctly', () async {
      // Set current position and duration via stream
      positionController.add(const Duration(seconds: 30));
      durationController.add(const Duration(minutes: 5));
      await Future.delayed(const Duration(milliseconds: 50));

      await adapter.skipForward(const Duration(seconds: 30));

      verify(mockAudioPlayer.seek(const Duration(seconds: 60))).called(1);
    });

    test('skipForward caps at duration', () async {
      positionController.add(const Duration(minutes: 4, seconds: 50));
      durationController.add(const Duration(minutes: 5));
      await Future.delayed(const Duration(milliseconds: 50));

      await adapter.skipForward(const Duration(seconds: 30));

      // Should cap at duration (5 min)
      verify(mockAudioPlayer.seek(const Duration(minutes: 5))).called(1);
    });

    test('skipBackward seeks correctly', () async {
      positionController.add(const Duration(seconds: 30));
      await Future.delayed(const Duration(milliseconds: 50));

      await adapter.skipBackward(const Duration(seconds: 10));

      verify(mockAudioPlayer.seek(const Duration(seconds: 20))).called(1);
    });

    test('skipBackward does not go below zero', () async {
      positionController.add(const Duration(seconds: 5));
      await Future.delayed(const Duration(milliseconds: 50));

      await adapter.skipBackward(const Duration(seconds: 10));

      verify(mockAudioPlayer.seek(Duration.zero)).called(1);
    });
  });

  group('LocalPlayerAdapter - Error Handling', () {
    late MockAudioPlayer mockAudioPlayer;
    late LocalPlayerAdapter adapter;

    setUp(() {
      mockAudioPlayer = MockAudioPlayer();

      when(mockAudioPlayer.playerStateStream)
          .thenAnswer((_) => const Stream.empty());
      when(mockAudioPlayer.positionStream)
          .thenAnswer((_) => const Stream.empty());
      when(mockAudioPlayer.durationStream)
          .thenAnswer((_) => const Stream.empty());
      when(mockAudioPlayer.speed).thenReturn(1.0);

      adapter = LocalPlayerAdapter(audioPlayer: mockAudioPlayer);
    });

    test('play throws PlayerAdapterException on error', () async {
      when(mockAudioPlayer.play()).thenThrow(Exception('Play failed'));

      expect(
        () => adapter.play(),
        throwsA(isA<PlayerAdapterException>()),
      );
    });

    test('pause throws PlayerAdapterException on error', () async {
      when(mockAudioPlayer.pause()).thenThrow(Exception('Pause failed'));

      expect(
        () => adapter.pause(),
        throwsA(isA<PlayerAdapterException>()),
      );
    });

    test('stop throws PlayerAdapterException on error', () async {
      when(mockAudioPlayer.stop()).thenThrow(Exception('Stop failed'));

      expect(
        () => adapter.stop(),
        throwsA(isA<PlayerAdapterException>()),
      );
    });

    test('seek throws PlayerAdapterException on error', () async {
      when(mockAudioPlayer.seek(any)).thenThrow(Exception('Seek failed'));

      expect(
        () => adapter.seek(const Duration(seconds: 10)),
        throwsA(isA<PlayerAdapterException>()),
      );
    });

    test('setSpeed throws PlayerAdapterException on error', () async {
      when(mockAudioPlayer.setSpeed(any)).thenThrow(Exception('Speed failed'));

      expect(
        () => adapter.setSpeed(1.5),
        throwsA(isA<PlayerAdapterException>()),
      );
    });

    test('setAudioSource throws PlayerAdapterException on error', () async {
      when(mockAudioPlayer.setAudioSource(any,
              initialPosition: anyNamed('initialPosition')))
          .thenThrow(Exception('Source failed'));

      expect(
        () => adapter.setAudioSource(TestUtils.createSampleAudioFile()),
        throwsA(isA<PlayerAdapterException>()),
      );
    });

    test('dispose only runs once', () async {
      when(mockAudioPlayer.dispose()).thenAnswer((_) async {});

      await adapter.dispose();
      await adapter.dispose(); // Second call should be no-op

      verify(mockAudioPlayer.dispose()).called(1);
    });
  });
}
