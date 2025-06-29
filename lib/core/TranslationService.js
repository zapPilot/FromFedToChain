import { execSync } from 'child_process';
import { ContentManager } from './ContentManager.js';
import { FileUtils } from '../utils/FileUtils.js';
import { Logger } from '../utils/Logger.js';
import { ProgressBar } from '../utils/ProgressBar.js';
import { LANGUAGES, TRANSLATION_CONFIG, getTargetLanguages } from '../../config/languages.js';

const LANGUAGE_NAMES = {
  'en-US': 'English',
  'ja-JP': 'Japanese',
  'zh-TW': 'Traditional Chinese'
};

export class TranslationService {
  static async callTranslationAPI(prompt) {
    const commands = [
      { name: 'Claude', cmd: `claude -p ${JSON.stringify(prompt)}` },
      { name: 'Gemini', cmd: `gemini -p ${JSON.stringify(prompt)}` }
    ];

    for (const { name, cmd } of commands) {
      try {
        return execSync(cmd, { 
          encoding: 'utf-8',
          timeout: 60000,
          maxBuffer: 1024 * 1024
        });
      } catch (error) {
        if (name === 'Claude') {
          Logger.warning('⚠️  Claude CLI not available, trying Gemini...');
          continue;
        }
        throw new Error('Neither Claude CLI nor Gemini CLI available');
      }
    }
  }

  static parseTranslationResult(result, fallbackTitle = 'Translated Title') {
    const lines = result.trim().split('\n');
    let translatedTitle = '';
    let translatedContent = '';
    let isContent = false;
    
    for (const line of lines) {
      if (line.startsWith('TITLE:')) {
        translatedTitle = line.replace('TITLE:', '').trim();
      } else if (line.startsWith('CONTENT:')) {
        translatedContent = line.replace('CONTENT:', '').trim();
        isContent = true;
      } else if (isContent) {
        translatedContent += '\n' + line;
      }
    }
    
    // Fallback parsing
    if (!translatedTitle || !translatedContent) {
      const fullTranslation = result.trim();
      const parts = fullTranslation.split('\n\n');
      if (parts.length >= 2) {
        translatedTitle = parts[0];
        translatedContent = parts.slice(1).join('\n\n');
      } else {
        translatedTitle = fallbackTitle;
        translatedContent = fullTranslation;
      }
    }
    
    return {
      title: translatedTitle.trim(),
      content: translatedContent.trim()
    };
  }

  static async translateContent(sourceData, targetLang) {
    const sourceContent = sourceData.languages[LANGUAGES.PRIMARY];
    const targetLanguageName = LANGUAGE_NAMES[targetLang] || targetLang;
    
    const prompt = `Please translate the following Traditional Chinese content to ${targetLanguageName}. 

IMPORTANT INSTRUCTIONS:
- Maintain the conversational style and tone of the original
- Keep the financial/crypto terminology accurate
- Preserve the educational and accessible nature of the content
- Do NOT add any formatting, markdown, or extra text
- Return ONLY the translated content, nothing else

TITLE TO TRANSLATE:
${sourceContent.title}

CONTENT TO TRANSLATE:
${sourceContent.content}

Please provide the translation in this exact format:
TITLE: [translated title]
CONTENT: [translated content]`;

    const result = await this.callTranslationAPI(prompt);
    return this.parseTranslationResult(result, `${sourceContent.title} (${targetLanguageName})`);
  }

  static async translateFile(fileId, targetLang) {
    Logger.info(`🔄 Translating ${fileId} → ${targetLang}`);
    
    // Find source file
    const { filePath: sourcePath, category } = await FileUtils.findSourceFile(fileId);
    const sourceData = await FileUtils.readJSON(sourcePath);
    
    // Validate
    if (!sourceData.metadata?.translation_status?.source_reviewed) {
      throw new Error('Source content must be reviewed before translation');
    }
    
    // Translate
    const translation = await this.translateContent(sourceData, targetLang);
    
    // Create translated file
    const targetPath = FileUtils.getContentPath(targetLang, category, sourceData.id);
    const translatedData = {
      id: sourceData.id,
      date: sourceData.date,
      category: sourceData.category,
      references: sourceData.references,
      languages: {
        [targetLang]: translation
      },
      metadata: {
        translation_status: {
          source_language: LANGUAGES.PRIMARY,
          source_reviewed: true,
          translated_to: [targetLang],
          translated_at: new Date().toISOString()
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
    
    // Update source metadata
    const translatedTo = sourceData.metadata.translation_status.translated_to || [];
    if (!translatedTo.includes(targetLang)) {
      translatedTo.push(targetLang);
      await ContentManager.updateContent(sourcePath, {
        metadata: {
          translation_status: { translated_to: translatedTo }
        }
      });
    }
    
    Logger.success(`✅ Translation completed: ${targetPath}`);
    return { sourcePath, targetPath, category, targetLang };
  }

  static async translateAll(targetLangs = null) {
    targetLangs = targetLangs || getTargetLanguages();
    
    Logger.title('🌐 Multi-Language Translation');
    
    const files = await ContentManager.getFilesForTranslation();
    if (files.length === 0) {
      Logger.success('✅ No files ready for translation');
      return;
    }
    
    // Build translation tasks
    const tasks = [];
    for (const file of files) {
      const missing = ContentManager.getMissingTranslations(file.data);
      for (const lang of targetLangs) {
        if (missing.includes(lang)) {
          tasks.push({ fileId: file.id, targetLang: lang, title: file.data.languages[LANGUAGES.PRIMARY].title });
        }
      }
    }
    
    if (tasks.length === 0) {
      Logger.success('✅ All content already translated');
      return;
    }
    
    Logger.info(`📝 Found ${tasks.length} translation tasks`);
    
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
        Logger.error(`❌ Failed: ${task.fileId} → ${task.targetLang}: ${error.message}`);
      }
    }
    
    progress.update(tasks.length, 'Complete!');
    progress.stop();
    
    Logger.success(`🎉 Translation completed! ${successCount}/${tasks.length} successful`);
  }
}