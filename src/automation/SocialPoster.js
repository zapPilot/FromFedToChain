import { chromium } from 'playwright';
import chalk from 'chalk';

export class SocialPoster {
  constructor() {
    this.browser = null;
    this.context = null;
  }

  async init() {
    console.log(chalk.blue('📱 Initializing social media poster...'));
    
    this.browser = await chromium.launch({ 
      headless: false, // Keep visible for manual auth
      slowMo: 500
    });
    
    this.context = await this.browser.newContext({
      viewport: { width: 1280, height: 720 }
    });
  }

  async postToTwitter(text, episodeUrl = null) {
    console.log(chalk.blue('🐦 Posting to Twitter/X...'));
    
    const page = await this.context.newPage();
    
    try {
      await page.goto('https://twitter.com/compose/tweet');
      
      // Wait for login if needed
      const isLoggedIn = await page.locator('[data-testid="tweetTextarea_0"]').count() > 0;
      if (!isLoggedIn) {
        console.log(chalk.yellow('⚠️ Please log in to Twitter manually'));
        await page.waitForSelector('[data-testid="tweetTextarea_0"]', { timeout: 120000 });
      }
      
      // Compose tweet
      const fullText = episodeUrl ? `${text}\n\n🎧 Listen: ${episodeUrl}` : text;
      await page.fill('[data-testid="tweetTextarea_0"]', fullText);
      
      // Post tweet
      await page.click('[data-testid="tweetButtonInline"]');
      
      // Wait for success
      await page.waitForSelector('text="Your post was sent"', { timeout: 30000 });
      
      console.log(chalk.green('✅ Posted to Twitter'));
      return { success: true, platform: 'twitter' };
      
    } catch (error) {
      console.error(chalk.red(`❌ Twitter posting failed: ${error.message}`));
      return { success: false, platform: 'twitter', error: error.message };
    } finally {
      await page.close();
    }
  }

  async postToThreads(text, episodeUrl = null) {
    console.log(chalk.blue('🧵 Posting to Threads...'));
    
    const page = await this.context.newPage();
    
    try {
      await page.goto('https://www.threads.net/');
      
      // Wait for compose area or login
      try {
        await page.waitForSelector('[placeholder*="Start a thread"]', { timeout: 10000 });
      } catch {
        console.log(chalk.yellow('⚠️ Please log in to Threads manually'));
        await page.waitForSelector('[placeholder*="Start a thread"]', { timeout: 120000 });
      }
      
      // Compose thread
      const fullText = episodeUrl ? `${text}\n\n🎧 Listen: ${episodeUrl}` : text;
      await page.fill('[placeholder*="Start a thread"]', fullText);
      
      // Post thread
      await page.click('text="Post"');
      
      // Wait for success (URL change or success indicator)
      await page.waitForURL(/threads\.net\/.*\/post\//, { timeout: 30000 });
      
      console.log(chalk.green('✅ Posted to Threads'));
      return { success: true, platform: 'threads' };
      
    } catch (error) {
      console.error(chalk.red(`❌ Threads posting failed: ${error.message}`));
      return { success: false, platform: 'threads', error: error.message };
    } finally {
      await page.close();
    }
  }

  async postToFarcaster(text, episodeUrl = null) {
    console.log(chalk.blue('🏰 Posting to Farcaster (Warpcast)...'));
    
    const page = await this.context.newPage();
    
    try {
      await page.goto('https://warpcast.com/');
      
      // Wait for compose area or login
      try {
        await page.waitForSelector('[placeholder*="What\'s happening"]', { timeout: 10000 });
      } catch {
        console.log(chalk.yellow('⚠️ Please log in to Warpcast manually'));
        await page.waitForSelector('[placeholder*="What\'s happening"]', { timeout: 120000 });
      }
      
      // Compose cast
      const fullText = episodeUrl ? `${text}\n\n🎧 Listen: ${episodeUrl}` : text;
      await page.fill('[placeholder*="What\'s happening"]', fullText);
      
      // Post cast
      await page.click('button:has-text("Cast")');
      
      // Wait for success
      await page.waitForSelector('text="Cast sent"', { timeout: 30000 });
      
      console.log(chalk.green('✅ Posted to Farcaster'));
      return { success: true, platform: 'farcaster' };
      
    } catch (error) {
      console.error(chalk.red(`❌ Farcaster posting failed: ${error.message}`));
      return { success: false, platform: 'farcaster', error: error.message };
    } finally {
      await page.close();
    }
  }

  async postToDeBank(text, episodeUrl = null) {
    console.log(chalk.blue('🏦 Posting to DeBank...'));
    
    const page = await this.context.newPage();
    
    try {
      await page.goto('https://debank.com/stream');
      
      // Wait for login - DeBank requires wallet connection
      console.log(chalk.yellow('⚠️ Please connect wallet and log in to DeBank manually'));
      await page.waitForSelector('[placeholder*="Share"]', { timeout: 120000 });
      
      // Compose post
      const fullText = episodeUrl ? `${text}\n\n🎧 Listen: ${episodeUrl}` : text;
      await page.fill('[placeholder*="Share"]', fullText);
      
      // Post
      await page.click('button:has-text("Post")');
      
      // Wait for success
      await page.waitForSelector('text="Posted successfully"', { timeout: 30000 });
      
      console.log(chalk.green('✅ Posted to DeBank'));
      return { success: true, platform: 'debank' };
      
    } catch (error) {
      console.error(chalk.red(`❌ DeBank posting failed: ${error.message}`));
      return { success: false, platform: 'debank', error: error.message };
    } finally {
      await page.close();
    }
  }

  async close() {
    if (this.browser) {
      await this.browser.close();
    }
  }

  // Post to all platforms
  static async postToAllPlatforms(socialHook, episodeUrl = null, platforms = ['twitter', 'threads', 'farcaster', 'debank']) {
    const poster = new SocialPoster();
    const results = {};
    
    try {
      await poster.init();
      
      for (const platform of platforms) {
        try {
          let result;
          
          switch (platform) {
            case 'twitter':
              result = await poster.postToTwitter(socialHook, episodeUrl);
              break;
            case 'threads':
              result = await poster.postToThreads(socialHook, episodeUrl);
              break;
            case 'farcaster':
              result = await poster.postToFarcaster(socialHook, episodeUrl);
              break;
            case 'debank':
              result = await poster.postToDeBank(socialHook, episodeUrl);
              break;
            default:
              result = { success: false, platform, error: 'Unknown platform' };
          }
          
          results[platform] = result;
          
          // Wait between posts to avoid rate limiting
          await new Promise(resolve => setTimeout(resolve, 2000));
          
        } catch (error) {
          results[platform] = { 
            success: false, 
            platform, 
            error: error.message 
          };
        }
      }
      
    } finally {
      await poster.close();
    }
    
    return results;
  }
}