import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart' as audio_service_pkg;

import '../models/audio_file.dart';
import 'background_audio_handler.dart';
import 'content_service.dart';

/// Playback states for the audio player
enum PlaybackState {
  stopped,
  playing,
  paused,
  loading,
  error,
}

/// Main audio service for managing playback with background support
class AudioService extends ChangeNotifier {
  late AudioPlayer _audioPlayer;
  final BackgroundAudioHandler? _audioHandler;
  final ContentService? _contentService;

  // Stream subscriptions for proper disposal
  StreamSubscription? _playbackStateSubscription;
  StreamSubscription? _mediaItemSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _playerStateSubscription;

  // Disposal guard to prevent multiple dispose calls
  bool _disposed = false;

  // Current playback state
  PlaybackState _playbackState = PlaybackState.stopped;
  AudioFile? _currentAudioFile;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  double _playbackSpeed = 1.0;

  // Progress tracking throttling
  DateTime _lastProgressUpdate = DateTime(0);
  String? _errorMessage;
  bool _autoplayEnabled = true;
  bool _repeatEnabled = false; // New: repeat current episode

  // Getters
  PlaybackState get playbackState => _playbackState;
  AudioFile? get currentAudioFile => _currentAudioFile;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  double get playbackSpeed => _playbackSpeed;
  String? get errorMessage => _errorMessage;
  bool get autoplayEnabled => _autoplayEnabled;
  bool get repeatEnabled => _repeatEnabled;

  // Computed properties
  bool get isPlaying => _playbackState == PlaybackState.playing;
  bool get isPaused => _playbackState == PlaybackState.paused;
  bool get isLoading => _playbackState == PlaybackState.loading;
  bool get hasError => _playbackState == PlaybackState.error;
  bool get isIdle => _playbackState == PlaybackState.stopped;

  double get progress {
    if (_totalDuration.inMilliseconds <= 0) return 0.0;
    final result =
        _currentPosition.inMilliseconds / _totalDuration.inMilliseconds;
    return result.clamp(0.0, 1.0);
  }

  String get formattedCurrentPosition {
    return _formatDuration(_currentPosition);
  }

  String get formattedTotalDuration {
    return _formatDuration(_totalDuration);
  }

  String? get currentAudioId => _currentAudioFile?.id;

  AudioService(this._audioHandler, [this._contentService]) {
    if (kDebugMode) {
      print('🎧 AudioService: Initializing...');
      print(
          '🎧 Background handler: ${_audioHandler != null ? "PRESENT" : "NULL"}');
      if (_audioHandler != null) {
        print('🎧 Handler type: ${_audioHandler.runtimeType}');
        print('🎧 Will use BACKGROUND AUDIO with media session support');
      } else {
        print('🎧 Will fallback to LOCAL PLAYER (no media session)');
      }
    }
    _initializePlayer();
  }

  void _initializePlayer() {
    if (_audioHandler != null) {
      if (kDebugMode) {
        print('🎧 AudioService: Using background audio handler');
      }

      // Set up episode navigation callbacks
      _audioHandler!.setEpisodeNavigationCallbacks(
        onNext: (audioFile) => _skipToNextEpisode(),
        onPrevious: (audioFile) => _skipToPreviousEpisode(),
      );

      // Listen to background handler state changes
      _playbackStateSubscription = _audioHandler!.playbackState.listen((state) {
        if (kDebugMode) {
          print(
              '🔄 AudioService: Background state changed - playing: ${state.playing}');
        }

        _currentPosition = state.updatePosition;
        _totalDuration = _audioHandler!.duration;
        _playbackSpeed = state.speed;
        _updateEpisodeProgress();

        // Map audio_service states to our internal states
        switch (state.processingState) {
          case audio_service_pkg.AudioProcessingState.idle:
            _playbackState = PlaybackState.stopped;
            break;
          case audio_service_pkg.AudioProcessingState.loading:
          case audio_service_pkg.AudioProcessingState.buffering:
            _playbackState = PlaybackState.loading;
            break;
          case audio_service_pkg.AudioProcessingState.ready:
            _playbackState =
                state.playing ? PlaybackState.playing : PlaybackState.paused;
            break;
          case audio_service_pkg.AudioProcessingState.completed:
            _playbackState = PlaybackState.stopped;
            _currentPosition = Duration.zero;
            _handleAudioCompletion();
            break;
          case audio_service_pkg.AudioProcessingState.error:
            _playbackState = PlaybackState.error;
            _errorMessage = 'Background audio error';
            break;
        }
        notifyListeners();
      });

      // Listen to media item changes
      _mediaItemSubscription = _audioHandler!.mediaItem.listen((mediaItem) {
        if (mediaItem != null) {
          _totalDuration = mediaItem.duration ?? Duration.zero;
          notifyListeners();
        }
      });
    } else {
      if (kDebugMode) {
        print('🎧 AudioService: Falling back to local audio player');
      }

      // Fallback to local player if background handler not available
      _audioPlayer = AudioPlayer();

      // Listen to position changes
      _positionSubscription = _audioPlayer.positionStream.listen((position) {
        _currentPosition = position;
        _updateEpisodeProgress();
        notifyListeners();
      });

      // Listen to duration changes
      _durationSubscription = _audioPlayer.durationStream.listen((duration) {
        _totalDuration = duration ?? Duration.zero;
        notifyListeners();
      });

      // Listen to player state changes
      _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
        switch (state.processingState) {
          case ProcessingState.idle:
            _playbackState = PlaybackState.stopped;
            break;
          case ProcessingState.loading:
            _playbackState = PlaybackState.loading;
            break;
          case ProcessingState.buffering:
            _playbackState = PlaybackState.loading;
            break;
          case ProcessingState.ready:
            _playbackState =
                state.playing ? PlaybackState.playing : PlaybackState.paused;
            break;
          case ProcessingState.completed:
            _playbackState = PlaybackState.stopped;
            _currentPosition = Duration.zero;
            _handleAudioCompletion();
            break;
        }
        notifyListeners();
      });
    }
  }

  /// Play audio file (supports both local files and streaming URLs)
  Future<void> playAudio(AudioFile audioFile) async {
    try {
      if (kDebugMode) {
        print('▶️ AudioService: Playing audio: ${audioFile.title}');
        print('🎵 Audio URL: ${audioFile.streamingUrl}');
      }

      _playbackState = PlaybackState.loading;
      _currentAudioFile = audioFile;
      _errorMessage = null;
      // Record listen history
      try {
        await _contentService?.addToListenHistory(audioFile);
      } catch (_) {}
      notifyListeners();

      if (_audioHandler != null) {
        // Use background audio handler
        await _audioHandler!.setAudioSource(
          audioFile.streamingUrl,
          title: audioFile.title,
          artist: 'From Fed to Chain',
          audioFile: audioFile,
        );
        await _audioHandler!.play();
      } else {
        // Fallback to local audio player
        await _audioPlayer.setUrl(audioFile.streamingUrl);
        await _audioPlayer.play();
      }

      if (kDebugMode) {
        print(
            '✅ AudioService: Successfully started playback for: ${audioFile.title}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ AudioService: Failed to play audio: $e');
      }
      _playbackState = PlaybackState.error;
      _errorMessage = 'Failed to play audio: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Set autoplay preference
  void setAutoplayEnabled(bool enabled) {
    if (_autoplayEnabled != enabled) {
      _autoplayEnabled = enabled;
      if (kDebugMode) {
        print('🔄 AudioService: Autoplay ${enabled ? 'enabled' : 'disabled'}');
      }
      notifyListeners();
    }
  }

  /// Set repeat preference
  void setRepeatEnabled(bool enabled) {
    if (_repeatEnabled != enabled) {
      _repeatEnabled = enabled;
      if (kDebugMode) {
        print('🔄 AudioService: Repeat ${enabled ? 'enabled' : 'disabled'}');
      }
      notifyListeners();
    }
  }

  /// Toggle play/pause
  Future<void> togglePlayPause() async {
    if (_audioHandler != null) {
      if (isPlaying) {
        await _audioHandler!.pause();
      } else {
        await _audioHandler!.play();
      }
    } else {
      if (isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
    }
  }

  /// Public method to skip to next episode
  Future<void> skipToNextEpisode() async {
    await _skipToNextEpisode();
  }

  /// Public method to skip to previous episode
  Future<void> skipToPreviousEpisode() async {
    await _skipToPreviousEpisode();
  }

  /// Seek to specific position
  Future<void> seekTo(Duration position) async {
    if (_audioHandler != null) {
      await _audioHandler!.seek(position);
    } else {
      await _audioPlayer.seek(position);
    }
  }

  /// Skip forward by 30 seconds
  Future<void> skipForward() async {
    if (_audioHandler != null) {
      await _audioHandler!.fastForward();
    } else {
      final newPosition = _currentPosition + const Duration(seconds: 30);
      final seekPosition =
          newPosition < _totalDuration ? newPosition : _totalDuration;
      await _audioPlayer.seek(seekPosition);
    }
  }

  /// Skip backward by 10 seconds
  Future<void> skipBackward() async {
    if (_audioHandler != null) {
      await _audioHandler!.rewind();
    } else {
      final newPosition = _currentPosition - const Duration(seconds: 10);
      final seekPosition =
          newPosition > Duration.zero ? newPosition : Duration.zero;
      await _audioPlayer.seek(seekPosition);
    }
  }

  /// Set playback speed
  Future<void> setPlaybackSpeed(double speed) async {
    try {
      if (_audioHandler != null) {
        await _audioHandler!.customAction('setSpeed', {'speed': speed});
      } else {
        await _audioPlayer.setSpeed(speed);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ AudioService: Failed to set speed on handler: $e');
      }
      // Continue to update internal speed even if handler fails
    }
    _playbackSpeed = speed;
    notifyListeners();
  }

  /// Handle audio completion (repeat, autoplay, or stop)
  Future<void> _handleAudioCompletion() async {
    if (kDebugMode) {
      print(
          '🎵 AudioService: Audio completed. Repeat: $_repeatEnabled, Autoplay: $_autoplayEnabled');
    }

    // Mark episode as finished in ContentService
    if (_contentService != null && _currentAudioFile != null) {
      try {
        await _contentService!.markEpisodeAsFinished(_currentAudioFile!.id);
        if (kDebugMode) {
          print(
              '✅ AudioService: Episode marked as finished: ${_currentAudioFile!.id}');
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ AudioService: Failed to mark episode as finished: $e');
        }
        // Continue with repeat/autoplay even if marking fails
      }
    }

    // Repeat mode takes precedence over autoplay
    if (_repeatEnabled && _currentAudioFile != null) {
      if (kDebugMode) {
        print('🔁 AudioService: Repeating current episode');
      }
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        await playAudio(_currentAudioFile!);
        if (kDebugMode) {
          print('✅ AudioService: Repeat completed successfully');
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ AudioService: Repeat failed: $e');
        }
        _playbackState = PlaybackState.error;
        _errorMessage = 'Repeat failed: $e';
        notifyListeners();
      }
      return;
    }

    if (!_autoplayEnabled) {
      if (kDebugMode) {
        print('📝 AudioService: Autoplay disabled, stopping playback');
      }
      return;
    }

    if (_contentService == null) {
      if (kDebugMode) {
        print('❌ AudioService: ContentService not available for autoplay');
      }
      return;
    }

    if (_currentAudioFile == null) {
      if (kDebugMode) {
        print('❌ AudioService: No current audio file for autoplay');
      }
      return;
    }

    try {
      final nextEpisode = _contentService!.getNextEpisode(_currentAudioFile!);
      if (nextEpisode != null) {
        if (kDebugMode) {
          print(
              '⏭️ AudioService: Autoplay starting next episode: ${nextEpisode.id}');
        }

        // Small delay to ensure smooth transition
        await Future.delayed(const Duration(milliseconds: 500));

        await playAudio(nextEpisode);
        if (kDebugMode) {
          print('✅ AudioService: Autoplay completed successfully');
        }
      } else {
        if (kDebugMode) {
          print('📝 AudioService: No next episode available for autoplay');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ AudioService: Autoplay failed: $e');
      }
      _playbackState = PlaybackState.error;
      _errorMessage = 'Autoplay failed: $e';
      notifyListeners();
    }
  }

  /// Format duration for display
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '$minutes:${twoDigits(seconds)}';
    }
  }

  /// Test method to verify media session is working
  Future<void> testMediaSession() async {
    if (_audioHandler != null) {
      if (kDebugMode) {
        print('🧪 Calling test method on background handler...');
      }
      try {
        await _audioHandler!.testMediaSession();
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ AudioService: Media session test failed: $e');
        }
        // Continue gracefully - media session errors shouldn't crash the app
      }
    } else {
      if (kDebugMode) {
        print('❌ Cannot test media session - no background handler available');
      }
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

  /// Skip to next episode
  Future<void> _skipToNextEpisode() async {
    if (_contentService == null || _currentAudioFile == null) {
      if (kDebugMode) {
        print(
            '❌ AudioService: Cannot skip to next - no content service or current audio');
      }
      return;
    }

    try {
      final nextEpisode = _contentService!.getNextEpisode(_currentAudioFile!);
      if (nextEpisode != null) {
        if (kDebugMode) {
          print('⏭️ AudioService: Skipping to next episode: ${nextEpisode.id}');
        }
        await playAudio(nextEpisode);
      } else {
        if (kDebugMode) {
          print('📝 AudioService: No next episode available');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ AudioService: Failed to skip to next episode: $e');
      }
      _playbackState = PlaybackState.error;
      _errorMessage = 'Failed to skip to next episode: $e';
      notifyListeners();
    }
  }

  /// Skip to previous episode
  Future<void> _skipToPreviousEpisode() async {
    if (_contentService == null || _currentAudioFile == null) {
      if (kDebugMode) {
        print(
            '❌ AudioService: Cannot skip to previous - no content service or current audio');
      }
      return;
    }

    try {
      final previousEpisode =
          _contentService!.getPreviousEpisode(_currentAudioFile!);
      if (previousEpisode != null) {
        if (kDebugMode) {
          print(
              '⏮️ AudioService: Skipping to previous episode: ${previousEpisode.id}');
        }
        await playAudio(previousEpisode);
      } else {
        if (kDebugMode) {
          print('📝 AudioService: No previous episode available');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ AudioService: Failed to skip to previous episode: $e');
      }
      _playbackState = PlaybackState.error;
      _errorMessage = 'Failed to skip to previous episode: $e';
      notifyListeners();
    }
  }

  /// Update episode progress in ContentService
  void _updateEpisodeProgress() {
    if (_contentService == null || _currentAudioFile == null) {
      return;
    }

    // Throttle progress updates to avoid excessive calls
    final now = DateTime.now();
    if (now.difference(_lastProgressUpdate).inMilliseconds < 1000) {
      return;
    }
    _lastProgressUpdate = now;

    if (_totalDuration.inMilliseconds > 0) {
      final progress =
          _currentPosition.inMilliseconds / _totalDuration.inMilliseconds;
      final clampedProgress = progress.clamp(0.0, 1.0);

      // Only update if progress is significant (avoid spam)
      if (clampedProgress >= 0.01) {
        _contentService!
            .updateEpisodeCompletion(_currentAudioFile!.id, clampedProgress);

        if (kDebugMode && clampedProgress % 0.1 < 0.01) {
          // Log every 10% progress
          print(
              '📊 AudioService: Episode ${_currentAudioFile!.id} progress: ${(clampedProgress * 100).toInt()}%');
        }
      }
    }
  }

  /// Play audio file (alias for playAudio for test compatibility)
  Future<void> play(AudioFile audioFile) => playAudio(audioFile);

  /// Pause playback
  Future<void> pause() async {
    if (_audioHandler != null) {
      await _audioHandler!.pause();
    } else {
      await _audioPlayer.pause();
    }
  }

  /// Resume playback
  Future<void> resume() async {
    if (_audioHandler != null) {
      await _audioHandler!.play();
    } else {
      await _audioPlayer.play();
    }
  }

  /// Stop playback
  Future<void> stop() async {
    if (_audioHandler != null) {
      await _audioHandler!.stop();
    } else {
      await _audioPlayer.stop();
    }
    _playbackState = PlaybackState.stopped;
    _currentPosition = Duration.zero;
    notifyListeners();
  }

  /// Toggle autoplay
  void toggleAutoplay() {
    setAutoplayEnabled(!_autoplayEnabled);
  }

  /// Toggle repeat
  void toggleRepeat() {
    setRepeatEnabled(!_repeatEnabled);
  }

  /// Enable autoplay (alias for setAutoplayEnabled)
  void enableAutoplay(bool enabled) {
    setAutoplayEnabled(enabled);
  }

  /// Handle episode completion (public method)
  Future<void> onEpisodeCompleted() => _handleAudioCompletion();

  /// Update progress manually
  void updateProgress(Duration position) {
    _currentPosition = position;
    _updateEpisodeProgress();
    notifyListeners();
  }

  /// Handle playback error
  void handlePlaybackError(String message) {
    _playbackState = PlaybackState.error;
    _errorMessage = message;
    notifyListeners();
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
    if (audioFile == null) return false;
    return audioFile.streamingUrl.trim().isNotEmpty;
  }

  /// Save playback state
  void savePlaybackState() {
    if (_contentService != null && _currentAudioFile != null) {
      final progress = _totalDuration.inMilliseconds > 0
          ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
          : 0.0;
      _contentService!.updateEpisodeCompletion(_currentAudioFile!.id, progress);
    }
  }

  /// Restore playback position
  Future<void> restorePlaybackPosition(AudioFile audioFile) async {
    if (_contentService != null) {
      final completion = _contentService!.getEpisodeCompletion(audioFile.id);
      if (completion > 0.0 && _totalDuration.inMilliseconds > 0) {
        final position = Duration(
            milliseconds: (_totalDuration.inMilliseconds * completion).round());
        _currentPosition = position;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    if (_disposed) {
      return; // Already disposed, nothing to do
    }

    _disposed = true;

    // Cancel all stream subscriptions
    _playbackStateSubscription?.cancel();
    _mediaItemSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();

    // Only dispose local audio player if not using background handler
    if (_audioHandler == null) {
      _audioPlayer.dispose();
    }
    super.dispose();
  }

  // Testing methods - only available in debug builds
  @visibleForTesting
  void setPlaybackStateForTesting(PlaybackState state) {
    _playbackState = state;
    notifyListeners();
  }

  @visibleForTesting
  void setCurrentAudioFileForTesting(AudioFile? audioFile) {
    _currentAudioFile = audioFile;
    notifyListeners();
  }

  @visibleForTesting
  void setDurationForTesting(Duration duration) {
    _totalDuration = duration;
    notifyListeners();
  }

  @visibleForTesting
  void setPositionForTesting(Duration position) {
    _currentPosition = position;
    notifyListeners();
  }

  @visibleForTesting
  void setErrorForTesting(String error) {
    _playbackState = PlaybackState.error;
    _errorMessage = error;
    notifyListeners();
  }

  @visibleForTesting
  void clearErrorForTesting() {
    _errorMessage = null;
    _playbackState = PlaybackState.stopped;
    notifyListeners();
  }
}
