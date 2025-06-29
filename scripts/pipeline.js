#!/usr/bin/env node

import { ContentPipeline } from '../lib/workflows/ContentPipeline.js';
import chalk from 'chalk';

const args = process.argv.slice(2);
const command = args.find(arg => !arg.startsWith('--')) || 'run';

async function main() {
  const useMock = args.includes('--mock');
  const useGCP = args.includes('--gcp');
  
  // Default behavior: use mock unless --gcp is specified
  const useMockTranslation = useGCP ? false : (useMock ? true : true);
  
  const pipeline = new ContentPipeline({ useMockTranslation });
  
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
        console.log(chalk.cyan('npm run pipeline') + chalk.gray(' - Run full pipeline (mock translation by default)'));
        console.log(chalk.cyan('npm run pipeline:mock') + chalk.gray(' - Run with mock translation (for testing)'));
        console.log(chalk.cyan('npm run pipeline:gcp') + chalk.gray(' - Run with Google Cloud Translation API'));
        console.log(chalk.cyan('npm run pipeline:retry') + chalk.gray(' - Retry all failed tasks'));
        console.log(chalk.cyan('npm run pipeline:status') + chalk.gray(' - Show pipeline status'));
        console.log(chalk.cyan('npm run pipeline:reset') + chalk.gray(' - Reset pipeline state'));
        console.log('');
        console.log(chalk.yellow('💡 Use Ctrl+C to safely interrupt and resume later'));
        console.log(chalk.yellow('💡 Enable GCP Translation API to use real translation'));
        break;
    }
  } catch (error) {
    console.error(chalk.red('❌ Pipeline error:'), error.message);
    process.exit(1);
  }
}

main();