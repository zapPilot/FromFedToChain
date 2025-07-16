import fs from "fs/promises";
import path from "path";
import chalk from "chalk";

export class MockM3U8Generator {
  static MOCK_DOMAIN = "https://mock-r2.fromfedtochain.com";
  static SEGMENT_DURATION = 10; // 10 seconds per segment
  static SEGMENT_FORMAT = "ts";
  static MOCK_SEGMENT_SIZE = 98304; // ~96KB per segment (realistic size)

  /**
   * Generate mock M3U8 files and segments for an audio file
   * @param {string} audioPath - Path to the audio file
   * @param {string} id - Content ID
   * @param {string} language - Language code
   * @param {string} category - Content category
   * @param {Object} options - Generation options
   * @returns {Promise<Object>} - Generated M3U8 data
   */
  static async generateMockM3U8(audioPath, id, language, category, options = {}) {
    const estimatedDuration = options.estimatedDuration || this.estimateAudioDuration(audioPath);
    const segmentDuration = options.segmentDuration || this.SEGMENT_DURATION;
    const segmentCount = Math.ceil(estimatedDuration / segmentDuration);

    console.log(chalk.blue(`🎬 Generating mock M3U8: ${id} (${language}) - ${estimatedDuration}s`));

    // Create M3U8 directory structure
    const m3u8Dir = path.join("audio", "m3u8", language, category, id);
    await fs.mkdir(m3u8Dir, { recursive: true });

    // Generate segment files
    const segments = [];
    for (let i = 0; i < segmentCount; i++) {
      const segmentName = `segment${i.toString().padStart(3, '0')}.${this.SEGMENT_FORMAT}`;
      const segmentPath = path.join(m3u8Dir, segmentName);
      
      // Create mock segment file (small placeholder)
      await this.createMockSegmentFile(segmentPath, segmentDuration);
      segments.push({
        name: segmentName,
        duration: Math.min(segmentDuration, estimatedDuration - (i * segmentDuration)),
        size: this.MOCK_SEGMENT_SIZE
      });
    }

    // Generate M3U8 playlist
    const playlistPath = path.join(m3u8Dir, "playlist.m3u8");
    const playlistContent = this.generatePlaylistContent(segments, estimatedDuration);
    await fs.writeFile(playlistPath, playlistContent);

    // Generate segment list file
    const segmentListPath = path.join(m3u8Dir, "segment-list.txt");
    const segmentListContent = segments.map(s => s.name).join('\n');
    await fs.writeFile(segmentListPath, segmentListContent);

    // Generate metadata
    const metadata = {
      id,
      language,
      category,
      totalDuration: estimatedDuration,
      segmentCount: segments.length,
      segmentDuration,
      playlistPath,
      segmentDir: m3u8Dir,
      segments: segments.map(s => s.name),
      generatedAt: new Date().toISOString(),
      mockData: true
    };

    // Write metadata file
    const metadataPath = path.join(m3u8Dir, "metadata.json");
    await fs.writeFile(metadataPath, JSON.stringify(metadata, null, 2));

    console.log(chalk.green(`✅ Mock M3U8 generated: ${segments.length} segments, ${estimatedDuration}s`));

    return {
      success: true,
      playlistPath,
      segmentDir: m3u8Dir,
      segments: segments.map(s => s.name),
      metadata,
      urls: this.generateStreamingUrls(id, language, category, segments.map(s => s.name))
    };
  }

  /**
   * Create a mock segment file (small placeholder)
   * @param {string} segmentPath - Path for the segment file
   * @param {number} duration - Duration in seconds
   */
  static async createMockSegmentFile(segmentPath, duration) {
    // Create a small mock file that represents a TS segment
    // This is just a placeholder - in real usage, this would be actual video/audio data
    const mockData = Buffer.alloc(this.MOCK_SEGMENT_SIZE);
    
    // Write some mock header data that might be found in a TS file
    const header = Buffer.from([
      0x47, 0x40, 0x00, 0x10, // TS packet header
      0x00, 0x00, 0x01, 0xE0, // PES packet header
      0x00, 0x00, 0x80, 0x00, // More PES data
      0x00, 0x00, 0x00, 0x00  // Padding
    ]);
    
    header.copy(mockData, 0);
    
    // Fill the rest with pseudo-random data to simulate compressed audio
    for (let i = header.length; i < this.MOCK_SEGMENT_SIZE; i++) {
      mockData[i] = Math.floor(Math.random() * 256);
    }
    
    await fs.writeFile(segmentPath, mockData);
  }

  /**
   * Generate M3U8 playlist content
   * @param {Array} segments - Array of segment objects
   * @param {number} totalDuration - Total duration in seconds
   * @returns {string} - M3U8 playlist content
   */
  static generatePlaylistContent(segments, totalDuration) {
    const lines = [
      '#EXTM3U',
      '#EXT-X-VERSION:3',
      '#EXT-X-TARGETDURATION:' + this.SEGMENT_DURATION,
      '#EXT-X-MEDIA-SEQUENCE:0',
      '#EXT-X-PLAYLIST-TYPE:VOD',
      ''
    ];

    // Add segment entries
    segments.forEach((segment, index) => {
      lines.push(`#EXTINF:${segment.duration.toFixed(6)},`);
      lines.push(segment.name);
    });

    // Add end marker
    lines.push('#EXT-X-ENDLIST');
    lines.push('');

    return lines.join('\n');
  }

  /**
   * Estimate audio duration based on file size (rough approximation)
   * @param {string} audioPath - Path to the audio file
   * @returns {number} - Estimated duration in seconds
   */
  static estimateAudioDuration(audioPath) {
    try {
      // This is a rough estimation based on typical WAV file sizes
      // For 16-bit, 16kHz WAV: ~32KB per second
      // For mock purposes, we'll use a range of 120-300 seconds (2-5 minutes)
      const variations = [120, 150, 180, 210, 240, 270, 300];
      const hash = this.simpleHash(audioPath);
      return variations[hash % variations.length];
    } catch (error) {
      return 180; // Default to 3 minutes
    }
  }

  /**
   * Generate streaming URLs for mock data
   * @param {string} id - Content ID
   * @param {string} language - Language code
   * @param {string} category - Content category
   * @param {Array} segments - Array of segment filenames
   * @returns {Object} - Streaming URLs object
   */
  static generateStreamingUrls(id, language, category, segments) {
    const basePath = `${this.MOCK_DOMAIN}/audio/${language}/${category}/${id}`;
    
    return {
      wav: `${basePath}/audio.wav`,
      m3u8: `${basePath}/playlist.m3u8`,
      segments: segments.map(segment => `${basePath}/${segment}`),
      baseUrl: basePath
    };
  }

  /**
   * Check if M3U8 files already exist for content
   * @param {string} id - Content ID
   * @param {string} language - Language code
   * @param {string} category - Content category
   * @returns {Promise<boolean>} - True if files exist
   */
  static async m3u8Exists(id, language, category) {
    const m3u8Dir = path.join("audio", "m3u8", language, category, id);
    const playlistPath = path.join(m3u8Dir, "playlist.m3u8");
    
    try {
      await fs.access(playlistPath);
      return true;
    } catch {
      return false;
    }
  }

  /**
   * List all existing M3U8 files
   * @returns {Promise<Array>} - Array of M3U8 file information
   */
  static async listExistingM3U8Files() {
    const m3u8Files = [];
    const m3u8Root = path.join("audio", "m3u8");
    
    try {
      const languages = await fs.readdir(m3u8Root);
      
      for (const language of languages) {
        const languagePath = path.join(m3u8Root, language);
        const languageStat = await fs.stat(languagePath);
        
        if (!languageStat.isDirectory()) continue;
        
        const categories = await fs.readdir(languagePath);
        
        for (const category of categories) {
          const categoryPath = path.join(languagePath, category);
          const categoryStat = await fs.stat(categoryPath);
          
          if (!categoryStat.isDirectory()) continue;
          
          const ids = await fs.readdir(categoryPath);
          
          for (const id of ids) {
            const idPath = path.join(categoryPath, id);
            const idStat = await fs.stat(idPath);
            
            if (!idStat.isDirectory()) continue;
            
            const playlistPath = path.join(idPath, "playlist.m3u8");
            const metadataPath = path.join(idPath, "metadata.json");
            
            try {
              await fs.access(playlistPath);
              
              let metadata = {};
              try {
                const metadataContent = await fs.readFile(metadataPath, 'utf-8');
                metadata = JSON.parse(metadataContent);
              } catch {
                // Metadata file doesn't exist or is invalid
              }
              
              m3u8Files.push({
                id,
                language,
                category,
                playlistPath,
                segmentDir: idPath,
                metadata,
                created: idStat.birthtime.toISOString()
              });
            } catch {
              // Playlist file doesn't exist
            }
          }
        }
      }
    } catch (error) {
      // M3U8 directory doesn't exist yet
    }
    
    return m3u8Files.sort((a, b) => new Date(b.created) - new Date(a.created));
  }

  /**
   * Clean up M3U8 files for specific content
   * @param {string} id - Content ID
   * @param {string} language - Language code
   * @param {string} category - Content category
   * @returns {Promise<boolean>} - Success status
   */
  static async cleanupM3U8Files(id, language, category) {
    const m3u8Dir = path.join("audio", "m3u8", language, category, id);
    
    try {
      await fs.rm(m3u8Dir, { recursive: true, force: true });
      console.log(chalk.green(`🗑️ Cleaned up mock M3U8 files: ${id} (${language})`));
      return true;
    } catch (error) {
      console.error(chalk.red(`Failed to cleanup M3U8 files: ${error.message}`));
      return false;
    }
  }

  /**
   * Simple hash function for consistent pseudo-random values
   * @param {string} str - String to hash
   * @returns {number} - Hash value
   */
  static simpleHash(str) {
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
      const char = str.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash; // Convert to 32-bit integer
    }
    return Math.abs(hash);
  }

  /**
   * Validate M3U8 file structure
   * @param {string} playlistPath - Path to the playlist file
   * @returns {Promise<Object>} - Validation result
   */
  static async validateM3U8Structure(playlistPath) {
    try {
      const content = await fs.readFile(playlistPath, 'utf-8');
      const lines = content.split('\n');
      
      const result = {
        valid: true,
        errors: [],
        segments: 0,
        totalDuration: 0
      };
      
      if (!lines[0].startsWith('#EXTM3U')) {
        result.valid = false;
        result.errors.push('Missing #EXTM3U header');
      }
      
      let currentDuration = 0;
      for (let i = 1; i < lines.length; i++) {
        const line = lines[i].trim();
        
        if (line.startsWith('#EXTINF:')) {
          const match = line.match(/#EXTINF:([0-9.]+),/);
          if (match) {
            currentDuration = parseFloat(match[1]);
            result.totalDuration += currentDuration;
          }
        } else if (line.endsWith('.ts')) {
          result.segments++;
        }
      }
      
      return result;
    } catch (error) {
      return {
        valid: false,
        errors: [`Failed to read playlist: ${error.message}`],
        segments: 0,
        totalDuration: 0
      };
    }
  }
}