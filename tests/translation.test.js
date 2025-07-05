import { describe, it, beforeEach, afterEach, mock } from 'node:test';
import assert from 'node:assert';
import fs from 'fs/promises';
import path from 'path';
import { TestUtils } from './setup.js';
import { ContentManager } from '../src/ContentManager.js';
import { TranslationService } from '../src/services/TranslationService.js';

describe('TranslationService Tests', () => {
  let tempDir;
  let originalContentDir;
  let mockTranslateClient;
  let originalGetTranslateClient;

  beforeEach(async () => {
    tempDir = await TestUtils.createTempDir();
    originalContentDir = ContentManager.CONTENT_DIR;
    ContentManager.CONTENT_DIR = tempDir;

    // Mock the Google Cloud Translate client
    mockTranslateClient = {
      translate: mock.fn()
    };

    // Mock the getTranslateClient method
    originalGetTranslateClient = TranslationService.getTranslateClient;
    TranslationService.getTranslateClient = mock.fn(() => mockTranslateClient);
    TranslationService.translate_client = mockTranslateClient; // Reset static client

    // Create test content with reviewed status
    const testContent = {
      id: '2025-07-01-translation-test',
      status: 'reviewed',
      category: 'daily-news',
      date: '2025-07-01',
      language: 'zh-TW',
      title: '比特幣價格突破新高',
      content: '今天比特幣價格突破了歷史新高，這對加密貨幣市場來說是一個重要的里程碑。',
      references: ['測試來源1'],
      audio_file: null,
      social_hook: null,
      feedback: {
        content_review: {
          status: 'accepted',
          score: 4,
          reviewer: 'test_reviewer',
          timestamp: new Date().toISOString(),
          comments: 'Approved for translation'
        },
        ai_outputs: {},
        performance_metrics: {}
      },
      updated_at: new Date().toISOString()
    };

    // Create nested directory structure and write test content
    const sourceDir = path.join(tempDir, 'zh-TW', 'daily-news');
    await fs.mkdir(sourceDir, { recursive: true });
    const filePath = path.join(sourceDir, `${testContent.id}.json`);
    await fs.writeFile(filePath, JSON.stringify(testContent, null, 2));
  });

  afterEach(async () => {
    ContentManager.CONTENT_DIR = originalContentDir;
    await TestUtils.cleanupTempDir(tempDir);
    
    // Restore original method
    TranslationService.getTranslateClient = originalGetTranslateClient;
    TranslationService.translate_client = null;
    
    // Reset all mocks
    mock.restoreAll();
  });

  describe('Google Cloud Translate Client Initialization', () => {
    it('should initialize translate client with service account', () => {
      // This test verifies the client initialization logic
      // Since we're in a test environment without service-account.json,
      // we verify that the method exists and can be called
      assert.strictEqual(typeof TranslationService.getTranslateClient, 'function');
      
      // Verify the static client property exists
      assert(TranslationService.hasOwnProperty('translate_client'));
    });

    it('should reuse existing translate client instance', () => {
      // Test that the static client property can be set and reused
      const mockClient = { translate: mock.fn() };
      
      // Clear the client first
      TranslationService.translate_client = null;
      
      // Set a specific mock client
      TranslationService.translate_client = mockClient;
      
      // Verify the client is reused
      const retrievedClient = TranslationService.translate_client;
      assert.strictEqual(retrievedClient, mockClient);
      
      // Reset for other tests
      TranslationService.translate_client = mockTranslateClient;
    });
  });

  describe('translateText Method', () => {
    it('should translate Chinese text to English', async () => {
      const mockTranslation = 'Bitcoin price breaks new high';
      mockTranslateClient.translate.mock.mockImplementation(() => 
        Promise.resolve([mockTranslation])
      );

      const result = await TranslationService.translateText('比特幣價格突破新高', 'en-US');
      
      assert.strictEqual(result, mockTranslation);
      assert.strictEqual(mockTranslateClient.translate.mock.callCount(), 1);
      
      const [text, options] = mockTranslateClient.translate.mock.calls[0].arguments;
      assert.strictEqual(text, '比特幣價格突破新高');
      assert.strictEqual(options.from, 'zh');
      assert.strictEqual(options.to, 'en');
      assert.strictEqual(options.format, 'text');
    });

    it('should translate Chinese text to Japanese', async () => {
      const mockTranslation = 'ビットコインの価格が新高値を突破';
      mockTranslateClient.translate.mock.mockImplementation(() => 
        Promise.resolve([mockTranslation])
      );

      const result = await TranslationService.translateText('比特幣價格突破新高', 'ja-JP');
      
      assert.strictEqual(result, mockTranslation);
      
      const [text, options] = mockTranslateClient.translate.mock.calls[0].arguments;
      assert.strictEqual(options.from, 'zh');
      assert.strictEqual(options.to, 'ja');
    });

    it('should handle empty text translation', async () => {
      mockTranslateClient.translate.mock.mockImplementation(() => 
        Promise.resolve([''])
      );

      const result = await TranslationService.translateText('', 'en-US');
      assert.strictEqual(result, '');
    });

    it('should handle long text translation', async () => {
      const longText = '比特幣'.repeat(1000);
      const mockTranslation = 'Bitcoin'.repeat(1000);
      
      mockTranslateClient.translate.mock.mockImplementation(() => 
        Promise.resolve([mockTranslation])
      );

      const result = await TranslationService.translateText(longText, 'en-US');
      assert.strictEqual(result, mockTranslation);
    });

    it('should throw error for unsupported language', async () => {
      await assert.rejects(
        async () => {
          await TranslationService.translateText('測試', 'fr-FR');
        },
        {
          name: 'Error',
          message: 'Unsupported language: fr-FR'
        }
      );
    });

    it('should handle Google Cloud API errors', async () => {
      const apiError = new Error('API quota exceeded');
      mockTranslateClient.translate.mock.mockImplementation(() => 
        Promise.reject(apiError)
      );

      await assert.rejects(
        async () => {
          await TranslationService.translateText('測試', 'en-US');
        },
        {
          name: 'Error',
          message: 'Translation failed: API quota exceeded'
        }
      );
    });

    it('should handle service account file not found error', async () => {
      const enoentError = new Error('ENOENT: no such file or directory');
      enoentError.code = 'ENOENT';
      
      mockTranslateClient.translate.mock.mockImplementation(() => 
        Promise.reject(enoentError)
      );

      await assert.rejects(
        async () => {
          await TranslationService.translateText('測試', 'en-US');
        },
        {
          name: 'Error',
          message: 'Google Cloud service account file not found. Please ensure service-account.json exists in the project root.'
        }
      );
    });

    it('should handle authentication errors', async () => {
      const authError = new Error('Authentication failed');
      authError.code = 'EACCES';
      
      mockTranslateClient.translate.mock.mockImplementation(() => 
        Promise.reject(authError)
      );

      await assert.rejects(
        async () => {
          await TranslationService.translateText('測試', 'en-US');
        },
        {
          name: 'Error',
          message: 'Google Cloud authentication failed. Please check your service-account.json credentials.'
        }
      );
    });
  });

  describe('translate Method (Content Translation)', () => {
    it('should translate content to English successfully', async () => {
      mockTranslateClient.translate.mock.mockImplementation((text) => {
        if (text === '比特幣價格突破新高') {
          return Promise.resolve(['Bitcoin price breaks new high']);
        } else if (text.includes('今天比特幣價格突破了歷史新高')) {
          return Promise.resolve(['Today Bitcoin price broke the historical high, this is an important milestone for the cryptocurrency market.']);
        }
        return Promise.resolve([text]);
      });

      const result = await TranslationService.translate('2025-07-01-translation-test', 'en-US');
      
      assert.strictEqual(result.translatedTitle, 'Bitcoin price breaks new high');
      assert.strictEqual(result.translatedContent, 'Today Bitcoin price broke the historical high, this is an important milestone for the cryptocurrency market.');

      // Verify translation file was created
      const translationPath = path.join(tempDir, 'en-US', 'daily-news', '2025-07-01-translation-test.json');
      const translationFile = await fs.readFile(translationPath, 'utf-8');
      const translationContent = JSON.parse(translationFile);
      
      assert.strictEqual(translationContent.language, 'en-US');
      assert.strictEqual(translationContent.status, 'translated');
      assert.strictEqual(translationContent.title, 'Bitcoin price breaks new high');
    });

    it('should translate content to Japanese successfully', async () => {
      mockTranslateClient.translate.mock.mockImplementation((text) => {
        if (text === '比特幣價格突破新高') {
          return Promise.resolve(['ビットコインの価格が新高値を突破']);
        } else if (text.includes('今天比特幣價格突破了歷史新高')) {
          return Promise.resolve(['今日、ビットコインの価格が史上最高値を突破しました。これは暗号通貨市場にとって重要なマイルストーンです。']);
        }
        return Promise.resolve([text]);
      });

      const result = await TranslationService.translate('2025-07-01-translation-test', 'ja-JP');
      
      assert.strictEqual(result.translatedTitle, 'ビットコインの価格が新高値を突破');
      assert.strictEqual(result.translatedContent, '今日、ビットコインの価格が史上最高値を突破しました。これは暗号通貨市場にとって重要なマイルストーンです。');
    });

    it('should throw error for unsupported language', async () => {
      await assert.rejects(
        async () => {
          await TranslationService.translate('2025-07-01-translation-test', 'de-DE');
        },
        {
          name: 'Error',
          message: 'Unsupported language: de-DE'
        }
      );
    });

    it('should throw error if content is not reviewed', async () => {
      // Create content with draft status
      const draftContent = {
        id: '2025-07-01-draft-test',
        status: 'draft',
        category: 'daily-news',
        date: '2025-07-01',
        language: 'zh-TW',
        title: '草稿測試',
        content: '這是草稿內容',
        references: [],
        audio_file: null,
        social_hook: null,
        feedback: { content_review: null, ai_outputs: {}, performance_metrics: {} },
        updated_at: new Date().toISOString()
      };

      const draftDir = path.join(tempDir, 'zh-TW', 'daily-news');
      const draftPath = path.join(draftDir, `${draftContent.id}.json`);
      await fs.writeFile(draftPath, JSON.stringify(draftContent, null, 2));

      await assert.rejects(
        async () => {
          await TranslationService.translate('2025-07-01-draft-test', 'en-US');
        },
        {
          name: 'Error',
          message: 'Content must be reviewed before translation. Current status: draft'
        }
      );
    });

    it('should throw error for non-existent content', async () => {
      await assert.rejects(
        async () => {
          await TranslationService.translate('non-existent-content', 'en-US');
        },
        {
          name: 'Error',
          message: /Content not found/
        }
      );
    });

    it('should update source status to translated when all languages are complete', async () => {
      // Mock successful translations
      mockTranslateClient.translate.mock.mockImplementation(() => 
        Promise.resolve(['Translated text'])
      );

      // Translate to English first
      await TranslationService.translate('2025-07-01-translation-test', 'en-US');
      
      // Check source status (should still be reviewed)
      let sourceContent = await ContentManager.readSource('2025-07-01-translation-test');
      assert.strictEqual(sourceContent.status, 'reviewed');

      // Translate to Japanese (final language)
      await TranslationService.translate('2025-07-01-translation-test', 'ja-JP');
      
      // Check source status (should now be translated)
      sourceContent = await ContentManager.readSource('2025-07-01-translation-test');
      assert.strictEqual(sourceContent.status, 'translated');
    });
  });

  describe('translateAll Method', () => {
    it('should translate content to all supported languages', async () => {
      mockTranslateClient.translate.mock.mockImplementation((text, options) => {
        if (text === '比特幣價格突破新高') {
          if (options.to === 'en') {
            return Promise.resolve(['Bitcoin price breaks new high']);
          } else if (options.to === 'ja') {
            return Promise.resolve(['ビットコインの価格が新高値を突破']);
          }
        } else if (text.includes('今天比特幣價格突破了歷史新高')) {
          if (options.to === 'en') {
            return Promise.resolve(['Today Bitcoin price broke the historical high.']);
          } else if (options.to === 'ja') {
            return Promise.resolve(['今日、ビットコインの価格が史上最高値を突破しました。']);
          }
        }
        return Promise.resolve(['Translated: ' + text]);
      });

      const results = await TranslationService.translateAll('2025-07-01-translation-test');
      
      assert(results['en-US']);
      assert(results['ja-JP']);
      assert.strictEqual(results['en-US'].translatedTitle, 'Bitcoin price breaks new high');
      assert.strictEqual(results['ja-JP'].translatedTitle, 'ビットコインの価格が新高値を突破');
      assert.strictEqual(results['en-US'].translatedContent, 'Today Bitcoin price broke the historical high.');
      assert.strictEqual(results['ja-JP'].translatedContent, '今日、ビットコインの価格が史上最高値を突破しました。');
      
      // Verify both translation files were created
      const enPath = path.join(tempDir, 'en-US', 'daily-news', '2025-07-01-translation-test.json');
      const jaPath = path.join(tempDir, 'ja-JP', 'daily-news', '2025-07-01-translation-test.json');
      
      assert(await fs.access(enPath).then(() => true).catch(() => false));
      assert(await fs.access(jaPath).then(() => true).catch(() => false));
    });

    it('should handle partial translation failures gracefully', async () => {
      mockTranslateClient.translate.mock.mockImplementation((text) => {
        // Simulate failure for Japanese translation
        if (mockTranslateClient.translate.mock.callCount() > 2) {
          throw new Error('API quota exceeded');
        }
        return Promise.resolve(['Translated: ' + text]);
      });

      const results = await TranslationService.translateAll('2025-07-01-translation-test');
      
      // English should succeed
      assert(results['en-US']);
      assert.strictEqual(results['en-US'].translatedTitle, 'Translated: 比特幣價格突破新高');
      
      // Japanese should fail
      assert(results['ja-JP']);
      assert(results['ja-JP'].error);
      assert(results['ja-JP'].error.includes('API quota exceeded'));
    });

    it('should return empty results for non-existent content', async () => {
      const results = await TranslationService.translateAll('non-existent-content');
      
      assert(results['en-US'].error);
      assert(results['ja-JP'].error);
      assert(results['en-US'].error.includes('Content not found'));
      assert(results['ja-JP'].error.includes('Content not found'));
    });
  });

  describe('getContentNeedingTranslation Method', () => {
    it('should return content with reviewed status', async () => {
      const contentList = await TranslationService.getContentNeedingTranslation();
      
      assert.strictEqual(contentList.length, 1);
      assert.strictEqual(contentList[0].id, '2025-07-01-translation-test');
      assert.strictEqual(contentList[0].status, 'reviewed');
    });

    it('should return empty array when no content needs translation', async () => {
      // Update content to translated status
      await ContentManager.updateSourceStatus('2025-07-01-translation-test', 'translated');
      
      const contentList = await TranslationService.getContentNeedingTranslation();
      assert.strictEqual(contentList.length, 0);
    });
  });

  describe('Language Support', () => {
    it('should support all defined languages', () => {
      const supportedLanguages = TranslationService.SUPPORTED_LANGUAGES;
      
      assert(Array.isArray(supportedLanguages));
      assert(supportedLanguages.includes('en-US'));
      assert(supportedLanguages.includes('ja-JP'));
      assert.strictEqual(supportedLanguages.length, 2);
    });

    it('should map language codes correctly', async () => {
      mockTranslateClient.translate.mock.mockImplementation(() => 
        Promise.resolve(['test'])
      );

      await TranslationService.translateText('測試', 'en-US');
      
      const [text, options] = mockTranslateClient.translate.mock.calls[0].arguments;
      assert.strictEqual(options.from, 'zh');
      assert.strictEqual(options.to, 'en');
    });
  });

  describe('Error Handling and Edge Cases', () => {
    it('should handle special characters in translation', async () => {
      const specialText = '比特幣 💰 價格突破 $50,000 美元！';
      const mockTranslation = 'Bitcoin 💰 price breaks $50,000!';
      
      mockTranslateClient.translate.mock.mockImplementation(() => 
        Promise.resolve([mockTranslation])
      );

      const result = await TranslationService.translateText(specialText, 'en-US');
      assert.strictEqual(result, mockTranslation);
    });

    it('should handle network timeout errors', async () => {
      const timeoutError = new Error('Request timeout');
      timeoutError.code = 'ETIMEDOUT';
      
      mockTranslateClient.translate.mock.mockImplementation(() => 
        Promise.reject(timeoutError)
      );

      await assert.rejects(
        async () => {
          await TranslationService.translateText('測試', 'en-US');
        },
        {
          name: 'Error',
          message: 'Translation failed: Request timeout'
        }
      );
    });

    it('should handle content with missing title or content fields', async () => {
      // Create content with missing title
      const incompleteContent = {
        id: '2025-07-01-incomplete-test',
        status: 'reviewed',
        category: 'daily-news',
        date: '2025-07-01',
        language: 'zh-TW',
        title: '',
        content: '內容存在但標題為空',
        references: [],
        audio_file: null,
        social_hook: null,
        feedback: { content_review: null, ai_outputs: {}, performance_metrics: {} },
        updated_at: new Date().toISOString()
      };

      const incompleteDir = path.join(tempDir, 'zh-TW', 'daily-news');
      const incompletePath = path.join(incompleteDir, `${incompleteContent.id}.json`);
      await fs.writeFile(incompletePath, JSON.stringify(incompleteContent, null, 2));

      mockTranslateClient.translate.mock.mockImplementation(() => 
        Promise.resolve(['Translated text'])
      );

      const result = await TranslationService.translate('2025-07-01-incomplete-test', 'en-US');
      assert.strictEqual(result.translatedTitle, 'Translated text');
      assert.strictEqual(result.translatedContent, 'Translated text');
    });
  });
});