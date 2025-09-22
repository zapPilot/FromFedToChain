import 'dart:async';
import '../models/audio_file.dart';
import 'player_state_notifier.dart';

/// Common interface for audio player implementations
///
/// This interface abstracts away the differences between BackgroundAudioHandler
/// and AudioPlayer, providing a unified API for playback control and state monitoring.
/// Adapters implementing this interface are responsible for mapping their specific
/// state enums to our canonical AppPlaybackState.
abstract class IPlayerAdapter {
  /// Stream of playback state changes
  Stream<AppPlaybackState> get playbackStateStream;

  /// Stream of position changes during playback
  Stream<Duration> get positionStream;

  /// Stream of duration changes when media is loaded
  Stream<Duration?> get durationStream;

  /// Stream of playback speed changes
  Stream<double> get speedStream;

  /// Current playback state (synchronous access)
  AppPlaybackState get currentState;

  /// Current position (synchronous access)
  Duration get currentPosition;

  /// Current duration (synchronous access)
  Duration? get currentDuration;

  /// Current playback speed (synchronous access)
  double get currentSpeed;

  /// Set up audio source and prepare for playback
  ///
  /// This should load the audio file and set up media metadata
  /// but not automatically start playback.
  Future<void> setAudioSource(AudioFile audioFile, {Duration? initialPosition});

  /// Start or resume playback
  Future<void> play();

  /// Pause playback
  Future<void> pause();

  /// Stop playback and reset position
  Future<void> stop();

  /// Seek to a specific position
  Future<void> seek(Duration position);

  /// Set playback speed
  Future<void> setSpeed(double speed);

  /// Skip forward by a specified duration (default 30 seconds)
  Future<void> skipForward([Duration duration = const Duration(seconds: 30)]);

  /// Skip backward by a specified duration (default 10 seconds)
  Future<void> skipBackward([Duration duration = const Duration(seconds: 10)]);

  /// Dispose of resources and cancel subscriptions
  Future<void> dispose();
}

/// Exception thrown when player adapter operations fail
class PlayerAdapterException implements Exception {
  final String message;
  final dynamic cause;

  const PlayerAdapterException(this.message, [this.cause]);

  @override
  String toString() => 'PlayerAdapterException: $message${cause != null ? ' (caused by $cause)' : ''}';
}