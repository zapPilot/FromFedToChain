import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
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
          _playbackState = state.playing ? PlaybackState.playing : PlaybackState.paused;
          break;
        case ProcessingState.completed:
          _playbackState = PlaybackState.stopped;
          _currentPosition = Duration.zero;
          break;
      }
      notifyListeners();
    });
  }

  // Play audio file (supports both local files and streaming URLs)
  Future<void> playAudio(AudioFile audioFile) async {
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

      // Use appropriate audio source based on file type and platform
      if (audioFile.isStreamingFile) {
        final streamingUrl = audioFile.streamingUrl;
        if (streamingUrl == null) {
          throw Exception('Streaming URL not available for ${audioFile.id}');
        }
        
        if (kDebugMode) {
          final urlType = audioFile.isUsingDirectSignedUrl ? 'pre-signed' : 'constructed';
          print('AudioService: Playing streaming audio ($urlType)');
          print('AudioService: Streaming URL: $streamingUrl');
          print('AudioService: Platform: ${kIsWeb ? 'Web' : 'Mobile'}');
        }
        
        if (kIsWeb) {
          // Web platform: Show helpful message for HLS limitation
          throw Exception('HLS streaming not supported on web. Use Android/iOS for full functionality.');
        } else {
          // Mobile platform: Use native streaming
          await _audioPlayer.setUrl(streamingUrl);
          await _audioPlayer.play();
        }
      } else {
        // Use file source for local files
        if (kDebugMode) {
          print('AudioService: Playing local file: ${audioFile.filePath}');
        }
        
        await _audioPlayer.setFilePath(audioFile.filePath);
        await _audioPlayer.play();
      }
      
      await _audioPlayer.setSpeed(_playbackSpeed);
      
    } catch (e) {
      _playbackState = PlaybackState.error;
      
      // Provide helpful error messages for common issues
      if (e.toString().contains('HttpException') || e.toString().contains('SocketException')) {
        _errorMessage = 'Network error: Cannot access streaming URL. Check internet connection.';
      } else if (e.toString().contains('FormatException') || e.toString().contains('UnsupportedError')) {
        _errorMessage = 'Unsupported media format. Please try a different audio source.';
      } else if (e.toString().contains('PlayerException')) {
        _errorMessage = 'Audio player error: ${e.toString()}';
      } else {
        _errorMessage = 'Failed to play audio: $e';
      }
      
      if (kDebugMode) {
        print('AudioService playback error: $e');
        print('AudioFile: ${audioFile.id}, isStreaming: ${audioFile.isStreamingFile}');
        print('AudioService: Platform: ${kIsWeb ? 'Web' : 'Mobile'}');
        if (audioFile.isStreamingFile) {
          print('AudioService: Streaming URL: ${audioFile.streamingUrl}');
        }
      }
      
      notifyListeners();
    }
  }

  // Resume playback
  Future<void> resume() async {
    try {
      await _audioPlayer.play();
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
      await _audioPlayer.setSpeed(speed);
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