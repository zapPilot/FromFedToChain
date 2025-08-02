# Development Commands

## Flutter App Commands (app/)

### Development

```bash
# Web development (with CORS disabled for API calls)
flutter run -d chrome --web-browser-flag="--disable-web-security"

# Mobile development
flutter run                           # iOS/Android
flutter run --release                 # Release mode for testing

# Hot reload during development
r                                     # Hot reload
R                                     # Hot restart
q                                     # Quit
```

### Building

```bash
flutter build web                     # Web build
flutter build apk                     # Android APK
flutter build ios                     # iOS build
flutter build appbundle              # Android App Bundle
```

### Testing & Quality

```bash
flutter test --coverage              # Run tests with coverage
flutter analyze --no-congratulate    # Static analysis
dart format lib/ test/               # Format code
flutter clean                        # Clean build artifacts
flutter pub get                      # Install dependencies
```

## Node.js Pipeline Commands (root)

### Content Management

```bash
npm run review                        # Interactive content review
npm run pipeline                      # Auto-process content (translation → audio → social)
npm run check-deps                    # Check pipeline dependencies
```

### Development

```bash
npm run test                          # Run all tests (Node.js + Flutter)
npm run format                       # Format all code (JS + Dart)
npm run lint                          # Lint all code
npm install:flutter                   # Install Flutter dependencies
npm build:flutter                     # Build Flutter for web
```

## Unified Commands

These commands work from the project root and handle both Node.js and Flutter:

```bash
npm run test                          # Runs both Node.js and Flutter tests
npm run format                       # Formats JS, JSON, Markdown, and Dart files
npm run lint                         # Lints Node.js code and runs Flutter analyze
```

## Platform-Specific Notes

- **macOS**: Uses Homebrew for dependencies (ffmpeg, rclone)
- **Darwin**: Standard Unix commands available (ls, grep, find, etc.)
- **Dependencies**: Node.js 18+, Flutter 3.10+, ffmpeg, rclone for full pipeline
