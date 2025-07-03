# Claude Code Configuration

This file contains important information for Claude Code to work effectively with this project.

## Project Context

**From Fed to Chain** is a simplified daily content pipeline that creates conversational Chinese explainers about crypto/macro economics in the style of 得到/樊登讀書會, with full automation for translation, TTS, and social media publishing.

## ✨ Simplified Architecture (2024)

**Key Principle**: Human review is the bottleneck (5 articles/day), so we optimize for maintainability over performance.

```
src/
├── cli.js               # Unified CLI for all operations
├── ContentManager.js    # Simple CRUD for single-file content
└── services/
    ├── TranslationService.js  # Claude-based translation
    ├── AudioService.js        # Google TTS generation
    ├── SocialService.js       # Social hook generation
    └── automation/
        ├── SpotifyUploader.js    # Playwright Spotify automation
        └── SocialPoster.js       # Playwright social media automation

content/                 # Nested structure by language and category
├── zh-TW/               # Source language (Traditional Chinese)
│   ├── daily-news/
│   │   └── 2025-06-30-article-id.json
│   ├── ethereum/
│   └── macro/
├── en-US/               # English translations
│   ├── daily-news/
│   │   └── 2025-06-30-article-id.json
│   └── ...
└── ja-JP/               # Japanese translations
    └── ...

audio/                   # Audio files only
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
  "feedback": { "content_review": null, "ai_outputs": {}, "performance_metrics": {} },
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
  "feedback": { "ai_outputs": { "translation": {...} } },
  "updated_at": "2025-06-30T15:00:00Z"
}
```

## 🚀 CLI Commands

### Content Management
```bash
# Create new content
npm run content create 2025-06-30-bitcoin-news daily-news

# List all content (or filter by status)
npm run content list
npm run content list draft

# Review content (approve for translation)
npm run content review 2025-06-30-bitcoin-news

# Check pipeline status
npm run content status
```

### Processing Pipeline
```bash
# Translate to all languages (en-US, ja-JP)
npm run translate 2025-06-30-bitcoin-news

# Generate audio for all languages
npm run audio 2025-06-30-bitcoin-news

# Generate social hooks for all languages
npm run social 2025-06-30-bitcoin-news
```

### Manual Publishing
After the content pipeline completes (review → translate → audio → social), content is ready for manual publishing:

- **Audio Files**: Located in `/audio/{language}/{category}/{id}.wav`
- **Social Hooks**: Generated and stored in content files for easy copy-paste
- **Manual Upload**: Upload audio files to your preferred podcast platform
- **Manual Posting**: Use generated social hooks to post on your preferred platforms

### Authentication
- Uses `./service-account.json` for Google Cloud (TTS and Translation)

## 📁 File Structure

### Content Files
- **Location**: `/content/{language}/{category}/{id}.json`
- **Format**: Single JSON per language with content and metadata
- **Status**: Tracked in `status` field (draft → reviewed → translated → audio → social)
- **Languages**: zh-TW (source), en-US, ja-JP

### Audio Files
- **Location**: `/audio/{language}/{id}.wav`
- **Format**: WAV files for podcast upload
- **Generated**: Google Cloud TTS

### Configuration
- **Languages**: English (en-US), Japanese (ja-JP), Source (zh-TW)
- **Categories**: daily-news, ethereum, macro
- **TTS**: Chinese Traditional (cmn-TW-Wavenet-B)

## 🔧 Simplified Services

### ContentManager
- Single-file CRUD operations
- Status management (draft → reviewed → translated → audio → social)
- No complex metadata or file scanning

### TranslationService  
- Claude-based translation via CLI
- Maintains conversational style
- Processes one file at a time

### AudioService
- Google Cloud TTS generation
- Saves directly to audio directory
- Updates content file with audio path

### SocialService
- Claude-based social hook generation
- Platform-agnostic format (180 chars)
- Stored directly in content file

## 🎯 Design Principles

1. **Human Review Bottleneck**: All optimizations focus on maintainability, not speed
2. **Language Separation**: One file per language, clear separation of concerns
3. **Simple State**: Linear status progression, no complex metadata
4. **Manual Triggers**: No automatic processing, human-controlled workflow  
5. **Browser Automation**: Playwright for platforms without APIs

## 🚨 Important Notes

- **No Backfilling**: Schema redesigned from scratch
- **Manual Login**: Social platforms require browser-based authentication
- **Rate Limiting**: 2-second delays between social posts
- **Error Handling**: Failed operations logged, manual retry required
- **File Paths**: Always use absolute paths, no relative references

## 📖 Typical Workflow

1. **Create**: `npm run content create 2025-06-30-topic`
2. **Edit**: Manually edit the JSON file with actual content
3. **Review**: `npm run content review 2025-06-30-topic`
4. **Translate**: `npm run translate 2025-06-30-topic`
5. **Audio**: `npm run audio 2025-06-30-topic`
6. **Social**: `npm run social 2025-06-30-topic`
7. **Manual Publish**: Upload audio files and post social hooks manually

This simplified approach removes all performance optimizations and complex state management, focusing on clarity and ease of maintenance for a human-bottlenecked workflow.

---

_Last updated: 2025-06-30 - Simplified architecture focusing on maintainability over performance_