import 'package:flutter_test/flutter_test.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_content.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';

void main() {
  group('AudioFile Tests', () {
    test('should create AudioFile from API response', () {
      // Arrange
      final apiResponse = {
        'id': '2025-08-16-bitcoin-analysis',
        'title': 'Bitcoin Market Analysis',
        'language': 'en-US',
        'category': 'daily-news',
        'streaming_url':
            'https://r2.example.com/audio/en-US/2025-08-16-bitcoin-analysis.m3u8',
        'path': 'audio/en-US/2025-08-16-bitcoin-analysis.m3u8',
        'duration': 180,
        'size': 5242880,
        'last_modified': '2025-08-16T10:30:00Z',
      };

      // Act
      final audioFile = AudioFile.fromApiResponse(apiResponse);

      // Assert
      expect(audioFile.id, equals('2025-08-16-bitcoin-analysis'));
      expect(audioFile.title, equals('Bitcoin Market Analysis'));
      expect(audioFile.language, equals('en-US'));
      expect(audioFile.category, equals('daily-news'));
      expect(
          audioFile.streamingUrl,
          equals(
              'https://r2.example.com/audio/en-US/2025-08-16-bitcoin-analysis.m3u8'));
      expect(audioFile.path,
          equals('audio/en-US/2025-08-16-bitcoin-analysis.m3u8'));
      expect(audioFile.duration, equals(const Duration(seconds: 180)));
      expect(audioFile.fileSizeBytes, equals(5242880));
      expect(audioFile.lastModified,
          equals(DateTime.parse('2025-08-16T10:30:00Z')));
    });

    test('should handle API response with missing optional fields', () {
      // Arrange
      final apiResponse = {
        'id': 'minimal-audio',
        'streaming_url': 'https://r2.example.com/minimal.m3u8',
        'path': 'audio/minimal.m3u8',
      };

      // Act
      final audioFile = AudioFile.fromApiResponse(apiResponse);

      // Assert
      expect(audioFile.id, equals('minimal-audio'));
      expect(audioFile.title, equals('Minimal Audio')); // Generated from ID
      expect(audioFile.language, equals('unknown'));
      expect(audioFile.category, equals('unknown'));
      expect(audioFile.duration, isNull);
      expect(audioFile.fileSizeBytes, isNull);
      expect(audioFile.lastModified, isA<DateTime>());
    });

    test('should create AudioFile from AudioContent', () {
      // Arrange
      final audioContent = AudioContent(
        id: 'test-content-id',
        title: 'Test Content Title',
        language: 'ja-JP',
        category: 'ethereum',
        date: DateTime.parse('2025-06-15'),
        status: 'published',
        duration: const Duration(minutes: 5),
        updatedAt: DateTime.parse('2025-06-15T15:00:00Z'),
      );

      const streamingPath = 'audio/ja-JP/test-content-id.m3u8';

      // Act
      final audioFile = AudioFile.fromContent(audioContent, streamingPath);

      // Assert
      expect(audioFile.id, equals('test-content-id'));
      expect(audioFile.title, equals('Test Content Title'));
      expect(audioFile.language, equals('ja-JP'));
      expect(audioFile.category, equals('ethereum'));
      expect(audioFile.path, equals(streamingPath));
      expect(audioFile.duration, equals(const Duration(minutes: 5)));
      expect(audioFile.lastModified,
          equals(DateTime.parse('2025-06-15T15:00:00Z')));
      expect(audioFile.metadata, equals(audioContent));
    });

    test('should format duration correctly', () {
      // Arrange
      final audioFile = AudioFile(
        id: 'duration-test',
        title: 'Duration Test',
        language: 'en-US',
        category: 'test',
        streamingUrl: 'https://example.com/test.m3u8',
        path: 'test.m3u8',
        duration: const Duration(minutes: 3, seconds: 45),
        lastModified: DateTime.now(),
      );

      // Act
      final formattedDuration = audioFile.formattedDuration;

      // Assert
      expect(formattedDuration, equals('3:45'));
    });

    test('should handle duration formatting for different lengths', () {
      final testCases = [
        {'duration': Duration(seconds: 30), 'expected': '0:30'},
        {'duration': Duration(minutes: 1, seconds: 5), 'expected': '1:05'},
        {'duration': Duration(minutes: 15, seconds: 0), 'expected': '15:00'},
        {
          'duration': Duration(hours: 1, minutes: 23, seconds: 45),
          'expected': '1:23:45'
        },
      ];

      for (final testCase in testCases) {
        final audioFile = AudioFile(
          id: 'test',
          title: 'Test',
          language: 'en-US',
          category: 'test',
          streamingUrl: 'https://example.com/test.m3u8',
          path: 'test.m3u8',
          duration: testCase['duration'] as Duration,
          lastModified: DateTime.now(),
        );

        expect(audioFile.formattedDuration, equals(testCase['expected']));
      }
    });

    test('should handle null duration formatting', () {
      // Arrange
      final audioFile = AudioFile(
        id: 'no-duration',
        title: 'No Duration',
        language: 'en-US',
        category: 'test',
        streamingUrl: 'https://example.com/test.m3u8',
        path: 'test.m3u8',
        lastModified: DateTime.now(),
      );

      // Act & Assert
      expect(audioFile.formattedDuration, equals('--:--'));
    });

    test('should support equality comparison', () {
      // Arrange
      final file1 = AudioFile(
        id: 'same-id',
        title: 'Same Title',
        language: 'en-US',
        category: 'daily-news',
        streamingUrl: 'https://example.com/same.m3u8',
        path: 'same.m3u8',
        lastModified: DateTime.parse('2025-01-01T12:00:00Z'),
      );

      final file2 = AudioFile(
        id: 'same-id',
        title: 'Same Title',
        language: 'en-US',
        category: 'daily-news',
        streamingUrl: 'https://example.com/same.m3u8',
        path: 'same.m3u8',
        lastModified: DateTime.parse('2025-01-01T12:00:00Z'),
      );

      final file3 = AudioFile(
        id: 'different-id',
        title: 'Same Title',
        language: 'en-US',
        category: 'daily-news',
        streamingUrl: 'https://example.com/same.m3u8',
        path: 'same.m3u8',
        lastModified: DateTime.parse('2025-01-01T12:00:00Z'),
      );

      // Assert
      expect(file1, equals(file2));
      expect(file1, isNot(equals(file3)));
      expect(file1.hashCode, equals(file2.hashCode));
    });

    test('should format file size correctly', () {
      final testCases = [
        {'bytes': 512, 'expected': '512 B'},
        {'bytes': 1536, 'expected': '1.5 KB'},
        {'bytes': 1048576, 'expected': '1.0 MB'},
        {'bytes': 5242880, 'expected': '5.0 MB'},
        {'bytes': 1073741824, 'expected': '1.0 GB'},
      ];

      for (final testCase in testCases) {
        final audioFile = AudioFile(
          id: 'size-test',
          title: 'Size Test',
          language: 'en-US',
          category: 'test',
          streamingUrl: 'https://example.com/test.m3u8',
          path: 'test.m3u8',
          fileSizeBytes: testCase['bytes'] as int,
          lastModified: DateTime.now(),
        );

        expect(audioFile.formattedFileSize, equals(testCase['expected']));
      }
    });

    test('should handle null file size formatting', () {
      // Arrange
      final audioFile = AudioFile(
        id: 'no-size',
        title: 'No Size',
        language: 'en-US',
        category: 'test',
        streamingUrl: 'https://example.com/test.m3u8',
        path: 'test.m3u8',
        lastModified: DateTime.now(),
      );

      // Act & Assert
      expect(audioFile.formattedFileSize, equals('Unknown'));
    });
  });
}
