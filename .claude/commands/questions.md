ultrathink
1. review the existing content in `/content/zh-TW/**/*.json`, focusing on each item’s `title`, `content`, `feedback.content_review.status`, and `feedback.content_review.comments` as learning data. Avoid repeating the same knowledge points—it’s okay to use the same topic, but make sure to extend it or present different knowledge angles.
2. Here's my questions: $ARGUMENTS
3. Use `zen` to conduct additional research on this topic (deep dive / ultrathink).
4. Use `claude` to conduct further research on the same topic (deep dive / ultrathink).
5. `Collect` and keep all reference `URLs` from Steps 1 – 3.
6. Write 1 conversational explainer article in Traditional Chinese, in the style of 得到/樊登讀書會, bearing in mind that the audience is international. You may reference a specific country as an example when appropriate, but do not assume all readers are from any single country.
7. `Categorize` the article `into one of the sub-folders` under `/content/zh-TW/*`, e.g.  
   `/content/zh-TW/daily-news`, `/content/zh-TW/ethereum`, `/content/zh-TW/macro`, `/content/zh-TW/startup`, `/content/zh-TW/ai`.
8. Use the following content schema:

```javascript
import { ContentSchema } from "./src/ContentSchema.js";

// Create new content
const content = ContentSchema.createContent(
  "2025-06-30-bitcoin-surge", // id (YYYY-MM-DD-topic-slug)
  "$CATEGORY", // category (chosen in Step 6)
  "Bitcoin機構投資者大舉進場", // title (Chinese)
  "你有沒有想過，當全世界最保守的錢...", // content (Chinese)
  ["https://bloomberg.com/", "https://www.coindesk.com/"], // references
);

// Validate content
ContentSchema.validate(content);
```
9. Save the file to `/content/zh-TW/$CATEGORY/${YYYY-MM-DD}-topic-slug.json`.