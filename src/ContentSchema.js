// Single source of truth for content schema
// This file defines the content structure and provides utilities for content creation

export class ContentSchema {
  // Create a new content object for single language
  static createContent(
    id,
    category,
    language,
    title,
    content,
    references = [],
  ) {
    return {
      id,
      status: "draft",
      category,
      date: new Date().toISOString().split("T")[0],
      language,
      title,
      content,
      references,
      audio_file: null,
      social_hook: null,
      feedback: {
        content_review: null,
      },
      updated_at: new Date().toISOString(),
    };
  }

  // Get supported languages
  static getSupportedLanguages() {
    return ["en-US", "ja-JP"];
  }

  // Get content categories
  static getCategories() {
    return ["daily-news", "ethereum", "macro", "startup", "ai", "defi"];
  }

  // Get status workflow states
  static getStatuses() {
    return ["draft", "reviewed", "translated", "wav", "m3u8", "cloudflare", "social"];
  }

  // Get supported social platforms
  static getSocialPlatforms() {
    return ["twitter", "threads", "farcaster", "debank"];
  }

  // Basic validation for single-language content structure
  static validate(content) {
    const required = [
      "id",
      "status",
      "category",
      "date",
      "language",
      "title",
      "content",
      "references",
      "feedback",
      "updated_at",
    ];

    for (const field of required) {
      if (!(field in content)) {
        throw new Error(`Missing required field: ${field}`);
      }
    }

    if (!this.getCategories().includes(content.category)) {
      throw new Error(`Invalid category: ${content.category}`);
    }

    if (!this.getStatuses().includes(content.status)) {
      throw new Error(`Invalid status: ${content.status}`);
    }

    const allLanguages = ["zh-TW", ...this.getSupportedLanguages()];
    if (!allLanguages.includes(content.language)) {
      throw new Error(`Invalid language: ${content.language}`);
    }

    if (!content.title || !content.content) {
      throw new Error("Title and content are required");
    }

    return true;
  }

  // Example content for reference
  static getExample() {
    return this.createContent(
      "2025-06-30-example-content",
      "daily-news",
      "zh-TW",
      "Example Bitcoin Analysis",
      "This is example content about Bitcoin trends...",
      ["Example Source 1", "Example Source 2"],
    );
  }

  // Helper method to get all supported languages including source language
  static getAllLanguages() {
    return ["zh-TW", ...this.getSupportedLanguages()];
  }
}
