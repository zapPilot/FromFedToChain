import { execSync } from "child_process";
import chalk from "chalk";
import { ContentManager } from "../ContentManager.js";

export class TranslationService {
  static SUPPORTED_LANGUAGES = ['en-US', 'ja-JP'];

  // Translate content to target language
  static async translate(id, targetLanguage) {
    if (!this.SUPPORTED_LANGUAGES.includes(targetLanguage)) {
      throw new Error(`Unsupported language: ${targetLanguage}`);
    }

    console.log(chalk.blue(`🌐 Translating ${id} to ${targetLanguage}...`));

    const content = await ContentManager.read(id);
    
    if (content.status !== 'reviewed') {
      throw new Error(`Content must be reviewed before translation. Current status: ${content.status}`);
    }

    const { title, content: sourceContent } = content.source;

    // Generate translation using Claude
    const translatedTitle = await this.translateText(title, targetLanguage);
    const translatedContent = await this.translateText(sourceContent, targetLanguage);

    // Add translation to content
    await ContentManager.addTranslation(id, targetLanguage, translatedTitle, translatedContent);

    // Update status if this is the first translation
    const updatedContent = await ContentManager.read(id);
    const translationCount = Object.keys(updatedContent.translations).length;
    
    if (translationCount === this.SUPPORTED_LANGUAGES.length) {
      await ContentManager.updateStatus(id, 'translated');
    }

    console.log(chalk.green(`✅ Translation completed: ${id} (${targetLanguage})`));
    return { translatedTitle, translatedContent };
  }

  // Translate all supported languages for content
  static async translateAll(id) {
    const results = {};
    
    for (const language of this.SUPPORTED_LANGUAGES) {
      try {
        const result = await this.translate(id, language);
        results[language] = result;
      } catch (error) {
        console.error(chalk.red(`❌ Translation failed for ${language}: ${error.message}`));
        results[language] = { error: error.message };
      }
    }

    return results;
  }

  // Translate text using Claude
  static async translateText(text, targetLanguage) {
    const languageMap = {
      'en-US': 'English',
      'ja-JP': 'Japanese'
    };

    const targetLangName = languageMap[targetLanguage];
    
    const prompt = `Translate the following Chinese text to ${targetLangName}. Maintain the conversational style and keep crypto/finance terminology accurate. Return only the translation, no explanations.

Text to translate:
${text}`;

    try {
      const claudeCommand = `claude -p ${JSON.stringify(prompt)}`;
      
      const result = execSync(claudeCommand, { 
        encoding: 'utf-8',
        timeout: 60000,
        maxBuffer: 1024 * 1024
      });

      return result.trim();
    } catch (error) {
      if (error.code === 'ENOENT') {
        throw new Error('Claude command not found. Install with: npm install -g claude-code');
      } else if (error.signal === 'SIGTERM') {
        throw new Error('Claude command timed out after 60 seconds');
      } else {
        throw new Error(`Translation failed: ${error.message}`);
      }
    }
  }

  // Get content needing translation
  static async getContentNeedingTranslation() {
    return ContentManager.getByStatus('reviewed');
  }
}