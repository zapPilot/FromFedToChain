#!/usr/bin/env node

import fs from "fs/promises";
import path from "path";
import chalk from "chalk";
import { MockM3U8Generator } from "./mock-m3u8-generator.js";

class MockDataValidator {
  static CONTENT_DIR = "./content";
  static AUDIO_DIR = "./audio";
  static M3U8_DIR = "./audio/m3u8";

  constructor(options = {}) {
    this.verbose = options.verbose || false;
    this.checkFiles = options.checkFiles || false;
  }

  /**
   * Validate all mock data
   */
  async validateMockData() {
    console.log(chalk.blue('🔍 Validating Mock Data Integrity'));
    console.log('====================================');

    const validationResults = {
      content: { valid: 0, invalid: 0, errors: [] },
      m3u8: { valid: 0, invalid: 0, errors: [] },
      streaming: { valid: 0, invalid: 0, errors: [] },
      files: { valid: 0, missing: 0, errors: [] }
    };

    try {
      // 1. Validate content files
      console.log(chalk.blue('\n1. Validating content files...'));
      await this.validateContentFiles(validationResults.content);

      // 2. Validate M3U8 files
      console.log(chalk.blue('\n2. Validating M3U8 files...'));
      await this.validateM3U8Files(validationResults.m3u8);

      // 3. Validate streaming URLs
      console.log(chalk.blue('\n3. Validating streaming URLs...'));
      await this.validateStreamingUrls(validationResults.streaming);

      // 4. Validate file existence (optional)
      if (this.checkFiles) {
        console.log(chalk.blue('\n4. Validating file existence...'));
        await this.validateFileExistence(validationResults.files);
      }

      // 5. Generate validation report
      console.log(chalk.blue('\n5. Validation Report'));
      this.generateValidationReport(validationResults);

      const allValid = Object.values(validationResults).every(result => result.invalid === 0);
      
      if (allValid) {
        console.log(chalk.green('\n✅ All mock data validation passed!'));
        console.log(chalk.blue('🚀 Your Flutter app is ready to use this mock data.'));
      } else {
        console.log(chalk.red('\n❌ Some validation issues found.'));
        console.log(chalk.yellow('Please review the errors above and regenerate mock data if needed.'));
      }

      return validationResults;

    } catch (error) {
      console.error(chalk.red(`❌ Validation failed: ${error.message}`));
      throw error;
    }
  }

  /**
   * Validate content files
   * @param {Object} results - Results object to update
   */
  async validateContentFiles(results) {
    const contentFiles = await this.discoverContentFiles();
    
    for (const contentFile of contentFiles) {
      const { id, language, category, filePath, data } = contentFile;
      
      try {
        // Check if content has streaming URLs
        if (!data.streaming_urls) {
          results.errors.push({
            type: 'content',
            id,
            language,
            category,
            error: 'Missing streaming_urls field'
          });
          results.invalid++;
          continue;
        }

        // Validate streaming URLs structure
        const streamingUrls = data.streaming_urls;
        const requiredFields = ['wav', 'baseUrl'];
        
        for (const field of requiredFields) {
          if (!streamingUrls[field]) {
            results.errors.push({
              type: 'content',
              id,
              language,
              category,
              error: `Missing streaming_urls.${field} field`
            });
            results.invalid++;
            continue;
          }
        }

        // Validate URL format
        if (streamingUrls.wav && !streamingUrls.wav.startsWith('https://')) {
          results.errors.push({
            type: 'content',
            id,
            language,
            category,
            error: 'Invalid WAV URL format'
          });
          results.invalid++;
          continue;
        }

        // Check mock data markers
        if (!data.mock_data || !data.mock_generated_at) {
          results.errors.push({
            type: 'content',
            id,
            language,
            category,
            error: 'Missing mock data markers'
          });
          results.invalid++;
          continue;
        }

        results.valid++;
        if (this.verbose) {
          console.log(chalk.green(`   ✅ Content valid: ${id} (${language})`));
        }

      } catch (error) {
        results.errors.push({
          type: 'content',
          id,
          language,
          category,
          error: error.message
        });
        results.invalid++;
      }
    }

    console.log(chalk.green(`   ✅ Valid content files: ${results.valid}`));
    if (results.invalid > 0) {
      console.log(chalk.red(`   ❌ Invalid content files: ${results.invalid}`));
    }
  }

  /**
   * Validate M3U8 files
   * @param {Object} results - Results object to update
   */
  async validateM3U8Files(results) {
    const m3u8Files = await MockM3U8Generator.listExistingM3U8Files();
    
    for (const m3u8File of m3u8Files) {
      const { id, language, category, playlistPath } = m3u8File;
      
      try {
        // Validate M3U8 structure
        const validation = await MockM3U8Generator.validateM3U8Structure(playlistPath);
        
        if (!validation.valid) {
          results.errors.push({
            type: 'm3u8',
            id,
            language,
            category,
            error: validation.errors.join(', ')
          });
          results.invalid++;
          continue;
        }

        // Check if segments exist
        const segmentDir = path.dirname(playlistPath);
        const segmentFiles = await fs.readdir(segmentDir);
        const tsFiles = segmentFiles.filter(f => f.endsWith('.ts'));
        
        if (tsFiles.length !== validation.segments) {
          results.errors.push({
            type: 'm3u8',
            id,
            language,
            category,
            error: `Segment count mismatch: expected ${validation.segments}, found ${tsFiles.length}`
          });
          results.invalid++;
          continue;
        }

        // Check metadata file
        const metadataPath = path.join(segmentDir, 'metadata.json');
        try {
          const metadataContent = await fs.readFile(metadataPath, 'utf-8');
          const metadata = JSON.parse(metadataContent);
          
          if (!metadata.mockData || !metadata.generatedAt) {
            results.errors.push({
              type: 'm3u8',
              id,
              language,
              category,
              error: 'Invalid metadata structure'
            });
            results.invalid++;
            continue;
          }
        } catch (metadataError) {
          results.errors.push({
            type: 'm3u8',
            id,
            language,
            category,
            error: 'Missing or invalid metadata.json'
          });
          results.invalid++;
          continue;
        }

        results.valid++;
        if (this.verbose) {
          console.log(chalk.green(`   ✅ M3U8 valid: ${id} (${language}) - ${validation.segments} segments`));
        }

      } catch (error) {
        results.errors.push({
          type: 'm3u8',
          id,
          language,
          category,
          error: error.message
        });
        results.invalid++;
      }
    }

    console.log(chalk.green(`   ✅ Valid M3U8 files: ${results.valid}`));
    if (results.invalid > 0) {
      console.log(chalk.red(`   ❌ Invalid M3U8 files: ${results.invalid}`));
    }
  }

  /**
   * Validate streaming URLs consistency
   * @param {Object} results - Results object to update
   */
  async validateStreamingUrls(results) {
    const contentFiles = await this.discoverContentFiles();
    
    for (const contentFile of contentFiles) {
      const { id, language, category, data } = contentFile;
      
      try {
        if (!data.streaming_urls) continue;
        
        const streamingUrls = data.streaming_urls;
        const expectedBasePath = `https://mock-r2.fromfedtochain.com/audio/${language}/${category}/${id}`;
        
        // Check WAV URL consistency
        if (streamingUrls.wav) {
          const expectedWavUrl = `${expectedBasePath}/audio.wav`;
          if (streamingUrls.wav !== expectedWavUrl) {
            results.errors.push({
              type: 'streaming',
              id,
              language,
              category,
              error: `WAV URL mismatch: expected ${expectedWavUrl}, got ${streamingUrls.wav}`
            });
            results.invalid++;
            continue;
          }
        }

        // Check M3U8 URL consistency
        if (streamingUrls.m3u8) {
          const expectedM3U8Url = `${expectedBasePath}/playlist.m3u8`;
          if (streamingUrls.m3u8 !== expectedM3U8Url) {
            results.errors.push({
              type: 'streaming',
              id,
              language,
              category,
              error: `M3U8 URL mismatch: expected ${expectedM3U8Url}, got ${streamingUrls.m3u8}`
            });
            results.invalid++;
            continue;
          }
        }

        // Check segment URLs consistency
        if (streamingUrls.segments && streamingUrls.segments.length > 0) {
          for (let i = 0; i < streamingUrls.segments.length; i++) {
            const segmentUrl = streamingUrls.segments[i];
            const expectedSegmentUrl = `${expectedBasePath}/segment${i.toString().padStart(3, '0')}.ts`;
            
            if (segmentUrl !== expectedSegmentUrl) {
              results.errors.push({
                type: 'streaming',
                id,
                language,
                category,
                error: `Segment URL mismatch at index ${i}: expected ${expectedSegmentUrl}, got ${segmentUrl}`
              });
              results.invalid++;
              continue;
            }
          }
        }

        // Check base URL consistency
        if (streamingUrls.baseUrl !== expectedBasePath) {
          results.errors.push({
            type: 'streaming',
            id,
            language,
            category,
            error: `Base URL mismatch: expected ${expectedBasePath}, got ${streamingUrls.baseUrl}`
          });
          results.invalid++;
          continue;
        }

        results.valid++;
        if (this.verbose) {
          console.log(chalk.green(`   ✅ Streaming URLs valid: ${id} (${language})`));
        }

      } catch (error) {
        results.errors.push({
          type: 'streaming',
          id,
          language,
          category,
          error: error.message
        });
        results.invalid++;
      }
    }

    console.log(chalk.green(`   ✅ Valid streaming URLs: ${results.valid}`));
    if (results.invalid > 0) {
      console.log(chalk.red(`   ❌ Invalid streaming URLs: ${results.invalid}`));
    }
  }

  /**
   * Validate file existence
   * @param {Object} results - Results object to update
   */
  async validateFileExistence(results) {
    const contentFiles = await this.discoverContentFiles();
    
    for (const contentFile of contentFiles) {
      const { id, language, category, data } = contentFile;
      
      try {
        // Check if audio file exists
        if (data.audio_file) {
          try {
            await fs.access(data.audio_file);
            results.valid++;
            if (this.verbose) {
              console.log(chalk.green(`   ✅ Audio file exists: ${data.audio_file}`));
            }
          } catch (error) {
            results.errors.push({
              type: 'files',
              id,
              language,
              category,
              error: `Audio file not found: ${data.audio_file}`
            });
            results.missing++;
          }
        }

        // Check if M3U8 files exist
        const m3u8Dir = path.join(MockDataValidator.M3U8_DIR, language, category, id);
        const playlistPath = path.join(m3u8Dir, 'playlist.m3u8');
        
        try {
          await fs.access(playlistPath);
          results.valid++;
          if (this.verbose) {
            console.log(chalk.green(`   ✅ M3U8 file exists: ${playlistPath}`));
          }
        } catch (error) {
          results.errors.push({
            type: 'files',
            id,
            language,
            category,
            error: `M3U8 file not found: ${playlistPath}`
          });
          results.missing++;
        }

      } catch (error) {
        results.errors.push({
          type: 'files',
          id,
          language,
          category,
          error: error.message
        });
        results.missing++;
      }
    }

    console.log(chalk.green(`   ✅ Files found: ${results.valid}`));
    if (results.missing > 0) {
      console.log(chalk.red(`   ❌ Files missing: ${results.missing}`));
    }
  }

  /**
   * Discover all content files
   * @returns {Promise<Array>} - Array of content file information
   */
  async discoverContentFiles() {
    const contentFiles = [];
    const languages = await fs.readdir(MockDataValidator.CONTENT_DIR);

    for (const language of languages) {
      const languagePath = path.join(MockDataValidator.CONTENT_DIR, language);
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
                data
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
   * Generate validation report
   * @param {Object} results - Validation results
   */
  generateValidationReport(results) {
    console.log(chalk.blue('   📊 Validation Summary:'));
    
    // Content files
    console.log(chalk.blue(`   Content Files: ${results.content.valid} valid, ${results.content.invalid} invalid`));
    
    // M3U8 files
    console.log(chalk.blue(`   M3U8 Files: ${results.m3u8.valid} valid, ${results.m3u8.invalid} invalid`));
    
    // Streaming URLs
    console.log(chalk.blue(`   Streaming URLs: ${results.streaming.valid} valid, ${results.streaming.invalid} invalid`));
    
    // File existence
    if (this.checkFiles) {
      console.log(chalk.blue(`   File Existence: ${results.files.valid} found, ${results.files.missing} missing`));
    }

    // Show detailed errors if verbose
    if (this.verbose && results.content.errors.length > 0) {
      console.log(chalk.red('\n   📝 Detailed Errors:'));
      results.content.errors.forEach(error => {
        console.log(chalk.red(`     - ${error.type}: ${error.id} (${error.language}): ${error.error}`));
      });
    }
  }

  /**
   * Quick validation check
   */
  async quickValidation() {
    console.log(chalk.blue('🔍 Quick Mock Data Validation'));
    console.log('===============================');

    try {
      // Count files
      const contentFiles = await this.discoverContentFiles();
      const m3u8Files = await MockM3U8Generator.listExistingM3U8Files();
      
      const mockContentFiles = contentFiles.filter(f => f.data.mock_data);
      const streamsUrls = contentFiles.filter(f => f.data.streaming_urls);
      
      console.log(chalk.green(`✅ Total content files: ${contentFiles.length}`));
      console.log(chalk.green(`✅ Mock content files: ${mockContentFiles.length}`));
      console.log(chalk.green(`✅ Files with streaming URLs: ${streamsUrls.length}`));
      console.log(chalk.green(`✅ M3U8 files: ${m3u8Files.length}`));
      
      // Check basic structure
      const languages = [...new Set(contentFiles.map(f => f.language))];
      const categories = [...new Set(contentFiles.map(f => f.category))];
      
      console.log(chalk.blue(`📊 Languages: ${languages.join(', ')}`));
      console.log(chalk.blue(`📊 Categories: ${categories.join(', ')}`));
      
      console.log(chalk.green('\n✅ Quick validation passed!'));
      
    } catch (error) {
      console.error(chalk.red(`❌ Quick validation failed: ${error.message}`));
    }
  }
}

// CLI interface
async function main() {
  const args = process.argv.slice(2);
  const options = {
    verbose: args.includes('--verbose'),
    checkFiles: args.includes('--check-files')
  };

  const validator = new MockDataValidator(options);

  if (args.includes('--quick')) {
    await validator.quickValidation();
  } else {
    await validator.validateMockData();
  }
}

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
  main().catch(console.error);
}

export { MockDataValidator };