import fs from "fs/promises";
import path from "path";
import chalk from "chalk";
import { GoogleTTSService } from "./GoogleTTSService.js";
import { M3U8AudioService } from "./M3U8AudioService.js";
import { CloudflareR2Service } from "./CloudflareR2Service.js";
import { ContentManager } from "../ContentManager.js";
import { 
  getAudioLanguages, 
  getTTSConfig, 
  shouldGenerateAudio,
  shouldGenerateM3U8,
  shouldUploadToR2,
  getM3U8Config,
  PATHS
} from "../../config/languages.js";

export class AudioService {
  static AUDIO_DIR = PATHS.AUDIO_ROOT;

  // Generate audio for specific language
  static async generateAudio(id, language) {
    console.log(chalk.blue(`🎙️ Generating audio: ${id} (${language})`));

    // Check if this language should have audio generated
    if (!shouldGenerateAudio(language)) {
      throw new Error(`Audio generation not configured for language: ${language}`);
    }

    // Get specific language content
    const content = await ContentManager.read(id, language);
    
    if (!content) {
      throw new Error(`No ${language} content found for ${id}`);
    }

    // Get TTS configuration for this language
    const ttsConfig = getTTSConfig(language);
    const voiceConfig = {
      languageCode: ttsConfig.languageCode,
      name: ttsConfig.name
    };

    const { content: text } = content;

    // Prepare content for TTS
    const ttsContent = GoogleTTSService.prepareContentForTTS(text, language);

    // Generate audio
    const ttsService = new GoogleTTSService();
    const audioResponse = await ttsService.synthesizeSpeech(ttsContent, voiceConfig);

    // Save audio file with category-based structure
    const audioPath = await this.saveAudioFile(
      audioResponse.audioContent,
      id,
      language,
      content.category
    );

    const result = {
      audioPath,
      urls: {}
    };

    // Generate M3U8 if enabled for this language
    if (shouldGenerateM3U8(language)) {
      try {
        console.log(chalk.blue(`🎬 Starting M3U8 generation for ${id} (${language})`));
        const m3u8Config = getM3U8Config(language);
        const m3u8Result = await M3U8AudioService.convertToM3U8(
          audioPath,
          id,
          language,
          content.category,
          m3u8Config
        );
        
        if (m3u8Result.success) {
          result.m3u8 = m3u8Result;
          console.log(chalk.green(`✅ M3U8 generated successfully`));
          console.log(chalk.gray(`   Playlist: ${m3u8Result.playlistPath}`));
          console.log(chalk.gray(`   Segments: ${m3u8Result.segments.length}`));
        } else {
          console.log(chalk.red(`❌ M3U8 generation failed`));
        }
      } catch (error) {
        console.error(chalk.red(`❌ M3U8 generation error: ${error.message}`));
        // Don't fail the entire process if M3U8 generation fails
      }
    }

    // Upload to R2 if enabled for this language
    if (shouldUploadToR2(language)) {
      try {
        console.log(chalk.blue(`☁️ Checking R2 upload requirements for ${language}...`));
        
        // Check if rclone is available
        const rcloneAvailable = await CloudflareR2Service.checkRcloneAvailability();
        
        if (rcloneAvailable) {
          const uploadFiles = {
            m3u8Data: result.m3u8
          };
          
          console.log(chalk.blue(`📤 Starting R2 upload for ${id} (${language})...`));
          console.log(chalk.gray(`   M3U8 data: ${result.m3u8 ? 'Available' : 'Missing'}`));
          if (result.m3u8) {
            console.log(chalk.gray(`   M3U8 playlist: ${result.m3u8.playlistPath}`));
            console.log(chalk.gray(`   M3U8 segments: ${result.m3u8.segments.length}`));
          }
          
          const uploadResult = await CloudflareR2Service.uploadAudioFiles(
            id,
            language,
            content.category,
            uploadFiles
          );
          
          if (uploadResult.success) {
            result.urls = uploadResult.urls;
            console.log(chalk.green(`✅ R2 upload completed successfully`));
            console.log(chalk.gray(`   Available URLs: ${Object.keys(uploadResult.urls).join(', ')}`));
          } else {
            console.error(chalk.red(`❌ R2 upload failed: ${uploadResult.errors.join(', ')}`));
          }
        } else {
          console.warn(chalk.yellow(`⚠️ rclone not available, skipping R2 upload`));
          console.warn(chalk.yellow(`   Audio files will be available locally only`));
        }
      } catch (error) {
        console.error(chalk.red(`❌ R2 upload failed: ${error.message}`));
        console.error(chalk.yellow(`   Continuing with local audio files only`));
        // Don't fail the entire process if R2 upload fails
      }
    } else {
      console.log(chalk.blue(`ℹ️ R2 upload disabled for language: ${language}`));
    }

    // Update content with audio path and streaming URLs
    await ContentManager.addAudio(id, language, audioPath, result.urls);

    console.log(chalk.green(`✅ Audio processing completed: ${audioPath}`));
    return result;
  }

  // Generate WAV audio files only (no M3U8 or R2 upload)
  static async generateWavOnly(id) {
    // Check source status first
    const sourceContent = await ContentManager.readSource(id);
    
    if (sourceContent.status !== 'translated') {
      throw new Error(`Content must be translated before audio generation. Current status: ${sourceContent.status}`);
    }

    // Get all available languages for this content
    const availableLanguages = await ContentManager.getAvailableLanguages(id);
    
    // Get all languages that should have audio generated
    const audioLanguages = getAudioLanguages();
    
    // Find intersection of available languages and configured audio languages
    const targetLanguages = availableLanguages.filter(lang => audioLanguages.includes(lang));

    if (targetLanguages.length === 0) {
      throw new Error(`No languages configured for audio generation found for content: ${id}`);
    }

    console.log(chalk.blue(`📝 Generating WAV audio for ${targetLanguages.length} languages: ${targetLanguages.join(', ')}`));

    const results = {};

    for (const language of targetLanguages) {
      try {
        console.log(chalk.blue(`🎙️ Generating WAV audio: ${id} (${language})`));

        // Check if this language should have audio generated
        if (!shouldGenerateAudio(language)) {
          throw new Error(`Audio generation not configured for language: ${language}`);
        }

        // Get specific language content
        const content = await ContentManager.read(id, language);
        
        if (!content) {
          throw new Error(`No ${language} content found for ${id}`);
        }

        // Get TTS configuration for this language
        const ttsConfig = getTTSConfig(language);
        const voiceConfig = {
          languageCode: ttsConfig.languageCode,
          name: ttsConfig.name
        };

        const { content: text } = content;

        // Prepare content for TTS
        const ttsContent = GoogleTTSService.prepareContentForTTS(text, language);

        // Generate audio
        const ttsService = new GoogleTTSService();
        const audioResponse = await ttsService.synthesizeSpeech(ttsContent, voiceConfig);

        // Save audio file with category-based structure
        const audioPath = await this.saveAudioFile(
          audioResponse.audioContent,
          id,
          language,
          content.category
        );

        // Update content with audio path (no URLs yet)
        await ContentManager.addAudio(id, language, audioPath, {});

        results[language] = { success: true, audioPath };
        console.log(chalk.green(`✅ WAV audio generated: ${audioPath}`));
      } catch (error) {
        console.error(chalk.red(`❌ WAV generation failed for ${language}: ${error.message}`));
        results[language] = { success: false, error: error.message };
      }
    }

    return results;
  }

  // Generate audio for all languages (including source language)
  static async generateAllAudio(id) {
    // Check source status first
    const sourceContent = await ContentManager.readSource(id);
    
    if (sourceContent.status !== 'translated') {
      throw new Error(`Content must be translated before audio generation. Current status: ${sourceContent.status}`);
    }

    // Get all available languages for this content
    const availableLanguages = await ContentManager.getAvailableLanguages(id);
    
    // Get all languages that should have audio generated
    const audioLanguages = getAudioLanguages();
    
    // Find intersection of available languages and configured audio languages
    const targetLanguages = availableLanguages.filter(lang => audioLanguages.includes(lang));

    if (targetLanguages.length === 0) {
      throw new Error(`No languages configured for audio generation found for content: ${id}`);
    }

    console.log(chalk.blue(`📝 Generating audio for ${targetLanguages.length} languages: ${targetLanguages.join(', ')}`));

    const results = {};

    for (const language of targetLanguages) {
      try {
        const audioPath = await this.generateAudio(id, language);
        results[language] = { success: true, audioPath };
      } catch (error) {
        console.error(chalk.red(`❌ Audio generation failed for ${language}: ${error.message}`));
        results[language] = { success: false, error: error.message };
      }
    }

    // Update source status if all audio generated successfully
    const allSuccessful = Object.values(results).every(r => r.success);
    if (allSuccessful && targetLanguages.length > 0) {
      await ContentManager.updateSourceStatus(id, 'audio');
    }

    return results;
  }

  // Save audio file to disk with category-based structure
  static async saveAudioFile(audioContent, id, language, category) {
    // Create directory structure: audio/<language>/<category>/
    const categoryDir = path.join(this.AUDIO_DIR, language, category);
    await fs.mkdir(categoryDir, { recursive: true });

    const fileName = `${id}.wav`;
    const filePath = path.join(categoryDir, fileName);

    await fs.writeFile(filePath, audioContent);
    
    return filePath;
  }

  // Get content needing audio generation
  static async getContentNeedingAudio() {
    return ContentManager.getSourceByStatus('translated');
  }

  // List all audio files with category-based structure
  static async listAudioFiles() {
    try {
      const languages = await fs.readdir(this.AUDIO_DIR);
      const audioFiles = [];

      for (const language of languages) {
        const languageDir = path.join(this.AUDIO_DIR, language);
        try {
          const stat = await fs.stat(languageDir);
          if (!stat.isDirectory()) continue;

          const categories = await fs.readdir(languageDir);
          
          for (const category of categories) {
            const categoryDir = path.join(languageDir, category);
            try {
              const categoryStat = await fs.stat(categoryDir);
              if (!categoryStat.isDirectory()) continue;

              const files = await fs.readdir(categoryDir);
              for (const file of files) {
                if (file.endsWith('.wav')) {
                  const filePath = path.join(categoryDir, file);
                  const stats = await fs.stat(filePath);
                  audioFiles.push({
                    id: path.basename(file, '.wav'),
                    language,
                    category,
                    file: filePath,
                    size: Math.round(stats.size / 1024) + 'KB',
                    created: stats.birthtime.toISOString().split('T')[0]
                  });
                }
              }
            } catch (e) {
              // Skip invalid category directories
            }
          }
        } catch (e) {
          // Skip invalid language directories
        }
      }

      return audioFiles.sort((a, b) => new Date(b.created) - new Date(a.created));
    } catch (error) {
      return [];
    }
  }
}