# Claude Code Configuration

This file contains important information for Claude Code to work effectively with this project.

## Project Context

**From Fed to Chain** is a simplified content review system for Chinese explainers about crypto/macro economics. The focus is on human review workflow and content management. The project includes both a Node.js CLI pipeline and a Flutter mobile/web app for audio playback.

## ✨ Current Architecture (2024)

**Key Principle**: Simplified content review workflow for content quality assurance.

### Node.js CLI Pipeline

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

### Flutter Mobile/Web App

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── audio_content.dart    # Content metadata model
│   └── audio_file.dart       # Audio file model
├── screens/                  # App screens
│   └── home_screen.dart      # Main screen
├── services/                 # Business logic
│   ├── audio_service.dart    # Audio playback service
│   └── content_service.dart  # Content loading service
├── themes/                   # App theming
│   └── app_theme.dart        # Dark theme configuration
└── widgets/                  # UI components
    ├── animated_background.dart
    ├── audio_item_card.dart
    ├── audio_list.dart
    ├── filter_bar.dart
    └── mini_player.dart
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

### Node.js CLI Commands

```bash
# Interactive review of all pending content
npm run review

# Auto-process content through translation → audio → social hooks
npm run pipeline

# Check all pipeline dependencies (ffmpeg, rclone, etc.)
npm run check-deps

# Run tests
npm run test

# Format code
npm run format
```

### Flutter App Commands

```bash
# Web development
flutter run -d chrome --web-browser-flag="--disable-web-security"

# Mobile development
flutter run

# Build for web
flutter build web

# Build for mobile
flutter build apk  # Android
flutter build ios  # iOS
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
- **Flutter Integration**: Flutter app provides modern UI for audio playback of generated content
- **Coexisting Dependencies**: Node.js (package.json) and Flutter (pubspec.yaml) dependencies coexist

## 🔧 Pipeline Dependencies

### Required Dependencies
- **Node.js** (v18+) - Runtime environment
- **npm** - Package manager
- **FFmpeg** - Audio processing and M3U8 conversion
- **rclone** - Cloudflare R2 uploads for M3U8 streaming

### Installation Commands
```bash
# macOS (using Homebrew)
brew install ffmpeg

# Install rclone
curl https://rclone.org/install.sh | sudo bash

# Configure rclone for Cloudflare R2
rclone config create r2 s3 \
  provider=Cloudflare \
  access_key_id=YOUR_ACCESS_KEY \
  secret_access_key=YOUR_SECRET_KEY \
  endpoint=https://YOUR_ACCOUNT_ID.r2.cloudflarestorage.com \
  region=auto
```

### Dependency Verification
```bash
# Check all dependencies
npm run check-deps

# This will verify:
# ✅ Node.js and npm versions
# ✅ FFmpeg installation and path
# ✅ rclone installation and configuration
# ✅ Overall pipeline readiness
```

### Pipeline Testing

```bash
# Test end-to-end pipeline with a content ID
npm run pipeline <content-id>

# Example: Process a specific content file
npm run pipeline 2025-07-05-blockchain-private-equity-tokenization
```

**Note**: For testing, you can manually edit content files to remove `streaming_urls` and set `status` to `reviewed` to trigger the pipeline phases.

## 📖 Current Workflow

### Content Management Workflow

1. **Content Creation**: Create source content files manually in `content/zh-TW/`
2. **Review**: Use `npm run review` to approve/reject content with feedback
3. **Pipeline Processing**: Use `npm run pipeline <content-id>` to process content through translation → audio → social hooks
4. **Testing**: Edit content files to remove `streaming_urls` and set `status: "reviewed"` for testing

### Flutter App Workflow

1. **Content Processing**: Use `npm run pipeline <content-id>` to generate content and M3U8 streaming files
2. **Audio Streaming**: Launch Flutter app with `flutter run -d chrome` or `flutter run`
3. **Browse Content**: Use modern UI to browse and stream M3U8 audio files
4. **Multi-platform**: Deploy to web, Android, or iOS for broader accessibility

This streamlined approach provides efficient content management and modern streaming audio playback.

## 🔧 Troubleshooting

### Pipeline Issues

**Problem**: `npm run pipeline` fails with "remote not configured"

**Cause**: rclone is not properly configured for Cloudflare R2 uploads

**Solutions**:
1. **Check rclone configuration**: Run `npm run check-deps` to verify rclone setup
2. **Configure rclone**: Follow the rclone configuration steps in the Pipeline Dependencies section
3. **Verify remote name**: Ensure remote name matches `REMOTE_NAME` in `CloudflareR2Service.js`

**Problem**: Pipeline skips audio/M3U8 generation

**Cause**: Content file already has `streaming_urls` populated or incorrect status

**Solutions**:
1. **Check content status**: Content must have `status: "reviewed"` to trigger pipeline
2. **Remove streaming URLs**: Delete `streaming_urls` field from content JSON file to force re-processing
3. **Manual testing**: Edit content file to remove `streaming_urls` and set `status: "reviewed"`

### Pipeline Dependencies

**Problem**: Pipeline fails with dependency errors

**Solutions**:
1. **Check dependencies**: Run `npm run check-deps` to verify all tools are installed
2. **Install missing tools**: Follow installation commands in the Pipeline Dependencies section
3. **Path issues**: Ensure ffmpeg and rclone are in your system PATH

### Content Generation Issues

**Problem**: Audio or M3U8 files not generated

**Solutions**:
1. **Check language configuration**: Verify language is enabled in `config/languages.js`
2. **Verify content status**: Content must be in correct status for each pipeline phase
3. **Check service accounts**: Ensure Google Cloud TTS credentials are configured

---

_Last updated: 2025-07-16 - Simplified pipeline-focused workflow_
