import readline from "readline";
import { ContentManager } from "./ContentManager.js";
import { Logger } from "../utils/Logger.js";
import { LANGUAGES } from "../../config/languages.js";

export class ReviewService {
  static async askQuestion(query) {
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout,
    });

    return new Promise((resolve) =>
      rl.question(query, (ans) => {
        rl.close();
        resolve(ans);
      }),
    );
  }

  static displayContent(fileData) {
    const langData = fileData.languages?.[LANGUAGES.PRIMARY] || {};

    Logger.title("📄 Content Preview");
    console.log(`Title: ${langData.title || "[No title]"}`);
    console.log(`Date: ${fileData.date}`);
    console.log(`Category: ${fileData.category}`);

    if (fileData.references?.length > 0) {
      console.log(`References: ${fileData.references.join(", ")}`);
    }

    console.log("\n--- Content ---");
    console.log(langData.content || "[No content]");

    const ttsStatus =
      fileData.metadata?.tts?.[LANGUAGES.PRIMARY]?.status || "[Unknown]";
    console.log(`\nTTS Status: ${ttsStatus}`);
    console.log("=".repeat(50));
  }

  static async reviewFile(file) {
    this.displayContent(file.data);

    let answer = await this.askQuestion("Approve this content? (y/n): ");
    answer = answer.trim().toLowerCase();

    if (answer === "n" || answer === "no") {
      const reason = await this.askQuestion("Enter rejection reason: ");

      await ContentManager.updateContent(file.path, {
        metadata: {
          translation_status: {
            source_reviewed: true,
            rejection: {
              rejected: true,
              reason,
              timestamp: new Date().toISOString(),
            },
          },
        },
      });

      Logger.error(`Rejected: ${reason}`);
      return false;
    } else if (answer === "y" || answer === "yes") {
      await ContentManager.updateContent(file.path, {
        metadata: {
          translation_status: {
            source_reviewed: true,
            rejection: {
              rejected: false,
              reason: "",
              timestamp: "",
            },
          },
        },
      });

      Logger.success("Approved");
      return true;
    } else {
      Logger.warning("Please enter y (approve) or n (reject)");
      return await this.reviewFile(file);
    }
  }

  static async reviewAll() {
    Logger.title("🔍 Content Review");

    const pendingFiles = await ContentManager.getFilesForReview();

    if (pendingFiles.length === 0) {
      Logger.success("✅ No content found for review");
      return;
    }

    Logger.info(`📝 Found ${pendingFiles.length} file(s) pending review`);

    for (let i = 0; i < pendingFiles.length; i++) {
      const file = pendingFiles[i];
      Logger.step(i + 1, pendingFiles.length, `Reviewing: ${file.filename}`);

      await this.reviewFile(file);

      if (i < pendingFiles.length - 1) {
        await this.askQuestion("\nPress Enter to continue...");
      }
    }

    Logger.success("🎉 All content reviewed!");
  }
}
