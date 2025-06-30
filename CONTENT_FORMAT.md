# Content Format Guide

This document explains the content format for Claude custom commands and external tools.

## Schema Location

**Single Source of Truth**: `/src/ContentSchema.js` - Content structure definition and utilities

## Quick Content Creation

```javascript
import { ContentSchema } from './src/ContentSchema.js';

// Create new content
const content = ContentSchema.createContent(
  '2025-06-30-bitcoin-surge',           // id (YYYY-MM-DD-topic-slug)
  'daily-news',                         // category
  'Bitcoin機構投資者大舉進場',            // title (Chinese)
  '你有沒有想過，當全世界最保守的錢...',   // content (Chinese)
  ['Bloomberg', 'CoinDesk']             // references
);

// Validate content
ContentSchema.validate(content);
```

## Content Structure

```json
{
  "id": "2025-06-30-bitcoin-surge",
  "status": "draft",
  "category": "daily-news",
  "date": "2025-06-30",
  "source": {
    "title": "Bitcoin機構投資者大舉進場",
    "content": "你有沒有想過，當全世界最保守的錢都開始瘋狂湧入比特幣時...",
    "references": ["Bloomberg", "CoinDesk"]
  },
  "translations": {
    "en-US": {
      "title": "Bitcoin Institutional Investor Surge",
      "content": "Have you ever wondered what it means when...",
      "audio_file": null,
      "social_hook": null
    }
  },
  "feedback": {
    "content_review": null,
    "ai_outputs": {
      "translations": {},
      "audio": {},
      "social_hooks": {}
    },
    "performance_metrics": {
      "spotify": {},
      "social_platforms": {}
    }
  },
  "updated_at": "2025-06-30T10:00:00.000Z"
}
```

## Workflow States

```
draft → reviewed → translated → audio → social → published
```

## Supported Values

**Categories**: `daily-news`, `ethereum`, `macro`  
**Languages**: `en-US`, `ja-JP`  
**Platforms**: `twitter`, `threads`, `farcaster`, `debank`

## For Claude Custom Commands

When creating content in `.claude/commands/`, use this format:

```javascript
// Save to: /content/{id}.json
import { ContentSchema } from '../src/ContentSchema.js';

const content = ContentSchema.createContent(
  generateId(),      // Your ID generation logic
  category,          // From command parameters
  title,             // Generated Chinese title
  content,           // Generated Chinese content
  references         // Source references
);

await fs.writeFile(`content/${content.id}.json`, JSON.stringify(content, null, 2));
```

## Validation

Always validate content before saving:

```javascript
try {
  ContentSchema.validate(content);
  console.log('✅ Content valid');
} catch (error) {
  console.error('❌ Invalid content:', error.message);
}
```

## Benefits of This Approach

✅ **True Single Source of Truth** - Content structure defined once in JavaScript  
✅ **Easy for Claude Commands** - Simple import and method calls, no external dependencies  
✅ **Validation** - Built-in validation with clear error messages  
✅ **Self-Documenting** - The code IS the documentation  
✅ **No Dependencies** - Pure JavaScript, no schema parsing libraries needed