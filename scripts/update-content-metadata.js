#!/usr/bin/env node

import fs from "fs/promises";
import path from "path";
import chalk from "chalk";
import { MockM3U8Generator } from "./mock-m3u8-generator.js";

export class ContentMetadataUpdater {
  static CONTENT_DIR = "./content";
  static MOCK_DOMAIN = "https://mock-r2.fromfedtochain.com";

  constructor(options = {}) {
    this.dryRun = options.dryRun || false;
    this.verbose = options.verbose || false;
    this.forceUpdate = options.forceUpdate || false;
    this.backupFiles = options.backupFiles || true;
  }

  /**
   * Update all content files with streaming URLs
   */
  async updateAllContentFiles() {
    console.log(chalk.blue('📝 Updating content metadata with streaming URLs'));
    console.log('================================================');

    try {
      // Discover all content files
      const contentFiles = await this.discoverContentFiles();
      console.log(chalk.green(`Found ${contentFiles.length} content files`));

      // Update each content file
      const results = {
        updated: [],
        skipped: [],
        errors: [],
        backed_up: []
      };

      for (const contentFile of contentFiles) {
        const result = await this.updateContentFile(contentFile);
        
        if (result.success) {
          results.updated.push(result);
          if (result.backedUp) {
            results.backed_up.push(result);
          }
        } else if (result.skipped) {
          results.skipped.push(result);
        } else {
          results.errors.push(result);
        }
      }

      // Log results
      this.logUpdateResults(results);

      return results;

    } catch (error) {
      console.error(chalk.red(`❌ Content metadata update failed: ${error.message}`));
      throw error;
    }
  }

  /**
   * Update a single content file
   * @param {Object} contentFile - Content file information
   * @returns {Promise<Object>} - Update result
   */
  async updateContentFile(contentFile) {
    const { id, language, category, filePath, data, hasStreamingUrls } = contentFile;

    try {
      // Skip if already has streaming URLs and not forcing update
      if (hasStreamingUrls && !this.forceUpdate) {
        if (this.verbose) {
          console.log(chalk.gray(`   Skipping (has URLs): ${id} (${language})`));
        }
        return { success: false, skipped: true, id, language, category };
      }

      // Create backup if enabled
      let backupPath = null;
      if (this.backupFiles && !this.dryRun) {
        backupPath = await this.createBackup(filePath);
      }

      // Check if corresponding M3U8 exists
      const m3u8Exists = await MockM3U8Generator.m3u8Exists(id, language, category);
      
      // Get M3U8 metadata if available
      let m3u8Metadata = null;
      if (m3u8Exists) {
        m3u8Metadata = await this.getM3U8Metadata(id, language, category);
      }

      // Generate streaming URLs
      const streamingUrls = this.generateStreamingUrls(id, language, category, m3u8Metadata);

      // Update content data
      const updatedData = {
        ...data,
        streaming_urls: streamingUrls,
        mock_data: true,
        mock_generated_at: new Date().toISOString()
      };

      // Write updated content
      if (!this.dryRun) {
        await fs.writeFile(filePath, JSON.stringify(updatedData, null, 2));
        console.log(chalk.green(`   ✅ Updated: ${id} (${language})`));
      } else {
        console.log(chalk.gray(`   [DRY RUN] Would update: ${id} (${language})`));
      }

      return {
        success: true,
        id,
        language,
        category,
        streamingUrls,
        backupPath,
        backedUp: !!backupPath,
        m3u8Available: m3u8Exists
      };

    } catch (error) {
      console.error(chalk.red(`   ❌ Failed to update ${id} (${language}): ${error.message}`));
      return {
        success: false,
        id,
        language,
        category,
        error: error.message
      };
    }
  }

  /**
   * Generate streaming URLs for content
   * @param {string} id - Content ID
   * @param {string} language - Language code
   * @param {string} category - Content category
   * @param {Object} m3u8Metadata - M3U8 metadata if available
   * @returns {Object} - Streaming URLs object
   */
  generateStreamingUrls(id, language, category, m3u8Metadata) {
    const basePath = `${this.MOCK_DOMAIN}/audio/${language}/${category}/${id}`;
    
    const streamingUrls = {
      wav: `${basePath}/audio.wav`,
      baseUrl: basePath
    };

    if (m3u8Metadata) {
      streamingUrls.m3u8 = `${basePath}/playlist.m3u8`;
      streamingUrls.segments = m3u8Metadata.segments.map(segment => `${basePath}/${segment}`);
      streamingUrls.duration = m3u8Metadata.totalDuration;
      streamingUrls.segmentCount = m3u8Metadata.segmentCount;
    } else {
      streamingUrls.m3u8 = null;
      streamingUrls.segments = [];
      streamingUrls.duration = null;
      streamingUrls.segmentCount = 0;
    }

    return streamingUrls;
  }

  /**
   * Get M3U8 metadata for content
   * @param {string} id - Content ID
   * @param {string} language - Language code
   * @param {string} category - Content category
   * @returns {Promise<Object|null>} - M3U8 metadata or null
   */
  async getM3U8Metadata(id, language, category) {
    const m3u8Dir = path.join("audio", "m3u8", language, category, id);
    const metadataPath = path.join(m3u8Dir, "metadata.json");

    try {
      const metadataContent = await fs.readFile(metadataPath, 'utf-8');
      return JSON.parse(metadataContent);
    } catch (error) {
      // Fallback: read playlist file and extract basic info
      const playlistPath = path.join(m3u8Dir, "playlist.m3u8");
      try {
        const playlistContent = await fs.readFile(playlistPath, 'utf-8');
        const segments = this.extractSegmentsFromPlaylist(playlistContent);
        const duration = this.extractDurationFromPlaylist(playlistContent);
        
        return {
          segments,
          totalDuration: duration,
          segmentCount: segments.length
        };
      } catch (playlistError) {
        return null;
      }
    }
  }

  /**
   * Extract segment filenames from M3U8 playlist
   * @param {string} playlistContent - M3U8 playlist content
   * @returns {Array} - Array of segment filenames
   */
  extractSegmentsFromPlaylist(playlistContent) {
    const lines = playlistContent.split('\n');
    const segments = [];
    
    for (const line of lines) {
      const trimmed = line.trim();
      if (trimmed.endsWith('.ts')) {
        segments.push(trimmed);
      }
    }
    
    return segments;
  }

  /**
   * Extract total duration from M3U8 playlist
   * @param {string} playlistContent - M3U8 playlist content
   * @returns {number} - Total duration in seconds
   */
  extractDurationFromPlaylist(playlistContent) {
    const lines = playlistContent.split('\n');
    let totalDuration = 0;
    
    for (const line of lines) {
      const trimmed = line.trim();
      if (trimmed.startsWith('#EXTINF:')) {
        const match = trimmed.match(/#EXTINF:([0-9.]+),/);
        if (match) {
          totalDuration += parseFloat(match[1]);
        }
      }
    }
    
    return totalDuration;
  }

  /**
   * Create backup of content file
   * @param {string} filePath - Path to content file
   * @returns {Promise<string>} - Backup file path
   */
  async createBackup(filePath) {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const backupDir = path.join(path.dirname(filePath), '.backups');
    const backupFileName = `${path.basename(filePath, '.json')}_${timestamp}.json`;
    const backupPath = path.join(backupDir, backupFileName);

    try {
      await fs.mkdir(backupDir, { recursive: true });
      await fs.copyFile(filePath, backupPath);
      
      if (this.verbose) {
        console.log(chalk.blue(`   💾 Backup created: ${backupPath}`));
      }
      
      return backupPath;
    } catch (error) {
      console.warn(chalk.yellow(`   ⚠️ Failed to create backup: ${error.message}`));
      return null;
    }
  }

  /**
   * Discover all content files
   * @returns {Promise<Array>} - Array of content file information
   */
  async discoverContentFiles() {
    const contentFiles = [];
    const languages = await fs.readdir(this.CONTENT_DIR);

    for (const language of languages) {
      const languagePath = path.join(this.CONTENT_DIR, language);
      const languageStat = await fs.stat(languagePath);
      
      if (!languageStat.isDirectory()) continue;

      const categories = await fs.readdir(languagePath);
      
      for (const category of categories) {
        const categoryPath = path.join(languagePath, category);
        const categoryStat = await fs.stat(categoryPath);
        
        if (!categoryStat.isDirectory()) continue;

        const files = await fs.readdir(categoryPath);
        
        for (const file of files) {
          if (file.endsWith('.json') && !file.startsWith('.')) {
            const filePath = path.join(categoryPath, file);
            const id = path.basename(file, '.json');
            
            try {
              const content = await fs.readFile(filePath, 'utf-8');
              const data = JSON.parse(content);
              
              contentFiles.push({
                id,
                language,
                category,
                filePath,
                data,
                hasAudioFile: !!data.audio_file,
                hasStreamingUrls: !!data.streaming_urls,
                isMockData: !!data.mock_data
              });
            } catch (error) {
              console.warn(chalk.yellow(`⚠️ Failed to parse: ${filePath}`));
            }
          }
        }
      }
    }

    return contentFiles;
  }

  /**
   * Remove streaming URLs from all content files
   */
  async removeStreamingUrls() {
    console.log(chalk.blue('🧹 Removing streaming URLs from content files'));
    console.log('==============================================');

    const contentFiles = await this.discoverContentFiles();
    const results = { removed: [], skipped: [], errors: [] };

    for (const contentFile of contentFiles) {
      const { id, language, category, filePath, data, hasStreamingUrls } = contentFile;

      try {
        if (!hasStreamingUrls) {
          results.skipped.push({ id, language, category });
          continue;
        }

        // Remove streaming URLs and mock data fields
        const { streaming_urls, mock_data, mock_generated_at, ...cleanData } = data;

        if (!this.dryRun) {
          await fs.writeFile(filePath, JSON.stringify(cleanData, null, 2));
          console.log(chalk.green(`   ✅ Cleaned: ${id} (${language})`));
        } else {
          console.log(chalk.gray(`   [DRY RUN] Would clean: ${id} (${language})`));
        }

        results.removed.push({ id, language, category });

      } catch (error) {
        console.error(chalk.red(`   ❌ Failed to clean ${id} (${language}): ${error.message}`));
        results.errors.push({ id, language, category, error: error.message });
      }
    }

    console.log(chalk.green(`\n✅ Removed streaming URLs from ${results.removed.length} files`));
    if (results.skipped.length > 0) {
      console.log(chalk.yellow(`⏩ Skipped ${results.skipped.length} files (no URLs)`));
    }
    if (results.errors.length > 0) {
      console.log(chalk.red(`❌ Errors: ${results.errors.length}`));
    }

    return results;
  }

  /**
   * Log update results
   * @param {Object} results - Update results
   */
  logUpdateResults(results) {
    console.log(chalk.green(`\n✅ Updated ${results.updated.length} content files`));
    
    if (results.skipped.length > 0) {
      console.log(chalk.yellow(`⏩ Skipped ${results.skipped.length} files (already have URLs)`));
    }
    
    if (results.backed_up.length > 0) {
      console.log(chalk.blue(`💾 Created ${results.backed_up.length} backup files`));
    }
    
    if (results.errors.length > 0) {
      console.log(chalk.red(`❌ Errors: ${results.errors.length}`));
      
      if (this.verbose) {
        results.errors.forEach(error => {
          console.log(chalk.red(`   - ${error.id} (${error.language}): ${error.error}`));
        });
      }
    }
  }
}

// CLI interface
async function main() {
  const args = process.argv.slice(2);
  const options = {
    dryRun: args.includes('--dry-run'),
    verbose: args.includes('--verbose'),
    forceUpdate: args.includes('--force'),
    backupFiles: !args.includes('--no-backup')
  };

  const updater = new ContentMetadataUpdater(options);

  if (args.includes('--remove')) {
    await updater.removeStreamingUrls();
  } else {
    await updater.updateAllContentFiles();
  }
}

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
  main().catch(console.error);
}