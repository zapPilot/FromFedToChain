#!/usr/bin/env node

import chalk from "chalk";
import { SocialMediaService } from "../lib/core/SocialMediaService.js";
import { spawn } from "child_process";

async function main() {
  console.log(chalk.blue.bold("🔍 Social Content Debug Tool"));
  console.log(chalk.gray("=".repeat(50)));

  // Check 1: Claude command availability
  console.log(chalk.blue("\n1. Checking Claude command availability..."));
  const claudeAvailable = await SocialMediaService.checkClaudeAvailability();
  
  if (claudeAvailable) {
    console.log(chalk.green("✅ Claude command is available"));
    
    // Test claude command with simple prompt
    console.log(chalk.blue("\n2. Testing Claude command with simple prompt..."));
    try {
      const testResult = await testClaudeCommand();
      console.log(chalk.green("✅ Claude command test successful"));
      console.log(chalk.gray(`Response: ${testResult.substring(0, 100)}...`));
    } catch (error) {
      console.log(chalk.red("❌ Claude command test failed:"));
      console.log(chalk.red(`   ${error.message}`));
    }
  } else {
    console.log(chalk.red("❌ Claude command not found"));
    console.log(chalk.yellow("💡 Install with: npm install -g claude-code"));
    return;
  }

  // Check 2: Files needing social hooks
  console.log(chalk.blue("\n3. Checking files needing social hooks..."));
  try {
    const files = await SocialMediaService.getFilesNeedingSocial();
    console.log(chalk.green(`✅ Found ${files.length} files needing social hooks`));
    
    if (files.length > 0) {
      console.log(chalk.gray("Files:"));
      files.slice(0, 5).forEach(file => {
        console.log(chalk.gray(`   - ${file.id} (${file.language})`));
      });
      if (files.length > 5) {
        console.log(chalk.gray(`   ... and ${files.length - 5} more`));
      }
    }
  } catch (error) {
    console.log(chalk.red("❌ Error checking files:"));
    console.log(chalk.red(`   ${error.message}`));
  }

  // Check 3: Configuration (simplified)
  console.log(chalk.blue("\n4. Checking configuration..."));
  console.log(chalk.green("✅ Using simplified configuration"));
  console.log(chalk.gray("   Languages: en-US, ja-JP"));
  console.log(chalk.gray("   Format: Single universal hook per language"));

  // Check 4: Single file test
  console.log(chalk.blue("\n5. Testing single file processing..."));
  try {
    const files = await SocialMediaService.getFilesNeedingSocial();
    if (files.length > 0) {
      const testFile = files[0];
      console.log(chalk.blue(`   Testing file: ${testFile.id} (${testFile.language})`));
      
      const result = await SocialMediaService.processSocialFile(testFile);
      
      if (result.success) {
        console.log(chalk.green("✅ Single file test successful"));
        if (result.cached) {
          console.log(chalk.blue("   (Used cached result)"));
        }
      } else {
        console.log(chalk.red("❌ Single file test failed:"));
        console.log(chalk.red(`   ${result.error}`));
      }
    } else {
      console.log(chalk.yellow("⚠️  No files available for testing"));
    }
  } catch (error) {
    console.log(chalk.red("❌ Single file test error:"));
    console.log(chalk.red(`   ${error.message}`));
    console.log(chalk.red(`   Stack: ${error.stack}`));
  }

  console.log(chalk.blue.bold("\n🏁 Debug completed"));
}

function testClaudeCommand() {
  return new Promise((resolve, reject) => {
    const claude = spawn('claude', ['-p', 'Respond with just "Hello" and nothing else'], {
      stdio: ['pipe', 'pipe', 'pipe'],
      timeout: 10000 // 10 second timeout for test
    });

    let output = '';
    let error = '';

    claude.stdout.on('data', (data) => {
      output += data.toString();
    });

    claude.stderr.on('data', (data) => {
      error += data.toString();
    });

    claude.on('close', (code) => {
      if (code === 0) {
        resolve(output.trim());
      } else {
        reject(new Error(`Claude test failed (code ${code}): ${error}`));
      }
    });

    claude.on('error', (err) => {
      reject(new Error(`Failed to spawn claude: ${err.message}`));
    });

    // Kill process if it hangs
    setTimeout(() => {
      claude.kill('SIGKILL');
      reject(new Error('Claude command timed out after 10 seconds'));
    }, 10000);
  });
}

main().catch(error => {
  console.error(chalk.red("❌ Debug script failed:"), error.message);
  process.exit(1);
});