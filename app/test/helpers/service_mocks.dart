import 'package:flutter/widgets.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:from_fed_to_chain_app/services/audio_service.dart';
import 'package:from_fed_to_chain_app/services/content_service.dart';
import 'package:from_fed_to_chain_app/services/auth/auth_service.dart';
import 'package:from_fed_to_chain_app/services/navigation_service.dart';
import 'package:from_fed_to_chain_app/services/deep_link_service.dart';
import 'package:from_fed_to_chain_app/services/streaming_api_service.dart';

// Generate mocks using build_runner
@GenerateMocks([
  NavigationService,
  DeepLinkService,
  StreamingApiService,
], customMocks: [
  MockSpec<AudioService>(as: #MockAudioServiceBase),
  MockSpec<ContentService>(as: #MockContentServiceBase),
  MockSpec<AuthService>(as: #MockAuthServiceBase),
])
import 'service_mocks.mocks.dart';

// Export the generated mock classes for easy access
export 'service_mocks.mocks.dart';

/// Extended mock for AudioService with additional testing features
class MockAudioService extends MockAudioServiceBase {
  bool _isPlaying = false;
  double _playbackSpeed = 1.0;
  bool _hasError = false;
  String? _errorMessage;
  bool _isLoading = false;
  bool _repeatEnabled = false;
  bool _autoplayEnabled = false;
  
  @override
  bool get isPlaying => _isPlaying;
  
  @override
  double get playbackSpeed => _playbackSpeed;
  
  @override
  bool get hasError => _hasError;
  
  @override
  String? get errorMessage => _errorMessage;
  
  @override
  bool get isLoading => _isLoading;
  
  @override
  bool get repeatEnabled => _repeatEnabled;
  
  @override
  bool get autoplayEnabled => _autoplayEnabled;
  
  /// Simulate playing state change
  void simulatePlayingStateChange(bool playing) {
    _isPlaying = playing;
    notifyListeners();
  }
  
  /// Simulate playback speed change
  void simulatePlaybackSpeedChange(double speed) {
    _playbackSpeed = speed;
    notifyListeners();
  }
  
  /// Simulate loading state
  void simulateLoadingState() {
    when(playbackState).thenReturn(PlaybackState.loading);
    notifyListeners();
  }
  
  /// Simulate error state
  void simulateErrorState() {
    when(playbackState).thenReturn(PlaybackState.error);
    notifyListeners();
  }
  
  /// Simulate successful audio load
  void simulateAudioLoad() {
    when(playbackState).thenReturn(PlaybackState.paused);
    when(totalDuration).thenReturn(const Duration(minutes: 5));
    notifyListeners();
  }
}

/// Extended mock for ContentService with additional testing features
class MockContentService extends MockContentServiceBase {
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  String _selectedLanguage = 'All';
  String _selectedCategory = 'All';
  String _searchQuery = '';
  String _sortOrder = 'newest';
  
  @override
  bool get isLoading => _isLoading;
  
  @override
  bool get hasError => _hasError;
  
  @override
  String? get errorMessage => _errorMessage;
  
  @override
  String get selectedLanguage => _selectedLanguage;
  
  @override
  String get selectedCategory => _selectedCategory;
  
  @override
  String get searchQuery => _searchQuery;
  
  @override
  String get sortOrder => _sortOrder;
  
  @override
  bool get hasEpisodes => true;
  
  @override
  bool get hasFilteredResults => true;
  
  /// Simulate loading state
  void simulateLoadingState() {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();
  }
  
  /// Simulate error state
  void simulateErrorState(String message) {
    _isLoading = false;
    _hasError = true;
    _errorMessage = message;
    notifyListeners();
  }
  
  /// Simulate successful data load
  void simulateSuccessfulLoad() {
    _isLoading = false;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();
  }
  
  /// Simulate filter changes
  void simulateLanguageFilter(String language) {
    _selectedLanguage = language;
    notifyListeners();
  }
  
  void simulateCategoryFilter(String category) {
    _selectedCategory = category;
    notifyListeners();
  }
  
  void simulateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
  
  void simulateSortOrder(String order) {
    _sortOrder = order;
    notifyListeners();
  }
}

/// Extended mock for AuthService with additional testing features  
class MockAuthService extends MockAuthServiceBase {
  bool _isAuthenticated = false;
  bool _isLoading = false;
  
  @override
  bool get isAuthenticated => _isAuthenticated;
  
  @override
  bool get isLoading => _isLoading;
  
  /// Simulate sign in
  void simulateSignIn() {
    _isAuthenticated = true;
    _isLoading = false;
    notifyListeners();
  }
  
  /// Simulate sign out
  void simulateSignOut() {
    _isAuthenticated = false;
    _isLoading = false;
    notifyListeners();
  }
  
  /// Simulate loading state
  void simulateLoadingState() {
    _isLoading = true;
    notifyListeners();
  }
  
  /// Simulate authentication error
  void simulateAuthError() {
    _isLoading = false;
    _isAuthenticated = false;
    notifyListeners();
  }
}

/// Mock audio handler for testing background audio
class MockAudioHandler extends Mock {
  bool _isPlaying = false;
  
  bool get isPlaying => _isPlaying;
  
  void simulatePlay() {
    _isPlaying = true;
  }
  
  void simulatePause() {
    _isPlaying = false;
  }
  
  void simulateStop() {
    _isPlaying = false;
  }
}

/// Navigation observer for testing navigation
class MockNavigatorObserver extends Mock implements NavigatorObserver {
  final List<Route<dynamic>> pushedRoutes = [];
  final List<Route<dynamic>> poppedRoutes = [];
  final List<Route<dynamic>> removedRoutes = [];
  final List<Route<dynamic>> replacedRoutes = [];
  
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoutes.add(route);
    super.noSuchMethod(Invocation.method(#didPush, [route, previousRoute]));
  }
  
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    poppedRoutes.add(route);
    super.noSuchMethod(Invocation.method(#didPop, [route, previousRoute]));
  }
  
  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    removedRoutes.add(route);
    super.noSuchMethod(Invocation.method(#didRemove, [route, previousRoute]));
  }
  
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) replacedRoutes.add(newRoute);
    super.noSuchMethod(Invocation.method(#didReplace, [], {
      #newRoute: newRoute,
      #oldRoute: oldRoute,
    }));
  }
  
  /// Reset all recorded routes
  void reset() {
    pushedRoutes.clear();
    poppedRoutes.clear();
    removedRoutes.clear();
    replacedRoutes.clear();
  }
}

/// Test data builder for consistent mock data
class MockDataBuilder {
  static MockContentService createContentServiceWithData() {
    final mock = MockContentService();
    
    // Set up mock behavior with realistic data
    when(mock.allEpisodes).thenReturn([
      // Test episodes with different categories and languages
    ]);
    
    return mock;
  }
  
  static MockAudioService createAudioServiceWithPlayback() {
    final mock = MockAudioService();
    
    // Set up mock behavior for active playback
    mock.simulatePlayingStateChange(true);
    when(mock.playbackState).thenReturn(PlaybackState.playing);
    when(mock.currentPosition).thenReturn(const Duration(minutes: 2));
    when(mock.totalDuration).thenReturn(const Duration(minutes: 5));
    
    return mock;
  }
  
  static MockAuthService createAuthenticatedAuthService() {
    final mock = MockAuthService();
    mock.simulateSignIn();
    return mock;
  }
}