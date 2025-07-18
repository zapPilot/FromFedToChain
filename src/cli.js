#!/usr/bin/env node

import fs from "fs/promises";
import path from "path";
import { exec } from "child_process";
import chalk from "chalk";
import { ContentManager } from "./ContentManager.js";
import { TranslationService } from "./services/TranslationService.js";
import { AudioService } from "./services/AudioService.js";
import { SocialService } from "./services/SocialService.js";
import { M3U8AudioService } from "./services/M3U8AudioService.js";
import { CloudflareR2Service } from "./services/CloudflareR2Service.js";

const args = process.argv.slice(2);
const command = args[0];

async function main() {
  console.log(chalk.blue.bold("🚀 From Fed to Chain - Content Pipeline"));
  console.log(chalk.gray("=".repeat(50)));

  try {
    switch (command) {
      case "review":
        await handleReview();
        break;
      case 'pipeline':
        await handlePipeline();
        break;
      default:
        showHelp();
    }
  } catch (error) {
    console.error(chalk.red("❌ Error:"), error.message);
    process.exit(1);
  }
}

async function handleReview() {
  console.log(chalk.blue.bold("📖 Interactive Content Review"));
  console.log(chalk.gray("=".repeat(50)));

  // Get all source content that needs review (excludes rejected content)
  const contents = await ContentManager.getSourceForReview();
  if (contents.length === 0) {
    console.log(chalk.green("✅ No content pending review"));
    return;
  }

  console.log(chalk.blue(`Found ${contents.length} items needing review\n`));

  for (let i = 0; i < contents.length; i++) {
    const content = contents[i];

    console.log(
      chalk.yellow(`📄 Reviewing [${i + 1}/${contents.length}]: ${content.id}`),
    );
    console.log(chalk.gray("=".repeat(60)));
    console.log(chalk.cyan(`Title: ${content.title}`));
    console.log(
      chalk.cyan(`Category: ${content.category} | Date: ${content.date}`),
    );
    console.log(chalk.cyan(`Language: ${content.language}`));
    console.log("");
    console.log(chalk.white("Content:"));
    console.log(content.content);
    console.log("");

    // Get user decision
    let action, feedback;
    while (true) {
      console.log(chalk.blue("Decision: [a]ccept, [r]eject, [s]kip, [q]uit"));
      process.stdout.write("❯ ");

      try {
        const input = await getUserInput();
        const parts = input.trim().split(" ", 2);
        const decision = parts[0].toLowerCase();
        feedback = parts.slice(1).join(" ");

        if (decision === "a" || decision === "accept") {
          action = "accept";
          if (!feedback) {
            process.stdout.write("Feedback (optional): ");
            feedback = await getUserInput();
          }
          break;
        } else if (decision === "r" || decision === "reject") {
          action = "reject";
          if (!feedback) {
            process.stdout.write("Feedback (required for rejection): ");
            feedback = await getUserInput();
          }
          break;
        } else if (decision === "s" || decision === "skip") {
          console.log(chalk.yellow("⏭️ Skipped\n"));
          action = null;
          break;
        } else if (decision === "q" || decision === "quit") {
          console.log(chalk.gray("Review session ended"));
          return;
        } else {
          console.log(
            chalk.red(
              "Invalid option. Use: a/accept, r/reject, s/skip, q/quit",
            ),
          );
          continue;
        }
      } catch (error) {
        console.log(chalk.red(`\n❌ Error getting input: ${error.message}`));
        return;
      }
    }

    // Process decision
    if (action === "accept") {
      try {
        await ContentManager.addContentFeedback(
          content.id,
          "accepted",
          4,
          "reviewer_cli",
          feedback || "Approved for translation",
        );
        await ContentManager.updateSourceStatus(content.id, "reviewed");
        console.log(chalk.green(`✅ Accepted: ${content.id}`));
        if (feedback) {
          console.log(chalk.gray(`📝 Feedback: ${feedback}`));
        }
      } catch (error) {
        console.log(chalk.red(`❌ Failed to accept: ${error.message}`));
      }
    } else if (action === "reject") {
      try {
        await ContentManager.addContentFeedback(
          content.id,
          "rejected",
          2,
          "reviewer_cli",
          feedback,
        );
        // Keep as draft for revision
        console.log(chalk.red(`❌ Rejected: ${content.id}`));
        console.log(chalk.yellow(`📝 Feedback: ${feedback}`));
      } catch (error) {
        console.log(chalk.red(`❌ Failed to reject: ${error.message}`));
      }
    }

    console.log(""); // Add spacing between reviews
  }

  console.log(chalk.green.bold("🎉 Review session completed!"));
}

// Helper function to get user input
function getUserInput() {
  return new Promise((resolve, reject) => {
    const timeout = setTimeout(() => {
      reject(new Error("Input timeout"));
    }, 300000); // 5 minute timeout

    process.stdin.once("readable", () => {
      clearTimeout(timeout);
      const chunk = process.stdin.read();
      if (chunk !== null) {
        resolve(chunk.toString().trim());
      } else {
        reject(new Error("No input received"));
      }
    });

    process.stdin.once("error", (error) => {
      clearTimeout(timeout);
      reject(error);
    });
  });
}

async function handlePipeline() {
  const id = args[1];

  console.log(chalk.blue.bold("🔄 Running Smart Pipeline"));
  console.log(chalk.gray("Automatically detects and processes unfinished phases"));
  console.log(chalk.gray("=".repeat(50)));

  if (id) {
    // Run pipeline for specific content
    await runPipelineForContent(id);
  } else {
    // Check all phases and find content that needs processing
    const allPendingContent = await getAllPendingContent();
    
    if (allPendingContent.length === 0) {
      console.log(chalk.green("✅ No content needs processing"));
      console.log(chalk.gray("💡 Use 'npm run review' to approve new content"));
      return;
    }

    // Show what was found
    console.log(chalk.blue(`Found ${allPendingContent.length} content items needing processing:`));
    showPipelineStatus(allPendingContent);
    console.log("");

    // Process each content item
    for (const item of allPendingContent) {
      console.log(chalk.cyan(`\n🔄 Processing: ${item.content.id} (needs ${item.nextPhase})`));
      await runPipelineForContent(item.content.id);
    }
  }

  console.log(chalk.green.bold("\n🎉 Pipeline completed!"));
}

// Get all content that needs processing at any phase
async function getAllPendingContent() {
  const pendingContent = [];

  // Phase 1: Translation (reviewed → translated)
  const needTranslation = await TranslationService.getContentNeedingTranslation();
  needTranslation.forEach(content => {
    pendingContent.push({ content, nextPhase: 'translation', currentStatus: 'reviewed' });
  });

  // Phase 2: Audio (translated → audio)  
  const needAudio = await AudioService.getContentNeedingAudio();
  needAudio.forEach(content => {
    pendingContent.push({ content, nextPhase: 'audio', currentStatus: 'translated' });
  });

  // Phase 3: Social hooks (audio → social)
  const needSocial = await SocialService.getContentNeedingSocial();
  needSocial.forEach(content => {
    pendingContent.push({ content, nextPhase: 'social', currentStatus: 'audio' });
  });


  // Sort by date (newest first)
  return pendingContent.sort((a, b) => new Date(b.content.date) - new Date(a.content.date));
}

// Show pipeline status summary
function showPipelineStatus(pendingContent) {
  const phaseGroups = {};
  pendingContent.forEach(item => {
    if (!phaseGroups[item.nextPhase]) {
      phaseGroups[item.nextPhase] = [];
    }
    phaseGroups[item.nextPhase].push(item);
  });

  Object.entries(phaseGroups).forEach(([phase, items]) => {
    const phaseColor = {
      'translation': chalk.cyan,
      'audio': chalk.green,
      'social': chalk.magenta
    }[phase] || chalk.white;
    
    console.log(phaseColor(`📋 ${phase.toUpperCase()}: ${items.length} items`));
    items.forEach(item => {
      console.log(chalk.gray(`   • ${item.content.id}: ${item.content.title.substring(0, 50)}...`));
    });
  });
}




async function runPipelineForContent(id) {
  try {
    // Determine what phase this content needs
    const sourceContent = await ContentManager.readSource(id);
    const currentStatus = sourceContent.status;
    
    console.log(chalk.gray(`Current status: ${currentStatus}`));

    // Run appropriate phases based on current status
    if (currentStatus === 'reviewed') {
      console.log(chalk.blue("1️⃣ Translation..."));
      await TranslationService.translateAll(id);
    }

    // Check updated status for next phase
    const updatedContent = await ContentManager.readSource(id);
    if (updatedContent.status === 'translated') {
      console.log(chalk.blue("2️⃣ WAV generation..."));
      await generateWavStep(id);
    }
    if (updatedContent.status === 'wav') {
      console.log(chalk.blue("3️⃣ M3U8 conversion..."));
      await generateM3U8Step(id);
    }
    if (updatedContent.status === 'm3u8') {
      console.log(chalk.blue("4️⃣ Cloudflare upload..."));
      await uploadToCloudflareStep(id);
    }

    // Check updated status for next phase
    const audioContent = await ContentManager.readSource(id);
    if (audioContent.status === 'cloudflare') {
      console.log(chalk.blue("5️⃣ Content upload..."));
      await uploadContentToCloudflareStep(id);
    }
    
    // Check updated status for social hooks
    const contentContent = await ContentManager.readSource(id);
    if (contentContent.status === 'content') {
      console.log(chalk.blue("6️⃣ Social hooks..."));
      await SocialService.generateAllHooks(id);
    }

    // Pipeline complete - content now has social hooks and is ready for manual publishing

    console.log(chalk.green(`✅ Pipeline completed for: ${id}`));

  } catch (error) {
    console.error(chalk.red(`❌ Pipeline failed for ${id}: ${error.message}`));
  }
}

// Separate step functions for modular audio processing

async function generateWavStep(id) {
  console.log(chalk.blue(`🎙️ Generating WAV audio for: ${id}`));
  
  // Check source status
  const sourceContent = await ContentManager.readSource(id);
  if (sourceContent.status !== 'translated') {
    throw new Error(`Content must be translated before WAV generation. Current status: ${sourceContent.status}`);
  }

  // Generate WAV files using AudioService but only the WAV part
  const result = await AudioService.generateWavOnly(id);
  
  console.log(chalk.green(`✅ WAV files generated for all languages`));
  return result;
}

async function generateM3U8Step(id) {
  console.log(chalk.blue(`🎬 Converting to M3U8 for: ${id}`));
  
  // Get available languages for this content
  const availableLanguages = await ContentManager.getAvailableLanguages(id);
  
  // Import language configuration
  const { getAudioLanguages, shouldGenerateM3U8, getM3U8Config } = await import("../config/languages.js");
  
  const audioLanguages = getAudioLanguages();
  const targetLanguages = availableLanguages.filter(lang => 
    audioLanguages.includes(lang) && shouldGenerateM3U8(lang)
  );

  if (targetLanguages.length === 0) {
    console.log(chalk.yellow(`⚠️ No languages configured for M3U8 conversion`));
    return;
  }

  console.log(chalk.blue(`📝 Converting M3U8 for ${targetLanguages.length} languages: ${targetLanguages.join(', ')}`));

  const results = {};
  
  for (const language of targetLanguages) {
    try {
      const content = await ContentManager.read(id, language);
      const audioPath = content.audio_file;
      
      if (!audioPath) {
        throw new Error(`No audio file found for ${language}`);
      }

      const m3u8Config = getM3U8Config(language);
      const m3u8Result = await M3U8AudioService.convertToM3U8(
        audioPath,
        id,
        language,
        content.category,
        m3u8Config
      );
      
      results[language] = { success: true, m3u8Result };
      console.log(chalk.green(`✅ M3U8 converted for ${language}`));
    } catch (error) {
      console.error(chalk.red(`❌ M3U8 conversion failed for ${language}: ${error.message}`));
      results[language] = { success: false, error: error.message };
    }
  }

  return results;
}

async function uploadToCloudflareStep(id) {
  console.log(chalk.blue(`☁️ Uploading to Cloudflare R2 for: ${id}`));
  
  // Check if rclone is available
  const rcloneAvailable = await CloudflareR2Service.checkRcloneAvailability();
  if (!rcloneAvailable) {
    throw new Error("rclone not available. Please install and configure rclone for Cloudflare R2.");
  }

  // Get available languages for this content
  const availableLanguages = await ContentManager.getAvailableLanguages(id);
  
  // Import language configuration
  const { getAudioLanguages, shouldUploadToR2 } = await import("../config/languages.js");
  
  const audioLanguages = getAudioLanguages();
  const targetLanguages = availableLanguages.filter(lang => 
    audioLanguages.includes(lang) && shouldUploadToR2(lang)
  );

  if (targetLanguages.length === 0) {
    console.log(chalk.yellow(`⚠️ No languages configured for R2 upload`));
    return;
  }

  console.log(chalk.blue(`📤 Uploading to R2 for ${targetLanguages.length} languages: ${targetLanguages.join(', ')}`));

  const results = {};
  
  for (const language of targetLanguages) {
    try {
      const content = await ContentManager.read(id, language);
      
      // Get M3U8 files for this content
      const m3u8Info = await M3U8AudioService.getM3U8Files(id, language, content.category);
      
      if (!m3u8Info) {
        throw new Error(`No M3U8 files found for ${language}. Run M3U8 conversion first.`);
      }

      // Upload only M3U8 files (no WAV files)
      const uploadFiles = {
        m3u8Data: m3u8Info
      };
      
      const uploadResult = await CloudflareR2Service.uploadAudioFiles(
        id,
        language,
        content.category,
        uploadFiles
      );
      
      if (uploadResult.success) {
        // Update content with streaming URLs
        await ContentManager.addAudio(id, language, content.audio_file, uploadResult.urls);
        results[language] = { success: true, urls: uploadResult.urls };
        console.log(chalk.green(`✅ R2 upload completed for ${language}`));
      } else {
        throw new Error(uploadResult.errors.join(', '));
      }
    } catch (error) {
      console.error(chalk.red(`❌ R2 upload failed for ${language}: ${error.message}`));
      results[language] = { success: false, error: error.message };
    }
  }

  // Update source status to 'cloudflare' if all uploads successful
  const allSuccessful = Object.values(results).every(r => r.success);
  if (allSuccessful && targetLanguages.length > 0) {
    await ContentManager.updateSourceStatus(id, 'cloudflare');
  }

  return results;
}

// Find all language/category versions of content
async function findContentFiles(id) {
  const contentFiles = [];
  const contentDir = 'content';
  
  try {
    const languages = await fs.readdir(contentDir);
    
    for (const lang of languages) {
      const langPath = path.join(contentDir, lang);
      const langStat = await fs.stat(langPath);
      if (!langStat.isDirectory()) continue;
      
      const categories = await fs.readdir(langPath);
      
      for (const category of categories) {
        const categoryPath = path.join(langPath, category);
        const categoryStat = await fs.stat(categoryPath);
        if (!categoryStat.isDirectory()) continue;
        
        const articlePath = path.join(categoryPath, `${id}.json`);
        
        try {
          await fs.access(articlePath);
          contentFiles.push({
            localPath: articlePath,
            r2Key: `content/${lang}/${category}/${id}.json`,
            language: lang,
            category: category,
            id: id
          });
        } catch (error) {
          // File doesn't exist in this language/category combination
        }
      }
    }
    
  } catch (error) {
    console.error('Error finding content files:', error);
  }
  
  return contentFiles;
}

// Upload single content file
async function uploadSingleContentFile(contentFile) {
  const { localPath, r2Key, language, category } = contentFile;
  
  console.log(chalk.gray(`Uploading: ${localPath} → r2:${process.env.R2_BUCKET_NAME}/${r2Key}`));
  
  const uploadCommand = `rclone copyto "${localPath}" "r2:${process.env.R2_BUCKET_NAME}/${r2Key}"`;
  
  try {
    await execAsync(uploadCommand);
    console.log(chalk.green(`✅ Uploaded: ${language}/${category}/${contentFile.id}.json`));
  } catch (error) {
    console.error(chalk.red(`❌ Upload failed: ${language}/${category}/${contentFile.id}.json - ${error.message}`));
    throw error;
  }
}

// Upload content files to Cloudflare R2
async function uploadContentToCloudflareStep(id) {
  console.log(chalk.blue(`📄 Uploading content to Cloudflare R2: ${id}`));
  
  try {
    // Find all language versions of this content
    const contentFiles = await findContentFiles(id);
    
    if (contentFiles.length === 0) {
      throw new Error(`No content files found for: ${id}`);
    }
    
    console.log(chalk.blue(`Found ${contentFiles.length} content file(s) to upload`));
    
    // Upload each language version
    for (const contentFile of contentFiles) {
      await uploadSingleContentFile(contentFile);
    }
    
    console.log(chalk.green(`✅ Content uploaded successfully: ${contentFiles.length} files`));
    await ContentManager.updateSourceStatus(id, 'content');
    
  } catch (error) {
    console.error(chalk.red(`❌ Content upload failed: ${error.message}`));
    throw error;
  }
}

// Helper function for executing shell commands
function execAsync(command) {
  return new Promise((resolve, reject) => {
    exec(command, (error, stdout, stderr) => {
      if (error) {
        reject(error);
      } else {
        resolve(stdout);
      }
    });
  });
}









function showHelp() {
  console.log(chalk.blue.bold("📖 From Fed to Chain CLI"));
  console.log(chalk.gray("=".repeat(50)));
  console.log(chalk.cyan("Streamlined Workflow:"));
  console.log("  npm run review                                 - Interactive review of draft content");
  console.log("  npm run pipeline                               - Process content through translation → audio → social");
      
  console.log(chalk.gray("\nWorkflow Steps:"));
  console.log("  1️⃣ Create content files in content/zh-TW/");
  console.log("  2️⃣ npm run review        - Review and approve content");
  console.log("  3️⃣ npm run pipeline      - Auto-process: translate → audio → social hooks");
  console.log("  4️⃣ Manual publishing     - Content ready for distribution");
  
  console.log(chalk.gray("\nPipeline Examples:"));
  console.log("  npm run pipeline                               - Process all unfinished content");
  console.log("  npm run pipeline 2025-06-30-bitcoin           - Process specific content");
  
  
  console.log("");
  console.log(chalk.yellow("Review Controls:"));
  console.log("  [a]ccept    - Approve content (optional feedback)");
  console.log("  [r]eject    - Reject with required feedback");
  console.log("  [s]kip      - Skip this content");
  console.log("  [q]uit      - Exit review session");
  console.log("");
  console.log(chalk.gray("Smart Pipeline Features:"));
  console.log("  • Auto-detects content phase: reviewed → translated → audio → social");
  console.log("  • Resumes from where you left off");
  console.log("  • Processes multiple content items in one command");
  console.log("  • Discrete audio steps for testing and debugging");
}

main();
