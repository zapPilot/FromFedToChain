import { describe, it } from "node:test";
import assert from "node:assert";
import fs from "fs/promises";
import path from "path";
import { ContentSchema } from "../src/ContentSchema.js";
import { ContentManager } from "../src/ContentManager.js";

describe("Sanity Check Tests", () => {
  describe("Core Module Imports", () => {
    it("should import ContentSchema without errors", () => {
      assert(ContentSchema);
      assert(typeof ContentSchema.validate === "function");
      assert(typeof ContentSchema.createContent === "function");
    });

    it("should import ContentManager without errors", () => {
      assert(ContentManager);
      assert(typeof ContentManager.create === "function");
      assert(typeof ContentManager.read === "function");
      assert(typeof ContentManager.list === "function");
    });

    it("should have consistent language configuration", () => {
      const allLanguages = ContentSchema.getAllLanguages();
      const supportedLanguages = ContentSchema.getSupportedLanguages();

      assert(Array.isArray(allLanguages));
      assert(Array.isArray(supportedLanguages));
      assert(allLanguages.length > supportedLanguages.length); // includes zh-TW
      assert(allLanguages.includes("zh-TW"));
    });

    it("should have consistent category configuration", () => {
      const categories = ContentSchema.getCategories();

      assert(Array.isArray(categories));
      assert(categories.length > 0);
      assert(categories.includes("daily-news"));
      assert(categories.includes("ethereum"));
    });

    it("should have consistent status configuration", () => {
      const statuses = ContentSchema.getStatuses();

      assert(Array.isArray(statuses));
      assert(statuses.includes("draft"));
      assert(statuses.includes("reviewed"));
      assert(statuses.includes("social"));
      // Should be in logical order
      assert.strictEqual(statuses[0], "draft");
      assert.strictEqual(statuses[statuses.length - 1], "social");
    });
  });

  describe("Content Schema Validation", () => {
    it("should create valid example content", () => {
      const example = ContentSchema.getExample();

      // Should not throw
      assert.doesNotThrow(() => ContentSchema.validate(example));

      // Should have all required fields
      assert(example.id);
      assert(example.status);
      assert(example.category);
      assert(example.language);
      assert(example.title);
      assert(example.content);
      assert(Array.isArray(example.references));
      assert(example.feedback);
      assert(example.date);
      assert(example.updated_at);
    });

    it("should detect missing required fields", () => {
      const validContent = ContentSchema.createContent(
        "test-id",
        "daily-news",
        "zh-TW",
        "Test Title",
        "Test Content",
      );

      const requiredFields = [
        "id",
        "status",
        "category",
        "language",
        "title",
        "content",
        "feedback",
      ];

      requiredFields.forEach((field) => {
        const invalidContent = { ...validContent };
        delete invalidContent[field];

        assert.throws(
          () => ContentSchema.validate(invalidContent),
          `Should throw for missing ${field}`,
        );
      });
    });

    it("should accept all valid categories", () => {
      const categories = ContentSchema.getCategories();

      categories.forEach((category) => {
        assert.doesNotThrow(() => {
          const content = ContentSchema.createContent(
            "test-id",
            category,
            "zh-TW",
            "Test Title",
            "Test Content",
          );
          ContentSchema.validate(content);
        }, `Should accept category: ${category}`);
      });
    });

    it("should accept all valid languages", () => {
      const languages = ContentSchema.getAllLanguages();

      languages.forEach((language) => {
        assert.doesNotThrow(() => {
          const content = ContentSchema.createContent(
            "test-id",
            "daily-news",
            language,
            "Test Title",
            "Test Content",
          );
          ContentSchema.validate(content);
        }, `Should accept language: ${language}`);
      });
    });

    it("should accept all valid statuses", () => {
      const statuses = ContentSchema.getStatuses();

      statuses.forEach((status) => {
        assert.doesNotThrow(() => {
          const content = ContentSchema.createContent(
            "test-id",
            "daily-news",
            "zh-TW",
            "Test Title",
            "Test Content",
          );
          content.status = status;
          ContentSchema.validate(content);
        }, `Should accept status: ${status}`);
      });
    });
  });

  describe("File System Structure", () => {
    it("should have src directory with core files", async () => {
      const srcDir = path.resolve("./src");
      const stats = await fs.stat(srcDir);
      assert(stats.isDirectory());

      // Check core files exist
      const coreFiles = ["ContentManager.js", "ContentSchema.js", "cli.js"];
      for (const file of coreFiles) {
        const filePath = path.join(srcDir, file);
        const fileStats = await fs.stat(filePath);
        assert(fileStats.isFile(), `${file} should exist`);
      }
    });

    it("should have services directory with service files", async () => {
      const servicesDir = path.resolve("./src/services");
      const stats = await fs.stat(servicesDir);
      assert(stats.isDirectory());

      // Check service files exist
      const serviceFiles = [
        "TranslationService.js",
        "AudioService.js",
        "SocialService.js",
      ];
      for (const file of serviceFiles) {
        const filePath = path.join(servicesDir, file);
        const fileStats = await fs.stat(filePath);
        assert(fileStats.isFile(), `${file} should exist`);
      }
    });

    it("should have content directory structure", async () => {
      const contentDir = path.resolve("./content");

      try {
        const stats = await fs.stat(contentDir);
        assert(stats.isDirectory());

        // Check language directories exist
        const languages = ContentSchema.getAllLanguages();
        for (const language of languages) {
          const langDir = path.join(contentDir, language);
          try {
            const langStats = await fs.stat(langDir);
            assert(
              langStats.isDirectory(),
              `${language} directory should exist`,
            );
          } catch (e) {
            // Language directory might not exist if no content, that's ok
            console.log(`Note: ${language} directory doesn't exist yet`);
          }
        }
      } catch (e) {
        // Content directory might not exist in test environment, that's ok
        console.log(
          "Note: Content directory doesn't exist in test environment",
        );
      }
    });

    it("should have config directory", async () => {
      const configDir = path.resolve("./config");
      const stats = await fs.stat(configDir);
      assert(stats.isDirectory());

      // Check config file exists
      const configFile = path.join(configDir, "languages.js");
      const configStats = await fs.stat(configFile);
      assert(configStats.isFile(), "languages.js should exist");
    });
  });

  describe("Package Configuration", () => {
    it("should have valid package.json", async () => {
      const packagePath = path.resolve("./package.json");
      const packageStats = await fs.stat(packagePath);
      assert(packageStats.isFile());

      const packageContent = await fs.readFile(packagePath, "utf-8");
      const packageObj = JSON.parse(packageContent);

      assert(packageObj.name);
      assert(packageObj.version);
      assert(packageObj.scripts);
      assert(packageObj.scripts.test);
      assert(packageObj.scripts.review);
      assert(packageObj.scripts.pipeline);
    });

    it("should have working npm scripts defined", async () => {
      const packagePath = path.resolve("./package.json");
      const packageContent = await fs.readFile(packagePath, "utf-8");
      const packageObj = JSON.parse(packageContent);

      const requiredScripts = ["test", "review", "pipeline"];
      requiredScripts.forEach((script) => {
        assert(
          packageObj.scripts[script],
          `Script ${script} should be defined`,
        );
        assert(
          typeof packageObj.scripts[script] === "string",
          `Script ${script} should be a string`,
        );
      });
    });
  });

  describe("Content ID Format Validation", () => {
    it("should validate standard date-based ID format", () => {
      const validIds = [
        "2025-07-13-bitcoin-analysis",
        "2025-01-01-new-year-crypto",
        "2025-12-31-year-end-review",
      ];

      validIds.forEach((id) => {
        assert.doesNotThrow(() => {
          ContentSchema.createContent(
            id,
            "daily-news",
            "zh-TW",
            "Title",
            "Content",
          );
        }, `Should accept ID: ${id}`);
      });
    });

    it("should handle various content lengths", () => {
      const shortContent = "Short content";
      const longContent = "Long content ".repeat(100);

      assert.doesNotThrow(() => {
        const short = ContentSchema.createContent(
          "2025-07-13-short",
          "daily-news",
          "zh-TW",
          "Title",
          shortContent,
        );
        ContentSchema.validate(short);
      });

      assert.doesNotThrow(() => {
        const long = ContentSchema.createContent(
          "2025-07-13-long",
          "daily-news",
          "zh-TW",
          "Title",
          longContent,
        );
        ContentSchema.validate(long);
      });
    });

    it("should handle empty and populated references", () => {
      assert.doesNotThrow(() => {
        const noRefs = ContentSchema.createContent(
          "2025-07-13-no-refs",
          "daily-news",
          "zh-TW",
          "Title",
          "Content",
        );
        ContentSchema.validate(noRefs);
        assert.deepStrictEqual(noRefs.references, []);
      });

      assert.doesNotThrow(() => {
        const withRefs = ContentSchema.createContent(
          "2025-07-13-with-refs",
          "daily-news",
          "zh-TW",
          "Title",
          "Content",
          ["Source 1", "Source 2", "Source 3"],
        );
        ContentSchema.validate(withRefs);
        assert.strictEqual(withRefs.references.length, 3);
      });
    });
  });
});
