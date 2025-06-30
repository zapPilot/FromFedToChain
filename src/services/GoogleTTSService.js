import { TextToSpeechClient } from "@google-cloud/text-to-speech";

export class GoogleTTSService {
  constructor() {
    this.client = new TextToSpeechClient();
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

    return ttsContent;
  }
}