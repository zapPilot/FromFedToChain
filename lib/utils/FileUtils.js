import fs from "fs/promises";
import path from "path";
import { PATHS, CATEGORIES, LANGUAGES } from "../../config/languages.js";

export class FileUtils {
  static async readJSON(filePath) {
    try {
      const content = await fs.readFile(filePath, "utf-8");
      return JSON.parse(content);
    } catch (error) {
      throw new Error(`Failed to read JSON file ${filePath}: ${error.message}`);
    }
  }

  static async writeJSON(filePath, data) {
    await fs.mkdir(path.dirname(filePath), { recursive: true });
    await fs.writeFile(filePath, JSON.stringify(data, null, 2));
  }

  static validateContentSchema(content) {
    // Basic schema validation for content structure
    if (!content || typeof content !== 'object') {
      throw new Error('Content must be an object');
    }

    if (!content.id || typeof content.id !== 'string') {
      throw new Error('Content must have a valid id');
    }

    if (!content.category || !CATEGORIES.includes(content.category)) {
      throw new Error(`Content must have a valid category. Got: ${content.category}`);
    }

    if (!content.language || typeof content.language !== 'object') {
      throw new Error('Content must have a language object');
    }

    // Check if at least one language exists
    const languages = Object.keys(content.language);
    if (languages.length === 0) {
      throw new Error('Content must have at least one language');
    }

    // Validate each language entry
    for (const [lang, langData] of Object.entries(content.language)) {
      if (!LANGUAGES.SUPPORTED.includes(lang)) {
        throw new Error(`Unsupported language: ${lang}`);
      }
      
      if (!langData.title || typeof langData.title !== 'string') {
        throw new Error(`Language ${lang} must have a title`);
      }
      
      if (!langData.content || typeof langData.content !== 'string') {
        throw new Error(`Language ${lang} must have content`);
      }
    }

    if (!content.metadata || typeof content.metadata !== 'object') {
      throw new Error('Content must have metadata object');
    }

    return true;
  }

  static async scanContentFiles(filter = null) {
    const results = [];

    for (const lang of LANGUAGES.SUPPORTED) {
      const langPath = path.join(PATHS.CONTENT_ROOT, lang);

      for (const category of CATEGORIES) {
        const categoryPath = path.join(langPath, category);

        try {
          const files = await fs.readdir(categoryPath);

          for (const file of files.filter((f) => f.endsWith(".json"))) {
            const filePath = path.join(categoryPath, file);

            try {
              const data = await this.readJSON(filePath);
              const fileInfo = {
                path: filePath,
                language: lang,
                category,
                filename: file,
                id: data.id || path.basename(file, ".json"),
                data,
              };

              if (!filter || filter(fileInfo)) {
                results.push(fileInfo);
              }
            } catch (error) {
              console.warn(
                `Warning: Could not parse ${filePath}: ${error.message}`,
              );
            }
          }
        } catch (error) {
          // Category directory doesn't exist, skip
        }
      }
    }

    return results;
  }

  static async findSourceFile(fileId) {
    const sourcePath = path.join(PATHS.CONTENT_ROOT, LANGUAGES.PRIMARY);

    for (const category of CATEGORIES) {
      const filePath = path.join(sourcePath, category, `${fileId}.json`);
      try {
        await fs.access(filePath);
        return { filePath, category };
      } catch {
        continue;
      }
    }

    throw new Error(`Source file not found: ${fileId}`);
  }

  static getContentPath(language, category, fileId) {
    return path.join(PATHS.CONTENT_ROOT, language, category, `${fileId}.json`);
  }
}
