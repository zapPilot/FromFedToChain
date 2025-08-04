import { describe, it, beforeEach, afterEach } from "node:test";
import assert from "node:assert";
import fs from "fs/promises";
import path from "path";
import { TestUtils } from "./setup.js";
import { ContentManager } from "../src/ContentManager.js";

describe("ContentManager Nested Structure Tests (Robust)", () => {
  let tempDir;
  let originalContentDir;

  beforeEach(async () => {
    tempDir = await TestUtils.createTempDir();
    originalContentDir = ContentManager.CONTENT_DIR;
    ContentManager.CONTENT_DIR = tempDir;

    // Create proper nested structure with simplified content
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

  describe("Basic Operations", () => {
    it("should find content in nested structure", async () => {
      const contents = await ContentManager.list();
      assert.equal(contents.length, 1);
      assert.equal(contents[0].id, "2025-07-01-test-content");
    });

    it("should read content by ID", async () => {
      const content = await ContentManager.read("2025-07-01-test-content");
      assert.equal(content.title, "測試文章標題");
      assert.equal(content.language, "zh-TW");
    });

    it("should read content by ID and language", async () => {
      const content = await ContentManager.read(
        "2025-07-01-test-content",
        "zh-TW",
      );
      assert.equal(content.title, "測試文章標題");
    });

    it("should throw error for non-existent content", async () => {
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
      assert.equal(drafts[0].status, "draft");
    });

    it("should create source content", async () => {
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

      // Verify file was created
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
      assert(fileExists, "File should exist");
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
    it("should create translation", async () => {
      const translation = await ContentManager.addTranslation(
        "2025-07-01-test-content",
        "en-US",
        "Test Article Title",
        "This is test article content...",
      );

      assert.equal(translation.language, "en-US");
      assert.equal(translation.status, "translated");
      assert.equal(translation.title, "Test Article Title");

      // Verify file was created
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
      assert(fileExists, "Translation file should exist");
    });

    it("should list available languages", async () => {
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

    it("should get all language versions", async () => {
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

    it("should add audio file", async () => {
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

    it("should add social hook", async () => {
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
    it("should add content review feedback", async () => {
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

  describe("Error Handling", () => {
    it("should handle empty directories", async () => {
      const initialContents = await ContentManager.list();
      const initialCount = initialContents.length;

      // Create empty category directory
      await fs.mkdir(path.join(tempDir, "ja-JP", "macro"), { recursive: true });

      const contents = await ContentManager.list();
      assert.equal(contents.length, initialCount);
    });

    it("should handle corrupted files", async () => {
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
      assert.equal(contents.length, initialCount);
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
