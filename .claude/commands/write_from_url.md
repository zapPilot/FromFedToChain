1. review the existing content in `/content/zh-TW/**/*.json`, focusing on each item's `title`, `content`, `feedback.content_review.status`, and `feedback.content_review.comments` as learning data. Avoid repeating the same knowledge points—it's okay to use the same topic, but make sure to extend it or present different knowledge angles.

1.5. **Knowledge Concepts Research**: Before writing, research existing concepts:

- Review existing content files in `/content/zh-TW/` to find related concepts
- Identify which concepts you can reference vs. which new concepts you may need to create
- Plan how to integrate concept references naturally into your article structure

2. Read the multiple URLs specified in `$ARGUMENTS`. Assume that readers are beginners, so use "in a nutshell" to explain this topic to them, providing some background knowledge first.
3. Use `zen` to conduct additional research on this topic (deep dive / ultrathink).
4. Use `claude` to conduct further research on the same topic (deep dive / ultrathink).
5. `Collect` and keep all reference `URLs` from Steps 1 – 3.
6. Write one conversational explainer article in Traditional Chinese. Choose the most appropriate writing framework from the guidelines/\*.md files, bearing in mind that the audience is international. You may refer to a specific country as an example when appropriate, but do not assume that all readers are from the same country. And assign the framework file name to $FRAMEWORK.

   **Knowledge Concepts Integration Guidelines:**
   - For **existing concepts**: Use brief mentions with natural integration, e.g., "這就是我們之前討論過的確定性溢價概念"
   - For **new concepts**: Provide full explanations using the 【】bracket format for key terms, e.g., "【確定性溢價】指人們願意為降低不確定性而支付的額外費用"
   - Identify 3-5 key concepts that should be tracked for this article
   - Ensure concept usage aligns with our established definitions from the knowledge base

7. `Categorize` the article `into one of the sub-folders` under `/content/zh-TW/*`, e.g.
   `/content/zh-TW/daily-news`, `/content/zh-TW/ethereum`, `/content/zh-TW/macro`, `/content/zh-TW/startup`, `/content/zh-TW/ai`.

8. **Knowledge Concepts Tagging**: After writing, identify and tag the concepts used:
   - List all key concepts referenced or introduced in your article
   - For existing concepts: Use their exact concept IDs (e.g., "certainty-premium", "network-effect")
   - For new concepts: Note which ones should be added to the knowledge base later
   - This list will be added to the `knowledge_concepts_used` field in the content schema

9. Use the following content schema:

```javascript
import { ContentSchema } from "./src/ContentSchema.js";

// Create new content
const content = ContentSchema.createContent(
  "2025-06-30-bitcoin-surge", // id (YYYY-MM-DD-topic-slug)
  "$CATEGORY", // category (chosen in Step 7)
  "zh-TW", // language
  "Bitcoin機構投資者大舉進場", // title (Chinese)
  "你有沒有想過，當全世界最保守的錢...", // content (Chinese)
  ["https://bloomberg.com/", "https://www.coindesk.com/"], // references
  "$FRAMEWORK", // framework (chosen in step 6, e.g. 解讀分析式風格.md)
);

// Add knowledge concepts used in this article (from Step 8)
content.knowledge_concepts_used = [
  "certainty-premium", // 確定性溢價
  "network-effect", // 網絡效應
  "institutional-adoption", // 機構採用 (if this is a new concept, note for later addition)
];

// Validate content
ContentSchema.validate(content);
```

10. Save the file to `/content/zh-TW/$CATEGORY/${YYYY-MM-DD}-topic-slug.json`.

## Knowledge Concepts Best Practices

### When to Reference Existing Concepts

- Review existing content files to see which articles already explain a concept
- If a concept was thoroughly explained in a recent article (within 5-10 articles), simply reference it: "正如我們在討論ETHGas時提到的確定性溢價概念"
- If it's been a while or the context is different, provide a brief refresher before diving deeper

### When to Create New Concepts

- The concept is central to understanding the current topic
- It's likely to be referenced in future articles
- It represents a fundamental principle or framework that transcends individual projects
- Examples of good concepts: "確定性溢價", "網絡效應", "監管套利", "代際財富轉移"

### Concept Naming Conventions

- Use English IDs with hyphens: "certainty-premium", "regulatory-arbitrage"
- Keep names descriptive but concise
- Check existing concepts first to avoid duplication

### After Publishing

- For new concepts introduced in your article, consider adding them to the knowledge base using the concept management tools
- This ensures future articles can reference them properly and maintain knowledge continuity across the content pipeline
