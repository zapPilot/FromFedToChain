import fs from "fs/promises";
import path from "path";
import chalk from "chalk";
import { spawn } from "child_process";

export class CloudflareR2Service {
  static REMOTE_NAME = "r2"; // R2 remote name in rclone config
  static BUCKET_NAME = "fromfedtochain"; // R2 bucket name
  static RCLONE_BINARY = "rclone"; // Assumes rclone is in PATH
  static BASE_URL =
    "https://fromfedtochain.1352ed9cb1e236fe232f67ff3a8e9850.r2.cloudflarestorage.com"; // Actual R2 domain

  /**
   * Upload audio files (WAV and M3U8) to Cloudflare R2
   * @param {string} id - Content ID
   * @param {string} language - Language code
   * @param {string} category - Content category
   * @param {Object} files - File paths to upload
   * @returns {Promise<Object>} - Upload result with URLs
   */
  static async uploadAudioFiles(id, language, category, files) {
    console.log(chalk.blue(`☁️ Uploading to R2: ${id} (${language})`));
    console.log(
      chalk.gray(`   Files to upload: ${Object.keys(files).join(", ")}`),
    );

    const uploadResults = {
      success: true,
      urls: {},
      errors: [],
    };

    try {
      // Create R2 directory structure: audio/{language}/{category}/{id}/
      const r2BasePath = `audio/${language}/${category}/${id}`;

      // WAV files are stored locally only, not uploaded to R2 for streaming

      // Upload M3U8 files if provided
      if (files.m3u8Data) {
        console.log(chalk.blue(`🎬 Uploading M3U8 files...`));
        console.log(chalk.gray(`   Playlist: ${files.m3u8Data.playlistPath}`));
        console.log(
          chalk.gray(`   Segments: ${files.m3u8Data.segments.length}`),
        );

        const m3u8Result = await this.uploadM3U8Files(
          files.m3u8Data,
          r2BasePath,
        );
        if (m3u8Result.success) {
          uploadResults.urls.m3u8 = `${this.BASE_URL}/${r2BasePath}/playlist.m3u8`;
          uploadResults.urls.segments = m3u8Result.segmentUrls;
          console.log(chalk.green(`✅ M3U8 files uploaded successfully`));
          console.log(
            chalk.gray(`   Playlist URL: ${uploadResults.urls.m3u8}`),
          );
          console.log(
            chalk.gray(
              `   Segments uploaded: ${m3u8Result.segmentUrls.length}`,
            ),
          );
        } else {
          console.error(
            chalk.red(`❌ M3U8 upload failed: ${m3u8Result.error}`),
          );
          uploadResults.errors.push(`M3U8 upload failed: ${m3u8Result.error}`);
          uploadResults.success = false;
        }
      } else {
        console.log(chalk.yellow(`⚠️ No M3U8 data provided for upload`));
      }

      if (uploadResults.success) {
        console.log(chalk.green(`✅ R2 upload completed: ${id} (${language})`));
        console.log(chalk.gray(`   M3U8: ${uploadResults.urls.m3u8 || "N/A"}`));
      } else {
        console.error(
          chalk.red(
            `❌ R2 upload had errors: ${uploadResults.errors.join(", ")}`,
          ),
        );
      }

      return uploadResults;
    } catch (error) {
      console.error(chalk.red(`❌ R2 upload failed: ${error.message}`));
      return {
        success: false,
        urls: {},
        errors: [error.message],
      };
    }
  }

  /**
   * Upload M3U8 playlist and segments to R2
   * @param {Object} m3u8Data - M3U8 data from M3U8AudioService
   * @param {string} r2BasePath - Base path in R2 bucket
   * @returns {Promise<Object>} - Upload result
   */
  static async uploadM3U8Files(m3u8Data, r2BasePath) {
    try {
      const segmentUrls = [];

      // Upload playlist file
      const playlistResult = await this.uploadFile(
        m3u8Data.playlistPath,
        `${r2BasePath}/playlist.m3u8`,
      );
      if (!playlistResult.success) {
        return {
          success: false,
          error: `Playlist upload failed: ${playlistResult.error}`,
        };
      }

      // Upload all segment files
      for (const segment of m3u8Data.segments) {
        const segmentPath = path.join(m3u8Data.segmentDir, segment);
        const segmentResult = await this.uploadFile(
          segmentPath,
          `${r2BasePath}/${segment}`,
        );

        if (segmentResult.success) {
          segmentUrls.push(`${this.BASE_URL}/${r2BasePath}/${segment}`);
        } else {
          return {
            success: false,
            error: `Segment upload failed: ${segmentResult.error}`,
          };
        }
      }

      return {
        success: true,
        segmentUrls,
      };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  /**
   * Upload a single file to R2 using rclone
   * @param {string} localPath - Local file path
   * @param {string} remotePath - Remote path in R2
   * @returns {Promise<Object>} - Upload result
   */
  static async uploadFile(localPath, remotePath) {
    console.log(
      chalk.gray(`   Uploading: ${path.basename(localPath)} → ${remotePath}`),
    );

    try {
      // Check if local file exists
      await fs.access(localPath);

      // Build rclone command using 'copyto' instead of 'copy' to avoid path duplication
      // This ensures the file is copied to the exact remote path specified
      const remoteFullPath = `${this.REMOTE_NAME}:${this.BUCKET_NAME}/${remotePath}`;
      const command = this.RCLONE_BINARY;
      const args = [
        "copyto", // Use 'copyto' instead of 'copy' to prevent directory creation
        localPath,
        remoteFullPath,
        "--progress",
        "--stats-one-line",
      ];

      // Execute rclone command
      const result = await this.executeRcloneCommand(command, args);

      if (result.success) {
        console.log(
          chalk.green(`     ✅ Uploaded: ${path.basename(localPath)}`),
        );
        return { success: true };
      } else {
        console.error(chalk.red(`     ❌ Upload failed: ${result.error}`));
        return { success: false, error: result.error };
      }
    } catch (error) {
      console.error(chalk.red(`     ❌ Upload error: ${error.message}`));
      return { success: false, error: error.message };
    }
  }

  /**
   * Execute rclone command with proper error handling
   * @param {string} command - Rclone command
   * @param {string[]} args - Command arguments
   * @returns {Promise<Object>} - Command result
   */
  static async executeRcloneCommand(command, args) {
    return new Promise((resolve) => {
      const process = spawn(command, args);
      let stdout = "";
      let stderr = "";

      process.stdout.on("data", (data) => {
        stdout += data.toString();
      });

      process.stderr.on("data", (data) => {
        stderr += data.toString();
      });

      process.on("close", (code) => {
        if (code === 0) {
          resolve({ success: true, output: stdout });
        } else {
          resolve({
            success: false,
            error: `rclone exited with code ${code}: ${stderr}`,
            output: stdout,
          });
        }
      });

      process.on("error", (error) => {
        resolve({
          success: false,
          error: `Failed to execute rclone: ${error.message}`,
        });
      });
    });
  }

  /**
   * List audio files in R2 bucket
   * @param {string} language - Language code (optional)
   * @param {string} category - Category (optional)
   * @returns {Promise<Object[]>} - List of files in R2
   */
  static async listR2Files(language = null, category = null) {
    console.log(chalk.blue(`📋 Listing R2 files...`));

    try {
      let remotePath = `${this.REMOTE_NAME}:${this.BUCKET_NAME}/audio`;

      if (language) {
        remotePath += `/${language}`;
        if (category) {
          remotePath += `/${category}`;
        }
      }

      const args = ["ls", remotePath, "--recursive"];
      const result = await this.executeRcloneCommand(this.RCLONE_BINARY, args);

      if (result.success) {
        const files = this.parseRcloneListOutput(result.output);
        console.log(chalk.green(`✅ Found ${files.length} files in R2`));
        return files;
      } else {
        console.error(chalk.red(`❌ Failed to list R2 files: ${result.error}`));
        return [];
      }
    } catch (error) {
      console.error(chalk.red(`❌ Error listing R2 files: ${error.message}`));
      return [];
    }
  }

  /**
   * Parse rclone ls output into structured data
   * @param {string} output - Raw rclone ls output
   * @returns {Object[]} - Parsed file list
   */
  static parseRcloneListOutput(output) {
    const files = [];
    const lines = output.split("\n").filter((line) => line.trim());

    for (const line of lines) {
      const match = line.match(/^\s*(\d+)\s+(.+)$/);
      if (match) {
        const size = parseInt(match[1]);
        const filePath = match[2];
        const pathParts = filePath.split("/");

        if (pathParts.length >= 4) {
          files.push({
            path: filePath,
            size: size,
            language: pathParts[1],
            category: pathParts[2],
            id: pathParts[3],
            filename: pathParts[pathParts.length - 1],
            url: `${this.BASE_URL}/${filePath}`,
          });
        }
      }
    }

    return files;
  }

  /**
   * Delete audio files from R2
   * @param {string} id - Content ID
   * @param {string} language - Language code
   * @param {string} category - Content category
   * @returns {Promise<boolean>} - Success status
   */
  static async deleteR2Files(id, language, category) {
    console.log(chalk.blue(`🗑️ Deleting R2 files: ${id} (${language})`));

    try {
      const remotePath = `${this.REMOTE_NAME}:${this.BUCKET_NAME}/audio/${language}/${category}/${id}`;
      const args = ["purge", remotePath];

      const result = await this.executeRcloneCommand(this.RCLONE_BINARY, args);

      if (result.success) {
        console.log(chalk.green(`✅ Deleted R2 files: ${id} (${language})`));
        return true;
      } else {
        console.error(
          chalk.red(`❌ Failed to delete R2 files: ${result.error}`),
        );
        return false;
      }
    } catch (error) {
      console.error(chalk.red(`❌ Error deleting R2 files: ${error.message}`));
      return false;
    }
  }

  /**
   * Check if rclone is available and configured
   * @returns {Promise<boolean>} - Availability status
   */
  static async checkRcloneAvailability() {
    try {
      console.log(chalk.blue(`🔍 Checking rclone availability...`));
      const result = await this.executeRcloneCommand(this.RCLONE_BINARY, [
        "version",
      ]);

      if (result.success) {
        console.log(chalk.green(`✅ rclone found and working`));

        // Check if remote is configured
        const configResult = await this.executeRcloneCommand(
          this.RCLONE_BINARY,
          ["listremotes"],
        );
        if (configResult.success) {
          const remotes = configResult.output
            .split("\n")
            .filter((line) => line.trim());
          console.log(
            chalk.blue(`📋 Available remotes: ${remotes.join(", ")}`),
          );

          if (configResult.output.includes(this.REMOTE_NAME)) {
            console.log(
              chalk.green(`✅ Remote '${this.REMOTE_NAME}' is configured`),
            );
            return true;
          } else {
            console.error(
              chalk.red(
                `❌ rclone remote '${this.REMOTE_NAME}' not configured`,
              ),
            );
            console.error(chalk.yellow(`💡 Configure remote with:`));
            console.error(
              chalk.yellow(`   rclone config create ${this.REMOTE_NAME} s3 \\`),
            );
            console.error(chalk.yellow(`     provider=Cloudflare \\`));
            console.error(
              chalk.yellow(`     access_key_id=YOUR_ACCESS_KEY \\`),
            );
            console.error(
              chalk.yellow(`     secret_access_key=YOUR_SECRET_KEY \\`),
            );
            console.error(
              chalk.yellow(
                `     endpoint=https://YOUR_ACCOUNT_ID.r2.cloudflarestorage.com \\`,
              ),
            );
            console.error(chalk.yellow(`     region=auto`));
            return false;
          }
        } else {
          console.error(
            chalk.red(
              `❌ Failed to list rclone remotes: ${configResult.error}`,
            ),
          );
          return false;
        }
      } else {
        console.error(chalk.red(`❌ rclone not available: ${result.error}`));
        console.error(chalk.yellow(`💡 Install rclone:`));
        console.error(
          chalk.yellow(`   curl https://rclone.org/install.sh | sudo bash`),
        );
        return false;
      }
    } catch (error) {
      console.error(chalk.red(`❌ Error checking rclone: ${error.message}`));
      return false;
    }
  }

  /**
   * Generate public URL for a file
   * @param {string} id - Content ID
   * @param {string} language - Language code
   * @param {string} category - Content category
   * @param {string} filename - Filename
   * @returns {string} - Public URL
   */
  static generatePublicUrl(id, language, category, filename) {
    return `${this.BASE_URL}/audio/${language}/${category}/${id}/${filename}`;
  }
}
