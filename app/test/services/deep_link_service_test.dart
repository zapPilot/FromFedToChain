import 'package:flutter_test/flutter_test.dart';

import 'package:from_fed_to_chain_app/core/navigation/deep_link_service.dart';

void main() {
  group('DeepLinkService Tests', () {
    setUp(() {
      // Reset service state before each test
      DeepLinkService.dispose();
    });

    tearDown(() {
      DeepLinkService.dispose();
    });

    group('Link Generation', () {
      test('should generate custom scheme link for simple content ID', () {
        final link = DeepLinkService.generateContentLink('test-episode');
        expect(link, 'fromfedtochain://audio/test-episode');
      });

      test('should generate custom scheme link with explicit language', () {
        final link = DeepLinkService.generateContentLink('test-episode',
            language: 'en-US');
        expect(link, 'fromfedtochain://audio/test-episode/en-US');
      });

      test('should generate universal link when requested', () {
        final link = DeepLinkService.generateContentLink('test-episode',
            useCustomScheme: false);
        expect(link, 'https://fromfedtochain.com/audio/test-episode');
      });

      test('should handle content ID with existing language suffix', () {
        final link = DeepLinkService.generateContentLink('test-episode-zh-TW');
        expect(link, 'fromfedtochain://audio/test-episode/zh-TW');
      });

      test('should extract existing language and ignore explicit parameter',
          () {
        final link = DeepLinkService.generateContentLink('test-episode-zh-TW',
            language: 'en-US');
        expect(link, 'fromfedtochain://audio/test-episode/zh-TW');
      });

      test('should handle multiple language patterns correctly', () {
        final linkZhTW = DeepLinkService.generateContentLink('episode-zh-TW');
        final linkEnUS = DeepLinkService.generateContentLink('episode-en-US');
        final linkJaJP = DeepLinkService.generateContentLink('episode-ja-JP');

        expect(linkZhTW, 'fromfedtochain://audio/episode/zh-TW');
        expect(linkEnUS, 'fromfedtochain://audio/episode/en-US');
        expect(linkJaJP, 'fromfedtochain://audio/episode/ja-JP');
      });

      test(
          'should handle content ID with no language when all supported languages checked',
          () {
        final link = DeepLinkService.generateContentLink('simple-episode');
        expect(link, 'fromfedtochain://audio/simple-episode');
      });

      test('should handle content ID ending with partial language match', () {
        final link =
            DeepLinkService.generateContentLink('episode-zh'); // not zh-TW
        expect(link, 'fromfedtochain://audio/episode-zh');
      });

      test('should handle universal links with language', () {
        final link = DeepLinkService.generateContentLink('test-episode',
            language: 'ja-JP', useCustomScheme: false);
        expect(link, 'https://fromfedtochain.com/audio/test-episode/ja-JP');
      });

      test('should handle universal links with existing language suffix', () {
        final link = DeepLinkService.generateContentLink('episode-en-US',
            useCustomScheme: false);
        expect(link, 'https://fromfedtochain.com/audio/episode/en-US');
      });
    });

    group('Resource Management', () {
      test('should dispose resources properly', () {
        // Dispose should not throw when called multiple times
        DeepLinkService.dispose();
        DeepLinkService.dispose();
        DeepLinkService.dispose();
      });

      test('dispose should be idempotent', () {
        DeepLinkService.dispose();
        expect(() => DeepLinkService.dispose(), returnsNormally);
      });
    });

    group('Edge Cases', () {
      test('should handle null and empty content IDs in link generation', () {
        final linkEmpty = DeepLinkService.generateContentLink('');
        final linkWithSpace = DeepLinkService.generateContentLink(' ');

        expect(linkEmpty, 'fromfedtochain://audio/');
        expect(linkWithSpace, 'fromfedtochain://audio/ ');
      });

      test('should handle special characters in content ID', () {
        final linkSpecial =
            DeepLinkService.generateContentLink('test-episode@123');
        expect(linkSpecial, 'fromfedtochain://audio/test-episode@123');
      });

      test('should handle very long content IDs', () {
        const longId =
            'very-long-episode-id-with-many-characters-and-dashes-zh-TW';
        final link = DeepLinkService.generateContentLink(longId);
        expect(link,
            'fromfedtochain://audio/very-long-episode-id-with-many-characters-and-dashes/zh-TW');
      });

      test('should handle case sensitivity in language detection', () {
        final linkLowerCase =
            DeepLinkService.generateContentLink('episode-zh-tw');
        final linkMixedCase =
            DeepLinkService.generateContentLink('episode-EN-us');

        // Should not match case-sensitive language patterns
        expect(linkLowerCase, 'fromfedtochain://audio/episode-zh-tw');
        expect(linkMixedCase, 'fromfedtochain://audio/episode-EN-us');
      });

      test('should handle multiple language-like patterns in content ID', () {
        final link =
            DeepLinkService.generateContentLink('test-zh-TW-episode-en-US');
        // Should match the last valid language pattern
        expect(link, 'fromfedtochain://audio/test-zh-TW-episode/en-US');
      });
    });

    group('Link Generation - Additional Cases', () {
      test('should generate link with all supported languages', () {
        final linkZhTW =
            DeepLinkService.generateContentLink('ep', language: 'zh-TW');
        final linkEnUS =
            DeepLinkService.generateContentLink('ep', language: 'en-US');
        final linkJaJP =
            DeepLinkService.generateContentLink('ep', language: 'ja-JP');

        expect(linkZhTW, 'fromfedtochain://audio/ep/zh-TW');
        expect(linkEnUS, 'fromfedtochain://audio/ep/en-US');
        expect(linkJaJP, 'fromfedtochain://audio/ep/ja-JP');
      });

      test('should handle date-like content IDs', () {
        final link =
            DeepLinkService.generateContentLink('2025-01-15-bitcoin-news');
        expect(link, 'fromfedtochain://audio/2025-01-15-bitcoin-news');
      });

      test('should handle content ID with language in middle', () {
        final link =
            DeepLinkService.generateContentLink('2025-01-15-en-US-bitcoin');
        expect(link, contains('2025-01-15-en-US-bitcoin'));
      });

      test('universal link with existing language suffix', () {
        final link = DeepLinkService.generateContentLink('ep-ja-JP',
            useCustomScheme: false);
        expect(link, 'https://fromfedtochain.com/audio/ep/ja-JP');
      });

      test('should not extract language from partial match at start', () {
        final link =
            DeepLinkService.generateContentLink('en-US-prefix-episode');
        // en-US is at start, not end - should not be extracted
        expect(link, 'fromfedtochain://audio/en-US-prefix-episode');
      });

      test('universal link without language', () {
        final link = DeepLinkService.generateContentLink('simple-ep',
            useCustomScheme: false, language: null);
        expect(link, 'https://fromfedtochain.com/audio/simple-ep');
      });
    });
  });
}
