#!/usr/bin/env node

import fs from "fs/promises";
import path from "path";
import chalk from "chalk";
import { execSync } from "child_process";
import { LANGUAGES, CATEGORIES, PATHS } from '../config/languages.js';

async function showPendingTranslations() {
  console.log(chalk.blue.bold('🌐 Translation Workflow Dashboard'));
  console.log(chalk.gray('='.repeat(50)));
  
  const sourcePath = path.join(PATHS.CONTENT_ROOT, LANGUAGES.PRIMARY);
  const pendingFiles = [];
  
  // Scan for reviewed content ready for translation
  for (const category of CATEGORIES) {
    const categoryDir = path.join(sourcePath, category);
    try {
      const files = await fs.readdir(categoryDir);
      for (const file of files.filter(f => f.endsWith('.json'))) {
        const filePath = path.join(categoryDir, file);
        try {
          const content = await fs.readFile(filePath, 'utf-8');
          const data = JSON.parse(content);
          
          if (data.metadata?.translation_status?.source_reviewed === true) {
            const translatedTo = data.metadata.translation_status.translated_to || [];
            const availableTargets = LANGUAGES.SUPPORTED.filter(lang => 
              lang !== LANGUAGES.PRIMARY && !translatedTo.includes(lang)
            );
            
            if (availableTargets.length > 0) {
              pendingFiles.push({
                id: data.id || path.basename(file, '.json'),
                title: data.languages?.[LANGUAGES.PRIMARY]?.title || '[No title]',
                category,
                translatedTo,
                availableTargets,
                file
              });
            }
          }
        } catch (error) {
          console.log(chalk.yellow(`⚠️  Could not parse: ${file}`));
        }
      }
    } catch (error) {
      // Category directory doesn't exist, skip
    }
  }
  
  if (pendingFiles.length === 0) {
    console.log(chalk.green('✅ No content ready for translation.'));
    console.log(chalk.gray('Run "npm run review" to review source content first.'));
    return null;
  }
  
  console.log(chalk.yellow(`📝 Found ${pendingFiles.length} files ready for translation:`));
  console.log('');
  
  pendingFiles.forEach((file, index) => {
    console.log(`${chalk.cyan((index + 1).toString().padStart(2))}: ${chalk.white(file.title)}`);
    console.log(`    ${chalk.gray('ID:')} ${file.id}`);
    console.log(`    ${chalk.gray('Category:')} ${file.category}`);
    console.log(`    ${chalk.gray('Available targets:')} ${file.availableTargets.join(', ')}`);
    if (file.translatedTo.length > 0) {
      console.log(`    ${chalk.gray('Already translated to:')} ${file.translatedTo.join(', ')}`);
    }
    console.log('');
  });
  
  return pendingFiles;
}

async function translateFile(fileId, targetLang = 'en-US') {
  console.log(chalk.blue(`🔄 Starting translation: ${fileId} → ${targetLang}`));
  
  try {
    // Use the existing translate script
    const command = `node scripts/translate.js ${fileId} --target_lang=${targetLang}`;
    console.log(chalk.gray(`Running: ${command}`));
    
    execSync(command, { 
      stdio: 'inherit',
      cwd: process.cwd()
    });
    
    console.log(chalk.green(`✅ Translation completed: ${fileId} → ${targetLang}`));
    return true;
  } catch (error) {
    console.log(chalk.red(`❌ Translation failed: ${error.message}`));
    return false;
  }
}

async function batchTranslate(fileIds, targetLang = 'en-US') {
  console.log(chalk.blue.bold(`🚀 Batch Translation: ${fileIds.length} files → ${targetLang}`));
  console.log(chalk.gray('='.repeat(50)));
  
  const results = { success: 0, failed: 0 };
  
  for (let i = 0; i < fileIds.length; i++) {
    const fileId = fileIds[i];
    console.log(chalk.blue(`\n[${i + 1}/${fileIds.length}] Translating: ${fileId}`));
    
    const success = await translateFile(fileId, targetLang);
    if (success) {
      results.success++;
    } else {
      results.failed++;
    }
  }
  
  console.log(chalk.green.bold(`\n🎉 Batch translation completed!`));
  console.log(`${chalk.green('✅ Success:')} ${results.success}`);
  console.log(`${chalk.red('❌ Failed:')} ${results.failed}`);
  
  if (results.success > 0) {
    console.log(chalk.gray(`\nNext steps:`));
    console.log(chalk.gray(`- Run "npm run tts" to generate audio files`));
    console.log(chalk.gray(`- Review translations in ./content/${targetLang}/`));
  }
}

async function main() {
  const args = process.argv.slice(2);
  const command = args[0];
  
  switch (command) {
    case 'list':
    case 'show':
    case undefined:
      await showPendingTranslations();
      break;
      
    case 'translate': {
      const fileId = args[1];
      const targetLang = args.find(arg => arg.startsWith('--target='))?.split('=')[1] || 'en-US';
      
      if (!fileId) {
        console.error(chalk.red('❌ Error: file_id is required'));
        console.log(chalk.gray('Usage: npm run translate translate <file_id> [--target=en]'));
        process.exit(1);
      }
      
      await translateFile(fileId, targetLang);
      break;
    }
    
    case 'batch': {
      const targetLang = args.find(arg => arg.startsWith('--target='))?.split('=')[1] || 'en-US';
      const fileIds = args.filter(arg => !arg.startsWith('--') && arg !== 'batch');
      
      if (fileIds.length === 0) {
        console.error(chalk.red('❌ Error: at least one file_id is required'));
        console.log(chalk.gray('Usage: npm run translate batch <file_id1> <file_id2> ... [--target=en]'));
        process.exit(1);
      }
      
      await batchTranslate(fileIds, targetLang);
      break;
    }
    
    case 'all': {
      const targetLang = args.find(arg => arg.startsWith('--target='))?.split('=')[1] || 'en-US';
      const pendingFiles = await showPendingTranslations();
      
      if (!pendingFiles || pendingFiles.length === 0) {
        return;
      }
      
      const availableFiles = pendingFiles.filter(file => 
        file.availableTargets.includes(targetLang)
      );
      
      if (availableFiles.length === 0) {
        console.log(chalk.yellow(`⚠️  No files available for translation to ${targetLang}`));
        return;
      }
      
      const fileIds = availableFiles.map(file => file.id);
      await batchTranslate(fileIds, targetLang);
      break;
    }
    
    default:
      console.log(chalk.blue.bold('🌐 Translation Workflow Commands'));
      console.log(chalk.gray('='.repeat(40)));
      console.log(`${chalk.cyan('list|show')}        Show files ready for translation`);
      console.log(`${chalk.cyan('translate <id>')}   Translate specific file`);
      console.log(`${chalk.cyan('batch <id1> <id2>')} Translate multiple files`);
      console.log(`${chalk.cyan('all')}             Translate all ready files`);
      console.log('');
      console.log(chalk.gray('Options:'));
      console.log(`${chalk.gray('--target=<lang>')}  Target language (default: en)`);
      console.log('');
      console.log(chalk.gray('Examples:'));
      console.log(`${chalk.gray('npm run translate list')}`);
      console.log(`${chalk.gray('npm run translate translate 2025-06-28-crypto-news')}`);
      console.log(`${chalk.gray('npm run translate all --target=ja-JP')}`);
      break;
  }
}

if (import.meta.url === `file://${process.argv[1]}`) {
  main().catch(error => {
    console.error(chalk.red('❌ Error:'), error);
    process.exit(1);
  });
}

export { showPendingTranslations, translateFile, batchTranslate };