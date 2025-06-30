import fs from "fs/promises";
import path from "path";
import crypto from "crypto";
import { spawn, execSync } from "child_process";
import { FileUtils } from "../utils/FileUtils.js";
import { Logger } from "../utils/Logger.js";
import { 
  SOCIAL_LANGUAGES, 
  SOCIAL_PLATFORMS, 
  OUTPUT_CONFIG,
  getSupportedPlatforms,
  getHashtagsForCategory,
  getPlatformConfig,
  isLanguageEnabled 
} from "../../config/social-media.js";

export class SocialMediaService {
  
  // Find files that need social media hook generation
  static async getFilesNeedingSocial() {
    const results = [];
    const files = await FileUtils.scanContentFiles();

    for (const file of files) {
      // Skip primary language (zh-TW) - only process translated files
      if (file.language === 'zh-TW') continue;
      
      // Only process enabled languages
      if (!isLanguageEnabled(file.language)) continue;

      // Check if social hooks are missing OR content changed
      const needsRegeneration = await this.needsHookRegeneration(file);
      
      if (needsRegeneration) {
        results.push({
          ...file,
          platforms: getSupportedPlatforms(file.language)
        });
      }
    }

    return results;
  }

  // Check if hook regeneration is needed based on content changes
  static async needsHookRegeneration(file) {
    const socialHooks = file.data.social_hooks;
    
    // No hooks exist
    if (!socialHooks || Object.keys(socialHooks).length === 0) {
      return true;
    }

    // Check if content changed since last hook generation
    const langData = file.data.language?.[file.language];
    if (!langData) return true;

    const currentContentHash = this.hashContent(langData.content + langData.title);
    const lastContentHash = socialHooks.content_hash;

    return currentContentHash !== lastContentHash;
  }

  // Create content hash for change detection
  static hashContent(content) {
    return crypto.createHash('sha256').update(content).digest('hex').substring(0, 16);
  }

  // OPTIMIZATION 1: Batch processing - process multiple files in single claude call
  static async generateHooksBatch(files) {
    if (files.length === 0) return [];
    
    // Group files by language for more efficient prompting
    const filesByLanguage = {};
    files.forEach(file => {
      if (!filesByLanguage[file.language]) {
        filesByLanguage[file.language] = [];
      }
      filesByLanguage[file.language].push(file);
    });

    const results = [];
    
    // Process each language group in batch
    for (const [language, langFiles] of Object.entries(filesByLanguage)) {
      try {
        const batchResults = await this.generateHooksBatchForLanguage(langFiles, language);
        results.push(...batchResults);
      } catch (error) {
        Logger.error(`Batch hook generation failed for ${language}:`, error.message);
        // Fallback to individual processing
        for (const file of langFiles) {
          try {
            const result = await this.processSocialFile(file);
            results.push({ file, result });
          } catch (err) {
            results.push({ file, result: { success: false, error: err.message } });
          }
        }
      }
    }

    return results;
  }

  // Process batch of files for single language
  static async generateHooksBatchForLanguage(files, language) {
    const batchPrompt = this.buildBatchPrompt(files, language);
    
    // Use single claude call for multiple files
    const batchOutput = await this.generateHookWithClaude(batchPrompt);
    
    // Parse batch output and assign to files
    return this.parseBatchOutput(batchOutput, files);
  }

  // OPTIMIZATION 2: Efficient batch prompting
  static buildBatchPrompt(files, language) {
    const filePrompts = files.map((file, index) => {
      const langData = file.data.language[language];
      const category = file.category;
      const hashtags = getHashtagsForCategory(language, category);
      
      // OPTIMIZATION 3: Shortened prompts - key insights only
      const keyInsight = this.extractKeyInsight(langData.content);
      
      return `${index + 1}. "${langData.title}" (${category}): ${keyInsight}`;
    }).join('\n\n');

    const hashtagText = files.length > 0 ? 
      `Hashtags: ${getHashtagsForCategory(language, files[0].category).join(', ')}` : '';

    return `Generate engaging social media hooks for these ${language} articles. Return EXACTLY ${files.length} hooks, numbered 1-${files.length}, one per line:

${filePrompts}

Requirements:
- Each hook under 180 characters
- Compelling and shareable
- Match ${language} language style
- ${hashtagText}

Format: Just return numbered hooks, no explanations.`;
  }

  // Extract key insight instead of full content
  static extractKeyInsight(content) {
    const sentences = content.split(/[.!?]\s+/);
    
    // Find most impactful sentence
    const keyInsight = sentences.find(s => 
      s.length > 20 && s.length < 120 && (
        s.includes('Bitcoin') || s.includes('crypto') || s.includes('government') ||
        /\d+%/.test(s) || /\$[\d,]+/.test(s) || 
        s.includes('breakthrough') || s.includes('change')
      )
    ) || sentences[0];

    return keyInsight.substring(0, 150);
  }

  // Parse batch output from claude
  static parseBatchOutput(batchOutput, files) {
    const lines = batchOutput.split('\n').filter(line => line.trim());
    const results = [];

    files.forEach((file, index) => {
      try {
        // Find numbered hook for this file
        const hookLine = lines.find(line => line.startsWith(`${index + 1}.`));
        const primaryHook = hookLine ? hookLine.replace(/^\d+\.\s*/, '').trim() : 
          this.generateFallbackHook(file.data.language[file.language].content, 
                                   file.data.language[file.language].title, 
                                   file.language, file.category);

        const socialHooks = this.createSocialHooksObject(primaryHook, file);
        results.push({
          file,
          result: { success: true, hooks: socialHooks }
        });

      } catch (error) {
        results.push({
          file,
          result: { success: false, error: error.message }
        });
      }
    });

    return results;
  }

  // Create social hooks object with platform optimizations
  static createSocialHooksObject(primaryHook, file) {
    const platforms = getSupportedPlatforms(file.language);
    const platformHooks = {};

    for (const platform of platforms) {
      platformHooks[platform] = this.optimizeForPlatform(primaryHook, platform, file.language, file.category);
    }

    const langData = file.data.language[file.language];
    const contentHash = this.hashContent(langData.content + langData.title);

    return {
      primary: primaryHook,
      platforms: platformHooks,
      generated_at: new Date().toISOString(),
      language: file.language,
      category: file.category,
      content_hash: contentHash // For change detection
    };
  }

  // Generate social media hook using claude -p command (fixed with execSync)
  static async generateHookWithClaude(prompt) {
    try {
      // Use execSync like the working example - this handles the enter requirement properly
      const claudeCommand = `claude -p ${JSON.stringify(prompt)}`;
      
      const hookResult = execSync(claudeCommand, { 
        encoding: 'utf-8',
        timeout: 60000, // 60 second timeout
        maxBuffer: 1024 * 1024 // 1MB buffer
      });

      return hookResult.trim();
    } catch (error) {
      if (error.code === 'ENOENT') {
        throw new Error('Claude command not found. Install with: npm install -g claude-code');
      } else if (error.signal === 'SIGTERM') {
        throw new Error('Claude command timed out after 60 seconds');
      } else {
        throw new Error(`Claude command failed: ${error.message}`);
      }
    }
  }

  // OPTIMIZATION 4: Process multiple files efficiently
  static async processSocialFiles(files) {
    if (files.length === 0) return [];

    Logger.info(`🚀 Processing ${files.length} files with batch optimization`);
    
    // Process in batches of 5 for optimal API efficiency
    const batchSize = 5;
    const results = [];
    
    for (let i = 0; i < files.length; i += batchSize) {
      const batch = files.slice(i, i + batchSize);
      const batchResults = await this.generateHooksBatch(batch);
      
      // Save hooks to files
      for (const { file, result } of batchResults) {
        if (result.success) {
          await this.updateFileWithSocialHooks(file.path, result.hooks);
          await this.savePlatformFiles(file, result.hooks);
        }
      }
      
      results.push(...batchResults);
    }

    return results;
  }

  // Legacy single file processing (fallback)
  static async processSocialFile(file) {
    try {
      Logger.info(`Generating social hooks for: ${file.id} (${file.language})`);

      const langData = file.data.language?.[file.language];
      if (!langData) {
        throw new Error(`No ${file.language} content found`);
      }

      // Check if regeneration needed
      if (!await this.needsHookRegeneration(file)) {
        Logger.info(`Hooks up to date for: ${file.id} (${file.language})`);
        return { success: true, cached: true };
      }

      // Use key insight instead of full content for faster processing
      const keyInsight = this.extractKeyInsight(langData.content);
      const shortPrompt = this.buildShortPrompt(keyInsight, langData.title, file.language, file.category);
      const primaryHook = await this.generateHookWithClaude(shortPrompt);
      const socialHooks = this.createSocialHooksObject(primaryHook, file);

      await this.updateFileWithSocialHooks(file.path, socialHooks);
      await this.savePlatformFiles(file, socialHooks);

      Logger.success(`Social hooks generated for: ${file.id} (${file.language})`);
      return { success: true, hooks: socialHooks };

    } catch (error) {
      Logger.error(`Failed to generate social hooks for ${file.id}:`, error.message);
      return { success: false, error: error.message };
    }
  }

  // Short prompt for individual files
  static buildShortPrompt(keyInsight, title, language, category) {
    const hashtags = getHashtagsForCategory(language, category);
    const hashtagText = hashtags.length > 0 ? `Hashtags: ${hashtags.join(', ')}` : '';
    
    return `Create 1 engaging social hook for "${title}" in ${language}:

Key insight: ${keyInsight}

Requirements: Under 180 chars, compelling, shareable. ${hashtagText}

Return only the hook, no explanations.`;
  }

  // Optimize hook for specific platform
  static optimizeForPlatform(hook, platform, language, category) {
    const platformConfig = getPlatformConfig(platform);
    const hashtags = getHashtagsForCategory(language, category);
    
    let optimized = hook;

    switch (platform) {
      case 'twitter':
        if (optimized.length > 240) {
          optimized = optimized.substring(0, 240 - 4) + ' 🧵';
        }
        const twitterHashtags = hashtags.slice(0, platformConfig.maxHashtags).join(' ');
        if (twitterHashtags && (optimized + ' ' + twitterHashtags).length <= platformConfig.maxLength) {
          optimized += ' ' + twitterHashtags;
        }
        break;

      case 'linkedin':
        optimized = optimized.replace(/[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]/gu, '').trim();
        const linkedinHashtags = hashtags.slice(0, platformConfig.maxHashtags).join(' ');
        if (linkedinHashtags) {
          optimized += '\n\n' + linkedinHashtags;
        }
        break;

      case 'facebook':
        if (!optimized.includes('?') && !optimized.includes('What do you think')) {
          optimized += '\n\nWhat do you think?';
        }
        break;

      case 'instagram':
        if (!/[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]/u.test(optimized)) {
          optimized = '✨ ' + optimized;
        }
        const instaHashtags = hashtags.slice(0, platformConfig.maxHashtags).join(' ');
        if (instaHashtags) {
          optimized += '\n\n' + instaHashtags;
        }
        break;
    }

    if (optimized.length > platformConfig.maxLength) {
      optimized = optimized.substring(0, platformConfig.maxLength - 3) + '...';
    }

    return optimized;
  }

  // Update content file with social hooks
  static async updateFileWithSocialHooks(filePath, socialHooks) {
    const content = await FileUtils.readJSON(filePath);
    content.social_hooks = socialHooks;
    content.metadata.updated_at = new Date().toISOString();
    await FileUtils.writeJSON(filePath, content);
  }

  // Save platform-specific files
  static async savePlatformFiles(file, socialHooks) {
    const baseDir = './social';
    
    for (const [platform, hook] of Object.entries(socialHooks.platforms)) {
      const platformDir = path.join(baseDir, file.language, platform, file.category);
      await fs.mkdir(platformDir, { recursive: true });

      const hookFile = path.join(platformDir, `${file.id}${OUTPUT_CONFIG.fileExtension}`);
      await fs.writeFile(hookFile, hook, 'utf-8');

      if (OUTPUT_CONFIG.includeMetadata) {
        const metadataFile = path.join(platformDir, `${file.id}${OUTPUT_CONFIG.metadataExtension}`);
        const metadata = {
          id: file.id,
          title: file.data.language[file.language].title,
          category: file.category,
          language: file.language,
          platform,
          hook,
          primary_hook: socialHooks.primary,
          generated_at: socialHooks.generated_at,
          content_hash: socialHooks.content_hash,
          file_path: file.path
        };
        await fs.writeFile(metadataFile, JSON.stringify(metadata, null, 2), 'utf-8');
      }
    }
  }

  // Check if claude command is available
  static async checkClaudeAvailability() {
    return new Promise((resolve) => {
      const claude = spawn('which', ['claude'], { stdio: ['pipe', 'pipe', 'pipe'] });
      claude.on('close', (code) => {
        resolve(code === 0);
      });
      claude.on('error', () => {
        resolve(false);
      });
    });
  }

  // Fallback hook generation (if claude unavailable)
  static generateFallbackHook(content, title, language, category) {
    const keyInsight = this.extractKeyInsight(content);
    const templates = {
      'daily-news': ['🚨 Breaking: {{insight}}', 'Did you know: {{insight}}?'],
      'ethereum': ['🔧 Ethereum update: {{insight}}', 'DeFi insight: {{insight}}'],
      'macro': ['💰 Economic insight: {{insight}}', 'Market update: {{insight}}']
    };

    const categoryTemplates = templates[category] || templates['daily-news'];
    const template = categoryTemplates[0];
    
    return template.replace('{{insight}}', keyInsight.substring(0, 150));
  }
}