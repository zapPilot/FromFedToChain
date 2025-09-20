import chalk from "chalk";
import { KnowledgeIndexManager } from "./KnowledgeIndexManager.js";

/**
 * ConceptCli - 概念管理的 CLI 界面
 */
export class ConceptCli {
  // 顯示概念管理幫助
  static showHelp() {
    console.log(chalk.blue.bold("🧠 Knowledge Concepts Management"));
    console.log(chalk.gray("=".repeat(50)));
    console.log("");
    console.log(chalk.yellow("Available commands:"));
    console.log(
      chalk.cyan("  concepts list [category]       ") +
        "List all concepts or by category",
    );
    console.log(
      chalk.cyan("  concepts search <query>        ") +
        "Search concepts by name or content",
    );
    console.log(
      chalk.cyan("  concepts show <concept-id>     ") +
        "Show detailed concept information",
    );
    console.log(
      chalk.cyan("  concepts references <concept-id>") +
        "Show articles that use this concept",
    );
    console.log(
      chalk.cyan("  concepts stats                ") +
        "Show knowledge base statistics",
    );
    console.log("");
    console.log(chalk.gray("Examples:"));
    console.log(chalk.gray("  npm run concepts list 經濟學"));
    console.log(chalk.gray("  npm run concepts search '確定性溢價'"));
    console.log(chalk.gray("  npm run concepts show certainty-premium"));
    console.log(chalk.gray("  npm run concepts references network-effect"));
  }

  // 處理概念相關命令
  static async handleCommand(args) {
    await KnowledgeIndexManager.initialize();

    const subCommand = args[0];

    switch (subCommand) {
      case "list":
        await this.listConcepts(args[1]);
        break;
      case "search":
        await this.searchConcepts(args[1]);
        break;
      case "show":
        await this.showConcept(args[1]);
        break;
      case "references":
        await this.showReferences(args[1]);
        break;
      case "stats":
        await this.showStats();
        break;
      default:
        this.showHelp();
    }
  }

  // 列出概念
  static async listConcepts(category = null) {
    try {
      const concepts = await KnowledgeIndexManager.listConcepts(category);

      if (concepts.length === 0) {
        console.log(
          chalk.yellow(
            `📝 No concepts found${category ? ` in category "${category}"` : ""}`,
          ),
        );
        return;
      }

      console.log(
        chalk.blue.bold(
          `📚 Knowledge Concepts${category ? ` - ${category}` : ""}`,
        ),
      );
      console.log(chalk.gray("=".repeat(50)));

      // 按類別分組
      const conceptsByCategory = {};
      for (const concept of concepts) {
        if (!conceptsByCategory[concept.category]) {
          conceptsByCategory[concept.category] = [];
        }
        conceptsByCategory[concept.category].push(concept);
      }

      for (const [cat, conceptList] of Object.entries(conceptsByCategory)) {
        console.log(chalk.cyan.bold(`\n${cat}:`));
        for (const concept of conceptList) {
          console.log(
            chalk.cyan(`  • ${concept.name} `) + chalk.gray(`(${concept.id})`),
          );
        }
      }
    } catch (error) {
      console.error(chalk.red("❌ Error listing concepts:"), error.message);
    }
  }

  // 搜尋概念
  static async searchConcepts(query) {
    if (!query) {
      console.log(chalk.red("❌ Please provide a search query"));
      return;
    }

    try {
      const results = await KnowledgeIndexManager.searchConcepts(query, {
        fuzzy: true,
        includeContext: true,
      });

      if (results.length === 0) {
        console.log(chalk.yellow(`🔍 No concepts found for "${query}"`));
        return;
      }

      console.log(chalk.blue.bold(`🔍 Search Results for "${query}"`));
      console.log(chalk.gray("=".repeat(50)));

      for (const concept of results) {
        console.log("");
        console.log(
          chalk.cyan.bold(`${concept.name} `) + chalk.gray(`(${concept.id})`),
        );
        console.log(chalk.gray(`Category: ${concept.category}`));
        console.log(chalk.white(`Definition: ${concept.definition}`));

        if (concept.referenced_in.length > 0) {
          console.log(
            chalk.gray(
              `Referenced in: ${concept.referenced_in.length} article(s)`,
            ),
          );
        }
      }
    } catch (error) {
      console.error(chalk.red("❌ Search failed:"), error.message);
    }
  }

  // 顯示概念詳情
  static async showConcept(conceptId) {
    if (!conceptId) {
      console.log(chalk.red("❌ Please provide a concept ID"));
      return;
    }

    try {
      const concept = await KnowledgeIndexManager.getConcept(conceptId);

      if (!concept) {
        console.log(chalk.yellow(`📝 Concept not found: ${conceptId}`));
        return;
      }

      console.log(chalk.blue.bold(`📖 ${concept.name}`));
      console.log(chalk.gray("=".repeat(50)));
      console.log("");

      console.log(chalk.cyan("ID: ") + chalk.white(concept.id));
      console.log(chalk.cyan("Category: ") + chalk.white(concept.category));
      console.log(chalk.cyan("Definition: ") + chalk.white(concept.definition));

      if (concept.context) {
        console.log(chalk.cyan("Context: ") + chalk.white(concept.context));
      }

      if (concept.examples && concept.examples.length > 0) {
        console.log(chalk.cyan("Examples:"));
        for (const example of concept.examples) {
          console.log(chalk.gray(`  • ${example}`));
        }
      }

      if (concept.tags && concept.tags.length > 0) {
        console.log(chalk.cyan("Tags: ") + chalk.gray(concept.tags.join(", ")));
      }

      if (concept.related_concepts && concept.related_concepts.length > 0) {
        console.log(
          chalk.cyan("Related Concepts: ") +
            chalk.gray(concept.related_concepts.join(", ")),
        );
      }

      if (concept.referenced_in && concept.referenced_in.length > 0) {
        console.log(chalk.cyan("Referenced in:"));
        for (const articleId of concept.referenced_in) {
          console.log(chalk.gray(`  • ${articleId}`));
        }
      }

      console.log("");
      console.log(
        chalk.gray(
          `First introduced: ${concept.first_introduced || "Unknown"}`,
        ),
      );
      console.log(chalk.gray(`Created: ${concept.created_at}`));
      console.log(chalk.gray(`Updated: ${concept.updated_at}`));
    } catch (error) {
      console.error(chalk.red("❌ Error showing concept:"), error.message);
    }
  }

  // 顯示概念引用
  static async showReferences(conceptId) {
    if (!conceptId) {
      console.log(chalk.red("❌ Please provide a concept ID"));
      return;
    }

    try {
      const concept = await KnowledgeIndexManager.getConcept(conceptId);

      if (!concept) {
        console.log(chalk.yellow(`📝 Concept not found: ${conceptId}`));
        return;
      }

      const references = concept.referenced_in || [];

      console.log(chalk.blue.bold(`📎 References for "${concept.name}"`));
      console.log(chalk.gray("=".repeat(50)));

      if (references.length === 0) {
        console.log(
          chalk.yellow("📝 This concept is not referenced in any articles yet"),
        );
        return;
      }

      console.log(chalk.cyan(`Found ${references.length} reference(s):`));
      console.log("");

      for (const articleId of references) {
        console.log(chalk.cyan(`• ${articleId}`));
      }
    } catch (error) {
      console.error(chalk.red("❌ Error showing references:"), error.message);
    }
  }

  // 顯示統計信息
  static async showStats() {
    try {
      const stats = await KnowledgeIndexManager.getStats();

      console.log(chalk.blue.bold("📊 Knowledge Base Statistics"));
      console.log(chalk.gray("=".repeat(50)));
      console.log("");

      console.log(
        chalk.cyan("Total Concepts: ") + chalk.white(stats.total_concepts),
      );
      console.log("");

      console.log(chalk.cyan("By Category:"));
      for (const [category, count] of Object.entries(stats.categories)) {
        console.log(chalk.gray(`  ${category}: `) + chalk.white(count));
      }

      console.log("");
      console.log(chalk.gray(`Last Updated: ${stats.last_updated}`));
    } catch (error) {
      console.error(chalk.red("❌ Error showing statistics:"), error.message);
    }
  }
}
