#!/usr/bin/env node

import fs from "fs/promises";
import path from "path";
import chalk from "chalk";

// Function to find JSON files with pending TTS status
async function findPendingJSONContent() {
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
          
          // Check if file has pending TTS status
          if (data.metadata && data.metadata.tts_status === 'pending') {
            pendingFiles.push({
              path: fullPath,
              data
            });
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

// Function to display content for review
function displayContentForReview(data) {
  console.log(chalk.blue.bold('\n📄 文章內容預覽'));
  console.log(chalk.gray('='.repeat(50)));
  
  console.log(chalk.green.bold(`標題: ${data.title}`));
  console.log(chalk.cyan(`日期: ${data.date}`));
  console.log(chalk.magenta(`類別: ${data.metadata.category}`));
  
  if (data.references && data.references.length > 0) {
    console.log(chalk.yellow(`參考資料: ${data.references.join(', ')}`));
  }
  
  console.log(chalk.gray('\n--- 內容 (將被 TTS 處理) ---'));
  console.log(data.content);
  
  console.log(chalk.gray('\n--- TTS 狀態 ---'));
  console.log(`狀態: ${data.metadata.tts_status}`);
  console.log(`音頻 URL: ${data.metadata.audio_url || '尚未生成'}`);
  
  console.log(chalk.gray('='.repeat(50)));
}

async function main() {
  try {
    console.log(chalk.blue.bold('🔍 掃描待審核的 JSON 內容...'));
    
    const pendingFiles = await findPendingJSONContent();
    
    if (pendingFiles.length === 0) {
      console.log(chalk.green('✅ 沒有找到待審核的內容。'));
      return;
    }
    
    console.log(chalk.yellow(`📝 找到 ${pendingFiles.length} 個待審核的文件：`));
    
    for (let i = 0; i < pendingFiles.length; i++) {
      const file = pendingFiles[i];
      
      console.log(chalk.blue.bold(`\n[${i + 1}/${pendingFiles.length}] 審核文件: ${path.basename(file.path)}`));
      displayContentForReview(file.data);
      
      // If there are more files, ask if user wants to continue
      if (i < pendingFiles.length - 1) {
        console.log(chalk.gray('\n按 Enter 繼續查看下一個文件...'));
        // In a real scenario, you might want to add readline for user input
      }
    }
    
    console.log(chalk.green.bold('\n🎉 所有內容審核完畢！'));
    console.log(chalk.gray('如需修改內容，請直接編輯對應的 JSON 文件。'));
    console.log(chalk.gray('確認無誤後，可執行 TTS 腳本進行語音轉換。'));
    
  } catch (error) {
    console.error(chalk.red('❌ 錯誤:'), error);
    process.exit(1);
  }
}

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}

export { findPendingJSONContent, displayContentForReview };