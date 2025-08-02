import { executeCommandSync } from "../utils/command-executor.js";
import chalk from "chalk";
import { ContentManager } from "../ContentManager.js";
import { TranslationService } from "./TranslationService.js";
import { ContentSchema } from "../ContentSchema.js";
import {
  getSocialConfig,
  shouldGenerateSocialHooks,
  getTranslationTargets,
} from "../../config/languages.js";

export class SocialService {
  // Dynamic language support based on configuration
  static get SUPPORTED_LANGUAGES() {
    return ContentSchema.getAllLanguages().filter((lang) =>
      shouldGenerateSocialHooks(lang),
    );
  }

  // Generate social hook for specific language
  static async generateHook(
    id,
    language,
    commandExecutor = executeCommandSync,
  ) {
    console.log(chalk.blue(`📱 Generating social hook: ${id} (${language})`));

    // Get specific language content
    const content = await ContentManager.read(id, language);

    if (!content) {
      throw new Error(`No ${language} translation found for ${id}`);
    }

    const { title, content: text } = content;

    // Generate social hook using Claude
    const hook = await this.generateHookWithClaude(
      title,
      text,
      language,
      commandExecutor,
    );

    // Validate hook length
    const validatedHook = this.validateHookLength(hook, language);

    // Add social hook to content
    await ContentManager.addSocialHook(id, language, validatedHook);

    console.log(chalk.green(`✅ Social hook generated: ${id} (${language})`));
    return validatedHook;
  }

  // Generate social hooks using zh-TW-first translation pipeline
  static async generateAllHooksTranslated(
    id,
    commandExecutor = executeCommandSync,
  ) {
    console.log(
      chalk.blue(`📱 Starting zh-TW-first social hook generation for: ${id}`),
    );

    // Check source status first
    const sourceContent = await ContentManager.readSource(id);

    if (sourceContent.status !== "content") {
      throw new Error(
        `Content must be uploaded before social hooks. Current status: ${sourceContent.status}`,
      );
    }

    // Get all available languages for this content
    const availableLanguages = await ContentManager.getAvailableLanguages(id);

    // Get all languages that should have social hooks generated
    const socialHookLanguages = ContentSchema.getAllLanguages().filter(
      (lang) =>
        availableLanguages.includes(lang) && shouldGenerateSocialHooks(lang),
    );

    if (socialHookLanguages.length === 0) {
      console.log(
        chalk.yellow(
          `⚠️  No languages configured for social hook generation for ${id}`,
        ),
      );
      await ContentManager.updateSourceStatus(id, "social");
      return {};
    }

    const results = {};

    try {
      // Step 1: Get or generate master Chinese (zh-TW) hook - the source language
      const sourceLang = "zh-TW";
      if (socialHookLanguages.includes(sourceLang)) {
        const sourceContent = await ContentManager.read(id, sourceLang);
        if (!sourceContent) {
          throw new Error(`No Chinese source content found for ${id}`);
        }

        let validatedChineseHook;

        // Check if Chinese hook already exists
        if (sourceContent.social_hook && sourceContent.social_hook.trim()) {
          console.log(
            chalk.blue(`🎯 Using existing Chinese social hook for: ${id}`),
          );
          validatedChineseHook = sourceContent.social_hook;
          results[sourceLang] = {
            success: true,
            hook: validatedChineseHook,
            method: "existing",
          };
          console.log(chalk.green(`✅ Master Chinese hook found: ${id}`));
        } else {
          // Generate new Chinese hook
          console.log(
            chalk.blue(`🎯 Generating master Chinese social hook for: ${id}`),
          );

          const masterHook = await this.generateHookWithClaude(
            sourceContent.title,
            sourceContent.content,
            sourceLang,
            commandExecutor,
          );

          // Validate and save Chinese hook
          validatedChineseHook = this.validateHookLength(
            masterHook,
            sourceLang,
          );
          await ContentManager.addSocialHook(
            id,
            sourceLang,
            validatedChineseHook,
          );

          results[sourceLang] = {
            success: true,
            hook: validatedChineseHook,
            method: "generated",
          };
          console.log(chalk.green(`✅ Master Chinese hook generated: ${id}`));
        }

        // Step 2: Translate Chinese hook to other languages
        const otherLanguages = socialHookLanguages.filter(
          (lang) => lang !== sourceLang,
        );
        const translationTargets = getTranslationTargets(); // en-US, ja-JP

        for (const targetLang of otherLanguages) {
          try {
            if (translationTargets.includes(targetLang)) {
              // Translate from Chinese to target language
              console.log(
                chalk.blue(
                  `🔄 Translating Chinese social hook to ${targetLang}: ${id}`,
                ),
              );

              const translatedHook =
                await TranslationService.translateSocialHook(
                  validatedChineseHook,
                  targetLang,
                );
              const validatedHook = this.validateHookLength(
                translatedHook,
                targetLang,
              );

              await ContentManager.addSocialHook(id, targetLang, validatedHook);
              results[targetLang] = {
                success: true,
                hook: validatedHook,
                method: "translated",
              };

              console.log(
                chalk.green(
                  `✅ Social hook translated to ${targetLang}: ${id}`,
                ),
              );
            } else {
              // Generate directly for any non-translation-target languages
              console.log(
                chalk.blue(
                  `🎯 Generating native social hook for ${targetLang}: ${id}`,
                ),
              );

              const hook = await this.generateHook(
                id,
                targetLang,
                commandExecutor,
              );
              results[targetLang] = {
                success: true,
                hook,
                method: "generated",
              };

              console.log(
                chalk.green(
                  `✅ Social hook generated for ${targetLang}: ${id}`,
                ),
              );
            }
          } catch (error) {
            console.error(
              chalk.red(
                `❌ Social hook processing failed for ${targetLang}: ${error.message}`,
              ),
            );
            results[targetLang] = {
              success: false,
              error: error.message,
              method: "translated",
            };
          }
        }
      } else {
        // Fallback: Generate for each language individually if Chinese not available
        console.log(
          chalk.yellow(
            `⚠️  Chinese source not available, falling back to individual generation`,
          ),
        );
        return await this.generateAllHooksIndividual(id, commandExecutor);
      }

      // Update source status if all hooks generated successfully
      const allSuccessful = Object.values(results).every((r) => r.success);
      if (allSuccessful) {
        await ContentManager.updateSourceStatus(id, "social");
        console.log(chalk.green(`🎉 All social hooks completed for: ${id}`));
      } else {
        console.log(chalk.yellow(`⚠️  Some social hooks failed for: ${id}`));
      }

      return results;
    } catch (error) {
      console.error(
        chalk.red(
          `❌ Social hook generation pipeline failed for ${id}: ${error.message}`,
        ),
      );
      throw error;
    }
  }

  // Validate hook length and truncate if necessary
  static validateHookLength(hook, language) {
    const socialConfig = getSocialConfig(language);
    const maxLength = socialConfig.hookLength;

    if (hook.length <= maxLength) {
      return hook;
    }

    console.log(
      chalk.yellow(
        `⚠️  Hook too long for ${language} (${hook.length}>${maxLength}), truncating...`,
      ),
    );

    // Truncate at last complete word before limit
    const truncated = hook.substring(0, maxLength);
    const lastSpaceIndex = truncated.lastIndexOf(" ");

    if (lastSpaceIndex > maxLength * 0.8) {
      // Only truncate at word boundary if we don't lose too much
      return truncated.substring(0, lastSpaceIndex) + "...";
    } else {
      return truncated.substring(0, maxLength - 3) + "...";
    }
  }

  // Generate social hooks for all languages (main entry point)
  static async generateAllHooks(id, commandExecutor = executeCommandSync) {
    // Use optimized translation pipeline by default
    return await this.generateAllHooksTranslated(id, commandExecutor);
  }

  // Generate social hooks for all languages (legacy individual method)
  static async generateAllHooksIndividual(
    id,
    commandExecutor = executeCommandSync,
  ) {
    console.log(
      chalk.blue(`📱 Generating social hooks individually for: ${id}`),
    );

    // Check source status first
    const sourceContent = await ContentManager.readSource(id);

    if (sourceContent.status !== "content") {
      throw new Error(
        `Content must be uploaded before social hooks. Current status: ${sourceContent.status}`,
      );
    }

    // Get all available languages for this content
    const availableLanguages = await ContentManager.getAvailableLanguages(id);

    // Get all languages that should have social hooks generated
    const socialHookLanguages = ContentSchema.getAllLanguages().filter(
      (lang) =>
        availableLanguages.includes(lang) && shouldGenerateSocialHooks(lang),
    );

    const results = {};

    for (const language of socialHookLanguages) {
      try {
        const hook = await this.generateHook(id, language, commandExecutor);
        const validatedHook = this.validateHookLength(hook, language);
        await ContentManager.addSocialHook(id, language, validatedHook);
        results[language] = {
          success: true,
          hook: validatedHook,
          method: "generated",
        };
      } catch (error) {
        console.error(
          chalk.red(
            `❌ Social hook generation failed for ${language}: ${error.message}`,
          ),
        );
        results[language] = {
          success: false,
          error: error.message,
          method: "generated",
        };
      }
    }

    // Update source status if all hooks generated successfully
    const allSuccessful = Object.values(results).every((r) => r.success);
    if (socialHookLanguages.length === 0 || allSuccessful) {
      await ContentManager.updateSourceStatus(id, "social");
    }

    return results;
  }

  // Generate social hook using Claude
  static async generateHookWithClaude(
    title,
    content,
    language,
    commandExecutor = executeCommandSync,
  ) {
    const languageMap = {
      "zh-TW": "Traditional Chinese",
      "en-US": "English",
      "ja-JP": "Japanese",
    };

    const langName = languageMap[language] || "English";

    // Extract key insight (first meaningful paragraph)
    const keyInsight = content.split("\n\n")[0] || content.substring(0, 200);

    const prompt = `Create 1 engaging social media hook for "${title}" in ${langName}.

Key content: ${keyInsight}

Requirements:
- Under 280 characters
- Compelling and shareable
- Match ${langName} social media style
- mention that Eng | 中 | 日 podcasts are available on Apple Podcasts, Spotify

Return only the hook, no explanations.`;

    try {
      const claudeCommand = `claude -p ${JSON.stringify(prompt)}`;

      const hookResult = commandExecutor(claudeCommand, {
        encoding: "utf-8",
        timeout: 60000,
        maxBuffer: 1024 * 1024,
      });

      return hookResult.trim();
    } catch (error) {
      if (error.code === "ENOENT") {
        throw new Error(
          "Claude command not found. Install with: npm install -g claude-code",
        );
      } else if (error.signal === "SIGTERM") {
        throw new Error("Claude command timed out after 60 seconds");
      } else {
        throw new Error(`Social hook generation failed: ${error.message}`);
      }
    }
  }

  // Get content needing social hooks
  static async getContentNeedingSocial() {
    return ContentManager.getSourceByStatus("content");
  }
}
