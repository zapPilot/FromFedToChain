# From Fed to Chain V2 - Simplified Flutter Audio Streaming App

A streamlined Flutter application for streaming crypto/macro economics audio content with a focus on simplicity and maintainability.

## 🎯 Project Goals

Transform the original 48-file, 14,502-line Flutter app into a cleaner, simpler codebase while preserving core functionality:

- **55-60% code reduction**: 48 files → 27 files, ~14,500 lines → ~6,500 lines
- **84% service reduction**: 19 service files → 3 services
- **Simplified UI**: Remove complex tabs, focus on language selection and category filtering
- **Preserved features**: Authentication, search, audio playback, background audio

## ✅ What's Included

### Core Features
- ✅ Google Sign-In authentication
- ✅ M3U8 audio streaming from Cloudflare R2
- ✅ Background audio playback (just_audio)
- ✅ Language switching (繁體中文, English, 日本語)
- ✅ Category filtering (Daily News, Ethereum, Macro, Startup, AI, DeFi)
- ✅ Search functionality
- ✅ Sort by newest/oldest
- ✅ Simple content list UI

### Architecture
```
lib/
├── config/          # API & app configuration
├── models/          # Data models (AudioContent, AudioFile, User)
├── services/        # 3 core services (Content, Audio, Auth)
├── providers/       # Provider state management
├── screens/         # 2 main screens (Splash, Home)
├── themes/          # Dark theme configuration
└── utils/           # Formatters and utilities
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.1.0 or higher
- Dart 3.0 or higher

### Installation

1. **Install dependencies**:
   ```bash
   cd app-v2
   flutter pub get
   ```

2. **Configure environment** (already created):
   ```bash
   # .env file is already configured
   cat .env
   ```

3. **Run the app**:
   ```bash
   # Web (recommended for development)
   flutter run -d chrome --web-browser-flag="--disable-web-security"

   # Mobile
   flutter run
   ```

4. **Run tests**:
   ```bash
   flutter test
   ```

5. **Analyze code**:
   ```bash
   flutter analyze --no-congratulate
   ```

## 📱 UI Structure

### New Simplified Layout
```
┌─────────────────────────────────────┐
│ From Fed to Chain                   │  ← AppBar
├─────────────────────────────────────┤
│ [🇹🇼 繁體中文] [🇺🇸 EN] [🇯🇵 JP]   │  ← Language tabs
├─────────────────────────────────────┤
│ [📰 Daily] [⚡ ETH] [📊 Macro] [All]│  ← Category chips
├─────────────────────────────────────┤
│ 📰 Bitcoin Breaks New Highs         │
│ 🇺🇸 en-US · 12 min · 2025-12-20    │  ← Content list
│                                     │
│ 📊 Macro Economic Analysis          │
│ 🇹🇼 zh-TW · 15 min · 2025-12-19    │
└─────────────────────────────────────┘
```

### What Was Removed
- ❌ Recent/All/Unfinished tabs
- ❌ Bottom navigation (History screen)
- ❌ Progress tracking (resume playback)
- ❌ Listen history
- ❌ Alphabetical sorting
- ❌ Complex repository pattern

## 🏗️ Architecture Details

### State Management
- **Provider** pattern with ChangeNotifier
- 3 providers: ContentProvider, AudioProvider, AuthProvider
- Direct service access (no repository layer)

### Services (3 files, ~900 lines total)

1. **ContentService** (~300 lines)
   - Direct Dio HTTP calls to Cloudflare R2 API
   - Simple in-memory caching
   - Groups AudioFiles into AudioContent objects

2. **AudioPlayerService** (~350 lines)
   - Uses just_audio for M3U8 streaming
   - Background audio support via audio_session
   - Simple queue management

3. **AuthService** (~200 lines)
   - Google Sign-In integration
   - Local session persistence (SharedPreferences)

### Data Flow
```
User Interaction
  ↓
HomeScreen (Language tabs + Category chips)
  ↓
ContentProvider.setLanguage() / setCategory()
  ↓
ContentService.loadContent()
  ↓
Dio → Cloudflare R2 API
  ↓
Parse JSON → AudioFile.fromApiResponse()
  ↓
Convert to AudioContent
  ↓
ContentProvider.notifyListeners()
  ↓
UI rebuilds
```

## 📊 Metrics Comparison

| Metric | V1 (Original) | V2 (Simplified) | Reduction |
|--------|---------------|-----------------|-----------|
| **Total Files** | 48 | 27 | **44%** |
| **Lines of Code** | ~14,500 | ~6,500 | **55%** |
| **Service Files** | 19 | 3 | **84%** |
| **Dependencies** | 17 | 13 | **24%** |
| **Screens** | 5 + bottom nav | 2 | **60%** |

## 🔧 Configuration

### Supported Languages
- `zh-TW`: 繁體中文 (Traditional Chinese) 🇹🇼
- `en-US`: English 🇺🇸
- `ja-JP`: 日本語 (Japanese) 🇯🇵

### Supported Categories
- `daily-news`: 📰 Daily News
- `ethereum`: ⚡ Ethereum
- `macro`: 📊 Macro Economics
- `startup`: 🚀 Startup
- `ai`: 🤖 AI
- `defi`: 💎 DeFi

### API Configuration
- Base URL: `https://signed-url.davidtnfsh.workers.dev`
- Content endpoint: `GET /?prefix=audio/{language}/{category}/`
- Streaming: M3U8 HLS format

## 🧪 Testing

Current test coverage:
- ✅ Widget smoke test (splash screen)
- ✅ Model tests (AudioContent, AudioFile, User)
- 📝 TODO: Service unit tests
- 📝 TODO: Provider tests
- 📝 TODO: Integration tests

## 📝 Dependencies (13 packages)

### Audio (3)
- `just_audio: ^0.9.36` - Audio playback engine
- `audio_service: ^0.18.12` - Background audio
- `audio_session: ^0.1.18` - Audio session management

### State & HTTP (3)
- `provider: ^6.1.1` - State management
- `dio: ^5.4.0` - HTTP client
- `shared_preferences: ^2.2.2` - Local storage

### Authentication (2)
- `google_sign_in: ^6.2.1` - Google Sign-In
- `sign_in_with_apple: ^6.1.1` - Apple Sign-In

### UI (2)
- `shimmer: ^3.0.0` - Loading animations
- `cached_network_image: ^3.3.1` - Image caching

### Utilities (3)
- `equatable: ^2.0.5` - Value equality
- `intl: ^0.19.0` - Internationalization
- `flutter_dotenv: ^5.1.0` - Environment variables

## 🚧 Future Enhancements (Phase 2)

Deferred features for future implementation:
1. **Playback progress tracking** - Resume from last position
2. **Listen history** - Track played content
3. **Favorites/bookmarks** - Save favorite episodes
4. **Playlists** - Create custom playlists
5. **Share functionality** - Share episodes
6. **Deep linking** - Direct content links
7. **Offline downloads** - Cache for offline playback
8. **Mini player** - Persistent bottom player
9. **Full-screen player** - Rich playback UI

## 📚 Documentation

- **Implementation Plan**: `/Users/chouyasushi/.claude/plans/async-hugging-crown.md`
- **Compilation Fixes**: `COMPILATION_FIXES.md`
- **Parent Project Docs**: `../CLAUDE.md`

## 🎯 Design Principles

1. **Simplicity First**: Remove unnecessary complexity
2. **Direct API Access**: No repository abstraction overhead
3. **Single Screen Focus**: No complex navigation
4. **Language-First Navigation**: Horizontal tabs for quick switching
5. **Maintainability**: Clean, readable code over performance micro-optimizations

## 🐛 Known Issues

- ⚠️ Custom Poppins fonts commented out (using system fonts)
- ℹ️ Deprecated `withOpacity` usage in theme (non-blocking)
- ℹ️ No .env.example file (using .env directly)

## 🤝 Contributing

This is a simplified v2 rebuild. Key areas for contribution:
- Add missing UI components (mini player, full-screen player)
- Implement deferred features (progress tracking, history)
- Add comprehensive tests
- Improve error handling
- Add custom fonts

## 📄 License

Same as parent project (From Fed to Chain)

---

**Version**: 2.0.0
**Created**: December 2024
**Framework**: Flutter 3.8+
**Target Platforms**: Web, iOS, Android

**Status**: ✅ Compiles successfully, ready for development
