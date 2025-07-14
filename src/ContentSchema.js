// Single source of truth for content schema
// This file defines the content structure and provides utilities for content creation

export class ContentSchema {
  // Clean content for storage - removes markdown formatting
  static cleanContent(content) {
    if (typeof content !== "string") {
      return content;
    }

    return content
      // Remove code blocks first (must be before inline code)
      .replace(/```[\s\S]*?```/g, '')       // Remove multi-line code blocks
      
      // Remove markdown formatting but preserve the text content
      .replace(/\*\*(.*?)\*\*/g, '$1')      // Remove bold: **text** -> text
      .replace(/\*(.*?)\*/g, '$1')          // Remove italic: *text* -> text
      .replace(/`([^`]*)`/g, '$1')          // Remove inline code: `text` -> text (improved)
      .replace(/#{1,6}\s+/g, '')            // Remove headers: ## Header -> Header
      .replace(/\[([^\]]+)\]\([^)]+\)/g, '$1') // Remove links: [text](url) -> text
      .replace(/^\s*[-*+]\s+/gm, '')        // Remove list markers: - item -> item
      
      // Clean up line breaks and spacing
      .replace(/\n{3,}/g, '\n\n')           // Normalize excessive line breaks
      .replace(/\n\n/g, ' ')                // Replace double newlines with space
      .replace(/\n/g, ' ')                  // Replace single newlines with space
      .replace(/\s{2,}/g, ' ')              // Collapse multiple spaces
      .trim();                              // Remove leading/trailing whitespace
  }

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
      content: this.cleanContent(content),
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
    return ["draft", "reviewed", "translated", "audio", "social"];
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
