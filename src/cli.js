#!/usr/bin/env node

import fs from "fs/promises";
import chalk from "chalk";
import { ContentManager } from "./ContentManager.js";
import { TranslationService } from "./services/TranslationService.js";
import { AudioService } from "./services/AudioService.js";
import { SocialService } from "./services/SocialService.js";

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

  // Get all source content that needs review
  const contents = await ContentManager.getSourceByStatus("draft");
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
      console.log(chalk.blue("2️⃣ Audio generation..."));
      await AudioService.generateAllAudio(id);
    }

    // Check updated status for next phase
    const audioContent = await ContentManager.readSource(id);
    if (audioContent.status === 'audio') {
      console.log(chalk.blue("3️⃣ Social hooks..."));
      await SocialService.generateAllHooks(id);
    }

    // Pipeline complete - content now has social hooks and is ready for manual publishing

    console.log(chalk.green(`✅ Pipeline completed for: ${id}`));

  } catch (error) {
    console.error(chalk.red(`❌ Pipeline failed for ${id}: ${error.message}`));
  }
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
}

main();
