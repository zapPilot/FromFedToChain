#!/usr/bin/env node

import fs from "fs/promises";
import path from "path";
import chalk from "chalk";

async function findEnglishContent() {
  const contentDir = './content/en';
  const files = [];
  
  async function scanDirectory(dir) {
    try {
      const items = await fs.readdir(dir, { withFileTypes: true });
      
      for (const item of items) {
        const fullPath = path.join(dir, item.name);
        
        if (item.isDirectory()) {
          await scanDirectory(fullPath);
        } else if (item.name.endsWith('.json')) {
          try {
            const content = await fs.readFile(fullPath, 'utf-8');
            const data = JSON.parse(content);
            
            if (data.languages?.en) {
              files.push({
                path: fullPath,
                data,
                category: data.category,
                id: data.id
              });
            }
          } catch (error) {
            console.log(chalk.yellow(`⚠️  Warning: Could not parse ${fullPath}`));
          }
        }
      }
    } catch (error) {
      // Directory doesn't exist yet
    }
  }
  
  await scanDirectory(contentDir);
  return files;
}

function formatForPlatform(content, platform) {
  const socialFormat = content.languages.en.social_format;
  
  if (!socialFormat) {
    return {
      error: "No social format available. Run translation first."
    };
  }
  
  switch (platform) {
    case 'twitter':
      return formatForTwitter(socialFormat);
    case 'linkedin':
      return formatForLinkedIn(socialFormat);
    case 'facebook':
      return formatForFacebook(socialFormat);
    default:
      return formatForGeneric(socialFormat);
  }
}

function formatForTwitter(socialFormat) {
  const maxLength = 280;
  const hook = socialFormat.hook;
  
  if (hook.length <= maxLength) {
    return {
      post: hook,
      thread: splitIntoThread(socialFormat.full_script, maxLength)
    };
  }
  
  return {
    post: hook.substring(0, maxLength - 3) + "...",
    thread: splitIntoThread(socialFormat.full_script, maxLength)
  };
}

function formatForLinkedIn(socialFormat) {
  return {
    post: `${socialFormat.hook}\n\n${socialFormat.full_script}\n\n#Crypto #Finance #Blockchain #FinTech`
  };
}

function formatForFacebook(socialFormat) {
  return {
    post: `${socialFormat.hook}\n\n${socialFormat.full_script}`
  };
}

function formatForGeneric(socialFormat) {
  return {
    hook: socialFormat.hook,
    full_script: socialFormat.full_script,
    combined: socialFormat.full_script,
    post: socialFormat.full_script
  };
}

function splitIntoThread(content, maxLength) {
  const sentences = content.split(/[.!?]\s+/);
  const thread = [];
  let currentTweet = "";
  let tweetIndex = 1;
  
  for (const sentence of sentences) {
    const addition = sentence + ". ";
    const prefix = `${tweetIndex}/ `;
    
    if ((currentTweet + addition).length + prefix.length <= maxLength) {
      currentTweet += addition;
    } else {
      if (currentTweet) {
        thread.push(`${tweetIndex}/ ${currentTweet.trim()}`);
        tweetIndex++;
        currentTweet = addition;
      }
    }
  }
  
  if (currentTweet) {
    thread.push(`${tweetIndex}/ ${currentTweet.trim()}`);
  }
  
  return thread;
}

function displaySocialPreview(content, platform) {
  const formatted = formatForPlatform(content, platform);
  
  if (formatted.error) {
    console.log(chalk.red(`❌ ${formatted.error}`));
    return;
  }
  
  console.log(chalk.blue.bold(`\n📱 ${platform.toUpperCase()} Preview`));
  console.log(chalk.gray('='.repeat(50)));
  
  switch (platform) {
    case 'twitter':
      console.log(chalk.green('🐦 Main Tweet:'));
      console.log(formatted.post);
      
      if (formatted.thread && formatted.thread.length > 1) {
        console.log(chalk.green('\n🧵 Thread:'));
        formatted.thread.forEach(tweet => {
          console.log(chalk.gray('---'));
          console.log(tweet);
        });
      }
      break;
      
    default:
      console.log(formatted.post);
      break;
  }
  
  console.log(chalk.gray('='.repeat(50)));
}

async function main() {
  const args = process.argv.slice(2);
  const fileId = args.find(arg => !arg.startsWith('--'))?.replace('--file_id=', '');
  const platform = args.find(arg => arg.startsWith('--platform='))?.split('=')[1] || 'generic';
  
  try {
    console.log(chalk.blue.bold('📱 Social Media Formatter'));
    console.log(chalk.gray('='.repeat(50)));
    
    if (!fileId) {
      // Show all available English content
      console.log(chalk.blue('📂 Available English content:'));
      const files = await findEnglishContent();
      
      if (files.length === 0) {
        console.log(chalk.yellow('⚠️  No English content found. Run translation first.'));
        return;
      }
      
      files.forEach(file => {
        const title = file.data.languages.en.title;
        console.log(`  📄 ${file.id}`);
        console.log(`     ${chalk.gray(title)}`);
      });
      
      console.log(chalk.gray('\nUsage: npm run social <file_id> [--platform=twitter|linkedin|facebook]'));
      return;
    }
    
    // Find specific file
    const files = await findEnglishContent();
    const targetFile = files.find(f => f.id === fileId);
    
    if (!targetFile) {
      console.log(chalk.red(`❌ File not found: ${fileId}`));
      console.log(chalk.gray('Available files:'));
      files.forEach(f => console.log(`  - ${f.id}`));
      return;
    }
    
    console.log(chalk.green(`📄 Processing: ${targetFile.data.languages.en.title}`));
    console.log(chalk.cyan(`📱 Platform: ${platform}`));
    
    displaySocialPreview(targetFile.data, platform);
    
  } catch (error) {
    console.error(chalk.red('❌ Error:'), error.message);
    process.exit(1);
  }
}

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}

export { findEnglishContent, formatForPlatform };