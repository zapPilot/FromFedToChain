import fs from "fs/promises";
import path from "path";
import chalk from "chalk";
import { PATHS } from "../../config/languages.js";

export class AudioStorageService {
  constructor() {
    this.audioRoot = PATHS.AUDIO_ROOT;
  }

  async initialize() {
    // Create audio directory structure
    await this.ensureDirectoryExists(this.audioRoot);

    // Create subdirectories for each language and category
    const languages = ["zh-TW", "en-US", "ja-JP"];
    const categories = ["daily-news", "ethereum", "macro"];

    for (const lang of languages) {
      for (const category of categories) {
        const dirPath = path.join(this.audioRoot, lang, category);
        await this.ensureDirectoryExists(dirPath);
      }
    }
  }

  async ensureDirectoryExists(dirPath) {
    try {
      await fs.mkdir(dirPath, { recursive: true });
    } catch (error) {
      if (error.code !== "EEXIST") {
        throw error;
      }
    }
  }

  async saveAudioFile(
    audioBuffer,
    fileId,
    language,
    category,
    extension = "wav",
  ) {
    await this.initialize();

    const fileName = `${fileId}.${extension}`;
    const filePath = path.join(this.audioRoot, language, category, fileName);

    console.log(chalk.gray(`  💾 Saving audio to: ${filePath}`));

    await fs.writeFile(filePath, audioBuffer);

    // Return the relative path from project root
    const relativePath = path.relative(".", filePath);
    console.log(chalk.green(`  ✅ Audio saved: ${relativePath}`));

    return relativePath;
  }

  async getAudioPath(fileId, language, category, extension = "wav") {
    const fileName = `${fileId}.${extension}`;
    const filePath = path.join(this.audioRoot, language, category, fileName);

    try {
      await fs.access(filePath);
      return path.relative(".", filePath);
    } catch (error) {
      return null; // File doesn't exist
    }
  }

  async audioFileExists(fileId, language, category, extension = "wav") {
    const audioPath = await this.getAudioPath(
      fileId,
      language,
      category,
      extension,
    );
    return audioPath !== null;
  }

  async deleteAudioFile(fileId, language, category, extension = "wav") {
    const fileName = `${fileId}.${extension}`;
    const filePath = path.join(this.audioRoot, language, category, fileName);

    try {
      await fs.unlink(filePath);
      console.log(
        chalk.yellow(`  🗑️  Deleted audio: ${path.relative(".", filePath)}`),
      );
      return true;
    } catch (error) {
      if (error.code !== "ENOENT") {
        console.log(chalk.red(`  ❌ Failed to delete audio: ${error.message}`));
      }
      return false;
    }
  }

  async listAudioFiles(language = null, category = null) {
    await this.initialize();

    const files = [];
    const languages = language ? [language] : ["zh-TW", "en-US", "ja-JP"];
    const categories = category
      ? [category]
      : ["daily-news", "ethereum", "macro"];

    for (const lang of languages) {
      for (const cat of categories) {
        const dirPath = path.join(this.audioRoot, lang, cat);

        try {
          const dirFiles = await fs.readdir(dirPath);

          for (const file of dirFiles) {
            if (file.endsWith(".wav") || file.endsWith(".mp3")) {
              const filePath = path.join(dirPath, file);
              const stats = await fs.stat(filePath);

              files.push({
                fileId: path.parse(file).name,
                language: lang,
                category: cat,
                extension: path.extname(file).slice(1),
                path: path.relative(".", filePath),
                size: stats.size,
                created: stats.birthtime,
                modified: stats.mtime,
              });
            }
          }
        } catch (error) {
          // Directory doesn't exist or is empty, skip
        }
      }
    }

    return files.sort((a, b) => b.modified - a.modified);
  }

  async getStorageStats() {
    const files = await this.listAudioFiles();

    const stats = {
      totalFiles: files.length,
      totalSize: files.reduce((sum, file) => sum + file.size, 0),
      byLanguage: {},
      byCategory: {},
      byExtension: {},
    };

    files.forEach((file) => {
      // By language
      if (!stats.byLanguage[file.language]) {
        stats.byLanguage[file.language] = { count: 0, size: 0 };
      }
      stats.byLanguage[file.language].count++;
      stats.byLanguage[file.language].size += file.size;

      // By category
      if (!stats.byCategory[file.category]) {
        stats.byCategory[file.category] = { count: 0, size: 0 };
      }
      stats.byCategory[file.category].count++;
      stats.byCategory[file.category].size += file.size;

      // By extension
      if (!stats.byExtension[file.extension]) {
        stats.byExtension[file.extension] = { count: 0, size: 0 };
      }
      stats.byExtension[file.extension].count++;
      stats.byExtension[file.extension].size += file.size;
    });

    return stats;
  }

  formatFileSize(bytes) {
    if (bytes === 0) return "0 B";
    const k = 1024;
    const sizes = ["B", "KB", "MB", "GB"];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + " " + sizes[i];
  }
}
