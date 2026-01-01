# From Fed to Chain

**A modern Flutter audio streaming app for crypto/macro economics educational content**

From Fed to Chain is a cross-platform mobile and web application featuring audio streaming of conversational Chinese explainers about cryptocurrency and macro economics. Content is available in Traditional Chinese, English, and Japanese with HLS streaming for optimized delivery.

## 🏗️ Architecture Overview

### 📱 Flutter Audio Streaming App

A modern cross-platform app (Web/iOS/Android) featuring:

- **Background Audio Playback** with media controls and lock screen support
- **Multi-language Content** (Traditional Chinese, English, Japanese)
- **HLS Streaming** for optimized audio delivery via Cloudflare R2
- **Advanced Playback Features** including speed control, seeking, and autoplay
- **Modern UI** with dark theme and smooth animations
- **Category-based Organization** (Daily News, Ethereum, Macro, Startup, AI, DeFi)

### 🌐 Cloudflare Worker API

A serverless API (`cloudflare/index.js`) that:

- Serves content metadata from R2 storage
- Proxies M3U8 streaming files with proper CORS headers
- Provides content listing and filtering by language/category

## 🚀 Quick Start

### Prerequisites

- **Node.js** (v18+) - For development tooling only
- **Flutter** (3.22.2+, Dart 3.0+)

### Installation

```bash
# Clone the repository
git clone <your-repo-url>
cd FromFedToChain

# Install Flutter dependencies
npm run install:flutter
# or directly: cd app && flutter pub get
```

### Development

#### Flutter App (Web Development)

```bash
# Run Flutter app in Chrome (with CORS disabled for development)
cd app
flutter run -d chrome --web-browser-flag="--disable-web-security"

# For mobile development
flutter run

# For iOS (macOS only)
flutter run -d ios

# For Android
flutter run -d android
```

#### Testing

```bash
# Run all tests (Flutter only)
npm run test

# Run Flutter tests with coverage
cd app && flutter test --coverage

# Check code coverage
npm run coverage:flutter

# Format code
npm run format

# Analyze code quality
npm run lint
```

#### Building

```bash
# Build for web
npm run build:flutter
# or: cd app && flutter build web

# Build for Android
cd app && flutter build apk

# Build for iOS (macOS only)
cd app && flutter build ios
```

## ✨ Key Features

### Audio Streaming

- **Modern Flutter UI** - Responsive design with smooth animations
- **Background Playback** - Continue listening while using other apps
- **Media Session Integration** - Lock screen controls and system notifications
- **Playlist Management** - Organize content by categories and completion status
- **Playback Controls** - Speed adjustment (0.5x - 2.0x), seeking, and autoplay features
- **Progress Tracking** - Remember playback position across sessions
- **Search & Filter** - Find content by language, category, or title

### Technical Excellence

- **HLS Streaming** - Adaptive bitrate streaming via M3U8 playlists
- **Cloudflare R2** - Scalable object storage for audio files
- **Cross-platform** - Single codebase for Web, iOS, and Android
- **Offline Support** - Cache content for offline playback (coming soon)
- **State Management** - Efficient state handling with Provider pattern

## 📁 Project Structure

```
FromFedToChain/
├── app/                         # Flutter application
│   ├── lib/
│   │   ├── main.dart           # App entry point
│   │   ├── models/             # Data models
│   │   ├── screens/            # App screens
│   │   ├── services/           # Business logic
│   │   ├── themes/             # App theming
│   │   └── widgets/            # UI components
│   ├── test/                   # Flutter tests
│   └── pubspec.yaml            # Flutter dependencies
├── cloudflare/
│   └── index.js                # Cloudflare Worker API
├── .github/workflows/          # CI/CD pipelines
│   ├── ci.yml                  # Main CI workflow
│   └── quality.yml             # Code quality checks
└── package.json                # Node.js tooling dependencies
```

## 🎯 Content Schema

Content is organized in a nested structure by language and category:

```
content/
├── zh-TW/                      # Traditional Chinese (source)
│   ├── daily-news/
│   ├── ethereum/
│   ├── macro/
│   ├── startup/
│   ├── ai/
│   └── defi/
├── en-US/                      # English translations
└── ja-JP/                      # Japanese translations
```

Each content file contains:

```json
{
  "id": "2025-06-30-article-id",
  "status": "published",
  "category": "daily-news",
  "date": "2025-06-30",
  "language": "zh-TW",
  "title": "Article Title",
  "content": "Article content...",
  "references": ["Source 1", "Source 2"],
  "streaming_urls": {
    "m3u8": "https://r2.example.com/audio/zh-TW/daily-news/2025-06-30-article-id/audio.m3u8"
  },
  "social_hook": "Social media hook text",
  "updated_at": "2025-06-30T14:00:00Z"
}
```

## 🔧 Development Commands

### Flutter Development

```bash
# Install dependencies
npm run install:flutter

# Run tests
npm run test

# Format code (Dart + JS/JSON/MD)
npm run format

# Lint/analyze code
npm run lint

# Build for web
npm run build:flutter
```

### Code Quality

The project includes:

- **Pre-commit hooks** (Husky) - Auto-format staged files
- **CI/CD pipelines** - Automated testing and quality checks
- **Code coverage** - Track test coverage metrics
- **Flutter analyze** - Static analysis for Dart code

## 🚀 Deployment

### Flutter Web

```bash
# Build for production
cd app && flutter build web --release

# Deploy to hosting (e.g., Cloudflare Pages, Vercel, Netlify)
# Output is in app/build/web/
```

### Mobile Apps

```bash
# Android (APK)
cd app && flutter build apk --release

# iOS (requires macOS and Xcode)
cd app && flutter build ios --release
```

### Cloudflare Worker

The Cloudflare Worker (`cloudflare/index.js`) serves as the API backend. Deploy using:

```bash
# Using Wrangler CLI
cd cloudflare
wrangler publish
```

## 🧪 Testing

### Running Tests

```bash
# Run all tests
npm run test

# Run with coverage
cd app && flutter test --coverage

# Run specific test file
cd app && flutter test test/models/audio_content_test.dart

# Generate coverage report
npm run coverage:flutter
```

### Test Coverage

Current test coverage:

- **Models**: 100% coverage
- **Services**: Partial coverage
- **Widgets**: Basic coverage

Coverage reports are generated in `app/coverage/lcov.info`.

## 📚 API Documentation

### Cloudflare Worker Endpoints

**List Content by Language/Category:**

```
GET https://your-worker.workers.dev?prefix=audio/{language}/{category}/
```

**Stream Audio (M3U8):**

```
GET https://your-worker.workers.dev/proxy/audio/{language}/{category}/{id}/audio.m3u8
```

**Environment Variables:**

```env
STREAMING_BASE_URL=https://your-worker.workers.dev
```

## 🛠️ Troubleshooting

### Flutter Web CORS Issues

When developing locally, disable web security:

```bash
flutter run -d chrome --web-browser-flag="--disable-web-security"
```

### Build Issues

```bash
# Clean build cache
cd app && flutter clean && flutter pub get

# Rebuild
flutter build web --release
```

### Audio Playback Issues

- Ensure `.env` file exists in `app/` directory with `STREAMING_BASE_URL`
- Check Cloudflare Worker CORS headers
- Verify M3U8 files are accessible via the streaming URL

## 📖 Learn More

### Flutter Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Flutter Codelabs](https://docs.flutter.dev/codelabs)

### Audio Streaming

- [HLS Streaming Guide](https://developer.apple.com/streaming/)
- [just_audio Package](https://pub.dev/packages/just_audio)
- [audio_service Package](https://pub.dev/packages/audio_service)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Google Cloud for TTS and Translation APIs
- Cloudflare for R2 storage and Workers platform
- Flutter team for the amazing framework
- just_audio and audio_service for Flutter audio support
