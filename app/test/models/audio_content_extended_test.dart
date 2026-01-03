import 'package:flutter_test/flutter_test.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_content.dart';

void main() {
  group('AudioContent Extended Tests', () {
    late AudioContent testContent;

    setUp(() {
      testContent = AudioContent(
        id: 'test-episode-2025',
        title: 'Test Episode Title',
        language: 'en-US',
        category: 'daily-news',
        date: DateTime.utc(2025, 6, 15),
        status: 'published',
        description: 'Test description',
        references: const ['Ref 1', 'Ref 2'],
        socialHook: 'Test hook',
        duration: const Duration(minutes: 5),
        updatedAt: DateTime.utc(2025, 6, 15, 12, 0, 0),
      );
    });

    group('displayTitle', () {
      test('should return title when title is not empty', () {
        expect(testContent.displayTitle, equals('Test Episode Title'));
      });

      test('should return formatted ID when title is empty', () {
        final content = testContent.copyWith(title: '');
        expect(content.displayTitle, equals('TEST EPISODE 2025'));
      });

      test('should return formatted ID when title is whitespace only', () {
        final content = testContent.copyWith(title: '   ');
        expect(content.displayTitle, equals('TEST EPISODE 2025'));
      });
    });

    group('formattedDate', () {
      test('should format date correctly with padding', () {
        expect(testContent.formattedDate, equals('2025-06-15'));
      });

      test('should pad single digit month and day', () {
        final content = testContent.copyWith(date: DateTime.utc(2025, 1, 5));
        expect(content.formattedDate, equals('2025-01-05'));
      });

      test('should handle end of year dates', () {
        final content = testContent.copyWith(date: DateTime.utc(2025, 12, 31));
        expect(content.formattedDate, equals('2025-12-31'));
      });
    });

    group('hasAudio', () {
      test('should return false for draft status', () {
        final content = testContent.copyWith(status: 'draft');
        expect(content.hasAudio, isFalse);
      });

      test('should return false for reviewed status', () {
        final content = testContent.copyWith(status: 'reviewed');
        expect(content.hasAudio, isFalse);
      });

      test('should return false for translated status', () {
        final content = testContent.copyWith(status: 'translated');
        expect(content.hasAudio, isFalse);
      });

      test('should return true for wav status', () {
        final content = testContent.copyWith(status: 'wav');
        expect(content.hasAudio, isTrue);
      });

      test('should return true for m3u8 status', () {
        final content = testContent.copyWith(status: 'm3u8');
        expect(content.hasAudio, isTrue);
      });

      test('should return true for cloudflare status', () {
        final content = testContent.copyWith(status: 'cloudflare');
        expect(content.hasAudio, isTrue);
      });

      test('should return true for content status', () {
        final content = testContent.copyWith(status: 'content');
        expect(content.hasAudio, isTrue);
      });

      test('should return true for social status', () {
        final content = testContent.copyWith(status: 'social');
        expect(content.hasAudio, isTrue);
      });

      test('should return false for unknown status', () {
        final content = testContent.copyWith(status: 'unknown');
        expect(content.hasAudio, isFalse);
      });
    });

    group('categoryEmoji', () {
      test('should return 📰 for daily-news', () {
        final content = testContent.copyWith(category: 'daily-news');
        expect(content.categoryEmoji, equals('📰'));
      });

      test('should return ⚡ for ethereum', () {
        final content = testContent.copyWith(category: 'ethereum');
        expect(content.categoryEmoji, equals('⚡'));
      });

      test('should return 📊 for macro', () {
        final content = testContent.copyWith(category: 'macro');
        expect(content.categoryEmoji, equals('📊'));
      });

      test('should return 🚀 for startup', () {
        final content = testContent.copyWith(category: 'startup');
        expect(content.categoryEmoji, equals('🚀'));
      });

      test('should return 🤖 for ai', () {
        final content = testContent.copyWith(category: 'ai');
        expect(content.categoryEmoji, equals('🤖'));
      });

      test('should return 💎 for defi', () {
        final content = testContent.copyWith(category: 'defi');
        expect(content.categoryEmoji, equals('💎'));
      });

      test('should return 🎧 for unknown category', () {
        final content = testContent.copyWith(category: 'unknown-category');
        expect(content.categoryEmoji, equals('🎧'));
      });
    });

    group('languageFlag', () {
      test('should return 🇹🇼 for zh-TW', () {
        final content = testContent.copyWith(language: 'zh-TW');
        expect(content.languageFlag, equals('🇹🇼'));
      });

      test('should return 🇺🇸 for en-US', () {
        final content = testContent.copyWith(language: 'en-US');
        expect(content.languageFlag, equals('🇺🇸'));
      });

      test('should return 🇯🇵 for ja-JP', () {
        final content = testContent.copyWith(language: 'ja-JP');
        expect(content.languageFlag, equals('🇯🇵'));
      });

      test('should return 🌐 for unknown language', () {
        final content = testContent.copyWith(language: 'unknown-lang');
        expect(content.languageFlag, equals('🌐'));
      });
    });

    group('copyWith', () {
      test('should create a copy with updated id', () {
        final copy = testContent.copyWith(id: 'new-id');
        expect(copy.id, equals('new-id'));
        expect(copy.title, equals(testContent.title));
      });

      test('should create a copy with updated title', () {
        final copy = testContent.copyWith(title: 'New Title');
        expect(copy.title, equals('New Title'));
        expect(copy.id, equals(testContent.id));
      });

      test('should create a copy with updated language', () {
        final copy = testContent.copyWith(language: 'ja-JP');
        expect(copy.language, equals('ja-JP'));
      });

      test('should create a copy with updated category', () {
        final copy = testContent.copyWith(category: 'defi');
        expect(copy.category, equals('defi'));
      });

      test('should create a copy with updated date', () {
        final newDate = DateTime.utc(2026, 1, 1);
        final copy = testContent.copyWith(date: newDate);
        expect(copy.date, equals(newDate));
      });

      test('should create a copy with updated status', () {
        final copy = testContent.copyWith(status: 'm3u8');
        expect(copy.status, equals('m3u8'));
      });

      test('should create a copy with updated description', () {
        final copy = testContent.copyWith(description: 'New description');
        expect(copy.description, equals('New description'));
      });

      test('should create a copy with updated references', () {
        final copy = testContent.copyWith(references: ['New Ref']);
        expect(copy.references, equals(['New Ref']));
      });

      test('should create a copy with updated socialHook', () {
        final copy = testContent.copyWith(socialHook: 'New hook');
        expect(copy.socialHook, equals('New hook'));
      });

      test('should create a copy with updated duration', () {
        final copy =
            testContent.copyWith(duration: const Duration(minutes: 10));
        expect(copy.duration, equals(const Duration(minutes: 10)));
      });

      test('should create a copy with updated updatedAt', () {
        final newUpdatedAt = DateTime.utc(2026, 1, 1, 12, 0, 0);
        final copy = testContent.copyWith(updatedAt: newUpdatedAt);
        expect(copy.updatedAt, equals(newUpdatedAt));
      });

      test('should preserve all values when no parameters passed', () {
        final copy = testContent.copyWith();
        expect(copy, equals(testContent));
      });
    });

    group('toString', () {
      test('should return formatted string representation', () {
        final str = testContent.toString();
        expect(str, contains('AudioContent'));
        expect(str, contains('test-episode-2025'));
        expect(str, contains('Test Episode Title'));
        expect(str, contains('en-US'));
        expect(str, contains('daily-news'));
      });
    });

    group('props (Equatable)', () {
      test('should correctly include all properties in equality check', () {
        final content1 = testContent;
        final content2 = testContent.copyWith();

        expect(content1.props.length, equals(11));
        expect(content1, equals(content2));
      });

      test('should detect differences in any property', () {
        expect(
            testContent.copyWith(id: 'different'), isNot(equals(testContent)));
        expect(testContent.copyWith(title: 'different'),
            isNot(equals(testContent)));
        expect(testContent.copyWith(language: 'different'),
            isNot(equals(testContent)));
        expect(testContent.copyWith(category: 'different'),
            isNot(equals(testContent)));
        expect(testContent.copyWith(status: 'different'),
            isNot(equals(testContent)));
        expect(testContent.copyWith(description: 'different'),
            isNot(equals(testContent)));
        expect(testContent.copyWith(socialHook: 'different'),
            isNot(equals(testContent)));
      });
    });
  });
}
