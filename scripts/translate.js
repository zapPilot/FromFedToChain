#!/usr/bin/env node

import fs from "fs/promises";
import path from "path";
import chalk from "chalk";
import { execSync } from "child_process";
import cliProgress from "cli-progress";
import { TRANSLATION_CONFIG, CATEGORIES, PATHS, LANGUAGES } from '../config/languages.js';

// Language mapping for translation prompts
const LANGUAGE_NAMES = {
  'en-US': 'English',
  'ja-JP': 'Japanese',
  'zh-TW': 'Traditional Chinese'
};

class TranslationService {
  constructor() {
    this.sourcePath = path.join(PATHS.CONTENT_ROOT, LANGUAGES.PRIMARY);
  }

  async findSourceFile(fileId) {
    for (const category of CATEGORIES) {
      const filePath = path.join(this.sourcePath, category, `${fileId}.json`);
      try {
        await fs.access(filePath);
        return { filePath, category };
      } catch {
        continue;
      }
    }
    throw new Error(`Source file not found: ${fileId}`);
  }

  async validateSourceFile(filePath) {
    const content = await fs.readFile(filePath, 'utf-8');
    const data = JSON.parse(content);
    
    // Check if source is reviewed
    if (!data.metadata?.translation_status?.source_reviewed) {
      throw new Error('Source content must be reviewed before translation');
    }
    
    // Check if already translated to target language
    const translatedTo = data.metadata.translation_status.translated_to || [];
    if (translatedTo.includes('en-US')) {
      console.log(chalk.yellow('⚠️  Content already translated to English'));
    }
    
    return data;
  }

  async callTranslationAPI(prompt) {
    // Try Claude first, fallback to Gemini
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
          console.log(chalk.yellow('⚠️  Claude CLI not available, trying Gemini...'));
          continue;
        }
        throw new Error('Neither Claude CLI nor Gemini CLI available. Please install claude-cli or gemini-cli.');
      }
    }
  }

  parseTranslationResult(result, fallbackTitle = 'Translated Title') {
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
    
    // Fallback parsing if structured format not found
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

  async translateContent(sourceData, targetLang = 'en-US', progressBar = null) {
    const sourceContent = sourceData.languages[LANGUAGES.PRIMARY];
    const targetLanguageName = LANGUAGE_NAMES[targetLang] || targetLang;
    
    if (progressBar) progressBar.update(10, { stage: 'Preparing translation...' });
    
    const translationPrompt = `Please translate the following Traditional Chinese content to ${targetLanguageName}. 

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

    if (progressBar) progressBar.update(30, { stage: 'Calling translation API...' });
    
    const translationResult = await this.callTranslationAPI(translationPrompt);
    
    if (progressBar) progressBar.update(70, { stage: 'Processing response...' });
    
    const translation = this.parseTranslationResult(translationResult, `${sourceContent.title} (${targetLanguageName})`);
    
    if (progressBar) progressBar.update(90, { stage: 'Translation complete' });
    
    return translation;
  }

  async createTranslatedFile(sourceData, translatedContent, targetLang, category) {
    const targetPath = path.join(PATHS.CONTENT_ROOT, targetLang, category, `${sourceData.id}.json`);
    
    // Ensure target directory exists
    await fs.mkdir(path.dirname(targetPath), { recursive: true });
    
    const translatedData = {
      id: sourceData.id,
      date: sourceData.date,
      category: sourceData.category,
      references: sourceData.references,
      languages: {
        [targetLang]: translatedContent
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
    
    await fs.writeFile(targetPath, JSON.stringify(translatedData, null, 2));
    return targetPath;
  }

  async updateSourceMetadata(sourcePath, targetLang) {
    const content = await fs.readFile(sourcePath, 'utf-8');
    const data = JSON.parse(content);
    
    // Update translation status
    const translatedTo = data.metadata.translation_status.translated_to || [];
    if (!translatedTo.includes(targetLang)) {
      translatedTo.push(targetLang);
    }
    
    data.metadata.translation_status.translated_to = translatedTo;
    data.metadata.updated_at = new Date().toISOString();
    
    await fs.writeFile(sourcePath, JSON.stringify(data, null, 2));
  }

  async translateFile(fileId, targetLang = 'en-US', showProgress = true) {
    const progressBar = showProgress ? new cliProgress.SingleBar({
      format: chalk.cyan('{bar}') + ' {percentage}% | {stage}',
      barCompleteChar: '\u2588',
      barIncompleteChar: '\u2591',
      hideCursor: true
    }, cliProgress.Presets.rect) : null;

    try {
      if (progressBar) progressBar.start(100, 0, { stage: 'Starting translation...' });

      // Find and validate source file
      const { filePath: sourcePath, category } = await this.findSourceFile(fileId);
      const sourceData = await this.validateSourceFile(sourcePath);
      
      if (progressBar) progressBar.update(5, { stage: 'Source file loaded' });

      // Translate content
      const translatedContent = await this.translateContent(sourceData, targetLang, progressBar);
      
      // Create translated file
      if (progressBar) progressBar.update(95, { stage: 'Saving translated file...' });
      const targetPath = await this.createTranslatedFile(sourceData, translatedContent, targetLang, category);
      
      // Update source metadata
      await this.updateSourceMetadata(sourcePath, targetLang);
      
      if (progressBar) {
        progressBar.update(100, { stage: 'Complete!' });
        progressBar.stop();
      }
      
      return {
        success: true,
        sourcePath,
        targetPath,
        category,
        targetLang
      };
      
    } catch (error) {
      if (progressBar) progressBar.stop();
      throw error;
    }
  }
}

async function main() {
  const args = process.argv.slice(2);
  const fileId = args.find(arg => !arg.startsWith('--'))?.replace('--file_id=', '');
  const targetLang = args.find(arg => arg.startsWith('--target_lang='))?.split('=')[1] || 'en-US';
  
  if (!fileId) {
    console.error(chalk.red('❌ Error: file_id is required'));
    console.log(chalk.gray('Usage: node scripts/translate.js <file_id> [--target_lang=en]'));
    process.exit(1);
  }
  
  try {
    console.log(chalk.blue.bold('🌐 Translation Pipeline'));
    console.log(chalk.gray('='.repeat(50)));
    
    const translationService = new TranslationService();
    const result = await translationService.translateFile(fileId, targetLang);
    
    console.log(chalk.green.bold('\n🎉 Translation completed!'));
    console.log(chalk.gray(`📁 Target file: ${path.basename(result.targetPath)}`));
    console.log(chalk.gray(`📂 Category: ${result.category}`));
    console.log(chalk.gray(`🌍 Language: ${targetLang}`));
    console.log(chalk.gray(`🎙️ Ready for TTS processing`));
    
  } catch (error) {
    console.error(chalk.red('❌ Translation failed:'), error.message);
    process.exit(1);
  }
}

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}

export { TranslationService };