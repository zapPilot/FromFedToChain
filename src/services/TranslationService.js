import { Translate } from "@google-cloud/translate/build/src/v2/index.js";
import chalk from "chalk";
import { ContentManager } from "../ContentManager.js";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export class TranslationService {
  static SUPPORTED_LANGUAGES = ['en-US', 'ja-JP'];
  static translate_client = null;

  // Initialize Google Cloud Translate client
  static getTranslateClient() {
    if (!this.translate_client) {
      const serviceAccountPath = path.resolve(process.cwd(), 'service-account.json');
      this.translate_client = new Translate({
        keyFilename: serviceAccountPath
        // projectId will be automatically inferred from service account file
      });
    }
    return this.translate_client;
  }

  // Translate content to target language
  static async translate(id, targetLanguage) {
    if (!this.SUPPORTED_LANGUAGES.includes(targetLanguage)) {
      throw new Error(`Unsupported language: ${targetLanguage}`);
    }

    console.log(chalk.blue(`🌐 Translating ${id} to ${targetLanguage}...`));

    // Get the source content (zh-TW)
    const sourceContent = await ContentManager.readSource(id);
    
    if (sourceContent.status !== 'reviewed') {
      throw new Error(`Content must be reviewed before translation. Current status: ${sourceContent.status}`);
    }

    const { title, content } = sourceContent;

    // Generate translation using Google Cloud Translate API
    const translatedTitle = await this.translateText(title, targetLanguage);
    const translatedContent = await this.translateText(content, targetLanguage);

    // Add translation to content (creates new language file)
    await ContentManager.addTranslation(id, targetLanguage, translatedTitle, translatedContent);

    // Update source status if all translations are complete
    const availableLanguages = await ContentManager.getAvailableLanguages(id);
    const targetLanguages = ['zh-TW', ...this.SUPPORTED_LANGUAGES]; // Source + translations
    
    if (availableLanguages.length === targetLanguages.length) {
      await ContentManager.updateSourceStatus(id, 'translated');
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

  // Translate text using Google Cloud Translate API
  static async translateText(text, targetLanguage) {
    const languageMap = {
      'zh-TW': 'zh',  // Source language
      'en-US': 'en',  // Target languages
      'ja-JP': 'ja'
    };

    const sourceLanguage = languageMap['zh-TW'];
    const targetLangCode = languageMap[targetLanguage];
    
    if (!targetLangCode) {
      throw new Error(`Unsupported language: ${targetLanguage}`);
    }

    try {
      const translateClient = this.getTranslateClient();
      
      const [translation] = await translateClient.translate(text, {
        from: sourceLanguage,
        to: targetLangCode,
        format: 'text'
      });

      return translation;
    } catch (error) {
      if (error.code === 'ENOENT') {
        throw new Error('Google Cloud service account file not found. Please ensure service-account.json exists in the project root.');
      } else if (error.code === 'EACCES') {
        throw new Error('Google Cloud authentication failed. Please check your service-account.json credentials.');
      } else {
        throw new Error(`Translation failed: ${error.message}`);
      }
    }
  }

  // Get content needing translation
  static async getContentNeedingTranslation() {
    return ContentManager.getSourceByStatus('reviewed');
  }
}