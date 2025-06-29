import fs from 'fs/promises';
import path from 'path';
import chalk from 'chalk';
import cliProgress from 'cli-progress';
import { ContentManager } from '../core/ContentManager.js';
import { FileUtils } from '../utils/FileUtils.js';
import { TranslationService } from '../core/TranslationService.js';
import { MockTranslationService } from '../services/MockTranslation.js';
import { GoogleTTSService } from '../services/GoogleTTS.js';
import { AudioStorageService } from '../services/AudioStorage.js';
import { VOICE_CONFIG, PATHS } from '../../config/languages.js';

export class ContentPipeline {
  constructor(options = {}) {
    this.options = {
      maxConcurrency: 3,
      skipCompleted: true,
      autoRetry: true,
      useMockTranslation: true, // Default to mock until GCP Translation API is enabled
      ...options
    };
    
    this.contentManager = new ContentManager();
    this.translationService = new TranslationService();
    this.ttsService = new GoogleTTSService();
    this.audioStorage = new AudioStorageService();
    
    this.progressBar = null;
    this.interrupted = false;
    
    // Handle graceful shutdown
    process.on('SIGINT', this.handleInterrupt.bind(this));
    process.on('SIGTERM', this.handleInterrupt.bind(this));
  }

  async handleInterrupt() {
    if (this.interrupted) return;
    this.interrupted = true;
    
    console.log(chalk.yellow('\n\n⏸️  Pipeline interrupted by user'));
    if (this.progressBar) {
      this.progressBar.stop();
    }
    
    console.log(chalk.blue('💾 Pipeline interrupted. Run again to continue from where files left off'));
    process.exit(0);
  }

  async initialize() {
    // Setup authentication
    process.env.GOOGLE_APPLICATION_CREDENTIALS = PATHS.SERVICE_ACCOUNT;
    
    console.log(chalk.blue.bold('🚀 Content Pipeline'));
    console.log(chalk.gray('='.repeat(50)));
  }

  async runFullPipeline() {
    await this.initialize();
    
    try {
      // Step 1: Translation
      console.log(chalk.blue.bold('\n📝 Step 1: Translation'));
      await this.runTranslationStep();
      
      // Step 2: TTS Processing
      console.log(chalk.blue.bold('\n🎙️ Step 2: TTS Processing'));
      await this.runTTSStep();
      
      // Step 3: Social Content (if needed)
      console.log(chalk.blue.bold('\n📱 Step 3: Social Content'));
      await this.runSocialStep();
      
      console.log(chalk.green.bold('\n🎉 Pipeline completed successfully!'));
      
    } catch (error) {
      console.error(chalk.red('\n❌ Pipeline failed:'), error.message);
      throw error;
    }
  }

  async runTranslationStep() {
    const files = await this.findFilesNeedingTranslation();
    if (files.length === 0) {
      console.log(chalk.green('✅ No files need translation'));
      return;
    }
    
    // Build translation tasks using file-based checking
    const tasks = [];
    for (const file of files) {
      const missing = await ContentManager.getMissingTranslations(file.data, file.category);
      for (const lang of missing) {
        tasks.push({ 
          fileId: file.id, 
          targetLang: lang, 
          title: file.data.language['zh-TW'].title 
        });
      }
    }
    
    if (tasks.length === 0) {
      console.log(chalk.green('✅ All files already translated'));
      return;
    }
    
    await this.processFilesWithProgress(tasks, 'Translation', async (task) => {
      // Check if file already exists (file-based state checking)
      const targetPath = FileUtils.getContentPath(task.targetLang, this.getCategoryFromFileId(task.fileId), task.fileId);
      try {
        await fs.access(targetPath);
        return { skipped: true }; // File already exists
      } catch {
        // File doesn't exist, proceed with translation
      }
      
      const TranslationServiceToUse = this.options.useMockTranslation ? MockTranslationService : TranslationService;
      const result = await TranslationServiceToUse.translateFile(task.fileId, task.targetLang);
      return result;
    });
  }

  async runTTSStep() {
    const files = await this.findFilesNeedingTTS();
    if (files.length === 0) {
      console.log(chalk.green('✅ No files need TTS processing'));
      return;
    }
    
    await this.processFilesWithProgress(files, 'TTS', async (file) => {
      // Check if TTS already completed (file-based state checking)
      if (file.ttsStatus?.status === 'completed') {
        return { skipped: true };
      }
      
      const result = await this.processTTSFile(file);
      return result;
    });
  }

  async runSocialStep() {
    // Placeholder for social content generation
    console.log(chalk.green('✅ Social content step completed (placeholder)'));
  }

  async processFilesWithProgress(files, stepName, processor) {
    this.progressBar = new cliProgress.SingleBar({
      format: chalk.cyan('{bar}') + ' {percentage}% | {value}/{total} | ETA: {eta}s | {stepName}',
      barCompleteChar: '\u2588',
      barIncompleteChar: '\u2591',
      hideCursor: true
    }, cliProgress.Presets.rect);

    this.progressBar.start(files.length, 0, { stepName });
    
    let completed = 0;
    const results = [];
    
    // Process in batches to respect rate limits
    for (let i = 0; i < files.length; i += this.options.maxConcurrency) {
      if (this.interrupted) break;
      
      const batch = files.slice(i, i + this.options.maxConcurrency);
      const batchPromises = batch.map(async (item) => {
        try {
          const result = await processor(item);
          completed++;
          const displayName = item.title || item.fileId || item.id || 'Unknown';
          this.progressBar.update(completed, { stepName: `${stepName}: ${displayName}` });
          return { file: item, result, success: true };
        } catch (error) {
          const itemId = item.fileId || item.id || 'unknown';
          completed++;
          const displayName = item.title || itemId;
          this.progressBar.update(completed, { stepName: `${stepName}: FAILED ${displayName}` });
          return { file: item, error: error.message, success: false };
        }
      });
      
      const batchResults = await Promise.all(batchPromises);
      results.push(...batchResults);
    }
    
    this.progressBar.stop();
    
    // Print summary
    const successful = results.filter(r => r.success).length;
    const failed = results.filter(r => !r.success).length;
    const skipped = results.filter(r => r.result?.skipped).length;
    
    console.log(chalk.green(`✅ ${stepName} completed:`));
    console.log(`  ${chalk.green('Success:')} ${successful}`);
    console.log(`  ${chalk.yellow('Skipped:')} ${skipped}`);
    if (failed > 0) {
      console.log(`  ${chalk.red('Failed:')} ${failed}`);
    }
  }

  async findFilesNeedingTranslation() {
    // Find source files that need translation
    return await ContentManager.getFilesForTranslation();
  }

  async findFilesNeedingTTS() {
    // Find translated files that need TTS processing
    return await ContentManager.getFilesForTTS();
  }

  async processTTSFile(file) {
    const voiceConfig = VOICE_CONFIG[file.language];
    if (!voiceConfig) {
      throw new Error(`No voice config for language: ${file.language}`);
    }
    
    const category = this.getCategoryFromPath(file.path);
    
    // Prepare content for TTS
    const ttsContent = GoogleTTSService.prepareContentForTTS(file.content, file.language);
    
    // Generate audio
    const audioResponse = await this.ttsService.synthesizeSpeech(ttsContent, voiceConfig);
    
    // Save audio file locally
    const audioPath = await this.audioStorage.saveAudioFile(
      audioResponse.audioContent,
      file.id,
      file.language,
      category,
      'wav'
    );
    
    // Update file metadata
    await this.updateTTSStatus(file.path, file.language, audioPath);
    
    return { audioPath, category };
  }

  getCategoryFromPath(filePath) {
    const pathParts = filePath.split(path.sep);
    const contentIndex = pathParts.findIndex(part => part === 'content');
    if (contentIndex !== -1 && pathParts.length > contentIndex + 2) {
      return pathParts[contentIndex + 2];
    }
    return 'daily-news';
  }

  async getCategoryFromFileId(fileId) {
    try {
      const { category } = await FileUtils.findSourceFile(fileId);
      return category;
    } catch {
      return 'daily-news'; // fallback
    }
  }

  async updateTTSStatus(filePath, language, audioPath) {
    const content = await fs.readFile(filePath, 'utf-8');
    const data = JSON.parse(content);
    
    if (data.metadata && data.metadata.tts && data.metadata.tts[language]) {
      data.metadata.tts[language].status = 'completed';
      data.metadata.tts[language].audio_path = audioPath;
      data.metadata.tts[language].audio_url = null; // Remove old drive URL field
      data.metadata.updated_at = new Date().toISOString();
    }
    
    await fs.writeFile(filePath, JSON.stringify(data, null, 2));
  }

  async retryFailed(step = null) {
    console.log(chalk.yellow('🔄 Retrying by running full pipeline...'));
    await this.runFullPipeline();
  }

  async reset() {
    console.log(chalk.green('✅ Pipeline reset (file-based state will automatically detect current status)'));
  }

  async status() {
    console.log(chalk.blue.bold('📊 Pipeline Status (File-based)'));
    console.log(chalk.gray('='.repeat(50)));
    
    const translationFiles = await this.findFilesNeedingTranslation();
    const ttsFiles = await this.findFilesNeedingTTS();
    
    console.log(`Files needing translation: ${translationFiles.length}`);
    console.log(`Files needing TTS: ${ttsFiles.length}`);
  }
}