#!/usr/bin/env node

import fs from "fs/promises";
import path from "path";
import chalk from "chalk";
import { execSync } from "child_process";
import { TRANSLATION_CONFIG, CATEGORIES, PATHS, LANGUAGES } from '../config/languages.js';

async function findSourceFile(fileId) {
  const sourcePath = path.join(PATHS.CONTENT_ROOT, LANGUAGES.PRIMARY);
  
  for (const category of CATEGORIES) {
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
  if (translatedTo.includes('en-US')) {
    console.log(chalk.yellow('⚠️  Content already translated to English'));
  }
  
  return data;
}

// Language mapping for translation prompts
const LANGUAGE_NAMES = {
  'en-US': 'English',
  'ja-JP': 'Japanese',
  'zh-TW': 'Traditional Chinese'
};

async function translateContent(sourceData, targetLang = 'en-US') {
  const sourceContent = sourceData.languages[LANGUAGES.PRIMARY];
  const targetLanguageName = LANGUAGE_NAMES[targetLang] || targetLang;
  
  console.log(chalk.blue('🔄 Translating content...'));
  console.log(`📝 Title: ${sourceContent.title}`);
  console.log(`📊 Content length: ${sourceContent.content.length} characters`);
  console.log(`🌐 Target: ${targetLanguageName}`);
  
  try {
    // Create translation prompt for Claude
    const translationPrompt = `Please translate the following Traditional Chinese content to ${targetLanguageName}. 

IMPORTANT INSTRUCTIONS:
- Maintain the conversational style and tone of the original
- Keep the financial/crypto terminology accurate
- Preserve the educational and accessible nature of the content
- Do NOT add any formatting, markdown, or extra text
- Return ONLY the translated content, nothing else

TITLE TO TRANSLATE:
${sourceContent.title}

CONTENT TO TRANSLATE:
${sourceContent.content}

Please provide the translation in this exact format:
TITLE: [translated title]
CONTENT: [translated content]`;

    console.log(chalk.gray('🤖 Calling Claude API for translation...'));
    
    // Use Claude via command line with -p flag
    const claudeCommand = `claude -p ${JSON.stringify(translationPrompt)}`;
    
    let translationResult;
    try {
      translationResult = execSync(claudeCommand, { 
        encoding: 'utf-8',
        timeout: 60000, // 60 second timeout
        maxBuffer: 1024 * 1024 // 1MB buffer
      });
    } catch (claudeError) {
      console.log(chalk.yellow('⚠️  Claude CLI not available, trying gemini...'));
      
      // Fallback to Gemini
      const geminiCommand = `gemini -p ${JSON.stringify(translationPrompt)}`;
      try {
        translationResult = execSync(geminiCommand, {
          encoding: 'utf-8',
          timeout: 60000,
          maxBuffer: 1024 * 1024
        });
      } catch (geminiError) {
        throw new Error('Neither Claude CLI nor Gemini CLI available. Please install claude-cli or gemini-cli.');
      }
    }
    
    console.log(chalk.green('✅ Translation received from AI'));
    
    // Parse the translation result
    const lines = translationResult.trim().split('\n');
    let translatedTitle = '';
    let translatedContent = '';
    let isContent = false;
    
    for (const line of lines) {
      if (line.startsWith('TITLE:')) {
        translatedTitle = line.replace('TITLE:', '').trim();
      } else if (line.startsWith('CONTENT:')) {
        translatedContent = line.replace('CONTENT:', '').trim();
        isContent = true;
      } else if (isContent) {
        translatedContent += '\n' + line;
      }
    }
    
    // Fallback parsing if structured format not found
    if (!translatedTitle || !translatedContent) {
      console.log(chalk.yellow('⚠️  Using fallback parsing...'));
      const fullTranslation = translationResult.trim();
      const parts = fullTranslation.split('\n\n');
      if (parts.length >= 2) {
        translatedTitle = parts[0];
        translatedContent = parts.slice(1).join('\n\n');
      } else {
        translatedTitle = `${sourceContent.title} (${targetLanguageName})`;
        translatedContent = fullTranslation;
      }
    }
    
    // Clean up the content
    translatedTitle = translatedTitle.trim();
    translatedContent = translatedContent.trim();
    
    console.log(chalk.gray(`📝 Translated title: ${translatedTitle.substring(0, 50)}...`));
    console.log(chalk.gray(`📄 Translated content: ${translatedContent.length} characters`));
    
    return {
      title: translatedTitle,
      content: translatedContent
    };
    
  } catch (error) {
    console.error(chalk.red('❌ Translation failed:'), error.message);
    throw new Error(`Translation failed: ${error.message}`);
  }
}

async function createTranslatedFile(sourceData, translatedContent, targetLang, category) {
  const targetPath = path.join(PATHS.CONTENT_ROOT, targetLang, category, `${sourceData.id}.json`);
  
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
        source_language: LANGUAGES.PRIMARY,
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
  const targetLang = args.find(arg => arg.startsWith('--target_lang='))?.split('=')[1] || 'en-US';
  
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