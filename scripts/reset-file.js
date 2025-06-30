#!/usr/bin/env node

import fs from "fs/promises";
import path from "path";
import chalk from "chalk";
import { FileUtils } from "../lib/utils/FileUtils.js";
import { Logger } from "../lib/utils/Logger.js";

const args = process.argv.slice(2);
const fileId = args[0];
const steps = args.slice(1).filter(arg => !arg.startsWith('--'));

async function main() {
  if (!fileId) {
    console.log(chalk.red("❌ Usage: npm run reset-file <file-id> [steps...]"));
    console.log(chalk.yellow("Steps: translation, tts, social"));
    console.log(chalk.yellow("Example: npm run reset-file 2025-06-28-crypto-news"));
    console.log(chalk.yellow("Example: npm run reset-file 2025-06-28-crypto-news translation tts"));
    process.exit(1);
  }

  const allSteps = steps.length === 0 ? ['translation', 'tts', 'social'] : steps;
  const validSteps = ['translation', 'tts', 'social'];
  
  for (const step of allSteps) {
    if (!validSteps.includes(step)) {
      console.log(chalk.red(`❌ Invalid step: ${step}`));
      console.log(chalk.yellow(`Valid steps: ${validSteps.join(', ')}`));
      process.exit(1);
    }
  }

  console.log(chalk.blue.bold(`🔄 Resetting file: ${fileId}`));
  console.log(chalk.gray(`Steps: ${allSteps.join(', ')}`));
  console.log(chalk.gray("=".repeat(50)));

  try {
    // Find source file
    const sourceFile = await FileUtils.findSourceFile(fileId);
    console.log(chalk.green(`✅ Found source file: ${sourceFile.path}`));

    let resetCount = 0;

    // Reset translation step
    if (allSteps.includes('translation')) {
      const translationCount = await resetTranslationStep(fileId, sourceFile.category);
      resetCount += translationCount;
    }

    // Reset TTS step
    if (allSteps.includes('tts')) {
      const ttsCount = await resetTTSStep(fileId, sourceFile.category);
      resetCount += ttsCount;
    }

    // Reset social step
    if (allSteps.includes('social')) {
      const socialCount = await resetSocialStep(fileId, sourceFile.category);
      resetCount += socialCount;
    }

    console.log(chalk.green.bold(`\n🎉 Reset completed!`));
    console.log(chalk.green(`Total files processed: ${resetCount}`));
    console.log(chalk.blue(`\n💡 You can now run: npm run pipeline`));

  } catch (error) {
    console.error(chalk.red("❌ Reset failed:"), error.message);
    process.exit(1);
  }
}

async function resetTranslationStep(fileId, category) {
  console.log(chalk.blue("\n📝 Resetting translation step..."));
  
  const languages = ['en-US', 'ja-JP'];
  let resetCount = 0;

  for (const lang of languages) {
    const translatedPath = FileUtils.getContentPath(lang, category, fileId);
    
    try {
      await fs.access(translatedPath);
      await fs.unlink(translatedPath);
      console.log(chalk.yellow(`🗑️  Removed: ${path.basename(translatedPath)}`));
      resetCount++;
    } catch (e) {
      // File doesn't exist, skip
    }
  }

  if (resetCount === 0) {
    console.log(chalk.gray("   No translation files to reset"));
  }

  return resetCount;
}

async function resetTTSStep(fileId, category) {
  console.log(chalk.blue("\n🎙️ Resetting TTS step..."));
  
  const languages = ['zh-TW', 'en-US', 'ja-JP'];
  let resetCount = 0;

  for (const lang of languages) {
    const filePath = FileUtils.getContentPath(lang, category, fileId);
    
    try {
      await fs.access(filePath);
      
      // Read and update file metadata
      const content = await FileUtils.readJSON(filePath);
      
      if (content.metadata?.tts) {
        // Reset TTS status for all languages
        for (const ttsLang of Object.keys(content.metadata.tts)) {
          if (content.metadata.tts[ttsLang]) {
            content.metadata.tts[ttsLang].status = 'pending';
            content.metadata.tts[ttsLang].audio_path = null;
            content.metadata.tts[ttsLang].audio_url = null;
          }
        }
        
        content.metadata.updated_at = new Date().toISOString();
        await FileUtils.writeJSON(filePath, content);
        
        console.log(chalk.yellow(`🔄 Reset TTS status in: ${path.basename(filePath)}`));
        resetCount++;
      }

      // Remove audio files
      const audioFiles = await findAudioFiles(fileId, lang);
      for (const audioFile of audioFiles) {
        try {
          await fs.unlink(audioFile);
          console.log(chalk.yellow(`🗑️  Removed audio: ${path.basename(audioFile)}`));
        } catch (e) {
          // Audio file doesn't exist, skip
        }
      }

    } catch (e) {
      // File doesn't exist, skip
    }
  }

  if (resetCount === 0) {
    console.log(chalk.gray("   No TTS data to reset"));
  }

  return resetCount;
}

async function resetSocialStep(fileId, category) {
  console.log(chalk.blue("\n📱 Resetting social step..."));
  
  const languages = ['en-US', 'ja-JP'];
  let resetCount = 0;

  for (const lang of languages) {
    const filePath = FileUtils.getContentPath(lang, category, fileId);
    
    try {
      await fs.access(filePath);
      
      // Read and update file metadata
      const content = await FileUtils.readJSON(filePath);
      
      if (content.social_hooks) {
        delete content.social_hooks;
        content.metadata.updated_at = new Date().toISOString();
        await FileUtils.writeJSON(filePath, content);
        
        console.log(chalk.yellow(`🔄 Removed social hooks from: ${path.basename(filePath)}`));
        resetCount++;
      }

    } catch (e) {
      // File doesn't exist, skip
    }
  }

  // Remove social media platform files
  const socialFiles = await findSocialFiles(fileId);
  for (const socialFile of socialFiles) {
    try {
      await fs.unlink(socialFile);
      console.log(chalk.yellow(`🗑️  Removed social file: ${socialFile}`));
    } catch (e) {
      // File doesn't exist, skip
    }
  }

  if (resetCount === 0) {
    console.log(chalk.gray("   No social data to reset"));
  }

  return resetCount;
}

async function findAudioFiles(fileId, language) {
  const audioFiles = [];
  const audioDir = `./audio/${language}`;
  
  try {
    const files = await fs.readdir(audioDir, { recursive: true });
    for (const file of files) {
      if (typeof file === 'string' && file.includes(fileId) && file.endsWith('.wav')) {
        audioFiles.push(path.join(audioDir, file));
      }
    }
  } catch (e) {
    // Audio directory doesn't exist
  }

  return audioFiles;
}

async function findSocialFiles(fileId) {
  const socialFiles = [];
  const socialDir = './social';
  
  try {
    const scan = async (dir) => {
      const items = await fs.readdir(dir, { withFileTypes: true });
      for (const item of items) {
        const fullPath = path.join(dir, item.name);
        if (item.isDirectory()) {
          await scan(fullPath);
        } else if (item.name.includes(fileId) && (item.name.endsWith('.txt') || item.name.endsWith('.json'))) {
          socialFiles.push(fullPath);
        }
      }
    };
    
    await scan(socialDir);
  } catch (e) {
    // Social directory doesn't exist
  }

  return socialFiles;
}

main();