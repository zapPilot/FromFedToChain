# Scripts

  📋 Content Schema & Structure:

  - JSON Schema: Comprehensive
  multi-language format with
  validation
  - Language-First Folders:
  content/zh-TW/ and content/en/
  structure
  - Future-Ready: Easy to add new
  languages (ja, ko, es, etc.)

  🔄 Complete Workflow:

  1. Generate (zh-TW) → claude 
  daily-content
  2. Review → npm run review
  3. Translate → claude translate 
  --file_id=... or npm run translate
  4. Social Format → npm run social 
  --platform=twitter
  5. Multi-TTS → npm run tts
  (processes all languages)

  🛠️ Key Features:

  - Translation Workflow: zh-TW
  (reviewed) → English with social
  formatting
  - Social Media Ready: Hook + full
  script for
  Twitter/LinkedIn/Facebook
  - Multi-Language TTS: Separate
  voices and Drive folders per
  language
  - Status Tracking: Translation and
  TTS status per language
  - Clean Separation:
  References/dates excluded from TTS

  🎯 Translation Integration:

  Note: The translate script
  currently uses placeholder content.
   To integrate real translation:

  1. Claude Code CLI: Use Claude's
  chat tools within the translate
  script
  2. Gemini CLI: Call gemini-cli from
   the translate script
  3. API Integration: Direct API
  calls to Claude/Gemini

  🚀 Ready for Production:

  - Schema validation ensures
  consistent format
  - Multi-language TTS with proper
  voice configs
  - Social media optimization
  built-in
  - Scalable to additional languages
  - Complete workflow automation
## Structure

```
scripts/
├── README.md          # This file
├── tts-multi.js       # Multi-language TTS processing and Google Drive upload
├── translate.js       # Translation workflow (zh-TW → en)
├── social-hook.js     # Social media hook generation
├── review.js          # Content review and preview
├── social.js          # Social media formatting
└── utils/             # Utility functions (future)
```


## Scripts Overview

### `tts-multi.js`
- Scans for JSON files with pending TTS status across all languages
- Supports multiple languages (zh-TW, en-US, ja-JP) with language-specific voices
- Uploads MP3s to language-specific Google Drive folders
- Updates JSON with completion status and audio URL per language
- Intelligently processes content (e.g., strips social hooks from English TTS)

### `review.js`
- Displays formatted preview of pending JSON content
- Shows title, date, category, references
- Highlights content that will be processed by TTS
- Helps with human review before TTS processing

## Usage

```bash
# Review pending content
npm run review

# Process TTS for pending content
npm run tts

# Full pipeline
claude daily-content
```

## Authentication

Both scripts use `./service-account.json` for Google Cloud authentication.