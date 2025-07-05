#!/usr/bin/env node

import fs from "fs/promises";
import chalk from "chalk";
import { ContentManager } from "./ContentManager.js";

const args = process.argv.slice(2);
const command = args[0];

async function main() {
  console.log(chalk.blue.bold("🚀 From Fed to Chain - Content Review"));
  console.log(chalk.gray("=".repeat(50)));

  try {
    switch (command) {
      case "review":
        await handleReview();
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


function showHelp() {
  console.log(chalk.blue.bold("📖 From Fed to Chain CLI"));
  console.log(chalk.gray("=".repeat(50)));
  console.log(chalk.cyan("Commands:"));
  console.log(
    "  npm run review                  - Interactive review of all pending content",
  );

  console.log(chalk.gray("\nContent Flow:"));
  console.log("  draft → reviewed (via review) → published (manual)");

  console.log(chalk.gray("\nExamples:"));
  console.log(
    "  npm run review                  - Review all draft content interactively",
  );
  console.log("");
  console.log(chalk.yellow("Review Controls:"));
  console.log("  [a]ccept    - Approve content (optional feedback)");
  console.log("  [r]eject    - Reject with required feedback");
  console.log("  [s]kip      - Skip this content");
  console.log("  [q]uit      - Exit review session");
}

main();
