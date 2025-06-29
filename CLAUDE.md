# Claude Code Configuration

This file contains important information for Claude Code to work effectively with this project.

## Project Context

**From Fed to Chain** is a daily content pipeline that creates conversational Chinese explainers about crypto/macro economics in the style of 得到/樊登讀書會.

## Key Information

### Content Format
- **Storage**: JSON format (not Markdown)
- **Structure**: Structured data with clear separation of metadata and content
- **TTS Processing**: Only the `content` field is converted to speech
- **Location**: `/content/{category}/YYYY-MM-DD-topic-name.json`

### Project Architecture  

**Simplified Architecture (New - Recommended)**
```
lib/
├── core/                # Core business logic
│   ├── ContentManager.js    # Content operations & file scanning
│   ├── ReviewService.js     # Content review workflow
│   ├── TranslationService.js # Translation logic
│   └── TTSService.js        # TTS generation & upload
├── utils/               # Shared utilities
│   ├── FileUtils.js         # File operations
│   ├── Logger.js            # Consistent logging  
│   └── ProgressBar.js       # Progress indicators
└── ui/
    └── CLI.js               # Command line interface

cli.js                   # Main CLI entry point
scripts/
├── review-simple.js     # Simplified review wrapper
├── translate-simple.js  # Simplified translation wrapper  
└── tts-simple.js        # Simplified TTS wrapper
```

**Legacy Architecture (Complex - Still Available)**
```
scripts/
├── tts-multi.js         # Multi-language TTS processing & Google Drive upload
├── review.js            # Content review & preview
├── translate.js         # Single file translation
├── workflow-translate.js # Translation workflow management
└── config/
    └── languages.js     # Shared language/TTS configuration
```

### Important Commands
```bash
# Content generation (primary workflow)
claude daily-content [--category daily-news|ethereum|macro]

# Unified pipeline (recommended)
npm run review                            # Review generated content
npm run pipeline                          # Full pipeline: translate → tts → social (mock translation)
npm run pipeline:gcp                      # Full pipeline with Google Cloud Translation API
npm run pipeline:status                   # Show pipeline progress
npm run pipeline:retry                    # Retry failed tasks

# Individual workflow commands (legacy)
npm run translate                         # Translate all to ALL languages (en-US, ja-JP)
npm run translate --target=en-US         # Translate all to English only  
npm run translate-status                  # Show translation status
npm run tts                               # Process TTS for all pending content

# Legacy commands (complex architecture - still available)
npm run legacy-review                     # Old review script
npm run legacy-translate                  # Old translation workflow  
npm run legacy-tts                        # Old TTS script
```

### Claude Code Custom Commands

#### Translation Commands
Use these commands to manage translation workflow via Claude Code:

```bash
# Show translation status and available files
claude translate-status

# Translate specific file to English (default)
claude translate <file_id>

# Translate to specific language
claude translate <file_id> --target=ja-JP

# Translate all ready files to English
claude translate-all

# Translate all ready files to specific language  
claude translate-all --target=ja-JP

# Show available target languages
claude translate-languages
```

**Supported Languages:**
- `en-US`: English (United States)
- `ja-JP`: Japanese
- `zh-TW`: Traditional Chinese (source language)

**Translation Process:**
1. Source content must be reviewed first (`npm run review`)
2. Uses Claude Code or Gemini CLI for AI translation
3. Preserves conversational style and crypto/finance terminology
4. Creates structured JSON files ready for TTS processing

### Authentication
- Uses `./service-account.json` for Google Cloud authentication
- Required for TTS processing and Translation API (if enabled)

### Content Categories
- `daily-news`: Daily crypto/macro news explainers
- `ethereum`: Ethereum ecosystem focused content
- `macro`: Macro economics and policy analysis

### File Naming Convention
- Format: `YYYY-MM-DD-topic-name.json`
- Location: `/content/{category}/`
- Example: `/content/daily-news/2025-06-28-crypto-mortgage-breakthrough.json`

### JSON Structure
```json
{
  "title": "文章標題",
  "date": "2025-06-28",
  "content": "純文字內容，無 markdown 格式",
  "references": ["參考資料"],
  "metadata": {
    "category": "daily-news",
    "tts_status": "pending|completed",
    "audio_path": "Local file path or null"
  }
}
```

### Audio Management
```bash
npm run audio list                        # List all audio files
npm run audio stats                       # Show storage statistics
npm run audio list en-US                  # List files for specific language
npm run audio list en-US daily-news       # List files for language + category
```

### Testing Commands
When testing the pipeline, always run:
1. `npm run review` - to preview content
2. `npm run pipeline` - to test full pipeline

### Dependencies
- `@google-cloud/text-to-speech`: TTS processing
- `@google-cloud/translate`: Translation API (optional)
- `chalk`: Colorized terminal output

### Important Notes
- Content should be in conversational Chinese style
- Focus on real-world relevance of crypto/macro topics
- TTS voice: Chinese Traditional (cmn-TW-Wavenet-B)
- Audio files stored locally in `./audio/` directory
- No Notion integration (removed legacy code)

## Troubleshooting

### Common Issues
1. **Authentication**: Ensure `service-account.json` exists and is valid
2. **Dependencies**: Run `npm install` if scripts fail
3. **Permissions**: Google Cloud service account needs TTS and Drive permissions

### File Structure Validation
If scripts fail, verify:
- JSON files are valid format
- `tts_status` field exists in metadata
- Content field contains actual text content

---

*This configuration helps Claude Code understand the project structure and workflow.*