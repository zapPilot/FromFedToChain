import fs from "fs/promises";
import path from "path";
import chalk from "chalk";
import ffmpeg from "fluent-ffmpeg";
import { spawn } from "child_process";
import { PATHS } from "../../config/languages.js";

export class M3U8AudioService {
  static M3U8_DIR = path.join(PATHS.AUDIO_ROOT, "m3u8");
  static DEFAULT_SEGMENT_DURATION = 10; // 10 seconds per segment
  static DEFAULT_SEGMENT_FORMAT = "ts"; // TypeScript format for HLS
  static FFMPEG_PATHS = [
    "/usr/local/bin/ffmpeg",
    "/opt/homebrew/bin/ffmpeg",
    "/usr/bin/ffmpeg",
    "ffmpeg" // Default PATH lookup
  ];

  /**
   * Check if ffmpeg is available and set the path
   * @returns {Promise<string|null>} - FFmpeg path or null if not found
   */
  static async detectFFmpegPath() {
    for (const ffmpegPath of this.FFMPEG_PATHS) {
      try {
        const result = await this.executeCommand(ffmpegPath, ["-version"]);
        if (result.success) {
          console.log(chalk.green(`✅ FFmpeg found at: ${ffmpegPath}`));
          return ffmpegPath;
        }
      } catch (error) {
        // Continue to next path
      }
    }
    
    console.error(chalk.red("❌ FFmpeg not found in any common locations"));
    console.error(chalk.yellow("💡 Please install FFmpeg:"));
    console.error(chalk.yellow("   macOS: brew install ffmpeg"));
    console.error(chalk.yellow("   Ubuntu: sudo apt install ffmpeg"));
    console.error(chalk.yellow("   Windows: choco install ffmpeg"));
    return null;
  }

  /**
   * Execute a command and return result
   * @param {string} command - Command to execute
   * @param {string[]} args - Command arguments
   * @returns {Promise<Object>} - Command result
   */
  static async executeCommand(command, args) {
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
        resolve({ 
          success: code === 0, 
          output: stdout, 
          error: stderr,
          code 
        });
      });

      process.on("error", (error) => {
        resolve({ 
          success: false, 
          error: error.message,
          code: -1
        });
      });
    });
  }

  /**
   * Convert WAV file to M3U8 format with HLS segmentation
   * @param {string} wavPath - Path to the WAV file
   * @param {string} id - Content ID
   * @param {string} language - Language code
   * @param {string} category - Content category
   * @param {Object} options - Conversion options
   * @returns {Promise<Object>} - M3U8 conversion result
   */
  static async convertToM3U8(wavPath, id, language, category, options = {}) {
    const segmentDuration = options.segmentDuration || this.DEFAULT_SEGMENT_DURATION;
    const segmentFormat = options.segmentFormat || this.DEFAULT_SEGMENT_FORMAT;

    console.log(chalk.blue(`🎬 Converting to M3U8: ${id} (${language})`));

    // Check if ffmpeg is available
    const ffmpegPath = await this.detectFFmpegPath();
    if (!ffmpegPath) {
      throw new Error("FFmpeg not found. Please install FFmpeg to enable M3U8 conversion.");
    }

    // Set ffmpeg path for fluent-ffmpeg
    ffmpeg.setFfmpegPath(ffmpegPath);

    // Create M3U8 directory structure: m3u8/<language>/<category>/<id>/
    const m3u8Dir = path.join(this.M3U8_DIR, language, category, id);
    await fs.mkdir(m3u8Dir, { recursive: true });

    // Define output paths
    const playlistPath = path.join(m3u8Dir, "playlist.m3u8");
    const segmentPattern = path.join(m3u8Dir, `segment%03d.${segmentFormat}`);
    const segmentListPath = path.join(m3u8Dir, "segment-list.txt");

    try {
      // Convert WAV to M3U8 using ffmpeg
      await this.runFFmpegConversion(wavPath, playlistPath, segmentPattern, segmentDuration);

      // Generate segment list for easier management
      const segments = await this.generateSegmentList(m3u8Dir, segmentFormat);
      await fs.writeFile(segmentListPath, segments.join('\n'));

      // Generate metadata
      const metadata = await this.generateM3U8Metadata(wavPath, playlistPath, segments, {
        id,
        language,
        category,
        segmentDuration,
        segmentFormat
      });

      console.log(chalk.green(`✅ M3U8 conversion completed: ${playlistPath}`));
      console.log(chalk.gray(`   Segments: ${segments.length}`));
      console.log(chalk.gray(`   Duration: ${segmentDuration}s per segment`));

      return {
        success: true,
        playlistPath,
        segmentDir: m3u8Dir,
        segments,
        metadata
      };

    } catch (error) {
      console.error(chalk.red(`❌ M3U8 conversion failed: ${error.message}`));
      throw new Error(`M3U8 conversion failed for ${id} (${language}): ${error.message}`);
    }
  }

  /**
   * Run FFmpeg conversion to create M3U8 playlist and segments
   * @param {string} inputPath - Input WAV file path
   * @param {string} playlistPath - Output M3U8 playlist path
   * @param {string} segmentPattern - Segment file pattern
   * @param {number} segmentDuration - Duration of each segment in seconds
   * @returns {Promise<void>}
   */
  static async runFFmpegConversion(inputPath, playlistPath, segmentPattern, segmentDuration) {
    return new Promise((resolve, reject) => {
      ffmpeg(inputPath)
        .audioCodec('aac')
        .audioBitrate(128) // 128kbps for good quality streaming
        .audioFrequency(44100) // Standard frequency for audio streaming
        .format('hls')
        .outputOptions([
          `-hls_time ${segmentDuration}`,
          `-hls_list_size 0`, // Keep all segments in playlist
          `-hls_segment_filename ${segmentPattern}`,
          `-hls_playlist_type vod`, // Video On Demand type
          `-hls_flags independent_segments` // Make segments independent
        ])
        .output(playlistPath)
        .on('start', (commandLine) => {
          console.log(chalk.gray(`   FFmpeg command: ${commandLine}`));
        })
        .on('progress', (progress) => {
          if (progress.percent) {
            console.log(chalk.gray(`   Progress: ${Math.round(progress.percent)}%`));
          }
        })
        .on('end', () => {
          console.log(chalk.green(`   FFmpeg conversion completed`));
          resolve();
        })
        .on('error', (error) => {
          console.error(chalk.red(`   FFmpeg error: ${error.message}`));
          reject(error);
        })
        .run();
    });
  }

  /**
   * Generate list of segment files
   * @param {string} segmentDir - Directory containing segments
   * @param {string} segmentFormat - Format of segment files
   * @returns {Promise<string[]>} - List of segment filenames
   */
  static async generateSegmentList(segmentDir, segmentFormat) {
    const files = await fs.readdir(segmentDir);
    const segments = files
      .filter(file => file.endsWith(`.${segmentFormat}`))
      .sort();
    
    return segments;
  }

  /**
   * Generate metadata for M3U8 conversion
   * @param {string} originalPath - Original WAV file path
   * @param {string} playlistPath - M3U8 playlist path
   * @param {string[]} segments - List of segment files
   * @param {Object} conversionInfo - Conversion information
   * @returns {Promise<Object>} - Metadata object
   */
  static async generateM3U8Metadata(originalPath, playlistPath, segments, conversionInfo) {
    const originalStats = await fs.stat(originalPath);
    const playlistStats = await fs.stat(playlistPath);
    
    // Calculate total segment file size
    const segmentDir = path.dirname(playlistPath);
    let totalSegmentSize = 0;
    
    for (const segment of segments) {
      const segmentPath = path.join(segmentDir, segment);
      const segmentStats = await fs.stat(segmentPath);
      totalSegmentSize += segmentStats.size;
    }

    return {
      original: {
        path: originalPath,
        size: originalStats.size,
        created: originalStats.birthtime.toISOString()
      },
      m3u8: {
        playlistPath,
        segmentDir,
        segments: segments.length,
        totalSegmentSize,
        playlistSize: playlistStats.size,
        created: playlistStats.birthtime.toISOString()
      },
      conversion: {
        ...conversionInfo,
        convertedAt: new Date().toISOString()
      }
    };
  }

  /**
   * Get M3U8 files for a specific content
   * @param {string} id - Content ID
   * @param {string} language - Language code
   * @param {string} category - Content category
   * @returns {Promise<Object|null>} - M3U8 file information or null if not found
   */
  static async getM3U8Files(id, language, category) {
    const m3u8Dir = path.join(this.M3U8_DIR, language, category, id);
    const playlistPath = path.join(m3u8Dir, "playlist.m3u8");

    try {
      const stats = await fs.stat(playlistPath);
      const segments = await this.generateSegmentList(m3u8Dir, this.DEFAULT_SEGMENT_FORMAT);
      
      return {
        playlistPath,
        segmentDir: m3u8Dir,
        segments,
        created: stats.birthtime.toISOString(),
        size: stats.size
      };
    } catch (error) {
      return null;
    }
  }

  /**
   * List all M3U8 files with organized structure
   * @returns {Promise<Object[]>} - List of M3U8 files
   */
  static async listM3U8Files() {
    try {
      const m3u8Files = [];
      
      // Check if M3U8_DIR exists
      try {
        await fs.access(this.M3U8_DIR);
      } catch (error) {
        console.log(chalk.yellow(`⚠️ M3U8 directory does not exist: ${this.M3U8_DIR}`));
        return [];
      }
      
      const languages = await fs.readdir(this.M3U8_DIR);

      for (const language of languages) {
        try {
          const languageDir = path.join(this.M3U8_DIR, language);
          const languageStat = await fs.stat(languageDir);
          
          if (!languageStat.isDirectory()) continue;

          const categories = await fs.readdir(languageDir);
          
          for (const category of categories) {
            try {
              const categoryDir = path.join(languageDir, category);
              const categoryStat = await fs.stat(categoryDir);
              
              if (!categoryStat.isDirectory()) continue;

              const contentIds = await fs.readdir(categoryDir);
              
              for (const id of contentIds) {
                try {
                  const idDir = path.join(categoryDir, id);
                  const idStat = await fs.stat(idDir);
                  
                  if (!idStat.isDirectory()) continue;

                  const m3u8Info = await this.getM3U8Files(id, language, category);
                  if (m3u8Info) {
                    m3u8Files.push({
                      id,
                      language,
                      category,
                      ...m3u8Info
                    });
                  }
                } catch (error) {
                  // Skip individual content directories that have issues
                  console.log(chalk.yellow(`⚠️ Skipping ${language}/${category}/${id}: ${error.message}`));
                }
              }
            } catch (error) {
              // Skip individual category directories that have issues  
              console.log(chalk.yellow(`⚠️ Skipping ${language}/${category}: ${error.message}`));
            }
          }
        } catch (error) {
          // Skip individual language directories that have issues
          console.log(chalk.yellow(`⚠️ Skipping ${language}: ${error.message}`));
        }
      }

      return m3u8Files.sort((a, b) => new Date(b.created) - new Date(a.created));
    } catch (error) {
      console.error(chalk.red(`Error listing M3U8 files: ${error.message}`));
      return [];
    }
  }

  /**
   * Clean up M3U8 files for a specific content
   * @param {string} id - Content ID
   * @param {string} language - Language code
   * @param {string} category - Content category
   * @returns {Promise<boolean>} - Success status
   */
  static async cleanupM3U8Files(id, language, category) {
    const m3u8Dir = path.join(this.M3U8_DIR, language, category, id);
    
    try {
      await fs.rm(m3u8Dir, { recursive: true, force: true });
      console.log(chalk.green(`🗑️ Cleaned up M3U8 files: ${id} (${language})`));
      return true;
    } catch (error) {
      console.error(chalk.red(`Failed to cleanup M3U8 files: ${error.message}`));
      return false;
    }
  }
}