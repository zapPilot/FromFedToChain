import { chromium } from 'playwright';
import path from 'path';
import chalk from 'chalk';

export class SpotifyUploader {
  constructor() {
    this.browser = null;
    this.page = null;
  }

  async init() {
    console.log(chalk.blue('🎵 Initializing Spotify uploader...'));
    
    this.browser = await chromium.launch({ 
      headless: false, // Keep visible for manual auth if needed
      slowMo: 1000     // Slow down for reliability
    });
    
    this.page = await this.browser.newPage();
    
    // Set longer timeout for uploads
    this.page.setDefaultTimeout(300000); // 5 minutes
  }

  async login(email, password) {
    console.log(chalk.blue('🔐 Logging into Spotify for Podcasters...'));
    
    // Go to Spotify for Podcasters
    await this.page.goto('https://podcasters.spotify.com/');
    
    // Wait for login button and click
    await this.page.click('text="Log in"');
    
    // Fill credentials
    await this.page.fill('input[id="login-username"]', email);
    await this.page.fill('input[id="login-password"]', password);
    await this.page.click('button[id="login-button"]');
    
    // Wait for dashboard to load
    await this.page.waitForSelector('text="Dashboard"', { timeout: 30000 });
    console.log(chalk.green('✅ Logged into Spotify'));
  }

  async uploadEpisode(audioFilePath, title, description, category = 'Technology') {
    console.log(chalk.blue(`📤 Uploading episode: ${title}`));
    
    try {
      // Navigate to upload page
      await this.page.click('text="New episode"');
      
      // Upload audio file
      const fileInput = await this.page.locator('input[type="file"]');
      await fileInput.setInputFiles(audioFilePath);
      
      // Wait for upload to complete (look for progress indicator)
      await this.page.waitForSelector('text="Upload complete"', { timeout: 600000 }); // 10 minutes
      
      // Fill episode details
      await this.page.fill('input[name="title"]', title);
      await this.page.fill('textarea[name="description"]', description);
      
      // Select category
      await this.page.selectOption('select[name="category"]', category);
      
      // Set as explicit content false (assuming crypto content is not explicit)
      await this.page.uncheck('input[name="explicit"]');
      
      // Publish episode
      await this.page.click('button:has-text("Publish episode")');
      
      // Wait for success confirmation
      await this.page.waitForSelector('text="Episode published"', { timeout: 60000 });
      
      // Get episode URL
      const episodeUrl = await this.getEpisodeUrl();
      
      console.log(chalk.green(`✅ Episode uploaded successfully`));
      console.log(chalk.cyan(`📎 Episode URL: ${episodeUrl}`));
      
      return episodeUrl;
      
    } catch (error) {
      console.error(chalk.red(`❌ Upload failed: ${error.message}`));
      throw error;
    }
  }

  async getEpisodeUrl() {
    // Try to get the episode URL from the success page or episodes list
    try {
      // Look for share link or episode URL
      const urlElement = await this.page.locator('a[href*="spotify.com/episode"]').first();
      if (await urlElement.count() > 0) {
        return await urlElement.getAttribute('href');
      }
      
      // If not found, go to episodes list and get the first one
      await this.page.click('text="Episodes"');
      await this.page.waitForSelector('a[href*="spotify.com/episode"]');
      const latestEpisode = await this.page.locator('a[href*="spotify.com/episode"]').first();
      return await latestEpisode.getAttribute('href');
    } catch (error) {
      console.warn(chalk.yellow('⚠️ Could not get episode URL automatically'));
      return null;
    }
  }

  async close() {
    if (this.browser) {
      await this.browser.close();
    }
  }

  // Upload multiple episodes for different languages
  static async uploadMultipleEpisodes(contentData, audioFiles) {
    const uploader = new SpotifyUploader();
    const results = {};
    
    try {
      await uploader.init();
      
      // You'll need to implement login with actual credentials
      console.log(chalk.yellow('⚠️ Please log in manually in the browser window'));
      await uploader.page.waitForSelector('text="Dashboard"', { timeout: 120000 });
      
      for (const [language, audioFile] of Object.entries(audioFiles)) {
        if (!audioFile || !contentData.translations[language]) continue;
        
        const { title } = contentData.translations[language];
        const description = `${contentData.source.content.substring(0, 500)}...`;
        
        try {
          const episodeUrl = await uploader.uploadEpisode(
            audioFile,
            `${title} (${language})`,
            description,
            'Technology'
          );
          
          results[language] = {
            success: true,
            url: episodeUrl,
            audioFile
          };
        } catch (error) {
          results[language] = {
            success: false,
            error: error.message,
            audioFile
          };
        }
      }
      
    } finally {
      await uploader.close();
    }
    
    return results;
  }
}