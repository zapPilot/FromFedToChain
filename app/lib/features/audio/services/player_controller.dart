import 'dart:async';

import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';
import 'package:from_fed_to_chain_app/features/audio/services/player_adapter.dart';
import 'package:from_fed_to_chain_app/features/audio/services/player_state_notifier.dart';
import 'package:from_fed_to_chain_app/core/services/logger_service.dart';

/// Stateless playback controller that delegates to an IPlayerAdapter
///
/// This controller provides a clean interface for playback operations
/// while abstracting away the underlying player implementation.
/// It coordinates between the player adapter and state notifier,
/// ensuring state changes are properly propagated.
class PlayerController {
  static final _log = LoggerService.getLogger('PlayerController');
  final IPlayerAdapter _player;
  final PlayerStateNotifier _stateNotifier;

  // Stream subscriptions for cleanup
  StreamSubscription? _stateSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _speedSubscription;

  bool _disposed = false;

  PlayerController(this._player, this._stateNotifier) {
    _setupSubscriptions();
  }

  /// Set up listeners to update state notifier from player streams
  void _setupSubscriptions() {
    // Listen to player state changes and update state notifier
    _stateSubscription = _player.playbackStateStream.listen((state) {
      if (!_disposed) {
        _stateNotifier.updateState(state);
      }
    });

    // Listen to position changes and update state notifier
    _positionSubscription = _player.positionStream.listen((position) {
      if (!_disposed) {
        _stateNotifier.updatePosition(position);
      }
    });

    // Listen to duration changes and update state notifier
    _durationSubscription = _player.durationStream.listen((duration) {
      if (!_disposed && duration != null) {
        _stateNotifier.updateDuration(duration);
      }
    });

    // Listen to speed changes and update state notifier
    _speedSubscription = _player.speedStream.listen((speed) {
      if (!_disposed) {
        _stateNotifier.updateSpeed(speed);
      }
    });
  }

  /// Play an audio file
  Future<void> play(AudioFile audioFile, {Duration? initialPosition}) async {
    try {
      _log.info('Playing audio: ${audioFile.title}');

      _stateNotifier.clearError();
      await _setupAudioSource(audioFile, initialPosition);
      await _player.play();

      _log.fine('Successfully started playback');
    } catch (e) {
      _log.severe('Failed to play audio: $e');
      _stateNotifier.setError('Failed to play audio: $e');
      rethrow;
    }
  }

  /// Pause playback
  Future<void> pause() async {
    try {
      _log.info('Pausing playback');
      await _player.pause();
    } catch (e) {
      _log.severe('Failed to pause: $e');
      _stateNotifier.setError('Failed to pause playback: $e');
      rethrow;
    }
  }

  /// Resume playback
  Future<void> resume() async {
    try {
      _log.info('Resuming playback');
      await _player.play();
    } catch (e) {
      _log.severe('Failed to resume: $e');
      _stateNotifier.setError('Failed to resume playback: $e');
      rethrow;
    }
  }

  /// Stop playback
  Future<void> stop() async {
    try {
      _log.info('Stopping playback');
      await _player.stop();
    } catch (e) {
      _log.severe('Failed to stop: $e');
      _stateNotifier.setError('Failed to stop playback: $e');
      rethrow;
    }
  }

  /// Seek to a specific position
  Future<void> seek(Duration position) async {
    try {
      _log.fine('Seeking to ${position.inSeconds}s');
      await _player.seek(position);
    } catch (e) {
      _log.severe('Failed to seek: $e');
      _stateNotifier.setError('Failed to seek: $e');
      rethrow;
    }
  }

  /// Set playback speed
  Future<void> setSpeed(double speed) async {
    try {
      _log.fine('Setting speed to ${speed}x');
      await _player.setSpeed(speed);
    } catch (e) {
      _log.warning('Failed to set speed: $e');
      // Don't set error state for speed failures - it's not critical
      // Just log and continue
    }
  }

  /// Skip forward by specified duration (default 30 seconds)
  Future<void> skipForward(
      [Duration duration = const Duration(seconds: 30)]) async {
    try {
      _log.info('Skipping forward ${duration.inSeconds}s');
      await _player.skipForward(duration);
    } catch (e) {
      _log.severe('Failed to skip forward: $e');
      _stateNotifier.setError('Failed to skip forward: $e');
      rethrow;
    }
  }

  /// Skip backward by specified duration (default 10 seconds)
  Future<void> skipBackward(
      [Duration duration = const Duration(seconds: 10)]) async {
    try {
      _log.info('Skipping backward ${duration.inSeconds}s');
      await _player.skipBackward(duration);
    } catch (e) {
      _log.severe('Failed to skip backward: $e');
      _stateNotifier.setError('Failed to skip backward: $e');
      rethrow;
    }
  }

  /// Set up audio source for playback
  Future<void> _setupAudioSource(
    AudioFile audioFile,
    Duration? initialPosition,
  ) async {
    try {
      _log.fine('Setting up audio source: ${audioFile.streamingUrl}');
      await _player.setAudioSource(
        audioFile,
        initialPosition: initialPosition,
      );
    } catch (e) {
      _log.severe('Failed to set up audio source: $e');
      throw PlayerAdapterException('Failed to set up audio source', e);
    }
  }

  /// Check if the provided audio file is valid
  bool isValidAudioFile(AudioFile? audioFile) {
    if (audioFile == null) return false;
    return audioFile.streamingUrl.trim().isNotEmpty;
  }

  /// Get current player state (for synchronous access)
  AppPlaybackState get currentState => _player.currentState;

  /// Get current position (for synchronous access)
  Duration get currentPosition => _player.currentPosition;

  /// Get current duration (for synchronous access)
  Duration? get currentDuration => _player.currentDuration;

  /// Get current speed (for synchronous access)
  double get currentSpeed => _player.currentSpeed;

  /// Dispose of resources
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    _log.info('Disposing...');

    // Cancel all subscriptions
    await _stateSubscription?.cancel();
    await _positionSubscription?.cancel();
    await _durationSubscription?.cancel();
    await _speedSubscription?.cancel();

    // Dispose the player adapter
    await _player.dispose();
  }
}
