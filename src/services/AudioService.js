import fs from "fs/promises";
import path from "path";
import chalk from "chalk";
import { GoogleTTSService } from "./GoogleTTSService.js";
import { ContentManager } from "../ContentManager.js";
import { VOICE_CONFIG } from "../../config/languages.js";

export class AudioService {
  static AUDIO_DIR = "./audio";

  // Generate audio for specific language
  static async generateAudio(id, language) {
    console.log(chalk.blue(`🎙️ Generating audio: ${id} (${language})`));

    const content = await ContentManager.read(id);
    
    if (!content.translations[language]) {
      throw new Error(`No ${language} translation found for ${id}`);
    }

    const voiceConfig = VOICE_CONFIG[language];
    if (!voiceConfig) {
      throw new Error(`No voice config for language: ${language}`);
    }

    const { content: text } = content.translations[language];

    // Prepare content for TTS
    const ttsContent = GoogleTTSService.prepareContentForTTS(text, language);

    // Generate audio
    const ttsService = new GoogleTTSService();
    const audioResponse = await ttsService.synthesizeSpeech(ttsContent, voiceConfig);

    // Save audio file
    const audioPath = await this.saveAudioFile(
      audioResponse.audioContent,
      id,
      language,
      content.category
    );

    // Update content with audio path
    await ContentManager.addAudio(id, language, audioPath);

    console.log(chalk.green(`✅ Audio generated: ${audioPath}`));
    return audioPath;
  }

  // Generate audio for all translations
  static async generateAllAudio(id) {
    const content = await ContentManager.read(id);
    
    if (content.status !== 'translated') {
      throw new Error(`Content must be translated before audio generation. Current status: ${content.status}`);
    }

    const results = {};
    const languages = Object.keys(content.translations);

    for (const language of languages) {
      try {
        const audioPath = await this.generateAudio(id, language);
        results[language] = { success: true, audioPath };
      } catch (error) {
        console.error(chalk.red(`❌ Audio generation failed for ${language}: ${error.message}`));
        results[language] = { success: false, error: error.message };
      }
    }

    // Update status if all audio generated
    const allSuccessful = Object.values(results).every(r => r.success);
    if (allSuccessful) {
      await ContentManager.updateStatus(id, 'audio');
    }

    return results;
  }

  // Save audio file to disk
  static async saveAudioFile(audioContent, id, language, category) {
    const languageDir = path.join(this.AUDIO_DIR, language);
    await fs.mkdir(languageDir, { recursive: true });

    const fileName = `${id}.wav`;
    const filePath = path.join(languageDir, fileName);

    await fs.writeFile(filePath, audioContent);
    
    return filePath;
  }

  // Get content needing audio generation
  static async getContentNeedingAudio() {
    return ContentManager.getByStatus('translated');
  }

  // List all audio files
  static async listAudioFiles() {
    try {
      const languages = await fs.readdir(this.AUDIO_DIR);
      const audioFiles = [];

      for (const language of languages) {
        const languageDir = path.join(this.AUDIO_DIR, language);
        try {
          const files = await fs.readdir(languageDir);
          for (const file of files) {
            if (file.endsWith('.wav')) {
              const stats = await fs.stat(path.join(languageDir, file));
              audioFiles.push({
                id: path.basename(file, '.wav'),
                language,
                file: path.join(languageDir, file),
                size: Math.round(stats.size / 1024) + 'KB',
                created: stats.birthtime.toISOString().split('T')[0]
              });
            }
          }
        } catch (e) {
          // Skip invalid directories
        }
      }

      return audioFiles.sort((a, b) => new Date(b.created) - new Date(a.created));
    } catch (error) {
      return [];
    }
  }
}