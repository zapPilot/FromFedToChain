#!/usr/bin/env node

import fs from "fs/promises";
import path from "path";
import { createReadStream } from "fs";
import { TextToSpeechClient } from "@google-cloud/text-to-speech";
import { google } from "googleapis";
import chalk from "chalk";

// Voice configurations for different languages
const VOICE_CONFIG = {
  'zh-TW': {
    languageCode: "zh-TW",
    name: "cmn-TW-Wavenet-B",
    folderId: "14AhPDY0WCrL6G_W6ZZ6cfR01znf0WLKF"
  },
  'en-US': {
    languageCode: "en-US", 
    name: "en-US-Wavenet-D",
    folderId: "1MkzZPY2iu09smRAwzGwXXG5_-hUDCVLw"
  },
  'ja-JP': {
    languageCode: "ja-JP",
    name: "ja-JP-Wavenet-C",
    folderId: "1KJ1WHnnFtsafzsrWuK6S3S8Atym5lVDs"
  }
};

async function findPendingContent() {
  const contentDir = './content';
  const pendingFiles = [];
  
  async function scanDirectory(dir) {
    const items = await fs.readdir(dir, { withFileTypes: true });
    
    for (const item of items) {
      const fullPath = path.join(dir, item.name);
      
      if (item.isDirectory()) {
        await scanDirectory(fullPath);
      } else if (item.name.endsWith('.json')) {
        try {
          const content = await fs.readFile(fullPath, 'utf-8');
          const data = JSON.parse(content);
          
          // Check if file uses new schema format
          if (data.languages && data.metadata?.tts) {
            // Check each language for pending TTS
            for (const [lang, langData] of Object.entries(data.languages)) {
              const ttsStatus = data.metadata.tts[lang];
              if (ttsStatus && ttsStatus.status === 'pending') {
                pendingFiles.push({
                  path: fullPath,
                  language: lang,
                  title: langData.title,
                  content: langData.content,
                  id: data.id,
                  voiceConfig: VOICE_CONFIG[lang] || VOICE_CONFIG['zh-TW']
                });
              }
            }
          }
        } catch (error) {
          console.log(chalk.yellow(`⚠️  Warning: Could not parse JSON file ${fullPath}`));
        }
      }
    }
  }
  
  await scanDirectory(contentDir);
  return pendingFiles;
}

async function updateTTSStatus(filePath, language, audioUrl) {
  const content = await fs.readFile(filePath, 'utf-8');
  const data = JSON.parse(content);
  
  // Update TTS metadata for specific language
  if (data.metadata && data.metadata.tts && data.metadata.tts[language]) {
    data.metadata.tts[language].status = 'completed';
    data.metadata.tts[language].audio_url = audioUrl;
    data.metadata.updated_at = new Date().toISOString();
  }
  
  // Write back to file with pretty formatting
  await fs.writeFile(filePath, JSON.stringify(data, null, 2));
}

function getContentForTTS(content, language) {
  // For English, if it has social format, use just the content part
  if (language === 'en' && content.includes('🚀')) {
    // Extract content after social hook
    const parts = content.split('\n\n');
    if (parts.length > 1) {
      return parts.slice(1).join('\n\n');
    }
  }
  return content;
}

async function main() {
  try {
    console.log(chalk.blue.bold('🎙️ Multi-Language TTS Pipeline'));
    console.log(chalk.gray('='.repeat(50)));
    
    // Setup Google Cloud Authentication
    const credsPath = './service-account.json';
    process.env.GOOGLE_APPLICATION_CREDENTIALS = credsPath;
    
    // Initialize clients
    const ttsClient = new TextToSpeechClient();
    const auth = new google.auth.GoogleAuth({
      scopes: ["https://www.googleapis.com/auth/drive.file"],
    });
    const authClient = await auth.getClient();
    const drive = google.drive({ version: "v3", auth: authClient });
    
    // Find pending content
    console.log(chalk.blue('🔍 Scanning for pending TTS content...'));
    const pendingFiles = await findPendingContent();
    
    if (pendingFiles.length === 0) {
      console.log(chalk.green('✅ No pending TTS content found.'));
      return;
    }
    
    console.log(chalk.yellow(`📝 Found ${pendingFiles.length} files with pending TTS status:`));
    pendingFiles.forEach(file => {
      console.log(`  ${chalk.cyan(file.language.toUpperCase())} - ${file.title}`);
    });
    
    // Process each file
    for (const file of pendingFiles) {
      console.log(chalk.blue(`\n🎙️ Processing [${file.language.toUpperCase()}]: ${file.title}`));
      
      // Get voice configuration
      const voiceConfig = file.voiceConfig;
      if (!voiceConfig) {
        console.log(chalk.red(`  ❌ No voice configuration for language: ${file.language}`));
        continue;
      }
      
      // Prepare content for TTS
      const ttsContent = getContentForTTS(file.content, file.language);
      
      console.log(chalk.gray(`  📢 Generating speech (${voiceConfig.name})...`));
      
      // Generate speech
      try {
        const [response] = await ttsClient.synthesizeSpeech({
          input: { text: ttsContent },
          voice: {
            languageCode: voiceConfig.languageCode,
            name: voiceConfig.name
          },
          audioConfig: { audioEncoding: "MP3" },
        });
        
        // Save temporary file
        const fileName = `${file.id}_${file.language}.mp3`;
        const filePath = `/tmp/${fileName}`;
        await fs.writeFile(filePath, response.audioContent, "binary");
        
        // Upload to Google Drive
        console.log(chalk.gray('  ☁️ Uploading to Google Drive...'));
        const uploaded = await drive.files.create({
          requestBody: {
            name: fileName,
            mimeType: "audio/mpeg",
            parents: [voiceConfig.folderId]
          },
          media: {
            mimeType: "audio/mpeg",
            body: createReadStream(filePath),
          },
        });
        
        const driveUrl = `https://drive.google.com/file/d/${uploaded.data.id}/view`;
        console.log(chalk.green(`  ✅ Uploaded: ${driveUrl}`));
        
        // Update file status
        await updateTTSStatus(file.path, file.language, driveUrl);
        console.log(chalk.gray(`  📝 Updated status in: ${path.basename(file.path)}`));
        
        // Clean up temp file
        await fs.unlink(filePath);
        
      } catch (error) {
        console.log(chalk.red(`  ❌ Failed to process ${file.language}: ${error.message}`));
      }
    }
    
    console.log(chalk.green.bold(`\n🎉 Completed TTS processing for ${pendingFiles.length} files!`));
    
  } catch (error) {
    console.error(chalk.red('❌ Error:'), error);
    process.exit(1);
  }
}

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}

export { findPendingContent, updateTTSStatus };