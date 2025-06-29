import fs from 'fs/promises';
import path from 'path';
import chalk from 'chalk';
import cliProgress from 'cli-progress';
import { ContentManager } from '../core/ContentManager.js';
import { TranslationService } from '../core/TranslationService.js';
import { TTSService } from '../core/TTSService.js';
import { GoogleTTSService } from '../services/GoogleTTS.js';
import { GoogleDriveService } from '../services/GoogleDrive.js';
import { PipelineStateManager } from '../services/PipelineState.js';
import { VOICE_CONFIG, PATHS } from '../../config/languages.js';

export class ContentPipeline {
  constructor(options = {}) {
    this.options = {
      maxConcurrency: 3,
      skipCompleted: true,
      autoRetry: true,
      ...options
    };
    
    this.stateManager = new PipelineStateManager();
    this.contentManager = new ContentManager();
    this.translationService = new TranslationService();
    this.ttsService = new GoogleTTSService();
    this.driveService = new GoogleDriveService();
    
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
    
    await this.stateManager.saveState();
    console.log(chalk.blue('💾 State saved. Run `npm run pipeline` to resume'));
    process.exit(0);
  }

  async initialize() {
    // Setup authentication
    process.env.GOOGLE_APPLICATION_CREDENTIALS = PATHS.SERVICE_ACCOUNT;
    
    // Load pipeline state
    await this.stateManager.loadState();
    
    console.log(chalk.blue.bold('🚀 Content Pipeline'));
    console.log(chalk.gray('='.repeat(50)));
    this.stateManager.printStatus();
  }

  async runFullPipeline() {
    await this.initialize();
    
    try {
      // Step 1: Translation
      if (this.stateManager.state.currentStep === 'translate') {
        console.log(chalk.blue.bold('\n📝 Step 1: Translation'));
        await this.runTranslationStep();
        this.stateManager.setCurrentStep('tts');
        await this.stateManager.saveState();
      }
      
      // Step 2: TTS Processing
      if (this.stateManager.state.currentStep === 'tts') {
        console.log(chalk.blue.bold('\n🎙️ Step 2: TTS Processing'));
        await this.runTTSStep();
        this.stateManager.setCurrentStep('social');
        await this.stateManager.saveState();
      }
      
      // Step 3: Social Content (if needed)
      if (this.stateManager.state.currentStep === 'social') {
        console.log(chalk.blue.bold('\n📱 Step 3: Social Content'));
        await this.runSocialStep();
        this.stateManager.setCurrentStep('completed');
        await this.stateManager.saveState();
      }
      
      console.log(chalk.green.bold('\n🎉 Pipeline completed successfully!'));
      this.stateManager.printStatus();
      
    } catch (error) {
      console.error(chalk.red('\n❌ Pipeline failed:'), error.message);
      await this.stateManager.saveState();
      throw error;
    }
  }

  async runTranslationStep() {
    const files = await this.findFilesNeedingTranslation();
    if (files.length === 0) {
      console.log(chalk.green('✅ No files need translation'));
      return;
    }
    
    await this.processFilesWithProgress(files, 'Translation', async (file) => {
      if (this.stateManager.isFileCompleted(file.id, 'translate')) {
        return { skipped: true };
      }
      
      const result = await this.translationService.translateContent(file);
      this.stateManager.markFileCompleted(file.id, 'translate', result);
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
      if (this.stateManager.isFileCompleted(file.id, 'tts')) {
        return { skipped: true };
      }
      
      const result = await this.processTTSFile(file);
      this.stateManager.markFileCompleted(file.id, 'tts', result);
      return result;
    });
  }

  async runSocialStep() {
    // Placeholder for social content generation
    console.log(chalk.green('✅ Social content step completed (placeholder)'));
  }

  async processFilesWithProgress(files, stepName, processor) {
    this.stateManager.setTotalFiles(files.length);
    
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
      const batchPromises = batch.map(async (file) => {
        try {
          const result = await processor(file);
          completed++;
          this.progressBar.update(completed, { stepName: `${stepName}: ${file.title || file.id}` });
          return { file, result, success: true };
        } catch (error) {
          this.stateManager.markFileFailed(file.id, stepName.toLowerCase(), error);
          completed++;
          this.progressBar.update(completed, { stepName: `${stepName}: FAILED ${file.title || file.id}` });
          return { file, error: error.message, success: false };
        }
      });
      
      const batchResults = await Promise.all(batchPromises);
      results.push(...batchResults);
      
      // Save state after each batch
      await this.stateManager.saveState();
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
    const folderId = GoogleDriveService.getFolderId(voiceConfig, category);
    
    // Prepare content for TTS
    const ttsContent = GoogleTTSService.prepareContentForTTS(file.content, file.language);
    
    // Generate audio
    const audioResponse = await this.ttsService.synthesizeSpeech(ttsContent, voiceConfig);
    
    // Save temporary file
    const fileName = `${file.id}_${file.language}.mp3`;
    const tempPath = `/tmp/${fileName}`;
    await fs.writeFile(tempPath, audioResponse.audioContent, 'binary');
    
    try {
      // Upload to Google Drive
      const driveUrl = await this.driveService.uploadFile(tempPath, fileName, folderId);
      
      // Update file metadata
      await this.updateTTSStatus(file.path, file.language, driveUrl);
      
      return { driveUrl, category };
    } finally {
      // Clean up temp file
      await fs.unlink(tempPath).catch(() => {});
    }
  }

  getCategoryFromPath(filePath) {
    const pathParts = filePath.split(path.sep);
    const contentIndex = pathParts.findIndex(part => part === 'content');
    if (contentIndex !== -1 && pathParts.length > contentIndex + 2) {
      return pathParts[contentIndex + 2];
    }
    return 'daily-news';
  }

  async updateTTSStatus(filePath, language, audioUrl) {
    const content = await fs.readFile(filePath, 'utf-8');
    const data = JSON.parse(content);
    
    if (data.metadata && data.metadata.tts && data.metadata.tts[language]) {
      data.metadata.tts[language].status = 'completed';
      data.metadata.tts[language].audio_url = audioUrl;
      data.metadata.updated_at = new Date().toISOString();
    }
    
    await fs.writeFile(filePath, JSON.stringify(data, null, 2));
  }

  async retryFailed(step = null) {
    await this.stateManager.loadState();
    const failedFiles = this.stateManager.getFailedFiles(step);
    
    if (Object.keys(failedFiles).length === 0) {
      console.log(chalk.green('✅ No failed files to retry'));
      return;
    }
    
    console.log(chalk.yellow(`🔄 Retrying ${Object.keys(failedFiles).length} failed files...`));
    this.stateManager.clearFailedFiles(step);
    
    if (step) {
      this.stateManager.setCurrentStep(step);
    }
    
    await this.runFullPipeline();
  }

  async reset() {
    await this.stateManager.reset();
  }

  async status() {
    await this.stateManager.loadState();
    this.stateManager.printStatus();
  }
}