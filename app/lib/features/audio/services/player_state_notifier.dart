import 'package:flutter/foundation.dart';
import 'package:from_fed_to_chain_app/core/utils/duration_utils.dart';

/// Canonical playback states for the audio player
enum AppPlaybackState {
  stopped,
  playing,
  paused,
  loading,
  completed,
  error,
}

/// State management for audio playback
///
/// Manages all playback state data including position, duration, speed,
/// and provides computed properties for UI consumption.
/// Emits granular state changes for optimized UI updates.
class PlayerStateNotifier extends ChangeNotifier {
  // Core state
  AppPlaybackState _playbackState = AppPlaybackState.stopped;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  double _playbackSpeed = 1.0;
  String? _errorMessage;

  // Read-only getters
  AppPlaybackState get playbackState => _playbackState;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  double get playbackSpeed => _playbackSpeed;
  String? get errorMessage => _errorMessage;

  // Computed properties
  bool get isPlaying => _playbackState == AppPlaybackState.playing;
  bool get isPaused => _playbackState == AppPlaybackState.paused;
  bool get isLoading => _playbackState == AppPlaybackState.loading;
  bool get hasError => _playbackState == AppPlaybackState.error;
  bool get isIdle => _playbackState == AppPlaybackState.stopped;
  bool get isCompleted => _playbackState == AppPlaybackState.completed;

  /// Progress as a value between 0.0 and 1.0
  double get progress {
    if (_totalDuration.inMilliseconds <= 0) return 0.0;
    final result =
        _currentPosition.inMilliseconds / _totalDuration.inMilliseconds;
    return result.clamp(0.0, 1.0);
  }

  /// Formatted current position for display (e.g., "1:23" or "1:23:45")
  String get formattedCurrentPosition {
    return DurationUtils.formatDuration(_currentPosition);
  }

  /// Formatted total duration for display (e.g., "5:42" or "1:05:30")
  String get formattedTotalDuration {
    return DurationUtils.formatDuration(_totalDuration);
  }

  // State update methods (called by PlayerController)

  /// Update the playback state
  void updateState(AppPlaybackState state) {
    if (_playbackState != state) {
      _playbackState = state;

      // Clear error when transitioning away from error state
      if (state != AppPlaybackState.error && _errorMessage != null) {
        _errorMessage = null;
      }

      notifyListeners();
    }
  }

  /// Update the current playback position
  void updatePosition(Duration position) {
    if (_currentPosition != position) {
      _currentPosition = position;
      notifyListeners();
    }
  }

  /// Update the total duration
  void updateDuration(Duration duration) {
    if (_totalDuration != duration) {
      _totalDuration = duration;
      notifyListeners();
    }
  }

  /// Update the playback speed
  void updateSpeed(double speed) {
    if (_playbackSpeed != speed) {
      _playbackSpeed = speed;
      notifyListeners();
    }
  }

  /// Set an error message and update state to error
  void setError(String error) {
    _playbackState = AppPlaybackState.error;
    _errorMessage = error;
    notifyListeners();
  }

  /// Clear the error message and reset to stopped state
  void clearError() {
    if (_errorMessage != null || _playbackState == AppPlaybackState.error) {
      _errorMessage = null;
      _playbackState = AppPlaybackState.stopped;
      notifyListeners();
    }
  }

  /// Reset position when playback completes
  void onPlaybackCompleted() {
    _playbackState = AppPlaybackState.completed;
    _currentPosition = Duration.zero;
    notifyListeners();
  }

  /// Reset all state to initial values
  void reset() {
    _playbackState = AppPlaybackState.stopped;
    _currentPosition = Duration.zero;
    _totalDuration = Duration.zero;
    _playbackSpeed = 1.0;
    _errorMessage = null;
    notifyListeners();
  }

  // Testing methods - only available in debug builds
  // Note: These are public (not @visibleForTesting) because they're used by
  // audio_player_service.dart's test helper methods
  void setPlaybackStateForTesting(AppPlaybackState state) {
    _playbackState = state;
    notifyListeners();
  }

  void setPositionForTesting(Duration position) {
    _currentPosition = position;
    notifyListeners();
  }

  void setDurationForTesting(Duration duration) {
    _totalDuration = duration;
    notifyListeners();
  }

  void setSpeedForTesting(double speed) {
    _playbackSpeed = speed;
    notifyListeners();
  }

  void setErrorForTesting(String error) {
    _playbackState = AppPlaybackState.error;
    _errorMessage = error;
    notifyListeners();
  }

  void clearErrorForTesting() {
    _errorMessage = null;
    _playbackState = AppPlaybackState.stopped;
    notifyListeners();
  }
}
