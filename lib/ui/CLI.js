import { ReviewService } from "../core/ReviewService.js";
import { TranslationService } from "../core/TranslationService.js";
import { TTSService } from "../core/TTSService.js";
import { ContentManager } from "../core/ContentManager.js";
import { Logger } from "../utils/Logger.js";
import { getTargetLanguages } from "../../config/languages.js";

export class CLI {
  static async showTranslationStatus() {
    Logger.title("🌐 Translation Status");

    const files = await ContentManager.getFilesForTranslation();
    if (files.length === 0) {
      Logger.success("✅ No files ready for translation");
      return;
    }

    Logger.info(`📝 Found ${files.length} files ready for translation:`);

    files.forEach((file, index) => {
      const missing = ContentManager.getMissingTranslations(file.data);
      const langData =
        file.data.languages[
          file.data.metadata.translation_status.source_language
        ];

      console.log(`${(index + 1).toString().padStart(2)}: ${langData.title}`);
      console.log(`    ID: ${file.id}`);
      console.log(`    Category: ${file.category}`);
      console.log(`    Missing: ${missing.join(", ") || "None"}`);
      console.log("");
    });
  }

  static showHelp() {
    Logger.title("📚 FromFedToChain CLI");
    console.log("Available commands:");
    console.log("");
    console.log("review                    - Review content for approval");
    console.log("translate                 - Translate all to all languages");
    console.log(
      "translate --target=<lang> - Translate all to specific language",
    );
    console.log("translate-status          - Show translation status");
    console.log(
      "tts                       - Process TTS for all pending content",
    );
    console.log("help                      - Show this help");
    console.log("");
    console.log("Examples:");
    console.log("node cli.js review");
    console.log("node cli.js translate --target=ja-JP");
    console.log("node cli.js tts");
  }

  static async run(args = []) {
    const command = args[0];

    try {
      switch (command) {
        case "review":
          await ReviewService.reviewAll();
          break;

        case "translate":
          const targetLang = args
            .find((arg) => arg.startsWith("--target="))
            ?.split("=")[1];
          if (targetLang) {
            await TranslationService.translateAll([targetLang]);
          } else {
            await TranslationService.translateAll();
          }
          break;

        case "translate-status":
          await this.showTranslationStatus();
          break;

        case "tts":
          const ttsService = new TTSService();
          await ttsService.processAll();
          break;

        case "help":
        case undefined:
          this.showHelp();
          break;

        default:
          Logger.error(`Unknown command: ${command}`);
          this.showHelp();
          process.exit(1);
      }
    } catch (error) {
      Logger.error(`❌ Error: ${error.message}`);
      process.exit(1);
    }
  }
}
