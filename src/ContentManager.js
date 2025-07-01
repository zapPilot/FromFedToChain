import fs from "fs/promises";
import path from "path";
import chalk from "chalk";
import { ContentSchema } from "./ContentSchema.js";

export class ContentManager {
  static CONTENT_DIR = "./content";
  static AUDIO_DIR = "./audio";

  // Create new content using schema (single language file)
  static async create(id, category, language, title, content, references = []) {
    const contentData = ContentSchema.createContent(id, category, language, title, content, references);
    
    // Validate the content
    ContentSchema.validate(contentData);

    // Create nested directory structure
    const dir = path.join(this.CONTENT_DIR, language, category);
    await fs.mkdir(dir, { recursive: true });

    const filePath = path.join(dir, `${id}.json`);
    await fs.writeFile(filePath, JSON.stringify(contentData, null, 2));
    
    console.log(chalk.green(`✅ Created content: ${language}/${category}/${id}`));
    return contentData;
  }

  // Read content by ID (searches across all language/category folders)
  static async read(id, language = null) {
    if (language) {
      // If language specified, search only in that language's folders
      return this._readFromLanguage(id, language);
    }

    // Search all languages for the content
    const languages = ContentSchema.getAllLanguages();
    
    for (const lang of languages) {
      try {
        return await this._readFromLanguage(id, lang);
      } catch (error) {
        // Continue searching in other languages
      }
    }
    
    throw new Error(`Content not found: ${id}`);
  }

  // Helper method to read content from a specific language
  static async _readFromLanguage(id, language) {
    const categories = ContentSchema.getCategories();
    
    for (const category of categories) {
      const filePath = path.join(this.CONTENT_DIR, language, category, `${id}.json`);
      try {
        const content = await fs.readFile(filePath, 'utf-8');
        const parsed = JSON.parse(content);
        
        // Validate content on read (helps catch schema issues)
        try {
          ContentSchema.validate(parsed);
        } catch (validationError) {
          console.warn(chalk.yellow(`⚠️ Schema validation warning for ${language}/${category}/${id}: ${validationError.message}`));
        }
        
        return parsed;
      } catch (error) {
        // Continue searching in other categories
      }
    }
    
    throw new Error(`Content not found in ${language}: ${id}`);
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

  // Update content (finds existing file and updates it)
  static async update(id, updates, language = null) {
    const content = await this.read(id, language);
    const updatedContent = {
      ...content,
      ...updates,
      updated_at: new Date().toISOString()
    };

    // Find the correct file path
    const filePath = path.join(this.CONTENT_DIR, content.language, content.category, `${id}.json`);
    await fs.writeFile(filePath, JSON.stringify(updatedContent, null, 2));
    
    return updatedContent;
  }

  // List all content with optional status filter (scans nested folders)
  static async list(status = null, language = null) {
    try {
      const contents = [];
      const languages = language ? [language] : ContentSchema.getAllLanguages();
      const categories = ContentSchema.getCategories();

      for (const lang of languages) {
        for (const category of categories) {
          const categoryDir = path.join(this.CONTENT_DIR, lang, category);
          
          try {
            const files = await fs.readdir(categoryDir);
            const contentFiles = files.filter(f => f.endsWith('.json'));
            
            for (const file of contentFiles) {
              try {
                const id = path.basename(file, '.json');
                const content = await this._readFromLanguage(id, lang);
                
                if (!status || content.status === status) {
                  contents.push(content);
                }
              } catch (e) {
                // Skip invalid files
                console.warn(chalk.yellow(`⚠️ Skipping invalid file: ${lang}/${category}/${file}`));
              }
            }
          } catch (error) {
            // Category directory doesn't exist - skip
          }
        }
      }

      return contents.sort((a, b) => new Date(b.date) - new Date(a.date));
    } catch (error) {
      console.error(chalk.red(`❌ Error listing content: ${error.message}`));
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

  // Add translation (creates new file in target language)
  static async addTranslation(id, targetLanguage, title, content) {
    // Read source content to get category and references
    const sourceContent = await this.read(id, 'zh-TW');
    
    // Create new translation file
    const translationData = ContentSchema.createContent(
      id,
      sourceContent.category,
      targetLanguage,
      title,
      content,
      sourceContent.references
    );
    
    // Set status to translated
    translationData.status = 'translated';

    // Create directory and save file
    const dir = path.join(this.CONTENT_DIR, targetLanguage, sourceContent.category);
    await fs.mkdir(dir, { recursive: true });

    const filePath = path.join(dir, `${id}.json`);
    await fs.writeFile(filePath, JSON.stringify(translationData, null, 2));
    
    console.log(chalk.green(`✅ Created translation: ${targetLanguage}/${sourceContent.category}/${id}`));
    return translationData;
  }

  // Add audio file path to specific language file
  static async addAudio(id, language, audioPath) {
    const content = await this.read(id, language);
    return this.update(id, { audio_file: audioPath }, language);
  }

  // Add social hook to specific language file
  static async addSocialHook(id, language, hook) {
    const content = await this.read(id, language);
    return this.update(id, { social_hook: hook }, language);
  }

  // Add feedback for content review (applies to source language file)
  static async addContentFeedback(id, status, score, reviewer, comments, trainingLabels = {}) {
    // Validate that rejection requires feedback
    if (status === 'rejected' && (!comments || comments.trim() === '')) {
      throw new Error('Feedback comment is required when rejecting content');
    }

    const contentData = await this.read(id, 'zh-TW');
    
    // Initialize feedback structure if missing (backward compatibility)
    if (!contentData.feedback) {
      contentData.feedback = {
        content_review: null,
        ai_outputs: {},
        performance_metrics: {}
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

    return this.update(id, contentData, 'zh-TW');
  }

  // Add feedback for AI outputs (translation, audio, social)
  static async addAIFeedback(id, type, language, status, score, reviewer, comments, modelInfo = {}, trainingLabels = {}) {
    const contentData = await this.read(id, language);
    
    // Initialize feedback structure if missing
    if (!contentData.feedback) {
      contentData.feedback = {
        content_review: null,
        ai_outputs: {},
        performance_metrics: {}
      };
    }
    
    if (!contentData.feedback.ai_outputs[type]) {
      contentData.feedback.ai_outputs[type] = {};
    }

    contentData.feedback.ai_outputs[type] = {
      status,
      score,
      reviewer,
      timestamp: new Date().toISOString(),
      comments,
      model_info: modelInfo,
      training_labels: trainingLabels
    };

    return this.update(id, contentData, language);
  }

  // Add performance metrics to specific language file
  static async addPerformanceMetrics(id, platform, language, metrics) {
    const contentData = await this.read(id, language);
    
    // Initialize feedback structure if missing
    if (!contentData.feedback) {
      contentData.feedback = {
        content_review: null,
        ai_outputs: {},
        performance_metrics: {}
      };
    }

    if (!contentData.feedback.performance_metrics[platform]) {
      contentData.feedback.performance_metrics[platform] = {};
    }

    contentData.feedback.performance_metrics[platform] = {
      ...metrics,
      measured_at: new Date().toISOString()
    };

    return this.update(id, contentData, language);
  }

  // Export training data format (scans all language files)
  static async exportTrainingData(filters = {}) {
    const contents = await this.list();
    const trainingSamples = [];

    contents.forEach(content => {
      if (!content.feedback || !content.feedback.ai_outputs) return;

      // Export training data from AI feedback in this language file
      Object.entries(content.feedback.ai_outputs).forEach(([type, feedback]) => {
        if (feedback.status === 'accepted' || feedback.status === 'rejected') {
          const sample = {
            input: {
              task: type,
              language: content.language,
              content_id: content.id,
              category: content.category,
              context: `${content.category} content, conversational style`
            },
            output: {
              model_version: feedback.model_info?.model,
              timestamp: feedback.timestamp
            },
            feedback: {
              rating: feedback.score,
              accepted: feedback.status === 'accepted',
              reviewer_expertise: feedback.reviewer,
              detailed_scores: feedback.training_labels,
              comments: feedback.comments
            }
          };

          // Add specific fields based on task type
          if (type === 'translation') {
            sample.input.target_language = content.language;
            sample.input.source_language = 'zh-TW';
            sample.output.generated_text = content.content;
          } else if (type === 'social_hook') {
            sample.input.title = content.title;
            sample.input.content_summary = content.content.substring(0, 500);
            sample.output.generated_text = content.social_hook;
          }

          trainingSamples.push(sample);
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

  // Get content summary for CLI display (single language format)
  static formatSummary(content) {
    const { id, status, category, date, language, title, audio_file, social_hook, feedback } = content;
    
    // Count feedback items
    const feedbackCount = feedback ? (
      (feedback.content_review ? 1 : 0) +
      Object.keys(feedback.ai_outputs || {}).length +
      Object.keys(feedback.performance_metrics || {}).length
    ) : 0;
    
    return {
      id: id.substring(0, 25) + (id.length > 25 ? '...' : ''),
      language,
      status,
      category,
      date,
      title: title.substring(0, 40) + (title.length > 40 ? '...' : ''),
      audio: audio_file ? 1 : 0,
      social: social_hook ? 1 : 0,
      feedback: feedbackCount
    };
  }

  // Helper methods for review workflow (work with source language)
  
  // Get all source content needing review
  static async getSourceByStatus(status) {
    return this.list(status, 'zh-TW');
  }

  // Create source content (simplified method for Claude commands)
  static async createSource(id, category, title, content, references = []) {
    return this.create(id, category, 'zh-TW', title, content, references);
  }

  // Read source content specifically
  static async readSource(id) {
    return this.read(id, 'zh-TW');
  }

  // Update source content status specifically
  static async updateSourceStatus(id, status) {
    return this.update(id, { status }, 'zh-TW');
  }

  // Get all content by ID across all languages (for pipeline processing)
  static async getAllLanguagesForId(id) {
    const allContent = [];
    const languages = ContentSchema.getAllLanguages();
    
    for (const language of languages) {
      try {
        const content = await this.read(id, language);
        allContent.push(content);
      } catch (error) {
        // Language version doesn't exist - skip
      }
    }
    
    return allContent;
  }

  // Check if translations exist for an ID
  static async getAvailableLanguages(id) {
    const languages = [];
    const allLanguages = ContentSchema.getAllLanguages();
    
    for (const language of allLanguages) {
      try {
        await this.read(id, language);
        languages.push(language);
      } catch (error) {
        // Language version doesn't exist - skip
      }
    }
    
    return languages;
  }
}