import chalk from "chalk";
import { ContentManager } from "../ContentManager.js";
import { ContentSchema } from "../ContentSchema.js";
import { TranslationService } from "./TranslationService.js";
import { AudioService } from "./AudioService.js";
import { SocialService } from "./SocialService.js";
import { M3U8AudioService } from "./M3U8AudioService.js";
import { CloudflareR2Service } from "./CloudflareR2Service.js";

export class ContentPipelineService {
  /**
   * Get content that needs processing for a specific status
   * @param {string} status - The current status to find content for
   * @returns {Promise<Array>} Array of content objects that need processing
   */
  static async getPendingContent(status) {
    try {
      const step = ContentSchema.getPipelineStep(status);
      if (!step) {
        console.warn(`No pipeline step found for status: ${status}`);
        return [];
      }

      // Get content with the specified status
      const content = await ContentManager.getByStatus(status);
      return content;
    } catch (error) {
      console.error(
        chalk.red(
          `❌ Error getting pending content for ${status}: ${error.message}`,
        ),
      );
      return [];
    }
  }

  /**
   * Get all pending content across all pipeline stages
   * @returns {Promise<Array>} Array of objects with content and pipeline info
   */
  static async getAllPendingContent() {
    const pendingContent = [];
    const pipelineConfig = ContentSchema.getPipelineConfig();

    for (const step of pipelineConfig) {
      const content = await this.getPendingContent(step.status);
      content.forEach((item) => {
        pendingContent.push({
          content: item,
          nextPhase: step.phase,
          currentStatus: step.status,
          nextStatus: step.nextStatus,
          description: step.description,
        });
      });
    }

    // Sort by date (newest first)
    return pendingContent.sort(
      (a, b) => new Date(b.content.date) - new Date(a.content.date),
    );
  }

  /**
   * Process content through the next pipeline step
   * @param {string} id - Content ID to process
   * @returns {Promise<boolean>} True if successful, false otherwise
   */
  static async processContentNextStep(id) {
    try {
      const sourceContent = await ContentManager.readSource(id);
      const currentStatus = sourceContent.status;

      const step = ContentSchema.getPipelineStep(currentStatus);
      if (!step) {
        console.warn(`No pipeline step found for status: ${currentStatus}`);
        return false;
      }

      if (!step.nextStatus) {
        console.log(
          `Content ${id} is in final pipeline stage (${currentStatus}). No next step.`,
        );
        return true;
      }

      console.log(
        chalk.blue(
          `🔄 Processing ${id}: ${currentStatus} → ${step.nextStatus}`,
        ),
      );
      console.log(chalk.gray(`   ${step.description}`));

      // Execute the appropriate processing step
      const success = await this.executeProcessingStep(id, step);

      if (success) {
        console.log(
          chalk.green(`✅ ${id}: ${currentStatus} → ${step.nextStatus}`),
        );
        return true;
      } else {
        console.error(
          chalk.red(`❌ Failed to process ${id} from ${currentStatus}`),
        );
        return false;
      }
    } catch (error) {
      console.error(chalk.red(`❌ Error processing ${id}: ${error.message}`));
      return false;
    }
  }

  /**
   * Execute the specific processing step based on the pipeline configuration
   * @param {string} id - Content ID
   * @param {Object} step - Pipeline step configuration
   * @returns {Promise<boolean>} Success status
   */
  static async executeProcessingStep(id, step) {
    try {
      switch (step.status) {
        case "reviewed":
          await TranslationService.translateAll(id);
          await ContentManager.updateSourceStatus(id, "translated");
          return true;

        case "translated":
          await AudioService.generateWavOnly(id);
          await ContentManager.updateSourceStatus(id, "wav");
          return true;

        case "wav":
          return await this.generateM3U8Step(id);

        case "m3u8":
          return await this.uploadToCloudflareStep(id);

        case "cloudflare":
          return await this.uploadContentToCloudflareStep(id);

        case "content":
          await SocialService.generateAllHooks(id);
          return true;

        default:
          console.error(`Unknown processing step: ${step.status}`);
          return false;
      }
    } catch (error) {
      console.error(chalk.red(`❌ Processing step failed: ${error.message}`));
      return false;
    }
  }

  /**
   * Generate M3U8 files for content (extracted from cli.js)
   */
  static async generateM3U8Step(id) {
    console.log(chalk.blue(`🎬 Converting to M3U8 for: ${id}`));

    try {
      // Get available languages for this content
      const availableLanguages = await ContentManager.getAvailableLanguages(id);

      // Import language configuration
      const { getAudioLanguages, shouldGenerateM3U8, getM3U8Config } =
        await import("../../config/languages.js");

      const audioLanguages = getAudioLanguages();
      const targetLanguages = availableLanguages.filter(
        (lang) => audioLanguages.includes(lang) && shouldGenerateM3U8(lang),
      );

      if (targetLanguages.length === 0) {
        console.log(
          chalk.yellow(`⚠️ No languages configured for M3U8 conversion`),
        );
        return false;
      }

      console.log(
        chalk.blue(
          `📝 Converting M3U8 for ${targetLanguages.length} languages: ${targetLanguages.join(", ")}`,
        ),
      );

      let allSuccessful = true;

      for (const language of targetLanguages) {
        try {
          const content = await ContentManager.read(id, language);
          const audioPath = content.audio_file;

          if (!audioPath) {
            throw new Error(`No audio file found for ${language}`);
          }

          const m3u8Config = getM3U8Config(language);
          const m3u8Result = await M3U8AudioService.convertToM3U8(
            audioPath,
            id,
            language,
            content.category,
            m3u8Config,
          );

          console.log(chalk.green(`✅ M3U8 converted for ${language}`));
        } catch (error) {
          console.error(
            chalk.red(
              `❌ M3U8 conversion failed for ${language}: ${error.message}`,
            ),
          );
          allSuccessful = false;
        }
      }

      if (allSuccessful) {
        await ContentManager.updateSourceStatus(id, "m3u8");
      }

      return allSuccessful;
    } catch (error) {
      console.error(chalk.red(`❌ M3U8 step failed: ${error.message}`));
      return false;
    }
  }

  /**
   * Upload audio files to Cloudflare R2 (extracted from cli.js)
   */
  static async uploadToCloudflareStep(id) {
    console.log(chalk.blue(`☁️ Uploading to Cloudflare R2 for: ${id}`));

    try {
      // Check if rclone is available
      const rcloneAvailable =
        await CloudflareR2Service.checkRcloneAvailability();
      if (!rcloneAvailable) {
        throw new Error(
          "rclone not available. Please install and configure rclone for Cloudflare R2.",
        );
      }

      // Get available languages for this content
      const availableLanguages = await ContentManager.getAvailableLanguages(id);

      // Import language configuration
      const { getAudioLanguages, shouldUploadToR2 } = await import(
        "../../config/languages.js"
      );

      const audioLanguages = getAudioLanguages();
      const targetLanguages = availableLanguages.filter(
        (lang) => audioLanguages.includes(lang) && shouldUploadToR2(lang),
      );

      if (targetLanguages.length === 0) {
        console.log(chalk.yellow(`⚠️ No languages configured for R2 upload`));
        return false;
      }

      console.log(
        chalk.blue(
          `📤 Uploading to R2 for ${targetLanguages.length} languages: ${targetLanguages.join(", ")}`,
        ),
      );

      let allSuccessful = true;

      for (const language of targetLanguages) {
        try {
          const content = await ContentManager.read(id, language);

          // Get M3U8 files for this content
          const m3u8Info = await M3U8AudioService.getM3U8Files(
            id,
            language,
            content.category,
          );

          if (!m3u8Info) {
            throw new Error(
              `No M3U8 files found for ${language}. Run M3U8 conversion first.`,
            );
          }

          // Upload only M3U8 files (no WAV files)
          const uploadFiles = {
            m3u8Data: m3u8Info,
          };

          const uploadResult = await CloudflareR2Service.uploadAudioFiles(
            id,
            language,
            content.category,
            uploadFiles,
          );

          if (uploadResult.success) {
            // Update content with streaming URLs
            await ContentManager.addAudio(
              id,
              language,
              content.audio_file,
              uploadResult.urls,
            );
            console.log(chalk.green(`✅ R2 upload completed for ${language}`));
          } else {
            throw new Error(uploadResult.errors.join(", "));
          }
        } catch (error) {
          console.error(
            chalk.red(`❌ R2 upload failed for ${language}: ${error.message}`),
          );
          allSuccessful = false;
        }
      }

      // Update source status to 'cloudflare' if all uploads successful
      if (allSuccessful && targetLanguages.length > 0) {
        await ContentManager.updateSourceStatus(id, "cloudflare");
      }

      return allSuccessful;
    } catch (error) {
      console.error(
        chalk.red(`❌ Cloudflare upload step failed: ${error.message}`),
      );
      return false;
    }
  }

  /**
   * Upload content files to Cloudflare R2 (extracted from cli.js)
   */
  static async uploadContentToCloudflareStep(id) {
    console.log(chalk.blue(`📄 Uploading content to Cloudflare R2: ${id}`));

    try {
      // Find all language versions of this content
      const contentFiles = await this.findContentFiles(id);

      if (contentFiles.length === 0) {
        throw new Error(`No content files found for: ${id}`);
      }

      console.log(
        chalk.blue(`Found ${contentFiles.length} content file(s) to upload`),
      );

      // Upload each language version
      for (const contentFile of contentFiles) {
        await this.uploadSingleContentFile(contentFile);
      }

      console.log(
        chalk.green(
          `✅ Content uploaded successfully: ${contentFiles.length} files`,
        ),
      );
      await ContentManager.updateSourceStatus(id, "content");

      return true;
    } catch (error) {
      console.error(chalk.red(`❌ Content upload failed: ${error.message}`));
      return false;
    }
  }

  /**
   * Find all language/category versions of content (helper method)
   */
  static async findContentFiles(id) {
    const fs = await import("fs/promises");
    const path = await import("path");

    const contentFiles = [];
    const contentDir = "content";

    try {
      const languages = await fs.readdir(contentDir);

      for (const lang of languages) {
        const langPath = path.join(contentDir, lang);
        const langStat = await fs.stat(langPath);
        if (!langStat.isDirectory()) continue;

        const categories = await fs.readdir(langPath);

        for (const category of categories) {
          const categoryPath = path.join(langPath, category);
          const categoryStat = await fs.stat(categoryPath);
          if (!categoryStat.isDirectory()) continue;

          const articlePath = path.join(categoryPath, `${id}.json`);

          try {
            await fs.access(articlePath);
            contentFiles.push({
              localPath: articlePath,
              r2Key: `content/${lang}/${category}/${id}.json`,
              language: lang,
              category: category,
              id: id,
            });
          } catch (error) {
            // File doesn't exist in this language/category combination
          }
        }
      }
    } catch (error) {
      console.error("Error finding content files:", error);
    }

    return contentFiles;
  }

  /**
   * Upload single content file (helper method)
   */
  static async uploadSingleContentFile(contentFile) {
    const { exec } = await import("child_process");
    const { promisify } = await import("util");
    const execAsync = promisify(exec);

    const { localPath, r2Key, language, category } = contentFile;

    console.log(
      chalk.gray(
        `Uploading: ${localPath} → r2:${CloudflareR2Service.BUCKET_NAME}/${r2Key}`,
      ),
    );

    const uploadCommand = `rclone copyto "${localPath}" "r2:${CloudflareR2Service.BUCKET_NAME}/${r2Key}"`;

    try {
      await execAsync(uploadCommand);
      console.log(
        chalk.green(
          `✅ Uploaded: ${language}/${category}/${contentFile.id}.json`,
        ),
      );
    } catch (error) {
      console.error(
        chalk.red(
          `❌ Upload failed: ${language}/${category}/${contentFile.id}.json - ${error.message}`,
        ),
      );
      throw error;
    }
  }

  /**
   * Get pipeline status summary for display
   * @param {Array} pendingContent - Array of pending content items
   * @returns {Object} Grouped content by phase
   */
  static getPhaseGroups(pendingContent) {
    const phaseGroups = {};
    pendingContent.forEach((item) => {
      if (!phaseGroups[item.nextPhase]) {
        phaseGroups[item.nextPhase] = [];
      }
      phaseGroups[item.nextPhase].push(item);
    });
    return phaseGroups;
  }

  /**
   * Get phase color for display
   * @param {string} phase - Phase name
   * @returns {Function} Chalk color function
   */
  static getPhaseColor(phase) {
    const colors = {
      translation: chalk.cyan,
      audio: chalk.green,
      content: chalk.blue,
      social: chalk.magenta,
    };
    return colors[phase] || chalk.white;
  }
}
