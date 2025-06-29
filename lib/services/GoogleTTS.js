import { TextToSpeechClient } from "@google-cloud/text-to-speech";
import { RetryUtils } from "../utils/RetryUtils.js";
import chalk from "chalk";
import fs from "fs/promises";

export class GoogleTTSService {
  constructor() {
    this.client = new TextToSpeechClient();
  }

  async synthesizeSpeech(text, voiceConfig) {
    // Check text length - Google TTS has 5000 byte limit
    const textBytes = Buffer.byteLength(text, "utf8");

    if (textBytes > 4500) {
      // Leave some buffer
      console.log(
        chalk.yellow(`  ⚠️  Text too long (${textBytes} bytes), chunking...`),
      );
      return await this.synthesizeLongText(text, voiceConfig);
    }

    const operation = async () => {
      const [response] = await this.client.synthesizeSpeech({
        input: { text },
        voice: {
          languageCode: voiceConfig.languageCode,
          name: voiceConfig.name,
        },
        audioConfig: {
          audioEncoding: "LINEAR16",
          sampleRateHertz: 24000,
        },
      });
      return response;
    };

    return await RetryUtils.retryOperation(operation, {
      maxRetries: 3,
      initialDelay: 1000,
      retryCondition: RetryUtils.isRetryableError,
      onRetry: (error, attempt, maxRetries) => {
        console.log(
          chalk.yellow(
            `  🔄 TTS retry ${attempt}/${maxRetries}: ${error.message}`,
          ),
        );
      },
    });
  }

  async synthesizeLongText(text, voiceConfig) {
    const chunks = this.chunkText(text, 4000); // Conservative chunk size
    console.log(chalk.gray(`  📄 Processing ${chunks.length} chunks...`));

    const audioChunks = [];

    // Generate audio for each chunk
    for (let i = 0; i < chunks.length; i++) {
      const chunk = chunks[i];
      console.log(chalk.gray(`  🎵 Chunk ${i + 1}/${chunks.length}`));

      const operation = async () => {
        const [response] = await this.client.synthesizeSpeech({
          input: { text: chunk },
          voice: {
            languageCode: voiceConfig.languageCode,
            name: voiceConfig.name,
          },
          audioConfig: {
            audioEncoding: "LINEAR16",
            sampleRateHertz: 24000,
          },
        });
        return response;
      };

      const chunkResponse = await RetryUtils.retryOperation(operation, {
        maxRetries: 3,
        initialDelay: 1000,
        retryCondition: RetryUtils.isRetryableError,
        onRetry: (error, attempt, maxRetries) => {
          console.log(
            chalk.yellow(
              `  🔄 Chunk ${i + 1} retry ${attempt}/${maxRetries}: ${error.message}`,
            ),
          );
        },
      });

      audioChunks.push(chunkResponse.audioContent);
    }

    // Merge audio chunks using simple MP3 concatenation
    console.log(chalk.gray(`  🔧 Merging ${chunks.length} audio chunks...`));
    const mergedAudio = await this.mergeMP3Buffers(audioChunks);

    return { audioContent: mergedAudio };
  }

  async mergeMP3Buffers(audioChunks) {
    // For LINEAR16 PCM audio, we can seamlessly concatenate the raw audio data
    console.log(
      chalk.gray(`  🎶 Merging ${audioChunks.length} LINEAR16 audio chunks...`),
    );

    // LINEAR16 is raw PCM data that can be directly concatenated
    const mergedBuffer = Buffer.concat(audioChunks);

    // Convert to WAV format for better compatibility
    const wavBuffer = this.createWAVFromPCM(mergedBuffer, 24000, 16, 1);

    console.log(
      chalk.gray(
        `  ✅ Audio merge completed (${Math.round(wavBuffer.length / 1024)}KB WAV)`,
      ),
    );

    return wavBuffer;
  }

  createWAVFromPCM(pcmBuffer, sampleRate, bitsPerSample, channels) {
    const byteRate = sampleRate * channels * (bitsPerSample / 8);
    const blockAlign = channels * (bitsPerSample / 8);
    const dataSize = pcmBuffer.length;
    const fileSize = 36 + dataSize;

    const header = Buffer.alloc(44);
    let offset = 0;

    // RIFF header
    header.write("RIFF", offset);
    offset += 4;
    header.writeUInt32LE(fileSize, offset);
    offset += 4;
    header.write("WAVE", offset);
    offset += 4;

    // fmt chunk
    header.write("fmt ", offset);
    offset += 4;
    header.writeUInt32LE(16, offset);
    offset += 4; // Subchunk1Size
    header.writeUInt16LE(1, offset);
    offset += 2; // AudioFormat (PCM = 1)
    header.writeUInt16LE(channels, offset);
    offset += 2;
    header.writeUInt32LE(sampleRate, offset);
    offset += 4;
    header.writeUInt32LE(byteRate, offset);
    offset += 4;
    header.writeUInt16LE(blockAlign, offset);
    offset += 2;
    header.writeUInt16LE(bitsPerSample, offset);
    offset += 2;

    // data chunk
    header.write("data", offset);
    offset += 4;
    header.writeUInt32LE(dataSize, offset);

    return Buffer.concat([header, pcmBuffer]);
  }

  chunkText(text, maxBytes = 4000) {
    // Handle both English and Chinese content
    const sentencePatterns = /[.!?。！？]+\s*/g;
    const sentences = text.split(sentencePatterns).filter((s) => s.trim());

    const chunks = [];
    let currentChunk = "";

    for (let i = 0; i < sentences.length; i++) {
      const sentence = sentences[i].trim();
      if (!sentence) continue;

      // Try adding the sentence to current chunk
      const testChunk = currentChunk
        ? `${currentChunk}. ${sentence}`
        : sentence;
      const testBytes = Buffer.byteLength(testChunk, "utf8");

      if (testBytes > maxBytes && currentChunk) {
        // Current chunk is full, start new one
        chunks.push(currentChunk.trim());
        currentChunk = sentence;
      } else {
        currentChunk = testChunk;
      }
    }

    if (currentChunk.trim()) {
      chunks.push(currentChunk.trim());
    }

    // If we still have chunks that are too big, split by paragraphs
    const finalChunks = [];
    for (const chunk of chunks) {
      if (Buffer.byteLength(chunk, "utf8") > maxBytes) {
        const subChunks = this.splitByParagraphs(chunk, maxBytes);
        finalChunks.push(...subChunks);
      } else {
        finalChunks.push(chunk);
      }
    }

    return finalChunks.filter((chunk) => chunk.length > 0);
  }

  splitByParagraphs(text, maxBytes) {
    const paragraphs = text.split(/\n\s*\n/);
    const chunks = [];
    let currentChunk = "";

    for (const paragraph of paragraphs) {
      const testChunk = currentChunk
        ? `${currentChunk}\n\n${paragraph}`
        : paragraph;
      const testBytes = Buffer.byteLength(testChunk, "utf8");

      if (testBytes > maxBytes && currentChunk) {
        chunks.push(currentChunk.trim());
        currentChunk = paragraph;
      } else {
        currentChunk = testChunk;
      }
    }

    if (currentChunk.trim()) {
      chunks.push(currentChunk.trim());
    }

    return chunks;
  }

  static prepareContentForTTS(content, language) {
    // For English, if it has social format, use just the content part
    if (language === "en-US" && content.includes("🚀")) {
      // Extract content after social hook
      const parts = content.split("\n\n");
      if (parts.length > 1) {
        return parts.slice(1).join("\n\n");
      }
    }
    return content;
  }
}
