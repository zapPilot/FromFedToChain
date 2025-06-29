import { Translate } from '@google-cloud/translate/build/src/v2/index.js';
import { ContentManager } from './ContentManager.js';
import { FileUtils } from '../utils/FileUtils.js';
import { Logger } from '../utils/Logger.js';
import { ProgressBar } from '../utils/ProgressBar.js';
import { RetryUtils } from '../utils/RetryUtils.js';
import { LANGUAGES, TRANSLATION_CONFIG, getTargetLanguages, PATHS } from '../../config/languages.js';
import chalk from 'chalk';

const LANGUAGE_NAMES = {
  'en-US': 'English',
  'ja-JP': 'Japanese', 
  'zh-TW': 'Traditional Chinese'
};

// GCP Translation API language codes
const GCP_LANGUAGE_CODES = {
  'zh-TW': 'zh-TW',
  'en-US': 'en',
  'ja-JP': 'ja'
};

export class TranslationService {
  constructor() {
    // Initialize Google Translate client
    process.env.GOOGLE_APPLICATION_CREDENTIALS = PATHS.SERVICE_ACCOUNT;
    this.translate = new Translate();
  }

  static async translateContent(sourceData, targetLang) {
    const service = new TranslationService();
    return await service.translateContentWithGCP(sourceData, targetLang);
  }

  async translateContentWithGCP(sourceData, targetLang) {
    const sourceContent = sourceData.language[LANGUAGES.PRIMARY];
    const sourceLangCode = GCP_LANGUAGE_CODES[LANGUAGES.PRIMARY];
    const targetLangCode = GCP_LANGUAGE_CODES[targetLang];
    
    if (!targetLangCode) {
      throw new Error(`Unsupported target language: ${targetLang}`);
    }

    console.log(chalk.blue(`🌐 Translating from ${sourceLangCode} to ${targetLangCode}`));
    
    // Translate title and content separately for better control
    const titleTranslation = await this.translateText(sourceContent.title, sourceLangCode, targetLangCode);
    const contentTranslation = await this.translateText(sourceContent.content, sourceLangCode, targetLangCode);
    
    return {
      title: titleTranslation,
      content: contentTranslation
    };
  }

  async translateText(text, sourceLang, targetLang) {
    const operation = async () => {
      const [translation] = await this.translate.translate(text, {
        from: sourceLang,
        to: targetLang,
        format: 'text'
      });
      return translation;
    };

    return await RetryUtils.retryOperation(operation, {
      maxRetries: 3,
      initialDelay: 1000,
      retryCondition: RetryUtils.isRetryableError,
      onRetry: (error, attempt, maxRetries) => {
        console.log(chalk.yellow(`  🔄 Translation retry ${attempt}/${maxRetries}: ${error.message}`));
      }
    });
  }

  static async translateFile(fileId, targetLang) {
    console.log(chalk.blue(`🔄 Translating ${fileId} → ${targetLang}`));
    
    // Find source file
    const { filePath: sourcePath, category } = await FileUtils.findSourceFile(fileId);
    const sourceData = await FileUtils.readJSON(sourcePath);
    
    // Validate
    if (!sourceData.metadata?.translation_status?.source_reviewed) {
      throw new Error('Source content must be reviewed before translation');
    }
    
    // Translate using GCP API
    const translation = await this.translateContent(sourceData, targetLang);
    
    // Create translated file
    const targetPath = FileUtils.getContentPath(targetLang, category, sourceData.id);
    const translatedData = {
      id: sourceData.id,
      date: sourceData.date,
      category: sourceData.category,
      references: sourceData.references,
      language: {
        [targetLang]: translation
      },
      metadata: {
        translation_status: {
          source_reviewed: true,
          translated_at: new Date().toISOString(),
          translation_provider: 'google-cloud-translate'
        },
        tts: {
          [targetLang]: {
            status: "pending",
            audio_url: null,
            voice_config: TRANSLATION_CONFIG[targetLang].voice
          }
        },
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      }
    };
    
    await FileUtils.writeJSON(targetPath, translatedData);
    
    console.log(chalk.green(`✅ Translation completed: ${targetPath}`));
    return { sourcePath, targetPath, category, targetLang };
  }

  static async translateAll(targetLangs = null) {
    targetLangs = targetLangs || getTargetLanguages();
    
    console.log(chalk.blue.bold('🌐 Multi-Language Translation (Google Cloud)'));
    console.log(chalk.gray('='.repeat(50)));
    
    const files = await ContentManager.getFilesForTranslation();
    if (files.length === 0) {
      console.log(chalk.green('✅ No files ready for translation'));
      return;
    }
    
    // Build translation tasks
    const tasks = [];
    for (const file of files) {
      const missing = await ContentManager.getMissingTranslations(file.data, file.category);
      for (const lang of targetLangs) {
        if (missing.includes(lang)) {
          tasks.push({ fileId: file.id, targetLang: lang, title: file.data.language[LANGUAGES.PRIMARY].title });
        }
      }
    }
    
    if (tasks.length === 0) {
      console.log(chalk.green('✅ All content already translated'));
      return;
    }
    
    console.log(chalk.cyan(`📝 Found ${tasks.length} translation tasks`));
    
    const progress = new ProgressBar(tasks.length);
    progress.start();
    
    let successCount = 0;
    for (let i = 0; i < tasks.length; i++) {
      const task = tasks[i];
      progress.update(i, `${task.targetLang}: ${task.fileId}`);
      
      try {
        await this.translateFile(task.fileId, task.targetLang);
        successCount++;
      } catch (error) {
        console.log(chalk.red(`❌ Failed: ${task.fileId} → ${task.targetLang}: ${error.message}`));
      }
    }
    
    progress.update(tasks.length, 'Complete!');
    progress.stop();
    
    console.log(chalk.green.bold(`🎉 Translation completed! ${successCount}/${tasks.length} successful`));
  }

  // Static method to get supported languages
  static getSupportedLanguages() {
    return Object.keys(GCP_LANGUAGE_CODES);
  }

  // Static method to get GCP language code
  static getGCPLanguageCode(languageCode) {
    return GCP_LANGUAGE_CODES[languageCode];
  }
}