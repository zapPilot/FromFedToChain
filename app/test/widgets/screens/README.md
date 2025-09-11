# HomeScreen Widget Tests

This directory contains comprehensive widget tests for the HomeScreen class, the main screen of the "From Fed to Chain" audio streaming application.

## Test Coverage

### HomeScreen Test File: `home_screen_test.dart`

**Comprehensive test coverage for HomeScreen functionality:**

#### Test Groups:

1. **Basic Rendering**
   - Renders HomeScreen with main components
   - Displays episode statistics in header
   - Displays total episodes when no filtering

2. **Search Functionality**
   - Shows/hides search bar on icon tap
   - Calls setSearchQuery when text changes
   - Search bar animation testing

3. **Filter Bar Integration**
   - Passes correct props to FilterBar
   - Calls content service methods when filters change
   - Language and category selection

4. **Loading and Error States**
   - Displays loading state with progress indicators
   - Displays error state with retry functionality
   - Empty state handling for no filtered results

5. **Mini Player Integration**
   - Shows mini player when audio is playing
   - Hides mini player when no audio
   - Proper state integration

6. **User Profile and Authentication**
   - Displays user profile in popup menu
   - Handles logout functionality
   - Authentication state management

7. **Refresh Functionality**
   - Calls refresh when button is tapped
   - Loads episodes on initialization
   - Loading state handling

8. **Tab Navigation**
   - TabBar with correct number of tabs
   - Unfinished episodes empty state
   - Tab switching functionality

9. **Sort Selector**
   - Displays sort selector with dropdown
   - Sort options integration

10. **Episode List Content**
    - Displays AudioList when episodes available
    - Correct episode data passing

## Test Utilities

### HomeScreenTestUtils Class

**Provides comprehensive testing utilities:**

- **Sample Data Creation**: `createSampleEpisodes()`, `createMockUser()`
- **Mock Setup**: `setupContentServiceMocks()`, `setupAudioServiceMocks()`, `setupAuthServiceMocks()`
- **Widget Wrapper**: `createHomeScreenWrapper()` with all providers
- **Animation Handling**: `pumpAndSettle()` for smooth test execution

### Mock Objects

Generated using Mockito for:

- `ContentService` - Episode data and filtering
- `AudioService` - Audio playback states
- `AuthService` - User authentication

## Key Features Tested

- ✅ Tab navigation (Recent, All, Unfinished)
- ✅ Search functionality with animation
- ✅ Language and category filtering
- ✅ Episode list display and interactions
- ✅ Mini player show/hide logic
- ✅ User profile and logout
- ✅ Loading, error, and empty states
- ✅ Refresh functionality
- ✅ Sort selector integration
- ✅ Service integration and callbacks

## Running Tests

```bash
# Run HomeScreen widget tests
flutter test test/widgets/screens/home_screen_test.dart

# Run all widget tests
flutter test test/widgets/

# Run with coverage
flutter test --coverage test/widgets/screens/home_screen_test.dart
```

## Test Statistics

- **Total Tests**: 22 passing
- **Coverage Areas**: UI rendering, user interactions, state management, service integration
- **Mock Objects**: 3 services fully mocked with realistic behavior
- **Test Categories**: Widget rendering, user interactions, state changes, error scenarios

## Architecture

The tests follow Flutter best practices:

- Proper Provider integration testing
- Comprehensive mock setup
- User interaction simulation
- State management validation
- Error scenario coverage
- Animation handling
- Service callback verification

All tests use realistic mock data and cover both happy path and edge case scenarios to ensure robust HomeScreen functionality.
