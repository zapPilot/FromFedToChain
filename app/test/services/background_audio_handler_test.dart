import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'package:from_fed_to_chain_app/features/audio/services/background_audio_handler.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';
import '../test_utils.dart';

// Generate mocks
@GenerateMocks([AudioPlayer, AudioSession])
import 'background_audio_handler_test.mocks.dart';

void main() {
  group('BackgroundAudioHandler Tests', () {
    late BackgroundAudioHandler handler;
    late MockAudioPlayer mockAudioPlayer;
    late MockAudioSession mockAudioSession;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();

      // Mock platform channels for just_audio and audio_session
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.ryanheise.just_audio.methods'),
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'init':
              return null;
            case 'dispose':
              return null;
            case 'load':
              return {'duration': 300000}; // 5 minutes in milliseconds
            case 'play':
              return null;
            case 'pause':
              return null;
            case 'stop':
              return null;
            case 'seek':
              return null;
            case 'setSpeed':
              return null;
            default:
              return null;
          }
        },
      );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.ryanheise.audio_session'),
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'configure':
              return true;
            case 'setActive':
              return true;
            default:
              return null;
          }
        },
      );

      mockAudioPlayer = MockAudioPlayer();
      mockAudioSession = MockAudioSession();

      // Setup default mock responses
      when(mockAudioPlayer.playbackEventStream)
          .thenAnswer((_) => Stream<PlaybackEvent>.empty());
      when(mockAudioPlayer.playerStateStream)
          .thenAnswer((_) => Stream<PlayerState>.empty());
      when(mockAudioPlayer.durationStream)
          .thenAnswer((_) => Stream<Duration?>.empty());
      when(mockAudioPlayer.position).thenReturn(Duration.zero);
      when(mockAudioPlayer.duration).thenReturn(const Duration(minutes: 5));
      when(mockAudioPlayer.bufferedPosition).thenReturn(Duration.zero);
      when(mockAudioPlayer.speed).thenReturn(1.0);
      when(mockAudioPlayer.playing).thenReturn(false);
      when(mockAudioPlayer.processingState).thenReturn(ProcessingState.idle);
      when(mockAudioPlayer.dispose()).thenAnswer((_) async {});
      when(mockAudioPlayer.setAudioSource(
        any,
        initialPosition: anyNamed('initialPosition'),
      )).thenAnswer((_) async => const Duration(minutes: 5));

      // Mock audio session
      when(mockAudioSession.configure(any)).thenAnswer((_) async => true);
      when(mockAudioSession.setActive(any)).thenAnswer((_) async => true);
      when(mockAudioSession.interruptionEventStream)
          .thenAnswer((_) => Stream<AudioInterruptionEvent>.empty());

      handler = BackgroundAudioHandler(
        audioPlayer: mockAudioPlayer,
        audioSession: mockAudioSession,
      );
    });

    tearDown(() {
      handler.dispose();

      // Clean up platform channel mocks
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.ryanheise.just_audio.methods'),
        null,
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.ryanheise.audio_session'),
        null,
      );
    });

    group('Initialization', () {
      test('should initialize with correct initial states', () async {
        // Allow some time for initialization
        await Future.delayed(const Duration(milliseconds: 100));

        // Verify initial MediaItem is set
        expect(handler.mediaItem.value, isNotNull);
        expect(handler.mediaItem.value!.id, equals('initial'));
        expect(handler.mediaItem.value!.title, equals('From Fed to Chain'));

        // Verify initial PlaybackState is set
        expect(handler.playbackState.value, isNotNull);
        expect(handler.playbackState.value.playing, isFalse);
        expect(handler.playbackState.value.processingState,
            equals(AudioProcessingState.idle));
        expect(
            handler.playbackState.value.controls, contains(MediaControl.play));
      });

      test('should handle audio session configuration errors gracefully',
          () async {
        when(mockAudioSession.configure(any))
            .thenThrow(Exception('Audio session error'));

        // Should not throw, just log error
        expect(
            () => BackgroundAudioHandler(
                  audioPlayer: mockAudioPlayer,
                  audioSession: mockAudioSession,
                ),
            returnsNormally);
      });
    });

    group('Episode Navigation Callbacks', () {
      test('should set episode navigation callbacks correctly', () {
        handler.setEpisodeNavigationCallbacks(
          onNext: (episode) {
            // Callback set for next episode
          },
          onPrevious: (episode) {
            // Callback set for previous episode
          },
        );

        expect(handler.onSkipToNextEpisode, isNotNull);
        expect(handler.onSkipToPreviousEpisode, isNotNull);
      });
    });

    group('Audio Source Management', () {
      test('should set audio source and MediaItem correctly', () async {
        const url = 'https://example.com/test.m3u8';
        const title = 'Test Episode';
        const artist = 'Test Artist';
        final audioFile = TestDataFactory.createMockAudioFile(
          id: 'test-episode',
          title: title,
          category: 'daily-news',
          language: 'zh-TW',
        );

        when(mockAudioPlayer.setAudioSource(any,
                initialPosition: anyNamed('initialPosition')))
            .thenAnswer((_) async => const Duration(minutes: 5));

        await handler.setAudioSource(
          url,
          title: title,
          artist: artist,
          audioFile: audioFile,
        );

        verify(mockAudioPlayer.setAudioSource(
          any,
          initialPosition: Duration.zero,
        )).called(1);

        // Check if MediaItem was updated (we can't directly test due to stream nature)
        expect(handler.mediaItem, isNotNull);
      });

      test('should handle initial position correctly', () async {
        const url = 'https://example.com/test.m3u8';
        const title = 'Test Episode';
        const initialPosition = Duration(seconds: 30);

        when(mockAudioPlayer.setAudioSource(any,
                initialPosition: anyNamed('initialPosition')))
            .thenAnswer((_) async => const Duration(minutes: 5));

        await handler.setAudioSource(
          url,
          title: title,
          initialPosition: initialPosition,
        );

        verify(mockAudioPlayer.setAudioSource(
          any,
          initialPosition: initialPosition,
        )).called(1);
      });

      test('should handle setAudioSource errors gracefully', () async {
        const url = 'https://invalid-url.com/test.m3u8';
        const title = 'Test Episode';

        when(mockAudioPlayer.setAudioSource(any,
                initialPosition: anyNamed('initialPosition')))
            .thenThrow(Exception('Failed to load audio'));

        expect(
          () => handler.setAudioSource(url, title: title),
          throwsException,
        );
      });

      test('should get duration correctly', () {
        when(mockAudioPlayer.duration).thenReturn(const Duration(minutes: 10));

        expect(handler.duration, equals(const Duration(minutes: 10)));
      });

      test('should return zero duration when player duration is null', () {
        when(mockAudioPlayer.duration).thenReturn(null);

        expect(handler.duration, equals(Duration.zero));
      });
    });

    group('Playback Controls', () {
      test('should handle play command correctly', () async {
        when(mockAudioPlayer.play()).thenAnswer((_) async {});

        await handler.play();

        verify(mockAudioPlayer.play()).called(1);
      });

      test('should handle play errors gracefully', () async {
        when(mockAudioPlayer.play()).thenThrow(Exception('Play failed'));

        await handler.play();

        verify(mockAudioPlayer.play()).called(1);
        // Should not throw, just update playback state
      });

      test('should handle pause command correctly', () async {
        when(mockAudioPlayer.pause()).thenAnswer((_) async {});

        await handler.pause();

        verify(mockAudioPlayer.pause()).called(1);
      });

      test('should handle stop command correctly', () async {
        when(mockAudioPlayer.stop()).thenAnswer((_) async {});
        when(mockAudioPlayer.seek(any)).thenAnswer((_) async {});

        await handler.stop();

        verify(mockAudioPlayer.stop()).called(1);
        verify(mockAudioPlayer.seek(Duration.zero)).called(1);
      });

      test('should handle seek command correctly', () async {
        const seekPosition = Duration(seconds: 30);
        when(mockAudioPlayer.seek(any)).thenAnswer((_) async {});

        await handler.seek(seekPosition);

        verify(mockAudioPlayer.seek(seekPosition)).called(1);
      });
    });

    group('Skip Controls', () {
      test('should skip to next episode using callback when available',
          () async {
        bool callbackCalled = false;
        AudioFile? passedEpisode;
        final testAudioFile = TestDataFactory.createMockAudioFile();

        handler.setEpisodeNavigationCallbacks(
          onNext: (episode) {
            callbackCalled = true;
            passedEpisode = episode;
          },
          onPrevious: (_) {},
        );

        // Set current audio file
        await handler.setAudioSource(
          'https://test.com/test.m3u8',
          title: 'Test',
          audioFile: testAudioFile,
        );

        await handler.skipToNext();

        expect(callbackCalled, isTrue);
        expect(passedEpisode, equals(testAudioFile));
      });

      test('should skip 30 seconds forward when no callback available',
          () async {
        when(mockAudioPlayer.position).thenReturn(const Duration(seconds: 30));
        when(mockAudioPlayer.duration).thenReturn(const Duration(minutes: 5));
        when(mockAudioPlayer.seek(any)).thenAnswer((_) async {});

        await handler.skipToNext();

        verify(mockAudioPlayer.seek(const Duration(seconds: 60))).called(1);
      });

      test('should seek to end when skipping beyond duration', () async {
        when(mockAudioPlayer.position)
            .thenReturn(const Duration(minutes: 4, seconds: 50));
        when(mockAudioPlayer.duration).thenReturn(const Duration(minutes: 5));
        when(mockAudioPlayer.seek(any)).thenAnswer((_) async {});

        await handler.skipToNext();

        verify(mockAudioPlayer.seek(const Duration(minutes: 5))).called(1);
      });

      test('should skip to previous episode using callback when available',
          () async {
        bool callbackCalled = false;
        AudioFile? passedEpisode;
        final testAudioFile = TestDataFactory.createMockAudioFile();

        handler.setEpisodeNavigationCallbacks(
          onNext: (_) {},
          onPrevious: (episode) {
            callbackCalled = true;
            passedEpisode = episode;
          },
        );

        // Set current audio file
        await handler.setAudioSource(
          'https://test.com/test.m3u8',
          title: 'Test',
          audioFile: testAudioFile,
        );

        await handler.skipToPrevious();

        expect(callbackCalled, isTrue);
        expect(passedEpisode, equals(testAudioFile));
      });

      test('should skip 10 seconds backward when no callback available',
          () async {
        when(mockAudioPlayer.position).thenReturn(const Duration(seconds: 30));
        when(mockAudioPlayer.seek(any)).thenAnswer((_) async {});

        await handler.skipToPrevious();

        verify(mockAudioPlayer.seek(const Duration(seconds: 20))).called(1);
      });

      test('should seek to start when skipping before beginning', () async {
        when(mockAudioPlayer.position).thenReturn(const Duration(seconds: 5));
        when(mockAudioPlayer.seek(any)).thenAnswer((_) async {});

        await handler.skipToPrevious();

        verify(mockAudioPlayer.seek(Duration.zero)).called(1);
      });
    });

    group('Fast Forward and Rewind', () {
      test('should fast forward 30 seconds', () async {
        when(mockAudioPlayer.position).thenReturn(const Duration(seconds: 30));
        when(mockAudioPlayer.duration).thenReturn(const Duration(minutes: 5));
        when(mockAudioPlayer.seek(any)).thenAnswer((_) async {});

        await handler.fastForward();

        verify(mockAudioPlayer.seek(const Duration(seconds: 60))).called(1);
      });

      test('should fast forward to end when exceeding duration', () async {
        when(mockAudioPlayer.position)
            .thenReturn(const Duration(minutes: 4, seconds: 50));
        when(mockAudioPlayer.duration).thenReturn(const Duration(minutes: 5));
        when(mockAudioPlayer.seek(any)).thenAnswer((_) async {});

        await handler.fastForward();

        verify(mockAudioPlayer.seek(const Duration(minutes: 5))).called(1);
      });

      test('should rewind 10 seconds', () async {
        when(mockAudioPlayer.position).thenReturn(const Duration(seconds: 30));
        when(mockAudioPlayer.seek(any)).thenAnswer((_) async {});

        await handler.rewind();

        verify(mockAudioPlayer.seek(const Duration(seconds: 20))).called(1);
      });

      test('should rewind to start when going before beginning', () async {
        when(mockAudioPlayer.position).thenReturn(const Duration(seconds: 5));
        when(mockAudioPlayer.seek(any)).thenAnswer((_) async {});

        await handler.rewind();

        verify(mockAudioPlayer.seek(Duration.zero)).called(1);
      });
    });

    group('Custom Actions', () {
      test('should handle setSpeed custom action', () async {
        const speed = 1.5;
        when(mockAudioPlayer.setSpeed(any)).thenAnswer((_) async {});

        await handler.customAction('setSpeed', {'speed': speed});

        verify(mockAudioPlayer.setSpeed(speed)).called(1);
      });

      test('should handle setSpeed with default speed when not provided',
          () async {
        when(mockAudioPlayer.setSpeed(any)).thenAnswer((_) async {});

        await handler.customAction('setSpeed');

        verify(mockAudioPlayer.setSpeed(1.0)).called(1);
      });

      test('should handle getPosition custom action', () async {
        when(mockAudioPlayer.position).thenReturn(const Duration(seconds: 45));

        final result = await handler.customAction('getPosition');

        expect(result, equals(const Duration(seconds: 45)));
      });

      test('should handle getDuration custom action', () async {
        when(mockAudioPlayer.duration).thenReturn(const Duration(minutes: 3));

        final result = await handler.customAction('getDuration');

        expect(result, equals(const Duration(minutes: 3)));
      });

      test('should handle unknown custom action', () async {
        final result = await handler.customAction('unknownAction');

        expect(result, isNull);
      });
    });

    group('Media Session Testing', () {
      test('should test media session correctly', () async {
        await handler.testMediaSession();

        // Verify MediaItem was updated (check via stream would require more complex setup)
        expect(handler.mediaItem, isNotNull);
        expect(handler.playbackState, isNotNull);
      });
    });

    group('Task Management', () {
      test('should handle onTaskRemoved correctly', () async {
        when(mockAudioPlayer.stop()).thenAnswer((_) async {});
        when(mockAudioPlayer.seek(any)).thenAnswer((_) async {});

        await handler.onTaskRemoved();

        verify(mockAudioPlayer.stop()).called(1);
        verify(mockAudioPlayer.seek(Duration.zero)).called(1);
      });
    });

    group('State Broadcasting', () {
      test('should handle playback event stream updates', () async {
        // Create a stream controller to emit test events
        final streamController = StreamController<PlaybackEvent>();

        when(mockAudioPlayer.playbackEventStream)
            .thenAnswer((_) => streamController.stream);
        when(mockAudioPlayer.playing).thenReturn(true);
        when(mockAudioPlayer.position).thenReturn(const Duration(seconds: 30));
        when(mockAudioPlayer.bufferedPosition)
            .thenReturn(const Duration(seconds: 45));
        when(mockAudioPlayer.speed).thenReturn(1.0);
        when(mockAudioPlayer.processingState).thenReturn(ProcessingState.ready);

        // Create new handler to test stream subscription
        final testMockPlayer = MockAudioPlayer();
        when(testMockPlayer.playbackEventStream)
            .thenAnswer((_) => streamController.stream);
        when(testMockPlayer.playerStateStream)
            .thenAnswer((_) => Stream<PlayerState>.empty());
        when(testMockPlayer.durationStream)
            .thenAnswer((_) => Stream<Duration?>.empty());
        when(testMockPlayer.playing).thenReturn(true);
        when(testMockPlayer.position).thenReturn(const Duration(seconds: 30));
        when(testMockPlayer.bufferedPosition)
            .thenReturn(const Duration(seconds: 45));
        when(testMockPlayer.speed).thenReturn(1.0);
        when(testMockPlayer.processingState).thenReturn(ProcessingState.ready);
        when(testMockPlayer.dispose()).thenAnswer((_) async {});

        final testHandler = BackgroundAudioHandler(
          audioPlayer: testMockPlayer,
          audioSession: mockAudioSession,
        );

        // Emit a test event
        streamController.add(PlaybackEvent(
          currentIndex: 0,
          updateTime: DateTime.now(),
          updatePosition: const Duration(seconds: 30),
          bufferedPosition: const Duration(seconds: 45),
          duration: const Duration(minutes: 5),
          icyMetadata: null,
          processingState: ProcessingState.ready,
        ));

        // Allow time for stream processing
        await Future.delayed(const Duration(milliseconds: 10));

        // Verify playback state is updated
        expect(testHandler.playbackState.value.playing, isTrue);
        expect(testHandler.playbackState.value.updatePosition,
            equals(const Duration(seconds: 30)));

        await streamController.close();
        testHandler.dispose();
      });

      test('should handle player state stream updates', () async {
        final streamController = StreamController<PlayerState>();

        final testMockPlayer2 = MockAudioPlayer();
        when(testMockPlayer2.playerStateStream)
            .thenAnswer((_) => streamController.stream);
        when(testMockPlayer2.playbackEventStream)
            .thenAnswer((_) => Stream<PlaybackEvent>.empty());
        when(testMockPlayer2.durationStream)
            .thenAnswer((_) => Stream<Duration?>.empty());
        when(testMockPlayer2.dispose()).thenAnswer((_) async {});

        final testHandler = BackgroundAudioHandler(
          audioPlayer: testMockPlayer2,
          audioSession: mockAudioSession,
        );

        // Emit test player state
        streamController.add(PlayerState(
          false, // not playing
          ProcessingState.ready,
        ));

        // Allow time for stream processing
        await Future.delayed(const Duration(milliseconds: 10));

        await streamController.close();
        testHandler.dispose();
      });

      test('should handle duration stream updates', () async {
        final streamController = StreamController<Duration?>();
        final mediaItemController = StreamController<MediaItem?>.broadcast();

        final testMockPlayer3 = MockAudioPlayer();
        when(testMockPlayer3.durationStream)
            .thenAnswer((_) => streamController.stream);
        when(testMockPlayer3.playbackEventStream)
            .thenAnswer((_) => Stream<PlaybackEvent>.empty());
        when(testMockPlayer3.playerStateStream)
            .thenAnswer((_) => Stream<PlayerState>.empty());
        when(testMockPlayer3.dispose()).thenAnswer((_) async {});

        final testHandler = BackgroundAudioHandler(
          audioPlayer: testMockPlayer3,
          audioSession: mockAudioSession,
        );

        // Emit duration update
        streamController.add(const Duration(minutes: 5));

        // Allow time for stream processing
        await Future.delayed(const Duration(milliseconds: 10));

        await streamController.close();
        await mediaItemController.close();
        testHandler.dispose();
      });
    });

    group('Error Handling', () {
      test('should handle audio interruption begin event', () async {
        final streamController = StreamController<AudioInterruptionEvent>();

        final testMockPlayer4 = MockAudioPlayer();
        when(testMockPlayer4.playbackEventStream)
            .thenAnswer((_) => Stream<PlaybackEvent>.empty());
        when(testMockPlayer4.playerStateStream)
            .thenAnswer((_) => Stream<PlayerState>.empty());
        when(testMockPlayer4.durationStream)
            .thenAnswer((_) => Stream<Duration?>.empty());
        when(testMockPlayer4.dispose()).thenAnswer((_) async {});

        final testMockAudioSession = MockAudioSession();
        when(testMockAudioSession.configure(any)).thenAnswer((_) async => true);
        when(testMockAudioSession.setActive(any)).thenAnswer((_) async => true);
        when(testMockAudioSession.interruptionEventStream)
            .thenAnswer((_) => streamController.stream);

        final testHandler = BackgroundAudioHandler(
          audioPlayer: testMockPlayer4,
          audioSession: testMockAudioSession,
        );

        // Create interruption begin event
        final interruptionEvent = AudioInterruptionEvent(
          true, // begin
          AudioInterruptionType.unknown,
        );

        streamController.add(interruptionEvent);

        // Allow time for event processing
        await Future.delayed(const Duration(milliseconds: 10));

        await streamController.close();
        testHandler.dispose();
      });

      test('should handle audio interruption end event with pause type',
          () async {
        final streamController = StreamController<AudioInterruptionEvent>();

        final testMockPlayer5 = MockAudioPlayer();
        when(testMockPlayer5.playbackEventStream)
            .thenAnswer((_) => Stream<PlaybackEvent>.empty());
        when(testMockPlayer5.playerStateStream)
            .thenAnswer((_) => Stream<PlayerState>.empty());
        when(testMockPlayer5.durationStream)
            .thenAnswer((_) => Stream<Duration?>.empty());
        when(testMockPlayer5.dispose()).thenAnswer((_) async {});

        final testMockAudioSession2 = MockAudioSession();
        when(testMockAudioSession2.configure(any))
            .thenAnswer((_) async => true);
        when(testMockAudioSession2.setActive(any))
            .thenAnswer((_) async => true);
        when(testMockAudioSession2.interruptionEventStream)
            .thenAnswer((_) => streamController.stream);

        final testHandler = BackgroundAudioHandler(
          audioPlayer: testMockPlayer5,
          audioSession: testMockAudioSession2,
        );

        // Create interruption end event
        final interruptionEvent = AudioInterruptionEvent(
          false, // end
          AudioInterruptionType.pause,
        );

        streamController.add(interruptionEvent);

        // Allow time for event processing
        await Future.delayed(const Duration(milliseconds: 10));

        await streamController.close();
        testHandler.dispose();
      });
    });

    group('Resource Management', () {
      test('should dispose audio player correctly', () {
        handler.dispose();

        verify(mockAudioPlayer.dispose()).called(1);
      });
    });
  });
}
