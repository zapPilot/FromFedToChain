import 'package:flutter_test/flutter_test.dart';
import 'package:from_fed_to_chain_app/models/audio_file.dart';
import 'package:from_fed_to_chain_app/models/audio_content.dart';
import '../test_utils.dart';

void main() {
  group('AudioFile', () {
    group('Constructor', () {
      test('creates AudioFile with required fields', () {
        final audioFile = TestUtils.createSampleAudioFile();

        expect(audioFile.id, '2025-01-15-bitcoin-analysis');
        expect(audioFile.title, 'Bitcoin Analysis');
        expect(audioFile.language, 'en-US');
        expect(audioFile.category, 'daily-news');
        expect(audioFile.streamingUrl, 'https://example.com/audio.m3u8');
        expect(audioFile.path, 'audio/en-US/2025-01-15-bitcoin-analysis.m3u8');
        expect(audioFile.duration, const Duration(minutes: 5));
        expect(audioFile.fileSizeBytes, 1024000);
        expect(audioFile.lastModified, DateTime.parse('2025-01-15T10:00:00Z'));
      });

      test('handles optional fields correctly', () {
        final audioFile = AudioFile(
          id: 'test-id',
          title: 'Test Title',
          language: 'en-US',
          category: 'daily-news',
          streamingUrl: 'https://example.com/test.m3u8',
          path: 'test.m3u8',
          lastModified: DateTime.now(),
        );

        expect(audioFile.duration, isNull);
        expect(audioFile.fileSizeBytes, isNull);
        expect(audioFile.metadata, isNull);
      });
    });

    group('fromApiResponse', () {
      test('creates AudioFile from valid API response', () {
        final json = TestUtils.createAudioFileJson();
        final audioFile = AudioFile.fromApiResponse(json);

        expect(audioFile.id, '2025-01-15-bitcoin-analysis');
        expect(audioFile.title, 'Bitcoin Analysis');
        expect(audioFile.language, 'en-US');
        expect(audioFile.category, 'daily-news');
        expect(audioFile.streamingUrl, 'https://example.com/audio.m3u8');
        expect(audioFile.path, 'audio/en-US/2025-01-15-bitcoin-analysis.m3u8');
        expect(audioFile.duration, const Duration(minutes: 5));
        expect(audioFile.fileSizeBytes, 1024000);
        expect(audioFile.lastModified, DateTime.parse('2025-01-15T10:00:00Z'));
      });

      test('handles missing optional fields in API response', () {
        final json = {
          'id': 'test-id',
          'streaming_url': 'https://example.com/test.m3u8',
          'path': 'test.m3u8',
        };

        final audioFile = AudioFile.fromApiResponse(json);

        expect(audioFile.title, 'Test Id'); // Generated from ID
        expect(audioFile.language, 'unknown');
        expect(audioFile.category, 'unknown');
        expect(audioFile.duration, isNull);
        expect(audioFile.fileSizeBytes, isNull);
        expect(audioFile.lastModified, isA<DateTime>());
      });

      test('generates title from ID when title is missing', () {
        final json = {
          'id': '2025-07-15-ethereum-analysis-report',
          'streaming_url': 'https://example.com/test.m3u8',
          'path': 'test.m3u8',
        };

        final audioFile = AudioFile.fromApiResponse(json);
        expect(audioFile.title, '2025 07 15 Ethereum Analysis Report');
      });

      test('uses provided title when available', () {
        final json = {
          'id': 'test-id',
          'title': 'Custom Title',
          'streaming_url': 'https://example.com/test.m3u8',
          'path': 'test.m3u8',
        };

        final audioFile = AudioFile.fromApiResponse(json);
        expect(audioFile.title, 'Custom Title');
      });
    });

    group('fromContent', () {
      test('creates AudioFile from AudioContent and streaming path', () {
        final content = TestUtils.createSampleAudioContent();
        final streamingPath = 'audio/en-US/2025-01-15-bitcoin-analysis.m3u8';

        final audioFile = AudioFile.fromContent(content, streamingPath);

        expect(audioFile.id, content.id);
        expect(audioFile.title, content.title);
        expect(audioFile.language, content.language);
        expect(audioFile.category, content.category);
        expect(audioFile.duration, content.duration);
        expect(audioFile.lastModified, content.updatedAt);
        expect(audioFile.metadata, content);
        expect(audioFile.path, streamingPath);
        expect(audioFile.streamingUrl, contains(streamingPath));
      });
    });

    group('toJson', () {
      test('converts AudioFile to JSON correctly', () {
        final audioFile = TestUtils.createSampleAudioFile();
        final json = audioFile.toJson();

        expect(json['id'], '2025-01-15-bitcoin-analysis');
        expect(json['title'], 'Bitcoin Analysis');
        expect(json['language'], 'en-US');
        expect(json['category'], 'daily-news');
        expect(json['streaming_url'], 'https://example.com/audio.m3u8');
        expect(json['path'], 'audio/en-US/2025-01-15-bitcoin-analysis.m3u8');
        expect(json['duration'], 300);
        expect(json['size'], 1024000);
        expect(json['last_modified'], '2025-01-15T10:00:00.000Z');
      });

      test('handles null optional fields in JSON output', () {
        final audioFile = AudioFile(
          id: 'test-id',
          title: 'Test Title',
          language: 'en-US',
          category: 'daily-news',
          streamingUrl: 'https://example.com/test.m3u8',
          path: 'test.m3u8',
          lastModified: DateTime.parse('2025-01-15T10:00:00Z'),
        );

        final json = audioFile.toJson();

        expect(json['duration'], isNull);
        expect(json['size'], isNull);
      });
    });

    group('copyWith', () {
      test('creates copy with updated fields', () {
        final original = TestUtils.createSampleAudioFile();
        final copy = original.copyWith(
          title: 'Updated Title',
          duration: const Duration(minutes: 10),
        );

        expect(copy.title, 'Updated Title');
        expect(copy.duration, const Duration(minutes: 10));
        expect(copy.id, original.id); // Unchanged
        expect(copy.language, original.language); // Unchanged
      });

      test('creates exact copy when no parameters provided', () {
        final original = TestUtils.createSampleAudioFile();
        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.title, original.title);
        expect(copy.streamingUrl, original.streamingUrl);
        expect(copy.duration, original.duration);
      });
    });

    group('Display Properties', () {
      test('displayTitle returns title when not empty', () {
        final audioFile = TestUtils.createSampleAudioFile(title: 'Test Title');
        expect(audioFile.displayTitle, 'Test Title');
      });

      test('displayTitle generates from ID when title is empty', () {
        final audioFile = TestUtils.createSampleAudioFile(
          id: '2025-07-15-ethereum-analysis',
          title: '',
        );
        expect(audioFile.displayTitle, '2025 07 15 Ethereum Analysis');
      });

      test('displayTitle generates from ID when title is whitespace', () {
        final audioFile = TestUtils.createSampleAudioFile(title: '   ');
        expect(audioFile.displayTitle, '2025 01 15 Bitcoin Analysis');
      });

      test('sourceUrl returns streamingUrl', () {
        final audioFile = TestUtils.createSampleAudioFile();
        expect(audioFile.sourceUrl, audioFile.streamingUrl);
      });
    });

    group('File Type Checks', () {
      test('isHlsStream returns true for m3u8 files', () {
        final audioFile = TestUtils.createSampleAudioFile(
          path: 'audio/test.m3u8',
        );
        expect(audioFile.isHlsStream, isTrue);
      });

      test('isHlsStream returns false for non-m3u8 files', () {
        final audioFile = TestUtils.createSampleAudioFile(
          path: 'audio/test.wav',
        );
        expect(audioFile.isHlsStream, isFalse);
      });

      test('isDirectAudio returns true for wav files', () {
        final audioFile = TestUtils.createSampleAudioFile(
          path: 'audio/test.wav',
        );
        expect(audioFile.isDirectAudio, isTrue);
      });

      test('isDirectAudio returns true for mp3 files', () {
        final audioFile = TestUtils.createSampleAudioFile(
          path: 'audio/test.mp3',
        );
        expect(audioFile.isDirectAudio, isTrue);
      });

      test('isDirectAudio returns true for m4a files', () {
        final audioFile = TestUtils.createSampleAudioFile(
          path: 'audio/test.m4a',
        );
        expect(audioFile.isDirectAudio, isTrue);
      });

      test('isDirectAudio returns false for m3u8 files', () {
        final audioFile = TestUtils.createSampleAudioFile(
          path: 'audio/test.m3u8',
        );
        expect(audioFile.isDirectAudio, isFalse);
      });
    });

    group('Formatted Properties', () {
      test('formattedFileSize displays bytes correctly', () {
        final audioFile = TestUtils.createSampleAudioFile(fileSizeBytes: 512);
        expect(audioFile.formattedFileSize, '512.0 B');
      });

      test('formattedFileSize displays KB correctly', () {
        final audioFile =
            TestUtils.createSampleAudioFile(fileSizeBytes: 1536); // 1.5 KB
        expect(audioFile.formattedFileSize, '1.5 KB');
      });

      test('formattedFileSize displays MB correctly', () {
        final audioFile =
            TestUtils.createSampleAudioFile(fileSizeBytes: 1572864); // 1.5 MB
        expect(audioFile.formattedFileSize, '1.5 MB');
      });

      test('formattedFileSize displays GB correctly', () {
        final audioFile = TestUtils.createSampleAudioFile(
            fileSizeBytes: 1610612736); // 1.5 GB
        expect(audioFile.formattedFileSize, '1.5 GB');
      });

      test('formattedFileSize handles null size', () {
        final audioFile = TestUtils.createSampleAudioFile(fileSizeBytes: null);
        expect(audioFile.formattedFileSize, 'Unknown size');
      });

      test('formattedDuration handles minutes only', () {
        final audioFile = TestUtils.createSampleAudioFile(
          duration: const Duration(minutes: 3, seconds: 45),
        );
        expect(audioFile.formattedDuration, '3:45');
      });

      test('formattedDuration handles hours', () {
        final audioFile = TestUtils.createSampleAudioFile(
          duration: const Duration(hours: 1, minutes: 23, seconds: 45),
        );
        expect(audioFile.formattedDuration, '1:23:45');
      });

      test('formattedDuration handles null duration', () {
        final audioFile = TestUtils.createSampleAudioFile(duration: null);
        expect(audioFile.formattedDuration, '');
      });

      test('formattedDuration pads seconds correctly', () {
        final audioFile = TestUtils.createSampleAudioFile(
          duration: const Duration(minutes: 5, seconds: 7),
        );
        expect(audioFile.formattedDuration, '5:07');
      });
    });

    group('Category and Language Emojis', () {
      test('returns correct emoji for each category', () {
        for (final entry in TestUtils.categoryEmojis.entries) {
          final audioFile =
              TestUtils.createSampleAudioFile(category: entry.key);
          expect(audioFile.categoryEmoji, entry.value,
              reason: 'Category: ${entry.key}');
        }
      });

      test('returns default emoji for unknown category', () {
        final audioFile = TestUtils.createSampleAudioFile(category: 'unknown');
        expect(audioFile.categoryEmoji, '🎧');
      });

      test('returns correct flag for each language', () {
        for (final entry in TestUtils.languageEmojis.entries) {
          final audioFile =
              TestUtils.createSampleAudioFile(language: entry.key);
          expect(audioFile.languageFlag, entry.value,
              reason: 'Language: ${entry.key}');
        }
      });

      test('returns default flag for unknown language', () {
        final audioFile = TestUtils.createSampleAudioFile(language: 'unknown');
        expect(audioFile.languageFlag, '🌐');
      });
    });

    group('publishDate', () {
      test('parses date from ID correctly', () {
        final audioFile = TestUtils.createSampleAudioFile(
          id: '2025-07-15-bitcoin-analysis',
        );
        expect(audioFile.publishDate, DateTime.parse('2025-07-15'));
      });

      test('handles different date formats in ID', () {
        final audioFile = TestUtils.createSampleAudioFile(
          id: '2025-12-31-year-end-review',
        );
        expect(audioFile.publishDate, DateTime.parse('2025-12-31'));
      });

      test('falls back to lastModified for invalid date in ID', () {
        final lastModified = DateTime.parse('2025-01-15T10:00:00Z');
        final audioFile = AudioFile(
          id: 'invalid-date-format',
          title: 'Test',
          language: 'en-US',
          category: 'daily-news',
          streamingUrl: 'https://example.com/test.m3u8',
          path: 'test.m3u8',
          lastModified: lastModified,
        );
        expect(audioFile.publishDate, lastModified);
      });

      test('falls back to lastModified for short ID', () {
        final lastModified = DateTime.parse('2025-01-15T10:00:00Z');
        final audioFile = AudioFile(
          id: 'short',
          title: 'Test',
          language: 'en-US',
          category: 'daily-news',
          streamingUrl: 'https://example.com/test.m3u8',
          path: 'test.m3u8',
          lastModified: lastModified,
        );
        expect(audioFile.publishDate, lastModified);
      });

      test('falls back to lastModified for malformed date in ID', () {
        final lastModified = DateTime.parse('2025-01-15T10:00:00Z');
        final audioFile = AudioFile(
          id: '2025-13-35-invalid-date',
          title: 'Test',
          language: 'en-US',
          category: 'daily-news',
          streamingUrl: 'https://example.com/test.m3u8',
          path: 'test.m3u8',
          lastModified: lastModified,
        );
        expect(audioFile.publishDate, lastModified);
      });
    });

    group('Equality', () {
      test('equal objects have same hash code', () {
        final audioFile1 = TestUtils.createSampleAudioFile();
        final audioFile2 = TestUtils.createSampleAudioFile();

        expect(audioFile1, equals(audioFile2));
        expect(audioFile1.hashCode, equals(audioFile2.hashCode));
      });

      test('different objects are not equal', () {
        final audioFile1 = TestUtils.createSampleAudioFile();
        final audioFile2 =
            TestUtils.createSampleAudioFile(title: 'Different Title');

        expect(audioFile1, isNot(equals(audioFile2)));
      });

      test('same object is equal to itself', () {
        final audioFile = TestUtils.createSampleAudioFile();
        expect(audioFile, equals(audioFile));
      });
    });

    group('toString', () {
      test('returns formatted string representation', () {
        final audioFile = TestUtils.createSampleAudioFile();
        final string = audioFile.toString();

        expect(string, contains('AudioFile'));
        expect(string, contains('2025-01-15-bitcoin-analysis'));
        expect(string, contains('Bitcoin Analysis'));
        expect(string, contains('en-US'));
        expect(string, contains('daily-news'));
        expect(string, contains('https://example.com/audio.m3u8'));
      });
    });

    group('Edge Cases', () {
      test('handles empty strings', () {
        final audioFile = TestUtils.createEdgeCaseAudioFile();
        expect(audioFile.id, '');
        expect(audioFile.title, '');
        expect(audioFile.displayTitle, ''); // Generated from empty ID
        expect(audioFile.formattedFileSize, 'Unknown size');
        expect(audioFile.formattedDuration, '');
      });

      test('handles very large file sizes', () {
        final audioFile = TestUtils.createSampleAudioFile(
          fileSizeBytes: 5497558138880, // 5TB
        );
        expect(audioFile.formattedFileSize, '5.0 GB'); // Should cap at GB
      });

      test('handles very long durations', () {
        final audioFile = TestUtils.createSampleAudioFile(
          duration: const Duration(hours: 25, minutes: 30, seconds: 45),
        );
        expect(audioFile.formattedDuration, '25:30:45');
      });

      test('handles special characters in path', () {
        final audioFile = TestUtils.createSampleAudioFile(
          path: 'audio/special chars & symbols/test file.m3u8',
        );
        expect(audioFile.path, 'audio/special chars & symbols/test file.m3u8');
        expect(audioFile.isHlsStream, isTrue);
      });
    });

    group('Static Methods', () {
      test('_generateTitleFromId formats correctly', () {
        // This is tested indirectly through displayTitle and fromApiResponse
        final audioFile = AudioFile.fromApiResponse({
          'id': 'hello-world-test-case',
          'streaming_url': 'https://example.com/test.m3u8',
          'path': 'test.m3u8',
        });
        expect(audioFile.title, 'Hello World Test Case');
      });
    });
  });
}
