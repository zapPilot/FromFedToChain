#!/usr/bin/env node

import fs from "fs/promises";
import path from "path";
import { createReadStream } from "fs";
import { TextToSpeechClient } from "@google-cloud/text-to-speech";
import { google } from "googleapis";
import chalk from "chalk";
import cliProgress from "cli-progress";
import { VOICE_CONFIG, PATHS } from '../config/languages.js';

// Upload records file to track uploaded files and prevent duplicates
const UPLOAD_RECORDS_FILE = './upload-records.json';

async function loadUploadRecords() {
  try {
    const content = await fs.readFile(UPLOAD_RECORDS_FILE, 'utf-8');
    return JSON.parse(content);
  } catch (error) {
    // File doesn't exist or is invalid, return empty records
    return {};
  }
}

async function saveUploadRecords(records) {
  await fs.writeFile(UPLOAD_RECORDS_FILE, JSON.stringify(records, null, 2));
}

function generateFileHash(fileId, language, content) {
  // Create a simple hash based on content length and first/last chars
  const start = content.substring(0, 50);
  const end = content.substring(content.length - 50);
  return `${fileId}_${language}_${content.length}_${Buffer.from(start + end).toString('base64').substring(0, 10)}`;
}

async function isAlreadyUploaded(fileId, language, content, uploadRecords) {
  const hash = generateFileHash(fileId, language, content);
  return uploadRecords[hash] || null;
}

async function recordUpload(fileId, language, content, driveUrl, uploadRecords) {
  const hash = generateFileHash(fileId, language, content);
  uploadRecords[hash] = {
    fileId,
    language,
    driveUrl,
    uploadedAt: new Date().toISOString(),
    contentLength: content.length
  };
  await saveUploadRecords(uploadRecords);
}

function getCategoryFromPath(filePath) {
  // Extract category from file path (e.g., /content/zh-TW/daily-news/file.json -> daily-news)
  const pathParts = filePath.split(path.sep);
  const contentIndex = pathParts.findIndex(part => part === 'content');
  if (contentIndex !== -1 && pathParts.length > contentIndex + 2) {
    return pathParts[contentIndex + 2]; // category is after /content/{language}/
  }
  return 'daily-news'; // default fallback
}

async function findPendingContent() {
  const contentDir = PATHS.CONTENT_ROOT;
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
              const translationStatus = data.metadata.translation_status;
              
              // Safe checking for rejection field (might not exist in older files)
              const isRejected = translationStatus?.rejection?.rejected === true;
              const isReviewed = translationStatus?.source_reviewed === true;
              
              if (ttsStatus && ttsStatus.status === 'pending' && !isRejected && isReviewed) {
                const category = getCategoryFromPath(fullPath);
                pendingFiles.push({
                  path: fullPath,
                  language: lang,
                  title: langData.title,
                  content: langData.content,
                  id: data.id,
                  category: category,
                  voiceConfig: VOICE_CONFIG[lang] || VOICE_CONFIG['zh-TW']
                });
              }
            }
          }
        } catch (error) {
          console.log(chalk.yellow(`⚠️  Warning: Could not parse JSON file ${fullPath}: ${error.message}`));
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
  if (language === 'en-US' && content.includes('🚀')) {
    // Extract content after social hook
    const parts = content.split('\n\n');
    if (parts.length > 1) {
      return parts.slice(1).join('\n\n');
    }
  }
  return content;
}

async function retryOperation(operation, maxRetries = 3, delayMs = 1000) {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await operation();
    } catch (error) {
      if (attempt === maxRetries) {
        throw error;
      }
      console.log(chalk.yellow(`  ⚠️  Attempt ${attempt} failed: ${error.message}`));
      console.log(chalk.gray(`  ⏳ Retrying in ${delayMs}ms... (${attempt}/${maxRetries})`));
      await new Promise(resolve => setTimeout(resolve, delayMs));
      delayMs *= 2; // Exponential backoff
    }
  }
}

async function processFile(file, ttsClient, drive, uploadRecords) {
  console.log(chalk.blue(`🎙️ Processing [${file.language.toUpperCase()}]: ${file.title}`));
  
  // Get voice configuration
  const voiceConfig = file.voiceConfig;
  if (!voiceConfig) {
    throw new Error(`No voice configuration for language: ${file.language}`);
  }
  
  // Get category-specific folder ID
  const folderId = voiceConfig.folders?.[file.category];
  if (!folderId) {
    throw new Error(`No folder ID for category '${file.category}' in language '${file.language}'`);
  }
  
  // Prepare content for TTS
  const ttsContent = getContentForTTS(file.content, file.language);
  
  // Check if already uploaded
  const existingUpload = await isAlreadyUploaded(file.id, file.language, ttsContent, uploadRecords);
  if (existingUpload) {
    console.log(chalk.yellow(`  ⏭️  Already uploaded: ${existingUpload.driveUrl}`));
    console.log(chalk.gray(`  📝 Using existing upload from ${existingUpload.uploadedAt}`));
    
    // Update file status with existing URL
    await updateTTSStatus(file.path, file.language, existingUpload.driveUrl);
    console.log(chalk.gray(`  📝 Updated status in: ${path.basename(file.path)}`));
    return { success: true, url: existingUpload.driveUrl };
  }
  
  console.log(chalk.gray(`  📢 Generating speech (${voiceConfig.name}) -> ${file.category} folder...`));
  
  // Generate speech with retry
  const response = await retryOperation(async () => {
    const [result] = await ttsClient.synthesizeSpeech({
      input: { text: ttsContent },
      voice: {
        languageCode: voiceConfig.languageCode,
        name: voiceConfig.name
      },
      audioConfig: { audioEncoding: "MP3" },
    });
    return result;
  });
  
  // Save temporary file
  const fileName = `${file.id}_${file.language}.mp3`;
  const filePath = `/tmp/${fileName}`;
  await fs.writeFile(filePath, response.audioContent, "binary");
  
  // Upload to Google Drive with retry
  console.log(chalk.gray(`  ☁️ Uploading to Google Drive (${file.category})...`));
  const uploaded = await retryOperation(async () => {
    return await drive.files.create({
      requestBody: {
        name: fileName,
        mimeType: "audio/mpeg",
        parents: [folderId]
      },
      media: {
        mimeType: "audio/mpeg",
        body: createReadStream(filePath),
      },
    });
  });
  
  const driveUrl = `https://drive.google.com/file/d/${uploaded.data.id}/view`;
  console.log(chalk.green(`  ✅ Uploaded: ${driveUrl}`));
  
  // Record the upload to prevent duplicates
  await recordUpload(file.id, file.language, ttsContent, driveUrl, uploadRecords);
  console.log(chalk.gray(`  📋 Recorded upload for duplicate prevention`));
  
  // Update file status
  await updateTTSStatus(file.path, file.language, driveUrl);
  console.log(chalk.gray(`  📝 Updated status in: ${path.basename(file.path)}`));
  
  // Clean up temp file
  await fs.unlink(filePath);
  
  return { success: true, url: driveUrl };
}

async function main() {
  try {
    console.log(chalk.blue.bold('🎙️ Multi-Language TTS Pipeline'));
    console.log(chalk.gray('='.repeat(50)));
    
    // Load upload records to prevent duplicates
    console.log(chalk.blue('📋 Loading upload records...'));
    const uploadRecords = await loadUploadRecords();
    console.log(chalk.gray(`Found ${Object.keys(uploadRecords).length} existing upload records`));
    
    // Setup Google Cloud Authentication
    const credsPath = PATHS.SERVICE_ACCOUNT;
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
    
    // Setup progress bar
    const progressBar = new cliProgress.SingleBar({
      format: chalk.cyan('{bar}') + ' {percentage}% | {value}/{total} files | ETA: {eta}s | {speed}/s',
      barCompleteChar: '\u2588',
      barIncompleteChar: '\u2591',
      hideCursor: true
    }, cliProgress.Presets.rect);

    progressBar.start(pendingFiles.length, 0);
    
    // Process files with controlled concurrency (max 3 concurrent to avoid rate limits)
    const maxConcurrency = 3;
    const results = [];
    let completed = 0;
    
    for (let i = 0; i < pendingFiles.length; i += maxConcurrency) {
      const batch = pendingFiles.slice(i, i + maxConcurrency);
      
      const batchPromises = batch.map(async (file) => {
        try {
          const result = await processFile(file, ttsClient, drive, uploadRecords);
          completed++;
          progressBar.update(completed);
          return { file, result, success: true };
        } catch (error) {
          throw error;
          console.log(chalk.red(`❌ Failed to process ${file.language}: ${file.title}`));
          console.log(chalk.red(`   Error: ${error.message}`));
          completed++;
          progressBar.update(completed);
          return { file, error: error.message, success: false };
        }
      });
      
      const batchResults = await Promise.all(batchPromises);
      results.push(...batchResults);
    }
    
    progressBar.stop();
    
    // Summary of results
    const successful = results.filter(r => r.success).length;
    const failed = results.filter(r => !r.success).length;
    
    console.log(chalk.green.bold(`\n🎉 TTS Processing Complete!`));
    console.log(chalk.green(`✅ Successful: ${successful}`));
    if (failed > 0) {
      console.log(chalk.red(`❌ Failed: ${failed}`));
      console.log(chalk.yellow('\nFailed files:'));
      results.filter(r => !r.success).forEach(result => {
        console.log(`  ${chalk.red('❌')} ${result.file.language}: ${result.file.title}`);
        console.log(`     ${chalk.gray(result.error)}`);
      });
    }
    console.log(chalk.blue(`📊 Total processed: ${pendingFiles.length} files`));
    
  } catch (error) {
    console.error(chalk.red('❌ Error:'), error);
    process.exit(1);
  }
}

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}

export { findPendingContent, updateTTSStatus, loadUploadRecords, saveUploadRecords, processFile, retryOperation };