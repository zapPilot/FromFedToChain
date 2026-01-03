import 'package:flutter_test/flutter_test.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_content.dart';

void main() {
  group('AudioContent', () {
    final testDate = DateTime.parse('2025-01-01T12:00:00Z');
    final updateDate = DateTime.parse('2025-01-02T12:00:00Z');

    final testContent = AudioContent(
      id: 'test-id',
      title: 'Test Title',
      language: 'en-US',
      category: 'daily-news',
      date: testDate,
      status: 'published',
      description: 'Test Description',
      references: const ['Ref 1', 'Ref 2'],
      socialHook: 'Check this out!',
      duration: const Duration(minutes: 5),
      updatedAt: updateDate,
    );

    test('props are correct', () {
      expect(testContent.props, [
        'test-id',
        'Test Title',
        'en-US',
        'daily-news',
        testDate,
        'published',
        'Test Description',
        ['Ref 1', 'Ref 2'],
        'Check this out!',
        const Duration(minutes: 5),
        updateDate,
      ]);
    });

    test('toJson returns correct map', () {
      final json = testContent.toJson();
      expect(json['id'], 'test-id');
      expect(json['title'], 'Test Title');
      expect(json['language'], 'en-US');
      expect(json['category'], 'daily-news');
      expect(json['date'], testDate.toUtc().toIso8601String());
      expect(json['status'], 'published');
      expect(json['content'], 'Test Description');
      expect(json['references'], ['Ref 1', 'Ref 2']);
      expect(json['social_hook'], 'Check this out!');
      expect(json['duration'], 300);
      expect(json['updated_at'], updateDate.toUtc().toIso8601String());
    });

    test('fromJson creates correct instance', () {
      final json = {
        'id': 'json-id',
        'title': 'JSON Title',
        'language': 'ja-JP',
        'category': 'defi',
        'date': '2025-02-01T10:00:00Z',
        'status': 'draft',
        'content': 'JSON Content',
        'references': ['Link 1'],
        'social_hook': 'Hook',
        'duration': 120,
        'updated_at': '2025-02-01T11:00:00Z',
      };

      final content = AudioContent.fromJson(json);

      expect(content.id, 'json-id');
      expect(content.title, 'JSON Title');
      expect(content.description, 'JSON Content');
      expect(content.references, ['Link 1']);
      expect(content.duration?.inSeconds, 120);
    });

    test('copyWith updates fields correctly', () {
      final updated = testContent.copyWith(
        title: 'New Title',
        status: 'archived',
      );

      expect(updated.title, 'New Title');
      expect(updated.status, 'archived');
      expect(updated.id, testContent.id);
    });

    test('displayTitle falls back to formatted ID', () {
      final emptyTitle = testContent.copyWith(title: '');
      expect(emptyTitle.displayTitle,
          'TEST ID'); // Assuming ID is 'test-id', replaced - with space and upper case
    });

    test('formattedDate returns YYYY-MM-DD', () {
      expect(testContent.formattedDate, '2025-01-01');
    });

    test('hasAudio returns correct boolean based on status', () {
      expect(testContent.copyWith(status: 'draft').hasAudio, isFalse);
      expect(testContent.copyWith(status: 'reviewed').hasAudio, isFalse);
      expect(testContent.copyWith(status: 'translated').hasAudio, isFalse);

      expect(testContent.copyWith(status: 'wav').hasAudio, isTrue);
      expect(testContent.copyWith(status: 'm3u8').hasAudio, isTrue);
      expect(testContent.copyWith(status: 'cloudflare').hasAudio, isTrue);
      expect(testContent.copyWith(status: 'content').hasAudio, isTrue);
      expect(testContent.copyWith(status: 'social').hasAudio, isTrue);
    });

    test('categoryEmoji returns correct emojis', () {
      expect(testContent.copyWith(category: 'daily-news').categoryEmoji, '📰');
      expect(testContent.copyWith(category: 'unknown').categoryEmoji, '🎧');
    });

    test('languageFlag returns correct flags', () {
      expect(testContent.copyWith(language: 'zh-TW').languageFlag, '🇹🇼');
      expect(testContent.copyWith(language: 'unknown').languageFlag, '🌐');
    });
  });
}
