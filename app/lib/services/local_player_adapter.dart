import 'dart:async';
import 'package:just_audio/just_audio.dart';

import '../models/audio_file.dart';
import 'player_adapter.dart';
import 'player_state_notifier.dart';

/// Adapter for AudioPlayer that implements IPlayerAdapter
///
/// This adapter wraps just_audio.AudioPlayer and maps its ProcessingState types
/// to our canonical AppPlaybackState. Used as a fallback when background audio
/// is not available or not desired.
class LocalPlayerAdapter implements IPlayerAdapter {
  final AudioPlayer _player;

  // Stream controllers for unified interface
  late final StreamController<AppPlaybackState> _stateController;
  late final StreamController<Duration> _positionController;
  late final StreamController<Duration?> _durationController;
  late final StreamController<double> _speedController;

  // Stream subscriptions for cleanup
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;

  // Current state cache for synchronous access
  AppPlaybackState _currentState = AppPlaybackState.stopped;
  Duration _currentPosition = Duration.zero;
  Duration? _currentDuration;
  double _currentSpeed = 1.0;

  bool _disposed = false;

  LocalPlayerAdapter({AudioPlayer? audioPlayer})
      : _player = audioPlayer ?? AudioPlayer() {
    _initializeStreams();
    _setupSubscriptions();
  }

  void _initializeStreams() {
    _stateController = StreamController<AppPlaybackState>.broadcast();
    _positionController = StreamController<Duration>.broadcast();
    _durationController = StreamController<Duration?>.broadcast();
    _speedController = StreamController<double>.broadcast();
  }

  void _setupSubscriptions() {
    // Listen to player state changes
    _playerStateSubscription = _player.playerStateStream.listen((state) {
      if (_disposed) return;

      // Map just_audio states to our canonical states
      final newState = _mapPlayerState(state.processingState, state.playing);

      // Update cached state
      if (_currentState != newState) {
        _currentState = newState;
        _stateController.add(newState);
      }
    });

    // Listen to position changes
    _positionSubscription = _player.positionStream.listen((position) {
      if (_disposed) return;

      if (_currentPosition != position) {
        _currentPosition = position;
        _positionController.add(position);
      }
    });

    // Listen to duration changes
    _durationSubscription = _player.durationStream.listen((duration) {
      if (_disposed) return;

      if (_currentDuration != duration) {
        _currentDuration = duration;
        _durationController.add(duration);
      }
    });

    // Speed changes are handled manually in setSpeed method
    _currentSpeed = _player.speed;
  }

  /// Map just_audio.ProcessingState to AppPlaybackState
  AppPlaybackState _mapPlayerState(
      ProcessingState processingState, bool playing) {
    switch (processingState) {
      case ProcessingState.idle:
        return AppPlaybackState.stopped;
      case ProcessingState.loading:
      case ProcessingState.buffering:
        return AppPlaybackState.loading;
      case ProcessingState.ready:
        return playing ? AppPlaybackState.playing : AppPlaybackState.paused;
      case ProcessingState.completed:
        return AppPlaybackState.completed;
    }
  }

  @override
  Stream<AppPlaybackState> get playbackStateStream => _stateController.stream;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Stream<Duration?> get durationStream => _durationController.stream;

  @override
  Stream<double> get speedStream => _speedController.stream;

  @override
  AppPlaybackState get currentState => _currentState;

  @override
  Duration get currentPosition => _currentPosition;

  @override
  Duration? get currentDuration => _currentDuration;

  @override
  double get currentSpeed => _currentSpeed;

  @override
  Future<void> setAudioSource(AudioFile audioFile,
      {Duration? initialPosition}) async {
    try {
      await _player.setAudioSource(
        AudioSource.uri(Uri.parse(audioFile.streamingUrl)),
        initialPosition: initialPosition,
      );
    } catch (e) {
      throw PlayerAdapterException('Failed to set audio source', e);
    }
  }

  @override
  Future<void> play() async {
    try {
      await _player.play();
    } catch (e) {
      throw PlayerAdapterException('Failed to start playback', e);
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (e) {
      throw PlayerAdapterException('Failed to pause playback', e);
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (e) {
      throw PlayerAdapterException('Failed to stop playback', e);
    }
  }

  @override
  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      throw PlayerAdapterException('Failed to seek', e);
    }
  }

  @override
  Future<void> setSpeed(double speed) async {
    try {
      await _player.setSpeed(speed);

      // Update cached speed and emit change
      if (_currentSpeed != speed) {
        _currentSpeed = speed;
        _speedController.add(speed);
      }
    } catch (e) {
      throw PlayerAdapterException('Failed to set speed', e);
    }
  }

  @override
  Future<void> skipForward(
      [Duration duration = const Duration(seconds: 30)]) async {
    try {
      final newPosition = _currentPosition + duration;
      final maxPosition = _currentDuration ?? Duration.zero;
      final seekPosition =
          newPosition < maxPosition ? newPosition : maxPosition;
      await seek(seekPosition);
    } catch (e) {
      throw PlayerAdapterException('Failed to skip forward', e);
    }
  }

  @override
  Future<void> skipBackward(
      [Duration duration = const Duration(seconds: 10)]) async {
    try {
      final newPosition = _currentPosition - duration;
      final seekPosition =
          newPosition > Duration.zero ? newPosition : Duration.zero;
      await seek(seekPosition);
    } catch (e) {
      throw PlayerAdapterException('Failed to skip backward', e);
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    await _playerStateSubscription?.cancel();
    await _positionSubscription?.cancel();
    await _durationSubscription?.cancel();

    await _stateController.close();
    await _positionController.close();
    await _durationController.close();
    await _speedController.close();

    await _player.dispose();
  }
}
