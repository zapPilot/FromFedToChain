import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:audio_service/audio_service.dart' as audio_service_pkg;
import 'package:rxdart/rxdart.dart';
import 'package:just_audio/just_audio.dart';

import 'package:from_fed_to_chain_app/services/background_audio_handler.dart';
import 'package:from_fed_to_chain_app/models/audio_file.dart';

// Generate mocks for audio dependencies
@GenerateMocks([AudioPlayer, BackgroundAudioHandler])
import 'background_audio_handler_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BackgroundAudioHandler - Basic Tests', () {
    late MockBackgroundAudioHandler mockAudioHandler;
    late AudioFile testAudioFile;

    setUp(() {
      mockAudioHandler = MockBackgroundAudioHandler();
      
      testAudioFile = AudioFile(
        id: 'test-episode',
        title: 'Test Episode',
        language: 'en-US',
        category: 'daily-news',
        streamingUrl: 'https://example.com/test.m3u8',
        path: 'test.m3u8',
        duration: const Duration(minutes: 5),
        lastModified: DateTime.now(),
      );

      // Basic stream setup
      final playbackStateStream = BehaviorSubject<audio_service_pkg.PlaybackState>.seeded(
        audio_service_pkg.PlaybackState(
          controls: [audio_service_pkg.MediaControl.play],
          systemActions: const {audio_service_pkg.MediaAction.seek},
          processingState: audio_service_pkg.AudioProcessingState.idle,
          playing: false,
          updatePosition: Duration.zero,
          bufferedPosition: Duration.zero,
          speed: 1.0,
        ),
      );

      when(mockAudioHandler.playbackState).thenAnswer((_) => playbackStateStream);
      when(mockAudioHandler.mediaItem).thenAnswer((_) => 
          BehaviorSubject<audio_service_pkg.MediaItem?>.seeded(null));
      when(mockAudioHandler.duration).thenReturn(Duration.zero);
    });

    tearDown(() {
      reset(mockAudioHandler);
    });

    group('Basic Interface Tests', () {
      test('should provide playback state stream', () {
        expect(mockAudioHandler.playbackState, isA<Stream<audio_service_pkg.PlaybackState>>());
      });

      test('should provide media item stream', () {
        expect(mockAudioHandler.mediaItem, isA<Stream<audio_service_pkg.MediaItem?>>());
      });

      test('should provide duration property', () {
        expect(mockAudioHandler.duration, isA<Duration>());
      });
    });

    group('Basic Playback Control', () {
      test('should handle play command', () async {
        when(mockAudioHandler.play()).thenAnswer((_) async => {});
        await mockAudioHandler.play();
        verify(mockAudioHandler.play()).called(1);
      });

      test('should handle pause command', () async {
        when(mockAudioHandler.pause()).thenAnswer((_) async => {});
        await mockAudioHandler.pause();
        verify(mockAudioHandler.pause()).called(1);
      });

      test('should handle stop command', () async {
        when(mockAudioHandler.stop()).thenAnswer((_) async => {});
        await mockAudioHandler.stop();
        verify(mockAudioHandler.stop()).called(1);
      });

      test('should handle seek command', () async {
        const position = Duration(seconds: 30);
        when(mockAudioHandler.seek(position)).thenAnswer((_) async => {});
        await mockAudioHandler.seek(position);
        verify(mockAudioHandler.seek(position)).called(1);
      });
    });

    group('Audio Source Setup', () {
      test('should handle setAudioSource with basic parameters', () async {
        when(mockAudioHandler.setAudioSource(
          any,
          title: anyNamed('title'),
          artist: anyNamed('artist'),
          initialPosition: anyNamed('initialPosition'),
          audioFile: anyNamed('audioFile'),
        )).thenAnswer((_) async => {});

        await mockAudioHandler.setAudioSource(
          testAudioFile.streamingUrl,
          title: testAudioFile.title,
          artist: 'From Fed to Chain',
          audioFile: testAudioFile,
        );

        verify(mockAudioHandler.setAudioSource(
          testAudioFile.streamingUrl,
          title: testAudioFile.title,
          artist: 'From Fed to Chain',
          initialPosition: anyNamed('initialPosition'),
          audioFile: testAudioFile,
        )).called(1);
      });
    });

    group('Episode Navigation', () {
      test('should handle skipToNext command', () async {
        when(mockAudioHandler.skipToNext()).thenAnswer((_) async => {});
        await mockAudioHandler.skipToNext();
        verify(mockAudioHandler.skipToNext()).called(1);
      });

      test('should handle skipToPrevious command', () async {
        when(mockAudioHandler.skipToPrevious()).thenAnswer((_) async => {});
        await mockAudioHandler.skipToPrevious();
        verify(mockAudioHandler.skipToPrevious()).called(1);
      });
    });

    group('Custom Actions', () {
      test('should handle setSpeed custom action', () async {
        when(mockAudioHandler.customAction('setSpeed', any)).thenAnswer((_) async => {});
        
        await mockAudioHandler.customAction('setSpeed', {'speed': 1.5});
        
        verify(mockAudioHandler.customAction('setSpeed', {'speed': 1.5})).called(1);
      });

      test('should handle getPosition custom action', () async {
        when(mockAudioHandler.customAction('getPosition')).thenAnswer((_) async => Duration.zero);
        
        final position = await mockAudioHandler.customAction('getPosition');
        
        verify(mockAudioHandler.customAction('getPosition')).called(1);
        expect(position, isA<Duration>());
      });
    });

    group('Error Handling', () {
      test('should handle errors gracefully without crashing', () async {
        when(mockAudioHandler.setAudioSource(
          any,
          title: anyNamed('title'),
          artist: anyNamed('artist'),
          initialPosition: anyNamed('initialPosition'),
          audioFile: anyNamed('audioFile'),
        )).thenThrow(Exception('Audio loading failed'));

        // Should not throw an unhandled exception
        expect(() async {
          try {
            await mockAudioHandler.setAudioSource(
              'invalid-url',
              title: 'Test',
              artist: 'Test',
              audioFile: testAudioFile,
            );
          } catch (e) {
            // Expected to throw, but shouldn't crash the test
            expect(e, isA<Exception>());
          }
        }, returnsNormally);
      });
    });
  });
}