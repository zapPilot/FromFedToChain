# From Fed to Chain - System Architecture

## Overview

From Fed to Chain is a dual-platform content management and audio streaming system designed for educational crypto/macro economics content. The system follows a clean separation between content management (Node.js CLI) and content consumption (Flutter app).

## Core Architecture

### 1. Node.js CLI Pipeline (`src/`)

**Entry Point**: `src/cli.js`

- Interactive CLI interface for content management
- Command parsing and workflow orchestration
- User interaction handling (review, pipeline commands)

**Core Components**:

- **ContentManager.js**: Single-source-of-truth for content CRUD operations
  - Manages nested file structure: `/content/{language}/{category}/{id}.json`
  - Handles status transitions: draft → reviewed → published
  - Schema validation integration
  - Feedback collection for review workflow

- **ContentSchema.js**: Schema definition and validation
  - Content structure validation
  - Schema constants and utilities
  - Example content generation
  - Language/category management

**Service Layer** (`src/services/`):

- **ContentPipelineService.js**: Main pipeline orchestrator
- **TranslationService.js**: Google Translate API integration
- **GoogleTTSService.js**: Text-to-speech generation with batching
- **AudioService.js**: Audio processing and format conversion
- **M3U8AudioService.js**: HLS streaming file generation
- **CloudflareR2Service.js**: Cloud storage and CDN integration
- **SocialService.js**: Social media hook generation

**Utilities**:

- **command-executor.js**: Shell command execution wrapper

### 2. Flutter Audio Streaming App (`app/lib/`)

**Architecture Pattern**: Provider-based state management with service layer separation

**Entry Point**: `main.dart`

- Audio service initialization
- Provider setup
- App configuration and theming

**Models** (`models/`):

- **AudioContent**: Content metadata and structure
- **AudioFile**: Audio file metadata and streaming URLs
- **Playlist**: Episode collection and playback state

**Services** (`services/`):

- **BackgroundAudioHandler**: Media session management, lock screen controls
- **AudioService**: Core audio playbook logic, state management
- **ContentService**: Content loading, filtering, search
- **StreamingApiService**: API communication for content fetching

**UI Layer**:

- **Screens**: HomeScreen, PlayerScreen
- **Widgets**: Reusable components (AudioItemCard, MiniPlayer, FilterBar, etc.)
- **Themes**: Dark theme configuration

**Configuration**:

- **ApiConfig**: Environment-based API endpoint management

### 3. Content Structure

**File Organization**:

```
content/
├── zh-TW/          # Source language (Traditional Chinese)
├── en-US/          # English translations
└── ja-JP/          # Japanese translations
    ├── daily-news/
    ├── ethereum/
    ├── macro/
    ├── startup/
    └── ai/
```

**Content Schema**:

- **Core Fields**: id, status, category, date, language
- **Content Fields**: title, content, references
- **Media Fields**: audio_file, streaming_urls
- **Social Fields**: social_hook
- **Workflow Fields**: feedback, updated_at

### 4. Audio Pipeline

**Processing Chain**:

1. Text-to-Speech (Google Cloud TTS)
2. Audio format conversion (FFmpeg)
3. M3U8 segmentation for streaming
4. Cloudflare R2 upload
5. CDN URL generation

**Streaming Architecture**:

- HLS (HTTP Live Streaming) format
- Chunked audio delivery
- Progressive download support
- Background playback compatibility

### 5. Testing Architecture

**Node.js Tests** (`tests/`):

- End-to-end workflow testing
- Service integration tests
- CLI command testing
- Content schema validation
- Pipeline component tests

**Flutter Tests** (`app/test/`):

- Model unit tests
- Widget testing
- Service mocking
- Coverage reporting

### 6. CI/CD Pipeline

**GitHub Actions** (`.github/workflows/ci.yml`):

- Multi-environment testing (Node.js + Flutter)
- Code formatting validation
- Static analysis
- Coverage reporting
- Build verification

## Key Design Principles

1. **Separation of Concerns**: Clear boundaries between content management and consumption
2. **Human-First Workflow**: Interactive review process with feedback collection
3. **Multi-Platform Support**: Single Flutter codebase for web/mobile
4. **Scalable Audio Delivery**: HLS streaming for optimal performance
5. **Quality Assurance**: Comprehensive testing at all levels
6. **Developer Experience**: Automated formatting, linting, and pre-commit hooks

## Integration Points

- **Google Cloud Services**: TTS and Translation APIs
- **Cloudflare R2**: Storage and CDN for audio streaming
- **Flutter Audio Ecosystem**: just_audio, audio_service packages
- **Development Tools**: FFmpeg, rclone, Flutter SDK

## Current Status

- **Node.js Pipeline**: 174 tests passing, comprehensive coverage
- **Flutter App**: 16 tests passing, modern UI with background audio
- **Content Schema**: Stable, supports multi-language workflow
- **Deployment**: Ready for web/mobile deployment
- **CI/CD**: Fully automated testing and quality gates

This architecture supports the full content lifecycle from creation through consumption while maintaining code quality and developer productivity.
