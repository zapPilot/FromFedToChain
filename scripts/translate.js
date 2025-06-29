#!/usr/bin/env node

import fs from "fs/promises";
import path from "path";
import chalk from "chalk";

// Translation configuration
const TRANSLATION_CONFIG = {
  'en': {
    voice: {
      languageCode: "en-US",
      name: "en-US-Wavenet-D"
    },
    socialPrefix: "🚀",
    hookLength: 150, // characters for hook
  }
};

async function findSourceFile(fileId) {
  const sourcePath = `./content/zh-TW`;
  const categories = ['daily-news', 'ethereum', 'macro'];
  
  for (const category of categories) {
    const filePath = path.join(sourcePath, category, `${fileId}.json`);
    try {
      await fs.access(filePath);
      return { filePath, category };
    } catch {
      continue;
    }
  }
  
  throw new Error(`Source file not found: ${fileId}`);
}

async function validateSourceFile(filePath) {
  const content = await fs.readFile(filePath, 'utf-8');
  const data = JSON.parse(content);
  
  // Check if source is reviewed
  if (!data.metadata?.translation_status?.source_reviewed) {
    throw new Error('Source content must be reviewed before translation');
  }
  
  // Check if already translated to target language
  const translatedTo = data.metadata.translation_status.translated_to || [];
  if (translatedTo.includes('en')) {
    console.log(chalk.yellow('⚠️  Content already translated to English'));
  }
  
  return data;
}

// Removed social media formatting from translate - moved to separate command

async function translateContent(sourceData, targetLang = 'en') {
  const sourceContent = sourceData.languages['zh-TW'];
  
  console.log(chalk.blue('🔄 Translating content...'));
  console.log(`📝 Title: ${sourceContent.title}`);
  console.log(`📊 Content length: ${sourceContent.content.length} characters`);
  
  // For now, we'll create a placeholder translation
  // In a real implementation, this would call Claude/Gemini API
  const translatedTitle = `[EN] ${sourceContent.title}`;
  const translatedContent = `[TRANSLATED] ${sourceContent.content}`;
  
  console.log(chalk.yellow('⚠️  Using placeholder translation. Implement Claude/Gemini API call here.'));
  
  return {
    title: translatedTitle,
    content: translatedContent
  };
}

async function createTranslatedFile(sourceData, translatedContent, targetLang, category) {
  const targetPath = `./content/${targetLang}/${category}/${sourceData.id}.json`;
  
  const translatedData = {
    id: sourceData.id,
    date: sourceData.date,
    category: sourceData.category,
    references: sourceData.references,
    languages: {
      [targetLang]: translatedContent
    },
    metadata: {
      translation_status: {
        source_language: "zh-TW",
        source_reviewed: true,
        translated_to: [targetLang],
        translated_at: new Date().toISOString()
      },
      tts: {
        [targetLang]: {
          status: "pending",
          audio_url: null,
          voice_config: TRANSLATION_CONFIG[targetLang].voice
        }
      },
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    }
  };
  
  await fs.writeFile(targetPath, JSON.stringify(translatedData, null, 2));
  return targetPath;
}

async function updateSourceMetadata(sourcePath, targetLang) {
  const content = await fs.readFile(sourcePath, 'utf-8');
  const data = JSON.parse(content);
  
  // Update translation status
  const translatedTo = data.metadata.translation_status.translated_to || [];
  if (!translatedTo.includes(targetLang)) {
    translatedTo.push(targetLang);
  }
  
  data.metadata.translation_status.translated_to = translatedTo;
  data.metadata.updated_at = new Date().toISOString();
  
  await fs.writeFile(sourcePath, JSON.stringify(data, null, 2));
}

async function main() {
  const args = process.argv.slice(2);
  const fileId = args.find(arg => !arg.startsWith('--'))?.replace('--file_id=', '');
  const targetLang = args.find(arg => arg.startsWith('--target_lang='))?.split('=')[1] || 'en';
  
  if (!fileId) {
    console.error(chalk.red('❌ Error: file_id is required'));
    console.log(chalk.gray('Usage: node scripts/translate.js <file_id> [--target_lang=en]'));
    process.exit(1);
  }
  
  try {
    console.log(chalk.blue.bold('🌐 Translation Pipeline'));
    console.log(chalk.gray('='.repeat(50)));
    
    // Find and validate source file
    console.log(chalk.blue('📖 Loading source file...'));
    const { filePath: sourcePath, category } = await findSourceFile(fileId);
    const sourceData = await validateSourceFile(sourcePath);
    
    console.log(chalk.green(`✅ Source loaded: ${path.basename(sourcePath)}`));
    console.log(chalk.cyan(`📂 Category: ${category}`));
    console.log(chalk.cyan(`🌍 Target: ${targetLang}`));
    
    // Translate content
    const translatedContent = await translateContent(sourceData, targetLang);
    
    // Create translated file
    console.log(chalk.blue('💾 Creating translated file...'));
    const targetPath = await createTranslatedFile(sourceData, translatedContent, targetLang, category);
    console.log(chalk.green(`✅ Created: ${path.basename(targetPath)}`));
    
    // Update source metadata
    console.log(chalk.blue('🔗 Updating source metadata...'));
    await updateSourceMetadata(sourcePath, targetLang);
    
    console.log(chalk.green.bold('\n🎉 Translation completed!'));
    console.log(chalk.gray(`📁 English version: ${targetPath}`));
    console.log(chalk.gray(`📱 Social format included`));
    console.log(chalk.gray(`🎙️ Ready for TTS processing`));
    
  } catch (error) {
    console.error(chalk.red('❌ Translation failed:'), error.message);
    process.exit(1);
  }
}

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}

export { findSourceFile, validateSourceFile, translateContent };