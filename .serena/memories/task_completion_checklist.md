# Task Completion Checklist

## When a Flutter Development Task is Completed

### 1. Code Quality Checks

```bash
# Run static analysis
flutter analyze --no-congratulate

# Fix any critical issues (errors and warnings)
# Info-level warnings (prefer_const_constructors, etc.) can be ignored
```

### 2. Code Formatting

```bash
# Format Dart code
dart format lib/ test/

# Or use unified command from root
npm run format
```

### 3. Testing

```bash
# Run Flutter tests
flutter test

# Run with coverage if needed
flutter test --coverage

# For full project testing
npm run test
```

### 4. Build Verification

```bash
# Test debug build
flutter run --debug

# Test release build for performance
flutter run --release

# Build for target platforms
flutter build web          # Web deployment
flutter build apk          # Android testing
flutter build ios          # iOS testing (macOS only)
```

### 5. Platform-Specific Verification

#### Android

- Test on physical device for background audio
- Verify notification permissions
- Check lock screen controls

#### iOS

- Test background audio capabilities
- Verify Control Center integration
- Check interruption handling (calls, etc.)

#### Web

- Test basic functionality (background audio limited)
- Verify CORS handling for API calls

### 6. Documentation Updates

- Update relevant code comments
- Add inline documentation for new public APIs
- Update CLAUDE.md if architecture changes

## When a Node.js Pipeline Task is Completed

### 1. Linting and Formatting

```bash
npm run lint                # ESLint check
npm run format              # Prettier formatting
```

### 2. Testing

```bash
npm run test:node           # Node.js specific tests
npm run test                # All tests including Flutter
```

### 3. Dependency Verification

```bash
npm run check-deps          # Verify ffmpeg, rclone, etc.
```

## CI/CD Considerations

The project uses GitHub Actions for CI. Ensure:

- All tests pass locally before pushing
- Code is properly formatted
- No critical analysis errors
- Flutter builds successfully

## Pre-commit Hooks

The project uses Husky for pre-commit hooks that automatically:

- Format staged files (Prettier for JS, Dart format for Dart)
- Run Flutter analyze on Dart files
- Run Flutter tests when Dart files change

## Common Issues to Check

### Flutter

- Audio service initialization in main.dart
- Proper error handling in async methods
- Memory leaks (dispose controllers and streams)
- Platform-specific permissions

### Node.js

- Environment variable handling
- File path resolution (use absolute paths)
- Error handling and user feedback
