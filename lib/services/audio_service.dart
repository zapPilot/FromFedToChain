import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart' as audio_service_pkg;
import '../models/audio_file.dart';
import 'background_audio_handler.dart';
import 'content_service.dart';

enum PlaybackState {
  stopped,
  playing,
  paused,
  loading,
  error,
}

class AudioService extends ChangeNotifier {
  late AudioPlayer _audioPlayer;
  final BackgroundAudioHandler? _audioHandler;
  final ContentService? _contentService;

  // Current playback state
  PlaybackState _playbackState = PlaybackState.stopped;
  AudioFile? _currentAudioFile;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  double _playbackSpeed = 1.0;
  String? _errorMessage;
  bool _autoplayEnabled = true; // Default autoplay enabled

  // Getters
  PlaybackState get playbackState => _playbackState;
  AudioFile? get currentAudioFile => _currentAudioFile;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  double get playbackSpeed => _playbackSpeed;
  String? get errorMessage => _errorMessage;
  bool get autoplayEnabled => _autoplayEnabled;

  // Computed properties
  bool get isPlaying => _playbackState == PlaybackState.playing;
  bool get isPaused => _playbackState == PlaybackState.paused;
  bool get isLoading => _playbackState == PlaybackState.loading;
  bool get hasError => _playbackState == PlaybackState.error;
  bool get isIdle => _playbackState == PlaybackState.stopped;

  double get progress {
    if (_totalDuration.inMilliseconds == 0) return 0.0;
    return _currentPosition.inMilliseconds / _totalDuration.inMilliseconds;
  }

  String get formattedCurrentPosition {
    return _formatDuration(_currentPosition);
  }

  String get formattedTotalDuration {
    return _formatDuration(_totalDuration);
  }

  // Get current audio file ID for language switching
  String? get currentAudioId => _currentAudioFile?.id;

  AudioService(this._audioHandler, [this._contentService]) {
    print(
        '🎧 AudioService: Initializing with background handler: ${_audioHandler != null}');
    _initializePlayer();
  }

  void _initializePlayer() {
    if (_audioHandler != null) {
      print('🎧 AudioService: Using background audio handler');

      // Set up episode navigation callbacks
      _audioHandler!.setEpisodeNavigationCallbacks(
        onNext: _skipToNextEpisode,
        onPrevious: _skipToPreviousEpisode,
      );

      // Listen to background handler state changes
      _audioHandler!.playbackState.listen((state) {
        print(
            '🔄 AudioService: Background state changed - playing: ${state.playing}');

        _currentPosition = state.updatePosition;
        _totalDuration = _audioHandler!.duration;
        _playbackSpeed = state.speed;

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
      _audioHandler!.mediaItem.listen((mediaItem) {
        if (mediaItem != null) {
          _totalDuration = mediaItem.duration ?? Duration.zero;
          notifyListeners();
        }
      });
    } else {
      print('🎧 AudioService: Falling back to local audio player');

      // Fallback to local player if background handler not available
      _audioPlayer = AudioPlayer();

      // Listen to position changes
      _audioPlayer.positionStream.listen((position) {
        _currentPosition = position;
        notifyListeners();
      });

      // Listen to duration changes
      _audioPlayer.durationStream.listen((duration) {
        _totalDuration = duration ?? Duration.zero;
        notifyListeners();
      });

      // Listen to player state changes
      _audioPlayer.playerStateStream.listen((state) {
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

  // Play audio file (supports both local files and streaming URLs)
  Future<void> playAudio(AudioFile audioFile) async {
    if (_audioHandler != null) {
      print(
          '🎵 AudioService: Playing via background handler - ${audioFile.displayTitle}');

      try {
        _playbackState = PlaybackState.loading;
        _errorMessage = null;
        _currentAudioFile = audioFile;
        notifyListeners();

        await _audioHandler!.setAudioSource(
          audioFile.sourceUrl,
          title: audioFile.displayTitle,
          artist: 'David Chang',
          audioFile: audioFile,
        );

        await _audioHandler!.play();
        print('✅ AudioService: Background playback started');
      } catch (e) {
        _playbackState = PlaybackState.error;
        _errorMessage = 'Background audio failed: $e';

        if (kDebugMode) {
          print('❌ AudioService: Background playback error: $e');
          print('AudioFile: ${audioFile.id}');
          print('sourceUrl: ${audioFile.sourceUrl}');
        }
        notifyListeners();
      }
    } else {
      print(
          '🎵 AudioService: Playing via local player - ${audioFile.displayTitle}');

      // Fallback to original implementation
      try {
        _playbackState = PlaybackState.loading;
        _errorMessage = null;
        notifyListeners();

        // Stop current playback if playing different file
        final currentAudioId = _currentAudioFile?.id;
        if (currentAudioId != audioFile.id) {
          await _audioPlayer.stop();
          _currentAudioFile = audioFile;
          _currentPosition = Duration.zero;
          _totalDuration = Duration.zero;
        }

        // Always use sourceUrl for playback
        if (kDebugMode) {
          print('AudioService: Playing audio from sourceUrl');
          print('AudioService: sourceUrl:  [32m${audioFile.sourceUrl} [0m');
          print(
              'AudioService: Platform:  [36m${kIsWeb ? 'Web' : 'Mobile'} [0m');
        }

        if (kIsWeb) {
          throw Exception(
              'HLS streaming not supported on web. Use Android/iOS for full functionality.');
        } else {
          await _audioPlayer
              .setAudioSource(AudioSource.uri(Uri.parse(audioFile.sourceUrl)));
          await _audioPlayer.play();
        }

        await _audioPlayer.setSpeed(_playbackSpeed);
      } catch (e) {
        _playbackState = PlaybackState.error;
        // Provide helpful error messages for common issues
        if (e.toString().contains('HttpException') ||
            e.toString().contains('SocketException')) {
          _errorMessage =
              'Network error: Cannot access streaming URL. Check internet connection.';
        } else if (e.toString().contains('FormatException') ||
            e.toString().contains('UnsupportedError')) {
          _errorMessage =
              'Unsupported media format. Please try a different audio source.';
        } else if (e.toString().contains('PlayerException')) {
          _errorMessage = 'Audio player error: ${e.toString()}';
        } else {
          _errorMessage = 'Failed to play audio: $e';
        }
        if (kDebugMode) {
          print('AudioService playback error: $e');
          print('AudioFile: ${audioFile.id}');
          print('AudioService: Platform: ${kIsWeb ? 'Web' : 'Mobile'}');
          print('AudioService: sourceUrl: ${audioFile.sourceUrl}');
        }
        notifyListeners();
      }
    }
  }

  // Resume playback
  Future<void> resume() async {
    if (_audioHandler != null) {
      try {
        await _audioHandler!.play();
      } catch (e) {
        _playbackState = PlaybackState.error;
        _errorMessage = 'Failed to resume background playback: $e';
        notifyListeners();
      }
    } else {
      try {
        await _audioPlayer.play();
      } catch (e) {
        _playbackState = PlaybackState.error;
        _errorMessage = 'Failed to resume playback: $e';
        notifyListeners();
      }
    }
  }

  // Pause playback
  Future<void> pause() async {
    if (_audioHandler != null) {
      try {
        await _audioHandler!.pause();
      } catch (e) {
        _playbackState = PlaybackState.error;
        _errorMessage = 'Failed to pause background playback: $e';
        notifyListeners();
      }
    } else {
      try {
        await _audioPlayer.pause();
      } catch (e) {
        _playbackState = PlaybackState.error;
        _errorMessage = 'Failed to pause playback: $e';
        notifyListeners();
      }
    }
  }

  // Stop playback
  Future<void> stop() async {
    if (_audioHandler != null) {
      try {
        await _audioHandler!.stop();
        _currentPosition = Duration.zero;
      } catch (e) {
        _playbackState = PlaybackState.error;
        _errorMessage = 'Failed to stop background playback: $e';
        notifyListeners();
      }
    } else {
      try {
        await _audioPlayer.stop();
        _currentPosition = Duration.zero;
      } catch (e) {
        _playbackState = PlaybackState.error;
        _errorMessage = 'Failed to stop playback: $e';
        notifyListeners();
      }
    }
  }

  // Seek to position
  Future<void> seekTo(Duration position) async {
    if (_audioHandler != null) {
      try {
        await _audioHandler!.seek(position);
      } catch (e) {
        _playbackState = PlaybackState.error;
        _errorMessage = 'Failed to seek in background playback: $e';
        notifyListeners();
      }
    } else {
      try {
        await _audioPlayer.seek(position);
      } catch (e) {
        _playbackState = PlaybackState.error;
        _errorMessage = 'Failed to seek: $e';
        notifyListeners();
      }
    }
  }

  // Set playback speed
  Future<void> setPlaybackSpeed(double speed) async {
    try {
      _playbackSpeed = speed;

      if (_audioHandler != null) {
        await _audioHandler!.customAction('setSpeed', {'speed': speed});
      } else {
        await _audioPlayer.setSpeed(speed);
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to set playback speed: $e';
      notifyListeners();
    }
  }

  // Skip forward
  Future<void> skipForward(
      [Duration duration = const Duration(seconds: 30)]) async {
    if (_audioHandler != null) {
      await _audioHandler!
          .skipToNext(); // Uses 30-second skip in background handler
    } else {
      final newPosition = _currentPosition + duration;
      final maxPosition = _totalDuration;

      if (newPosition < maxPosition) {
        await seekTo(newPosition);
      } else {
        await seekTo(maxPosition);
      }
    }
  }

  // Skip backward
  Future<void> skipBackward(
      [Duration duration = const Duration(seconds: 10)]) async {
    if (_audioHandler != null) {
      await _audioHandler!
          .skipToPrevious(); // Uses 10-second skip in background handler
    } else {
      final newPosition = _currentPosition - duration;

      if (newPosition > Duration.zero) {
        await seekTo(newPosition);
      } else {
        await seekTo(Duration.zero);
      }
    }
  }

  // Toggle play/pause
  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await pause();
    } else if (isPaused) {
      await resume();
    }
  }

  // Episode navigation methods for lock screen controls
  Future<void> _skipToNextEpisode(AudioFile currentEpisode) async {
    if (_contentService == null) {
      print(
          '❌ AudioService: ContentService not available for episode navigation');
      return;
    }

    print(
        '⏭️ AudioService: Skipping to next episode from ${currentEpisode.id}');

    final nextEpisode = _contentService!.getNextEpisode(currentEpisode);
    if (nextEpisode != null) {
      await playAudio(nextEpisode);
      print('✅ AudioService: Switched to next episode: ${nextEpisode.id}');
    } else {
      print('📝 AudioService: No next episode available');
    }
  }

  Future<void> _skipToPreviousEpisode(AudioFile currentEpisode) async {
    if (_contentService == null) {
      print(
          '❌ AudioService: ContentService not available for episode navigation');
      return;
    }

    print(
        '⏮️ AudioService: Skipping to previous episode from ${currentEpisode.id}');

    final previousEpisode = _contentService!.getPreviousEpisode(currentEpisode);
    if (previousEpisode != null) {
      await playAudio(previousEpisode);
      print(
          '✅ AudioService: Switched to previous episode: ${previousEpisode.id}');
    } else {
      print('📝 AudioService: No previous episode available');
    }
  }

  // Switch audio to new language while maintaining playback position
  Future<void> switchLanguage(AudioFile newLanguageAudioFile) async {
    if (_currentAudioFile == null) {
      // No audio currently playing, just load the new audio
      await playAudio(newLanguageAudioFile);
      return;
    }

    // Check if this is the same content in a different language
    if (_currentAudioFile!.id != newLanguageAudioFile.id) {
      // Different content, just play normally
      await playAudio(newLanguageAudioFile);
      return;
    }

    print('🔄 AudioService: Switching language for ${newLanguageAudioFile.id}');

    try {
      // Capture current state
      final wasPlaying = isPlaying;
      final currentPosition = _currentPosition;

      // Set loading state
      _playbackState = PlaybackState.loading;
      _errorMessage = null;
      notifyListeners();

      if (_audioHandler != null) {
        // Background audio handler
        await _audioHandler!.setAudioSource(
          newLanguageAudioFile.sourceUrl,
          title: newLanguageAudioFile.displayTitle,
          artist: 'David Chang',
          initialPosition: currentPosition,
          audioFile: newLanguageAudioFile,
        );

        // Resume playback if it was playing
        if (wasPlaying) {
          await _audioHandler!.play();
        }
      } else {
        // Local audio player
        await _audioPlayer.setAudioSource(
          AudioSource.uri(Uri.parse(newLanguageAudioFile.sourceUrl)),
          initialPosition: currentPosition,
        );

        // Resume playback if it was playing
        if (wasPlaying) {
          await _audioPlayer.play();
        }
      }

      // Update current audio file
      _currentAudioFile = newLanguageAudioFile;

      print('✅ AudioService: Language switched successfully');
    } catch (e) {
      _playbackState = PlaybackState.error;
      _errorMessage = 'Failed to switch language: $e';

      if (kDebugMode) {
        print('❌ AudioService: Language switch error: $e');
        print('New AudioFile: ${newLanguageAudioFile.id}');
        print('New sourceUrl: ${newLanguageAudioFile.sourceUrl}');
      }
      notifyListeners();
    }
  }

  // Seek relative to current position
  Future<void> seekRelative(int seconds) async {
    final newPosition = _currentPosition + Duration(seconds: seconds);

    if (newPosition < Duration.zero) {
      await seekTo(Duration.zero);
    } else if (newPosition > _totalDuration) {
      await seekTo(_totalDuration);
    } else {
      await seekTo(newPosition);
    }
  }

  // Handle audio completion - triggers autoplay if enabled
  Future<void> _handleAudioCompletion() async {
    print(
        '🔄 AudioService: Audio completed. Autoplay enabled: $_autoplayEnabled');

    if (!_autoplayEnabled) {
      print('📝 AudioService: Autoplay disabled, stopping playback');
      return;
    }

    if (_contentService == null) {
      print('❌ AudioService: ContentService not available for autoplay');
      return;
    }

    if (_currentAudioFile == null) {
      print('❌ AudioService: No current audio file for autoplay');
      return;
    }

    try {
      final nextEpisode = _contentService!.getNextEpisode(_currentAudioFile!);
      if (nextEpisode != null) {
        print(
            '⏭️ AudioService: Autoplay starting next episode: ${nextEpisode.id}');

        // Small delay to ensure smooth transition
        await Future.delayed(const Duration(milliseconds: 500));

        await playAudio(nextEpisode);
        print('✅ AudioService: Autoplay completed successfully');
      } else {
        print('📝 AudioService: No next episode available for autoplay');
      }
    } catch (e) {
      print('❌ AudioService: Autoplay failed: $e');
      _playbackState = PlaybackState.error;
      _errorMessage = 'Autoplay failed: $e';
      notifyListeners();
    }
  }

  // Set autoplay preference
  void setAutoplayEnabled(bool enabled) {
    if (_autoplayEnabled != enabled) {
      _autoplayEnabled = enabled;
      print('🔄 AudioService: Autoplay ${enabled ? 'enabled' : 'disabled'}');
      notifyListeners();
    }
  }

  // Format duration for display
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${minutes}:${twoDigits(seconds)}';
    }
  }

  @override
  void dispose() {
    // Only dispose local audio player if not using background handler
    if (_audioHandler == null) {
      _audioPlayer.dispose();
    }
    super.dispose();
  }
}
