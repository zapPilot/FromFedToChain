import { describe, it, beforeEach, afterEach, mock } from 'node:test';
import assert from 'node:assert';
import fs from 'fs/promises';
import path from 'path';
import { TestUtils } from './setup.js';
import { ContentManager } from '../src/ContentManager.js';
import { ContentSchema } from '../src/ContentSchema.js';
import { TranslationService } from '../src/services/TranslationService.js';
import { AudioService } from '../src/services/AudioService.js';
import { SocialService } from '../src/services/SocialService.js';

describe('End-to-End Workflow Tests', () => {
  let tempDir;
  let tempAudioDir;
  let originalContentDir;
  let originalAudioDir;
  let mockTranslateClient;
  let mockTTSService;
  let mockExecSync;
  let originalExecSync;

  beforeEach(async () => {
    // Setup temp directories
    tempDir = await TestUtils.createTempDir();
    tempAudioDir = await TestUtils.createTempDir();
    
    originalContentDir = ContentManager.CONTENT_DIR;
    originalAudioDir = AudioService.AUDIO_DIR;
    
    ContentManager.CONTENT_DIR = tempDir;
    AudioService.AUDIO_DIR = tempAudioDir;

    // Mock external services
    await setupMocks();
  });

  afterEach(async () => {
    ContentManager.CONTENT_DIR = originalContentDir;
    AudioService.AUDIO_DIR = originalAudioDir;
    
    await TestUtils.cleanupTempDir(tempDir);
    await TestUtils.cleanupTempDir(tempAudioDir);
    
    // Restore original services
    await restoreMocks();
    
    mock.restoreAll();
  });

  async function setupMocks() {
    // Mock Google Translate
    mockTranslateClient = {
      translate: mock.fn()
    };
    
    const originalGetTranslateClient = TranslationService.getTranslateClient;
    TranslationService.getTranslateClient = mock.fn(() => mockTranslateClient);
    TranslationService.translate_client = mockTranslateClient;

    // Mock Google TTS
    mockTTSService = {
      synthesizeSpeech: mock.fn(),
      prepareContentForTTS: mock.fn()
    };

    // Note: execSync mocking will be done per test using t.mock.module
  }

  async function restoreMocks() {
    // Restore original services
    TranslationService.translate_client = null;
  }

  function createMockAudioContent(size = 1000) {
    const buffer = Buffer.alloc(size);
    // Write basic WAV header
    buffer.write('RIFF', 0);
    buffer.writeUInt32LE(size - 8, 4);
    buffer.write('WAVE', 8);
    buffer.write('data', 36);
    buffer.writeUInt32LE(size - 44, 40);
    return buffer;
  }

  describe('Full Content Pipeline Workflow', () => {
    it('should complete full workflow from creation to social hooks', async (t) => {
      // 1. Create source content
      console.log('Step 1: Creating source content...');
      const sourceContent = await ContentManager.createSource(
        '2025-07-02-workflow-test',
        'daily-news',
        'Bitcoin突破新高度',
        '比特幣價格今天創下了新的歷史高點，這標誌著加密貨幣市場的重要轉折點。專家預測這種趨勢將持續下去。',
        ['Financial Times', 'CoinDesk']
      );

      assert.strictEqual(sourceContent.status, 'draft');
      assert.strictEqual(sourceContent.language, 'zh-TW');
      
      // 2. Review and approve content
      console.log('Step 2: Reviewing content...');
      await ContentManager.addContentFeedback(
        '2025-07-02-workflow-test',
        'accepted',
        4,
        'test_reviewer',
        'Good content for translation',
        {}
      );
      await ContentManager.updateSourceStatus('2025-07-02-workflow-test', 'reviewed');

      const reviewedContent = await ContentManager.readSource('2025-07-02-workflow-test');
      assert.strictEqual(reviewedContent.status, 'reviewed');
      assert.strictEqual(reviewedContent.feedback.content_review.status, 'accepted');

      // 3. Setup translation mocks
      console.log('Step 3: Setting up translation...');
      mockTranslateClient.translate.mock.mockImplementation((text, options) => {
        if (options.to === 'en') {
          if (text.includes('Bitcoin突破新高度')) {
            return Promise.resolve(['Bitcoin Breaks New Heights']);
          } else if (text.includes('比特幣價格今天創下了新的歷史高點')) {
            return Promise.resolve(['Bitcoin price reached new historical highs today, marking an important turning point for the cryptocurrency market. Experts predict this trend will continue.']);
          }
        } else if (options.to === 'ja') {
          if (text.includes('Bitcoin突破新高度')) {
            return Promise.resolve(['ビットコインが新高度を突破']);
          } else if (text.includes('比特幣價格今天創下了新的歷史高點')) {
            return Promise.resolve(['ビットコインの価格が今日、新たな歴史的高値に達し、暗号通貨市場の重要な転換点となりました。専門家はこの傾向が続くと予測しています。']);
          }
        }
        return Promise.resolve([text]);
      });

      // 4. Translate to all languages
      console.log('Step 4: Translating content...');
      const translationResults = await TranslationService.translateAll('2025-07-02-workflow-test');
      
      assert(translationResults['en-US'].translatedTitle);
      assert(translationResults['ja-JP'].translatedTitle);
      assert.strictEqual(translationResults['en-US'].translatedTitle, 'Bitcoin Breaks New Heights');
      assert.strictEqual(translationResults['ja-JP'].translatedTitle, 'ビットコインが新高度を突破');

      // Verify translation files were created
      const enTranslation = await ContentManager.read('2025-07-02-workflow-test', 'en-US');
      const jaTranslation = await ContentManager.read('2025-07-02-workflow-test', 'ja-JP');
      
      assert.strictEqual(enTranslation.status, 'translated');
      assert.strictEqual(jaTranslation.status, 'translated');

      // Verify source status updated
      const translatedSource = await ContentManager.readSource('2025-07-02-workflow-test');
      assert.strictEqual(translatedSource.status, 'translated');

      // 5. Setup audio generation mocks
      console.log('Step 5: Setting up audio generation...');
      mockTTSService.synthesizeSpeech.mock.mockImplementation((content, config) => {
        return Promise.resolve({
          audioContent: createMockAudioContent(5000)
        });
      });

      // Override AudioService methods for testing
      const originalGenerateAudio = AudioService.generateAudio;
      AudioService.generateAudio = async function(id, language) {
        const content = await ContentManager.read(id, language);
        if (!content) {
          throw new Error(`No ${language} content found for ${id}`);
        }

        const audioResponse = await mockTTSService.synthesizeSpeech(content.content, {});
        const audioPath = await this.saveAudioFile(
          audioResponse.audioContent,
          id,
          language,
          content.category
        );

        await ContentManager.addAudio(id, language, audioPath);
        return audioPath;
      };

      // 6. Generate audio for all languages
      console.log('Step 6: Generating audio...');
      const audioResults = await AudioService.generateAllAudio('2025-07-02-workflow-test');
      
      assert.strictEqual(audioResults['zh-TW'].success, true);
      assert.strictEqual(audioResults['en-US'].success, true);
      assert.strictEqual(audioResults['ja-JP'].success, true);

      // Verify audio files were created and content updated
      const audioUpdatedSource = await ContentManager.readSource('2025-07-02-workflow-test');
      assert.strictEqual(audioUpdatedSource.status, 'audio');

      const audioUpdatedEn = await ContentManager.read('2025-07-02-workflow-test', 'en-US');
      const audioUpdatedJa = await ContentManager.read('2025-07-02-workflow-test', 'ja-JP');
      assert(audioUpdatedEn.audio_file);
      assert(audioUpdatedJa.audio_file);

      // Restore original method
      AudioService.generateAudio = originalGenerateAudio;

      // 7. Setup social hook generation mocks
      console.log('Step 7: Setting up social hook generation...');
      const mockExecuteCommandSync = t.mock.fn((command) => {
        if (command.includes('English')) {
          return '🚀 Bitcoin breaks new heights! Historic highs reached in crypto market. #Bitcoin #Crypto #NewHighs';
        } else if (command.includes('Japanese')) {
          return '🚀 ビットコインが新高度突破！暗号通貨市場で歴史的高値達成 #ビットコイン #暗号通貨 #新高値';
        }
        return 'Generated social hook';
      });

      // 8. Generate social hooks
      console.log('Step 8: Generating social hooks...');
      const socialResults = await SocialService.generateAllHooks('2025-07-02-workflow-test', mockExecuteCommandSync);
      
      assert.strictEqual(socialResults['en-US'].success, true);
      assert.strictEqual(socialResults['ja-JP'].success, true);
      // Check that hooks exist and have reasonable content
      assert(socialResults['en-US'].hook);
      assert(socialResults['ja-JP'].hook);
      assert(socialResults['en-US'].hook.length > 10);
      assert(socialResults['ja-JP'].hook.length > 10);

      // Verify source status updated to social
      const finalSource = await ContentManager.readSource('2025-07-02-workflow-test');
      assert.strictEqual(finalSource.status, 'social');

      // Verify social hooks were added to content
      const socialUpdatedEn = await ContentManager.read('2025-07-02-workflow-test', 'en-US');
      const socialUpdatedJa = await ContentManager.read('2025-07-02-workflow-test', 'ja-JP');
      assert(socialUpdatedEn.social_hook);
      assert(socialUpdatedJa.social_hook);

      console.log('✅ Full workflow completed successfully!');
    });

    it('should maintain data consistency across workflow steps', async (t) => {
      // Create content with specific metadata
      const contentId = '2025-07-02-consistency-test';
      const sourceContent = await ContentManager.createSource(
        contentId,
        'ethereum',
        'Ethereum升級測試',
        '這是一個用於測試數據一致性的以太坊內容',
        ['Ethereum Foundation', 'Vitalik Blog']
      );

      // Review content
      await ContentManager.updateSourceStatus(contentId, 'reviewed');

      // Setup successful translation
      mockTranslateClient.translate.mock.mockImplementation((text, options) => {
        return Promise.resolve([`Translated: ${text} (${options.to})`]);
      });

      // Translate content
      await TranslationService.translateAll(contentId);

      // Verify data consistency across all language versions
      const allVersions = await ContentManager.getAllLanguagesForId(contentId);
      
      assert.strictEqual(allVersions.length, 3); // zh-TW, en-US, ja-JP
      
      allVersions.forEach(version => {
        assert.strictEqual(version.id, contentId);
        assert.strictEqual(version.category, 'ethereum');
        assert.strictEqual(version.date, sourceContent.date);
        assert(version.updated_at);
        
        // All should have same feedback structure
        assert(version.feedback);
        assert.strictEqual(version.feedback.content_review, null);
      });

      // Verify source retains original references
      const updatedSource = await ContentManager.readSource(contentId);
      assert.deepStrictEqual(updatedSource.references, ['Ethereum Foundation', 'Vitalik Blog']);
    });
  });

  describe('Workflow Status Transitions', () => {
    it('should enforce correct status transitions', async (t) => {
      const contentId = '2025-07-02-status-test';
      
      // 1. Create content (draft)
      const sourceContent = await ContentManager.createSource(
        contentId,
        'macro',
        'Status Test Content',
        'Testing status transitions',
        []
      );
      assert.strictEqual(sourceContent.status, 'draft');

      // 2. Cannot translate draft content
      await assert.rejects(
        async () => {
          await TranslationService.translate(contentId, 'en-US');
        },
        {
          name: 'Error',
          message: /Content must be reviewed before translation/
        }
      );

      // 3. Review content (reviewed)
      await ContentManager.updateSourceStatus(contentId, 'reviewed');
      
      // 4. Cannot generate audio before translation
      await assert.rejects(
        async () => {
          await AudioService.generateAllAudio(contentId);
        },
        {
          name: 'Error',
          message: /Content must be translated before audio generation/
        }
      );

      // 5. Cannot generate social hooks before audio
      await assert.rejects(
        async () => {
          await SocialService.generateAllHooks(contentId);
        },
        {
          name: 'Error',
          message: /Content must have audio before social hooks/
        }
      );
    });

    it('should track status changes with timestamps', async (t) => {
      const contentId = '2025-07-02-timestamp-test';
      
      const beforeCreate = new Date().toISOString();
      const sourceContent = await ContentManager.createSource(
        contentId,
        'daily-news',
        'Timestamp Test',
        'Testing timestamp tracking',
        []
      );
      const afterCreate = new Date().toISOString();

      assert(sourceContent.updated_at >= beforeCreate);
      assert(sourceContent.updated_at <= afterCreate);

      // Update status and verify timestamp changes
      const beforeUpdate = new Date().toISOString();
      await ContentManager.updateSourceStatus(contentId, 'reviewed');
      const afterUpdate = new Date().toISOString();

      const updatedContent = await ContentManager.readSource(contentId);
      assert(updatedContent.updated_at >= beforeUpdate);
      assert(updatedContent.updated_at <= afterUpdate);
      assert(updatedContent.updated_at > sourceContent.updated_at);
    });
  });

  describe('Error Recovery and Resilience', () => {
    it('should recover from partial translation failures', async (t) => {
      const contentId = '2025-07-02-recovery-test';
      
      await ContentManager.createSource(
        contentId,
        'daily-news',
        'Recovery Test',
        'Testing error recovery',
        []
      );
      await ContentManager.updateSourceStatus(contentId, 'reviewed');

      // Mock partial failure (English succeeds, Japanese fails)
      let callCount = 0;
      mockTranslateClient.translate.mock.mockImplementation((text, options) => {
        callCount++;
        if (options.to === 'en') {
          return Promise.resolve([`English: ${text}`]);
        } else if (options.to === 'ja') {
          throw new Error('Japanese translation service temporarily unavailable');
        }
        return Promise.resolve([text]);
      });

      const results = await TranslationService.translateAll(contentId);
      
      // English should succeed
      assert.strictEqual(results['en-US'].translatedTitle, 'English: Recovery Test');
      
      // Japanese should fail
      assert(results['ja-JP'].error);
      assert(results['ja-JP'].error.includes('Japanese translation service'));

      // Source should remain in reviewed status (not fully translated)
      const sourceContent = await ContentManager.readSource(contentId);
      assert.strictEqual(sourceContent.status, 'reviewed');

      // Retry with fixed service
      mockTranslateClient.translate.mock.mockImplementation((text, options) => {
        return Promise.resolve([`${options.to}: ${text}`]);
      });

      // Retry just the failed language
      const retryResult = await TranslationService.translate(contentId, 'ja-JP');
      assert.strictEqual(retryResult.translatedTitle, 'ja: Recovery Test');

      // Now all translations complete, source should update to translated
      const finalSource = await ContentManager.readSource(contentId);
      assert.strictEqual(finalSource.status, 'translated');
    });
  });

  describe('Content Validation Throughout Workflow', () => {
    it('should validate content schema at each step', async (t) => {
      const contentId = '2025-07-02-validation-test';
      
      // Create valid content
      const sourceContent = await ContentManager.createSource(
        contentId,
        'daily-news',
        'Validation Test',
        'Testing schema validation',
        []
      );

      // Should pass validation
      assert.doesNotThrow(() => ContentSchema.validate(sourceContent));

      // Update status and re-validate
      await ContentManager.updateSourceStatus(contentId, 'reviewed');
      const reviewedContent = await ContentManager.readSource(contentId);
      assert.doesNotThrow(() => ContentSchema.validate(reviewedContent));

      // Setup translation and validate translation files
      mockTranslateClient.translate.mock.mockImplementation((text) => {
        return Promise.resolve([`Translated: ${text}`]);
      });

      await TranslationService.translate(contentId, 'en-US');
      const translatedContent = await ContentManager.read(contentId, 'en-US');
      assert.doesNotThrow(() => ContentSchema.validate(translatedContent));

      // Verify all required fields are preserved
      assert.strictEqual(translatedContent.id, contentId);
      assert.strictEqual(translatedContent.category, 'daily-news');
      assert.strictEqual(translatedContent.language, 'en-US');
      assert(translatedContent.title);
      assert(translatedContent.content);
      assert(translatedContent.feedback);
    });

    it('should handle malformed content gracefully', async (t) => {
      // Create content file with missing required fields
      const malformedContent = {
        id: '2025-07-02-malformed',
        status: 'draft',
        // Missing category, date, language, etc.
        title: 'Malformed Content',
        content: 'This content is missing required fields'
      };

      const contentDir = path.join(tempDir, 'zh-TW', 'daily-news');
      await fs.mkdir(contentDir, { recursive: true });
      await fs.writeFile(
        path.join(contentDir, '2025-07-02-malformed.json'),
        JSON.stringify(malformedContent, null, 2)
      );

      // ContentManager should handle malformed content gracefully
      const allContent = await ContentManager.list();
      
      // Should include malformed content but it should fail validation if used
      const malformed = allContent.find(c => c.id === '2025-07-02-malformed');
      assert(malformed); // Content exists but is malformed
      
      // Attempting to validate should throw an error due to missing fields
      assert.throws(() => {
        ContentSchema.validate(malformed);
      });
    });
  });
});