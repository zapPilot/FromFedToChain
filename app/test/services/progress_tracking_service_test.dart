import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:from_fed_to_chain_app/features/content/data/progress_tracking_service.dart';
import '../test_utils.dart';

void main() {
  late ProgressTrackingService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    service = ProgressTrackingService();
  });

  tearDown(() {
    service.dispose();
  });

  group('ProgressTrackingService - Initial State', () {
    test('should have empty completion map initially', () {
      expect(service.episodeCompletion, isEmpty);
    });

    test('should have empty listen history initially', () {
      expect(service.listenHistory, isEmpty);
    });

    test('should have no current session initially', () {
      expect(service.currentEpisodeId, isNull);
      expect(service.sessionStartTime, isNull);
      expect(service.sessionDuration, Duration.zero);
    });
  });

  group('ProgressTrackingService - Episode Completion', () {
    test('getEpisodeCompletion should return 0 for unknown episode', () {
      expect(service.getEpisodeCompletion('unknown-ep'), 0.0);
    });

    test('updateEpisodeCompletion should update completion', () async {
      await service.updateEpisodeCompletion('test-ep', 0.5);
      expect(service.getEpisodeCompletion('test-ep'), 0.5);
    });

    test('updateEpisodeCompletion should clamp to 0-1 range', () async {
      await service.updateEpisodeCompletion('test-ep', 1.5);
      expect(service.getEpisodeCompletion('test-ep'), 1.0);

      await service.updateEpisodeCompletion('test-ep2', -0.5);
      expect(service.getEpisodeCompletion('test-ep2'), 0.0);
    });

    test('isEpisodeFinished should return true for >= 90%', () async {
      await service.updateEpisodeCompletion('finished-ep', 0.95);
      expect(service.isEpisodeFinished('finished-ep'), isTrue);

      await service.updateEpisodeCompletion('unfinished-ep', 0.85);
      expect(service.isEpisodeFinished('unfinished-ep'), isFalse);
    });

    test('isEpisodeUnfinished should return true for started but not complete',
        () async {
      await service.updateEpisodeCompletion('started-ep', 0.3);
      expect(service.isEpisodeUnfinished('started-ep'), isTrue);

      await service.updateEpisodeCompletion('complete-ep', 0.95);
      expect(service.isEpisodeUnfinished('complete-ep'), isFalse);

      expect(service.isEpisodeUnfinished('never-started'), isFalse);
    });

    test('markEpisodeAsFinished should set completion to 1.0', () async {
      await service.markEpisodeAsFinished('test-ep');
      expect(service.getEpisodeCompletion('test-ep'), 1.0);
      expect(service.isEpisodeFinished('test-ep'), isTrue);
    });

    test('resetEpisodeProgress should remove completion', () async {
      await service.updateEpisodeCompletion('test-ep', 0.5);
      expect(service.getEpisodeCompletion('test-ep'), 0.5);

      await service.resetEpisodeProgress('test-ep');
      expect(service.getEpisodeCompletion('test-ep'), 0.0);
    });
  });

  group('ProgressTrackingService - Testing Methods', () {
    test('setCompletionForTesting should set completion', () {
      service.setCompletionForTesting('test-ep', 0.7);
      expect(service.getEpisodeCompletion('test-ep'), 0.7);
    });

    test('setHistoryForTesting should set history entry', () {
      final timestamp = DateTime(2025, 1, 15);
      service.setHistoryForTesting('test-ep', timestamp);
      expect(service.listenHistory['test-ep'], timestamp);
    });

    test('clearDataForTesting should clear all data', () {
      service.setCompletionForTesting('ep1', 0.5);
      service.setHistoryForTesting('ep1', DateTime.now());

      service.clearDataForTesting();

      expect(service.episodeCompletion, isEmpty);
      expect(service.listenHistory, isEmpty);
    });
  });

  group('ProgressTrackingService - Listen History', () {
    test('addToListenHistory should add episode to history', () async {
      final episode = TestUtils.createSampleAudioFile(id: 'test-ep');
      await service.addToListenHistory(episode);

      expect(service.listenHistory.containsKey('test-ep'), isTrue);
    });

    test('addToListenHistory should cap at 100 entries', () async {
      // Add 105 entries
      for (int i = 0; i < 105; i++) {
        final episode = TestUtils.createSampleAudioFile(id: 'ep-$i');
        await service.addToListenHistory(episode,
            at: DateTime(2025, 1, 1).add(Duration(hours: i)));
      }

      expect(service.listenHistory.length, 100);
    });

    test('removeFromListenHistory should remove episode', () async {
      final episode = TestUtils.createSampleAudioFile(id: 'test-ep');
      await service.addToListenHistory(episode);
      expect(service.listenHistory.containsKey('test-ep'), isTrue);

      await service.removeFromListenHistory('test-ep');
      expect(service.listenHistory.containsKey('test-ep'), isFalse);
    });

    test('clearListenHistory should remove all entries', () async {
      final episode1 = TestUtils.createSampleAudioFile(id: 'ep1');
      final episode2 = TestUtils.createSampleAudioFile(id: 'ep2');
      await service.addToListenHistory(episode1);
      await service.addToListenHistory(episode2);

      await service.clearListenHistory();

      expect(service.listenHistory, isEmpty);
    });
  });

  group('ProgressTrackingService - Get Filtered Episodes', () {
    late List<dynamic> testEpisodes;

    setUp(() {
      // Set up completion states
      service.setCompletionForTesting('ep1', 0.95); // finished
      service.setCompletionForTesting('ep2', 0.5); // unfinished
      service.setCompletionForTesting('ep3', 0.3); // unfinished
      // ep4 never started

      testEpisodes = [
        TestUtils.createSampleAudioFile(id: 'ep1'),
        TestUtils.createSampleAudioFile(id: 'ep2'),
        TestUtils.createSampleAudioFile(id: 'ep3'),
        TestUtils.createSampleAudioFile(id: 'ep4'),
      ];
    });

    test('getUnfinishedEpisodes should return only unfinished episodes', () {
      final result = service.getUnfinishedEpisodes(testEpisodes.cast());
      expect(result.length, 2);
      expect(result.map((e) => e.id), containsAll(['ep2', 'ep3']));
    });

    test('getFinishedEpisodes should return only finished episodes', () {
      final result = service.getFinishedEpisodes(testEpisodes.cast());
      expect(result.length, 1);
      expect(result.first.id, 'ep1');
    });

    test('getListenHistoryEpisodes should return episodes in order', () {
      service.setHistoryForTesting('ep2', DateTime(2025, 1, 15));
      service.setHistoryForTesting('ep1', DateTime(2025, 1, 10));
      service.setHistoryForTesting('ep3', DateTime(2025, 1, 20));

      final result = service.getListenHistoryEpisodes(testEpisodes.cast());

      expect(result.length, 3);
      expect(result[0].id, 'ep3'); // Most recent
      expect(result[1].id, 'ep2');
      expect(result[2].id, 'ep1'); // Oldest
    });

    test('getListenHistoryEpisodes should respect limit', () {
      service.setHistoryForTesting('ep1', DateTime(2025, 1, 10));
      service.setHistoryForTesting('ep2', DateTime(2025, 1, 15));
      service.setHistoryForTesting('ep3', DateTime(2025, 1, 20));

      final result =
          service.getListenHistoryEpisodes(testEpisodes.cast(), limit: 2);

      expect(result.length, 2);
    });
  });

  group('ProgressTrackingService - Listening Sessions', () {
    test('startListeningSession should set session state', () {
      service.startListeningSession('test-ep');

      expect(service.currentEpisodeId, 'test-ep');
      expect(service.sessionStartTime, isNotNull);
      expect(service.sessionDuration, Duration.zero);
    });

    test('updateSessionDuration should update duration', () {
      service.startListeningSession('test-ep');
      service.updateSessionDuration(const Duration(minutes: 5));

      expect(service.sessionDuration, const Duration(minutes: 5));
    });

    test('endListeningSession should record history and clear state', () async {
      service.startListeningSession('test-ep');
      await service.endListeningSession(finalCompletion: 0.6);

      expect(service.currentEpisodeId, isNull);
      expect(service.sessionStartTime, isNull);
      expect(service.sessionDuration, Duration.zero);
      expect(service.listenHistory.containsKey('test-ep'), isTrue);
      expect(service.getEpisodeCompletion('test-ep'), 0.6);
    });

    test('endListeningSession without completion should only record history',
        () async {
      service.startListeningSession('test-ep');
      await service.endListeningSession();

      expect(service.listenHistory.containsKey('test-ep'), isTrue);
      expect(service.getEpisodeCompletion('test-ep'), 0.0);
    });
  });

  group('ProgressTrackingService - Statistics', () {
    test('getListeningStatistics should return correct stats', () {
      service.setCompletionForTesting('ep1', 0.95);
      service.setCompletionForTesting('ep2', 0.5);
      service.setHistoryForTesting('ep1', DateTime.now());

      final episodes = [
        TestUtils.createSampleAudioFile(
            id: 'ep1', duration: const Duration(minutes: 10)),
        TestUtils.createSampleAudioFile(
            id: 'ep2', duration: const Duration(minutes: 15)),
        TestUtils.createSampleAudioFile(
            id: 'ep3', duration: const Duration(minutes: 20)),
      ];

      final stats = service.getListeningStatistics(episodes);

      expect(stats['totalEpisodes'], 3);
      expect(stats['finishedCount'], 1);
      expect(stats['unfinishedCount'], 1);
      expect(stats['unstartedCount'], 1);
      expect(stats['listenHistorySize'], 1);
    });

    test('getListeningStatistics should handle empty episodes', () {
      final stats = service.getListeningStatistics([]);

      expect(stats['totalEpisodes'], 0);
      expect(stats['completionRate'], 0.0);
    });
  });

  group('ProgressTrackingService - Export/Import', () {
    test('exportProgressData should return all data', () {
      service.setCompletionForTesting('ep1', 0.7);
      service.setHistoryForTesting('ep1', DateTime(2025, 1, 15));

      final exported = service.exportProgressData();

      expect(exported.containsKey('episodeCompletion'), isTrue);
      expect(exported.containsKey('listenHistory'), isTrue);
      expect(exported.containsKey('exportedAt'), isTrue);
    });

    test('importProgressData should restore data', () async {
      final data = {
        'episodeCompletion': {'ep1': 0.8, 'ep2': 0.3},
        'listenHistory': {
          'ep1': '2025-01-15T12:00:00.000',
          'ep2': '2025-01-16T14:00:00.000',
        },
      };

      await service.importProgressData(data);

      expect(service.getEpisodeCompletion('ep1'), 0.8);
      expect(service.getEpisodeCompletion('ep2'), 0.3);
      expect(service.listenHistory.length, 2);
    });

    test('importProgressData should handle missing fields', () async {
      await service.importProgressData({});

      expect(service.episodeCompletion, isEmpty);
      expect(service.listenHistory, isEmpty);
    });
  });

  group('ProgressTrackingService - Clear and Dispose', () {
    test('clearAllProgress should clear all data', () async {
      service.setCompletionForTesting('ep1', 0.5);
      service.setHistoryForTesting('ep1', DateTime.now());

      await service.clearAllProgress();

      expect(service.episodeCompletion, isEmpty);
      expect(service.listenHistory, isEmpty);
    });

    test('dispose should clear data and prevent updates', () {
      service.setCompletionForTesting('ep1', 0.5);

      service.dispose();

      expect(service.episodeCompletion, isEmpty);
    });

    test('multiple dispose calls should be safe', () {
      service.dispose();
      service.dispose();
      service.dispose();
      // Should not throw
    });
  });

  group('ProgressTrackingService - Initialize', () {
    test('initialize should load without error', () async {
      await service.initialize();
      // Should not throw
    });
  });

  group('ProgressTrackingService - ChangeNotifier', () {
    test('should notify listeners on completion update', () async {
      int notifyCount = 0;
      service.addListener(() => notifyCount++);

      await service.updateEpisodeCompletion('test-ep', 0.5);

      expect(notifyCount, greaterThanOrEqualTo(1));
    });
  });
}
