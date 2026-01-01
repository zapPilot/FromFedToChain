import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import '../models/audio_content.dart';

/// Simplified audio playback service using just_audio
/// Consolidates AudioPlayerService + PlayerController + StateNotifier from v1
class AudioPlayerService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  AudioContent? _currentContent;
  List<AudioContent> _queue = [];
  int _currentIndex = -1;

  // Getters
  AudioPlayer get player => _player;
  AudioContent? get currentContent => _currentContent;
  List<AudioContent> get queue => List.unmodifiable(_queue);
  int get currentIndex => _currentIndex;

  // Streams from just_audio
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<double> get speedStream => _player.speedStream;
  Stream<bool> get playingStream => _player.playingStream;

  // State properties
  bool get isPlaying => _player.playing;
  bool get isPaused => !_player.playing && _player.processingState != ProcessingState.idle;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;
  double get speed => _player.speed;

  AudioPlayerService() {
    _initialize();
  }

  /// Initialize audio session and listeners
  Future<void> _initialize() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      // Handle audio interruptions (phone calls, etc.)
      session.interruptionEventStream.listen((event) {
        if (event.begin) {
          _player.pause();
        } else {
          if (event.type == AudioInterruptionType.duck) {
            // Lower volume during temporary interruption
            _player.setVolume(0.5);
          }
        }
      });

      // Handle becoming noisy (headphones unplugged)
      session.becomingNoisyEventStream.listen((_) {
        _player.pause();
      });

      // Listen to playback completion
      _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _onPlaybackCompleted();
        }
      });
    } catch (e) {
      debugPrint('Error initializing audio session: $e');
    }
  }

  /// Play audio content
  Future<void> play(AudioContent content, {List<AudioContent>? playlist}) async {
    try {
      // Validate streaming URL exists
      if (content.streamingUrl == null || content.streamingUrl!.isEmpty) {
        throw Exception('No streaming URL available for this content');
      }

      _currentContent = content;

      // Update queue if provided
      if (playlist != null) {
        _queue = playlist;
        _currentIndex = playlist.indexWhere((c) => c.id == content.id);
      } else {
        _queue = [content];
        _currentIndex = 0;
      }

      // Set audio source
      await _player.setUrl(content.streamingUrl!);

      // Play
      await _player.play();

      notifyListeners();
    } catch (e) {
      debugPrint('Error playing audio: $e');
      rethrow;
    }
  }

  /// Pause playback
  Future<void> pause() async {
    await _player.pause();
    notifyListeners();
  }

  /// Resume playback
  Future<void> resume() async {
    await _player.play();
    notifyListeners();
  }

  /// Toggle play/pause
  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await pause();
    } else {
      await resume();
    }
  }

  /// Stop playback
  Future<void> stop() async {
    await _player.stop();
    _currentContent = null;
    notifyListeners();
  }

  /// Seek to position
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  /// Seek forward by 10 seconds
  Future<void> seekForward() async {
    final newPosition = position + const Duration(seconds: 10);
    final maxPosition = duration ?? position;
    await seek(newPosition > maxPosition ? maxPosition : newPosition);
  }

  /// Seek backward by 10 seconds
  Future<void> seekBackward() async {
    final newPosition = position - const Duration(seconds: 10);
    await seek(newPosition < Duration.zero ? Duration.zero : newPosition);
  }

  /// Set playback speed
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
    notifyListeners();
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  /// Play next item in queue
  Future<void> next() async {
    if (_queue.isEmpty || _currentIndex == -1) return;

    final nextIndex = _currentIndex + 1;
    if (nextIndex < _queue.length) {
      await play(_queue[nextIndex], playlist: _queue);
    }
  }

  /// Play previous item in queue
  Future<void> previous() async {
    if (_queue.isEmpty || _currentIndex == -1) return;

    // If we're more than 3 seconds in, restart current track
    if (position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }

    // Otherwise go to previous track
    final prevIndex = _currentIndex - 1;
    if (prevIndex >= 0) {
      await play(_queue[prevIndex], playlist: _queue);
    }
  }

  /// Check if there's a next track
  bool get hasNext => _currentIndex >= 0 && _currentIndex < _queue.length - 1;

  /// Check if there's a previous track
  bool get hasPrevious => _currentIndex > 0;

  /// Handle playback completion
  void _onPlaybackCompleted() {
    if (hasNext) {
      // Auto-play next track
      next();
    } else {
      // Reset to beginning
      seek(Duration.zero);
      pause();
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
