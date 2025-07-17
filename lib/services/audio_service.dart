import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
  
  // Resolve signed URL from Cloudflare worker response
  Future<String> _resolveSignedUrl(String workerUrl) async {
    if (kDebugMode) {
      print('AudioService: Resolving signed URL from: $workerUrl');
    }
    
    try {
      final response = await http.get(Uri.parse(workerUrl));
      
      if (response.statusCode == 200) {
        // Check if response is JSON (signed URL response)
        if (response.headers['content-type']?.contains('application/json') == true) {
          final jsonData = json.decode(response.body);
          final signedUrl = jsonData['url'] as String;
          
          if (kDebugMode) {
            print('AudioService: Resolved signed URL: $signedUrl');
          }
          
          return signedUrl;
        } else {
          // If not JSON, assume it's the direct content
          if (kDebugMode) {
            print('AudioService: Direct content, using original URL');
          }
          return workerUrl;
        }
      } else {
        throw Exception('Failed to resolve signed URL: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AudioService: Error resolving signed URL: $e');
      }
      throw Exception('Failed to resolve signed URL: $e');
    }
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

      // Always use sourceUrl for playback
      if (kDebugMode) {
        print('AudioService: Playing audio from sourceUrl');
        print('AudioService: sourceUrl:  [32m${audioFile.sourceUrl} [0m');
        print('AudioService: Platform:  [36m${kIsWeb ? 'Web' : 'Mobile'} [0m');
      }

      if (kIsWeb) {
        throw Exception('HLS streaming not supported on web. Use Android/iOS for full functionality.');
      } else {
        await _audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(audioFile.sourceUrl)));
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
        print('AudioFile: ${audioFile.id}');
        print('AudioService: Platform: ${kIsWeb ? 'Web' : 'Mobile'}');
        print('AudioService: sourceUrl: ${audioFile.sourceUrl}');
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