import { describe, it, beforeEach, afterEach } from "node:test";
import assert from "node:assert";
import fs from "fs/promises";
import path from "path";
import { TestUtils } from "./setup.js";
import { ContentManager } from "../src/ContentManager.js";
import { ContentSchema } from "../src/ContentSchema.js";

describe("ContentManager Nested Structure Tests", () => {
  let tempDir;
  let originalContentDir;

  beforeEach(async () => {
    tempDir = await TestUtils.createTempDir();
    originalContentDir = ContentManager.CONTENT_DIR;
    ContentManager.CONTENT_DIR = tempDir;

    // Create proper nested structure with real content
    const testContent = {
      id: "2025-07-01-test-content",
      status: "draft",
      category: "daily-news",
      date: "2025-07-01",
      language: "zh-TW",
      title: "測試文章標題",
      content: "這是一篇測試文章的內容...",
      references: ["測試來源1", "測試來源2"],
      audio_file: null,
      social_hook: null,
      feedback: {
        content_review: null,
        ai_outputs: {},
        performance_metrics: {},
      },
      updated_at: new Date().toISOString(),
    };

    // Create nested directory structure
    const sourceDir = path.join(tempDir, "zh-TW", "daily-news");
    await fs.mkdir(sourceDir, { recursive: true });

    // Write content file
    const filePath = path.join(sourceDir, `${testContent.id}.json`);
    await fs.writeFile(filePath, JSON.stringify(testContent, null, 2));
  });

  afterEach(async () => {
    ContentManager.CONTENT_DIR = originalContentDir;
    await TestUtils.cleanupTempDir(tempDir);
  });

  describe("Folder Structure Validation", () => {
    it("should find content in nested zh-TW/daily-news structure", async () => {
      const contents = await ContentManager.list();
      assert.equal(contents.length, 1);
      assert.equal(contents[0].id, "2025-07-01-test-content");
      assert.equal(contents[0].language, "zh-TW");
      assert.equal(contents[0].category, "daily-news");
    });

    it("should read content by ID across nested structure", async () => {
      const content = await ContentManager.read("2025-07-01-test-content");
      assert.equal(content.title, "測試文章標題");
      assert.equal(content.language, "zh-TW");
      assert.equal(content.category, "daily-news");
    });

    it("should read content by ID and specific language", async () => {
      const content = await ContentManager.read(
        "2025-07-01-test-content",
        "zh-TW",
      );
      assert.equal(content.title, "測試文章標題");
      assert.equal(content.language, "zh-TW");
    });

    it("should throw error when content not found", async () => {
      try {
        await ContentManager.read("non-existent-content");
        assert.fail("Should have thrown an error");
      } catch (error) {
        assert(error.message.includes("Content not found"));
      }
    });
  });

  describe("Source Content Operations", () => {
    it("should get source content by status", async () => {
      const drafts = await ContentManager.getSourceByStatus("draft");
      assert.equal(drafts.length, 1);
      assert.equal(drafts[0].language, "zh-TW");
      assert.equal(drafts[0].status, "draft");
    });

    it("should create source content correctly", async () => {
      const newContent = await ContentManager.createSource(
        "2025-07-01-new-test",
        "ethereum",
        "新測試文章",
        "新的測試內容...",
        ["新來源"],
      );

      assert.equal(newContent.language, "zh-TW");
      assert.equal(newContent.category, "ethereum");
      assert.equal(newContent.status, "draft");

      // Verify file was created in correct location
      const filePath = path.join(
        tempDir,
        "zh-TW",
        "ethereum",
        "2025-07-01-new-test.json",
      );
      const fileExists = await fs
        .access(filePath)
        .then(() => true)
        .catch(() => false);
      assert(fileExists, "File should exist in zh-TW/ethereum/");
    });

    it("should update source content status", async () => {
      await ContentManager.updateSourceStatus(
        "2025-07-01-test-content",
        "reviewed",
      );

      const content = await ContentManager.readSource(
        "2025-07-01-test-content",
      );
      assert.equal(content.status, "reviewed");
    });
  });

  describe("Translation Operations", () => {
    it("should create translation file in correct nested structure", async () => {
      const translation = await ContentManager.addTranslation(
        "2025-07-01-test-content",
        "en-US",
        "Test Article Title",
        "This is test article content...",
      );

      assert.equal(translation.language, "en-US");
      assert.equal(translation.status, "translated");
      assert.equal(translation.title, "Test Article Title");

      // Verify file was created in correct location
      const filePath = path.join(
        tempDir,
        "en-US",
        "daily-news",
        "2025-07-01-test-content.json",
      );
      const fileExists = await fs
        .access(filePath)
        .then(() => true)
        .catch(() => false);
      assert(fileExists, "Translation file should exist in en-US/daily-news/");
    });

    it("should list available languages for content ID", async () => {
      // Add English translation
      await ContentManager.addTranslation(
        "2025-07-01-test-content",
        "en-US",
        "Test Title",
        "Test content...",
      );

      const languages = await ContentManager.getAvailableLanguages(
        "2025-07-01-test-content",
      );
      assert(languages.includes("zh-TW"));
      assert(languages.includes("en-US"));
      assert.equal(languages.length, 2);
    });

    it("should get all language versions of content", async () => {
      // Add translation
      await ContentManager.addTranslation(
        "2025-07-01-test-content",
        "en-US",
        "Test Title",
        "Test content...",
      );

      const allVersions = await ContentManager.getAllLanguagesForId(
        "2025-07-01-test-content",
      );
      assert.equal(allVersions.length, 2);

      const languages = allVersions.map((v) => v.language);
      assert(languages.includes("zh-TW"));
      assert(languages.includes("en-US"));
    });
  });

  describe("Audio and Social Hook Operations", () => {
    beforeEach(async () => {
      // Create English translation for testing
      await ContentManager.addTranslation(
        "2025-07-01-test-content",
        "en-US",
        "Test Title",
        "Test content...",
      );
    });

    it("should add audio file to specific language", async () => {
      const audioPath = "audio/en-US/2025-07-01-test-content.wav";

      await ContentManager.addAudio(
        "2025-07-01-test-content",
        "en-US",
        audioPath,
      );

      const content = await ContentManager.read(
        "2025-07-01-test-content",
        "en-US",
      );
      assert.equal(content.audio_file, audioPath);
    });

    it("should add social hook to specific language", async () => {
      const hook = "Test social hook for sharing!";

      await ContentManager.addSocialHook(
        "2025-07-01-test-content",
        "en-US",
        hook,
      );

      const content = await ContentManager.read(
        "2025-07-01-test-content",
        "en-US",
      );
      assert.equal(content.social_hook, hook);
    });
  });

  describe("Feedback Operations", () => {
    it("should add content review feedback to source file", async () => {
      await ContentManager.addContentFeedback(
        "2025-07-01-test-content",
        "accepted",
        4,
        "test_reviewer",
        "Good content",
        { quality: 4 },
      );

      const content = await ContentManager.readSource(
        "2025-07-01-test-content",
      );
      assert.equal(content.feedback.content_review.status, "accepted");
      assert.equal(content.feedback.content_review.comments, "Good content");
      assert.equal(content.feedback.content_review.score, 4);
    });

  });

  describe("Performance and Edge Cases", () => {
    it("should handle empty directories gracefully", async () => {
      // Get initial count
      const initialContents = await ContentManager.list();
      const initialCount = initialContents.length;

      // Create empty category directory
      await fs.mkdir(path.join(tempDir, "ja-JP", "macro"), { recursive: true });

      const contents = await ContentManager.list();
      assert.equal(contents.length, initialCount); // Should not change count
    });

    it("should handle corrupted files gracefully", async () => {
      // Get initial count
      const initialContents = await ContentManager.list();
      const initialCount = initialContents.length;

      // Create corrupted file
      const corruptedDir = path.join(tempDir, "zh-TW", "macro");
      await fs.mkdir(corruptedDir, { recursive: true });
      await fs.writeFile(
        path.join(corruptedDir, "corrupted.json"),
        "{ invalid json }",
      );

      const contents = await ContentManager.list();
      assert.equal(contents.length, initialCount); // Should skip corrupted file and not change count
    });

    it("should prevent access outside nested structure", async () => {
      try {
        await ContentManager._readFromLanguage(
          "2025-07-01-test-content",
          "invalid-language",
        );
        assert.fail("Should have thrown an error");
      } catch (error) {
        assert(error.message.includes("Content not found"));
      }
    });
  });
});
