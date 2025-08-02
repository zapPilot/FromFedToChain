# Coding Style and Conventions

## Flutter/Dart Code Style

### File Organization

- **Models**: Data classes in `lib/models/` using `equatable` for comparisons
- **Services**: Business logic in `lib/services/` following single responsibility
- **Widgets**: Reusable UI components in `lib/widgets/`
- **Screens**: Full-screen widgets in `lib/screens/`

### Naming Conventions

- **Files**: snake_case (e.g., `background_audio_handler.dart`)
- **Classes**: PascalCase (e.g., `BackgroundAudioHandler`)
- **Variables/Methods**: camelCase (e.g., `playbackState`, `setAudioSource`)
- **Constants**: SCREAMING_SNAKE_CASE (e.g., `DEFAULT_SPEED`)

### Code Patterns

- **State Management**: Provider pattern with ChangeNotifier
- **Async Operations**: Use async/await, handle errors with try-catch
- **Logging**: Use print() with emojis for visibility (🎵, ✅, ❌, 🔄)
- **Error Handling**: Graceful degradation with user-friendly error messages

### Documentation

- **Classes**: Document purpose and key functionality
- **Methods**: Document parameters and return values for public APIs
- **Complex Logic**: Add inline comments explaining business logic

## Node.js Code Style

### File Organization

- **Services**: Business logic classes in `src/` directory
- **Configuration**: Environment and constants in `config/`
- **Tests**: Jest tests in `tests/` directory

### Conventions

- **Files**: kebab-case or camelCase (e.g., `ContentManager.js`)
- **Classes**: PascalCase (e.g., `ContentManager`)
- **Variables**: camelCase
- **Constants**: SCREAMING_SNAKE_CASE

## Project-Specific Patterns

### Audio Service Architecture

- **BackgroundAudioHandler**: Handles media session and system integration
- **AudioService**: Main playback logic with fallback support
- **Provider Pattern**: Services injected via Provider for state management

### Error Handling

- Always provide fallback behavior for critical features
- Log errors with context information
- Show user-friendly error messages in UI

### Performance Considerations

- Use async/await for non-blocking operations
- Implement proper disposal patterns for streams and controllers
- Cache network requests where appropriate
