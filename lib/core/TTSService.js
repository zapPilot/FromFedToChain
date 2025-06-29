import fs from 'fs/promises';
import { createReadStream } from 'fs';
import { TextToSpeechClient } from '@google-cloud/text-to-speech';
import { google } from 'googleapis';
import { ContentManager } from './ContentManager.js';
import { FileUtils } from '../utils/FileUtils.js';
import { Logger } from '../utils/Logger.js';
import { ProgressBar } from '../utils/ProgressBar.js';
import { VOICE_CONFIG, PATHS } from '../../config/languages.js';

export class TTSService {
  constructor() {
    this.uploadRecords = {};
    this.uploadRecordsFile = './upload-records.json';
  }

  async loadUploadRecords() {
    try {
      const content = await fs.readFile(this.uploadRecordsFile, 'utf-8');
      this.uploadRecords = JSON.parse(content);
    } catch (error) {
      this.uploadRecords = {};
    }
    return this.uploadRecords;
  }

  async saveUploadRecords() {
    await fs.writeFile(this.uploadRecordsFile, JSON.stringify(this.uploadRecords, null, 2));
  }

  generateFileHash(fileId, language, content) {
    const start = content.substring(0, 50);
    const end = content.substring(content.length - 50);
    return `${fileId}_${language}_${content.length}_${Buffer.from(start + end).toString('base64').substring(0, 10)}`;
  }

  isAlreadyUploaded(fileId, language, content) {
    const hash = this.generateFileHash(fileId, language, content);
    return this.uploadRecords[hash] || null;
  }

  async recordUpload(fileId, language, content, driveUrl) {
    const hash = this.generateFileHash(fileId, language, content);
    this.uploadRecords[hash] = {
      fileId,
      language,
      driveUrl,
      uploadedAt: new Date().toISOString(),
      contentLength: content.length
    };
    await this.saveUploadRecords();
  }

  prepareContentForTTS(content, language) {
    // For English, if it has social format, use just the content part
    if (language === 'en-US' && content.includes('🚀')) {
      const parts = content.split('\n\n');
      if (parts.length > 1) {
        return parts.slice(1).join('\n\n');
      }
    }
    return content;
  }

  async initializeClients() {
    process.env.GOOGLE_APPLICATION_CREDENTIALS = PATHS.SERVICE_ACCOUNT;
    
    const ttsClient = new TextToSpeechClient();
    const auth = new google.auth.GoogleAuth({
      scopes: ["https://www.googleapis.com/auth/drive.file"],
    });
    const authClient = await auth.getClient();
    const drive = google.drive({ version: "v3", auth: authClient });
    
    return { ttsClient, drive };
  }

  truncateContentForTTS(content, maxBytes = 4800) {
    // Leave some buffer under 5000 bytes
    const encoder = new TextEncoder();
    let truncated = content;
    
    while (encoder.encode(truncated).length > maxBytes) {
      // Find last sentence boundary before the limit
      const sentences = truncated.split(/[。！？\.!?]/);
      sentences.pop(); // Remove last (incomplete) sentence
      truncated = sentences.join('。') + '。';
      
      // If still too long, try paragraph boundaries
      if (encoder.encode(truncated).length > maxBytes) {
        const paragraphs = truncated.split('\n\n');
        paragraphs.pop();
        truncated = paragraphs.join('\n\n');
      }
      
      // Last resort: character truncation
      if (encoder.encode(truncated).length > maxBytes) {
        while (encoder.encode(truncated).length > maxBytes && truncated.length > 0) {
          truncated = truncated.slice(0, -1);
        }
        break;
      }
    }
    
    return truncated;
  }

  async generateLongAudio(file, ttsClient, drive, ttsContent, voiceConfig) {
    // For now, truncate content to fit within limits
    Logger.warning('⚠️  Content exceeds 5000 bytes. Truncating to fit standard TTS API...');
    const truncatedContent = this.truncateContentForTTS(ttsContent);
    
    Logger.info(`📝 Truncated from ${Buffer.byteLength(ttsContent, 'utf8')} to ${Buffer.byteLength(truncatedContent, 'utf8')} bytes`);
    
    // Generate speech with truncated content
    const [response] = await ttsClient.synthesizeSpeech({
      input: { text: truncatedContent },
      voice: {
        languageCode: voiceConfig.languageCode,
        name: voiceConfig.name
      },
      audioConfig: { audioEncoding: "MP3" },
    });

    // Save temporary file
    const fileName = `${file.id}_${file.language}.mp3`;
    const tempPath = `/tmp/${fileName}`;
    await fs.writeFile(tempPath, response.audioContent, "binary");

    // Upload to Google Drive
    const uploaded = await drive.files.create({
      requestBody: {
        name: fileName,
        mimeType: "audio/mpeg",
        parents: [voiceConfig.folderId]
      },
      media: {
        mimeType: "audio/mpeg",
        body: createReadStream(tempPath),
      },
    });

    const driveUrl = `https://drive.google.com/file/d/${uploaded.data.id}/view`;
    
    // Record upload and update file
    await this.recordUpload(file.id, file.language, truncatedContent, driveUrl);
    await ContentManager.updateContent(file.path, {
      metadata: {
        tts: {
          [file.language]: {
            status: 'completed',
            audio_url: driveUrl
          }
        }
      }
    });

    // Clean up
    await fs.unlink(tempPath);
    
    Logger.success(`✅ Uploaded (truncated): ${driveUrl}`);
    return driveUrl;
  }

  async generateAndUpload(file, ttsClient, drive) {
    const voiceConfig = VOICE_CONFIG[file.language];
    if (!voiceConfig) {
      throw new Error(`No voice configuration for language: ${file.language}`);
    }

    const ttsContent = this.prepareContentForTTS(file.content, file.language);
    
    // Check for existing upload
    const existing = this.isAlreadyUploaded(file.id, file.language, ttsContent);
    if (existing) {
      Logger.warning(`⏭️  Already uploaded: ${existing.driveUrl}`);
      await ContentManager.updateContent(file.path, {
        metadata: {
          tts: {
            [file.language]: {
              status: 'completed',
              audio_url: existing.driveUrl
            }
          }
        }
      });
      return existing.driveUrl;
    }

    // Check content length and use appropriate API
    const contentBytes = Buffer.byteLength(ttsContent, 'utf8');
    if (contentBytes > 5000) {
      Logger.warning(`⚠️  Content too long (${contentBytes} bytes). Using Long Audio API...`);
      return await this.generateLongAudio(file, ttsClient, drive, ttsContent, voiceConfig);
    }

    // Generate speech using standard API
    const [response] = await ttsClient.synthesizeSpeech({
      input: { text: ttsContent },
      voice: {
        languageCode: voiceConfig.languageCode,
        name: voiceConfig.name
      },
      audioConfig: { audioEncoding: "MP3" },
    });

    // Save temporary file
    const fileName = `${file.id}_${file.language}.mp3`;
    const tempPath = `/tmp/${fileName}`;
    await fs.writeFile(tempPath, response.audioContent, "binary");

    // Upload to Google Drive
    const uploaded = await drive.files.create({
      requestBody: {
        name: fileName,
        mimeType: "audio/mpeg",
        parents: [voiceConfig.folderId]
      },
      media: {
        mimeType: "audio/mpeg",
        body: createReadStream(tempPath),
      },
    });

    const driveUrl = `https://drive.google.com/file/d/${uploaded.data.id}/view`;
    
    // Record upload and update file
    await this.recordUpload(file.id, file.language, ttsContent, driveUrl);
    await ContentManager.updateContent(file.path, {
      metadata: {
        tts: {
          [file.language]: {
            status: 'completed',
            audio_url: driveUrl
          }
        }
      }
    });

    // Clean up
    await fs.unlink(tempPath);
    
    Logger.success(`✅ Uploaded: ${driveUrl}`);
    return driveUrl;
  }

  async processAll() {
    Logger.title('🎙️ TTS Processing');
    
    await this.loadUploadRecords();
    Logger.gray(`Found ${Object.keys(this.uploadRecords).length} existing upload records`);
    
    const { ttsClient, drive } = await this.initializeClients();
    const files = await ContentManager.getFilesForTTS();
    
    if (files.length === 0) {
      Logger.success('✅ No pending TTS content found');
      return;
    }
    
    Logger.info(`📝 Found ${files.length} files with pending TTS`);
    
    const progress = new ProgressBar(files.length);
    progress.start();
    
    let successCount = 0;
    for (let i = 0; i < files.length; i++) {
      const file = files[i];
      progress.update(i, `${file.language}: ${file.title}`);
      
      try {
        await this.generateAndUpload(file, ttsClient, drive);
        successCount++;
      } catch (error) {
        Logger.error(`❌ Failed: ${file.language}/${file.id}: ${error.message}`);
      }
    }
    
    progress.update(files.length, 'Complete!');
    progress.stop();
    
    Logger.success(`🎉 TTS processing completed! ${successCount}/${files.length} successful`);
  }
}