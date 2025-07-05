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
<<<<<<< HEAD
=======
      case 'pipeline':
        await handlePipeline();
        break;
      case 'translate':
        await handleTranslate();
        break;
      case 'audio':
        await handleAudio();
        break;
      case 'social':
        await handleSocial();
        break;
      case 'analytics':
        await handleAnalytics();
        break;
      case 'export-training':
        await handleExportTraining();
        break;
      case 'list':
        await handleList();
        break;
      case 'status':
        await handleStatus();
        break;
>>>>>>> parent of d1b51ba (refactor: simplified)
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

<<<<<<< HEAD
=======
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



async function handleTranslate() {
  const id = args[1];
  const language = args[2];
  
  if (id && language) {
    await TranslationService.translate(id, language);
  } else if (id) {
    console.log(chalk.blue(`🌐 Translating ${id} to all languages...`));
    await TranslationService.translateAll(id);
  } else {
    const contents = await TranslationService.getContentNeedingTranslation();
    if (contents.length === 0) {
      console.log(chalk.green("✅ No content needs translation"));
      return;
    }
    
    console.log(chalk.blue(`📋 Content Ready for Translation (${contents.length})`));
    contents.forEach(content => {
      console.log(chalk.yellow(`📄 ${content.id}: ${content.title}`));
    });
    
    console.log(chalk.gray("\n💡 Usage:"));
    console.log(chalk.gray("  npm run translate <id>           - Translate specific content"));
    console.log(chalk.gray("  npm run translate <id> en-US     - Translate to specific language"));
  }
}

async function handleAudio() {
  const id = args[1];
  const language = args[2];
  
  if (id && language) {
    await AudioService.generateAudio(id, language);
  } else if (id) {
    console.log(chalk.blue(`🎙️ Generating audio for ${id}...`));
    await AudioService.generateAllAudio(id);
  } else if (args[1] === 'list') {
    const audioFiles = await AudioService.listAudioFiles();
    if (audioFiles.length === 0) {
      console.log(chalk.yellow("No audio files found"));
      return;
    }
    
    console.log(chalk.blue(`🎵 Audio Files (${audioFiles.length})`));
    console.log(chalk.gray("-".repeat(80)));
    console.log(
      chalk.cyan("ID".padEnd(30)) +
      chalk.cyan("Language".padEnd(10)) +
      chalk.cyan("Size".padEnd(10)) +
      chalk.cyan("Created".padEnd(12))
    );
    console.log(chalk.gray("-".repeat(80)));
    
    audioFiles.forEach(audio => {
      console.log(
        audio.id.padEnd(30) +
        audio.language.padEnd(10) +
        audio.size.padEnd(10) +
        audio.created.padEnd(12)
      );
    });
  } else {
    const contents = await AudioService.getContentNeedingAudio();
    if (contents.length === 0) {
      console.log(chalk.green("✅ No content needs audio generation"));
      return;
    }
    
    console.log(chalk.blue(`📋 Content Ready for Audio (${contents.length})`));
    contents.forEach(content => {
      console.log(chalk.yellow(`🎙️ ${content.id}: ${content.title}`));
    });
  }
}

async function handleSocial() {
  const id = args[1];
  const language = args[2];
  
  if (id && language) {
    await SocialService.generateHook(id, language);
  } else if (id) {
    console.log(chalk.blue(`📱 Generating social hooks for ${id}...`));
    await SocialService.generateAllHooks(id);
  } else {
    const contents = await SocialService.getContentNeedingSocial();
    if (contents.length === 0) {
      console.log(chalk.green("✅ No content needs social hook generation"));
      return;
    }
    
    console.log(chalk.blue(`📋 Content Ready for Social Hooks (${contents.length})`));
    contents.forEach(content => {
      console.log(chalk.yellow(`📱 ${content.id}: ${content.title}`));
    });
  }
}


async function handleList() {
  const status = args[1];
  const contents = await ContentManager.list(status);
  
  if (contents.length === 0) {
    console.log(chalk.yellow(`No content found${status ? ` with status: ${status}` : ''}`));
    return;
  }

  console.log(chalk.blue(`📋 Content List${status ? ` (${status})` : ''}`));
  console.log(chalk.gray("-".repeat(100)));
  
  console.log(
    chalk.cyan("ID".padEnd(25)) +
    chalk.cyan("Lang".padEnd(6)) +
    chalk.cyan("Status".padEnd(12)) +
    chalk.cyan("Category".padEnd(12)) +
    chalk.cyan("Date".padEnd(12)) +
    chalk.cyan("Audio".padEnd(6)) +
    chalk.cyan("Social".padEnd(7)) +
    chalk.cyan("Feedback".padEnd(9))
  );
  
  console.log(chalk.gray("-".repeat(100)));
  
  contents.forEach(content => {
    const summary = ContentManager.formatSummary(content);
    const statusColor = getStatusColor(summary.status);
    
    console.log(
      summary.id.padEnd(25) +
      summary.language.padEnd(6) +
      statusColor(summary.status.padEnd(12)) +
      summary.category.padEnd(12) +
      summary.date.padEnd(12) +
      String(summary.audio).padEnd(6) +
      String(summary.social).padEnd(7) +
      String(summary.feedback).padEnd(9)
    );
  });
}

async function handleAnalytics() {
  console.log(chalk.blue("📊 Content Analytics"));
  console.log(chalk.gray("=".repeat(50)));

  const contents = await ContentManager.list();
  const feedbackStats = {
    total_content: contents.length,
    with_feedback: 0,
    accepted: 0,
    rejected: 0
  };

  contents.forEach(content => {
    if (content.feedback?.content_review) {
      feedbackStats.with_feedback++;
      if (content.feedback.content_review.status === 'accepted') {
        feedbackStats.accepted++;
      } else if (content.feedback.content_review.status === 'rejected') {
        feedbackStats.rejected++;
      }
    }
  });

  console.log(chalk.cyan(`📋 Total Content: ${feedbackStats.total_content}`));
  console.log(chalk.cyan(`📝 With Feedback: ${feedbackStats.with_feedback}`));
  console.log(chalk.green(`✅ Accepted: ${feedbackStats.accepted}`));
  console.log(chalk.red(`❌ Rejected: ${feedbackStats.rejected}`));

  console.log(chalk.gray("\n💡 Use 'npm run export-training' to export training data"));
}

async function handleExportTraining() {
  console.log(chalk.blue("📤 Exporting Training Data"));
  console.log(chalk.gray("=".repeat(50)));

  const trainingData = await ContentManager.exportTrainingData();
  
  const filename = `training-data-${new Date().toISOString().split('T')[0]}.json`;
  await fs.writeFile(filename, JSON.stringify(trainingData, null, 2));
  
  console.log(chalk.green(`✅ Training data exported: ${filename}`));
  console.log(chalk.cyan(`📊 Total samples: ${trainingData.training_samples.length}`));
  
  const taskBreakdown = {};
  trainingData.training_samples.forEach(sample => {
    const task = sample.input.task;
    taskBreakdown[task] = (taskBreakdown[task] || 0) + 1;
  });
  
  console.log(chalk.gray("\n📋 Breakdown by task:"));
  Object.entries(taskBreakdown).forEach(([task, count]) => {
    console.log(chalk.gray(`  ${task}: ${count} samples`));
  });
}
>>>>>>> parent of d1b51ba (refactor: simplified)

async function handleStatus() {
  console.log(chalk.blue("📊 Pipeline Status"));
  console.log(chalk.gray("=".repeat(50)));
  
  const statuses = ['draft', 'reviewed', 'translated', 'audio', 'social', 'published'];
  
  for (const status of statuses) {
    const contents = await ContentManager.getSourceByStatus(status);
    const statusColor = getStatusColor(status);
    console.log(statusColor(`${status.toUpperCase().padEnd(12)}: ${contents.length} items (source)`));
  }
  
  console.log(chalk.gray("\n💡 Next steps:"));
  const drafts = await ContentManager.getSourceByStatus('draft');
  const reviewed = await ContentManager.getSourceByStatus('reviewed');
  
  if (drafts.length > 0) {
    console.log(chalk.yellow(`📝 Review ${drafts.length} draft(s): npm run review`));
  }
  if (reviewed.length > 0) {
    console.log(chalk.blue(`🔄 Run pipeline for ${reviewed.length} item(s): npm run pipeline`));
  }
}

function getStatusColor(status) {
  const colors = {
    draft: chalk.yellow,
    reviewed: chalk.blue,
    translated: chalk.cyan,
    audio: chalk.green,
    social: chalk.magenta,
    published: chalk.green.bold
  };
  return colors[status] || chalk.white;
}

function showHelp() {
  console.log(chalk.blue.bold("📖 From Fed to Chain CLI"));
  console.log(chalk.gray("=".repeat(50)));
  console.log(chalk.cyan("Core Workflow:"));
  console.log("  npm run review                                 - Interactive review of all pending content");
      
  console.log(chalk.gray("\nExamples:"));
  console.log("  npm run review                                 - Review all draft content interactively");
  console.log("  npm run pipeline                               - Auto-detect and process all unfinished content");
  console.log("  npm run pipeline 2025-06-30-bitcoin           - Continue processing specific content from where it left off");
  console.log("");
  console.log(chalk.yellow("Review Controls:"));
  console.log("  [a]ccept    - Approve content (optional feedback)");
  console.log("  [r]eject    - Reject with required feedback");
  console.log("  [s]kip      - Skip this content");
  console.log("  [q]uit      - Exit review session");
  console.log("");
  console.log(chalk.gray("Smart Pipeline Features:"));
  console.log("  • Automatically detects content at each phase: reviewed → translated → audio → social");
  console.log("  • Picks up where you left off - no need to restart from translation");
  console.log("  • Shows what content needs what phase before processing");
  
  console.log(chalk.gray("\nReview Tips:"));
  console.log("  • Type 'a good content' to accept with feedback");
  console.log("  • Type 'r needs examples' to reject with feedback");
  console.log("  • Just 'a' or 'r' will prompt for feedback");
}

main();
