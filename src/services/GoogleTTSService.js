import { TextToSpeechClient } from "@google-cloud/text-to-speech";
import path from "path";

export class GoogleTTSService {
  constructor() {
    // Explicitly use service account file
    const serviceAccountPath = path.resolve(process.cwd(), 'service-account.json');
    this.client = new TextToSpeechClient({
      keyFilename: serviceAccountPath
      // projectId will be automatically inferred from service account file
    });
  }

  async synthesizeSpeech(text, voiceConfig) {
    const request = {
      input: { text },
      voice: {
        languageCode: voiceConfig.languageCode,
        name: voiceConfig.name,
      },
      audioConfig: {
        audioEncoding: "LINEAR16",
        sampleRateHertz: 16000,
      },
    };

    const [response] = await this.client.synthesizeSpeech(request);
    return response;
  }

  static prepareContentForTTS(content, language) {
    // Remove markdown and format for speech
    let ttsContent = content
      .replace(/\*\*(.*?)\*\*/g, '$1') // Remove bold
      .replace(/\*(.*?)\*/g, '$1')     // Remove italic
      .replace(/`(.*?)`/g, '$1')       // Remove code
      .replace(/#{1,6}\s/g, '')        // Remove headers
      .replace(/\[([^\]]+)\]\([^)]+\)/g, '$1') // Remove links, keep text
      .replace(/\n{3,}/g, '\n\n')      // Normalize line breaks
      .trim();

    // Add pauses for better speech flow
    ttsContent = ttsContent
      .replace(/\n\n/g, '\n\n... \n\n') // Add pause between paragraphs
      .replace(/([.!?])\s+([A-Z])/g, '$1 ... $2'); // Add pause between sentences

    // Check if content exceeds Google TTS limit (5000 bytes)
    const contentBytes = Buffer.byteLength(ttsContent, 'utf8');
    const MAX_TTS_BYTES = 4800; // Leave some buffer under 5000 byte limit

    if (contentBytes > MAX_TTS_BYTES) {
      console.warn(`⚠️ Content too long (${contentBytes} bytes). Truncating to fit TTS limit.`);
      
      // Truncate content while trying to preserve sentence boundaries
      let truncated = ttsContent;
      while (Buffer.byteLength(truncated, 'utf8') > MAX_TTS_BYTES) {
        // Find last sentence ending before the limit
        const sentences = truncated.split(/[.!?]\s+/);
        if (sentences.length > 1) {
          sentences.pop(); // Remove last sentence
          truncated = sentences.join('. ') + '.';
        } else {
          // If we can't preserve sentences, just truncate
          truncated = truncated.substring(0, truncated.length - 100);
        }
      }
      
      // Add indication that content was truncated
      ttsContent = truncated + '... 內容已截斷以符合語音合成限制。';
    }

    return ttsContent;
  }
}