import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/audio_file.dart';
import 'background_audio_handler.dart';
import 'content_facade_service.dart';
import 'enhanced_audio_service.dart';
import 'player_state_notifier.dart';

/// Playback states for the audio player
enum PlaybackState {
  stopped,
  playing,
  paused,
  loading,
  error,
}

/// Main audio service for managing playback with background support
///
/// MIGRATION NOTE: This service now uses the enhanced decomposed architecture
/// internally while maintaining full backward compatibility with the existing API.
class AudioService extends ChangeNotifier {
  // Enhanced service instance (new architecture)
  late final EnhancedAudioService _enhancedService;

  // Disposal guard
  bool _disposed = false;

  // Getters (delegate to enhanced service with state mapping)
  PlaybackState get playbackState =>
      _mapToLegacyState(_enhancedService.playbackState);
  AudioFile? get currentAudioFile => _enhancedService.currentAudioFile;
  Duration get currentPosition => _enhancedService.currentPosition;
  Duration get totalDuration => _enhancedService.totalDuration;
  double get playbackSpeed => _enhancedService.playbackSpeed;
  String? get errorMessage => _enhancedService.errorMessage;
  bool get autoplayEnabled => _enhancedService.autoplayEnabled;
  bool get repeatEnabled => _enhancedService.repeatEnabled;

  // Computed properties (delegate to enhanced service)
  bool get isPlaying => _enhancedService.isPlaying;
  bool get isPaused => _enhancedService.isPaused;
  bool get isLoading => _enhancedService.isLoading;
  bool get hasError => _enhancedService.hasError;
  bool get isIdle => _enhancedService.isIdle;
  double get progress => _enhancedService.progress;
  String get formattedCurrentPosition =>
      _enhancedService.formattedCurrentPosition;
  String get formattedTotalDuration => _enhancedService.formattedTotalDuration;
  String? get currentAudioId => _enhancedService.currentAudioId;

  AudioService(
    BackgroundAudioHandler? audioHandler,
    ContentFacadeService? contentService, [
    AudioPlayer? localAudioPlayer,
  ]) {
    if (kDebugMode) {
      print('🎧 AudioService: Initializing with enhanced architecture...');
    }

    // Create enhanced service instance
    _enhancedService =
        EnhancedAudioService(audioHandler, contentService, localAudioPlayer);

    // Set up state synchronization
    _enhancedService.addListener(() {
      if (!_disposed) {
        notifyListeners();
      }
    });

    if (kDebugMode) {
      print('✅ AudioService: Legacy compatibility layer initialized');
    }
  }

  /// Map from new AppPlaybackState to legacy PlaybackState for backward compatibility
  PlaybackState _mapToLegacyState(AppPlaybackState appState) {
    switch (appState) {
      case AppPlaybackState.stopped:
        return PlaybackState.stopped;
      case AppPlaybackState.playing:
        return PlaybackState.playing;
      case AppPlaybackState.paused:
        return PlaybackState.paused;
      case AppPlaybackState.loading:
        return PlaybackState.loading;
      case AppPlaybackState.completed:
        return PlaybackState
            .stopped; // Map completed to stopped for backward compatibility
      case AppPlaybackState.error:
        return PlaybackState.error;
    }
  }

  /// Play audio file (supports both local files and streaming URLs)
  Future<void> playAudio(AudioFile audioFile) async {
    await _enhancedService.playAudio(audioFile);
  }

  /// Set autoplay preference
  void setAutoplayEnabled(bool enabled) {
    _enhancedService.setAutoplayEnabled(enabled);
  }

  /// Set repeat preference
  void setRepeatEnabled(bool enabled) {
    _enhancedService.setRepeatEnabled(enabled);
  }

  /// Toggle play/pause
  Future<void> togglePlayPause() async {
    await _enhancedService.togglePlayPause();
  }

  /// Public method to skip to next episode
  Future<void> skipToNextEpisode() async {
    await _enhancedService.skipToNextEpisode();
  }

  /// Public method to skip to previous episode
  Future<void> skipToPreviousEpisode() async {
    await _enhancedService.skipToPreviousEpisode();
  }

  /// Seek to specific position
  Future<void> seekTo(Duration position) async {
    await _enhancedService.seekTo(position);
  }

  /// Skip forward by 30 seconds
  Future<void> skipForward() async {
    await _enhancedService.skipForward();
  }

  /// Skip backward by 10 seconds
  Future<void> skipBackward() async {
    await _enhancedService.skipBackward();
  }

  /// Set playback speed
  Future<void> setPlaybackSpeed(double speed) async {
    await _enhancedService.setPlaybackSpeed(speed);
  }

  /// Test method to verify media session is working
  Future<void> testMediaSession() async {
    // Note: This is a testing method - enhanced service handles media session internally
    if (kDebugMode) {
      print(
          '🧪 AudioService: Media session testing delegated to enhanced service');
    }
  }

  /// Skip to next episode (public method for testing compatibility)
  Future<void> skipToNext() => skipToNextEpisode();

  /// Skip to previous episode (public method for testing compatibility)
  Future<void> skipToPrevious() => skipToPreviousEpisode();

  /// Skip forward by 30 seconds (alias for seekForward)
  Future<void> seekForward() async => skipForward();

  /// Skip backward by 10 seconds (alias for seekBackward)
  Future<void> seekBackward() async => skipBackward();

  /// Play audio file (alias for playAudio for test compatibility)
  Future<void> play(AudioFile audioFile) => playAudio(audioFile);

  /// Pause playback
  Future<void> pause() async {
    await _enhancedService.pause();
  }

  /// Resume playback
  Future<void> resume() async {
    await _enhancedService.resume();
  }

  /// Stop playback
  Future<void> stop() async {
    await _enhancedService.stop();
  }

  /// Toggle autoplay
  void toggleAutoplay() {
    _enhancedService.toggleAutoplay();
  }

  /// Toggle repeat
  void toggleRepeat() {
    _enhancedService.toggleRepeat();
  }

  /// Enable autoplay (alias for setAutoplayEnabled)
  void enableAutoplay(bool enabled) {
    _enhancedService.enableAutoplay(enabled);
  }

  /// Handle episode completion (public method)
  Future<void> onEpisodeCompleted() async {
    await _enhancedService.onEpisodeCompletedManually();
  }

  /// Update progress manually
  void updateProgress(Duration position) {
    _enhancedService.updateProgress(position);
  }

  /// Handle playback error
  void handlePlaybackError(String message) {
    _enhancedService.handlePlaybackError(message);
  }

  /// Handle network timeout
  void handleNetworkTimeout() {
    handlePlaybackError('Network timeout occurred');
  }

  /// Handle invalid URL
  void handleInvalidUrl(AudioFile audioFile) {
    handlePlaybackError('Invalid audio URL: ${audioFile.streamingUrl}');
  }

  /// Validate audio file
  bool isValidAudioFile(AudioFile? audioFile) {
    return _enhancedService.isValidAudioFile(audioFile);
  }

  /// Save playback state
  void savePlaybackState() {
    _enhancedService.savePlaybackState();
  }

  /// Restore playback position
  Future<void> restorePlaybackPosition(AudioFile audioFile) async {
    await _enhancedService.restorePlaybackPosition(audioFile);
  }

  @override
  void dispose() {
    if (_disposed) {
      return; // Already disposed, nothing to do
    }

    _disposed = true;

    // Dispose enhanced service
    _enhancedService.dispose();

    super.dispose();
  }

  // Testing methods - only available in debug builds
  @visibleForTesting
  void setPlaybackStateForTesting(PlaybackState state) {
    final appState = _mapPlaybackStateToAppState(state);
    _enhancedService.setPlaybackStateForTesting(appState);
  }

  @visibleForTesting
  void setCurrentAudioFileForTesting(AudioFile? audioFile) {
    _enhancedService.setCurrentAudioFileForTesting(audioFile);
  }

  @visibleForTesting
  void setDurationForTesting(Duration duration) {
    _enhancedService.setDurationForTesting(duration);
  }

  @visibleForTesting
  void setPositionForTesting(Duration position) {
    _enhancedService.setPositionForTesting(position);
  }

  @visibleForTesting
  void setErrorForTesting(String error) {
    _enhancedService.setErrorForTesting(error);
  }

  @visibleForTesting
  void clearErrorForTesting() {
    _enhancedService.clearErrorForTesting();
  }

  /// Maps legacy PlaybackState to AppPlaybackState for testing compatibility
  AppPlaybackState _mapPlaybackStateToAppState(PlaybackState state) {
    switch (state) {
      case PlaybackState.stopped:
        return AppPlaybackState.stopped;
      case PlaybackState.playing:
        return AppPlaybackState.playing;
      case PlaybackState.paused:
        return AppPlaybackState.paused;
      case PlaybackState.loading:
        return AppPlaybackState.loading;
      case PlaybackState.error:
        return AppPlaybackState.error;
    }
  }
}
