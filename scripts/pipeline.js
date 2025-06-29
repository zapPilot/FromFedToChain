#!/usr/bin/env node

import { ContentPipeline } from '../lib/workflows/ContentPipeline.js';
import chalk from 'chalk';

const args = process.argv.slice(2);
const command = args[0] || 'run';

async function main() {
  const pipeline = new ContentPipeline();
  
  try {
    switch (command) {
      case 'run':
        await pipeline.runFullPipeline();
        break;
        
      case 'retry':
        const step = args[1]; // Optional step to retry
        await pipeline.retryFailed(step);
        break;
        
      case 'status':
        await pipeline.status();
        break;
        
      case 'reset':
        await pipeline.reset();
        break;
        
      default:
        console.log(chalk.blue.bold('📋 Content Pipeline Commands:'));
        console.log(chalk.gray('='.repeat(40)));
        console.log(chalk.cyan('npm run pipeline') + chalk.gray(' - Run full pipeline (translate → tts → social)'));
        console.log(chalk.cyan('npm run pipeline retry') + chalk.gray(' - Retry all failed tasks'));
        console.log(chalk.cyan('npm run pipeline retry translate') + chalk.gray(' - Retry specific step'));
        console.log(chalk.cyan('npm run pipeline status') + chalk.gray(' - Show pipeline status'));
        console.log(chalk.cyan('npm run pipeline reset') + chalk.gray(' - Reset pipeline state'));
        console.log('');
        console.log(chalk.yellow('💡 Use Ctrl+C to safely interrupt and resume later'));
        break;
    }
  } catch (error) {
    console.error(chalk.red('❌ Pipeline error:'), error.message);
    process.exit(1);
  }
}

main();