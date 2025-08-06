# Flutter App Components - Detailed Reference

## Component Inventory

### Core Services (`app/lib/services/`)

#### BackgroundAudioHandler (`background_audio_handler.dart`)

**Purpose**: Manages media session, lock screen controls, and system audio integration
**Key Responsibilities**:

- Media session management for background audio
- Lock screen controls (play, pause, skip, previous)
- System notifications and media metadata
- Integration with platform audio focus
- Handles audio interruptions (calls, notifications)

**Integration Points**:

- Extends `BaseAudioHandler` from audio_service package
- Works with `AudioService` for playback state
- Communicates with system media controls

#### AudioService (`audio_service.dart`)

**Purpose**: Core audio playback logic and state management
**Key Responsibilities**:

- Audio playback control (play, pause, seek, stop)
- Playlist management and navigation
- Playback speed control
- Progress tracking and completion status updates
- Episode state management (completed, current position)

**State Management**:

- Uses Provider pattern for state distribution
- Manages current episode, position, playback state
- Handles autoplay and continuous playback
- Updates ContentService with completion progress

**Recent Changes**:

- Fixed issue where episode completion progress wasn't updating in ContentService
- Improved playlist navigation and autoplay functionality

#### ContentService (`content_service.dart`)

**Purpose**: Content loading, management, and filtering
**Key Responsibilities**:

- Fetches content from API endpoints
- Filters content by category, language, completion status
- Search functionality across content
- Content caching and state management
- Episode completion tracking

**Data Flow**:

- Loads content from streaming API
- Provides filtered lists to UI components
- Maintains user preferences and completion status
- Integrates with audio service for playback state

#### StreamingApiService (`streaming_api_service.dart`)

**Purpose**: API communication for content fetching
**Key Responsibilities**:

- HTTP requests to content endpoints
- Response parsing and error handling
- API configuration management
- Content metadata retrieval

### Models (`app/lib/models/`)

#### AudioContent (`audio_content.dart`)

**Purpose**: Core content model with metadata
**Fields**:

- Content identification (id, title, date, category)
- Multi-language support (language field)
- Content text and references
- Audio file URLs and streaming metadata
- Social media hooks
- Status and feedback information

#### AudioFile (`audio_file.dart`)

**Purpose**: Audio-specific metadata model
**Fields**:

- File paths and streaming URLs
- Audio duration and format information
- Quality settings and streaming options
- Progress and completion tracking

#### Playlist (`playlist.dart`)

**Purpose**: Episode collection and playback management
**Features**:

- Episode ordering and organization
- Current position tracking
- Autoplay configuration
- Filter state management

### UI Components

#### Screens (`app/lib/screens/`)

**HomeScreen** (`home_screen.dart`):

- Main application interface
- Content browsing and filtering
- Search functionality
- Navigation to player screen

**PlayerScreen** (`player_screen.dart`):

- Full-screen audio player
- Detailed episode information
- Advanced playback controls
- Content display and metadata

#### Widgets (`app/lib/widgets/`)

**Audio Controls** (`audio_controls.dart`):

- Primary playback interface
- Play/pause, skip, previous buttons
- Progress bar with seeking
- Playback speed controls

**Mini Player** (`mini_player.dart`):

- Persistent playback controls
- Episode information display
- Quick access to player screen
- Appears during audio playback

**Audio Item Card** (`audio_item_card.dart`):

- Individual episode display
- Episode metadata and thumbnail
- Play/pause button integration
- Completion status indication

**Audio List** (`audio_list.dart`):

- Episode collection display
- Scrollable list with lazy loading
- Filter integration
- Selection and navigation

**Filter Bar** (`filter_bar.dart`):

- Category and status filtering
- Language selection
- Search input integration
- Filter state management

**Content Display** (`content_display.dart`):

- Episode content text display
- Reference and metadata information
- Responsive text formatting
- Scrollable content area

**Search Bar** (`search_bar.dart`):

- Content search interface
- Real-time search functionality
- Search history and suggestions
- Integration with ContentService

**Playback Speed Selector** (`playback_speed_selector.dart`):

- Speed control interface
- Common speed presets (0.5x to 2.0x)
- Visual feedback for selected speed
- Integration with AudioService

### Configuration (`app/lib/config/`)

#### ApiConfig (`api_config.dart`)

**Purpose**: Environment-based API configuration
**Features**:

- Environment-specific endpoints
- API key management
- Request timeout configuration
- Debug mode settings

### Theme System (`app/lib/themes/`)

#### AppTheme (`app_theme.dart`)

**Purpose**: Centralized theme configuration
**Features**:

- Dark theme optimization
- Color palette definition
- Typography configuration
- Component styling consistency

## Architecture Patterns

### State Management

- **Provider Pattern**: Used throughout for dependency injection and state distribution
- **Service Locator**: Services registered at app initialization
- **Observer Pattern**: UI components subscribe to service state changes

### Audio Integration

- **Audio Service Package**: Provides background audio capabilities
- **Just Audio Package**: Core audio playback engine
- **Audio Session Package**: System audio session management

### Data Flow

1. **Content Loading**: StreamingApiService → ContentService → UI Components
2. **Audio Playback**: UI → AudioService → BackgroundAudioHandler → System
3. **State Updates**: Service State Changes → Provider → UI Rebuild

## Development Patterns

### Testing Strategy

- **Unit Tests**: Model validation and business logic
- **Widget Tests**: UI component behavior and interaction
- **Integration Tests**: Service interaction and data flow
- **Mock Services**: Isolated component testing

### Code Organization

- **Feature-Based Structure**: Components grouped by functionality
- **Single Responsibility**: Each service has a clear, focused purpose
- **Dependency Injection**: Services loosely coupled through Provider
- **Error Handling**: Comprehensive error states and user feedback

## Performance Considerations

- **Lazy Loading**: Content loaded on-demand
- **Audio Streaming**: HLS format for optimal bandwidth usage
- **State Optimization**: Minimal rebuilds through targeted Provider usage
- **Memory Management**: Proper disposal of audio resources

## Platform Integration

### Web Support

- Progressive Web App capabilities
- CORS configuration for development
- Web-specific audio handling

### Mobile Support

- Background audio permissions
- Platform-specific audio focus handling
- Lock screen controls integration
- Notification management

This component architecture provides a scalable foundation for audio streaming with excellent user experience across platforms.
