# From Fed to Chain Flutter App - Project Overview (Updated 2025-01-13)

## Purpose

A comprehensive dual-platform system combining a powerful Node.js CLI pipeline for content management with a modern Flutter mobile/web app for audio streaming. Creates conversational Chinese explainers about cryptocurrency and macro economics.

**Available Memories**:

1. `project_overview` - High-level project summary (this file)
2. `system_architecture` - Detailed architecture documentation
3. `flutter_app_components` - Flutter component inventory and patterns
4. `testing_and_ci_infrastructure` - Testing strategy and CI/CD documentation

## Architecture Summary

### Node.js CLI Pipeline (`src/`)

- **Interactive Review System**: Human-first content quality workflow
- **Automated Processing**: Translation → TTS → Social Hooks → M3U8 streaming
- **Service Architecture**: Modular services for pipeline operations
- **Quality Assurance**: 174 passing tests with comprehensive coverage

### Flutter Audio Streaming App (`app/lib/`)

- **Cross-Platform**: Web, iOS, Android from single codebase
- **Background Audio**: Lock screen controls, media session integration
- **Modern UI**: Dark theme with smooth animations and responsive design
- **Provider Pattern**: Clean state management with service layer separation

## Tech Stack

**Node.js Pipeline**:

- Node.js 18+, Express-style CLI interface
- Google Cloud TTS & Translate APIs
- FFmpeg for audio processing, rclone for cloud storage
- Comprehensive test suite with custom runner

**Flutter App**:

- Flutter 3.22.2+, Dart 3.0+
- Audio: just_audio, audio_service, audio_session
- State: Provider pattern with service layer
- HTTP: dio with streaming API integration
- UI: Material Design 3 with custom dark theme

## Key Features

### Content Management

- Interactive CLI review workflow with feedback collection
- Multi-language support (zh-TW source, en-US, ja-JP translations)
- Nested content organization by language/category
- Schema validation and content integrity

### Audio Streaming

- HLS streaming with background playback support
- Lock screen controls and system notifications
- Playback speed control, seeking, autoplay
- Episode progress tracking and completion status
- Multi-platform deployment ready

### Quality Assurance

- **Node.js**: 174 tests (12 skipped) with comprehensive coverage
- **Flutter**: 16 widget tests with coverage reporting
- **CI/CD**: GitHub Actions with automated testing and formatting
- **Code Quality**: ESLint, Prettier, Flutter analyze with pre-commit hooks

## Project Structure

```
FromFedToChain/
├── src/                    # Node.js CLI Pipeline
│   ├── cli.js             # Interactive CLI interface
│   ├── ContentManager.js  # Content CRUD with nested structure
│   ├── ContentSchema.js   # Schema validation
│   └── services/          # Pipeline services (TTS, Translation, etc.)
├── app/                   # Flutter Audio Streaming App
│   ├── lib/
│   │   ├── models/        # AudioContent, AudioFile, Playlist
│   │   ├── services/      # Audio, Content, Streaming services
│   │   ├── screens/       # HomeScreen, PlayerScreen
│   │   └── widgets/       # Reusable UI components
├── content/               # Nested content files by language/category
├── tests/                 # Comprehensive Node.js test suite
├── .github/workflows/     # CI/CD pipeline configuration
└── docs/                  # Updated comprehensive documentation
```

## Development Workflow

1. **Content Creation**: Manual creation in `content/zh-TW/`
2. **Interactive Review**: `npm run review` with feedback collection
3. **Automated Pipeline**: `npm run pipeline <id>` for processing
4. **Flutter Development**: `flutter run -d chrome` for streaming app
5. **Quality Assurance**: Automated testing and formatting on every commit

## Current Status

- **Documentation**: Fully updated and comprehensive
- **Architecture**: Stable with recent audio service improvements
- **Testing**: All tests passing with good coverage
- **CI/CD**: Fully automated quality gates
- **Deployment**: Ready for web/mobile deployment

## Integration Points

- **Google Cloud**: TTS and Translation APIs with service account auth
- **Cloudflare R2**: Storage and CDN for HLS streaming delivery
- **GitHub Actions**: Automated testing, formatting, and build verification
- **Flutter Ecosystem**: Modern packages for audio and UI

## Recent Updates

- Fixed episode completion progress issue in AudioService
- Extracted Flutter modules for better organization
- Updated comprehensive documentation across README.md and memories
- Maintained CI/CD pipeline with passing tests

This dual-platform system provides a complete solution from content creation through consumption, with emphasis on code quality, user experience, and maintainability.
