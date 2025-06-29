import fs from "fs/promises";
import path from "path";
import { spawn } from "child_process";
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

      // Check if social hooks are missing
      const needsSocial = !file.data.social_hooks || Object.keys(file.data.social_hooks).length === 0;
      
      if (needsSocial) {
        results.push({
          ...file,
          platforms: getSupportedPlatforms(file.language)
        });
      }
    }

    return results;
  }

  // Generate social media hook using claude -p command
  static async generateHookWithClaude(content, title, language, category) {
    return new Promise((resolve, reject) => {
      const prompt = this.buildPrompt(content, title, language, category);
      
      const claude = spawn('claude', ['-p', prompt], {
        stdio: ['pipe', 'pipe', 'pipe']
      });

      let output = '';
      let error = '';

      claude.stdout.on('data', (data) => {
        output += data.toString();
      });

      claude.stderr.on('data', (data) => {
        error += data.toString();
      });

      claude.on('close', (code) => {
        if (code === 0) {
          resolve(output.trim());
        } else {
          reject(new Error(`Claude command failed: ${error}`));
        }
      });

      claude.on('error', (err) => {
        reject(new Error(`Failed to spawn claude command: ${err.message}`));
      });
    });
  }

  // Build prompt for claude command
  static buildPrompt(content, title, language, category) {
    const hashtags = getHashtagsForCategory(language, category);
    const hashtagText = hashtags.length > 0 ? `Hashtags to consider: ${hashtags.join(', ')}` : '';
    
    return `Generate an engaging social media hook for this ${language} content about ${category}:

Title: ${title}

Content: ${content}

Requirements:
- Create a compelling hook that grabs attention immediately
- Keep it under 200 characters for versatility across platforms
- Make it engaging and shareable
- Match the tone and language (${language})
- Focus on the most compelling insight or shocking fact
- ${hashtagText}

Return only the hook text, no explanations or additional formatting.`;
  }

  // Process a single file for social media hook generation
  static async processSocialFile(file) {
    try {
      Logger.info(`Generating social hooks for: ${file.id} (${file.language})`);

      // Extract content from the language-specific section
      const langData = file.data.language?.[file.language];
      if (!langData) {
        throw new Error(`No ${file.language} content found`);
      }

      // Generate primary hook using claude -p
      const primaryHook = await this.generateHookWithClaude(
        langData.content,
        langData.title,
        file.language,
        file.category
      );

      // Create platform-specific variations
      const platforms = getSupportedPlatforms(file.language);
      const platformHooks = {};

      for (const platform of platforms) {
        platformHooks[platform] = this.optimizeForPlatform(primaryHook, platform, file.language, file.category);
      }

      // Create social hooks object
      const socialHooks = {
        primary: primaryHook,
        platforms: platformHooks,
        generated_at: new Date().toISOString(),
        language: file.language,
        category: file.category
      };

      // Update the content file with social hooks
      await this.updateFileWithSocialHooks(file.path, socialHooks);

      // Save individual platform files
      await this.savePlatformFiles(file, socialHooks);

      Logger.success(`Social hooks generated for: ${file.id} (${file.language})`);
      return { success: true, hooks: socialHooks };

    } catch (error) {
      Logger.error(`Failed to generate social hooks for ${file.id}:`, error.message);
      return { success: false, error: error.message };
    }
  }

  // Optimize hook for specific platform
  static optimizeForPlatform(hook, platform, language, category) {
    const platformConfig = getPlatformConfig(platform);
    const hashtags = getHashtagsForCategory(language, category);
    
    let optimized = hook;

    // Add platform-specific optimizations
    switch (platform) {
      case 'twitter':
        // Add thread indicator if too long
        if (optimized.length > 240) {
          optimized = optimized.substring(0, 240 - 4) + ' 🧵';
        }
        // Add hashtags
        const twitterHashtags = hashtags.slice(0, platformConfig.maxHashtags).join(' ');
        if (twitterHashtags && (optimized + ' ' + twitterHashtags).length <= platformConfig.maxLength) {
          optimized += ' ' + twitterHashtags;
        }
        break;

      case 'linkedin':
        // Remove emojis for professional tone
        optimized = optimized.replace(/[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]/gu, '').trim();
        // Add professional hashtags
        const linkedinHashtags = hashtags.slice(0, platformConfig.maxHashtags).join(' ');
        if (linkedinHashtags) {
          optimized += '\n\n' + linkedinHashtags;
        }
        break;

      case 'facebook':
        // Keep conversational, add call to action
        if (!optimized.includes('?') && !optimized.includes('What do you think')) {
          optimized += '\n\nWhat do you think?';
        }
        break;

      case 'instagram':
        // Add emojis if missing
        if (!/[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]/u.test(optimized)) {
          optimized = '✨ ' + optimized;
        }
        // Add hashtags
        const instaHashtags = hashtags.slice(0, platformConfig.maxHashtags).join(' ');
        if (instaHashtags) {
          optimized += '\n\n' + instaHashtags;
        }
        break;
    }

    // Ensure length compliance
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
      // Create directory structure: social/{language}/{platform}/{category}/
      const platformDir = path.join(baseDir, file.language, platform, file.category);
      await fs.mkdir(platformDir, { recursive: true });

      // Save hook as text file
      const hookFile = path.join(platformDir, `${file.id}${OUTPUT_CONFIG.fileExtension}`);
      await fs.writeFile(hookFile, hook, 'utf-8');

      // Save metadata
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

  // Fallback hook generation (if claude command not available)
  static generateFallbackHook(content, title, language, category) {
    // Extract key insight from content
    const sentences = content.split(/[.!?]\s+/);
    const keyInsight = sentences.find(s => 
      s.length > 30 && s.length < 150 && (
        s.includes('Bitcoin') || s.includes('crypto') || 
        /\d+%/.test(s) || /\$[\d,]+/.test(s)
      )
    ) || sentences[0];

    // Simple hook templates by category
    const templates = {
      'daily-news': ['🚨 Breaking: {{insight}}', 'Did you know: {{insight}}?'],
      'ethereum': ['🔧 Ethereum update: {{insight}}', 'DeFi insight: {{insight}}'],
      'macro': ['💰 Economic insight: {{insight}}', 'Market update: {{insight}}']
    };

    const categoryTemplates = templates[category] || templates['daily-news'];
    const template = categoryTemplates[0];
    
    return template.replace('{{insight}}', keyInsight.substring(0, 180));
  }
}