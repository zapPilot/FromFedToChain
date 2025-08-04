import 'package:flutter_test/flutter_test.dart';
import 'package:from_fed_to_chain_app/models/audio_content.dart';
import '../test_utils.dart';

void main() {
  group('AudioContent', () {
    group('Constructor', () {
      test('creates AudioContent with required fields', () {
        final content = TestUtils.createSampleAudioContent();

        expect(content.id, '2025-01-15-bitcoin-analysis');
        expect(content.title, 'Bitcoin Analysis');
        expect(content.language, 'en-US');
        expect(content.category, 'daily-news');
        expect(content.status, 'published');
        expect(content.date, DateTime.parse('2025-01-15'));
        expect(content.updatedAt, DateTime.parse('2025-01-15T10:00:00Z'));
      });

      test('handles optional fields correctly', () {
        final content = AudioContent(
          id: 'test-id',
          title: 'Test Title',
          language: 'en-US',
          category: 'daily-news',
          date: DateTime.now(),
          status: 'draft',
          updatedAt: DateTime.now(),
        );

        expect(content.description, isNull);
        expect(content.references, isEmpty);
        expect(content.socialHook, isNull);
        expect(content.duration, isNull);
      });
    });

    group('fromJson', () {
      test('creates AudioContent from valid JSON', () {
        final json = TestUtils.createAudioContentJson();
        final content = AudioContent.fromJson(json);

        expect(content.id, '2025-01-15-bitcoin-analysis');
        expect(content.title, 'Bitcoin Analysis');
        expect(content.language, 'en-US');
        expect(content.category, 'daily-news');
        expect(content.date, DateTime.parse('2025-01-15'));
        expect(content.status, 'published');
        expect(content.description, 'Sample content description');
        expect(content.references, ['Source 1', 'Source 2']);
        expect(content.socialHook, '🚀 Bitcoin breaking news!');
        expect(content.duration, const Duration(minutes: 5));
        expect(content.updatedAt, DateTime.parse('2025-01-15T10:00:00Z'));
      });

      test('handles missing optional fields in JSON', () {
        final json = {
          'id': 'test-id',
          'title': 'Test Title',
          'language': 'en-US',
          'category': 'daily-news',
          'date': '2025-01-15',
          'status': 'draft',
          'updated_at': '2025-01-15T10:00:00Z',
        };

        final content = AudioContent.fromJson(json);

        expect(content.description, isNull);
        expect(content.references, isEmpty);
        expect(content.socialHook, isNull);
        expect(content.duration, isNull);
      });

      test('handles null references array', () {
        final json = TestUtils.createAudioContentJson();
        json['references'] = null;

        final content = AudioContent.fromJson(json);
        expect(content.references, isEmpty);
      });

      test('converts reference items to strings', () {
        final json = TestUtils.createAudioContentJson();
        json['references'] = [1, 2, 'string', true];

        final content = AudioContent.fromJson(json);
        expect(content.references, ['1', '2', 'string', 'true']);
      });
    });

    group('toJson', () {
      test('converts AudioContent to JSON correctly', () {
        final content = TestUtils.createSampleAudioContent();
        final json = content.toJson();

        expect(json['id'], '2025-01-15-bitcoin-analysis');
        expect(json['title'], 'Bitcoin Analysis');
        expect(json['language'], 'en-US');
        expect(json['category'], 'daily-news');
        expect(json['date'], '2025-01-15T00:00:00.000');
        expect(json['status'], 'published');
        expect(json['content'], 'Sample content description');
        expect(json['references'], ['Source 1', 'Source 2']);
        expect(json['social_hook'], '🚀 Bitcoin breaking news!');
        expect(json['duration'], 300);
        expect(json['updated_at'], '2025-01-15T10:00:00.000Z');
      });

      test('handles null optional fields in JSON output', () {
        final content = AudioContent(
          id: 'test-id',
          title: 'Test Title',
          language: 'en-US',
          category: 'daily-news',
          date: DateTime.parse('2025-01-15'),
          status: 'draft',
          updatedAt: DateTime.parse('2025-01-15T10:00:00Z'),
        );

        final json = content.toJson();

        expect(json['content'], isNull);
        expect(json['social_hook'], isNull);
        expect(json['duration'], isNull);
        expect(json['references'], isEmpty);
      });
    });

    group('copyWith', () {
      test('creates copy with updated fields', () {
        final original = TestUtils.createSampleAudioContent();
        final copy = original.copyWith(
          title: 'Updated Title',
          status: 'draft',
        );

        expect(copy.title, 'Updated Title');
        expect(copy.status, 'draft');
        expect(copy.id, original.id); // Unchanged
        expect(copy.language, original.language); // Unchanged
      });

      test('creates exact copy when no parameters provided', () {
        final original = TestUtils.createSampleAudioContent();
        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.title, original.title);
        expect(copy.language, original.language);
        expect(copy.category, original.category);
        expect(copy.status, original.status);
      });
    });

    group('Display Properties', () {
      test('displayTitle returns title when not empty', () {
        final content = TestUtils.createSampleAudioContent(title: 'Test Title');
        expect(content.displayTitle, 'Test Title');
      });

      test('displayTitle returns formatted ID when title is empty', () {
        final content = TestUtils.createSampleAudioContent(title: '');
        expect(content.displayTitle, '2025 01 15 BITCOIN ANALYSIS');
      });

      test('displayTitle returns formatted ID when title is whitespace', () {
        final content = TestUtils.createSampleAudioContent(title: '   ');
        expect(content.displayTitle, '2025 01 15 BITCOIN ANALYSIS');
      });

      test('formattedDate returns correctly formatted date', () {
        final content = TestUtils.createSampleAudioContent();
        expect(content.formattedDate, '2025-01-15');
      });

      test('formattedDate handles different months and days', () {
        final content = AudioContent(
          id: 'test',
          title: 'Test',
          language: 'en-US',
          category: 'daily-news',
          date: DateTime(2025, 7, 5),
          status: 'published',
          updatedAt: DateTime.now(),
        );
        expect(content.formattedDate, '2025-07-05');
      });
    });

    group('Status Checks', () {
      test('hasAudio returns true for published status', () {
        final content = TestUtils.createSampleAudioContent(status: 'published');
        expect(content.hasAudio, isTrue);
      });

      test('hasAudio returns true for reviewed status', () {
        final content = TestUtils.createSampleAudioContent(status: 'reviewed');
        expect(content.hasAudio, isTrue);
      });

      test('hasAudio returns false for draft status', () {
        final content = TestUtils.createSampleAudioContent(status: 'draft');
        expect(content.hasAudio, isFalse);
      });

      test('hasAudio returns false for unknown status', () {
        final content = TestUtils.createSampleAudioContent(status: 'unknown');
        expect(content.hasAudio, isFalse);
      });
    });

    group('Category Emojis', () {
      test('returns correct emoji for each category', () {
        for (final entry in TestUtils.categoryEmojis.entries) {
          final content =
              TestUtils.createSampleAudioContent(category: entry.key);
          expect(content.categoryEmoji, entry.value,
              reason: 'Category: ${entry.key}');
        }
      });

      test('returns default emoji for unknown category', () {
        final content = TestUtils.createSampleAudioContent(category: 'unknown');
        expect(content.categoryEmoji, '🎧');
      });
    });

    group('Language Emojis', () {
      test('returns correct flag for each language', () {
        for (final entry in TestUtils.languageEmojis.entries) {
          final content =
              TestUtils.createSampleAudioContent(language: entry.key);
          expect(content.languageFlag, entry.value,
              reason: 'Language: ${entry.key}');
        }
      });

      test('returns default flag for unknown language', () {
        final content = TestUtils.createSampleAudioContent(language: 'unknown');
        expect(content.languageFlag, '🌐');
      });
    });

    group('Equality', () {
      test('equal objects have same hash code', () {
        final content1 = TestUtils.createSampleAudioContent();
        final content2 = TestUtils.createSampleAudioContent();

        expect(content1, equals(content2));
        expect(content1.hashCode, equals(content2.hashCode));
      });

      test('different objects are not equal', () {
        final content1 = TestUtils.createSampleAudioContent();
        final content2 =
            TestUtils.createSampleAudioContent(title: 'Different Title');

        expect(content1, isNot(equals(content2)));
      });

      test('same object is equal to itself', () {
        final content = TestUtils.createSampleAudioContent();
        expect(content, equals(content));
      });
    });

    group('toString', () {
      test('returns formatted string representation', () {
        final content = TestUtils.createSampleAudioContent();
        final string = content.toString();

        expect(string, contains('AudioContent'));
        expect(string, contains('2025-01-15-bitcoin-analysis'));
        expect(string, contains('Bitcoin Analysis'));
        expect(string, contains('en-US'));
        expect(string, contains('daily-news'));
      });
    });

    group('Edge Cases', () {
      test('handles empty references list', () {
        final content = TestUtils.createSampleAudioContent(references: []);
        expect(content.references, isEmpty);

        final json = content.toJson();
        expect(json['references'], isEmpty);
      });

      test('handles very long title', () {
        final longTitle = 'A' * 1000;
        final content = TestUtils.createSampleAudioContent(title: longTitle);
        expect(content.title, longTitle);
        expect(content.displayTitle, longTitle);
      });

      test('handles special characters in fields', () {
        final content = TestUtils.createSampleAudioContent(
          title: '🚀 Bitcoin & Ethereum: "The Future" (2025)',
          description: 'Content with special chars: <>&"\'',
        );

        expect(content.title, '🚀 Bitcoin & Ethereum: "The Future" (2025)');
        expect(content.description, 'Content with special chars: <>&"\'');

        // Should survive JSON round-trip
        final json = content.toJson();
        final restored = AudioContent.fromJson(json);
        expect(restored.title, content.title);
        expect(restored.description, content.description);
      });
    });
  });
}
