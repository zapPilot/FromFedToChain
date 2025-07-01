import { execSync } from "child_process";
import chalk from "chalk";
import { ContentManager } from "../ContentManager.js";

export class SocialService {
  static SUPPORTED_LANGUAGES = ['en-US', 'ja-JP'];

  // Generate social hook for specific language
  static async generateHook(id, language) {
    console.log(chalk.blue(`📱 Generating social hook: ${id} (${language})`));

    // Get specific language content
    const content = await ContentManager.read(id, language);
    
    if (!content) {
      throw new Error(`No ${language} translation found for ${id}`);
    }

    const { title, content: text } = content;

    // Generate social hook using Claude
    const hook = await this.generateHookWithClaude(title, text, language);

    // Add social hook to content
    await ContentManager.addSocialHook(id, language, hook);

    console.log(chalk.green(`✅ Social hook generated: ${id} (${language})`));
    return hook;
  }

  // Generate social hooks for all languages
  static async generateAllHooks(id) {
    // Check source status first
    const sourceContent = await ContentManager.readSource(id);
    
    if (sourceContent.status !== 'audio') {
      throw new Error(`Content must have audio before social hooks. Current status: ${sourceContent.status}`);
    }

    // Get all available languages for this content
    const availableLanguages = await ContentManager.getAvailableLanguages(id);
    
    // Filter out source language for social hooks (only need translations)
    const translationLanguages = availableLanguages.filter(lang => lang !== 'zh-TW');

    const results = {};

    for (const language of translationLanguages) {
      try {
        const hook = await this.generateHook(id, language);
        results[language] = { success: true, hook };
      } catch (error) {
        console.error(chalk.red(`❌ Social hook generation failed for ${language}: ${error.message}`));
        results[language] = { success: false, error: error.message };
      }
    }

    // Update source status if all hooks generated
    const allSuccessful = Object.values(results).every(r => r.success);
    if (allSuccessful && translationLanguages.length > 0) {
      await ContentManager.updateSourceStatus(id, 'social');
    }

    return results;
  }

  // Generate social hook using Claude
  static async generateHookWithClaude(title, content, language) {
    const languageMap = {
      'en-US': 'English',
      'ja-JP': 'Japanese'
    };
    
    const langName = languageMap[language] || 'English';
    
    // Extract key insight (first meaningful paragraph)
    const keyInsight = content.split('\n\n')[0] || content.substring(0, 200);
    
    const prompt = `Create 1 engaging social media hook for "${title}" in ${langName}.

Key content: ${keyInsight}

Requirements:
- Under 180 characters
- Compelling and shareable
- Include relevant hashtags
- Match ${langName} social media style

Return only the hook, no explanations.`;

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
        throw new Error(`Social hook generation failed: ${error.message}`);
      }
    }
  }

  // Get content needing social hooks
  static async getContentNeedingSocial() {
    return ContentManager.getSourceByStatus('audio');
  }

  // Get content ready for publishing
  static async getContentReadyToPublish() {
    return ContentManager.getSourceByStatus('social');
  }
}