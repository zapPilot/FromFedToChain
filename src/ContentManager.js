import fs from "fs/promises";
import path from "path";
import chalk from "chalk";
import { ContentSchema } from "./ContentSchema.js";

export class ContentManager {
  static CONTENT_DIR = "./content";
  static AUDIO_DIR = "./audio";

  // Create new content using schema
  static async create(id, category, title, content, references = []) {
    const contentData = ContentSchema.createContent(id, category, title, content, references);
    
    // Validate the content
    ContentSchema.validate(contentData);

    const filePath = path.join(this.CONTENT_DIR, `${id}.json`);
    await fs.writeFile(filePath, JSON.stringify(contentData, null, 2));
    
    console.log(chalk.green(`✅ Created content: ${id}`));
    return contentData;
  }

  // Read content by ID
  static async read(id) {
    const filePath = path.join(this.CONTENT_DIR, `${id}.json`);
    try {
      const content = await fs.readFile(filePath, 'utf-8');
      const parsed = JSON.parse(content);
      
      // Validate content on read (helps catch schema issues)
      try {
        ContentSchema.validate(parsed);
      } catch (validationError) {
        console.warn(chalk.yellow(`⚠️ Schema validation warning for ${id}: ${validationError.message}`));
      }
      
      return parsed;
    } catch (error) {
      throw new Error(`Content not found: ${id}`);
    }
  }

  // Validate content against schema
  static validateContent(content) {
    return ContentSchema.validate(content);
  }

  // Get schema constants (no longer async)
  static getSchemaInfo() {
    return {
      categories: ContentSchema.getCategories(),
      languages: ContentSchema.getSupportedLanguages(),
      statuses: ContentSchema.getStatuses(),
      platforms: ContentSchema.getSocialPlatforms()
    };
  }

  // Get supported languages, categories, etc.
  static getSupportedLanguages() {
    return ContentSchema.getSupportedLanguages();
  }

  static getCategories() {
    return ContentSchema.getCategories();
  }

  static getStatuses() {
    return ContentSchema.getStatuses();
  }

  // Update content
  static async update(id, updates) {
    const content = await this.read(id);
    const updatedContent = {
      ...content,
      ...updates,
      updated_at: new Date().toISOString()
    };

    const filePath = path.join(this.CONTENT_DIR, `${id}.json`);
    await fs.writeFile(filePath, JSON.stringify(updatedContent, null, 2));
    
    return updatedContent;
  }

  // List all content with optional status filter
  static async list(status = null) {
    try {
      const files = await fs.readdir(this.CONTENT_DIR);
      const contentFiles = files.filter(f => f.endsWith('.json'));
      
      const contents = [];
      for (const file of contentFiles) {
        try {
          const content = await this.read(path.basename(file, '.json'));
          if (!status || content.status === status) {
            contents.push(content);
          }
        } catch (e) {
          // Skip invalid files
        }
      }

      return contents.sort((a, b) => new Date(b.date) - new Date(a.date));
    } catch (error) {
      return [];
    }
  }

  // Get content needing specific processing
  static async getByStatus(status) {
    return this.list(status);
  }

  // Update status
  static async updateStatus(id, status) {
    return this.update(id, { status });
  }

  // Add translation
  static async addTranslation(id, language, title, content) {
    const contentData = await this.read(id);
    
    if (!contentData.translations) {
      contentData.translations = {};
    }
    
    contentData.translations[language] = {
      title,
      content,
      audio_file: null,
      social_hook: null
    };

    return this.update(id, contentData);
  }

  // Add audio file path
  static async addAudio(id, language, audioPath) {
    const contentData = await this.read(id);
    
    if (contentData.translations[language]) {
      contentData.translations[language].audio_file = audioPath;
      return this.update(id, contentData);
    }
    
    throw new Error(`Translation not found for ${language}`);
  }

  // Add social hook
  static async addSocialHook(id, language, hook) {
    const contentData = await this.read(id);
    
    if (contentData.translations[language]) {
      contentData.translations[language].social_hook = hook;
      return this.update(id, contentData);
    }
    
    throw new Error(`Translation not found for ${language}`);
  }

  // Add feedback for content review
  static async addContentFeedback(id, status, score, reviewer, comments, trainingLabels = {}) {
    const contentData = await this.read(id);
    
    // Initialize feedback structure if missing (backward compatibility)
    if (!contentData.feedback) {
      contentData.feedback = {
        content_review: null,
        ai_outputs: { translations: {}, audio: {}, social_hooks: {} },
        performance_metrics: { spotify: {}, social_platforms: {} }
      };
    }
    
    contentData.feedback.content_review = {
      status,
      score,
      reviewer,
      timestamp: new Date().toISOString(),
      comments,
      training_labels: trainingLabels
    };

    return this.update(id, contentData);
  }

  // Add feedback for AI outputs (translation, audio, social)
  static async addAIFeedback(id, type, language, status, score, reviewer, comments, modelInfo = {}, trainingLabels = {}) {
    const contentData = await this.read(id);
    
    // Initialize feedback structure if missing
    if (!contentData.feedback) {
      contentData.feedback = {
        content_review: null,
        ai_outputs: { translations: {}, audio: {}, social_hooks: {} },
        performance_metrics: { spotify: {}, social_platforms: {} }
      };
    }
    
    if (!contentData.feedback.ai_outputs[type]) {
      contentData.feedback.ai_outputs[type] = {};
    }

    contentData.feedback.ai_outputs[type][language] = {
      status,
      score,
      reviewer,
      timestamp: new Date().toISOString(),
      comments,
      model_info: modelInfo,
      training_labels: trainingLabels
    };

    return this.update(id, contentData);
  }

  // Add performance metrics
  static async addPerformanceMetrics(id, platform, language, metrics) {
    const contentData = await this.read(id);
    
    // Initialize feedback structure if missing
    if (!contentData.feedback) {
      contentData.feedback = {
        content_review: null,
        ai_outputs: { translations: {}, audio: {}, social_hooks: {} },
        performance_metrics: { spotify: {}, social_platforms: {} }
      };
    }

    if (platform === 'spotify') {
      contentData.feedback.performance_metrics.spotify[language] = {
        ...metrics,
        measured_at: new Date().toISOString()
      };
    } else {
      if (!contentData.feedback.performance_metrics.social_platforms[platform]) {
        contentData.feedback.performance_metrics.social_platforms[platform] = {};
      }
      contentData.feedback.performance_metrics.social_platforms[platform][language] = {
        ...metrics,
        measured_at: new Date().toISOString()
      };
    }

    return this.update(id, contentData);
  }

  // Export training data format
  static async exportTrainingData(filters = {}) {
    const contents = await this.list();
    const trainingSamples = [];

    contents.forEach(content => {
      if (!content.feedback) return;

      // Export translation training data
      Object.entries(content.feedback.ai_outputs.translations || {}).forEach(([lang, feedback]) => {
        if (feedback.status === 'accepted' || feedback.status === 'rejected') {
          trainingSamples.push({
            input: {
              task: 'translation',
              source_language: 'zh-TW',
              target_language: lang,
              source_text: content.source.content,
              context: `${content.category} content, conversational style`
            },
            output: {
              generated_text: content.translations[lang]?.content,
              model_version: feedback.model_info.model,
              timestamp: feedback.timestamp
            },
            feedback: {
              rating: feedback.score,
              accepted: feedback.status === 'accepted',
              reviewer_expertise: feedback.reviewer,
              detailed_scores: feedback.training_labels,
              comments: feedback.comments
            }
          });
        }
      });

      // Export social hook training data
      Object.entries(content.feedback.ai_outputs.social_hooks || {}).forEach(([lang, feedback]) => {
        if (feedback.status === 'accepted' || feedback.status === 'rejected') {
          trainingSamples.push({
            input: {
              task: 'social_hook',
              language: lang,
              title: content.translations[lang]?.title,
              content_summary: content.translations[lang]?.content.substring(0, 500),
              context: `${content.category}, social media hook`
            },
            output: {
              generated_text: content.translations[lang]?.social_hook,
              model_version: feedback.model_info.model,
              timestamp: feedback.timestamp
            },
            feedback: {
              rating: feedback.score,
              accepted: feedback.status === 'accepted',
              reviewer_expertise: feedback.reviewer,
              detailed_scores: feedback.training_labels,
              comments: feedback.comments
            }
          });
        }
      });
    });

    return {
      export_metadata: {
        total_samples: trainingSamples.length,
        export_date: new Date().toISOString(),
        filters_applied: filters
      },
      training_samples: trainingSamples
    };
  }

  // Get content summary for CLI display
  static formatSummary(content) {
    const { id, status, category, date, source, translations, feedback } = content;
    const translationCount = Object.keys(translations || {}).length;
    const audioCount = Object.values(translations || {}).filter(t => t.audio_file).length;
    const socialCount = Object.values(translations || {}).filter(t => t.social_hook).length;
    
    // Count feedback items
    const feedbackCount = feedback ? (
      (feedback.content_review ? 1 : 0) +
      Object.keys(feedback.ai_outputs.translations || {}).length +
      Object.keys(feedback.ai_outputs.audio || {}).length +
      Object.keys(feedback.ai_outputs.social_hooks || {}).length
    ) : 0;
    
    return {
      id: id.substring(0, 30) + (id.length > 30 ? '...' : ''),
      status,
      category,
      date,
      title: source.title.substring(0, 40) + (source.title.length > 40 ? '...' : ''),
      translations: translationCount,
      audio: audioCount,
      social: socialCount,
      feedback: feedbackCount
    };
  }
}