#!/usr/bin/env node

import { ReviewService } from "../lib/core/ReviewService.js";
import chalk from "chalk";

async function main() {
  try {
    console.log(chalk.blue.bold("📖 Content Review"));
    console.log(chalk.gray("=".repeat(50)));
    
    await ReviewService.reviewPendingContent();
    
  } catch (error) {
    console.error(chalk.red("❌ Review failed:"), error.message);
    process.exit(1);
  }
}

main();