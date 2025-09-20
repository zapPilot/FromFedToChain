#!/usr/bin/env node
import { ContentSchema } from "./ContentSchema.js";
import chalk from "chalk";
import { ContentManager } from "./ContentManager.js";
import { ContentPipelineService } from "./services/ContentPipelineService.js";

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
      case "pipeline":
        await handlePipeline();
        break;
      case "concepts":
        // 導入 ConceptCli 來處理概念相關命令
        const { ConceptCli } = await import("./ConceptCli.js");
        await ConceptCli.handleCommand(args.slice(1));
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

    // Check category
    let currentCategory = content.category;
    console.log(
      chalk.blue("Check category: [c]hange category, [k]eep current"),
    );
    process.stdout.write("▷ ");

    try {
      const categoryInput = await getUserInput();
      const categoryDecision = categoryInput.trim().toLowerCase();

      if (categoryDecision === "c" || categoryDecision === "change") {
        const availableCategories = ContentSchema.getCategories();
        console.log(chalk.cyan("Available categories:"));
        availableCategories.forEach((cat, index) => {
          console.log(chalk.cyan(`  ${index + 1}. ${cat}`));
        });

        process.stdout.write("Enter new category: ");
        const newCategoryInput = await getUserInput();
        const newCategory = newCategoryInput.trim();

        if (availableCategories.includes(newCategory)) {
          currentCategory = newCategory;
          console.log(chalk.green(`✅ Category changed to: ${newCategory}`));
        } else {
          console.log(
            chalk.red(
              `❌ Invalid category. Keeping current: ${currentCategory}`,
            ),
          );
        }
      } else {
        console.log(chalk.gray(`📂 Keeping category: ${currentCategory}`));
      }
    } catch (error) {
      console.log(
        chalk.red(`\n❌ Error getting category input: ${error.message}`),
      );
      console.log(chalk.gray(`📂 Keeping category: ${currentCategory}`));
    }

    console.log("");

    // Get user decision
    let action, feedback;
    while (true) {
      console.log(chalk.blue("Decision: [a]ccept, [r]eject, [s]kip, [q]uit"));
      process.stdout.write("▷ ");

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
        // Update category if changed
        if (currentCategory !== content.category) {
          await ContentManager.updateSourceCategory(
            content.id,
            currentCategory,
          );
          console.log(chalk.blue(`📂 Category updated to: ${currentCategory}`));
        }

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
        // Update category if changed (even for rejected content)
        if (currentCategory !== content.category) {
          await ContentManager.updateSourceCategory(
            content.id,
            currentCategory,
          );
          console.log(chalk.blue(`📂 Category updated to: ${currentCategory}`));
        }

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
    let timeout;
    let readableListener;
    let errorListener;

    const cleanup = () => {
      if (timeout) clearTimeout(timeout);
      if (readableListener)
        process.stdin.removeListener("readable", readableListener);
      if (errorListener) process.stdin.removeListener("error", errorListener);
    };

    timeout = setTimeout(() => {
      cleanup();
      reject(new Error("Input timeout"));
    }, 300000); // 5 minute timeout

    readableListener = () => {
      cleanup();
      const chunk = process.stdin.read();
      if (chunk !== null) {
        resolve(chunk.toString().trim());
      } else {
        reject(new Error("No input received"));
      }
    };

    errorListener = (error) => {
      cleanup();
      reject(error);
    };

    process.stdin.once("readable", readableListener);
    process.stdin.once("error", errorListener);
  });
}

async function handlePipeline() {
  const id = args[1];

  console.log(chalk.blue.bold("🔄 Running Smart Pipeline"));
  console.log(
    chalk.gray("Automatically detects and processes unfinished phases"),
  );
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
    console.log(
      chalk.blue(
        `Found ${allPendingContent.length} content items needing processing:`,
      ),
    );
    showPipelineStatus(allPendingContent);
    console.log("");

    // Process each content item
    for (const item of allPendingContent) {
      console.log(
        chalk.cyan(
          `\n🔄 Processing: ${item.content.id} (needs ${item.nextPhase})`,
        ),
      );
      await runPipelineForContent(item.content.id);
    }
  }

  console.log(chalk.green.bold("\n🎉 Pipeline completed!"));
}

// Get all content that needs processing at any phase (data-driven)
async function getAllPendingContent() {
  return await ContentPipelineService.getAllPendingContent();
}

// Show pipeline status summary (data-driven)
function showPipelineStatus(pendingContent) {
  const phaseGroups = ContentPipelineService.getPhaseGroups(pendingContent);

  Object.entries(phaseGroups).forEach(([phase, items]) => {
    const phaseColor = ContentPipelineService.getPhaseColor(phase);

    console.log(phaseColor(`📋 ${phase.toUpperCase()}: ${items.length} items`));
    items.forEach((item) => {
      console.log(
        chalk.gray(
          `   • ${item.content.id}: ${item.content.title.substring(0, 50)}...`,
        ),
      );
    });
  });
}

async function runPipelineForContent(id) {
  try {
    console.log(chalk.blue.bold(`🔄 Running pipeline for: ${id}`));

    let currentContent = await ContentManager.readSource(id);
    let currentStatus = currentContent.status;
    let stepNumber = 1;

    console.log(chalk.gray(`Starting status: ${currentStatus}`));

    // Continue processing until we reach the end of the pipeline or encounter an error
    while (true) {
      const step = ContentSchema.getPipelineStep(currentStatus);

      if (!step) {
        console.log(
          chalk.yellow(
            `⚠️ No pipeline step found for status: ${currentStatus}`,
          ),
        );
        break;
      }

      if (!step.nextStatus) {
        console.log(
          chalk.green(
            `✅ Content ${id} has reached final status: ${currentStatus}`,
          ),
        );
        break;
      }

      console.log(chalk.blue(`${stepNumber}️⃣ ${step.description}...`));
      console.log(chalk.gray(`   ${currentStatus} → ${step.nextStatus}`));

      // Process the next step
      const success = await ContentPipelineService.processContentNextStep(id);

      if (!success) {
        console.error(
          chalk.red(`❌ Pipeline step failed: ${step.description}`),
        );
        break;
      }

      // Update current status for next iteration
      currentContent = await ContentManager.readSource(id);
      const newStatus = currentContent.status;

      if (newStatus === currentStatus) {
        console.error(
          chalk.red(
            `❌ Status didn't change after processing. Stuck at: ${currentStatus}`,
          ),
        );
        break;
      }

      currentStatus = newStatus;
      stepNumber++;

      // Safety check to prevent infinite loops
      if (stepNumber > 10) {
        console.error(
          chalk.red(
            `❌ Pipeline exceeded maximum steps (10). Breaking to prevent infinite loop.`,
          ),
        );
        break;
      }
    }

    console.log(
      chalk.green(
        `✅ Pipeline completed for: ${id} (final status: ${currentStatus})`,
      ),
    );
  } catch (error) {
    console.error(chalk.red(`❌ Pipeline failed for ${id}: ${error.message}`));
  }
}

function showHelp() {
  console.log(chalk.blue.bold("📖 From Fed to Chain CLI"));
  console.log(chalk.gray("=".repeat(50)));
  console.log(chalk.cyan("Streamlined Workflow:"));
  console.log(
    "  npm run review                                 - Interactive review of draft content",
  );
  console.log(
    "  npm run pipeline                               - Process content through translation → audio → social",
  );
  console.log(
    "  npm run concepts <command>                     - Manage knowledge concepts",
  );

  console.log(chalk.gray("\nWorkflow Steps:"));
  console.log("  1️⃣ Create content files in content/zh-TW/");
  console.log("  2️⃣ npm run review        - Review and approve content");
  console.log(
    "  3️⃣ npm run pipeline      - Auto-process: translate → audio → social hooks",
  );
  console.log("  4️⃣ Manual publishing     - Content ready for distribution");

  console.log(chalk.gray("\nPipeline Examples:"));
  console.log(
    "  npm run pipeline                               - Process all unfinished content",
  );
  console.log(
    "  npm run pipeline 2025-06-30-bitcoin           - Process specific content",
  );

  console.log(chalk.gray("\nKnowledge Concepts:"));
  console.log(
    "  npm run concepts list                          - List all concepts",
  );
  console.log(
    "  npm run concepts search '確定性溢價'             - Search concepts",
  );
  console.log(
    "  npm run concepts show certainty-premium        - Show concept details",
  );
  console.log(
    "  npm run concepts stats                         - Show statistics",
  );

  console.log("");
  console.log(chalk.yellow("Review Controls:"));
  console.log("  [a]ccept    - Approve content (optional feedback)");
  console.log("  [r]eject    - Reject with required feedback");
  console.log("  [s]kip      - Skip this content");
  console.log("  [q]uit      - Exit review session");
  console.log("");
  console.log(chalk.gray("Smart Pipeline Features:"));
  console.log(
    "  • Auto-detects content phase: reviewed → translated → audio → social",
  );
  console.log("  • Resumes from where you left off");
  console.log("  • Processes multiple content items in one command");
  console.log("  • Discrete audio steps for testing and debugging");
  console.log("  • Knowledge concepts are preserved across all languages");
}

main();
