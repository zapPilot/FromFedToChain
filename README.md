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

# Process TTS for pending content  
npm run tts
```

## 📁 Project Structure

```
FromFedToChain/
├── scripts/
│   ├── tts-multi.js     # Multi-language TTS processing
│   ├── translate.js     # Translation workflow
│   ├── review.js        # Content review & preview
│   ├── social.js        # Social media formatting
│   └── utils/           # Future utility functions
├── content/
│   ├── zh-TW/           # Traditional Chinese content
│   │   ├── daily-news/
│   │   ├── ethereum/
│   │   └── macro/
│   └── en/              # English content
│       ├── daily-news/
│       ├── ethereum/
│       └── macro/
├── .claude/
│   └── commands/        # Claude Code commands
├── schema.json          # Content format schema
├── service-account.json # Google Cloud authentication
└── package.json
```

## 🔄 Multi-Language Content Pipeline

### 1. Content Generation (Traditional Chinese)
```bash
claude daily-content [--category daily-news|ethereum|macro]
```
- Searches current crypto/macro news
- Generates conversational Traditional Chinese content
- Saves to `content/zh-TW/{category}/` as structured JSON

### 2. Content Review 
```bash
npm run review
```
- Preview generated content before translation
- Edit JSON files directly if needed
- Mark as reviewed for translation

### 3. Translation to English
```bash
claude translate --file_id YYYY-MM-DD-topic-name
npm run translate YYYY-MM-DD-topic-name
```
- Translates reviewed zh-TW content to English
- Creates social media format (hook + full script)
- Saves to `content/en/{category}/`

### 4. Social Media Formatting
```bash
npm run social YYYY-MM-DD-topic-name --platform=twitter
```
- Formats English content for social platforms
- Supports Twitter, LinkedIn, Facebook
- Creates optimized hooks and threads

### 5. Multi-Language TTS Processing
```bash
npm run tts
```
- Processes pending TTS for all languages
- Chinese: Traditional voice (cmn-TW-Wavenet-B)
- English: US voice (en-US-Wavenet-D)
- Uploads MP3s to language-specific Drive folders

## 📄 Multi-Language Content Format

Content follows a structured JSON schema with language separation:

```json
{
  "id": "2025-06-28-crypto-mortgage-breakthrough",
  "date": "2025-06-28",
  "category": "daily-news",
  "references": ["Source 1", "Source 2"],
  "languages": {
    "zh-TW": {
      "title": "用比特幣買房子：加密貨幣房貸的突破與風險", 
      "content": "純文字內容，無 markdown 格式"
    },
    "en": {
      "title": "Bitcoin Mortgages: The Breakthrough and Risks",
      "content": "Clean English text content",
      "social_format": {
        "hook": "🚀 Attention-grabbing opening...",
        "full_script": "🚀 Hook + complete content for social media"
      }
    }
  },
  "metadata": {
    "translation_status": {
      "source_language": "zh-TW",
      "source_reviewed": true,
      "translated_to": ["en"]
    },
    "tts": {
      "zh-TW": {
        "status": "completed",
        "audio_url": "https://drive.google.com/...",
        "voice_config": {...}
      },
      "en": {
        "status": "pending",
        "audio_url": null,
        "voice_config": {...}
      }
    }
  }
}
```

### Schema Benefits:

- **Multi-Language**: Clean separation of content by language
- **TTS Precision**: Only language `content` fields processed
- **Social Ready**: Built-in social media formatting for English
- **Translation Tracking**: Status tracking across workflow
- **Scalable**: Easy to add new languages

## 🔧 Configuration

### Prerequisites

1. **Google Cloud Setup**:
   - Enable Text-to-Speech API
   - Enable Google Drive API
   - Download service account JSON → `service-account.json`

2. **Node.js Dependencies**:
   ```bash
   npm install
   ```

### Authentication

Both TTS and upload use `./service-account.json` for Google Cloud authentication.

## 🎯 Content Guidelines

- **Style**: Conversational, accessible Chinese (得到/樊登讀書會 style)
- **Focus**: Real-world relevance of crypto/macro topics
- **Length**: ~2000-3000 characters for optimal TTS
- **Tone**: Educational but engaging, avoid jargon

## 📝 Available Scripts

```bash
npm run review     # Preview pending content (zh-TW)
npm run translate  # Translate content zh-TW → en
npm run tts        # Multi-language TTS processing  
npm run social     # Format English content for social media
npm run pipeline   # Show full pipeline help
```

### Script Examples:

```bash
# Review generated Chinese content
npm run review

# Translate specific content to English  
npm run translate 2025-06-28-topic-name

# Generate social media posts
npm run social 2025-06-28-topic-name --platform=twitter

# Process TTS for all pending languages
npm run tts
```

## 🗂️ Content Categories

- **`daily-news`**: Daily crypto/macro news explainers
- **`ethereum`**: Ethereum ecosystem focused content  
- **`macro`**: Macro economics and policy analysis

## 🔗 Audio Output

Processed audio files are:
- Uploaded to Google Drive automatically
- Chinese Traditional voice (cmn-TW-Wavenet-A)
- MP3 format for broad compatibility
- Linked back to JSON metadata

---

*This pipeline transforms complex financial news into accessible Chinese audio content.*