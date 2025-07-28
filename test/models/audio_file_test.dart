import 'package:flutter_test/flutter_test.dart';
import 'package:from_fed_to_chain_audio/models/audio_file.dart';

void main() {
  group('AudioFile', () {
    group('constructor and getters', () {
      test('should create AudioFile with required parameters', () {
        final audioFile = AudioFile(
          id: '2025-07-21-test-audio',
          language: 'en-US',
          category: 'daily-news',
          fileName: 'test-audio.m3u8',
          sizeInBytes: 1024000,
          created: DateTime(2025, 7, 21),
          sourceUrl: 'https://example.com/test.m3u8',
        );

        expect(audioFile.id, equals('2025-07-21-test-audio'));
        expect(audioFile.language, equals('en-US'));
        expect(audioFile.category, equals('daily-news'));
        expect(audioFile.fileName, equals('test-audio.m3u8'));
        expect(audioFile.sizeInBytes, equals(1024000));
        expect(audioFile.sourceUrl, equals('https://example.com/test.m3u8'));
        expect(audioFile.hasContent, isFalse);
      });

      test('should handle optional parameters correctly', () {
        final duration = Duration(minutes: 5, seconds: 30);
        final audioFile = AudioFile(
          id: '2025-07-21-test-audio',
          language: 'ja-JP',
          category: 'ethereum',
          fileName: 'test-audio.m3u8',
          sizeInBytes: 2048000,
          created: DateTime(2025, 7, 21),
          sourceUrl: 'https://example.com/test.m3u8',
          title: 'Test Audio Title',
          duration: duration,
          hasContent: true,
        );

        expect(audioFile.title, equals('Test Audio Title'));
        expect(audioFile.duration, equals(duration));
        expect(audioFile.hasContent, isTrue);
      });
    });

    group('fromApiResponse factory', () {
      test('should create AudioFile from API response', () {
        final json = {
          'id': '2025-07-21-blockchain-news',
          'playlistUrl': 'https://api.example.com/playlist.m3u8',
          'title': 'Blockchain News Today',
          'hasContent': true,
          'date': '2025-07-21T10:00:00Z',
        };

        final audioFile =
            AudioFile.fromApiResponse(json, 'en-US', 'daily-news');

        expect(audioFile.id, equals('2025-07-21-blockchain-news'));
        expect(audioFile.language, equals('en-US'));
        expect(audioFile.category, equals('daily-news'));
        expect(audioFile.sourceUrl,
            equals('https://api.example.com/playlist.m3u8'));
        expect(audioFile.title, equals('Blockchain News Today'));
        expect(audioFile.hasContent, isTrue);
      });

      test('should handle API response without optional fields', () {
        final json = {
          'id': '2025-07-21-ethereum-update',
          'playlistUrl': 'https://api.example.com/playlist.m3u8',
        };

        final audioFile = AudioFile.fromApiResponse(json, 'ja-JP', 'ethereum');

        expect(audioFile.id, equals('2025-07-21-ethereum-update'));
        expect(audioFile.title, isNull);
        expect(audioFile.hasContent, isFalse);
        expect(audioFile.fileName, equals('2025-07-21-ethereum-update.m3u8'));
      });

      test('should parse date from ID when date field is missing', () {
        final json = {
          'id': '2025-07-21-test-content',
          'playlistUrl': 'https://api.example.com/playlist.m3u8',
        };

        final audioFile =
            AudioFile.fromApiResponse(json, 'en-US', 'daily-news');

        expect(audioFile.created.year, equals(2025));
        expect(audioFile.created.month, equals(7));
        expect(audioFile.created.day, equals(21));
      });
    });

    group('display methods', () {
      late AudioFile audioFile;

      setUp(() {
        audioFile = AudioFile(
          id: '2025-07-21-blockchain-revolution',
          language: 'en-US',
          category: 'daily-news',
          fileName: 'test.m3u8',
          sizeInBytes: 1536000, // 1.5MB
          created: DateTime(2025, 7, 21),
          sourceUrl: 'https://example.com/test.m3u8',
          duration: Duration(minutes: 3, seconds: 45),
        );
      });

      test('should format file size correctly', () {
        expect(audioFile.sizeFormatted, equals('1.5MB'));

        final smallFile = AudioFile(
          id: 'test',
          language: 'en-US',
          category: 'daily-news',
          fileName: 'small.m3u8',
          sizeInBytes: 512,
          created: DateTime.now(),
          sourceUrl: 'https://example.com/test.m3u8',
        );
        expect(smallFile.sizeFormatted, equals('512B'));

        final mediumFile = AudioFile(
          id: 'test',
          language: 'en-US',
          category: 'daily-news',
          fileName: 'medium.m3u8',
          sizeInBytes: 1536, // 1.5KB
          created: DateTime.now(),
          sourceUrl: 'https://example.com/test.m3u8',
        );
        expect(mediumFile.sizeFormatted, equals('1.5KB'));
      });

      test('should format duration correctly', () {
        expect(audioFile.durationFormatted, equals('3:45'));

        final noDurationFile = AudioFile(
          id: 'test',
          language: 'en-US',
          category: 'daily-news',
          fileName: 'test.m3u8',
          sizeInBytes: 1024,
          created: DateTime.now(),
          sourceUrl: 'https://example.com/test.m3u8',
        );
        expect(noDurationFile.durationFormatted, equals('Unknown'));
      });

      test('should format display date correctly', () {
        expect(audioFile.displayDate, equals('2025-07-21'));
      });

      test('should return correct category display names', () {
        expect(audioFile.categoryDisplayName, equals('Daily News'));

        final ethereumFile = AudioFile(
          id: 'test',
          language: 'en-US',
          category: 'ethereum',
          fileName: 'test.m3u8',
          sizeInBytes: 1024,
          created: DateTime.now(),
          sourceUrl: 'https://example.com/test.m3u8',
        );
        expect(ethereumFile.categoryDisplayName, equals('Ethereum'));
      });

      test('should return correct language display names', () {
        expect(audioFile.languageDisplayName, equals('English'));

        final chineseFile = AudioFile(
          id: 'test',
          language: 'zh-TW',
          category: 'daily-news',
          fileName: 'test.m3u8',
          sizeInBytes: 1024,
          created: DateTime.now(),
          sourceUrl: 'https://example.com/test.m3u8',
        );
        expect(chineseFile.languageDisplayName, equals('繁體中文'));

        final japaneseFile = AudioFile(
          id: 'test',
          language: 'ja-JP',
          category: 'daily-news',
          fileName: 'test.m3u8',
          sizeInBytes: 1024,
          created: DateTime.now(),
          sourceUrl: 'https://example.com/test.m3u8',
        );
        expect(japaneseFile.languageDisplayName, equals('日本語'));
      });

      test('should generate display title from ID when title is null', () {
        expect(audioFile.displayTitle, equals('Blockchain Revolution'));

        final withTitleFile = AudioFile(
          id: 'test-id',
          language: 'en-US',
          category: 'daily-news',
          fileName: 'test.m3u8',
          sizeInBytes: 1024,
          created: DateTime.now(),
          sourceUrl: 'https://example.com/test.m3u8',
          title: 'Custom Title',
        );
        expect(withTitleFile.displayTitle, equals('Custom Title'));
      });
    });

    group('utility methods', () {
      test('should return correct exists status', () {
        final validFile = AudioFile(
          id: 'test',
          language: 'en-US',
          category: 'daily-news',
          fileName: 'test.m3u8',
          sizeInBytes: 1024,
          created: DateTime.now(),
          sourceUrl: 'https://example.com/test.m3u8',
        );
        expect(validFile.exists, isTrue);

        final emptyUrlFile = AudioFile(
          id: 'test',
          language: 'en-US',
          category: 'daily-news',
          fileName: 'test.m3u8',
          sizeInBytes: 1024,
          created: DateTime.now(),
          sourceUrl: '',
        );
        expect(emptyUrlFile.exists, isFalse);
      });

      test('should return correct playback URL', () {
        final audioFile = AudioFile(
          id: 'test',
          language: 'en-US',
          category: 'daily-news',
          fileName: 'test.m3u8',
          sizeInBytes: 1024,
          created: DateTime.now(),
          sourceUrl: 'https://example.com/test.m3u8',
        );
        expect(audioFile.playbackUrl, equals('https://example.com/test.m3u8'));
      });
    });
  });
}
