import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:from_fed_to_chain_app/features/audio/services/playback_navigation_service.dart';
import 'package:from_fed_to_chain_app/features/audio/services/audio_progress_tracker.dart';
import 'package:from_fed_to_chain_app/features/audio/services/player_controller.dart';
import 'package:from_fed_to_chain_app/features/content/services/content_service.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';

@GenerateMocks([ContentService, PlayerController, AudioProgressTracker])
import 'playback_navigation_service_test.mocks.dart';

void main() {
  late MockContentService mockContentService;
  late MockPlayerController mockPlayerController;
  late MockAudioProgressTracker mockProgressTracker;
  late PlaybackNavigationService service;
  late AudioFile testEpisode;
  late AudioFile nextEpisode;
  late AudioFile prevEpisode;

  setUp(() {
    mockContentService = MockContentService();
    mockPlayerController = MockPlayerController();
    mockProgressTracker = MockAudioProgressTracker();
    service = PlaybackNavigationService(
      mockContentService,
      mockPlayerController,
      mockProgressTracker,
    );

    testEpisode = AudioFile(
      id: 'test-episode',
      title: 'Test Episode',
      language: 'en-US',
      category: 'daily-news',
      streamingUrl: 'https://example.com/test.m3u8',
      path: '/test/path',
      lastModified: DateTime.now(),
      duration: const Duration(minutes: 10),
    );

    nextEpisode = AudioFile(
      id: 'next-episode',
      title: 'Next Episode',
      language: 'en-US',
      category: 'daily-news',
      streamingUrl: 'https://example.com/next.m3u8',
      path: '/next/path',
      lastModified: DateTime.now(),
      duration: const Duration(minutes: 15),
    );

    prevEpisode = AudioFile(
      id: 'prev-episode',
      title: 'Previous Episode',
      language: 'en-US',
      category: 'daily-news',
      streamingUrl: 'https://example.com/prev.m3u8',
      path: '/prev/path',
      lastModified: DateTime.now(),
      duration: const Duration(minutes: 8),
    );
  });

  group('PlaybackNavigationService', () {
    group('autoplay settings', () {
      test('should have autoplay enabled by default', () {
        expect(service.autoplayEnabled, isTrue);
      });

      test('should set autoplay enabled to false', () {
        service.setAutoplayEnabled(false);
        expect(service.autoplayEnabled, isFalse);
      });

      test('should set autoplay enabled to true', () {
        service.setAutoplayEnabled(false);
        service.setAutoplayEnabled(true);
        expect(service.autoplayEnabled, isTrue);
      });

      test('should not notify when setting same value', () {
        service.setAutoplayEnabled(true); // Already true
        expect(service.autoplayEnabled, isTrue);
      });

      test('should toggle autoplay', () {
        expect(service.autoplayEnabled, isTrue);
        service.toggleAutoplay();
        expect(service.autoplayEnabled, isFalse);
        service.toggleAutoplay();
        expect(service.autoplayEnabled, isTrue);
      });

      test('enableAutoplay should be alias for setAutoplayEnabled', () {
        service.enableAutoplay(false);
        expect(service.autoplayEnabled, isFalse);
        service.enableAutoplay(true);
        expect(service.autoplayEnabled, isTrue);
      });
    });

    group('repeat settings', () {
      test('should have repeat disabled by default', () {
        expect(service.repeatEnabled, isFalse);
      });

      test('should set repeat enabled to true', () {
        service.setRepeatEnabled(true);
        expect(service.repeatEnabled, isTrue);
      });

      test('should set repeat enabled to false', () {
        service.setRepeatEnabled(true);
        service.setRepeatEnabled(false);
        expect(service.repeatEnabled, isFalse);
      });

      test('should not notify when setting same value', () {
        service.setRepeatEnabled(false); // Already false
        expect(service.repeatEnabled, isFalse);
      });

      test('should toggle repeat', () {
        expect(service.repeatEnabled, isFalse);
        service.toggleRepeat();
        expect(service.repeatEnabled, isTrue);
        service.toggleRepeat();
        expect(service.repeatEnabled, isFalse);
      });
    });

    group('skipToNext', () {
      test('should skip to next episode when available', () async {
        when(mockContentService.getNextEpisode(testEpisode))
            .thenReturn(nextEpisode);
        when(mockProgressTracker.calculateResumePosition(any, any))
            .thenReturn(Duration.zero);
        when(mockPlayerController.play(any,
                initialPosition: anyNamed('initialPosition')))
            .thenAnswer((_) async {});

        final result = await service.skipToNext(testEpisode);

        expect(result, equals(nextEpisode));
        verify(mockPlayerController.play(nextEpisode, initialPosition: null))
            .called(1);
      });

      test('should skip to next with resume position', () async {
        when(mockContentService.getNextEpisode(testEpisode))
            .thenReturn(nextEpisode);
        when(mockProgressTracker.calculateResumePosition(any, any))
            .thenReturn(const Duration(minutes: 5));
        when(mockPlayerController.play(any,
                initialPosition: anyNamed('initialPosition')))
            .thenAnswer((_) async {});

        final result = await service.skipToNext(testEpisode);

        expect(result, equals(nextEpisode));
        verify(mockPlayerController.play(
          nextEpisode,
          initialPosition: const Duration(minutes: 5),
        )).called(1);
      });

      test('should return null when no next episode available', () async {
        when(mockContentService.getNextEpisode(testEpisode)).thenReturn(null);

        final result = await service.skipToNext(testEpisode);

        expect(result, isNull);
        verifyNever(mockPlayerController.play(any,
            initialPosition: anyNamed('initialPosition')));
      });

      test('should return null and not crash when player controller throws',
          () async {
        when(mockContentService.getNextEpisode(testEpisode))
            .thenReturn(nextEpisode);
        when(mockProgressTracker.calculateResumePosition(any, any))
            .thenReturn(Duration.zero);
        when(mockPlayerController.play(any,
                initialPosition: anyNamed('initialPosition')))
            .thenThrow(Exception('Playback failed'));

        final result = await service.skipToNext(testEpisode);

        expect(result, isNull);
      });
    });

    group('skipToPrevious', () {
      test('should skip to previous episode when available', () async {
        when(mockContentService.getPreviousEpisode(testEpisode))
            .thenReturn(prevEpisode);
        when(mockProgressTracker.calculateResumePosition(any, any))
            .thenReturn(Duration.zero);
        when(mockPlayerController.play(any,
                initialPosition: anyNamed('initialPosition')))
            .thenAnswer((_) async {});

        final result = await service.skipToPrevious(testEpisode);

        expect(result, equals(prevEpisode));
        verify(mockPlayerController.play(prevEpisode, initialPosition: null))
            .called(1);
      });

      test('should return null when no previous episode available', () async {
        when(mockContentService.getPreviousEpisode(testEpisode))
            .thenReturn(null);

        final result = await service.skipToPrevious(testEpisode);

        expect(result, isNull);
        verifyNever(mockPlayerController.play(any,
            initialPosition: anyNamed('initialPosition')));
      });

      test('should return null and not crash when player controller throws',
          () async {
        when(mockContentService.getPreviousEpisode(testEpisode))
            .thenReturn(prevEpisode);
        when(mockProgressTracker.calculateResumePosition(any, any))
            .thenReturn(Duration.zero);
        when(mockPlayerController.play(any,
                initialPosition: anyNamed('initialPosition')))
            .thenThrow(Exception('Playback failed'));

        final result = await service.skipToPrevious(testEpisode);

        expect(result, isNull);
      });
    });

    group('handleEpisodeCompletion', () {
      test('should repeat episode when repeat is enabled', () async {
        service.setRepeatEnabled(true);
        when(mockPlayerController.play(any,
                initialPosition: anyNamed('initialPosition')))
            .thenAnswer((_) async {});

        final result = await service.handleEpisodeCompletion(testEpisode);

        expect(result, equals(testEpisode));
        verify(mockPlayerController.play(testEpisode,
                initialPosition: Duration.zero))
            .called(1);
      });

      test('should not autoplay when autoplay is disabled', () async {
        service.setAutoplayEnabled(false);

        final result = await service.handleEpisodeCompletion(testEpisode);

        expect(result, isNull);
        verifyNever(mockPlayerController.play(any,
            initialPosition: anyNamed('initialPosition')));
      });

      test('should autoplay next episode when autoplay is enabled', () async {
        service.setAutoplayEnabled(true);
        when(mockContentService.getNextEpisode(testEpisode))
            .thenReturn(nextEpisode);
        when(mockProgressTracker.calculateResumePosition(any, any))
            .thenReturn(Duration.zero);
        when(mockPlayerController.play(any,
                initialPosition: anyNamed('initialPosition')))
            .thenAnswer((_) async {});

        final result = await service.handleEpisodeCompletion(testEpisode);

        expect(result, equals(nextEpisode));
        verify(mockPlayerController.play(nextEpisode, initialPosition: null))
            .called(1);
      });

      test('should return null when no next episode available for autoplay',
          () async {
        service.setAutoplayEnabled(true);
        when(mockContentService.getNextEpisode(testEpisode)).thenReturn(null);

        final result = await service.handleEpisodeCompletion(testEpisode);

        expect(result, isNull);
      });

      test('repeat should take precedence over autoplay', () async {
        service.setRepeatEnabled(true);
        service.setAutoplayEnabled(true);
        when(mockPlayerController.play(any,
                initialPosition: anyNamed('initialPosition')))
            .thenAnswer((_) async {});

        final result = await service.handleEpisodeCompletion(testEpisode);

        expect(result, equals(testEpisode));
        verify(mockPlayerController.play(testEpisode,
                initialPosition: Duration.zero))
            .called(1);
        verifyNever(mockContentService.getNextEpisode(any));
      });

      test('should return null when repeat fails', () async {
        service.setRepeatEnabled(true);
        when(mockPlayerController.play(any,
                initialPosition: anyNamed('initialPosition')))
            .thenThrow(Exception('Repeat failed'));

        final result = await service.handleEpisodeCompletion(testEpisode);

        expect(result, isNull);
      });

      test('should return null when autoplay fails', () async {
        service.setAutoplayEnabled(true);
        when(mockContentService.getNextEpisode(testEpisode))
            .thenReturn(nextEpisode);
        when(mockProgressTracker.calculateResumePosition(any, any))
            .thenReturn(Duration.zero);
        when(mockPlayerController.play(any,
                initialPosition: anyNamed('initialPosition')))
            .thenThrow(Exception('Autoplay failed'));

        final result = await service.handleEpisodeCompletion(testEpisode);

        expect(result, isNull);
      });
    });

    group('hasNextEpisode', () {
      test('should return true when next episode exists', () {
        when(mockContentService.getNextEpisode(testEpisode))
            .thenReturn(nextEpisode);

        expect(service.hasNextEpisode(testEpisode), isTrue);
      });

      test('should return false when no next episode', () {
        when(mockContentService.getNextEpisode(testEpisode)).thenReturn(null);

        expect(service.hasNextEpisode(testEpisode), isFalse);
      });
    });

    group('hasPreviousEpisode', () {
      test('should return true when previous episode exists', () {
        when(mockContentService.getPreviousEpisode(testEpisode))
            .thenReturn(prevEpisode);

        expect(service.hasPreviousEpisode(testEpisode), isTrue);
      });

      test('should return false when no previous episode', () {
        when(mockContentService.getPreviousEpisode(testEpisode))
            .thenReturn(null);

        expect(service.hasPreviousEpisode(testEpisode), isFalse);
      });
    });

    group('getNextEpisode', () {
      test('should return next episode when available', () {
        when(mockContentService.getNextEpisode(testEpisode))
            .thenReturn(nextEpisode);

        expect(service.getNextEpisode(testEpisode), equals(nextEpisode));
      });

      test('should return null when no next episode', () {
        when(mockContentService.getNextEpisode(testEpisode)).thenReturn(null);

        expect(service.getNextEpisode(testEpisode), isNull);
      });
    });

    group('getPreviousEpisode', () {
      test('should return previous episode when available', () {
        when(mockContentService.getPreviousEpisode(testEpisode))
            .thenReturn(prevEpisode);

        expect(service.getPreviousEpisode(testEpisode), equals(prevEpisode));
      });

      test('should return null when no previous episode', () {
        when(mockContentService.getPreviousEpisode(testEpisode))
            .thenReturn(null);

        expect(service.getPreviousEpisode(testEpisode), isNull);
      });
    });

    group('null content service', () {
      late PlaybackNavigationService serviceWithoutContentService;

      setUp(() {
        serviceWithoutContentService = PlaybackNavigationService(
          null,
          mockPlayerController,
          mockProgressTracker,
        );
      });

      test('skipToNext should return null when no content service', () async {
        final result =
            await serviceWithoutContentService.skipToNext(testEpisode);
        expect(result, isNull);
      });

      test('skipToPrevious should return null when no content service',
          () async {
        final result =
            await serviceWithoutContentService.skipToPrevious(testEpisode);
        expect(result, isNull);
      });

      test(
          'handleEpisodeCompletion should return null when no content service and autoplay enabled',
          () async {
        serviceWithoutContentService.setAutoplayEnabled(true);
        final result = await serviceWithoutContentService
            .handleEpisodeCompletion(testEpisode);
        expect(result, isNull);
      });

      test('hasNextEpisode should return false when no content service', () {
        expect(
            serviceWithoutContentService.hasNextEpisode(testEpisode), isFalse);
      });

      test('hasPreviousEpisode should return false when no content service',
          () {
        expect(serviceWithoutContentService.hasPreviousEpisode(testEpisode),
            isFalse);
      });

      test('getNextEpisode should return null when no content service', () {
        expect(
            serviceWithoutContentService.getNextEpisode(testEpisode), isNull);
      });

      test('getPreviousEpisode should return null when no content service', () {
        expect(serviceWithoutContentService.getPreviousEpisode(testEpisode),
            isNull);
      });
    });
  });
}
