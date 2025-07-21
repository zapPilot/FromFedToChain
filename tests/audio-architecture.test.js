import { describe, it, beforeEach, afterEach, mock } from 'node:test';
import assert from 'node:assert';
import fs from 'fs/promises';
import path from 'path';
import { TestUtils } from './setup.js';
import { AudioService } from '../src/services/AudioService.js';
import { ContentManager } from '../src/ContentManager.js';
import { 
  getAudioLanguages, 
  getTTSConfig, 
  shouldGenerateAudio,
  LANGUAGE_CONFIG 
} from '../config/languages.js';

describe('Audio Architecture Tests', () => {
  let tempDir;
  let tempAudioDir;
  let originalContentDir;
  let originalAudioDir;
  let mockTTSService;

  beforeEach(async () => {
    // Setup temp directories
    tempDir = await TestUtils.createTempDir();
    tempAudioDir = await TestUtils.createTempDir();
    
    originalContentDir = ContentManager.CONTENT_DIR;
    originalAudioDir = AudioService.AUDIO_DIR;
    
    ContentManager.CONTENT_DIR = tempDir;
    AudioService.AUDIO_DIR = tempAudioDir;

    // Mock TTS service
    mockTTSService = {
      synthesizeSpeech: mock.fn(),
      prepareContentForTTS: mock.fn()
    };

    // Create test content
    await createTestContent();
  });

  afterEach(async () => {
    ContentManager.CONTENT_DIR = originalContentDir;
    AudioService.AUDIO_DIR = originalAudioDir;
    
    await TestUtils.cleanupTempDir(tempDir);
    await TestUtils.cleanupTempDir(tempAudioDir);
    
    mock.restoreAll();
  });

  async function createTestContent() {
    const sourceContent = {
      id: '2025-07-01-test-audio',
      status: 'translated',
      category: 'daily-news',
      date: '2025-07-01',
      language: 'zh-TW',
      title: '測試音頻內容標題',
      content: '這是用於測試音頻生成的中文內容。它包含足夠的文字來測試TTS功能。',
      references: ['測試來源'],
      audio_file: null,
      social_hook: null,
      feedback: { content_review: null, ai_outputs: {}, performance_metrics: {} },
      updated_at: new Date().toISOString()
    };

    const enContent = {
      ...sourceContent,
      language: 'en-US',
      title: 'Test Audio Content Title',
      content: 'This is English content for testing audio generation. It contains enough text to test TTS functionality.',
      status: 'translated'
    };

    const jaContent = {
      ...sourceContent,
      language: 'ja-JP',
      title: 'テストオーディオコンテンツのタイトル',
      content: 'これは音声生成をテストするための日本語コンテンツです。TTS機能をテストするのに十分なテキストが含まれています。',
      status: 'translated'
    };

    // Create directory structure and files
    for (const content of [sourceContent, enContent, jaContent]) {
      const contentDir = path.join(tempDir, content.language, content.category);
      await fs.mkdir(contentDir, { recursive: true });
      const filePath = path.join(contentDir, `${content.id}.json`);
      await fs.writeFile(filePath, JSON.stringify(content, null, 2));
    }
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

  describe('Unified Language Configuration', () => {
    it('should include zh-TW in audio languages', () => {
      const audioLangs = getAudioLanguages();
      assert(audioLangs.includes('zh-TW'), 'zh-TW should be included in audio languages');
      assert(audioLangs.includes('en-US'), 'en-US should be included in audio languages');
      assert(audioLangs.includes('ja-JP'), 'ja-JP should be included in audio languages');
    });

    it('should provide TTS config for all languages including zh-TW', () => {
      const zhConfig = getTTSConfig('zh-TW');
      assert.strictEqual(zhConfig.languageCode, 'zh-TW');
      assert.strictEqual(zhConfig.name, 'cmn-TW-Wavenet-B');
      assert.strictEqual(zhConfig.voiceConfig.ssmlGender, 'FEMALE');

      const enConfig = getTTSConfig('en-US');
      assert.strictEqual(enConfig.languageCode, 'en-US');
      assert.strictEqual(enConfig.name, 'en-US-Wavenet-D');
      assert.strictEqual(enConfig.voiceConfig.ssmlGender, 'MALE');

      const jaConfig = getTTSConfig('ja-JP');
      assert.strictEqual(jaConfig.languageCode, 'ja-JP');
      assert.strictEqual(jaConfig.name, 'ja-JP-Wavenet-C');
      assert.strictEqual(jaConfig.voiceConfig.ssmlGender, 'FEMALE');
    });

    it('should validate audio generation flags for all languages', () => {
      assert.strictEqual(shouldGenerateAudio('zh-TW'), true);
      assert.strictEqual(shouldGenerateAudio('en-US'), true);
      assert.strictEqual(shouldGenerateAudio('ja-JP'), true);
    });

    it('should have comprehensive language metadata', () => {
      const zhConfig = LANGUAGE_CONFIG['zh-TW'];
      assert.strictEqual(zhConfig.name, 'Traditional Chinese');
      assert.strictEqual(zhConfig.region, 'Taiwan');
      assert.strictEqual(zhConfig.isSource, true);
      assert.strictEqual(zhConfig.contentProcessing.generateAudio, true);

      const enConfig = LANGUAGE_CONFIG['en-US'];
      assert.strictEqual(enConfig.name, 'English');
      assert.strictEqual(enConfig.region, 'United States');
      assert.strictEqual(enConfig.isTarget, true);
      assert.strictEqual(enConfig.contentProcessing.generateAudio, true);
    });
  });

  describe('Audio Generation with zh-TW Inclusion', () => {
    beforeEach(() => {
      // Mock successful TTS generation
      mockTTSService.synthesizeSpeech.mock.mockImplementation(() => 
        Promise.resolve({
          audioContent: createMockAudioContent(5000)
        })
      );

      mockTTSService.prepareContentForTTS = (content, lang) => content;

      // Override the TTS service import
      const originalPrepareContent = AudioService.constructor.prototype.prepareContentForTTS;
      
      // Mock the generateAudio static method to use our mock
      const originalGenerateAudio = AudioService.generateAudio;
      AudioService.generateAudio = async function(id, language) {
        console.log(`🎙️ Generating audio: ${id} (${language})`);

        if (!shouldGenerateAudio(language)) {
          throw new Error(`Audio generation not configured for language: ${language}`);
        }

        const content = await ContentManager.read(id, language);
        if (!content) {
          throw new Error(`No ${language} content found for ${id}`);
        }

        const ttsConfig = getTTSConfig(language);
        const voiceConfig = {
          languageCode: ttsConfig.languageCode,
          name: ttsConfig.name
        };

        const audioResponse = await mockTTSService.synthesizeSpeech(content.content, voiceConfig);

        const audioPath = await this.saveAudioFile(
          audioResponse.audioContent,
          id,
          language,
          content.category
        );

        await ContentManager.addAudio(id, language, audioPath);

        console.log(`✅ Audio generated: ${audioPath}`);
        return audioPath;
      };
    });

    it('should generate audio for zh-TW source content', async () => {
      const audioPath = await AudioService.generateAudio('2025-07-01-test-audio', 'zh-TW');
      
      // Verify audio path follows correct structure
      assert(audioPath.includes('zh-TW/daily-news/2025-07-01-test-audio.wav'));
      
      // Verify file was created
      const fileExists = await fs.access(audioPath).then(() => true).catch(() => false);
      assert(fileExists, 'Audio file should be created');
      
      // Verify TTS service was called
      assert.strictEqual(mockTTSService.synthesizeSpeech.mock.callCount(), 1);
    });

    // REMOVED: Tests using non-existent AudioService.generateAllAudio method

    it('should verify TTS configuration is passed correctly', async () => {
      await AudioService.generateAudio('2025-07-01-test-audio', 'zh-TW');
      
      const callArgs = mockTTSService.synthesizeSpeech.mock.calls[0].arguments[1];
      assert.strictEqual(callArgs.languageCode, 'zh-TW');
      assert.strictEqual(callArgs.name, 'cmn-TW-Wavenet-B');
    });
  });

  describe('Folder Structure Consistency', () => {
    beforeEach(() => {
      mockTTSService.synthesizeSpeech.mock.mockImplementation(() => 
        Promise.resolve({ audioContent: createMockAudioContent(1000) })
      );
    });

    it('should create audio files in correct nested structure', async () => {
      const audioPath = await AudioService.saveAudioFile(
        createMockAudioContent(1000),
        '2025-07-01-test-audio',
        'zh-TW',
        'daily-news'
      );

      const expectedPath = path.join(tempAudioDir, 'zh-TW', 'daily-news', '2025-07-01-test-audio.wav');
      assert.strictEqual(audioPath, expectedPath);

      // Verify file exists
      const fileExists = await fs.access(audioPath).then(() => true).catch(() => false);
      assert(fileExists, 'Audio file should exist at correct path');
    });

    // REMOVED: Test using non-existent AudioService.generateAllAudio method

    it('should handle different categories correctly', async () => {
      // Create macro category content
      const macroContent = {
        id: '2025-07-01-macro-test',
        status: 'translated',
        category: 'macro',
        date: '2025-07-01',
        language: 'zh-TW',
        title: '宏觀測試',
        content: '宏觀經濟測試內容',
        references: [],
        audio_file: null,
        social_hook: null,
        feedback: { content_review: null, ai_outputs: {}, performance_metrics: {} },
        updated_at: new Date().toISOString()
      };

      const macroDir = path.join(tempDir, 'zh-TW', 'macro');
      await fs.mkdir(macroDir, { recursive: true });
      await fs.writeFile(
        path.join(macroDir, `${macroContent.id}.json`),
        JSON.stringify(macroContent, null, 2)
      );

      const audioPath = await AudioService.saveAudioFile(
        createMockAudioContent(1000),
        macroContent.id,
        'zh-TW',
        'macro'
      );

      assert(audioPath.includes('zh-TW/macro/'), 'Should create macro category structure');
    });

    it('should create directories recursively', async () => {
      const audioPath = await AudioService.saveAudioFile(
        createMockAudioContent(500),
        '2025-07-01-ethereum-test',
        'ja-JP',
        'ethereum'
      );

      // Verify nested directory was created
      const expectedDir = path.join(tempAudioDir, 'ja-JP', 'ethereum');
      const dirStat = await fs.stat(expectedDir);
      assert(dirStat.isDirectory(), 'Should create nested directory structure');

      // Verify file was created
      const fileExists = await fs.access(audioPath).then(() => true).catch(() => false);
      assert(fileExists, 'Audio file should be created in nested structure');
    });
  });

  describe('Audio File Listing with New Structure', () => {
    beforeEach(async () => {
      // Create test audio files in nested structure
      const testFiles = [
        { lang: 'zh-TW', category: 'daily-news', id: 'test1' },
        { lang: 'en-US', category: 'daily-news', id: 'test1' },
        { lang: 'ja-JP', category: 'macro', id: 'test2' },
        { lang: 'zh-TW', category: 'ethereum', id: 'test3' }
      ];

      for (const file of testFiles) {
        const audioDir = path.join(tempAudioDir, file.lang, file.category);
        await fs.mkdir(audioDir, { recursive: true });
        const filePath = path.join(audioDir, `${file.id}.wav`);
        await fs.writeFile(filePath, createMockAudioContent(1000));
      }
    });

    // REMOVED: Tests using non-existent AudioService.listAudioFiles method
  });

  describe('Error Handling and Edge Cases', () => {
    it('should handle missing content gracefully', async () => {
      await assert.rejects(
        async () => {
          await AudioService.generateAudio('nonexistent-id', 'zh-TW');
        },
        {
          name: 'Error',
          message: /Content not found in zh-TW: nonexistent-id/
        }
      );
    });

    it('should validate language configuration', async () => {
      await assert.rejects(
        async () => {
          await AudioService.generateAudio('2025-07-01-test-audio', 'invalid-lang');
        },
        {
          name: 'Error',
          message: /Audio generation not configured for language: invalid-lang/
        }
      );
    });

    it('should handle audio directory creation errors', async () => {
      // Mock fs.mkdir to fail
      const originalMkdir = fs.mkdir;
      fs.mkdir = mock.fn(() => Promise.reject(new Error('Permission denied')));

      try {
        await assert.rejects(
          async () => {
            await AudioService.saveAudioFile(
              createMockAudioContent(500),
              'test-id',
              'zh-TW', 
              'daily-news'
            );
          },
          {
            name: 'Error',
            message: 'Permission denied'
          }
        );
      } finally {
        fs.mkdir = originalMkdir;
      }
    });

    // REMOVED: Test using non-existent AudioService.generateAllAudio method
  });
});