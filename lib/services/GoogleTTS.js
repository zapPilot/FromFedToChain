import { TextToSpeechClient } from "@google-cloud/text-to-speech";
import { RetryUtils } from '../utils/RetryUtils.js';
import chalk from 'chalk';

export class GoogleTTSService {
  constructor() {
    this.client = new TextToSpeechClient();
  }

  async synthesizeSpeech(text, voiceConfig) {
    const operation = async () => {
      const [response] = await this.client.synthesizeSpeech({
        input: { text },
        voice: {
          languageCode: voiceConfig.languageCode,
          name: voiceConfig.name
        },
        audioConfig: { audioEncoding: "MP3" },
      });
      return response;
    };

    return await RetryUtils.retryOperation(operation, {
      maxRetries: 3,
      initialDelay: 1000,
      retryCondition: RetryUtils.isRetryableError,
      onRetry: (error, attempt, maxRetries) => {
        console.log(chalk.yellow(`  🔄 TTS retry ${attempt}/${maxRetries}: ${error.message}`));
      }
    });
  }

  static prepareContentForTTS(content, language) {
    // For English, if it has social format, use just the content part
    if (language === 'en-US' && content.includes('🚀')) {
      // Extract content after social hook
      const parts = content.split('\n\n');
      if (parts.length > 1) {
        return parts.slice(1).join('\n\n');
      }
    }
    return content;
  }
}