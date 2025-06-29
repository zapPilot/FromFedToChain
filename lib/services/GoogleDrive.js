import { google } from "googleapis";
import { createReadStream } from "fs";
import { RetryUtils } from '../utils/RetryUtils.js';
import chalk from 'chalk';

export class GoogleDriveService {
  constructor() {
    this.drive = null;
  }

  async initialize() {
    if (this.drive) return;

    const auth = new google.auth.GoogleAuth({
      scopes: ["https://www.googleapis.com/auth/drive.file"],
    });
    const authClient = await auth.getClient();
    this.drive = google.drive({ version: "v3", auth: authClient });
  }

  async uploadFile(filePath, fileName, folderId, mimeType = "audio/mpeg") {
    await this.initialize();

    const operation = async () => {
      return await this.drive.files.create({
        requestBody: {
          name: fileName,
          mimeType: mimeType,
          parents: [folderId]
        },
        media: {
          mimeType: mimeType,
          body: createReadStream(filePath),
        },
      });
    };

    const result = await RetryUtils.retryOperation(operation, {
      maxRetries: 3,
      initialDelay: 2000,
      retryCondition: RetryUtils.isRetryableError,
      onRetry: (error, attempt, maxRetries) => {
        console.log(chalk.yellow(`  🔄 Drive upload retry ${attempt}/${maxRetries}: ${error.message}`));
      }
    });

    return `https://drive.google.com/file/d/${result.data.id}/view`;
  }

  static getFolderId(voiceConfig, category) {
    const folderId = voiceConfig.folders?.[category];
    if (!folderId) {
      throw new Error(`No folder ID found for category '${category}' in voice config`);
    }
    return folderId;
  }
}