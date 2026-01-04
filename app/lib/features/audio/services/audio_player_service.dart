import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';
import 'package:from_fed_to_chain_app/features/content/services/playlist_service.dart';
import 'package:from_fed_to_chain_app/features/audio/services/audio_progress_tracker.dart';
import 'package:from_fed_to_chain_app/features/audio/services/background_audio_handler.dart';
import 'package:from_fed_to_chain_app/features/audio/services/background_player_adapter.dart';
import 'package:from_fed_to_chain_app/features/content/services/content_service.dart';
import 'package:from_fed_to_chain_app/features/audio/services/local_player_adapter.dart';
import 'package:from_fed_to_chain_app/features/audio/services/playback_navigation_service.dart';
import 'package:from_fed_to_chain_app/features/audio/services/player_adapter.dart';
import 'package:from_fed_to_chain_app/features/audio/services/player_controller.dart';
import 'package:from_fed_to_chain_app/features/audio/services/player_state_notifier.dart';

/// Unified audio service that coordinates all playback components
///
/// This service acts as the main coordinator for audio playbook functionality,
/// managing playback state, progress tracking, episode navigation, and
/// background audio support. It delegates operations to focused components
/// and manages state synchronization between them.
class AudioPlayerService extends ChangeNotifier {
  // Core components
  late final PlayerStateNotifier _stateNotifier;
  late final PlayerController _playerController;
  late final AudioProgressTracker _progressTracker;
  late final PlaybackNavigationService _navigationService;

  // Dependencies
  // Dependencies
  final BackgroundAudioHandler? _audioHandler;
  final ContentService? _contentService;
  final PlaylistService? _playlistService;
  final AudioPlayer? _providedAudioPlayer;

  // Current state
  AudioFile? _currentAudioFile;
  bool _disposed = false;
  bool _suspendProgressUpdates = false;

  AudioPlayerService(
    this._audioHandler,
    this._contentService,
    this._playlistService, [
    AudioPlayer? localAudioPlayer,
  ]) : _providedAudioPlayer = localAudioPlayer {
    if (kDebugMode) {
      print('🎧 AudioPlayerService: Initializing...');
      print(
          '🎧 Background handler: ${_audioHandler != null ? "PRESENT" : "NULL"}');
    }
    _initializeComponents();
    _setupStateListener();
  }

  /// Initialize all components and wire them together
  void _initializeComponents() {
    // Create state notifier (foundation)
    _stateNotifier = PlayerStateNotifier();

    // Create appropriate player adapter based on available handler
    final IPlayerAdapter playerAdapter;
    if (_audioHandler != null) {
      if (kDebugMode) {
        print('🎧 AudioPlayerService: Using background audio adapter');
      }
      playerAdapter = BackgroundPlayerAdapter(_audioHandler!);

      // Set up episode navigation callbacks for background handler
      _audioHandler!.setEpisodeNavigationCallbacks(
        onNext: (audioFile) => skipToNextEpisode(),
        onPrevious: (audioFile) => skipToPreviousEpisode(),
      );
    } else {
      if (kDebugMode) {
        print('🎧 AudioPlayerService: Using local audio adapter');
      }
      playerAdapter = LocalPlayerAdapter(audioPlayer: _providedAudioPlayer);
    }

    // Create player controller with adapter and state notifier
    _playerController = PlayerController(playerAdapter, _stateNotifier);

    // Create progress tracker
    _progressTracker = AudioProgressTracker(_contentService);

    // Create navigation service
    _navigationService = PlaybackNavigationService(
      _playlistService,
      _playerController,
      _progressTracker,
    );

    if (kDebugMode) {
      print('✅ AudioPlayerService: All components initialized successfully');
    }
  }

  /// Set up listener to propagate state changes to UI
  void _setupStateListener() {
    _stateNotifier.addListener(_onStateChange);
  }

  /// Handle state changes from PlayerStateNotifier
  void _onStateChange() {
    if (_disposed) return;

    // Update progress tracking if we have a current audio file
    if (!_suspendProgressUpdates && _currentAudioFile != null) {
      _progressTracker.updateProgress(
        _currentAudioFile!.id,
        _stateNotifier.currentPosition,
        _stateNotifier.totalDuration,
      );
    }

    if (_stateNotifier.playbackState == AppPlaybackState.error &&
        _stateNotifier.errorMessage == null) {
      _stateNotifier.setError('Background audio error');
      return;
    }

    // Handle episode completion
    if (_stateNotifier.playbackState == AppPlaybackState.completed &&
        _currentAudioFile != null) {
      unawaited(_handleEpisodeCompletion());
    }

    // Notify UI listeners
    notifyListeners();
  }

  /// Handle episode completion by delegating to navigation service
  Future<void> _handleEpisodeCompletion() async {
    if (_currentAudioFile != null) {
      // Mark episode as finished
      await _progressTracker.markEpisodeCompleted(_currentAudioFile!.id);

      // Handle repeat/autoplay logic
      final nextEpisode =
          await _navigationService.handleEpisodeCompletion(_currentAudioFile!);
      if (nextEpisode != null) {
        _currentAudioFile = nextEpisode;
      }
    }
  }

  // Public API methods (maintain backward compatibility)

  /// Play audio file (supports both local files and streaming URLs)
  Future<void> playAudio(AudioFile audioFile) async {
    try {
      if (kDebugMode) {
        print('▶️ AudioPlayerService: Playing audio: ${audioFile.title}');
      }

      _currentAudioFile = audioFile;

      // Record listen history
      try {
        await _contentService?.addToListenHistory(audioFile);
      } catch (_) {
        // Continue even if history fails
      }

      final totalForResume = _stateNotifier.totalDuration.inMilliseconds > 0
          ? _stateNotifier.totalDuration
          : (audioFile.duration ?? Duration.zero);
      final resumePosition = _progressTracker.calculateResumePosition(
        audioFile.id,
        totalForResume,
      );

      // Delegate to player controller
      await _playerController.play(
        audioFile,
        initialPosition: resumePosition > Duration.zero ? resumePosition : null,
      );

      if (resumePosition > Duration.zero) {
        _stateNotifier.updatePosition(resumePosition);
      }

      if (kDebugMode) {
        print('✅ AudioPlayerService: Successfully started playback');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ AudioPlayerService: Failed to play audio: $e');
      }
      rethrow;
    }
  }

  /// Toggle play/pause
  Future<void> togglePlayPause() async {
    if (_stateNotifier.isPlaying) {
      await _playerController.pause();
    } else {
      await _playerController.resume();
    }
  }

  /// Skip to next episode
  Future<void> skipToNextEpisode() async {
    if (_currentAudioFile != null) {
      final nextEpisode =
          await _navigationService.skipToNext(_currentAudioFile!);
      if (nextEpisode != null) {
        _currentAudioFile = nextEpisode;
      }
    }
  }

  /// Skip to previous episode
  Future<void> skipToPreviousEpisode() async {
    if (_currentAudioFile != null) {
      final previousEpisode =
          await _navigationService.skipToPrevious(_currentAudioFile!);
      if (previousEpisode != null) {
        _currentAudioFile = previousEpisode;
      }
    }
  }

  /// Seek to specific position
  Future<void> seekTo(Duration position) async {
    await _playerController.seek(position);
  }

  /// Skip forward by 30 seconds
  Future<void> skipForward() async {
    await _playerController.skipForward();
  }

  /// Skip backward by 10 seconds
  Future<void> skipBackward() async {
    await _playerController.skipBackward();
  }

  /// Set playback speed
  Future<void> setPlaybackSpeed(double speed) async {
    await _playerController.setSpeed(speed);
    _suspendProgressUpdates = true;
    _stateNotifier.updateSpeed(speed);
    _suspendProgressUpdates = false;
    notifyListeners();
  }

  /// Set autoplay preference
  void setAutoplayEnabled(bool enabled) {
    _navigationService.setAutoplayEnabled(enabled);
    notifyListeners();
  }

  /// Set repeat preference
  void setRepeatEnabled(bool enabled) {
    _navigationService.setRepeatEnabled(enabled);
    notifyListeners();
  }

  // Getters (delegate to appropriate components)

  /// Current playback state
  AppPlaybackState get playbackState => _stateNotifier.playbackState;

  /// Currently playing audio file
  AudioFile? get currentAudioFile => _currentAudioFile;

  /// Current playback position
  Duration get currentPosition => _stateNotifier.currentPosition;

  /// Total duration of current audio
  Duration get totalDuration => _stateNotifier.totalDuration;

  /// Current playback speed
  double get playbackSpeed => _stateNotifier.playbackSpeed;

  /// Current error message (if any)
  String? get errorMessage => _stateNotifier.errorMessage;

  /// Whether autoplay is enabled
  bool get autoplayEnabled => _navigationService.autoplayEnabled;

  /// Whether repeat is enabled
  bool get repeatEnabled => _navigationService.repeatEnabled;

  // Computed properties (delegate to state notifier)

  /// Whether audio is currently playing
  bool get isPlaying => _stateNotifier.isPlaying;

  /// Whether audio is paused
  bool get isPaused => _stateNotifier.isPaused;

  /// Whether audio is loading
  bool get isLoading => _stateNotifier.isLoading;

  /// Whether there's an error
  bool get hasError => _stateNotifier.hasError;

  /// Whether player is idle/stopped
  bool get isIdle => _stateNotifier.isIdle;

  /// Playback progress (0.0 to 1.0)
  double get progress => _stateNotifier.progress;

  /// Formatted current position
  String get formattedCurrentPosition =>
      _stateNotifier.formattedCurrentPosition;

  /// Formatted total duration
  String get formattedTotalDuration => _stateNotifier.formattedTotalDuration;

  /// Current audio ID (convenience getter)
  String? get currentAudioId => _currentAudioFile?.id;

  // Additional convenience methods

  /// Toggle autoplay
  void toggleAutoplay() {
    _navigationService.toggleAutoplay();
    notifyListeners();
  }

  /// Toggle repeat
  void toggleRepeat() {
    _navigationService.toggleRepeat();
    notifyListeners();
  }

  /// Check if audio file is valid
  bool isValidAudioFile(AudioFile? audioFile) {
    return _playerController.isValidAudioFile(audioFile);
  }

  /// Save current playback state
  void savePlaybackState() {
    if (_currentAudioFile != null) {
      _progressTracker.saveProgress(
        _currentAudioFile!.id,
        _stateNotifier.currentPosition,
        _stateNotifier.totalDuration,
      );
    }
  }

  /// Manually update progress and persist it through the tracker
  void updateProgress(Duration position) {
    final clampedPosition = position < Duration.zero ? Duration.zero : position;
    _stateNotifier.updatePosition(clampedPosition);

    if (_currentAudioFile == null) {
      notifyListeners();
      return;
    }

    final total = _stateNotifier.totalDuration.inMilliseconds > 0
        ? _stateNotifier.totalDuration
        : (_currentAudioFile?.duration ?? Duration.zero);

    _progressTracker.updateProgress(
      _currentAudioFile!.id,
      clampedPosition,
      total,
    );
    notifyListeners();
  }

  /// Surface playback errors through the state notifier
  void handlePlaybackError(String message) {
    _stateNotifier.setError(message);
    notifyListeners();
  }

  /// Restore the saved playback position for the provided audio file
  Future<void> restorePlaybackPosition(AudioFile audioFile) async {
    _currentAudioFile = audioFile;
    final total = _stateNotifier.totalDuration.inMilliseconds > 0
        ? _stateNotifier.totalDuration
        : (audioFile.duration ?? Duration.zero);
    final resumePosition = _progressTracker.calculateResumePosition(
      audioFile.id,
      total,
    );
    _stateNotifier.updatePosition(resumePosition);
    notifyListeners();
  }

  /// Allow callers to manually trigger completion handling
  Future<void> onEpisodeCompletedManually() async {
    await _handleEpisodeCompletion();
  }

  // Legacy method aliases for backward compatibility

  /// Play audio file (alias for playAudio)
  Future<void> play(AudioFile audioFile) => playAudio(audioFile);

  /// Pause playback
  Future<void> pause() => _playerController.pause();

  /// Resume playback
  Future<void> resume() => _playerController.resume();

  /// Stop playback
  Future<void> stop() async {
    await _playerController.stop();
    _suspendProgressUpdates = true;
    _stateNotifier.updateState(AppPlaybackState.stopped);
    _stateNotifier.updatePosition(Duration.zero);
    _suspendProgressUpdates = false;
  }

  /// Skip to next (alias)
  Future<void> skipToNext() => skipToNextEpisode();

  /// Skip to previous (alias)
  Future<void> skipToPrevious() => skipToPreviousEpisode();

  /// Seek forward (alias)
  Future<void> seekForward() => skipForward();

  /// Seek backward (alias)
  Future<void> seekBackward() => skipBackward();

  /// Enable autoplay (alias)
  void enableAutoplay(bool enabled) => setAutoplayEnabled(enabled);

  // Testing methods - only available in debug builds
  @visibleForTesting
  void setPlaybackStateForTesting(AppPlaybackState state) {
    _suspendProgressUpdates = true;
    _stateNotifier.setPlaybackStateForTesting(state);
    _suspendProgressUpdates = false;
  }

  @visibleForTesting
  void setCurrentAudioFileForTesting(AudioFile? audioFile) {
    _currentAudioFile = audioFile;
    notifyListeners();
  }

  @visibleForTesting
  void setDurationForTesting(Duration duration) {
    _suspendProgressUpdates = true;
    _stateNotifier.setDurationForTesting(duration);
    _suspendProgressUpdates = false;
  }

  @visibleForTesting
  void setPositionForTesting(Duration position) {
    _suspendProgressUpdates = true;
    _stateNotifier.setPositionForTesting(position);
    _suspendProgressUpdates = false;
  }

  @visibleForTesting
  void setErrorForTesting(String error) {
    _stateNotifier.setErrorForTesting(error);
  }

  @visibleForTesting
  void clearErrorForTesting() {
    _stateNotifier.clearErrorForTesting();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    if (kDebugMode) {
      print('🗑️ AudioPlayerService: Disposing all components...');
    }

    // Remove state change listener
    _stateNotifier.removeListener(_onStateChange);

    // Dispose all components in reverse order
    _playerController.dispose();
    _stateNotifier.dispose();

    super.dispose();

    if (kDebugMode) {
      print('✅ AudioPlayerService: Disposal complete');
    }
  }
}
