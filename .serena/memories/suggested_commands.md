# Suggested Commands and Workflows

## Essential Development Commands

### Node.js CLI Commands

```bash
# Interactive content review (primary workflow)
npm run review

# Auto-process content through full pipeline
npm run pipeline <content-id>

# Check pipeline dependencies (ffmpeg, rclone, etc.)
npm run check-deps

# Run Node.js tests
npm run test:node

# Format JavaScript code
npm run format:js

# Lint Node.js code
npm run lint:node
```

### Flutter App Commands

```bash
# Web development (with CORS disabled)
flutter run -d chrome --web-browser-flag="--disable-web-security"

# Mobile development
flutter run

# Build for web
flutter build web

# Run tests with coverage
flutter test --coverage

# Static analysis
flutter analyze --no-congratulate

# Format Dart code
dart format lib/ test/
```

### Unified Commands (Both Ecosystems)

```bash
# Run all tests (Node.js + Flutter)
npm run test

# Format all code (JS + Dart)
npm run format

# Lint all code
npm run lint

# Install Flutter dependencies
npm run install:flutter

# Build Flutter for web
npm run build:flutter
```

## Content Management Workflow

### Review Process

```bash
# Start interactive review session
npm run review

# Review controls:
# [a]ccept - Approve content (optional feedback)
# [r]eject - Reject with required feedback
# [s]kip - Skip this content
# [q]uit - Exit review session
```

### Pipeline Processing

```bash
# Process specific content through pipeline
npm run pipeline 2025-08-08-example-content

# Pipeline phases:
# 1. reviewed → translated (TranslationService)
# 2. translated → wav (AudioService)
# 3. wav → m3u8 (M3U8AudioService)
# 4. m3u8 → cloudflare (CloudflareR2Service)
# 5. cloudflare → content (ContentUpload)
# 6. content → social (SocialService)
```

## Development Best Practices

### When Task is Complete

1. **Run Tests**: `npm run test` (both Node.js and Flutter)
2. **Format Code**: `npm run format` (both ecosystems)
3. **Lint Code**: `npm run lint` (static analysis)
4. **Check Dependencies**: `npm run check-deps` (if pipeline changes)

### Pre-commit Automation

- Husky runs automatically on `git commit`
- Formats staged files with Prettier/dart format
- Runs Flutter analyze on Dart files
- Executes Flutter tests when Dart files change

### System Utilities (macOS/Darwin)

- `ls`, `cd`, `mkdir`, `rm` (standard Unix commands)
- `grep`, `find` (text search and file finding)
- `git` (version control)
- `brew install` (package management for dependencies like ffmpeg)
