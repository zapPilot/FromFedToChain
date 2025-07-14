import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/audio_file.dart';

enum PlaybackState {
  stopped,
  playing,
  paused,
  loading,
  error,
}

class AudioService extends ChangeNotifier {
  late AudioPlayer _audioPlayer;
  
  // Current playback state
  PlaybackState _playbackState = PlaybackState.stopped;
  AudioFile? _currentAudioFile;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  double _playbackSpeed = 1.0;
  String? _errorMessage;

  // Getters
  PlaybackState get playbackState => _playbackState;
  AudioFile? get currentAudioFile => _currentAudioFile;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  double get playbackSpeed => _playbackSpeed;
  String? get errorMessage => _errorMessage;
  
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

  AudioService() {
    _initializePlayer();
  }

  void _initializePlayer() {
    _audioPlayer = AudioPlayer();
    
    // Listen to position changes
    _audioPlayer.onPositionChanged.listen((position) {
      _currentPosition = position;
      notifyListeners();
    });
    
    // Listen to duration changes
    _audioPlayer.onDurationChanged.listen((duration) {
      _totalDuration = duration;
      notifyListeners();
    });
    
    // Listen to player state changes
    _audioPlayer.onPlayerStateChanged.listen((state) {
      switch (state) {
        case PlayerState.playing:
          _playbackState = PlaybackState.playing;
          break;
        case PlayerState.paused:
          _playbackState = PlaybackState.paused;
          break;
        case PlayerState.stopped:
          _playbackState = PlaybackState.stopped;
          break;
        case PlayerState.completed:
          _playbackState = PlaybackState.stopped;
          _currentPosition = Duration.zero;
          break;
        case PlayerState.disposed:
          _playbackState = PlaybackState.stopped;
          break;
      }
      notifyListeners();
    });
  }

  // Play audio file
  Future<void> playAudio(AudioFile audioFile) async {
    try {
      _playbackState = PlaybackState.loading;
      _errorMessage = null;
      notifyListeners();

      // Stop current playback if playing different file
      if (_currentAudioFile?.filePath != audioFile.filePath) {
        await _audioPlayer.stop();
        _currentAudioFile = audioFile;
        _currentPosition = Duration.zero;
        _totalDuration = Duration.zero;
      }

      await _audioPlayer.play(DeviceFileSource(audioFile.filePath));
      await _audioPlayer.setPlaybackRate(_playbackSpeed);
      
    } catch (e) {
      _playbackState = PlaybackState.error;
      _errorMessage = 'Failed to play audio: $e';
      notifyListeners();
    }
  }

  // Resume playback
  Future<void> resume() async {
    try {
      await _audioPlayer.resume();
    } catch (e) {
      _playbackState = PlaybackState.error;
      _errorMessage = 'Failed to resume playback: $e';
      notifyListeners();
    }
  }

  // Pause playback
  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      _playbackState = PlaybackState.error;
      _errorMessage = 'Failed to pause playback: $e';
      notifyListeners();
    }
  }

  // Stop playback
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _currentPosition = Duration.zero;
    } catch (e) {
      _playbackState = PlaybackState.error;
      _errorMessage = 'Failed to stop playback: $e';
      notifyListeners();
    }
  }

  // Seek to position
  Future<void> seekTo(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      _playbackState = PlaybackState.error;
      _errorMessage = 'Failed to seek: $e';
      notifyListeners();
    }
  }

  // Set playback speed
  Future<void> setPlaybackSpeed(double speed) async {
    try {
      _playbackSpeed = speed;
      await _audioPlayer.setPlaybackRate(speed);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to set playback speed: $e';
      notifyListeners();
    }
  }

  // Skip forward
  Future<void> skipForward([Duration duration = const Duration(seconds: 15)]) async {
    final newPosition = _currentPosition + duration;
    final maxPosition = _totalDuration;
    
    if (newPosition < maxPosition) {
      await seekTo(newPosition);
    } else {
      await seekTo(maxPosition);
    }
  }

  // Skip backward
  Future<void> skipBackward([Duration duration = const Duration(seconds: 15)]) async {
    final newPosition = _currentPosition - duration;
    
    if (newPosition > Duration.zero) {
      await seekTo(newPosition);
    } else {
      await seekTo(Duration.zero);
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
    _audioPlayer.dispose();
    super.dispose();
  }
}