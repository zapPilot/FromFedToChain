import chalk from "chalk";
import { ContentManager } from "../core/ContentManager.js";
import { FileUtils } from "../utils/FileUtils.js";
import { LANGUAGES } from "../../config/languages.js";

/**
 * Mock translation service for testing pipeline
 * Copies source content with "[LANG]" prefix for testing
 */
export class MockTranslationService {
  static async translateFile(fileId, targetLang) {
    console.log(chalk.blue(`🔄 Mock translating ${fileId} → ${targetLang}`));

    // Find source file
    const { filePath: sourcePath, category } =
      await FileUtils.findSourceFile(fileId);
    const sourceData = await FileUtils.readJSON(sourcePath);

    // Validate
    if (!sourceData.metadata?.translation_status?.source_reviewed) {
      throw new Error("Source content must be reviewed before translation");
    }

    // Mock translation - just add language prefix
    const sourceContent = sourceData.languages[LANGUAGES.PRIMARY];
    const mockTranslation = {
      title: `[${targetLang.toUpperCase()}] ${sourceContent.title}`,
      content: `[${targetLang.toUpperCase()}] ${sourceContent.content}`,
    };

    // Create translated file
    const targetPath = FileUtils.getContentPath(
      targetLang,
      category,
      sourceData.id,
    );
    const translatedData = {
      id: sourceData.id,
      date: sourceData.date,
      category: sourceData.category,
      references: sourceData.references,
      languages: {
        [targetLang]: mockTranslation,
      },
      metadata: {
        translation_status: {
          source_language: LANGUAGES.PRIMARY,
          source_reviewed: true,
          translated_to: [targetLang],
          translated_at: new Date().toISOString(),
          mock: true, // Mark as mock translation
        },
        tts: {
          [targetLang]: {
            status: "pending",
            audio_url: null,
            voice_config: null,
          },
        },
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      },
    };

    await FileUtils.writeJSON(targetPath, translatedData);

    // Update source metadata
    const translatedTo =
      sourceData.metadata.translation_status.translated_to || [];
    if (!translatedTo.includes(targetLang)) {
      translatedTo.push(targetLang);
      await ContentManager.updateContent(sourcePath, {
        metadata: {
          translation_status: { translated_to: translatedTo },
        },
      });
    }

    console.log(chalk.green(`✅ Mock translation completed: ${targetPath}`));
    return { sourcePath, targetPath, category, targetLang, mock: true };
  }
}
