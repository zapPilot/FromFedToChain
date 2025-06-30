# From Fed to Chain

Daily content pipeline for creating conversational Chinese explainers about crypto/macro economics in the style of 得到/樊登讀書會.

## 🚀 Quick Start

```bash
# Install dependencies
npm install

# Generate daily content  
claude daily-content

# Review pending content
npm run review

# Run full pipeline: Translation → TTS → Social Hooks
npm run pipeline
```

## 📁 Project Structure

```
FromFedToChain/
├── lib/
│   ├── core/                # Core business logic
│   │   ├── ContentManager.js    # Content operations & file scanning
│   │   ├── ReviewService.js     # Content review workflow
│   │   ├── TranslationService.js # Translation logic
│   │   ├── TTSService.js        # TTS generation & upload
│   │   └── SocialMediaService.js # Social media hook generation
│   ├── services/            # Supporting services
│   │   ├── AudioStorage.js      # Audio file management
│   │   ├── GoogleTTS.js         # Google Cloud TTS
│   │   └── MockTranslation.js   # Mock translation service
│   ├── utils/               # Shared utilities
│   │   ├── FileUtils.js         # File operations
│   │   ├── Logger.js            # Consistent logging
│   │   └── ProgressBar.js       # Progress indicators
│   └── workflows/
│       └── ContentPipeline.js   # Main pipeline orchestration
├── scripts/                 # Essential scripts only
│   ├── pipeline.js              # Main pipeline script  
│   ├── review.js                # Content review
│   └── audio-manager.js         # Audio file management
├── config/
│   ├── languages.js             # Language & TTS configuration
│   └── social-media.js          # Social media platform settings
├── content/                 # Content by language
│   ├── zh-TW/               # Traditional Chinese (source)
│   ├── en-US/               # English translations
│   └── ja-JP/               # Japanese translations
├── audio/                   # Generated audio files
│   ├── zh-TW/
│   ├── en-US/
│   └── ja-JP/
└── social/                  # Generated social media hooks
    ├── en-US/
    │   ├── twitter/
    │   ├── linkedin/
    │   └── facebook/
    └── ja-JP/
```

## 🔄 Streamlined Workflow

### Single Command Pipeline

```bash
# Run complete pipeline: Translation → TTS → Social Hooks
npm run pipeline

# Optional: Use Google Cloud Translation API instead of mock
npm run pipeline:gcp

# Check pipeline status
npm run pipeline:status

# Retry failed tasks
npm run pipeline:retry
```

The pipeline automatically:

1. **Translates** reviewed Chinese content to all target languages (en-US, ja-JP)
2. **Generates TTS** audio files for all translated content
3. **Creates social media hooks** using `claude -p` command for engaging content
4. **Auto-creates** folder structures as needed (`social/{language}/{platform}/{category}/`)

### When to Use Reset

```bash
npm run pipeline:reset      # Reset when pipeline gets stuck
```

**Reset needed when:**
- Pipeline stuck due to API rate limits
- Corrupted state/authentication issues  
- Want to reprocess everything from scratch

## 📱 Social Media Hook Generation

### Integrated with Pipeline

Social media hooks are automatically generated as part of `npm run pipeline`:

- **AI-Generated**: Uses `claude -p` for dynamic, context-aware hooks
- **Multi-Platform**: Optimized for Twitter, LinkedIn, Facebook, Instagram
- **Multi-Language**: Supports all translated languages with platform preferences
- **Auto-Folder Creation**: Creates `social/{language}/{platform}/{category}/` structure

### Configuration

Language and platform preferences in `config/social-media.js`:

```javascript
// Example: English supports all platforms, Japanese only Twitter/Facebook
SOCIAL_LANGUAGES = {
  'en-US': {
    enabled: true,
    platforms: ['twitter', 'linkedin', 'facebook', 'instagram'],
    defaultPlatform: 'twitter'
  },
  'ja-JP': {
    enabled: true,
    platforms: ['twitter', 'facebook'],
    defaultPlatform: 'twitter'
  }
}
```

### Output Structure

```
social/
├── en-US/
│   ├── twitter/
│   │   ├── daily-news/
│   │   │   ├── 2025-06-29-crypto-news.txt      # Hook text
│   │   │   └── 2025-06-29-crypto-news.json     # Metadata
│   │   ├── ethereum/
│   │   └── macro/
│   ├── linkedin/
│   └── facebook/
└── ja-JP/
    ├── twitter/
    └── facebook/
```

## 📄 Content Format

Content follows a structured JSON schema with language separation:

```json
{
  "id": "2025-06-29-crypto-news",
  "category": "daily-news",
  "language": {
    "zh-TW": {
      "title": "加密貨幣新聞標題",
      "content": "純文字內容，無markdown格式"
    },
    "en-US": {
      "title": "Crypto News Title",
      "content": "Plain text content, no markdown"
    }
  },
  "social_hooks": {
    "primary": "🚨 Breaking: Major crypto development...",
    "platforms": {
      "twitter": "🚨 Breaking: Major crypto development... #Crypto #Bitcoin",
      "linkedin": "Breaking: Major crypto development that will change finance...",
      "facebook": "Breaking: Major crypto development...\n\nWhat do you think?"
    },
    "generated_at": "2025-06-29T10:00:00Z",
    "language": "en-US"
  },
  "metadata": {
    "translation_status": { "source_reviewed": true },
    "tts": {
      "zh-TW": { "status": "completed", "audio_path": "./audio/zh-TW/..." },
      "en-US": { "status": "pending" }
    }
  }
}
```

## 🔧 Configuration

### Prerequisites

1. **Google Cloud Setup**:
   - Enable Text-to-Speech API
   - Download service account JSON → `service-account.json`

2. **Claude Code CLI**:
   ```bash
   npm install -g claude-code
   ```

3. **Node.js Dependencies**:
   ```bash
   npm install
   ```

### Authentication

- Google Cloud: `./service-account.json`
- Claude: Follow claude-code setup instructions

## 🎯 Content Guidelines

- **Style**: Conversational, accessible Chinese (得到/樊登讀書會 style)
- **Focus**: Real-world relevance of crypto/macro topics
- **Length**: ~2000-3000 characters for optimal TTS
- **Tone**: Educational but engaging, avoid jargon

## 📝 Essential Commands (Only 7!)

### Core Workflow
```bash
npm run review             # Review pending content
npm run pipeline           # Full pipeline (Translation → TTS → Social)
npm run pipeline:gcp       # Use Google Cloud Translation API
```

### Status & Recovery
```bash
npm run pipeline:status    # Show current pipeline status
npm run pipeline:reset     # Reset when pipeline gets stuck
```

### Utilities
```bash
npm run audio              # Audio file management (list, stats)
npm run test               # Run focused unit tests
npm run format             # Code formatting
```

## 🗂️ Content Categories

- **`daily-news`**: Daily crypto/macro news explainers
- **`ethereum`**: Ethereum ecosystem focused content  
- **`macro`**: Macro economics and policy analysis

## 🔗 Multi-Language Support

### Supported Languages

- **`zh-TW`**: Traditional Chinese (source language)
- **`en-US`**: English (full pipeline support)
- **`ja-JP`**: Japanese (full pipeline support)

### TTS Voices

- **Chinese**: `cmn-TW-Wavenet-B` (Traditional Chinese)
- **English**: `en-US-Wavenet-D` (US English)
- **Japanese**: `ja-JP-Wavenet-C` (Japanese)

## 🚀 Advanced Features

### Automatic Recovery

- **File-based State**: Pipeline uses actual file existence for state tracking
- **Graceful Interruption**: Ctrl+C safely stops pipeline, resume with same command
- **Smart Skipping**: Automatically skips completed tasks

### Social Media Intelligence

- **Context-Aware Hooks**: AI understands content and generates relevant hooks
- **Platform Optimization**: Automatic formatting for each social platform
- **Hashtag Integration**: Language and category-specific hashtag suggestions
- **Fallback System**: Works even without claude command (with basic templates)
- **Ultra-Fast Processing**: Batch optimization + smart caching = 5x speed improvement

## 🧪 Testing Strategy

### **Focused Testing Approach**
This project uses a **surgical testing strategy** - test business logic, not 3rd party APIs.

```bash
npm test                   # Run focused unit tests
```

### **What We Test**
✅ **Business Logic**: Content validation, social hook formatting  
✅ **Configuration**: Language/platform settings, schema validation  
✅ **File Operations**: JSON parsing, file structure validation  
✅ **Error Handling**: Graceful failures, data corruption prevention  

### **What We DON'T Test** 
❌ **3rd Party APIs**: Google TTS, Google Translate, Claude CLI (they own quality)  
❌ **Infrastructure**: File permissions, network connectivity, auth tokens  
❌ **Integration**: End-to-end API workflows (too complex, low value)

### **GitHub Actions**
- ✅ **Code Quality**: Prettier formatting, basic linting
- ✅ **Security**: Dependency audit, secret scanning
- ✅ **Fast Tests**: Business logic validation (< 30 seconds)
- ❌ **Heavy Testing**: No API integration testing in CI

**Philosophy**: Keep testing simple, focused, and fast. Trust external providers for their APIs.

---

_This pipeline transforms complex financial news into accessible multi-language content with engaging social media hooks._