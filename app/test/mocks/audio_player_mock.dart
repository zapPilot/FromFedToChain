import 'package:mockito/mockito.dart';
import 'package:just_audio/just_audio.dart';

// Simple mock for audio player that avoids platform dependencies
class MockAudioPlayer extends Mock implements AudioPlayer {
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration? _duration;

  @override
  bool get playing => _playing;

  @override
  Duration get position => _position;

  @override
  Duration? get duration => _duration;

  @override
  Stream<Duration> get positionStream =>
      Stream.periodic(const Duration(seconds: 1), (i) => _position);

  @override
  Stream<bool> get playingStream => Stream.value(_playing);

  // Simulate playback methods
  Future<void> simulatePlay() async {
    _playing = true;
  }

  Future<void> simulatePause() async {
    _playing = false;
  }

  Future<void> simulateSeek(Duration position) async {
    _position = position;
  }

  void setMockDuration(Duration duration) {
    _duration = duration;
  }
}
