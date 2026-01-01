# Claude Code Configuration

This file contains important information for Claude Code to work effectively with this project.

## Project Context

**From Fed to Chain** is a Flutter mobile/web application for streaming audio content about crypto/macro economics. Content is available in multiple languages (Traditional Chinese, English, Japanese) with HLS streaming via Cloudflare R2.

## ✨ Current Architecture

**Key Principle**: Cross-platform Flutter app with serverless API backend

### Flutter Mobile/Web App

```
app/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── models/                   # Data models
│   │   ├── audio_content.dart    # Content metadata model
│   │   └── audio_file.dart       # Audio file model
│   ├── screens/                  # App screens
│   │   └── home_screen.dart      # Main screen
│   ├── services/                 # Business logic
│   │   ├── audio_service.dart    # Audio playback service
│   │   └── content_service.dart  # Content loading service
│   ├── themes/                   # App theming
│   │   └── app_theme.dart        # Dark theme configuration
│   ├── config/                   # Configuration
│   │   └── api_config.dart       # API endpoints and constants
│   └── widgets/                  # UI components
│       ├── animated_background.dart
│       ├── audio_item_card.dart
│       ├── audio_list.dart
│       ├── filter_bar.dart
│       └── mini_player.dart
└── test/                         # Flutter tests
    └── models/
        ├── audio_content_test.dart
        └── audio_file_test.dart
```

### Cloudflare Worker API

```
cloudflare/
└── index.js                      # Serverless API for content/audio serving
```

Content and audio files are stored in Cloudflare R2:

```
content/                          # Content metadata (JSON)
├── zh-TW/                       # Traditional Chinese (source)
│   ├── daily-news/
│   ├── ethereum/
│   ├── macro/
│   ├── startup/
│   ├── ai/
│   └── defi/
├── en-US/                       # English translations
└── ja-JP/                       # Japanese translations

audio/                            # Audio files (M3U8/TS segments)
├── zh-TW/{category}/{id}/
│   ├── audio.m3u8
│   └── segment-*.ts
├── en-US/{category}/{id}/
└── ja-JP/{category}/{id}/
```

## 📋 Content Schema

Each content file is a JSON file containing metadata for one piece of content:

**Example** (`content/zh-TW/daily-news/2025-06-30-bitcoin-news.json`):

```json
{
  "id": "2025-06-30-bitcoin-news",
  "status": "published",
  "category": "daily-news",
  "date": "2025-06-30",
  "language": "zh-TW",
  "title": "比特幣突破新高...",
  "content": "你有沒有想過...",
  "references": ["資料來源1", "資料來源2"],
  "streaming_urls": {
    "m3u8": "https://r2.example.com/audio/zh-TW/daily-news/2025-06-30-bitcoin-news/audio.m3u8"
  },
  "social_hook": "🚀 比特幣新高...",
  "updated_at": "2025-06-30T14:00:00Z"
}
```

## 🚀 Development Commands

### Flutter App Commands

```bash
# Web development
flutter run -d chrome --web-browser-flag="--disable-web-security"

# Mobile development
flutter run                       # Auto-detects device
flutter run -d ios               # iOS (macOS only)
flutter run -d android           # Android

# Build
flutter build web --release      # Web
flutter build apk --release      # Android
flutter build ios --release      # iOS (macOS only)

# Testing
flutter test --coverage          # Run tests with coverage
flutter analyze --no-congratulate # Static analysis
dart format lib/ test/           # Format code
```

### Unified npm Commands

```bash
# Run all tests (Flutter only)
npm run test

# Format all code (Dart + JS/JSON/MD)
npm run format

# Lint all code
npm run lint

# Install Flutter dependencies
npm run install:flutter

# Build Flutter for web
npm run build:flutter
```

## 📁 File Structure

### Content Files

- **Location**: `/content/{language}/{category}/{id}.json`
- **Format**: JSON metadata with content and streaming URLs
- **Languages**: zh-TW (source), en-US, ja-JP
- **Categories**: daily-news, ethereum, macro, startup, ai, defi

### Audio Files

- **Location**: `/audio/{language}/{category}/{id}/audio.m3u8`
- **Format**: HLS streaming (M3U8 playlist + TS segments)
- **Served by**: Cloudflare Worker with R2 storage

### Configuration

- **Languages**: English (en-US), Japanese (ja-JP), Traditional Chinese (zh-TW)
- **Categories**: daily-news, ethereum, macro, startup, ai, defi
- **API Endpoint**: Configured in `app/lib/config/api_config.dart`

## 🔧 Core Components

### Flutter App

- **AudioService**: Background audio playback with just_audio and audio_service packages
- **ContentService**: Fetches content list from Cloudflare Worker API
- **Models**: AudioContent and AudioFile data models
- **Screens**: HomeScreen with audio player UI
- **Widgets**: Reusable UI components (AudioItemCard, FilterBar, MiniPlayer)

### Cloudflare Worker

- **Content API**: Lists and serves content JSON files from R2
- **M3U8 Proxy**: Proxies M3U8 streaming files with proper CORS headers
- **Endpoints**:
  - `GET /?prefix=audio/{lang}/{category}/` - List content
  - `GET /proxy/audio/{lang}/{category}/{id}/audio.m3u8` - Stream audio

## 🎯 Design Principles

1. **Cross-platform**: Single Flutter codebase for Web, iOS, and Android
2. **Serverless**: Cloudflare Worker API with R2 object storage
3. **HLS Streaming**: Optimized audio delivery with adaptive bitrate
4. **Modern UI**: Dark theme with smooth animations and responsive design
5. **Maintainability**: Clean code structure prioritizing readability

## 🚨 Important Notes

- **Flutter-focused**: System designed for audio streaming and playback
- **File Paths**: Always use absolute paths in API configurations
- **Schema Validation**: Content models validated in Dart via fromJson()
- **Nested Structure**: Content organized by language/category
- **Coexisting Dependencies**: Node.js (package.json) for tooling, Flutter (pubspec.yaml) for app

## 🔄 Configuration Constants

**IMPORTANT**: These constants are defined in `app/lib/config/api_config.dart` and must be kept in sync with actual content organization:

### Languages

```dart
static const List<String> supportedLanguages = ['zh-TW', 'en-US', 'ja-JP'];

static const Map<String, String> languageNames = {
  'zh-TW': '繁體中文',
  'en-US': 'English',
  'ja-JP': '日本語',
};
```

### Categories

```dart
static const List<String> supportedCategories = [
  'daily-news', 'ethereum', 'macro', 'startup', 'ai', 'defi'
];

static const Map<String, String> categoryNames = {
  'daily-news': 'Daily News',
  'ethereum': 'Ethereum',
  'macro': 'Macro Economics',
  'startup': 'Startup',
  'ai': 'AI',
  'defi': 'DeFi',
};
```

### UI Constants (Flutter-Specific)

**Category Emojis** (`app/lib/models/audio_content.dart`):

```dart
'daily-news': '📰', 'ethereum': '⚡', 'macro': '📊',
'startup': '🚀', 'ai': '🤖', 'defi': '💎'
```

**Language Flags** (`app/lib/models/audio_content.dart`):

```dart
'zh-TW': '🇹🇼', 'en-US': '🇺🇸', 'ja-JP': '🇯🇵'
```

## 🏗️ CI/CD Pipeline

### GitHub Actions Workflow

The project uses GitHub Actions for continuous integration:

**Test Job (`.github/workflows/ci.yml`):**

- ✅ Flutter setup with pub caching
- ✅ Flutter tests with coverage
- ✅ Code analysis (`flutter analyze`)
- ✅ Coverage reporting to Codecov

**Build Job:**

- ✅ Flutter web build verification
- ✅ Build artifacts upload

### Pre-commit Hooks

Husky and lint-staged provide pre-commit validation:

```bash
# Pre-commit hooks run automatically on git commit
# - Format staged Dart files (dart format)
# - Format staged JS/JSON/MD files (prettier)
# - Run Flutter analyze on Dart files
```

**Configuration Files:**

- `.husky/pre-commit` - Git hook script
- `package.json` - Husky and lint-staged setup

### Test Coverage

**Current Test Status:**

- **Flutter Tests**: 16 passing, 0 failing
- **Coverage**: Generated in `app/coverage/lcov.info`

**Test Structure:**

- `app/test/models/` - Model unit tests
- Coverage reports uploaded to Codecov in CI

## 🔧 Troubleshooting

### Flutter Web CORS Issues

**Problem**: CORS errors when streaming audio

**Solutions**:

1. **Development**: Use `flutter run -d chrome --web-browser-flag="--disable-web-security"`
2. **Production**: Ensure Cloudflare Worker sets proper CORS headers

### Audio Playback Issues

**Problem**: Audio doesn't play or stream

**Solutions**:

1. **Check .env file**: Ensure `STREAMING_BASE_URL` is set in `app/.env`
2. **Verify M3U8 URLs**: Check that streaming URLs in content JSON are accessible
3. **Check Cloudflare Worker**: Verify worker is deployed and responding

### Build Issues

**Problem**: Flutter build fails

**Solutions**:

```bash
# Clean build cache
cd app && flutter clean && flutter pub get

# Rebuild
flutter build web --release
```

## 📚 Resources

### Flutter Development

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [just_audio Package](https://pub.dev/packages/just_audio)
- [audio_service Package](https://pub.dev/packages/audio_service)

### Audio Streaming

- [HLS Streaming Guide](https://developer.apple.com/streaming/)
- [Cloudflare R2 Documentation](https://developers.cloudflare.com/r2/)
- [Cloudflare Workers Documentation](https://developers.cloudflare.com/workers/)

---

_Last updated: 2025-01-01 - Simplified to Flutter-only architecture after CLI deprecation_
