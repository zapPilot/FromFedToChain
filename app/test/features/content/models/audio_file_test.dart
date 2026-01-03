import 'package:flutter_test/flutter_test.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_content.dart';

void main() {
  group('AudioFile', () {
    final testDate = DateTime.parse('2025-01-01T12:00:00Z');

    final testAudioFile = AudioFile(
      id: 'test-id',
      title: 'Test Title',
      language: 'en-US',
      category: 'daily-news',
      streamingUrl: 'https://example.com/audio.m3u8',
      path: 'audio/en-US/daily-news/test-id/audio.m3u8',
      duration: const Duration(minutes: 5, seconds: 30),
      fileSizeBytes: 1024 * 1024 * 5, // 5MB
      lastModified: testDate,
    );

    test('props are correct', () {
      expect(testAudioFile.props, [
        'test-id',
        'Test Title',
        'en-US',
        'daily-news',
        'https://example.com/audio.m3u8',
        'audio/en-US/daily-news/test-id/audio.m3u8',
        const Duration(minutes: 5, seconds: 30),
        1024 * 1024 * 5,
        testDate,
      ]);
    });

    test('toJson returns correct map', () {
      final json = testAudioFile.toJson();
      expect(json['id'], 'test-id');
      expect(json['title'], 'Test Title');
      expect(json['language'], 'en-US');
      expect(json['category'], 'daily-news');
      expect(json['streaming_url'], 'https://example.com/audio.m3u8');
      expect(json['path'], 'audio/en-US/daily-news/test-id/audio.m3u8');
      expect(json['duration'], 330);
      expect(json['size'], 1024 * 1024 * 5);
      expect(json['last_modified'], testDate.toIso8601String());
    });

    test('fromApiResponse creates correct instance', () {
      final json = {
        'id': 'test-id-2',
        'title': 'API Title',
        'language': 'ja-JP',
        'category': 'defi',
        'streaming_url': 'https://example.com/stream',
        'path': 'path/to/file',
        'duration': 120,
        'size': 2048,
        'last_modified': '2025-02-01T10:00:00Z',
      };

      final audioFile = AudioFile.fromApiResponse(json);

      expect(audioFile.id, 'test-id-2');
      expect(audioFile.title, 'API Title');
      expect(audioFile.language, 'ja-JP');
      expect(audioFile.category, 'defi');
      expect(audioFile.duration?.inSeconds, 120);
      expect(audioFile.fileSizeBytes, 2048);
    });

    test('fromApiResponse handles minimal data', () {
      final json = {
        'id': 'minimal-id',
        'path': 'minimal/path',
        'streaming_url': 'https://example.com/min',
      };

      final audioFile = AudioFile.fromApiResponse(json);

      expect(audioFile.id, 'minimal-id');
      expect(audioFile.language, 'unknown');
      expect(audioFile.category, 'unknown');
      expect(audioFile.duration, isNull);
    });

    test('fromContent creates correct instance', () {
      final content = AudioContent(
        id: 'content-id',
        title: 'Content Title',
        language: 'zh-TW',
        category: 'macro',
        date: DateTime.now(),
        status: 'published',
        updatedAt: DateTime.now(),
        duration: const Duration(seconds: 60),
      );

      final audioFile = AudioFile.fromContent(content, 'streaming/path');

      expect(audioFile.id, 'content-id');
      expect(audioFile.title, 'Content Title');
      expect(audioFile.metadata, content);
      expect(audioFile.streamingUrl, contains('streaming/path'));
    });

    test('copyWith updates fields correctly', () {
      final updated = testAudioFile.copyWith(
        title: 'New Title',
        duration: const Duration(minutes: 10),
      );

      expect(updated.title, 'New Title');
      expect(updated.duration?.inMinutes, 10);
      expect(updated.id, testAudioFile.id);
    });

    test('getters return correct values', () {
      expect(testAudioFile.isHlsStream, isTrue);
      expect(testAudioFile.isDirectAudio, isFalse);

      final mp3File = testAudioFile.copyWith(path: 'test.mp3');
      expect(mp3File.isDirectAudio, isTrue);

      expect(testAudioFile.formattedDuration, '5:30');
      expect(testAudioFile.formattedFileSize, '5.0 MB');
    });

    test('formattedFileSize handles various sizes', () {
      final small = testAudioFile.copyWith(fileSizeBytes: 500);
      expect(small.formattedFileSize, '500 B');

      final kb = testAudioFile.copyWith(fileSizeBytes: 1024 * 5); // 5KB
      expect(kb.formattedFileSize, '5.0 KB');

      final gb =
          testAudioFile.copyWith(fileSizeBytes: 1024 * 1024 * 1024 * 2); // 2GB
      expect(gb.formattedFileSize, '2.0 GB');
    });

    test('categoryEmoji returns correct emojis', () {
      expect(
          testAudioFile.copyWith(category: 'daily-news').categoryEmoji, '📰');
      expect(testAudioFile.copyWith(category: 'ethereum').categoryEmoji, '⚡');
      expect(testAudioFile.copyWith(category: 'unknown').categoryEmoji, '🎧');
    });

    test('languageFlag returns correct flags', () {
      expect(testAudioFile.copyWith(language: 'zh-TW').languageFlag, '🇹🇼');
      expect(testAudioFile.copyWith(language: 'en-US').languageFlag, '🇺🇸');
      expect(testAudioFile.copyWith(language: 'ja-JP').languageFlag, '🇯🇵');
      expect(testAudioFile.copyWith(language: 'unknown').languageFlag, '🌐');
    });

    test('publishDate extracts date from ID correctly', () {
      final dateId = testAudioFile.copyWith(id: '2025-10-20-some-title');
      expect(dateId.publishDate, DateTime(2025, 10, 20));

      final noDateId =
          testAudioFile.copyWith(id: 'just-some-title', lastModified: testDate);
      expect(noDateId.publishDate, testDate);
    });

    test('displayTitle falls back to formatted ID if title isEmpty', () {
      final emptyTitle =
          testAudioFile.copyWith(title: '', id: 'my-cool-episode');
      expect(emptyTitle.displayTitle, 'My Cool Episode');

      final spaceTitle =
          testAudioFile.copyWith(title: '   ', id: 'another-episode');
      expect(spaceTitle.displayTitle, 'Another Episode');
    });
  });
}
