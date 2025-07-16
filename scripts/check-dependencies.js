#!/usr/bin/env node

import { spawn } from "child_process";
import chalk from "chalk";
import { M3U8AudioService } from "../src/services/M3U8AudioService.js";
import { CloudflareR2Service } from "../src/services/CloudflareR2Service.js";

class DependencyChecker {
  constructor() {
    this.results = {
      ffmpeg: { status: 'unknown', message: '', path: null },
      rclone: { status: 'unknown', message: '', configured: false },
      nodejs: { status: 'unknown', message: '', version: null },
      npm: { status: 'unknown', message: '', version: null }
    };
  }

  /**
   * Check all dependencies
   */
  async checkAllDependencies() {
    console.log(chalk.blue.bold('🔍 Checking Pipeline Dependencies'));
    console.log(chalk.gray('='.repeat(50)));

    try {
      // Check Node.js
      await this.checkNodeJS();
      
      // Check npm
      await this.checkNpm();
      
      // Check FFmpeg
      await this.checkFFmpeg();
      
      // Check rclone
      await this.checkRclone();
      
      // Generate report
      this.generateReport();
      
    } catch (error) {
      console.error(chalk.red(`❌ Dependency check failed: ${error.message}`));
      process.exit(1);
    }
  }

  /**
   * Check Node.js
   */
  async checkNodeJS() {
    console.log(chalk.blue('\n📦 Checking Node.js...'));
    
    try {
      const result = await this.executeCommand('node', ['--version']);
      if (result.success) {
        this.results.nodejs.status = 'success';
        this.results.nodejs.version = result.output.trim();
        this.results.nodejs.message = `Node.js ${this.results.nodejs.version}`;
        console.log(chalk.green(`✅ Node.js: ${this.results.nodejs.version}`));
      } else {
        this.results.nodejs.status = 'error';
        this.results.nodejs.message = 'Node.js not found';
        console.log(chalk.red(`❌ Node.js not found`));
      }
    } catch (error) {
      this.results.nodejs.status = 'error';
      this.results.nodejs.message = error.message;
      console.log(chalk.red(`❌ Node.js check failed: ${error.message}`));
    }
  }

  /**
   * Check npm
   */
  async checkNpm() {
    console.log(chalk.blue('\n📦 Checking npm...'));
    
    try {
      const result = await this.executeCommand('npm', ['--version']);
      if (result.success) {
        this.results.npm.status = 'success';
        this.results.npm.version = result.output.trim();
        this.results.npm.message = `npm ${this.results.npm.version}`;
        console.log(chalk.green(`✅ npm: ${this.results.npm.version}`));
      } else {
        this.results.npm.status = 'error';
        this.results.npm.message = 'npm not found';
        console.log(chalk.red(`❌ npm not found`));
      }
    } catch (error) {
      this.results.npm.status = 'error';
      this.results.npm.message = error.message;
      console.log(chalk.red(`❌ npm check failed: ${error.message}`));
    }
  }

  /**
   * Check FFmpeg using M3U8AudioService
   */
  async checkFFmpeg() {
    console.log(chalk.blue('\n🎬 Checking FFmpeg...'));
    
    try {
      const ffmpegPath = await M3U8AudioService.detectFFmpegPath();
      if (ffmpegPath) {
        this.results.ffmpeg.status = 'success';
        this.results.ffmpeg.path = ffmpegPath;
        this.results.ffmpeg.message = `FFmpeg found at: ${ffmpegPath}`;
        console.log(chalk.green(`✅ FFmpeg: ${ffmpegPath}`));
      } else {
        this.results.ffmpeg.status = 'error';
        this.results.ffmpeg.message = 'FFmpeg not found';
        console.log(chalk.red(`❌ FFmpeg not found`));
      }
    } catch (error) {
      this.results.ffmpeg.status = 'error';
      this.results.ffmpeg.message = error.message;
      console.log(chalk.red(`❌ FFmpeg check failed: ${error.message}`));
    }
  }

  /**
   * Check rclone using CloudflareR2Service
   */
  async checkRclone() {
    console.log(chalk.blue('\n☁️ Checking rclone...'));
    
    try {
      const rcloneAvailable = await CloudflareR2Service.checkRcloneAvailability();
      if (rcloneAvailable) {
        this.results.rclone.status = 'success';
        this.results.rclone.configured = true;
        this.results.rclone.message = 'rclone available and configured';
        console.log(chalk.green(`✅ rclone: configured and ready`));
      } else {
        this.results.rclone.status = 'warning';
        this.results.rclone.configured = false;
        this.results.rclone.message = 'rclone not configured or not available';
        console.log(chalk.yellow(`⚠️ rclone: not configured or not available`));
      }
    } catch (error) {
      this.results.rclone.status = 'error';
      this.results.rclone.message = error.message;
      console.log(chalk.red(`❌ rclone check failed: ${error.message}`));
    }
  }

  /**
   * Execute a command and return result
   */
  async executeCommand(command, args) {
    return new Promise((resolve) => {
      const process = spawn(command, args);
      let stdout = "";
      let stderr = "";

      process.stdout.on("data", (data) => {
        stdout += data.toString();
      });

      process.stderr.on("data", (data) => {
        stderr += data.toString();
      });

      process.on("close", (code) => {
        resolve({ 
          success: code === 0, 
          output: stdout, 
          error: stderr,
          code 
        });
      });

      process.on("error", (error) => {
        resolve({ 
          success: false, 
          error: error.message,
          code: -1
        });
      });
    });
  }

  /**
   * Generate dependency report
   */
  generateReport() {
    console.log(chalk.blue.bold('\n📊 Dependency Report'));
    console.log(chalk.gray('='.repeat(50)));

    const categories = {
      'Core Runtime': ['nodejs', 'npm'],
      'Media Processing': ['ffmpeg'],
      'Cloud Storage': ['rclone']
    };

    let allSuccess = true;
    let hasWarnings = false;

    Object.entries(categories).forEach(([category, deps]) => {
      console.log(chalk.blue(`\n${category}:`));
      
      deps.forEach(dep => {
        const result = this.results[dep];
        const icon = result.status === 'success' ? '✅' : 
                     result.status === 'warning' ? '⚠️' : '❌';
        const color = result.status === 'success' ? chalk.green : 
                      result.status === 'warning' ? chalk.yellow : chalk.red;
        
        console.log(color(`  ${icon} ${dep}: ${result.message}`));
        
        if (result.status === 'error') {
          allSuccess = false;
        } else if (result.status === 'warning') {
          hasWarnings = true;
        }
      });
    });

    // Final status
    console.log(chalk.blue('\n🎯 Pipeline Status:'));
    
    if (allSuccess && !hasWarnings) {
      console.log(chalk.green('✅ All dependencies are available - pipeline ready!'));
    } else if (allSuccess && hasWarnings) {
      console.log(chalk.yellow('⚠️ Core dependencies available - pipeline will work with limited features'));
      console.log(chalk.yellow('   (Some features like R2 upload may be disabled)'));
    } else {
      console.log(chalk.red('❌ Missing critical dependencies - pipeline may fail'));
      console.log(chalk.yellow('\n💡 Installation instructions:'));
      
      if (this.results.ffmpeg.status === 'error') {
        console.log(chalk.yellow('   FFmpeg: brew install ffmpeg (macOS) or apt install ffmpeg (Ubuntu)'));
      }
      
      if (this.results.rclone.status === 'error') {
        console.log(chalk.yellow('   rclone: curl https://rclone.org/install.sh | sudo bash'));
      }
    }

    // Next steps
    console.log(chalk.blue('\n🚀 Next Steps:'));
    console.log(chalk.cyan('   npm run pipeline              # Run the full pipeline'));
    console.log(chalk.cyan('   npm run pipeline <content-id> # Process specific content'));
    console.log(chalk.cyan('   npm run review                # Review pending content'));
  }
}

// CLI interface
async function main() {
  const args = process.argv.slice(2);
  
  if (args.includes('--help') || args.includes('-h')) {
    console.log(chalk.blue.bold('📖 Dependency Checker'));
    console.log(chalk.gray('='.repeat(50)));
    console.log('Usage: node scripts/check-dependencies.js [options]');
    console.log('');
    console.log('Options:');
    console.log('  --help, -h     Show this help message');
    console.log('');
    console.log('This script checks all dependencies required for the pipeline:');
    console.log('  • Node.js and npm');
    console.log('  • FFmpeg (for M3U8 conversion)');
    console.log('  • rclone (for R2 uploads)');
    return;
  }

  const checker = new DependencyChecker();
  await checker.checkAllDependencies();
}

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
  main().catch(console.error);
}

export { DependencyChecker };