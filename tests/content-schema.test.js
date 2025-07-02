import { describe, it } from 'node:test';
import assert from 'node:assert';
import { ContentSchema } from '../src/ContentSchema.js';

describe('ContentSchema Tests', () => {
  
  describe('Content Creation', () => {
    it('should create valid content object with all required fields', () => {
      const content = ContentSchema.createContent(
        '2025-07-02-test-content',
        'daily-news',
        'zh-TW',
        'Test Title',
        'Test content body',
        ['Source 1', 'Source 2']
      );

      assert.strictEqual(content.id, '2025-07-02-test-content');
      assert.strictEqual(content.status, 'draft');
      assert.strictEqual(content.category, 'daily-news');
      assert.strictEqual(content.language, 'zh-TW');
      assert.strictEqual(content.title, 'Test Title');
      assert.strictEqual(content.content, 'Test content body');
      assert.deepStrictEqual(content.references, ['Source 1', 'Source 2']);
      assert.strictEqual(content.audio_file, null);
      assert.strictEqual(content.social_hook, null);
      assert(content.feedback);
      assert.strictEqual(content.feedback.content_review, null);
      assert.deepStrictEqual(content.feedback.ai_outputs, {});
      assert.deepStrictEqual(content.feedback.performance_metrics, {});
      assert(content.updated_at);
      assert(content.date);
    });

    it('should handle empty references array by default', () => {
      const content = ContentSchema.createContent(
        '2025-07-02-test',
        'ethereum',
        'en-US',
        'Test',
        'Content'
      );

      assert.deepStrictEqual(content.references, []);
    });

    it('should set current date automatically', () => {
      const content = ContentSchema.createContent(
        '2025-07-02-test',
        'macro',
        'ja-JP',
        'Test',
        'Content'
      );

      const today = new Date().toISOString().split('T')[0];
      assert.strictEqual(content.date, today);
    });

    it('should set updated_at timestamp', () => {
      const before = new Date().toISOString();
      const content = ContentSchema.createContent(
        '2025-07-02-test',
        'daily-news',
        'zh-TW',
        'Test',
        'Content'
      );
      const after = new Date().toISOString();

      assert(content.updated_at >= before);
      assert(content.updated_at <= after);
    });
  });

  describe('Schema Validation', () => {
    it('should validate correct content structure', () => {
      const validContent = ContentSchema.createContent(
        '2025-07-02-valid',
        'daily-news',
        'zh-TW',
        'Valid Title',
        'Valid content body'
      );

      assert.strictEqual(ContentSchema.validate(validContent), true);
    });

    it('should throw error for missing required fields', () => {
      const tests = [
        { field: 'id', value: undefined },
        { field: 'status', value: undefined },
        { field: 'category', value: undefined },
        { field: 'date', value: undefined },
        { field: 'language', value: undefined },
        { field: 'title', value: undefined },
        { field: 'content', value: undefined },
        { field: 'references', value: undefined },
        { field: 'feedback', value: undefined },
        { field: 'updated_at', value: undefined }
      ];

      tests.forEach(test => {
        const content = ContentSchema.createContent(
          '2025-07-02-test',
          'daily-news',
          'zh-TW',
          'Title',
          'Content'
        );
        delete content[test.field];

        assert.throws(
          () => ContentSchema.validate(content),
          {
            name: 'Error',
            message: `Missing required field: ${test.field}`
          },
          `Should throw error for missing ${test.field}`
        );
      });
    });

    it('should throw error for invalid category', () => {
      const content = ContentSchema.createContent(
        '2025-07-02-test',
        'invalid-category',
        'zh-TW',
        'Title',
        'Content'
      );

      assert.throws(
        () => ContentSchema.validate(content),
        {
          name: 'Error',
          message: 'Invalid category: invalid-category'
        }
      );
    });

    it('should throw error for invalid status', () => {
      const content = ContentSchema.createContent(
        '2025-07-02-test',
        'daily-news',
        'zh-TW',
        'Title',
        'Content'
      );
      content.status = 'invalid-status';

      assert.throws(
        () => ContentSchema.validate(content),
        {
          name: 'Error',
          message: 'Invalid status: invalid-status'
        }
      );
    });

    it('should throw error for invalid language', () => {
      const content = ContentSchema.createContent(
        '2025-07-02-test',
        'daily-news',
        'invalid-lang',
        'Title',
        'Content'
      );

      assert.throws(
        () => ContentSchema.validate(content),
        {
          name: 'Error',
          message: 'Invalid language: invalid-lang'
        }
      );
    });

    it('should throw error for empty title', () => {
      const content = ContentSchema.createContent(
        '2025-07-02-test',
        'daily-news',
        'zh-TW',
        '',
        'Content'
      );

      assert.throws(
        () => ContentSchema.validate(content),
        {
          name: 'Error',
          message: 'Title and content are required'
        }
      );
    });

    it('should throw error for empty content', () => {
      const content = ContentSchema.createContent(
        '2025-07-02-test',
        'daily-news',
        'zh-TW',
        'Title',
        ''
      );

      assert.throws(
        () => ContentSchema.validate(content),
        {
          name: 'Error',
          message: 'Title and content are required'
        }
      );
    });

    it('should accept all valid categories', () => {
      const categories = ContentSchema.getCategories();
      
      categories.forEach(category => {
        const content = ContentSchema.createContent(
          '2025-07-02-test',
          category,
          'zh-TW',
          'Title',
          'Content'
        );

        assert.doesNotThrow(() => ContentSchema.validate(content));
      });
    });

    it('should accept all valid statuses', () => {
      const statuses = ContentSchema.getStatuses();
      
      statuses.forEach(status => {
        const content = ContentSchema.createContent(
          '2025-07-02-test',
          'daily-news',
          'zh-TW',
          'Title',
          'Content'
        );
        content.status = status;

        assert.doesNotThrow(() => ContentSchema.validate(content));
      });
    });

    it('should accept all valid languages', () => {
      const languages = ContentSchema.getAllLanguages();
      
      languages.forEach(language => {
        const content = ContentSchema.createContent(
          '2025-07-02-test',
          'daily-news',
          language,
          'Title',
          'Content'
        );

        assert.doesNotThrow(() => ContentSchema.validate(content));
      });
    });
  });

  describe('Schema Constants', () => {
    it('should return supported languages', () => {
      const languages = ContentSchema.getSupportedLanguages();
      
      assert(Array.isArray(languages));
      assert(languages.includes('en-US'));
      assert(languages.includes('ja-JP'));
      assert.strictEqual(languages.length, 2);
    });

    it('should return all languages including source', () => {
      const allLanguages = ContentSchema.getAllLanguages();
      
      assert(Array.isArray(allLanguages));
      assert(allLanguages.includes('zh-TW'));
      assert(allLanguages.includes('en-US'));
      assert(allLanguages.includes('ja-JP'));
      assert.strictEqual(allLanguages.length, 3);
    });

    it('should return valid categories', () => {
      const categories = ContentSchema.getCategories();
      
      assert(Array.isArray(categories));
      assert(categories.includes('daily-news'));
      assert(categories.includes('ethereum'));
      assert(categories.includes('macro'));
      assert(categories.includes('startup'));
      assert(categories.includes('ai'));
    });

    it('should return valid statuses in correct order', () => {
      const statuses = ContentSchema.getStatuses();
      
      assert(Array.isArray(statuses));
      assert.deepStrictEqual(statuses, [
        'draft', 'reviewed', 'translated', 'audio', 'social', 'published'
      ]);
    });

    it('should return supported social platforms', () => {
      const platforms = ContentSchema.getSocialPlatforms();
      
      assert(Array.isArray(platforms));
      assert(platforms.includes('twitter'));
      assert(platforms.includes('threads'));
      assert(platforms.includes('farcaster'));
      assert(platforms.includes('debank'));
    });
  });

  describe('Example Content', () => {
    it('should provide valid example content', () => {
      const example = ContentSchema.getExample();
      
      assert.strictEqual(example.id, '2025-06-30-example-content');
      assert.strictEqual(example.category, 'daily-news');
      assert.strictEqual(example.language, 'zh-TW');
      assert.strictEqual(example.title, 'Example Bitcoin Analysis');
      assert(example.content.includes('Bitcoin'));
      assert.deepStrictEqual(example.references, ['Example Source 1', 'Example Source 2']);
      
      // Should pass validation
      assert.doesNotThrow(() => ContentSchema.validate(example));
    });
  });

  describe('Edge Cases and Error Handling', () => {
    it('should handle null and undefined values gracefully', () => {
      assert.throws(() => ContentSchema.validate(null));
      assert.throws(() => ContentSchema.validate(undefined));
      assert.throws(() => ContentSchema.validate({}));
    });

    it('should handle non-string title and content', () => {
      const content = ContentSchema.createContent(
        '2025-07-02-test',
        'daily-news',
        'zh-TW',
        123, // number instead of string
        ['array', 'instead', 'of', 'string']
      );

      // Should still validate since we're checking truthiness, not type
      assert.doesNotThrow(() => ContentSchema.validate(content));
    });

    it('should handle extra unexpected fields', () => {
      const content = ContentSchema.createContent(
        '2025-07-02-test',
        'daily-news',
        'zh-TW',
        'Title',
        'Content'
      );
      content.extraField = 'unexpected';
      content.anotherField = 123;

      // Should still validate - schema doesn't restrict extra fields
      assert.doesNotThrow(() => ContentSchema.validate(content));
    });

    it('should handle malformed feedback structure', () => {
      const content = ContentSchema.createContent(
        '2025-07-02-test',
        'daily-news',
        'zh-TW',
        'Title',
        'Content'
      );
      content.feedback = null;

      assert.throws(
        () => ContentSchema.validate(content),
        {
          name: 'Error',
          message: 'Missing required field: feedback'
        }
      );
    });

    it('should handle invalid date format', () => {
      const content = ContentSchema.createContent(
        '2025-07-02-test',
        'daily-news',
        'zh-TW',
        'Title',
        'Content'
      );
      content.date = 'invalid-date';

      // Schema doesn't validate date format, only presence
      assert.doesNotThrow(() => ContentSchema.validate(content));
    });
  });
});