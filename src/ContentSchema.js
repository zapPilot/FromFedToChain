// Single source of truth for content schema
// This file defines the content structure and provides utilities for content creation

export class ContentSchema {

  // Create a new content object following the schema
  static createContent(id, category, title, content, references = []) {
    return {
      id,
      status: "draft",
      category,
      date: new Date().toISOString().split('T')[0],
      source: {
        title,
        content,
        references
      },
      translations: {},
      feedback: {
        content_review: null,
        ai_outputs: {
          translations: {},
          audio: {},
          social_hooks: {}
        },
        performance_metrics: {
          spotify: {},
          social_platforms: {}
        }
      },
      updated_at: new Date().toISOString()
    };
  }

  // Get supported languages
  static getSupportedLanguages() {
    return ['en-US', 'ja-JP'];
  }

  // Get content categories
  static getCategories() {
    return ['daily-news', 'ethereum', 'macro'];
  }

  // Get status workflow states
  static getStatuses() {
    return ['draft', 'reviewed', 'translated', 'audio', 'social', 'published'];
  }

  // Get supported social platforms
  static getSocialPlatforms() {
    return ['twitter', 'threads', 'farcaster', 'debank'];
  }

  // Basic validation (for simple cases, full JSON Schema validation would need a library)
  static validate(content) {
    const required = ['id', 'status', 'category', 'date', 'source', 'translations', 'feedback', 'updated_at'];
    
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

    if (!content.source || !content.source.title || !content.source.content) {
      throw new Error('Invalid source content structure');
    }

    return true;
  }

  // Example content for reference
  static getExample() {
    return this.createContent(
      '2025-06-30-example-content',
      'daily-news',
      'Example Bitcoin Analysis',
      'This is example content about Bitcoin trends...',
      ['Example Source 1', 'Example Source 2']
    );
  }
}