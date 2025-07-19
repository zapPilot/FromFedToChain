import fs from "fs/promises";
import path from "path";
import chalk from "chalk";
import { GoogleTTSService } from "./GoogleTTSService.js";
import { ContentManager } from "../ContentManager.js";
import { 
  getAudioLanguages, 
  getTTSConfig, 
  shouldGenerateAudio,
  PATHS
} from "../../config/languages.js";

export class AudioService {
  static AUDIO_DIR = PATHS.AUDIO_ROOT;


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

}