# Claude Code Configuration

This file contains important information for Claude Code to work effectively with this project.

## Project Context

**From Fed to Chain** is a simplified content review system for Chinese explainers about crypto/macro economics. The focus is on human review workflow and content management.

## ✨ Current Architecture (2024)

**Key Principle**: Simplified content review workflow for content quality assurance.

```
src/
├── cli.js               # CLI for review operations
├── ContentManager.js    # Content CRUD operations with nested file structure
└── ContentSchema.js     # Schema validation and content structure

content/                 # Nested structure by language and category
├── zh-TW/               # Source language (Traditional Chinese)
│   ├── daily-news/
│   │   └── 2025-06-30-article-id.json
│   ├── ethereum/
│   ├── macro/
│   └── startup/
├── en-US/               # English translations (if available)
│   ├── daily-news/
│   │   └── 2025-06-30-article-id.json
│   └── ...
└── ja-JP/               # Japanese translations (if available)
    └── ...

audio/                   # Audio files (if generated)
├── en-US/2025-06-30-article-id.wav
└── ja-JP/2025-06-30-article-id.wav
```

## 📋 Content Schema

**Each file contains content in one language:**

**Source file** (`content/zh-TW/daily-news/2025-06-30-bitcoin-news.json`):

```json
{
  "id": "2025-06-30-bitcoin-news",
  "status": "draft",
  "category": "daily-news",
  "date": "2025-06-30",
  "language": "zh-TW",
  "title": "比特幣突破新高...",
  "content": "你有沒有想過...",
  "references": ["資料來源1", "資料來源2"],
  "audio_file": null,
  "social_hook": null,
  "feedback": {
    "content_review": null
  },
  "updated_at": "2025-06-30T14:00:00Z"
}
```

**Translation file** (`content/en-US/daily-news/2025-06-30-bitcoin-news.json`):

```json
{
  "id": "2025-06-30-bitcoin-news",
  "status": "translated",
  "category": "daily-news",
  "date": "2025-06-30",
  "language": "en-US",
  "title": "Bitcoin Breaks New Highs...",
  "content": "Have you ever wondered...",
  "references": ["Source 1", "Source 2"],
  "audio_file": "audio/en-US/2025-06-30-bitcoin-news.wav",
  "social_hook": "🚀 Bitcoin breaks new highs...",
  "feedback": { "content_review": null },
  "updated_at": "2025-06-30T15:00:00Z"
}
```

## 🚀 CLI Commands

### Available Commands

```bash
# Interactive review of all pending content
npm run review

# Run tests
npm run test

# Format code
npm run format
```

### Review Workflow

```bash
# Start interactive review session
npm run review

# During review, use these controls:
# [a]ccept    - Approve content (optional feedback)
# [r]eject    - Reject with required feedback
# [s]kip      - Skip this content
# [q]uit      - Exit review session
```


## 📁 File Structure

### Content Files

- **Location**: `/content/{language}/{category}/{id}.json`
- **Format**: Single JSON per language with content and metadata
- **Status**: Tracked in `status` field (draft → reviewed → published)
- **Languages**: zh-TW (source), en-US, ja-JP

### Audio Files

- **Location**: `/audio/{language}/{id}.wav`
- **Format**: WAV files for podcast upload
- **Generated**: Google Cloud TTS

### Configuration

- **Languages**: English (en-US), Japanese (ja-JP), Source (zh-TW)
- **Categories**: daily-news, ethereum, macro, startup, ai
- **Status Flow**: draft → reviewed (via review) → (manual processing)

## 🔧 Core Components

### ContentManager

- Single-file CRUD operations with nested directory structure
- Status management and content lifecycle
- Feedback collection for review workflow
- Schema validation and content integrity

### ContentSchema

- Content structure validation
- Schema constants and utilities
- Example content generation
- Language and category management

### CLI (cli.js)

- Interactive content review workflow
- Error handling and user feedback

## 🎯 Design Principles

1. **Human Review Focus**: Optimized for content quality review and feedback collection
2. **Language Separation**: One file per language, clear separation of concerns
3. **Simple State**: Linear status progression with clear validation
4. **Review Workflow**: Streamlined feedback collection for content quality assurance
5. **Maintainability**: Clean code structure prioritizing readability over performance

## 🚨 Important Notes

- **Review-Focused**: System designed primarily for content review and feedback
- **Content Management**: Reviewer feedback collected for quality assurance
- **File Paths**: Always use absolute paths, no relative references
- **Schema Validation**: Content validated against schema on read/write operations
- **Nested Structure**: Content organized by language/category for clarity

## 📖 Current Workflow

1. **Content Creation**: Create source content files manually in `content/zh-TW/`
2. **Review**: Use `npm run review` to approve/reject content with feedback
3. **Content Management**: Review feedback is stored for quality tracking
4. **Future Processing**: Additional translation/audio features can be added as needed

This simplified approach focuses on content review quality and content management, providing a solid foundation for future feature expansion.

---

_Last updated: 2025-07-05 - Content review and management system_
