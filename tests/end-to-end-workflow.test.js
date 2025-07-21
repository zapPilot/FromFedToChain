import { describe, it, beforeEach, afterEach, mock } from "node:test";
import assert from "node:assert";
import fs from "fs/promises";
import path from "path";
import { TestUtils } from "./setup.js";
import { ContentManager } from "../src/ContentManager.js";
import { ContentSchema } from "../src/ContentSchema.js";
import { TranslationService } from "../src/services/TranslationService.js";
import { AudioService } from "../src/services/AudioService.js";
import { SocialService } from "../src/services/SocialService.js";

describe("End-to-End Workflow Tests", () => {
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
      translate: mock.fn(),
    };

    const originalGetTranslateClient = TranslationService.getTranslateClient;
    TranslationService.getTranslateClient = mock.fn(() => mockTranslateClient);
    TranslationService.translate_client = mockTranslateClient;

    // Mock Google TTS
    mockTTSService = {
      synthesizeSpeech: mock.fn(),
      prepareContentForTTS: mock.fn(),
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
    buffer.write("RIFF", 0);
    buffer.writeUInt32LE(size - 8, 4);
    buffer.write("WAVE", 8);
    buffer.write("data", 36);
    buffer.writeUInt32LE(size - 44, 40);
    return buffer;
  }

  describe("Full Content Pipeline Workflow", () => {
    // REMOVED: Tests using non-existent AudioService.generateAllAudio method

    it("should maintain data consistency across workflow steps", async (t) => {
      // Create content with specific metadata
      const contentId = "2025-07-02-consistency-test";
      const sourceContent = await ContentManager.createSource(
        contentId,
        "ethereum",
        "Ethereum升級測試",
        "這是一個用於測試數據一致性的以太坊內容",
        ["Ethereum Foundation", "Vitalik Blog"],
      );

      // Review content
      await ContentManager.updateSourceStatus(contentId, "reviewed");

      // Setup successful translation
      mockTranslateClient.translate.mock.mockImplementation((text, options) => {
        return Promise.resolve([`Translated: ${text} (${options.to})`]);
      });

      // Translate content
      await TranslationService.translateAll(contentId);

      // Verify data consistency across all language versions
      const allVersions = await ContentManager.getAllLanguagesForId(contentId);

      assert.strictEqual(allVersions.length, 3); // zh-TW, en-US, ja-JP

      allVersions.forEach((version) => {
        assert.strictEqual(version.id, contentId);
        assert.strictEqual(version.category, "ethereum");
        assert.strictEqual(version.date, sourceContent.date);
        assert(version.updated_at);

        // All should have same feedback structure
        assert(version.feedback);
        assert.strictEqual(version.feedback.content_review, null);
      });

      // Verify source retains original references
      const updatedSource = await ContentManager.readSource(contentId);
      assert.deepStrictEqual(updatedSource.references, [
        "Ethereum Foundation",
        "Vitalik Blog",
      ]);
    });
  });

  describe("Workflow Status Transitions", () => {
    // REMOVED: Tests using non-existent AudioService.generateAllAudio method

    it("should track status changes with timestamps", async (t) => {
      const contentId = "2025-07-02-timestamp-test";

      const beforeCreate = new Date().toISOString();
      const sourceContent = await ContentManager.createSource(
        contentId,
        "daily-news",
        "Timestamp Test",
        "Testing timestamp tracking",
        [],
      );
      const afterCreate = new Date().toISOString();

      assert(sourceContent.updated_at >= beforeCreate);
      assert(sourceContent.updated_at <= afterCreate);

      // Add small delay to ensure different timestamps
      await new Promise((resolve) => setTimeout(resolve, 1));

      // Update status and verify timestamp changes
      const beforeUpdate = new Date().toISOString();
      await ContentManager.updateSourceStatus(contentId, "reviewed");
      const afterUpdate = new Date().toISOString();

      const updatedContent = await ContentManager.readSource(contentId);
      assert(updatedContent.updated_at >= beforeUpdate);
      assert(updatedContent.updated_at <= afterUpdate);
      assert(updatedContent.updated_at > sourceContent.updated_at);
    });
  });

  describe("Error Recovery and Resilience", () => {
    it("should recover from partial translation failures", async (t) => {
      const contentId = "2025-07-02-recovery-test";

      await ContentManager.createSource(
        contentId,
        "daily-news",
        "Recovery Test",
        "Testing error recovery",
        [],
      );
      await ContentManager.updateSourceStatus(contentId, "reviewed");

      // Mock partial failure using explicit sequence for CI reliability
      // English calls succeed (title and content)
      mockTranslateClient.translate.mock.mockImplementation((text, options) => {
        if (options.to === "en") {
          return Promise.resolve([`English: ${text}`]);
        } else if (options.to === "ja") {
          throw new Error(
            "Japanese translation service temporarily unavailable",
          );
        }
        return Promise.resolve([text]);
      });

      const results = await TranslationService.translateAll(contentId);

      // English should succeed
      assert.strictEqual(
        results["en-US"].translatedTitle,
        "English: Recovery Test",
      );

      // Japanese should fail
      assert(results["ja-JP"].error);
      assert(results["ja-JP"].error.includes("Japanese translation service"));

      // Source should remain in reviewed status (not fully translated)
      const sourceContent = await ContentManager.readSource(contentId);
      assert.strictEqual(sourceContent.status, "reviewed");

      // Retry with fixed service
      mockTranslateClient.translate.mock.mockImplementation((text, options) => {
        return Promise.resolve([`${options.to}: ${text}`]);
      });

      // Retry just the failed language
      const retryResult = await TranslationService.translate(
        contentId,
        "ja-JP",
      );
      assert.strictEqual(retryResult.translatedTitle, "ja: Recovery Test");

      // Now all translations complete, source should update to translated
      const finalSource = await ContentManager.readSource(contentId);
      assert.strictEqual(finalSource.status, "translated");
    });
  });

  describe("Content Validation Throughout Workflow", () => {
    it("should validate content schema at each step", async (t) => {
      const contentId = "2025-07-02-validation-test";

      // Create valid content
      const sourceContent = await ContentManager.createSource(
        contentId,
        "daily-news",
        "Validation Test",
        "Testing schema validation",
        [],
      );

      // Should pass validation
      assert.doesNotThrow(() => ContentSchema.validate(sourceContent));

      // Update status and re-validate
      await ContentManager.updateSourceStatus(contentId, "reviewed");
      const reviewedContent = await ContentManager.readSource(contentId);
      assert.doesNotThrow(() => ContentSchema.validate(reviewedContent));

      // Setup translation and validate translation files
      mockTranslateClient.translate.mock.mockImplementation((text) => {
        return Promise.resolve([`Translated: ${text}`]);
      });

      await TranslationService.translate(contentId, "en-US");
      const translatedContent = await ContentManager.read(contentId, "en-US");
      assert.doesNotThrow(() => ContentSchema.validate(translatedContent));

      // Verify all required fields are preserved
      assert.strictEqual(translatedContent.id, contentId);
      assert.strictEqual(translatedContent.category, "daily-news");
      assert.strictEqual(translatedContent.language, "en-US");
      assert(translatedContent.title);
      assert(translatedContent.content);
      assert(translatedContent.feedback);
    });

    it("should handle malformed content gracefully", async (t) => {
      // Create content file with missing required fields
      const malformedContent = {
        id: "2025-07-02-malformed",
        status: "draft",
        // Missing category, date, language, etc.
        title: "Malformed Content",
        content: "This content is missing required fields",
      };

      const contentDir = path.join(tempDir, "zh-TW", "daily-news");
      await fs.mkdir(contentDir, { recursive: true });
      await fs.writeFile(
        path.join(contentDir, "2025-07-02-malformed.json"),
        JSON.stringify(malformedContent, null, 2),
      );

      // ContentManager should handle malformed content gracefully
      const allContent = await ContentManager.list();

      // Should include malformed content but it should fail validation if used
      const malformed = allContent.find((c) => c.id === "2025-07-02-malformed");
      assert(malformed); // Content exists but is malformed

      // Attempting to validate should throw an error due to missing fields
      assert.throws(() => {
        ContentSchema.validate(malformed);
      });
    });
  });
});
