import fs from "fs/promises";
import path from "path";
import { execSync } from "child_process";
import { FileUtils } from "../utils/FileUtils.js";
import { Logger } from "../utils/Logger.js";

export class SocialMediaService {
  
  // Find files that need social media hook generation
  static async getFilesNeedingSocial() {
    const results = [];
    const files = await FileUtils.scanContentFiles();

    for (const file of files) {
      // Skip primary language (zh-TW) - only process translated files
      if (file.language === 'zh-TW') continue;
      
      // Only process enabled languages
      const enabledLanguages = ['en-US', 'ja-JP'];
      if (!enabledLanguages.includes(file.language)) continue;

      // Check if social hook file exists
      const socialFile = this.getSocialFilePath(file);
      
      try {
        await fs.access(socialFile);
        // File exists, skip
      } catch {
        // File doesn't exist, needs generation
        results.push(file);
      }
    }

    return results;
  }

  // Get social hook file path
  static getSocialFilePath(file) {
    const socialDir = `./social/${file.language}/${file.category}`;
    return path.join(socialDir, `${file.id}.txt`);
  }

  // Process multiple files
  static async processSocialFiles(files) {
    if (files.length === 0) return [];

    Logger.info(`🚀 Processing ${files.length} social hooks`);
    
    const results = [];
    
    for (const file of files) {
      try {
        const result = await this.processSocialFile(file);
        results.push({ file, result });
      } catch (error) {
        Logger.error(`Failed to process ${file.id}:`, error.message);
        results.push({ file, result: { success: false, error: error.message } });
      }
    }

    return results;
  }

  // Process single file
  static async processSocialFile(file) {
    try {
      Logger.info(`Generating social hook for: ${file.id} (${file.language})`);

      const langData = file.data.language?.[file.language];
      if (!langData) {
        throw new Error(`No ${file.language} content found`);
      }

      // Generate simple prompt
      const prompt = this.buildPrompt(langData.title, langData.content, file.language);
      
      // Generate hook with Claude
      const hook = await this.generateHookWithClaude(prompt);
      
      // Save to txt file
      await this.saveHookToFile(file, hook);

      Logger.success(`Social hook generated for: ${file.id} (${file.language})`);
      return { success: true, hook };

    } catch (error) {
      Logger.error(`Failed to generate social hook for ${file.id}:`, error.message);
      return { success: false, error: error.message };
    }
  }

  // Build simple prompt
  static buildPrompt(title, content, language) {
    const languageMap = {
      'en-US': 'English',
      'ja-JP': 'Japanese'
    };
    
    const langName = languageMap[language] || 'English';
    
    // Extract key insight (first meaningful paragraph)
    const keyInsight = content.split('\n\n')[0] || content.substring(0, 200);
    
    return `Create 1 engaging social media hook for "${title}" in ${langName}.

Key content: ${keyInsight}

Requirements:
- Under 180 characters
- Compelling and shareable
- Include relevant hashtags
- Match ${langName} social media style

Return only the hook, no explanations.`;
  }

  // Generate hook with Claude
  static async generateHookWithClaude(prompt) {
    try {
      const claudeCommand = `claude -p ${JSON.stringify(prompt)}`;
      
      const hookResult = execSync(claudeCommand, { 
        encoding: 'utf-8',
        timeout: 60000,
        maxBuffer: 1024 * 1024
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

  // Save hook to txt file
  static async saveHookToFile(file, hook) {
    const socialFile = this.getSocialFilePath(file);
    const socialDir = path.dirname(socialFile);
    
    // Create directory if needed
    await fs.mkdir(socialDir, { recursive: true });
    
    // Save hook to txt file
    await fs.writeFile(socialFile, hook, 'utf-8');
  }

  // Check if claude command is available
  static async checkClaudeAvailability() {
    try {
      execSync('which claude', { stdio: 'ignore' });
      return true;
    } catch {
      return false;
    }
  }
}