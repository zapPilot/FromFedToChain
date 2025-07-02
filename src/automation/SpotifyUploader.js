import { chromium } from 'playwright';
import path from 'path';
import fs from 'fs';
import chalk from 'chalk';

export class SpotifyUploader {
  constructor() {
    this.browser = null;
    this.page = null;
    this.multilingualShowIdentifier = ['中文', '日本語', 'Eng'];
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

  async navigateToDashboard() {
    console.log(chalk.blue('🔐 Navigating to Spotify Creators dashboard...'));
    
    // Go to Spotify Creators dashboard
    await this.page.goto('https://creators.spotify.com/pod/dashboard/home');
    
    // Wait for dashboard to load (you'll need to login manually if not already logged in)
    try {
      await this.page.waitForSelector('[data-testid="dashboard-header"]', { timeout: 10000 });
      console.log(chalk.green('✅ Dashboard loaded successfully'));
    } catch (error) {
      console.log(chalk.yellow('⚠️ Please log in manually in the browser window'));
      console.log(chalk.cyan('Waiting for dashboard to load...'));
      await this.page.waitForSelector('[data-testid="dashboard-header"]', { timeout: 300000 }); // 5 minutes
      console.log(chalk.green('✅ Dashboard loaded after manual login'));
    }
  }

  async findMultilingualShow() {
    console.log(chalk.blue('🎯 Finding multilingual show...'));
    
    try {
      // Wait for dashboard to be ready
      await this.page.waitForSelector('[data-testid="dashboard-header"]', { timeout: 10000 });
      
      let showFound = false;
      let showNumber = 1;
      let maxAttempts = 10; // Limit search to first 10 shows
      
      while (!showFound && showNumber <= maxAttempts) {
        const showSelector = `#listrow-title-${showNumber}`;
        
        try {
          const showElement = await this.page.locator(showSelector).first();
          
          if (await showElement.count() > 0) {
            const showText = await showElement.textContent();
            console.log(chalk.cyan(`📋 Checking show ${showNumber}: ${showText}`));
            
            // Check if show title contains all multilingual identifiers
            const hasAllLanguages = this.multilingualShowIdentifier.every(lang => 
              showText.includes(lang)
            );
            
            if (hasAllLanguages) {
              console.log(chalk.green(`✅ Found multilingual show: ${showText}`));
              await showElement.click();
              showFound = true;
              return showText;
            }
          } else {
            // No more shows found
            break;
          }
        } catch (error) {
          // Show element not found, try next
          console.log(chalk.gray(`Show ${showNumber} not found, continuing...`));
        }
        
        showNumber++;
      }
      
      if (!showFound) {
        throw new Error(`Multilingual show containing "${this.multilingualShowIdentifier.join(', ')}" not found in first ${maxAttempts} shows`);
      }
      
    } catch (error) {
      console.error(chalk.red(`❌ Failed to find multilingual show: ${error.message}`));
      console.log(chalk.yellow('⚠️ Please manually navigate to the multilingual show'));
      throw error;
    }
  }

  async uploadEpisode(audioFilePath, title, description, language, category = 'Technology') {
    console.log(chalk.blue(`📤 Uploading episode: ${title} [${language}]`));
    
    try {
      // Create multilingual episode title with language indicator
      const languageIndicators = {
        'en-US': '[Eng]',
        'zh-TW': '【中文】',
        'ja-JP': '【日本語】'
      };
      
      const episodeTitle = `${title} ${languageIndicators[language] || '[' + language + ']'}`;
      
      // Click the new episode button using the specific selector you provided
      await this.page.click('[data-testid="new-episode-button"]', { timeout: 10000 });
      
      // Upload audio file
      const fileInput = await this.page.locator('input[type="file"]').first();
      await fileInput.setInputFiles(audioFilePath);
      
      // Wait for upload to complete
      console.log(chalk.cyan('⏳ Waiting for file upload to complete...'));
      await this.page.waitForSelector('text="Upload complete", text="Processing complete", [data-testid="upload-complete"]', 
        { timeout: 600000 }); // 10 minutes
      
      // Fill episode details with multilingual title
      await this.page.fill('input[name="title"], [data-testid="episode-title"]', episodeTitle);
      await this.page.fill('textarea[name="description"], [data-testid="episode-description"]', description);
      
      // Try to select category if available
      try {
        const categorySelector = await this.page.locator('select[name="category"], [data-testid="category-select"]').first();
        if (await categorySelector.count() > 0) {
          await categorySelector.selectOption(category);
        }
      } catch (error) {
        console.log(chalk.yellow('⚠️ Could not set category, continuing...'));
      }
      
      // Set as not explicit content
      try {
        const explicitCheckbox = await this.page.locator('input[name="explicit"], [data-testid="explicit-checkbox"]').first();
        if (await explicitCheckbox.count() > 0) {
          await explicitCheckbox.uncheck();
        }
      } catch (error) {
        console.log(chalk.yellow('⚠️ Could not set explicit flag, continuing...'));
      }
      
      // Publish episode
      await this.page.click('button:has-text("Publish episode"), button:has-text("Publish"), [data-testid="publish-button"]');
      
      // Wait for success confirmation
      await this.page.waitForSelector('text="Episode published", text="Published successfully", [data-testid="publish-success"]', 
        { timeout: 60000 });
      
      console.log(chalk.green(`✅ Episode uploaded successfully: ${episodeTitle}`));
      
      return true;
      
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

  // Find un-uploaded audio files and their corresponding content
  static findUnuploadedAudios(projectRoot = '/Users/chouyasushi/htdocs/FromFedToChain') {
    const audioDir = path.join(projectRoot, 'audio');
    const contentDir = path.join(projectRoot, 'content');
    const unuploaded = [];
    
    // Scan all languages
    const languages = ['en-US', 'ja-JP', 'zh-TW'];
    
    for (const language of languages) {
      const langAudioDir = path.join(audioDir, language);
      if (!fs.existsSync(langAudioDir)) continue;
      
      // Scan all categories in this language
      const categories = fs.readdirSync(langAudioDir, { withFileTypes: true })
        .filter(dirent => dirent.isDirectory())
        .map(dirent => dirent.name);
      
      for (const category of categories) {
        const categoryAudioDir = path.join(langAudioDir, category);
        const audioFiles = fs.readdirSync(categoryAudioDir)
          .filter(file => file.endsWith('.wav'));
        
        for (const audioFile of audioFiles) {
          const audioPath = path.join(categoryAudioDir, audioFile);
          const articleId = audioFile.replace('.wav', '');
          
          // Find corresponding content file
          const contentPath = path.join(contentDir, language, category, `${articleId}.json`);
          
          if (fs.existsSync(contentPath)) {
            try {
              const content = JSON.parse(fs.readFileSync(contentPath, 'utf8'));
              
              // Check if not already uploaded (no spotify_episode_url or similar field)
              if (!content.spotify_episode_url && !content.uploaded_to_spotify) {
                unuploaded.push({
                  language,
                  category,
                  articleId,
                  audioPath,
                  contentPath,
                  content,
                  title: content.title,
                  description: content.content ? content.content.substring(0, 500) + '...' : 'No description available'
                });
              }
            } catch (error) {
              console.warn(chalk.yellow(`⚠️ Could not read content file: ${contentPath}`));
            }
          }
        }
      }
    }
    
    return unuploaded;
  }

  // Upload all un-uploaded audio files
  static async uploadAllUnuploaded(projectRoot = '/Users/chouyasushi/htdocs/FromFedToChain') {
    const uploader = new SpotifyUploader();
    const unuploaded = SpotifyUploader.findUnuploadedAudios(projectRoot);
    
    if (unuploaded.length === 0) {
      console.log(chalk.green('✅ All audio files are already uploaded to Spotify'));
      return { success: true, uploaded: 0, failed: 0 };
    }
    
    console.log(chalk.cyan(`📋 Found ${unuploaded.length} un-uploaded audio files:`));
    unuploaded.forEach(item => {
      console.log(chalk.white(`  • ${item.title} [${item.language}]`));
    });
    
    const results = {
      success: true,
      uploaded: 0,
      failed: 0,
      details: []
    };
    
    try {
      await uploader.init();
      await uploader.navigateToDashboard();
      
      // Find and select the multilingual show once
      await uploader.findMultilingualShow();
      
      // Upload all episodes to the same multilingual show
      for (const item of unuploaded) {
        try {
          console.log(chalk.cyan(`\n📤 Uploading: ${item.title} [${item.language}]`));
          
          await uploader.uploadEpisode(
            item.audioPath,
            item.title,
            item.description,
            item.language,
            'Technology'
          );
          
          // Mark as uploaded in content file
          item.content.uploaded_to_spotify = true;
          item.content.spotify_upload_date = new Date().toISOString();
          fs.writeFileSync(item.contentPath, JSON.stringify(item.content, null, 2));
          
          results.uploaded++;
          results.details.push({
            ...item,
            success: true,
            uploadedAt: new Date().toISOString()
          });
          
          console.log(chalk.green(`✅ Successfully uploaded: ${item.title} [${item.language}]`));
          
          // Wait between uploads to avoid rate limiting
          await new Promise(resolve => setTimeout(resolve, 2000));
          
        } catch (error) {
          console.error(chalk.red(`❌ Failed to upload: ${item.title} [${item.language}] - ${error.message}`));
          results.failed++;
          results.details.push({
            ...item,
            success: false,
            error: error.message
          });
          
          // Continue with next episode even if one fails
          continue;
        }
      }
      
    } catch (error) {
      console.error(chalk.red(`❌ Upload process failed: ${error.message}`));
      results.success = false;
    } finally {
      await uploader.close();
    }
    
    // Summary
    console.log(chalk.blue('\n📊 Upload Summary:'));
    console.log(chalk.green(`✅ Successfully uploaded: ${results.uploaded}`));
    console.log(chalk.red(`❌ Failed uploads: ${results.failed}`));
    
    return results;
  }
}