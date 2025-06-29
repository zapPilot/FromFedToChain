#!/usr/bin/env node

import { ContentManager } from "../lib/core/ContentManager.js";
import chalk from "chalk";

async function debugPipeline() {
  try {
    console.log(chalk.blue("🔍 Debug Pipeline - Checking Files"));

    console.log(chalk.yellow("\n1. Files for translation:"));
    const translationFiles = await ContentManager.getFilesForTranslation();
    console.log(`Found ${translationFiles.length} files`);

    translationFiles.slice(0, 3).forEach((file) => {
      console.log(
        `  - ${file.id}: ${file.data.languages["zh-TW"]?.title || "No title"}`,
      );
      const missing = ContentManager.getMissingTranslations(file.data);
      console.log(`    Missing: ${missing.join(", ")}`);
    });

    console.log(chalk.yellow("\n2. Files for TTS:"));
    const ttsFiles = await ContentManager.getFilesForTTS();
    console.log(`Found ${ttsFiles.length} files`);

    ttsFiles.slice(0, 3).forEach((file) => {
      console.log(`  - ${file.id} (${file.language}): ${file.title}`);
    });

    console.log(chalk.green("\n✅ Debug complete"));
  } catch (error) {
    console.error(chalk.red("❌ Debug failed:"), error.message);
    console.error(error.stack);
  }
}

debugPipeline();
