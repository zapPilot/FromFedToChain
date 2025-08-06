# From Fed to Chain

**A comprehensive content pipeline and streaming platform for crypto/macro economics educational content**

From Fed to Chain is a dual-platform system that combines a powerful Node.js CLI pipeline for content management with a modern Flutter mobile/web app for audio streaming. The platform creates conversational Chinese explainers about cryptocurrency and macro economics in the style of premium educational platforms.

## 🏗️ Architecture Overview

The project consists of two main components working in harmony:

### 📱 Flutter Audio Streaming App

A modern cross-platform app (Web/iOS/Android) featuring:

- **Background Audio Playback** with media controls and lock screen support
- **Multi-language Content** (Traditional Chinese, English, Japanese)
- **HLS Streaming** for optimized audio delivery
- **Advanced Playback Features** including speed control, seeking, and autoplay
- **Modern UI** with dark theme and smooth animations

### 🔧 Node.js CLI Pipeline

A powerful content management system featuring:

- **Interactive Content Review** workflow with feedback collection
- **Automated Translation** using Google Translate API
- **Text-to-Speech Generation** with Google Cloud TTS
- **Social Media Hook Generation** for content promotion
- **Cloudflare R2 Integration** for M3U8 streaming file delivery

## 🚀 Quick Start

### Prerequisites

- **Node.js** (v18+)
- **Flutter** (3.22.2+, Dart 3.0+)
- **FFmpeg** (for audio processing)
- **rclone** (for cloud uploads)

### Installation

```bash
# Clone the repository
git clone <your-repo-url>
cd FromFedToChain

# Install Node.js dependencies
npm install

# Install Flutter dependencies
npm run install:flutter

# Check pipeline dependencies
npm run check-deps
```

### Development Setup

#### Flutter App (Web Development)

```bash
# Run Flutter app in Chrome (with CORS disabled for development)
flutter run -d chrome --web-browser-flag="--disable-web-security"

# For mobile development
flutter run
```

#### Node.js CLI Pipeline

```bash
# Start interactive content review
npm run review

# Process content through full pipeline
npm run pipeline <content-id>

# Run comprehensive tests
npm run test
```

## ✨ Key Features

### Content Management

- **Human-First Review Workflow** - Interactive CLI for content quality assurance
- **Multi-language Support** - Automatic translation to English and Japanese
- **Flexible Content Schema** - Structured JSON with metadata and status tracking
- **Nested File Organization** - Content organized by language and category

### Audio Streaming

- **Modern Flutter UI** - Responsive design with smooth animations
- **Background Playback** - Continue listening while using other apps
- **Media Session Integration** - Lock screen controls and system notifications
- **Playlist Management** - Organize content by categories and completion status
- **Playback Controls** - Speed adjustment, seeking, and autoplay features

### Technical Excellence

- **Comprehensive Testing** - 174+ Node.js tests, Flutter widget tests with coverage
- **CI/CD Pipeline** - GitHub Actions with automated testing and formatting
- **Code Quality** - ESLint, Prettier, Flutter analyze with pre-commit hooks
- **Cross-Platform** - Web, iOS, and Android support from single codebase

## 📁 Project Structure

```
FromFedToChain/
├── src/                     # Node.js CLI Pipeline
│   ├── cli.js              # Interactive CLI interface
│   ├── ContentManager.js   # Content CRUD operations
│   ├── ContentSchema.js    # Schema validation
│   └── services/           # Pipeline services (TTS, Translation, etc.)
├── app/                    # Flutter Streaming App
│   ├── lib/
│   │   ├── models/         # Data models
│   │   ├── services/       # Audio & content services
│   │   ├── screens/        # App screens
│   │   └── widgets/        # UI components
│   └── pubspec.yaml       # Flutter dependencies
├── content/                # Content files (nested by language/category)
├── audio/                  # Generated audio files
├── tests/                  # Comprehensive test suite
└── .github/workflows/      # CI/CD configuration
```

## 🎯 Content Workflow

### 1. Content Creation

```bash
# Create source content in Traditional Chinese
content/zh-TW/daily-news/2025-01-15-bitcoin-analysis.json
```

### 2. Interactive Review

```bash
npm run review
# Review content with feedback collection
# [a]ccept, [r]eject, [s]kip, [q]uit options
```

### 3. Automated Pipeline

```bash
npm run pipeline 2025-01-15-bitcoin-analysis
# Translation → TTS → Social Hooks → M3U8 Generation
```

### 4. Audio Streaming

```bash
flutter run -d chrome
# Launch Flutter app to stream generated content
```

## 🧪 Testing & Quality

### Test Coverage

- **Node.js**: 174 passing tests (12 skipped)
- **Flutter**: 16 widget tests with coverage reporting
- **CI/CD**: Automated testing on every commit

### Quality Assurance

```bash
# Run all tests
npm run test

# Format all code
npm run format

# Lint and analyze
npm run lint
```

## 📊 Content Schema

Each content file follows a structured schema:

```json
{
  "id": "2025-01-15-bitcoin-analysis",
  "status": "reviewed",
  "category": "daily-news",
  "date": "2025-01-15",
  "language": "zh-TW",
  "title": "比特幣市場分析...",
  "content": "你有沒有想過...",
  "references": ["資料來源"],
  "audio_file": "audio/zh-TW/2025-01-15-bitcoin-analysis.wav",
  "social_hook": "🚀 比特幣突破新高...",
  "streaming_urls": {
    "m3u8": "https://cdn.example.com/audio.m3u8"
  },
  "feedback": {
    "content_review": "Approved for publication"
  }
}
```

## ⚙️ Configuration

### Environment Variables

```bash
# Copy example files
cp .env.sample .env
cp app/.env.example app/.env

# Configure required services:
# - Google Cloud TTS credentials
# - Cloudflare R2 storage
# - API endpoints
```

### Pipeline Dependencies

```bash
# macOS setup
brew install ffmpeg

# Install and configure rclone
curl https://rclone.org/install.sh | sudo bash
rclone config create r2 s3 provider=Cloudflare ...
```

## 🚀 Deployment

### Flutter Web

```bash
npm run build:flutter
# Builds optimized web version
```

### Mobile Apps

```bash
cd app
flutter build apk    # Android
flutter build ios    # iOS (requires Xcode)
```

## 🔧 Troubleshooting

### Common Issues

**Pipeline fails with "remote not configured"**

- Solution: Configure rclone with `npm run check-deps`

**Flutter app CORS issues**

- Solution: Use `--web-browser-flag="--disable-web-security"` for development

**Audio streaming not working**

- Solution: Ensure content has `streaming_urls` generated by pipeline

See [CLAUDE.md](./CLAUDE.md) for comprehensive troubleshooting guide.

## 🤝 Contributing

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/amazing-feature`)
3. **Run tests** (`npm run test`)
4. **Format code** (`npm run format`)
5. **Commit changes** (`git commit -m 'Add amazing feature'`)
6. **Push to branch** (`git push origin feature/amazing-feature`)
7. **Open a Pull Request**

All commits trigger automated CI testing and formatting checks.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Google Cloud** - Text-to-Speech and Translation APIs
- **Cloudflare R2** - Audio streaming infrastructure
- **Flutter Community** - Exceptional audio playback packages
- **Open Source** - Built on the shoulders of giants

---

**Built with ❤️ for educational content creators and crypto enthusiasts**
