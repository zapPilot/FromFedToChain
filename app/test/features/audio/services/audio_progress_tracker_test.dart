import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:from_fed_to_chain_app/features/audio/services/audio_progress_tracker.dart';
import 'package:from_fed_to_chain_app/features/content/services/content_service.dart';

@GenerateMocks([ContentService])
import 'audio_progress_tracker_test.mocks.dart';

void main() {
  group('AudioProgressTracker Tests', () {
    late AudioProgressTracker tracker;
    late MockContentService mockContentService;

    setUp(() {
      mockContentService = MockContentService();
      tracker = AudioProgressTracker(mockContentService);
    });

    test('updates progress when conditions met', () {
      tracker.resetThrottling();

      tracker.updateProgress(
        'episode-1',
        const Duration(minutes: 5), // 50%
        const Duration(minutes: 10),
      );

      verify(mockContentService.updateEpisodeCompletion('episode-1', 0.5))
          .called(1);
    });

    test('does not update when throttled', () {
      tracker.resetThrottling();

      // First update (works)
      tracker.updateProgress(
        'episode-1',
        const Duration(minutes: 5),
        const Duration(minutes: 10),
      );
      verify(mockContentService.updateEpisodeCompletion(any, any)).called(1);

      // Immediate second update (should be throttled)
      tracker.updateProgress(
        'episode-1',
        const Duration(minutes: 6),
        const Duration(minutes: 10),
      );

      verifyNever(mockContentService.updateEpisodeCompletion(any, any));
    });

    test('does not update for small progress changes', () {
      tracker.resetThrottling();

      // 0.5% progress
      tracker.updateProgress(
        'episode-1',
        const Duration(seconds: 5),
        const Duration(minutes: 1000), // 60000 sec. 5/60000 is tiny.
      );

      verifyNever(mockContentService.updateEpisodeCompletion(any, any));
    });

    test('handles zero total duration', () {
      tracker.resetThrottling();

      tracker.updateProgress(
        'episode-1',
        const Duration(minutes: 1),
        Duration.zero,
      );

      verifyNever(mockContentService.updateEpisodeCompletion(any, any));
    });

    test('handles null content service safely', () {
      final nullTracker = AudioProgressTracker(null);
      nullTracker.updateProgress(
          'id', const Duration(minutes: 1), const Duration(minutes: 2));
      // Should not throw
    });

    test('markEpisodeCompleted handles null service', () async {
      final nullTracker = AudioProgressTracker(null);
      await nullTracker.markEpisodeCompleted('id');
      // Should not throw
    });

    test('markEpisodeCompleted handles exceptions', () async {
      when(mockContentService.markEpisodeAsFinished(any))
          .thenThrow(Exception('Error'));

      await tracker.markEpisodeCompleted('id');
      // Should not throw
      verify(mockContentService.markEpisodeAsFinished('id')).called(1);
    });

    test('markEpisodeCompleted delegates successfully', () async {
      await tracker.markEpisodeCompleted('id');
      verify(mockContentService.markEpisodeAsFinished('id')).called(1);
    });

    test('saveProgress handles null service', () {
      final nullTracker = AudioProgressTracker(null);
      nullTracker.saveProgress(
          'id', const Duration(minutes: 1), const Duration(minutes: 2));
      // No crash
    });

    test('saveProgress ignores zero duration', () {
      tracker.saveProgress('id', Duration.zero, Duration.zero);
      verifyNever(mockContentService.updateEpisodeCompletion(any, any));
    });

    test('saveProgress updates service', () {
      tracker.saveProgress(
          'id', const Duration(minutes: 1), const Duration(minutes: 2));
      verify(mockContentService.updateEpisodeCompletion('id', 0.5)).called(1);
    });

    test('getEpisodeProgress handles null service', () {
      final nullTracker = AudioProgressTracker(null);
      expect(nullTracker.getEpisodeProgress('id'), 0.0);
    });

    test('getEpisodeProgress delegates', () {
      when(mockContentService.getEpisodeCompletion('id')).thenReturn(0.7);
      expect(tracker.getEpisodeProgress('id'), 0.7);
    });

    test('calculateResumePosition handles null/zero', () {
      final nullTracker = AudioProgressTracker(null);
      expect(
          nullTracker.calculateResumePosition(
              'id', const Duration(minutes: 10)),
          Duration.zero);

      expect(
          tracker.calculateResumePosition('id', Duration.zero), Duration.zero);
    });

    test('calculateResumePosition returns zero for >95% completed', () {
      when(mockContentService.getEpisodeCompletion('id')).thenReturn(0.96);
      expect(
          tracker.calculateResumePosition('id', const Duration(minutes: 100)),
          Duration.zero);
    });

    test('calculateResumePosition returns zero for <5% completed', () {
      when(mockContentService.getEpisodeCompletion('id')).thenReturn(0.04);
      expect(
          tracker.calculateResumePosition('id', const Duration(minutes: 100)),
          Duration.zero);
    });

    test('calculateResumePosition returns correct position', () {
      when(mockContentService.getEpisodeCompletion('id')).thenReturn(0.5);
      final position = tracker.calculateResumePosition(
          'id', const Duration(seconds: 100)); // 50s

      expect(position.inSeconds, 50);
    });

    test('verify helper methods', () {
      tracker.resetThrottling();
      expect(tracker.lastUpdateTime, DateTime(0));
    });
  });
}
