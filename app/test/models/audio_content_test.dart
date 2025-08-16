import 'package:flutter_test/flutter_test.dart';
import 'package:from_fed_to_chain_app/models/audio_content.dart';

void main() {
  group('AudioContent Tests', () {
    test('should create AudioContent from valid JSON', () {
      // Arrange
      final json = {
        'id': '2025-08-16-test-content',
        'title': 'Test Audio Content',
        'language': 'en-US',
        'category': 'daily-news',
        'date': '2025-08-16',
        'status': 'published',
        'content': 'Test description content',
        'references': ['Source 1', 'Source 2'],
        'social_hook': 'Test social hook',
        'duration': 120,
        'updated_at': '2025-08-16T10:00:00Z',
      };

      // Act
      final audioContent = AudioContent.fromJson(json);

      // Assert
      expect(audioContent.id, equals('2025-08-16-test-content'));
      expect(audioContent.title, equals('Test Audio Content'));
      expect(audioContent.language, equals('en-US'));
      expect(audioContent.category, equals('daily-news'));
      expect(audioContent.date, equals(DateTime.parse('2025-08-16')));
      expect(audioContent.status, equals('published'));
      expect(audioContent.description, equals('Test description content'));
      expect(audioContent.references, equals(['Source 1', 'Source 2']));
      expect(audioContent.socialHook, equals('Test social hook'));
      expect(audioContent.duration, equals(const Duration(seconds: 120)));
      expect(audioContent.updatedAt,
          equals(DateTime.parse('2025-08-16T10:00:00Z')));
    });

    test('should handle minimal JSON with optional fields null', () {
      // Arrange
      final json = {
        'id': 'minimal-content',
        'title': 'Minimal Content',
        'language': 'zh-TW',
        'category': 'macro',
        'date': '2025-01-01',
        'status': 'draft',
        'updated_at': '2025-01-01T00:00:00Z',
      };

      // Act
      final audioContent = AudioContent.fromJson(json);

      // Assert
      expect(audioContent.id, equals('minimal-content'));
      expect(audioContent.title, equals('Minimal Content'));
      expect(audioContent.description, isNull);
      expect(audioContent.references, isEmpty);
      expect(audioContent.socialHook, isNull);
      expect(audioContent.duration, isNull);
    });

    test('should convert to JSON correctly', () {
      // Arrange
      final audioContent = AudioContent(
        id: 'test-content',
        title: 'Test Title',
        language: 'ja-JP',
        category: 'ethereum',
        date: DateTime.parse('2025-06-15'),
        status: 'reviewed',
        description: 'Test description',
        references: ['Ref 1'],
        socialHook: 'Test hook',
        duration: const Duration(minutes: 3),
        updatedAt: DateTime.parse('2025-06-15T12:00:00Z'),
      );

      // Act
      final json = audioContent.toJson();

      // Assert
      expect(json['id'], equals('test-content'));
      expect(json['title'], equals('Test Title'));
      expect(json['language'], equals('ja-JP'));
      expect(json['category'], equals('ethereum'));
      expect(json['date'], equals('2025-06-15T00:00:00.000Z'));
      expect(json['status'], equals('reviewed'));
      expect(json['content'], equals('Test description'));
      expect(json['references'], equals(['Ref 1']));
      expect(json['social_hook'], equals('Test hook'));
      expect(json['duration'], equals(180)); // 3 minutes in seconds
      expect(json['updated_at'], equals('2025-06-15T12:00:00.000Z'));
    });

    test('should support equality comparison', () {
      // Arrange
      final content1 = AudioContent(
        id: 'same-id',
        title: 'Same Title',
        language: 'en-US',
        category: 'daily-news',
        date: DateTime.parse('2025-01-01'),
        status: 'published',
        updatedAt: DateTime.parse('2025-01-01T12:00:00Z'),
      );

      final content2 = AudioContent(
        id: 'same-id',
        title: 'Same Title',
        language: 'en-US',
        category: 'daily-news',
        date: DateTime.parse('2025-01-01'),
        status: 'published',
        updatedAt: DateTime.parse('2025-01-01T12:00:00Z'),
      );

      final content3 = AudioContent(
        id: 'different-id',
        title: 'Same Title',
        language: 'en-US',
        category: 'daily-news',
        date: DateTime.parse('2025-01-01'),
        status: 'published',
        updatedAt: DateTime.parse('2025-01-01T12:00:00Z'),
      );

      // Assert
      expect(content1, equals(content2));
      expect(content1, isNot(equals(content3)));
      expect(content1.hashCode, equals(content2.hashCode));
    });

    test('should handle different content categories', () {
      final categories = ['daily-news', 'ethereum', 'macro', 'startup', 'ai'];

      for (final category in categories) {
        final content = AudioContent(
          id: 'test-$category',
          title: 'Test $category',
          language: 'en-US',
          category: category,
          date: DateTime.now(),
          status: 'published',
          updatedAt: DateTime.now(),
        );

        expect(content.category, equals(category));
      }
    });

    test('should handle different languages', () {
      final languages = ['zh-TW', 'en-US', 'ja-JP'];

      for (final language in languages) {
        final content = AudioContent(
          id: 'test-$language',
          title: 'Test Title',
          language: language,
          category: 'daily-news',
          date: DateTime.now(),
          status: 'published',
          updatedAt: DateTime.now(),
        );

        expect(content.language, equals(language));
      }
    });
  });
}
