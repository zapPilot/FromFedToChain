# From Fed to Chain - Flutter Audio App

A modern Flutter audio streaming application for crypto and macro economics educational content. This app provides a clean, intuitive interface for browsing and streaming audio episodes from the From Fed to Chain content library.

## 🎯 Features

### Core Features

- **Audio Streaming**: HLS/M3U8 streaming support via Cloudflare R2
- **Background Playback**: Full background audio support with media session controls
- **Multi-language Support**: Content available in Traditional Chinese (zh-TW), English (en-US), and Japanese (ja-JP)
- **Category Filtering**: Browse content by category (Daily News, Ethereum, Macro, Startup, AI, DeFi)
- **Search Functionality**: Full-text search across all episodes
- **Playlist Management**: Create and manage custom playlists

### UI/UX Features

- **Modern Dark Theme**: Sleek dark interface optimized for audio consumption
- **Animated UI**: Smooth animations and transitions using Flutter Staggered Animations
- **Responsive Design**: Optimized for different screen sizes and orientations
- **Mini Player**: Always-accessible mini player for quick controls
- **Full Player Screen**: Detailed player with advanced controls and visualizations

### Audio Features

- **Variable Playback Speed**: 0.5x to 2.0x speed control with fine-tuning
- **Skip Controls**: 10-second backward and 30-second forward skip
- **Episode Navigation**: Seamless next/previous episode navigation
- **Auto-play**: Optional automatic playback of next episode
- **Lock Screen Controls**: Full media session integration for iOS/Android

## 🏗️ Architecture

### Project Structure

```
app/
├── lib/
│   ├── config/
│   │   └── api_config.dart          # API configuration and endpoints
│   ├── models/
│   │   ├── audio_content.dart       # Content metadata model
│   │   ├── audio_file.dart          # Audio file model
│   │   └── playlist.dart            # Playlist management model
│   ├── services/
│   │   ├── streaming_api_service.dart    # Cloudflare R2 API integration
│   │   ├── content_service.dart          # Content management service
│   │   ├── audio_service.dart            # Audio playback service
│   │   └── background_audio_handler.dart # Background audio handler
│   ├── screens/
│   │   ├── home_screen.dart         # Main episode browsing screen
│   │   └── player_screen.dart       # Full-screen audio player
│   ├── widgets/
│   │   ├── audio_controls.dart      # Playback control widgets
│   │   ├── audio_item_card.dart     # Episode list item
│   │   ├── audio_list.dart          # Episode list with animations
│   │   ├── filter_bar.dart          # Language/category filters
│   │   ├── mini_player.dart         # Bottom mini player
│   │   ├── playback_speed_selector.dart  # Speed control widget
│   │   └── search_bar.dart          # Search input widget
│   ├── themes/
│   │   └── app_theme.dart           # App theming and design system
│   └── main.dart                    # App entry point
├── assets/
│   └── images/                      # App assets
├── pubspec.yaml                     # Dependencies and configuration
├── .env                            # Environment configuration
└── README.md                       # This file
```

### Key Services

#### StreamingApiService

- **Purpose**: Handles API communication with Cloudflare R2 streaming service
- **Features**: Episode discovery, signed URL generation, parallel loading
- **Endpoints**: Uses `https://signed-url.davidtnfsh.workers.dev` for production

#### AudioService

- **Purpose**: Manages audio playback state and controls
- **Features**: Background playback, speed control, episode navigation
- **Integration**: Works with `BackgroundAudioHandler` for media session support

#### ContentService

- **Purpose**: Manages episode data, filtering, and playlist state
- **Features**: Language/category filtering, search, playlist management
- **Storage**: Uses `SharedPreferences` for user preferences

#### BackgroundAudioHandler

- **Purpose**: Provides system-level media controls and background playback
- **Features**: Lock screen controls, notification media controls, episode navigation
- **Platform**: iOS and Android media session integration

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.10.0 or higher
- Dart SDK 3.0.0 or higher
- iOS 12.0+ / Android API level 21+

### Installation

1. **Clone the repository**

```bash
git clone <repository-url>
cd FromFedToChain/app
```

2. **Install dependencies**

```bash
flutter pub get
```

3. **Set up environment variables**

```bash
# Copy the .env file and configure if needed
cp .env.example .env
```

4. **Run the app**

```bash
# For mobile development
flutter run

# For web development (limited audio support)
flutter run -d chrome --web-browser-flag="--disable-web-security"
```

### Development Scripts

```bash
# Run tests
flutter test

# Run tests with coverage
flutter test --coverage

# Analyze code
flutter analyze

# Format code
dart format lib/ test/

# Build for production
flutter build apk          # Android
flutter build ipa          # iOS
flutter build web          # Web
flutter build macos        # macOS
flutter build windows      # Windows
flutter build linux        # Linux
```

## 📱 Platform Support

### Mobile (Recommended)

- **iOS**: Full feature support including background playback and lock screen controls
- **Android**: Full feature support with notification-based media controls

### Web (Limited)

- **Chrome/Edge**: Basic playback support (no HLS streaming, no background audio)
- **Safari**: Limited support due to media restrictions
- **Note**: Web platform has limitations for audio streaming and background playback

### Desktop

- **macOS/Windows/Linux**: Basic playback support (limited background features)

## 🔧 Configuration

### API Configuration

Edit `/app/lib/config/api_config.dart` to modify:

- Streaming base URL
- Supported languages and categories
- API timeout settings
- Environment-specific configurations

### Environment Variables

Edit `/app/.env` to configure:

```env
ENVIRONMENT=production
STREAMING_BASE_URL=https://signed-url.davidtnfsh.workers.dev
API_TIMEOUT_SECONDS=30
STREAM_TIMEOUT_SECONDS=60
APP_NAME=From Fed to Chain
```

### Theme Customization

Edit `/app/lib/themes/app_theme.dart` to customize:

- Color palette
- Typography
- Component styling
- Animation durations

## 🎨 Design System

### Color Palette

- **Primary**: Indigo (#6366F1) - Main brand color
- **Secondary**: Emerald (#10B981) - Accent color
- **Background**: Slate 900 (#0F172A) - Main background
- **Surface**: Slate 800 (#1E293B) - Card backgrounds
- **Error**: Red 500 (#EF4444) - Error states

### Typography

- **Font Family**: Inter (system fallback)
- **Heading Styles**: Large (32px), Medium (24px), Small (20px)
- **Body Styles**: Large (16px), Medium (14px), Small (12px)

### Spacing System

- **XS**: 4px, **S**: 8px, **M**: 16px, **L**: 24px, **XL**: 32px, **XXL**: 48px

## 🧪 Testing

### Test Structure

```bash
test/
├── models/                 # Model unit tests
├── services/              # Service unit tests
├── widgets/               # Widget tests
└── integration/           # Integration tests
```

### Running Tests

```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/

# Coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## 📦 Dependencies

### Core Dependencies

- `flutter`: Flutter SDK
- `just_audio`: Audio playback engine
- `audio_service`: Background audio service
- `audio_session`: Audio session management
- `provider`: State management
- `http`: HTTP client for API calls

### UI Dependencies

- `flutter_staggered_animations`: List animations
- `shimmer`: Loading shimmer effects
- `cached_network_image`: Image caching
- `heroicons`: Icon library

### Utility Dependencies

- `flutter_dotenv`: Environment configuration
- `shared_preferences`: Local storage
- `path`: Path utilities
- `equatable`: Value equality

## 🚀 Deployment

### Mobile App Stores

#### iOS App Store

```bash
# Build for iOS
flutter build ipa

# Upload to App Store Connect via Xcode or Transporter
```

#### Google Play Store

```bash
# Build signed APK
flutter build apk --release

# Or build App Bundle (recommended)
flutter build appbundle --release
```

### Web Deployment

```bash
# Build for web
flutter build web --release

# Deploy to static hosting (Vercel, Netlify, etc.)
```

## 🤝 Contributing

### Development Workflow

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/new-feature`
3. Make changes and test thoroughly
4. Follow the existing code style and conventions
5. Submit a pull request with a clear description

### Code Style

- Follow Flutter/Dart conventions
- Use `dart format` for consistent formatting
- Add documentation for public APIs
- Write tests for new features
- Follow the existing architecture patterns

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Troubleshooting

### Common Issues

#### Audio Playback Issues

- **Problem**: No audio playback on web
- **Solution**: Use mobile apps for full audio support. Web has limited HLS streaming support.

#### Background Playback Not Working

- **Problem**: Audio stops when app is backgrounded
- **Solution**: Ensure audio_service is properly initialized. Check platform-specific permissions.

#### Episode Loading Errors

- **Problem**: Episodes fail to load
- **Solution**: Check internet connection and API endpoint configuration in `api_config.dart`.

#### Build Errors

- **Problem**: Flutter build fails
- **Solution**: Run `flutter clean && flutter pub get` and ensure Flutter SDK is up to date.

### Performance Optimization

- Episodes are loaded in parallel for faster startup
- Images and metadata are cached locally
- Audio streams use HLS for efficient bandwidth usage
- UI animations are optimized for 60fps performance

## 📞 Support

For support and questions:

- Check the [troubleshooting section](#troubleshooting)
- Review existing [GitHub issues](issues)
- Create a new issue with detailed information about your problem

---

**Built with ❤️ using Flutter for the From Fed to Chain educational platform.**
