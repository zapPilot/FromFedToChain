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
