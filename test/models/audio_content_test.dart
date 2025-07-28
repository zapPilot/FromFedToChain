import 'package:flutter_test/flutter_test.dart';
import 'package:from_fed_to_chain_audio/models/audio_content.dart';

void main() {
  group('AudioContent constructor and getters', () {
    test('should create AudioContent with required parameters', () {
      final audioContent = AudioContent(
        id: '2025-07-21-test-content',
        title: 'Test Audio Content',
        category: 'daily-news',
        language: 'zh-TW',
        date: '2025-07-21',
        references: ['Reference 1', 'Reference 2'],
        content: 'This is test content for audio generation.',
        status: 'draft',
        updatedAt: DateTime(2025, 7, 21),
        author: 'David Chang',
      );

      expect(audioContent.id, equals('2025-07-21-test-content'));
      expect(audioContent.title, equals('Test Audio Content'));
      expect(audioContent.category, equals('daily-news'));
      expect(audioContent.language, equals('zh-TW'));
      expect(audioContent.date, equals('2025-07-21'));
      expect(audioContent.references, equals(['Reference 1', 'Reference 2']));
      expect(audioContent.content,
          equals('This is test content for audio generation.'));
      expect(audioContent.status, equals('draft'));
      expect(audioContent.updatedAt, equals(DateTime(2025, 7, 21)));
      expect(audioContent.author, equals('David Chang'));
    });

    test('should handle optional parameters correctly', () {
      final audioContent = AudioContent(
        id: '2025-07-21-minimal-content',
        title: 'Minimal Content',
        category: 'ethereum',
        language: 'en-US',
        date: '2025-07-21',
        audioFile: 'path/to/audio.wav',
        socialHook: 'Amazing crypto news! 🚀',
        references: [],
        content: 'Minimal content',
        status: 'published',
        updatedAt: DateTime(2025, 7, 21, 15, 30),
        author: 'David Chang',
      );

      expect(audioContent.audioFile, equals('path/to/audio.wav'));
      expect(audioContent.socialHook, equals('Amazing crypto news! 🚀'));
      expect(audioContent.references, isEmpty);
    });
  });

  group('AudioContent fromJson factory', () {
    test('should create AudioContent from JSON response', () {
      final json = {
        'id': '2025-07-21-json-test',
        'title': 'JSON Test Content',
        'category': 'macro',
        'language': 'ja-JP',
        'date': '2025-07-21',
        'audio_file': 'audio/test.wav',
        'social_hook': 'Test social hook',
        'references': ['Source A', 'Source B', 'Source C'],
        'content': 'This content was created from JSON.',
        'status': 'reviewed',
        'updated_at': '2025-07-21T10:30:00Z',
      };

      final audioContent = AudioContent.fromJson(json);

      expect(audioContent.id, equals('2025-07-21-json-test'));
      expect(audioContent.title, equals('JSON Test Content'));
      expect(audioContent.category, equals('macro'));
      expect(audioContent.language, equals('ja-JP'));
      expect(audioContent.date, equals('2025-07-21'));
      expect(audioContent.audioFile, equals('audio/test.wav'));
      expect(audioContent.socialHook, equals('Test social hook'));
      expect(audioContent.references,
          equals(['Source A', 'Source B', 'Source C']));
      expect(
          audioContent.content, equals('This content was created from JSON.'));
      expect(audioContent.status, equals('reviewed'));
      expect(audioContent.updatedAt,
          equals(DateTime.parse('2025-07-21T10:30:00Z')));
      expect(audioContent.author, equals('David Chang'));
    });

    test('should handle JSON response without optional fields', () {
      final json = {
        'id': '2025-07-21-minimal-json',
        'title': 'Minimal JSON Content',
        'category': 'startup',
        'language': 'en-US',
        'date': '2025-07-21',
        'content': 'Minimal JSON content',
        'status': 'draft',
      };

      final audioContent = AudioContent.fromJson(json);

      expect(audioContent.id, equals('2025-07-21-minimal-json'));
      expect(audioContent.title, equals('Minimal JSON Content'));
      expect(audioContent.audioFile, isNull);
      expect(audioContent.socialHook, isNull);
      expect(audioContent.references, isEmpty);
      expect(audioContent.author, equals('David Chang'));
    });

    test('should handle empty JSON gracefully', () {
      final json = <String, dynamic>{};
      final audioContent = AudioContent.fromJson(json);

      expect(audioContent.id, equals(''));
      expect(audioContent.title, equals(''));
      expect(audioContent.category, equals(''));
      expect(audioContent.language, equals(''));
      expect(audioContent.date, equals(''));
      expect(audioContent.content, equals(''));
      expect(audioContent.status, equals(''));
      expect(audioContent.references, isEmpty);
      expect(audioContent.author, equals('David Chang'));
    });
  });

  group('AudioContent toJson method', () {
    test('should convert AudioContent to JSON correctly', () {
      final audioContent = AudioContent(
        id: '2025-07-21-to-json-test',
        title: 'To JSON Test',
        category: 'ai',
        language: 'zh-TW',
        date: '2025-07-21',
        audioFile: 'audio/tojson.wav',
        socialHook: 'Converting to JSON! 📄',
        references: ['JSON Ref 1', 'JSON Ref 2'],
        content: 'This will be converted to JSON.',
        status: 'translated',
        updatedAt: DateTime(2025, 7, 21, 12, 0),
        author: 'David Chang',
      );

      final json = audioContent.toJson();

      expect(json['id'], equals('2025-07-21-to-json-test'));
      expect(json['title'], equals('To JSON Test'));
      expect(json['category'], equals('ai'));
      expect(json['language'], equals('zh-TW'));
      expect(json['date'], equals('2025-07-21'));
      expect(json['audio_file'], equals('audio/tojson.wav'));
      expect(json['social_hook'], equals('Converting to JSON! 📄'));
      expect(json['references'], equals(['JSON Ref 1', 'JSON Ref 2']));
      expect(json['content'], equals('This will be converted to JSON.'));
      expect(json['status'], equals('translated'));
      expect(json['updated_at'], equals('2025-07-21T12:00:00.000'));
      expect(json['author'], equals('David Chang'));
    });

    test('should handle null optional fields in JSON output', () {
      final audioContent = AudioContent(
        id: '2025-07-21-null-test',
        title: 'Null Fields Test',
        category: 'daily-news',
        language: 'en-US',
        date: '2025-07-21',
        references: ['Solo Reference'],
        content: 'Content with null fields.',
        status: 'draft',
        updatedAt: DateTime(2025, 7, 21),
        author: 'David Chang',
      );

      final json = audioContent.toJson();

      expect(json['audio_file'], isNull);
      expect(json['social_hook'], isNull);
      expect(json['references'], equals(['Solo Reference']));
    });
  });

  group('AudioContent data integrity', () {
    test('should maintain data consistency through JSON round trip', () {
      final original = AudioContent(
        id: '2025-07-21-round-trip',
        title: 'Round Trip Test',
        category: 'ethereum',
        language: 'ja-JP',
        date: '2025-07-21',
        audioFile: 'audio/roundtrip.wav',
        socialHook: 'Round trip complete! 🔄',
        references: ['Round Ref A', 'Round Ref B'],
        content: 'Testing JSON round trip integrity.',
        status: 'published',
        updatedAt: DateTime(2025, 7, 21, 8, 45),
        author: 'David Chang',
      );

      final json = original.toJson();
      final restored = AudioContent.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.title, equals(original.title));
      expect(restored.category, equals(original.category));
      expect(restored.language, equals(original.language));
      expect(restored.date, equals(original.date));
      expect(restored.audioFile, equals(original.audioFile));
      expect(restored.socialHook, equals(original.socialHook));
      expect(restored.references, equals(original.references));
      expect(restored.content, equals(original.content));
      expect(restored.status, equals(original.status));
      expect(restored.updatedAt, equals(original.updatedAt));
      expect(restored.author, equals(original.author));
    });
  });

  group('AudioContent edge cases', () {
    test('should handle special characters in content', () {
      final audioContent = AudioContent(
        id: '2025-07-21-special-chars',
        title: 'Special Characters: 特殊文字 & Émojis 🎯',
        category: 'daily-news',
        language: 'zh-TW',
        date: '2025-07-21',
        references: ['Référence spéciâle', '特殊参考'],
        content: 'Content with 特殊字符, émojis 🚀, and symbols: @#\$%^&*()',
        status: 'draft',
        updatedAt: DateTime(2025, 7, 21),
        author: 'David Chang',
      );

      expect(audioContent.title, contains('特殊文字'));
      expect(audioContent.title, contains('🎯'));
      expect(audioContent.content, contains('🚀'));
      expect(audioContent.references.first, equals('Référence spéciâle'));
    });

    test('should handle very long content strings', () {
      final longContent = 'Very long content ' * 1000;
      final audioContent = AudioContent(
        id: '2025-07-21-long-content',
        title: 'Long Content Test',
        category: 'macro',
        language: 'en-US',
        date: '2025-07-21',
        references: [],
        content: longContent,
        status: 'draft',
        updatedAt: DateTime(2025, 7, 21),
        author: 'David Chang',
      );

      expect(audioContent.content.length, greaterThan(15000));
      expect(audioContent.content, startsWith('Very long content'));
    });

    test('should handle empty reference list', () {
      final audioContent = AudioContent(
        id: '2025-07-21-no-refs',
        title: 'No References',
        category: 'startup',
        language: 'ja-JP',
        date: '2025-07-21',
        references: [],
        content: 'Content without references.',
        status: 'reviewed',
        updatedAt: DateTime(2025, 7, 21),
        author: 'David Chang',
      );

      expect(audioContent.references, isEmpty);
      expect(audioContent.references, isA<List<String>>());
    });
  });
}
