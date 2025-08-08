import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:from_fed_to_chain_app/services/content_service.dart';
import '../test_utils.dart';

void main() {
  group('ContentService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('filters episodes by language, category and search query', () async {
      final service = ContentService();
      await Future.delayed(Duration.zero);

      final ep1 = TestUtils.createSampleAudioFile(
        id: '2025-01-01-episode1',
        language: 'en-US',
        category: 'daily-news',
        title: 'Bitcoin Update',
      );
      final ep2 = TestUtils.createSampleAudioFile(
        id: '2025-01-02-episode2',
        language: 'en-US',
        category: 'ai',
        title: 'AI News',
      );
      final ep3 = TestUtils.createSampleAudioFile(
        id: '2025-01-03-episode3',
        language: 'zh-TW',
        category: 'daily-news',
        title: '金融新聞',
      );
      service.allEpisodes.addAll([ep1, ep2, ep3]);

      await service.setLanguage('en-US');
      expect(service.filteredEpisodes, containsAll([ep1, ep2]));

      await service.setCategory('daily-news');
      expect(service.filteredEpisodes, [ep1]);

      await service.setCategory('all');
      service.setSearchQuery('AI');
      expect(service.filteredEpisodes, [ep2]);
    });

    test('sorts episodes and navigates correctly', () async {
      final service = ContentService();
      await Future.delayed(Duration.zero);

      final older = TestUtils.createSampleAudioFile(
        id: '2024-01-01-old',
        language: 'en-US',
        category: 'daily-news',
        title: 'Old Episode',
      );
      final newer = TestUtils.createSampleAudioFile(
        id: '2025-01-01-new',
        language: 'en-US',
        category: 'daily-news',
        title: 'New Episode',
      );
      service.allEpisodes.addAll([older, newer]);

      await service.setLanguage('en-US');
      await service.setCategory('daily-news');

      await service.setSortOrder('oldest');
      expect(service.filteredEpisodes.first, older);

      await service.setSortOrder('newest');
      expect(service.filteredEpisodes.first, newer);

      final next = service.getNextEpisode(older);
      expect(next, newer);

      final previous = service.getPreviousEpisode(newer);
      expect(previous, older);
    });

    test('tracks episode completion', () async {
      final service = ContentService();
      await Future.delayed(Duration.zero);

      await service.updateEpisodeCompletion('episode1', 0.5);
      expect(service.getEpisodeCompletion('episode1'), 0.5);
      expect(service.isEpisodeFinished('episode1'), false);

      await service.markEpisodeAsFinished('episode1');
      expect(service.getEpisodeCompletion('episode1'), 1.0);
      expect(service.isEpisodeFinished('episode1'), true);
    });
  });
}
