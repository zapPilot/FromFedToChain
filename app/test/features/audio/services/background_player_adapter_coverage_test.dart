import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:audio_service/audio_service.dart';
import 'package:from_fed_to_chain_app/features/audio/services/background_audio_handler.dart';
import 'package:from_fed_to_chain_app/features/audio/services/background_player_adapter.dart';
import 'package:from_fed_to_chain_app/features/audio/services/player_adapter.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';

import 'package:rxdart/rxdart.dart';
import 'package:from_fed_to_chain_app/features/audio/services/background_audio_handler.dart';
import 'package:from_fed_to_chain_app/features/audio/services/background_player_adapter.dart';
import 'package:from_fed_to_chain_app/features/audio/services/player_adapter.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';

@GenerateMocks([BackgroundAudioHandler])
import 'background_player_adapter_coverage_test.mocks.dart';

void main() {
  group('BackgroundPlayerAdapter Coverage Tests', () {
    late MockBackgroundAudioHandler mockHandler;
    late BackgroundPlayerAdapter adapter;
    late BehaviorSubject<PlaybackState> playbackStateSubject;
    late BehaviorSubject<MediaItem?> mediaItemSubject;

    setUp(() {
      mockHandler = MockBackgroundAudioHandler();
      playbackStateSubject = BehaviorSubject<PlaybackState>();
      mediaItemSubject = BehaviorSubject<MediaItem?>();

      when(mockHandler.playbackState).thenAnswer((_) => playbackStateSubject);
      when(mockHandler.mediaItem).thenAnswer((_) => mediaItemSubject);

      adapter = BackgroundPlayerAdapter(mockHandler);
    });

    tearDown(() {
      playbackStateSubject.close();
      mediaItemSubject.close();
      adapter.dispose();
    });

    test('Method error handling', () async {
      when(mockHandler.play()).thenThrow(Exception('Play failed'));
      expect(() => adapter.play(), throwsA(isA<PlayerAdapterException>()));

      when(mockHandler.pause()).thenThrow(Exception('Pause failed'));
      expect(() => adapter.pause(), throwsA(isA<PlayerAdapterException>()));

      when(mockHandler.stop()).thenThrow(Exception('Stop failed'));
      expect(() => adapter.stop(), throwsA(isA<PlayerAdapterException>()));

      when(mockHandler.seek(any)).thenThrow(Exception('Seek failed'));
      expect(() => adapter.seek(Duration.zero),
          throwsA(isA<PlayerAdapterException>()));

      when(mockHandler.fastForward()).thenThrow(Exception('FF failed'));
      expect(
          () => adapter.skipForward(), throwsA(isA<PlayerAdapterException>()));

      when(mockHandler.rewind()).thenThrow(Exception('RW failed'));
      expect(
          () => adapter.skipBackward(), throwsA(isA<PlayerAdapterException>()));

      when(mockHandler.customAction('setSpeed', any))
          .thenThrow(Exception('Speed failed'));
      expect(
          () => adapter.setSpeed(1.5), throwsA(isA<PlayerAdapterException>()));

      final audioFile = AudioFile(
          id: '1',
          title: 'T',
          language: 'en',
          category: 'news',
          streamingUrl: 'u',
          path: 'p',
          duration: Duration.zero,
          lastModified: DateTime.now());
      when(mockHandler.setAudioSource(any,
              title: anyNamed('title'),
              artist: anyNamed('artist'),
              audioFile: anyNamed('audioFile'),
              initialPosition: anyNamed('initialPosition')))
          .thenThrow(Exception('Source failed'));
      expect(() => adapter.setAudioSource(audioFile),
          throwsA(isA<PlayerAdapterException>()));
    });

    test('Disposed adapter ignores stream events', () async {
      await adapter.dispose();

      // Should not crash or update state
      playbackStateSubject.add(PlaybackState(playing: true));
      mediaItemSubject.add(const MediaItem(
          id: '1', title: 'T', duration: Duration(seconds: 10)));

      await Future.delayed(Duration.zero);
    });

    test('Redundant state updates are filtered', () async {
      // Set initial state
      playbackStateSubject.add(PlaybackState(
          playing: true, processingState: AudioProcessingState.ready));
      await Future.delayed(Duration.zero);

      // Listen to stream
      bool emitted = false;
      final sub = adapter.playbackStateStream.listen((_) {
        emitted = true;
      });

      // Emit SAME state
      playbackStateSubject.add(PlaybackState(
          playing: true, processingState: AudioProcessingState.ready));
      await Future.delayed(Duration.zero);

      // Stream is broadcast and we subscribed LATE?
      // Actually adapter broadcasts current state on change.
      // If we subscribe after change, we might not get it unless behavior subject logic (not used here).
      // But subsequent ADD should NOT emit if value is same.

      expect(emitted, isFalse);

      // Emit DIFFERENT state
      playbackStateSubject.add(PlaybackState(
          playing: false, processingState: AudioProcessingState.ready));
      await Future.delayed(Duration.zero);

      expect(emitted, isTrue);
      await sub.cancel();
    });
  });
}
