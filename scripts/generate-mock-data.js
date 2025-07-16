#!/usr/bin/env node

import fs from "fs/promises";
import path from "path";
import chalk from "chalk";
import { MockM3U8Generator } from "./mock-m3u8-generator.js";

class MockDataGenerator {
  static CONTENT_DIR = "./content";
  static AUDIO_DIR = "./audio";
  static MOCK_DOMAIN = "https://mock-r2.fromfedtochain.com";

  constructor(options = {}) {
    this.dryRun = options.dryRun || false;
    this.verbose = options.verbose || false;
    this.forceRegenerate = options.forceRegenerate || false;
    this.skipExisting = options.skipExisting || true;
  }

  /**
   * Main entry point for mock data generation
   */
  async generateMockData() {
    console.log(chalk.blue('🎭 Generating Mock Data for Flutter UI Development'));
    console.log('====================================================');

    if (this.dryRun) {
      console.log(chalk.yellow('🔍 DRY RUN MODE - No files will be created'));
    }

    try {
      // Step 1: Discover existing content and audio files
      console.log(chalk.blue('\n1. Discovering existing content and audio files...'));
      const discovery = await this.discoverExistingFiles();
      this.logDiscoveryResults(discovery);

      // Step 2: Generate M3U8 files for existing audio
      console.log(chalk.blue('\n2. Generating mock M3U8 files...'));
      const m3u8Results = await this.generateM3U8Files(discovery.audioFiles);
      this.logM3U8Results(m3u8Results);

      // Step 3: Update content metadata with streaming URLs
      console.log(chalk.blue('\n3. Updating content metadata with streaming URLs...'));
      const metadataResults = await this.updateContentMetadata(discovery.contentFiles, m3u8Results);
      this.logMetadataResults(metadataResults);

      // Step 4: Generate summary report
      console.log(chalk.blue('\n4. Generating summary report...'));
      const summary = await this.generateSummaryReport(discovery, m3u8Results, metadataResults);
      this.logSummaryReport(summary);

      console.log(chalk.green('\n✅ Mock data generation completed successfully!'));
      console.log(chalk.blue('🚀 Your Flutter app is now ready for UI development and iteration.'));

    } catch (error) {
      console.error(chalk.red(`❌ Mock data generation failed: ${error.message}`));
      if (this.verbose) {
        console.error(error.stack);
      }
      process.exit(1);
    }
  }

  /**
   * Discover existing content and audio files
   * @returns {Promise<Object>} - Discovery results
   */
  async discoverExistingFiles() {
    const contentFiles = await this.discoverContentFiles();
    const audioFiles = await this.discoverAudioFiles();
    
    // Match content files with their audio counterparts
    const matches = [];
    const mismatches = [];

    contentFiles.forEach(content => {
      const audioFile = audioFiles.find(audio => 
        audio.id === content.id && 
        audio.language === content.language && 
        audio.category === content.category
      );
      
      if (audioFile) {
        matches.push({ content, audio: audioFile });
      } else {
        mismatches.push({ content, audio: null });
      }
    });

    return {
      contentFiles,
      audioFiles,
      matches,
      mismatches,
      stats: {
        totalContent: contentFiles.length,
        totalAudio: audioFiles.length,
        matched: matches.length,
        mismatched: mismatches.length
      }
    };
  }

  /**
   * Discover all content files
   * @returns {Promise<Array>} - Array of content file info
   */
  async discoverContentFiles() {
    const contentFiles = [];
    const languages = await fs.readdir(MockDataGenerator.CONTENT_DIR);

    for (const language of languages) {
      const languagePath = path.join(MockDataGenerator.CONTENT_DIR, language);
      const languageStat = await fs.stat(languagePath);
      
      if (!languageStat.isDirectory()) continue;

      const categories = await fs.readdir(languagePath);
      
      for (const category of categories) {
        const categoryPath = path.join(languagePath, category);
        const categoryStat = await fs.stat(categoryPath);
        
        if (!categoryStat.isDirectory()) continue;

        const files = await fs.readdir(categoryPath);
        
        for (const file of files) {
          if (file.endsWith('.json')) {
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
                hasStreamingUrls: !!data.streaming_urls
              });
            } catch (error) {
              console.warn(chalk.yellow(`⚠️ Failed to parse content file: ${filePath}`));
            }
          }
        }
      }
    }

    return contentFiles;
  }

  /**
   * Discover all audio files
   * @returns {Promise<Array>} - Array of audio file info
   */
  async discoverAudioFiles() {
    const audioFiles = [];
    const audioPath = MockDataGenerator.AUDIO_DIR;

    try {
      const languages = await fs.readdir(audioPath);

      for (const language of languages) {
        const languagePath = path.join(audioPath, language);
        const languageStat = await fs.stat(languagePath);
        
        if (!languageStat.isDirectory() || language === 'm3u8') continue;

        const categories = await fs.readdir(languagePath);
        
        for (const category of categories) {
          const categoryPath = path.join(languagePath, category);
          const categoryStat = await fs.stat(categoryPath);
          
          if (!categoryStat.isDirectory()) continue;

          const files = await fs.readdir(categoryPath);
          
          for (const file of files) {
            if (file.endsWith('.wav')) {
              const filePath = path.join(categoryPath, file);
              const id = path.basename(file, '.wav');
              const stats = await fs.stat(filePath);
              
              audioFiles.push({
                id,
                language,
                category,
                filePath,
                size: stats.size,
                created: stats.birthtime.toISOString()
              });
            }
          }
        }
      }
    } catch (error) {
      console.warn(chalk.yellow(`⚠️ Audio directory not found: ${audioPath}`));
    }

    return audioFiles;
  }

  /**
   * Generate M3U8 files for audio files
   * @param {Array} audioFiles - Array of audio file info
   * @returns {Promise<Object>} - Generation results
   */
  async generateM3U8Files(audioFiles) {
    const results = {
      generated: [],
      skipped: [],
      errors: []
    };

    for (const audioFile of audioFiles) {
      const { id, language, category, filePath } = audioFile;
      
      try {
        // Check if M3U8 already exists
        const exists = await MockM3U8Generator.m3u8Exists(id, language, category);
        
        if (exists && this.skipExisting && !this.forceRegenerate) {
          if (this.verbose) {
            console.log(chalk.gray(`   Skipping existing M3U8: ${id} (${language})`));
          }
          results.skipped.push({ id, language, category });
          continue;
        }

        if (!this.dryRun) {
          const m3u8Result = await MockM3U8Generator.generateMockM3U8(
            filePath,
            id,
            language,
            category
          );
          
          if (m3u8Result.success) {
            results.generated.push({
              id,
              language,
              category,
              ...m3u8Result
            });
          } else {
            results.errors.push({
              id,
              language,
              category,
              error: 'M3U8 generation failed'
            });
          }
        } else {
          console.log(chalk.gray(`   [DRY RUN] Would generate M3U8: ${id} (${language})`));
          results.generated.push({ id, language, category });
        }

      } catch (error) {
        console.error(chalk.red(`❌ Failed to generate M3U8 for ${id} (${language}): ${error.message}`));
        results.errors.push({
          id,
          language,
          category,
          error: error.message
        });
      }
    }

    return results;
  }

  /**
   * Update content metadata with streaming URLs
   * @param {Array} contentFiles - Array of content file info
   * @param {Object} m3u8Results - M3U8 generation results
   * @returns {Promise<Object>} - Update results
   */
  async updateContentMetadata(contentFiles, m3u8Results) {
    const results = {
      updated: [],
      skipped: [],
      errors: []
    };

    for (const contentFile of contentFiles) {
      const { id, language, category, filePath, data, hasStreamingUrls } = contentFile;
      
      try {
        // Skip if already has streaming URLs and not forcing regeneration
        if (hasStreamingUrls && !this.forceRegenerate) {
          if (this.verbose) {
            console.log(chalk.gray(`   Skipping content with existing URLs: ${id} (${language})`));
          }
          results.skipped.push({ id, language, category });
          continue;
        }

        // Find corresponding M3U8 result
        const m3u8Data = m3u8Results.generated.find(m3u8 => 
          m3u8.id === id && m3u8.language === language && m3u8.category === category
        );

        if (m3u8Data) {
          // Generate streaming URLs
          const streamingUrls = MockM3U8Generator.generateStreamingUrls(
            id,
            language,
            category,
            m3u8Data.segments || []
          );

          // Update content data
          const updatedData = {
            ...data,
            streaming_urls: streamingUrls,
            mock_data: true,
            mock_generated_at: new Date().toISOString()
          };

          if (!this.dryRun) {
            await fs.writeFile(filePath, JSON.stringify(updatedData, null, 2));
            results.updated.push({
              id,
              language,
              category,
              streamingUrls
            });
          } else {
            console.log(chalk.gray(`   [DRY RUN] Would update content: ${id} (${language})`));
            results.updated.push({ id, language, category });
          }
        } else {
          // No M3U8 data found, but still add basic streaming URLs
          const streamingUrls = MockM3U8Generator.generateStreamingUrls(
            id,
            language,
            category,
            []
          );

          const updatedData = {
            ...data,
            streaming_urls: {
              wav: streamingUrls.wav,
              m3u8: null, // No M3U8 available
              segments: []
            },
            mock_data: true,
            mock_generated_at: new Date().toISOString()
          };

          if (!this.dryRun) {
            await fs.writeFile(filePath, JSON.stringify(updatedData, null, 2));
          }
          
          results.updated.push({
            id,
            language,
            category,
            streamingUrls: updatedData.streaming_urls
          });
        }

      } catch (error) {
        console.error(chalk.red(`❌ Failed to update content metadata for ${id} (${language}): ${error.message}`));
        results.errors.push({
          id,
          language,
          category,
          error: error.message
        });
      }
    }

    return results;
  }

  /**
   * Generate summary report
   * @param {Object} discovery - Discovery results
   * @param {Object} m3u8Results - M3U8 generation results
   * @param {Object} metadataResults - Metadata update results
   * @returns {Promise<Object>} - Summary report
   */
  async generateSummaryReport(discovery, m3u8Results, metadataResults) {
    const summary = {
      timestamp: new Date().toISOString(),
      dryRun: this.dryRun,
      discovery: discovery.stats,
      m3u8: {
        generated: m3u8Results.generated.length,
        skipped: m3u8Results.skipped.length,
        errors: m3u8Results.errors.length
      },
      metadata: {
        updated: metadataResults.updated.length,
        skipped: metadataResults.skipped.length,
        errors: metadataResults.errors.length
      },
      languages: [...new Set(discovery.contentFiles.map(f => f.language))],
      categories: [...new Set(discovery.contentFiles.map(f => f.category))],
      mockDomain: this.MOCK_DOMAIN
    };

    // Write summary to file
    if (!this.dryRun) {
      const summaryPath = path.join("scripts", "mock-data-summary.json");
      await fs.writeFile(summaryPath, JSON.stringify(summary, null, 2));
    }

    return summary;
  }

  /**
   * Log discovery results
   * @param {Object} discovery - Discovery results
   */
  logDiscoveryResults(discovery) {
    console.log(chalk.green(`   ✅ Content files: ${discovery.stats.totalContent}`));
    console.log(chalk.green(`   ✅ Audio files: ${discovery.stats.totalAudio}`));
    console.log(chalk.green(`   ✅ Matched pairs: ${discovery.stats.matched}`));
    
    if (discovery.stats.mismatched > 0) {
      console.log(chalk.yellow(`   ⚠️ Mismatched: ${discovery.stats.mismatched}`));
    }
  }

  /**
   * Log M3U8 generation results
   * @param {Object} m3u8Results - M3U8 generation results
   */
  logM3U8Results(m3u8Results) {
    console.log(chalk.green(`   ✅ M3U8 files generated: ${m3u8Results.generated.length}`));
    
    if (m3u8Results.skipped.length > 0) {
      console.log(chalk.yellow(`   ⏩ Skipped (existing): ${m3u8Results.skipped.length}`));
    }
    
    if (m3u8Results.errors.length > 0) {
      console.log(chalk.red(`   ❌ Errors: ${m3u8Results.errors.length}`));
    }
  }

  /**
   * Log metadata update results
   * @param {Object} metadataResults - Metadata update results
   */
  logMetadataResults(metadataResults) {
    console.log(chalk.green(`   ✅ Content files updated: ${metadataResults.updated.length}`));
    
    if (metadataResults.skipped.length > 0) {
      console.log(chalk.yellow(`   ⏩ Skipped (existing): ${metadataResults.skipped.length}`));
    }
    
    if (metadataResults.errors.length > 0) {
      console.log(chalk.red(`   ❌ Errors: ${metadataResults.errors.length}`));
    }
  }

  /**
   * Log summary report
   * @param {Object} summary - Summary report
   */
  logSummaryReport(summary) {
    console.log(chalk.blue('   📊 Summary Report:'));
    console.log(chalk.blue(`   Languages: ${summary.languages.join(', ')}`));
    console.log(chalk.blue(`   Categories: ${summary.categories.join(', ')}`));
    console.log(chalk.blue(`   Mock Domain: ${summary.mockDomain}`));
    console.log(chalk.blue(`   Total Content: ${summary.discovery.totalContent}`));
    console.log(chalk.blue(`   Total Audio: ${summary.discovery.totalAudio}`));
    console.log(chalk.blue(`   M3U8 Generated: ${summary.m3u8.generated}`));
    console.log(chalk.blue(`   Metadata Updated: ${summary.metadata.updated}`));
  }

  /**
   * Clean up all mock data
   */
  async cleanupMockData() {
    console.log(chalk.blue('🧹 Cleaning up mock data...'));
    
    try {
      // Remove M3U8 directory
      const m3u8Dir = path.join(MockDataGenerator.AUDIO_DIR, "m3u8");
      await fs.rm(m3u8Dir, { recursive: true, force: true });
      console.log(chalk.green('   ✅ M3U8 files removed'));

      // Remove streaming URLs from content files
      const contentFiles = await this.discoverContentFiles();
      let updatedCount = 0;

      for (const contentFile of contentFiles) {
        if (contentFile.hasStreamingUrls) {
          const { streaming_urls, mock_data, mock_generated_at, ...cleanData } = contentFile.data;
          
          if (!this.dryRun) {
            await fs.writeFile(contentFile.filePath, JSON.stringify(cleanData, null, 2));
          }
          updatedCount++;
        }
      }

      console.log(chalk.green(`   ✅ Streaming URLs removed from ${updatedCount} content files`));
      console.log(chalk.green('🧹 Mock data cleanup completed'));

    } catch (error) {
      console.error(chalk.red(`❌ Cleanup failed: ${error.message}`));
    }
  }
}

// CLI interface
async function main() {
  const args = process.argv.slice(2);
  const options = {
    dryRun: args.includes('--dry-run'),
    verbose: args.includes('--verbose'),
    forceRegenerate: args.includes('--force'),
    skipExisting: !args.includes('--no-skip')
  };

  const generator = new MockDataGenerator(options);

  if (args.includes('--cleanup')) {
    await generator.cleanupMockData();
  } else {
    await generator.generateMockData();
  }
}

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
  main().catch(console.error);
}

export { MockDataGenerator };