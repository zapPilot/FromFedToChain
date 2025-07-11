1. Check `/guidelines/categories/macro.md`. Each category has specific topic selection criteria and style guidelines. Also, review the existing content in `/content/zh-TW/**/*.json`, focusing on each item’s `title`, `content`, `feedback.content_review.status`, and `feedback.content_review.comments` as learning data. Avoid repeating the same knowledge points—it’s okay to use the same topic, but make sure to extend it or present different knowledge angles.
2. Find valid candidates from sources.md that are relevant to $ARGUMENTS.
3. Use zen to find more candidates related to $ARGUMENTS.
4. Use `zen` to do fact-checking
5. Use claude to do fact-checking again, ultrathink
6. keep the reference urls
7. Write 3 candidate conversational explainer pieces in Traditional Chinese, in the style of 得到/樊登讀書會, bearing in mind that the audience is international. You may reference a specific country as an example when appropriate, but do not assume all readers are from any single country.
8. Content format:

```javascript
import { ContentSchema } from "./src/ContentSchema.js";

// Create new content
const content = ContentSchema.createContent(
  "2025-06-30-bitcoin-surge", // id (YYYY-MM-DD-topic-slug)
  "macro", // category
  "Bitcoin機構投資者大舉進場", // title (Chinese)
  "你有沒有想過，當全世界最保守的錢...", // content (Chinese)
  ["https://bloomberg.com/", "https://www.coindesk.com/"], // references
);

// Validate content
ContentSchema.validate(content);
```

9. Save the file to `/content/zh-TW/macro/$ARGUMENTS-topic-slug.json`.
ultrathink