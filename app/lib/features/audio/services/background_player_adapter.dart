import 'dart:async';
import 'package:audio_service/audio_service.dart' as audio_service_pkg;

import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';
import 'package:from_fed_to_chain_app/features/audio/services/background_audio_handler.dart';
import 'package:from_fed_to_chain_app/features/audio/services/player_adapter.dart';
import 'package:from_fed_to_chain_app/features/audio/services/player_state_notifier.dart';

/// Adapter for BackgroundAudioHandler that implements IPlayerAdapter
///
/// This adapter wraps BackgroundAudioHandler and maps its audio_service_pkg types
/// to our canonical AppPlaybackState and provides unified streams for the PlayerController.
class BackgroundPlayerAdapter implements IPlayerAdapter {
  final BackgroundAudioHandler _handler;

  // Stream controllers for unified interface
  late final StreamController<AppPlaybackState> _stateController;
  late final StreamController<Duration> _positionController;
  late final StreamController<Duration?> _durationController;
  late final StreamController<double> _speedController;

  // Stream subscriptions for cleanup
  StreamSubscription? _playbackStateSubscription;
  StreamSubscription? _mediaItemSubscription;

  // Current state cache for synchronous access
  AppPlaybackState _currentState = AppPlaybackState.stopped;
  Duration _currentPosition = Duration.zero;
  Duration? _currentDuration;
  double _currentSpeed = 1.0;

  bool _disposed = false;

  BackgroundPlayerAdapter(this._handler) {
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
    // Listen to background handler state changes
    _playbackStateSubscription = _handler.playbackState.listen((state) {
      if (_disposed) return;

      // Map audio_service_pkg states to our canonical states
      final newState = _mapPlaybackState(state.processingState, state.playing);
      final newPosition = state.updatePosition;
      final newSpeed = state.speed;

      // Update cached state
      if (_currentState != newState) {
        _currentState = newState;
        _stateController.add(newState);
      }

      if (_currentPosition != newPosition) {
        _currentPosition = newPosition;
        _positionController.add(newPosition);
      }

      if (_currentSpeed != newSpeed) {
        _currentSpeed = newSpeed;
        _speedController.add(newSpeed);
      }
    });

    // Listen to media item changes for duration
    _mediaItemSubscription = _handler.mediaItem.listen((mediaItem) {
      if (_disposed) return;

      final newDuration = mediaItem?.duration;
      if (_currentDuration != newDuration) {
        _currentDuration = newDuration;
        _durationController.add(newDuration);
      }
    });
  }

  /// Map audio_service_pkg.AudioProcessingState to AppPlaybackState
  AppPlaybackState _mapPlaybackState(
      audio_service_pkg.AudioProcessingState processingState, bool playing) {
    switch (processingState) {
      case audio_service_pkg.AudioProcessingState.idle:
        return AppPlaybackState.stopped;
      case audio_service_pkg.AudioProcessingState.loading:
      case audio_service_pkg.AudioProcessingState.buffering:
        return AppPlaybackState.loading;
      case audio_service_pkg.AudioProcessingState.ready:
        return playing ? AppPlaybackState.playing : AppPlaybackState.paused;
      case audio_service_pkg.AudioProcessingState.completed:
        return AppPlaybackState.completed;
      case audio_service_pkg.AudioProcessingState.error:
        return AppPlaybackState.error;
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
      await _handler.setAudioSource(
        audioFile.streamingUrl,
        title: audioFile.title,
        artist: 'From Fed to Chain',
        audioFile: audioFile,
        initialPosition: initialPosition,
      );
    } catch (e) {
      throw PlayerAdapterException('Failed to set audio source', e);
    }
  }

  @override
  Future<void> play() async {
    try {
      await _handler.play();
    } catch (e) {
      throw PlayerAdapterException('Failed to start playback', e);
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _handler.pause();
    } catch (e) {
      throw PlayerAdapterException('Failed to pause playback', e);
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _handler.stop();
    } catch (e) {
      throw PlayerAdapterException('Failed to stop playback', e);
    }
  }

  @override
  Future<void> seek(Duration position) async {
    try {
      await _handler.seek(position);
    } catch (e) {
      throw PlayerAdapterException('Failed to seek', e);
    }
  }

  @override
  Future<void> setSpeed(double speed) async {
    try {
      await _handler.customAction('setSpeed', {'speed': speed});
    } catch (e) {
      throw PlayerAdapterException('Failed to set speed', e);
    }
  }

  @override
  Future<void> skipForward(
      [Duration duration = const Duration(seconds: 30)]) async {
    try {
      await _handler.fastForward();
    } catch (e) {
      throw PlayerAdapterException('Failed to skip forward', e);
    }
  }

  @override
  Future<void> skipBackward(
      [Duration duration = const Duration(seconds: 10)]) async {
    try {
      await _handler.rewind();
    } catch (e) {
      throw PlayerAdapterException('Failed to skip backward', e);
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    await _playbackStateSubscription?.cancel();
    await _mediaItemSubscription?.cancel();

    await _stateController.close();
    await _positionController.close();
    await _durationController.close();
    await _speedController.close();

    _handler.dispose();
  }
}
