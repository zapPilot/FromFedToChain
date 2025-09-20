import fs from "fs/promises";
import path from "path";
import chalk from "chalk";

/**
 * KnowledgeIndexManager - 管理知識概念索引
 * 提供概念的創建、查詢、更新和關聯管理功能
 */
export class KnowledgeIndexManager {
  static KNOWLEDGE_DIR = "./knowledge";
  static CONCEPTS_DIR = "./knowledge/concepts";
  static INDEX_FILE = "./knowledge/concepts/index.json";
  static RELATIONSHIPS_FILE = "./knowledge/relationships.json";

  // 初始化知識庫結構
  static async initialize() {
    try {
      await fs.mkdir(this.KNOWLEDGE_DIR, { recursive: true });
      await fs.mkdir(this.CONCEPTS_DIR, { recursive: true });

      // 檢查索引文件是否存在，不存在則創建
      try {
        await fs.access(this.INDEX_FILE);
      } catch (error) {
        await this.createEmptyIndex();
      }

      // 檢查關聯文件是否存在，不存在則創建
      try {
        await fs.access(this.RELATIONSHIPS_FILE);
      } catch (error) {
        await this.createEmptyRelationships();
      }

      console.log(chalk.green("✅ Knowledge index initialized"));
    } catch (error) {
      throw new Error(`Failed to initialize knowledge index: ${error.message}`);
    }
  }

  // 創建空的索引文件
  static async createEmptyIndex() {
    const emptyIndex = {
      concepts: [],
      categories: ["經濟學", "技術", "商業", "政策", "歷史"],
      total_concepts: 0,
      last_updated: new Date().toISOString(),
    };
    await fs.writeFile(this.INDEX_FILE, JSON.stringify(emptyIndex, null, 2));
  }

  // 創建空的關聯文件
  static async createEmptyRelationships() {
    const emptyRelationships = {
      relationships: [],
      relationship_types: [
        "applies_to",
        "reinforces",
        "contrasts_with",
        "prerequisite_for",
        "example_of",
      ],
      last_updated: new Date().toISOString(),
    };
    await fs.writeFile(
      this.RELATIONSHIPS_FILE,
      JSON.stringify(emptyRelationships, null, 2),
    );
  }

  // 讀取索引文件
  static async readIndex() {
    try {
      const indexContent = await fs.readFile(this.INDEX_FILE, "utf-8");
      return JSON.parse(indexContent);
    } catch (error) {
      throw new Error(`Failed to read knowledge index: ${error.message}`);
    }
  }

  // 更新索引文件
  static async updateIndex(indexData) {
    try {
      indexData.last_updated = new Date().toISOString();
      await fs.writeFile(this.INDEX_FILE, JSON.stringify(indexData, null, 2));
    } catch (error) {
      throw new Error(`Failed to update knowledge index: ${error.message}`);
    }
  }

  // 創建新概念
  static async createConcept(conceptData) {
    // 驗證必要字段
    const requiredFields = ["id", "name", "definition", "category"];
    for (const field of requiredFields) {
      if (!conceptData[field]) {
        throw new Error(`Missing required field: ${field}`);
      }
    }

    // 檢查ID是否已存在
    const existingConcept = await this.getConcept(conceptData.id);
    if (existingConcept) {
      throw new Error(`Concept with id '${conceptData.id}' already exists`);
    }

    // 準備概念數據
    const concept = {
      id: conceptData.id,
      name: conceptData.name,
      definition: conceptData.definition,
      context: conceptData.context || "",
      examples: conceptData.examples || [],
      category: conceptData.category,
      first_introduced: conceptData.first_introduced || "",
      referenced_in: conceptData.referenced_in || [],
      related_concepts: conceptData.related_concepts || [],
      tags: conceptData.tags || [],
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    // 保存概念文件
    const conceptFile = path.join(this.CONCEPTS_DIR, `${concept.name}.json`);
    await fs.writeFile(conceptFile, JSON.stringify(concept, null, 2));

    // 更新索引
    const index = await this.readIndex();
    index.concepts.push({
      id: concept.id,
      name: concept.name,
      category: concept.category,
      first_introduced: concept.first_introduced,
    });
    index.total_concepts = index.concepts.length;
    await this.updateIndex(index);

    console.log(
      chalk.green(`✅ Created concept: ${concept.name} (${concept.id})`),
    );
    return concept;
  }

  // 獲取概念（通過ID或名稱）
  static async getConcept(identifier) {
    try {
      // 首先嘗試從索引中找到概念
      const index = await this.readIndex();
      const conceptInfo = index.concepts.find(
        (c) => c.id === identifier || c.name === identifier,
      );

      if (!conceptInfo) {
        return null;
      }

      // 讀取完整的概念文件
      const conceptFile = path.join(
        this.CONCEPTS_DIR,
        `${conceptInfo.name}.json`,
      );
      const conceptContent = await fs.readFile(conceptFile, "utf-8");
      return JSON.parse(conceptContent);
    } catch (error) {
      return null;
    }
  }

  // 搜尋概念
  static async searchConcepts(query, options = {}) {
    const { category = null, fuzzy = true, includeContext = false } = options;

    try {
      const index = await this.readIndex();
      let results = [];

      for (const conceptInfo of index.concepts) {
        // 類別過濾
        if (category && conceptInfo.category !== category) {
          continue;
        }

        // 讀取完整概念數據
        const concept = await this.getConcept(conceptInfo.id);
        if (!concept) continue;

        // 搜尋邏輯
        const searchFields = [
          concept.name,
          concept.definition,
          ...(concept.tags || []),
        ];

        if (includeContext) {
          searchFields.push(concept.context);
        }

        const searchText = searchFields.join(" ").toLowerCase();
        const queryLower = query.toLowerCase();

        let isMatch = false;
        if (fuzzy) {
          isMatch = searchText.includes(queryLower);
        } else {
          isMatch = searchFields.some(
            (field) => field.toLowerCase() === queryLower,
          );
        }

        if (isMatch) {
          results.push(concept);
        }
      }

      return results;
    } catch (error) {
      throw new Error(`Search failed: ${error.message}`);
    }
  }

  // 獲取概念被引用的文章
  static async getConceptReferences(conceptId) {
    const concept = await this.getConcept(conceptId);
    if (!concept) {
      throw new Error(`Concept not found: ${conceptId}`);
    }
    return concept.referenced_in || [];
  }

  // 為文章添加概念引用
  static async addConceptReference(conceptId, articleId) {
    const concept = await this.getConcept(conceptId);
    if (!concept) {
      throw new Error(`Concept not found: ${conceptId}`);
    }

    if (!concept.referenced_in.includes(articleId)) {
      concept.referenced_in.push(articleId);
      concept.updated_at = new Date().toISOString();

      // 保存更新的概念
      const conceptFile = path.join(this.CONCEPTS_DIR, `${concept.name}.json`);
      await fs.writeFile(conceptFile, JSON.stringify(concept, null, 2));

      console.log(
        chalk.blue(`📎 Added reference: ${concept.name} -> ${articleId}`),
      );
    }
  }

  // 移除文章的概念引用
  static async removeConceptReference(conceptId, articleId) {
    const concept = await this.getConcept(conceptId);
    if (!concept) {
      throw new Error(`Concept not found: ${conceptId}`);
    }

    const index = concept.referenced_in.indexOf(articleId);
    if (index > -1) {
      concept.referenced_in.splice(index, 1);
      concept.updated_at = new Date().toISOString();

      // 保存更新的概念
      const conceptFile = path.join(this.CONCEPTS_DIR, `${concept.name}.json`);
      await fs.writeFile(conceptFile, JSON.stringify(concept, null, 2));

      console.log(
        chalk.yellow(`🗑️ Removed reference: ${concept.name} -> ${articleId}`),
      );
    }
  }

  // 列出所有概念
  static async listConcepts(category = null) {
    try {
      const index = await this.readIndex();
      let concepts = index.concepts;

      if (category) {
        concepts = concepts.filter((c) => c.category === category);
      }

      return concepts.sort((a, b) => a.name.localeCompare(b.name));
    } catch (error) {
      throw new Error(`Failed to list concepts: ${error.message}`);
    }
  }

  // 獲取所有類別
  static async getCategories() {
    try {
      const index = await this.readIndex();
      return index.categories;
    } catch (error) {
      throw new Error(`Failed to get categories: ${error.message}`);
    }
  }

  // 更新概念
  static async updateConcept(conceptId, updates) {
    const concept = await this.getConcept(conceptId);
    if (!concept) {
      throw new Error(`Concept not found: ${conceptId}`);
    }

    // 應用更新
    const updatedConcept = {
      ...concept,
      ...updates,
      updated_at: new Date().toISOString(),
    };

    // 如果名稱改變了，需要重命名文件
    const oldFile = path.join(this.CONCEPTS_DIR, `${concept.name}.json`);
    const newFile = path.join(this.CONCEPTS_DIR, `${updatedConcept.name}.json`);

    await fs.writeFile(newFile, JSON.stringify(updatedConcept, null, 2));

    if (concept.name !== updatedConcept.name) {
      await fs.unlink(oldFile);

      // 更新索引中的名稱
      const index = await this.readIndex();
      const conceptIndex = index.concepts.findIndex((c) => c.id === conceptId);
      if (conceptIndex > -1) {
        index.concepts[conceptIndex].name = updatedConcept.name;
        await this.updateIndex(index);
      }
    }

    console.log(chalk.green(`✅ Updated concept: ${updatedConcept.name}`));
    return updatedConcept;
  }

  // 刪除概念
  static async deleteConcept(conceptId) {
    const concept = await this.getConcept(conceptId);
    if (!concept) {
      throw new Error(`Concept not found: ${conceptId}`);
    }

    // 刪除概念文件
    const conceptFile = path.join(this.CONCEPTS_DIR, `${concept.name}.json`);
    await fs.unlink(conceptFile);

    // 從索引中移除
    const index = await this.readIndex();
    index.concepts = index.concepts.filter((c) => c.id !== conceptId);
    index.total_concepts = index.concepts.length;
    await this.updateIndex(index);

    console.log(chalk.red(`🗑️ Deleted concept: ${concept.name}`));
  }

  // 統計信息
  static async getStats() {
    try {
      const index = await this.readIndex();
      const categoryStats = {};

      for (const concept of index.concepts) {
        categoryStats[concept.category] =
          (categoryStats[concept.category] || 0) + 1;
      }

      return {
        total_concepts: index.total_concepts,
        categories: categoryStats,
        last_updated: index.last_updated,
      };
    } catch (error) {
      throw new Error(`Failed to get stats: ${error.message}`);
    }
  }
}
