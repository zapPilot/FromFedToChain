import { Translate } from "@google-cloud/translate/build/src/v2/index.js";
import chalk from "chalk";
import { ContentManager } from "../ContentManager.js";
import path from "path";
import {
  getTranslationTargets,
  getTranslationConfig,
  LANGUAGES,
  PATHS,
} from "../../config/languages.js";

export class TranslationService {
  static SUPPORTED_LANGUAGES = getTranslationTargets();
  static translate_client = null;

  // Initialize Google Cloud Translate client
  static getTranslateClient() {
    if (!this.translate_client) {
      const serviceAccountPath = path.resolve(
        process.cwd(),
        PATHS.SERVICE_ACCOUNT,
      );
      this.translate_client = new Translate({
        keyFilename: serviceAccountPath,
        // projectId will be automatically inferred from service account file
      });
    }
    return this.translate_client;
  }

  // Translate content to target language
  static async translate(id, targetLanguage) {
    if (!this.SUPPORTED_LANGUAGES.includes(targetLanguage)) {
      throw new Error(`Unsupported language: ${targetLanguage}`);
    }

    console.log(chalk.blue(`🌐 Translating ${id} to ${targetLanguage}...`));

    // Get the source content (zh-TW)
    const sourceContent = await ContentManager.readSource(id);

    if (sourceContent.status !== "reviewed") {
      throw new Error(
        `Content must be reviewed before translation. Current status: ${sourceContent.status}`,
      );
    }

    const { title, content } = sourceContent;

    // Generate translation using Google Cloud Translate API
    const translatedTitle = await this.translateText(title, targetLanguage);
    const translatedContent = await this.translateText(content, targetLanguage);

    // Prepare knowledge concepts (copy from source, don't translate)
    const knowledgeConcepts = sourceContent.knowledge_concepts_used || [];

    // Add translation to content (creates new language file)
    await ContentManager.addTranslation(
      id,
      targetLanguage,
      translatedTitle,
      translatedContent,
      sourceContent.framework,
      knowledgeConcepts, // Pass knowledge concepts
    );

    // Update source status if all translations are complete
    const availableLanguages = await ContentManager.getAvailableLanguages(id);
    const targetLanguages = ["zh-TW", ...this.SUPPORTED_LANGUAGES]; // Source + translations

    if (availableLanguages.length === targetLanguages.length) {
      await ContentManager.updateSourceStatus(id, "translated");
    }

    console.log(
      chalk.green(`✅ Translation completed: ${id} (${targetLanguage})`),
    );
    return { translatedTitle, translatedContent };
  }

  // Translate all supported languages for content
  static async translateAll(id) {
    const results = {};

    for (const language of this.SUPPORTED_LANGUAGES) {
      try {
        const result = await this.translate(id, language);
        results[language] = result;
      } catch (error) {
        console.error(
          chalk.red(`❌ Translation failed for ${language}: ${error.message}`),
        );
        results[language] = { error: error.message };
      }
    }

    return results;
  }

  // Translate text using Google Cloud Translate API
  static async translateText(text, targetLanguage) {
    // Get translation configurations
    const sourceConfig = getTranslationConfig(LANGUAGES.PRIMARY);
    const targetConfig = getTranslationConfig(targetLanguage);

    const sourceLanguage = sourceConfig.languageCode;
    const targetLangCode = targetConfig.languageCode;

    if (!targetConfig.isTarget) {
      throw new Error(
        `Language ${targetLanguage} is not configured as a translation target`,
      );
    }

    try {
      const translateClient = this.getTranslateClient();

      const [translation] = await translateClient.translate(text, {
        from: sourceLanguage,
        to: targetLangCode,
        format: "text",
      });

      return translation;
    } catch (error) {
      if (error.code === "ENOENT") {
        throw new Error(
          "Google Cloud service account file not found. Please ensure service-account.json exists in the project root.",
        );
      } else if (error.code === "EACCES") {
        throw new Error(
          "Google Cloud authentication failed. Please check your service-account.json credentials.",
        );
      } else {
        throw new Error(`Translation failed: ${error.message}`);
      }
    }
  }

  // Translate social hook text
  static async translateSocialHook(hookText, targetLanguage) {
    if (!hookText || !hookText.trim()) {
      throw new Error("Hook text cannot be empty");
    }

    if (!this.SUPPORTED_LANGUAGES.includes(targetLanguage)) {
      throw new Error(
        `Unsupported language for social hook translation: ${targetLanguage}`,
      );
    }

    console.log(
      chalk.blue(`🔄 Translating social hook to ${targetLanguage}...`),
    );

    try {
      const translatedHook = await this.translateText(
        hookText.trim(),
        targetLanguage,
      );
      console.log(
        chalk.green(`✅ Social hook translated to ${targetLanguage}`),
      );
      return translatedHook;
    } catch (error) {
      console.error(
        chalk.red(
          `❌ Social hook translation failed for ${targetLanguage}: ${error.message}`,
        ),
      );
      throw error;
    }
  }

  // Get content needing translation
  static async getContentNeedingTranslation() {
    return ContentManager.getSourceByStatus("reviewed");
  }
}
