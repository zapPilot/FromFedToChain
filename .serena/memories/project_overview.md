# From Fed to Chain Flutter App - Project Overview

## Purpose

A modern Flutter audio streaming app for crypto and macro economics educational content. Provides audio playback with background support, lock screen controls, and multi-language content.

## Tech Stack

- **Framework**: Flutter 3.10.0+, Dart 3.0.0+
- **Audio**: just_audio, audio_service, audio_session packages
- **State Management**: Provider pattern
- **HTTP**: dio, http packages
- **UI**: Material Design with custom dark theme
- **Environment**: flutter_dotenv for configuration

## Key Features

- Background audio playback with media controls
- Multi-language content support (zh-TW, en-US, ja-JP)
- HLS streaming support for audio content
- Lock screen controls and notifications
- Playback speed control and seeking
- Episode navigation and autoplay

## Project Structure

```
app/
├── lib/
│   ├── main.dart                 # App entry point with audio service init
│   ├── models/                   # Data models (AudioFile, AudioContent, Playlist)
│   ├── services/                 # Business logic
│   │   ├── background_audio_handler.dart  # Media session and background audio
│   │   ├── audio_service.dart    # Main audio playback service
│   │   └── content_service.dart  # Content management
│   ├── screens/                  # UI screens
│   ├── widgets/                  # Reusable UI components
│   └── themes/                   # App theming
├── android/                      # Android-specific config
├── ios/                          # iOS-specific config
└── pubspec.yaml                  # Dependencies
```

## Dependencies

- just_audio: ^0.9.36 (Audio playback)
- audio_service: ^0.18.12 (Background audio and media controls)
- audio_session: ^0.1.18 (Audio session management)
- provider: ^6.1.1 (State management)
- dio: ^5.4.0 (HTTP client)
