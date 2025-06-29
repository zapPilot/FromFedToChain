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

    // Generate speech
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