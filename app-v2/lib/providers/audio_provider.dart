import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/audio_content.dart';
import '../services/audio_service.dart';

/// Audio provider wrapping AudioPlayerService
/// Exposes audio playback state to widgets
class AudioProvider with ChangeNotifier {
  final AudioPlayerService _audioService;

  AudioProvider(this._audioService) {
    // Listen to audio service changes
    _audioService.addListener(_onAudioServiceChanged);
  }

  void _onAudioServiceChanged() {
    notifyListeners();
  }

  // Expose getters from service
  AudioContent? get currentContent => _audioService.currentContent;
  bool get isPlaying => _audioService.isPlaying;
  bool get isPaused => _audioService.isPaused;
  Duration get position => _audioService.position;
  Duration? get duration => _audioService.duration;
  double get speed => _audioService.speed;
  bool get hasNext => _audioService.hasNext;
  bool get hasPrevious => _audioService.hasPrevious;

  // Expose streams
  Stream<PlayerState> get playerStateStream => _audioService.playerStateStream;
  Stream<Duration> get positionStream => _audioService.positionStream;
  Stream<Duration?> get durationStream => _audioService.durationStream;
  Stream<double> get speedStream => _audioService.speedStream;
  Stream<bool> get playingStream => _audioService.playingStream;

  // Expose methods
  Future<void> play(AudioContent content, {List<AudioContent>? playlist}) {
    return _audioService.play(content, playlist: playlist);
  }

  Future<void> pause() => _audioService.pause();
  Future<void> resume() => _audioService.resume();
  Future<void> togglePlayPause() => _audioService.togglePlayPause();
  Future<void> stop() => _audioService.stop();
  Future<void> seek(Duration position) => _audioService.seek(position);
  Future<void> seekForward() => _audioService.seekForward();
  Future<void> seekBackward() => _audioService.seekBackward();
  Future<void> setSpeed(double speed) => _audioService.setSpeed(speed);
  Future<void> setVolume(double volume) => _audioService.setVolume(volume);
  Future<void> next() => _audioService.next();
  Future<void> previous() => _audioService.previous();

  @override
  void dispose() {
    _audioService.removeListener(_onAudioServiceChanged);
    super.dispose();
  }
}
