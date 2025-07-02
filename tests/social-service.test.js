import { describe, it, beforeEach, afterEach, mock } from 'node:test';
import assert from 'node:assert';
import fs from 'fs/promises';
import path from 'path';
import { TestUtils } from './setup.js';
import { ContentManager } from '../src/ContentManager.js';
import { SocialService } from '../src/services/SocialService.js';

describe('SocialService Tests', () => {
  let tempDir;
  let originalContentDir;
  let mockExecSync;
  let originalExecSync;

  beforeEach(async () => {
    tempDir = await TestUtils.createTempDir();
    originalContentDir = ContentManager.CONTENT_DIR;
    ContentManager.CONTENT_DIR = tempDir;

    // Create test content structure
    await createTestContent();
  });

  afterEach(async () => {
    ContentManager.CONTENT_DIR = originalContentDir;
    await TestUtils.cleanupTempDir(tempDir);
    
    mock.restoreAll();
  });

  async function createTestContent() {
    // Create source content with audio status
    const sourceContent = {
      id: '2025-07-02-social-test',
      status: 'audio',
      category: 'daily-news',
      date: '2025-07-02',
      language: 'zh-TW',
      title: '比特幣突破新高',
      content: '比特幣價格今天突破了歷史新高，達到了前所未有的水平。這一突破標誌著加密貨幣市場的重要里程碑。',
      references: ['測試來源'],
      audio_file: 'audio/zh-TW/daily-news/2025-07-02-social-test.wav',
      social_hook: null,
      feedback: { content_review: null, ai_outputs: {}, performance_metrics: {} },
      updated_at: new Date().toISOString()
    };

    // Create English translation
    const enContent = {
      ...sourceContent,
      language: 'en-US',
      title: 'Bitcoin Breaks New Highs',
      content: 'Bitcoin price broke historical highs today, reaching unprecedented levels. This breakthrough marks an important milestone for the cryptocurrency market.',
      status: 'audio',
      audio_file: 'audio/en-US/daily-news/2025-07-02-social-test.wav'
    };

    // Create Japanese translation
    const jaContent = {
      ...sourceContent,
      language: 'ja-JP',
      title: 'ビットコインが新高値を突破',
      content: 'ビットコインの価格が今日、史上最高値を突破し、前例のないレベルに達しました。この突破は、暗号通貨市場の重要なマイルストーンを示しています。',
      status: 'audio',
      audio_file: 'audio/ja-JP/daily-news/2025-07-02-social-test.wav'
    };

    // Create directory structure and write files
    for (const content of [sourceContent, enContent, jaContent]) {
      const contentDir = path.join(tempDir, content.language, content.category);
      await fs.mkdir(contentDir, { recursive: true });
      const filePath = path.join(contentDir, `${content.id}.json`);
      await fs.writeFile(filePath, JSON.stringify(content, null, 2));
    }
  }

  describe('Claude Integration', () => {
    it('should generate hook with Claude for English content', async (t) => {
      const mockHook = '🚀 Bitcoin breaks new highs! Unprecedented levels reached in crypto market. #Bitcoin #Crypto #NewHighs #Milestone';
      
      const mockExecuteCommandSync = t.mock.fn(() => mockHook);

      const hook = await SocialService.generateHook('2025-07-02-social-test', 'en-US', mockExecuteCommandSync);
      
      assert.strictEqual(hook, mockHook);
      assert.strictEqual(mockExecuteCommandSync.mock.callCount(), 1);
      
      // Verify the prompt was constructed correctly
      const commandArg = mockExecuteCommandSync.mock.calls[0].arguments[0];
      assert(commandArg.includes('claude -p'));
      assert(commandArg.includes('English'));
      assert(commandArg.includes('Under 180 characters'));
      assert(commandArg.includes('Return only the hook'));
    });

    it('should generate hook with Claude for Japanese content', async (t) => {
      const mockHook = '🚀 ビットコインが新高値突破！暗号通貨市場の重要なマイルストーン #ビットコイン #暗号通貨 #新高値';
      
      const mockExecuteCommandSync = t.mock.fn(() => mockHook);

      const hook = await SocialService.generateHook('2025-07-02-social-test', 'ja-JP', mockExecuteCommandSync);
      
      assert.strictEqual(hook, mockHook);
      
      // Verify Japanese-specific prompt
      const commandArg = mockExecuteCommandSync.mock.calls[0].arguments[0];
      assert(commandArg.includes('ビットコインが新高値を突破'));
      assert(commandArg.includes('Japanese'));
    });

    it('should handle Claude CLI timeout errors', async (t) => {
      const timeoutError = new Error('Command timeout');
      timeoutError.signal = 'SIGTERM';
      
      const mockExecuteCommandSync = t.mock.fn(() => {
        throw timeoutError;
      });

      await assert.rejects(
        async () => {
          await SocialService.generateHook('2025-07-02-social-test', 'en-US', mockExecuteCommandSync);
        },
        {
          name: 'Error',
          message: 'Claude command timed out after 60 seconds'
        }
      );
    });

    it('should handle Claude CLI not found errors', async (t) => {
      const enoentError = new Error('Command not found');
      enoentError.code = 'ENOENT';
      
      const mockExecuteCommandSync = t.mock.fn(() => {
        throw enoentError;
      });

      await assert.rejects(
        async () => {
          await SocialService.generateHook('2025-07-02-social-test', 'en-US', mockExecuteCommandSync);
        },
        {
          name: 'Error',
          message: 'Claude command not found. Install with: npm install -g claude-code'
        }
      );
    });

    it('should handle other Claude CLI errors', async (t) => {
      const genericError = new Error('Authentication failed');
      
      const mockExecuteCommandSync = t.mock.fn(() => {
        throw genericError;
      });

      await assert.rejects(
        async () => {
          await SocialService.generateHook('2025-07-02-social-test', 'en-US', mockExecuteCommandSync);
        },
        {
          name: 'Error',
          message: 'Social hook generation failed: Authentication failed'
        }
      );
    });

    it('should extract key insight correctly from content', async (t) => {
      const content = 'First paragraph with key insight.\n\nSecond paragraph with more details.\n\nThird paragraph.';
      
      const mockExecuteCommandSync = t.mock.fn((command) => {
        assert(command.includes('First paragraph with key insight.'));
        return 'Generated hook';
      });

      return SocialService.generateHookWithClaude('Test Title', content, 'en-US', mockExecuteCommandSync);
    });

    it('should handle long content by extracting substring', async (t) => {
      const longContent = 'A'.repeat(500);
      
      const mockExecuteCommandSync = t.mock.fn((command) => {
        const keyInsight = longContent.substring(0, 200);
        assert(command.includes(keyInsight));
        return 'Generated hook';
      });

      return SocialService.generateHookWithClaude('Test Title', longContent, 'en-US', mockExecuteCommandSync);
    });
  });

  describe('Single Hook Generation', () => {
    it('should generate hook and update content file', async (t) => {
      const mockHook = 'Test social hook for Bitcoin news! #Bitcoin #News';
      
      const mockExecuteCommandSync = t.mock.fn(() => mockHook);

      const result = await SocialService.generateHook('2025-07-02-social-test', 'en-US', mockExecuteCommandSync);
      
      assert.strictEqual(result, mockHook);
      
      // Verify content was updated with social hook
      const updatedContent = await ContentManager.read('2025-07-02-social-test', 'en-US');
      assert.strictEqual(updatedContent.social_hook, mockHook);
    });

    it('should throw error for non-existent content', async (t) => {
      const mockExecuteCommandSync = t.mock.fn(() => 'Generated hook');
      
      await assert.rejects(
        async () => {
          await SocialService.generateHook('non-existent-content', 'en-US', mockExecuteCommandSync);
        },
        {
          name: 'Error',
          message: /Content not found in en-US: non-existent-content/
        }
      );
    });

    it('should throw error for unsupported language', async (t) => {
      const mockExecuteCommandSync = t.mock.fn(() => 'Generated hook');
      
      await assert.rejects(
        async () => {
          await SocialService.generateHook('2025-07-02-social-test', 'fr-FR', mockExecuteCommandSync);
        },
        {
          name: 'Error',
          message: /Content not found in fr-FR:/
        }
      );
    });
  });

  describe('All Languages Hook Generation', () => {
    it('should generate hooks for all available languages', async (t) => {
      let callCount = 0;
      const mockExecuteCommandSync = t.mock.fn((command) => {
        callCount++;
        if (command.includes('English')) {
          return 'English hook #Bitcoin #Crypto';
        } else if (command.includes('Japanese')) {
          return 'Japanese hook #ビットコイン #暗号通貨';
        }
        return 'Default hook';
      });

      const results = await SocialService.generateAllHooks('2025-07-02-social-test', mockExecuteCommandSync);
      
      // Should generate for both target languages (not source zh-TW)
      assert(results['en-US']);
      assert(results['ja-JP']);
      assert(!results['zh-TW']); // Should not generate for source language
      
      assert.strictEqual(results['en-US'].success, true);
      assert.strictEqual(results['ja-JP'].success, true);
      assert.strictEqual(results['en-US'].hook, 'English hook #Bitcoin #Crypto');
      assert.strictEqual(results['ja-JP'].hook, 'Japanese hook #ビットコイン #暗号通貨');
      
      // Should call Claude twice (once per target language)
      assert.strictEqual(mockExecuteCommandSync.mock.callCount(), 2);
    });

    it('should update source status to social when all hooks generated', async (t) => {
      const mockExecuteCommandSync = t.mock.fn(() => 'Generated hook');

      await SocialService.generateAllHooks('2025-07-02-social-test', mockExecuteCommandSync);
      
      // Verify source status was updated
      const sourceContent = await ContentManager.readSource('2025-07-02-social-test');
      assert.strictEqual(sourceContent.status, 'social');
    });

    it('should handle partial generation failures', async (t) => {
      let callCount = 0;
      const mockExecuteCommandSync = t.mock.fn((command) => {
        callCount++;
        if (command.includes('English')) {
          return 'English hook success';
        } else if (command.includes('Japanese')) {
          throw new Error('Claude API error for Japanese');
        }
        return 'Default';
      });

      const results = await SocialService.generateAllHooks('2025-07-02-social-test', mockExecuteCommandSync);
      
      // English should succeed
      assert.strictEqual(results['en-US'].success, true);
      assert.strictEqual(results['en-US'].hook, 'English hook success');
      
      // Japanese should fail
      assert.strictEqual(results['ja-JP'].success, false);
      assert(results['ja-JP'].error.includes('Claude API error for Japanese'));
      
      // Source status should NOT be updated due to failure
      const sourceContent = await ContentManager.readSource('2025-07-02-social-test');
      assert.strictEqual(sourceContent.status, 'audio'); // Should remain unchanged
    });

    it('should throw error if content not in audio status', async (t) => {
      const mockExecuteCommandSync = t.mock.fn(() => 'Generated hook');
      
      // Update source content to wrong status
      await ContentManager.updateSourceStatus('2025-07-02-social-test', 'translated');

      await assert.rejects(
        async () => {
          await SocialService.generateAllHooks('2025-07-02-social-test', mockExecuteCommandSync);
        },
        {
          name: 'Error',
          message: 'Content must have audio before social hooks. Current status: translated'
        }
      );
    });

    it('should handle content with no available languages', async (t) => {
      const mockExecuteCommandSync = t.mock.fn(() => 'Generated hook');
      // Create content with only source language
      const sourceOnly = {
        id: '2025-07-02-source-only',
        status: 'audio',
        category: 'daily-news',
        date: '2025-07-02',
        language: 'zh-TW',
        title: '僅源語言內容',
        content: '這個內容只有源語言版本',
        references: [],
        audio_file: null,
        social_hook: null,
        feedback: { content_review: null, ai_outputs: {}, performance_metrics: {} },
        updated_at: new Date().toISOString()
      };

      const sourceDir = path.join(tempDir, 'zh-TW', 'daily-news');
      await fs.writeFile(
        path.join(sourceDir, `${sourceOnly.id}.json`),
        JSON.stringify(sourceOnly, null, 2)
      );

      const results = await SocialService.generateAllHooks('2025-07-02-source-only', mockExecuteCommandSync);
      
      // Should return empty results for target languages
      assert.deepStrictEqual(results, {});
      
      // Source status should be updated to social (no translation languages to process)
      const sourceContent = await ContentManager.readSource('2025-07-02-source-only');
      assert.strictEqual(sourceContent.status, 'social');
    });
  });

  describe('Content Status Management', () => {
    it('should get content needing social hooks', async () => {
      const contentList = await SocialService.getContentNeedingSocial();
      
      assert.strictEqual(contentList.length, 1);
      assert.strictEqual(contentList[0].id, '2025-07-02-social-test');
      assert.strictEqual(contentList[0].status, 'audio');
    });

    it('should get content ready to publish', async () => {
      // Update status to social first
      await ContentManager.updateSourceStatus('2025-07-02-social-test', 'social');
      
      const contentList = await SocialService.getContentReadyToPublish();
      
      assert.strictEqual(contentList.length, 1);
      assert.strictEqual(contentList[0].id, '2025-07-02-social-test');
      assert.strictEqual(contentList[0].status, 'social');
    });

    it('should return empty arrays when no content matches status', async () => {
      // Update to published status
      await ContentManager.updateSourceStatus('2025-07-02-social-test', 'published');
      
      const needingSocial = await SocialService.getContentNeedingSocial();
      const readyToPublish = await SocialService.getContentReadyToPublish();
      
      assert.strictEqual(needingSocial.length, 0);
      assert.strictEqual(readyToPublish.length, 0);
    });
  });

  describe('Language Support', () => {
    it('should support defined languages', () => {
      const supportedLanguages = SocialService.SUPPORTED_LANGUAGES;
      
      assert(Array.isArray(supportedLanguages));
      assert(supportedLanguages.includes('en-US'));
      assert(supportedLanguages.includes('ja-JP'));
      assert.strictEqual(supportedLanguages.length, 2);
    });

    it('should map language codes correctly in prompts', async (t) => {
      const mockExecuteCommandSync = t.mock.fn((command) => {
        // Verify language names are correctly mapped
        assert(command.includes('English') || command.includes('Japanese'));
        return 'Generated hook';
      });

      await SocialService.generateHook('2025-07-02-social-test', 'en-US', mockExecuteCommandSync);
      await SocialService.generateHook('2025-07-02-social-test', 'ja-JP', mockExecuteCommandSync);
      
      assert.strictEqual(mockExecuteCommandSync.mock.callCount(), 2);
    });
  });

  describe('Error Handling and Edge Cases', () => {
    it('should handle special characters in content', async (t) => {
      const specialContent = {
        id: '2025-07-02-special-chars',
        status: 'audio',
        category: 'daily-news',
        date: '2025-07-02',
        language: 'en-US',
        title: 'Bitcoin $$$$ & ETH 🚀 100% gains!',
        content: 'Special chars: $$$, &&&, "quotes", \'apostrophes\', and emojis 🚀💰📈',
        references: [],
        audio_file: null,
        social_hook: null,
        feedback: { content_review: null, ai_outputs: {}, performance_metrics: {} },
        updated_at: new Date().toISOString()
      };

      const enDir = path.join(tempDir, 'en-US', 'daily-news');
      await fs.writeFile(
        path.join(enDir, `${specialContent.id}.json`),
        JSON.stringify(specialContent, null, 2)
      );

      const mockExecuteCommandSync = t.mock.fn((command) => {
        // Should handle special characters in command
        assert(command.includes('Bitcoin $$$$ & ETH'));
        return 'Generated hook with special chars';
      });

      const result = await SocialService.generateHook('2025-07-02-special-chars', 'en-US', mockExecuteCommandSync);
      assert.strictEqual(result, 'Generated hook with special chars');
    });

    it('should handle very long titles and content', async (t) => {
      const longTitle = 'A'.repeat(500);
      const longContent = 'B'.repeat(2000);
      
      const mockExecuteCommandSync = t.mock.fn((command) => {
        // Should truncate long content appropriately
        assert(command.length < 3000); // Reasonable command length
        return 'Generated hook for long content';
      });

      const result = await SocialService.generateHookWithClaude(longTitle, longContent, 'en-US', mockExecuteCommandSync);
      assert.strictEqual(result, 'Generated hook for long content');
    });

    it('should trim whitespace from generated hooks', async (t) => {
      const hookWithWhitespace = '   Generated hook with spaces   \n\n';
      
      const mockExecuteCommandSync = t.mock.fn(() => hookWithWhitespace);

      const result = await SocialService.generateHook('2025-07-02-social-test', 'en-US', mockExecuteCommandSync);
      assert.strictEqual(result, 'Generated hook with spaces');
    });

    it('should handle empty Claude responses', async (t) => {
      const mockExecuteCommandSync = t.mock.fn(() => '');

      const result = await SocialService.generateHook('2025-07-02-social-test', 'en-US', mockExecuteCommandSync);
      assert.strictEqual(result, '');
    });
  });
});