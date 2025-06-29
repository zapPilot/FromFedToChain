#!/usr/bin/env node

import { AudioStorageService } from '../lib/services/AudioStorage.js';
import chalk from 'chalk';

const args = process.argv.slice(2);
const command = args[0] || 'list';

async function main() {
  const audioStorage = new AudioStorageService();
  
  try {
    switch (command) {
      case 'list':
        await listAudioFiles(audioStorage, args[1], args[2]);
        break;
        
      case 'stats':
        await showStats(audioStorage);
        break;
        
      case 'delete':
        if (args.length < 4) {
          console.log(chalk.red('Usage: npm run audio delete <fileId> <language> <category>'));
          return;
        }
        await deleteAudio(audioStorage, args[1], args[2], args[3]);
        break;
        
      default:
        console.log(chalk.blue.bold('🎵 Audio Manager Commands:'));
        console.log(chalk.gray('='.repeat(30)));
        console.log(chalk.cyan('npm run audio list') + chalk.gray(' - List all audio files'));
        console.log(chalk.cyan('npm run audio list en-US') + chalk.gray(' - List files for language'));
        console.log(chalk.cyan('npm run audio list en-US daily-news') + chalk.gray(' - List files for language+category'));
        console.log(chalk.cyan('npm run audio stats') + chalk.gray(' - Show storage statistics'));
        console.log(chalk.cyan('npm run audio delete <fileId> <lang> <category>') + chalk.gray(' - Delete audio file'));
        break;
    }
  } catch (error) {
    console.error(chalk.red('❌ Audio manager error:'), error.message);
  }
}

async function listAudioFiles(audioStorage, language, category) {
  console.log(chalk.blue.bold('🎵 Audio Files'));
  console.log(chalk.gray('='.repeat(50)));
  
  const files = await audioStorage.listAudioFiles(language, category);
  
  if (files.length === 0) {
    console.log(chalk.yellow('No audio files found.'));
    return;
  }
  
  files.forEach(file => {
    const size = audioStorage.formatFileSize(file.size);
    const date = file.modified.toLocaleDateString();
    console.log(`${chalk.cyan(file.fileId)} (${chalk.yellow(file.language)}) [${chalk.green(file.category)}]`);
    console.log(`  📄 ${file.path}`);
    console.log(`  📊 ${size} • ${chalk.gray(date)}`);
    console.log('');
  });
  
  console.log(chalk.blue(`Total: ${files.length} files`));
}

async function showStats(audioStorage) {
  console.log(chalk.blue.bold('📊 Audio Storage Statistics'));
  console.log(chalk.gray('='.repeat(40)));
  
  const stats = await audioStorage.getStorageStats();
  
  console.log(chalk.cyan('Overall:'));
  console.log(`  Total Files: ${stats.totalFiles}`);
  console.log(`  Total Size: ${audioStorage.formatFileSize(stats.totalSize)}`);
  console.log('');
  
  console.log(chalk.cyan('By Language:'));
  Object.entries(stats.byLanguage).forEach(([lang, data]) => {
    console.log(`  ${lang}: ${data.count} files (${audioStorage.formatFileSize(data.size)})`);
  });
  console.log('');
  
  console.log(chalk.cyan('By Category:'));
  Object.entries(stats.byCategory).forEach(([cat, data]) => {
    console.log(`  ${cat}: ${data.count} files (${audioStorage.formatFileSize(data.size)})`);
  });
  console.log('');
  
  console.log(chalk.cyan('By Format:'));
  Object.entries(stats.byExtension).forEach(([ext, data]) => {
    console.log(`  ${ext.toUpperCase()}: ${data.count} files (${audioStorage.formatFileSize(data.size)})`);
  });
}

async function deleteAudio(audioStorage, fileId, language, category) {
  console.log(chalk.yellow(`🗑️  Deleting audio: ${fileId} (${language}/${category})`));
  
  const deleted = await audioStorage.deleteAudioFile(fileId, language, category);
  
  if (deleted) {
    console.log(chalk.green('✅ Audio file deleted successfully'));
  } else {
    console.log(chalk.red('❌ Audio file not found or could not be deleted'));
  }
}

main();