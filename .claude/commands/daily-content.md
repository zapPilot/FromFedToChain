1. Check `/guidelines/categories/daily-news.md`. Each category has specific topic selection criteria and style guidelines. Also check `/content/zh-TW/daily-news/*.json`. Be aware of the `metadata.translation_status.rejection.rejected == true` when reviewing existing files. ultrathink
2. Find valid candidates from sources.md that are relevant to $ARGUMENTS. ultrathink
3. Use zen to find more candidates related to $ARGUMENTS.
4. Use `zen` to do fact-checking
5. Use claude to do fact-checking again, ultrathink
6. keep the reference urls
6. Write 3 valid candidates as conversational Traditional Chinese explainers in the style of 得到/樊登讀書會.
7. Content format: 
```javascript
import { ContentSchema } from './src/ContentSchema.js';

// Create new content
const content = ContentSchema.createContent(
  '2025-06-30-bitcoin-surge',           // id (YYYY-MM-DD-topic-slug)
  'daily-news',                         // category
  'Bitcoin機構投資者大舉進場',            // title (Chinese)
  '你有沒有想過，當全世界最保守的錢...',   // content (Chinese)
  ['https://bloomberg.com/', 'https://www.coindesk.com/']             // references
);

// Validate content
ContentSchema.validate(content);
```
8. Save the file to `/content/zh-TW/daily-news/$ARGUMENTS-topic-slug.json`.
9. Set source_reviewed: false to indicate that human review is needed.