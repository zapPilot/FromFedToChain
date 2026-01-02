import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';

import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';

/// Background audio handler for media session controls and system integration
class BackgroundAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final AudioPlayer _player;
  final AudioSession? _audioSession;

  // Episode navigation callbacks
  Function(AudioFile)? onSkipToNextEpisode;
  Function(AudioFile)? onSkipToPreviousEpisode;
  AudioFile? _currentAudioFile;

  BackgroundAudioHandler({AudioPlayer? audioPlayer, AudioSession? audioSession})
      : _player = audioPlayer ?? AudioPlayer(),
        _audioSession = audioSession {
    if (kDebugMode) {
      print('🎵 BackgroundAudioHandler: Constructor called');
      print('🎵 Starting initialization for media session support...');
    }
    _init();
  }

  Future<void> _init() async {
    // Configure audio session for background playback and Control Center
    if (kDebugMode) {
      print('🎵 Configuring audio session for media notifications...');
    }

    try {
      final session = _audioSession ?? await AudioSession.instance;
      // Use the music preset - it includes all necessary settings for media notifications
      await session.configure(const AudioSessionConfiguration.music());
      await session.setActive(true);

      // Handle audio interruptions for better iOS integration
      session.interruptionEventStream.listen((event) {
        if (event.begin) {
          if (kDebugMode) {
            print('🍎 Audio interruption began (phone call, etc.)');
          }
          pause();
        } else {
          if (kDebugMode) {
            print('🍎 Audio interruption ended, resuming playback');
          }
          if (event.type == AudioInterruptionType.pause) {
            play();
          }
        }
      });

      if (kDebugMode) {
        print('✅ Audio session configured for media notifications');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Audio session configuration failed: $e');
      }
    }

    // Listen to player events
    _player.playbackEventStream.listen(_broadcastState);
    _player.playerStateStream.listen((state) {
      if (kDebugMode) {
        print(
            '🔄 Player state changed: ${state.playing ? 'PLAYING' : 'PAUSED'} (${state.processingState})');
      }
    });

    // Listen to duration changes to update MediaItem
    _player.durationStream.listen((duration) {
      final currentMediaItem = mediaItem.value;
      if (currentMediaItem != null &&
          duration != null &&
          currentMediaItem.duration != duration) {
        mediaItem.add(currentMediaItem.copyWith(duration: duration));
        if (kDebugMode) {
          print('🎵 MediaItem updated with duration: $duration');
        }
      }
    });

    // Set initial empty MediaItem to ensure notifications are ready
    mediaItem.add(const MediaItem(
      id: 'initial',
      title: 'From Fed to Chain',
      artist: 'Loading...',
      album: 'Crypto & Macro Economics Learning',
      duration: Duration.zero,
      artUri: null, // Avoid asset URI issues on Android
    ));

    // Set initial playback state optimized for media notifications
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2], // Previous, Play, Next
      processingState: AudioProcessingState.idle,
      playing: false,
      updatePosition: Duration.zero,
      bufferedPosition: Duration.zero,
      speed: 1.0,
      queueIndex: 0,
    ));

    if (kDebugMode) {
      print('✅ BackgroundAudioHandler: Initialization complete');
      print('🎵 Media session is ready for lock screen controls');
    }
  }

  /// Set episode navigation callbacks
  void setEpisodeNavigationCallbacks({
    required Function(AudioFile) onNext,
    required Function(AudioFile) onPrevious,
  }) {
    onSkipToNextEpisode = onNext;
    onSkipToPreviousEpisode = onPrevious;
    if (kDebugMode) {
      print('🎵 Episode navigation callbacks set');
    }
  }

  /// Set audio source and MediaItem
  Future<void> setAudioSource(
    String url, {
    required String title,
    String? artist,
    Duration? initialPosition,
    AudioFile? audioFile,
  }) async {
    if (kDebugMode) {
      print('🎵 BackgroundAudioHandler: setAudioSource called');
      print('🎵 URL: $url');
      print('🎵 Title: $title');
    }

    try {
      // Store current audio file for navigation
      _currentAudioFile = audioFile;

      // Create MediaItem for system notifications
      final newMediaItem = MediaItem(
        id: audioFile?.id ?? 'unknown',
        title: title,
        artist: artist ?? 'From Fed to Chain',
        album: 'Crypto & Macro Economics',
        duration: audioFile?.duration ?? Duration.zero,
        artUri: null, // Could add artwork URL here
        extras: {
          'url': url,
          'category': audioFile?.category ?? '',
          'language': audioFile?.language ?? '',
        },
      );

      // Update MediaItem first
      mediaItem.add(newMediaItem);

      // Set audio source
      await _player.setAudioSource(
        AudioSource.uri(Uri.parse(url)),
        initialPosition: initialPosition ?? Duration.zero,
      );

      if (kDebugMode) {
        print('✅ BackgroundAudioHandler: Audio source set successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ BackgroundAudioHandler: Failed to set audio source: $e');
      }
      // Update playback state to show error
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.error,
      ));
      rethrow;
    }
  }

  /// Get current duration
  Duration get duration => _player.duration ?? Duration.zero;

  @override
  Future<void> play() async {
    if (kDebugMode) {
      print('🎵 BackgroundAudioHandler: play() called');
    }
    try {
      await _player.play();
    } catch (e) {
      if (kDebugMode) {
        print('❌ BackgroundAudioHandler: Play failed: $e');
      }
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.error,
      ));
    }
  }

  @override
  Future<void> pause() async {
    if (kDebugMode) {
      print('🎵 BackgroundAudioHandler: pause() called');
    }
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    if (kDebugMode) {
      print('🎵 BackgroundAudioHandler: stop() called');
    }
    await _player.stop();
    await _player.seek(Duration.zero);

    // Reset MediaItem
    mediaItem.add(const MediaItem(
      id: 'stopped',
      title: 'From Fed to Chain',
      artist: 'Ready to play',
      album: 'Crypto & Macro Economics Learning',
      duration: Duration.zero,
    ));
  }

  @override
  Future<void> seek(Duration position) async {
    if (kDebugMode) {
      print('🎵 BackgroundAudioHandler: seek($position) called');
    }
    await _player.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    if (kDebugMode) {
      print('🎵 BackgroundAudioHandler: skipToNext() called');
    }

    // If we have episode navigation callback and current episode, use it
    if (onSkipToNextEpisode != null && _currentAudioFile != null) {
      if (kDebugMode) {
        print('🎵 Using episode navigation for next');
      }
      onSkipToNextEpisode!(_currentAudioFile!);
    } else {
      // Fallback to 30-second skip forward
      if (kDebugMode) {
        print('🎵 Using 30-second skip forward');
      }
      final currentPosition = _player.position;
      final duration = _player.duration ?? Duration.zero;
      final newPosition = currentPosition + const Duration(seconds: 30);

      if (newPosition < duration) {
        await seek(newPosition);
      } else {
        await seek(duration);
      }
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (kDebugMode) {
      print('🎵 BackgroundAudioHandler: skipToPrevious() called');
    }

    // If we have episode navigation callback and current episode, use it
    if (onSkipToPreviousEpisode != null && _currentAudioFile != null) {
      if (kDebugMode) {
        print('🎵 Using episode navigation for previous');
      }
      onSkipToPreviousEpisode!(_currentAudioFile!);
    } else {
      // Fallback to 10-second skip backward
      if (kDebugMode) {
        print('🎵 Using 10-second skip backward');
      }
      final currentPosition = _player.position;
      final newPosition = currentPosition - const Duration(seconds: 10);

      if (newPosition > Duration.zero) {
        await seek(newPosition);
      } else {
        await seek(Duration.zero);
      }
    }
  }

  @override
  Future<void> fastForward() async {
    if (kDebugMode) {
      print('🎵 BackgroundAudioHandler: fastForward() called');
    }
    final currentPosition = _player.position;
    final duration = _player.duration ?? Duration.zero;
    final newPosition = currentPosition + const Duration(seconds: 30);

    if (newPosition < duration) {
      await seek(newPosition);
    } else {
      await seek(duration);
    }
  }

  @override
  Future<void> rewind() async {
    if (kDebugMode) {
      print('🎵 BackgroundAudioHandler: rewind() called');
    }
    final currentPosition = _player.position;
    final newPosition = currentPosition - const Duration(seconds: 10);

    if (newPosition > Duration.zero) {
      await seek(newPosition);
    } else {
      await seek(Duration.zero);
    }
  }

  @override
  Future<dynamic> customAction(String name,
      [Map<String, dynamic>? extras]) async {
    if (kDebugMode) {
      print('🎵 BackgroundAudioHandler: customAction($name) called');
    }

    switch (name) {
      case 'setSpeed':
        final speed = extras?['speed'] as double? ?? 1.0;
        await _player.setSpeed(speed);
        if (kDebugMode) {
          print('🎵 Playback speed set to ${speed}x');
        }
        break;

      case 'getPosition':
        return _player.position;

      case 'getDuration':
        return _player.duration;

      default:
        if (kDebugMode) {
          print('🎵 Unknown custom action: $name');
        }
    }

    return super.customAction(name, extras);
  }

  /// Test method to verify media session is working
  Future<void> testMediaSession() async {
    if (kDebugMode) {
      print('🧪 BackgroundAudioHandler: Testing media session...');
    }

    // Create test MediaItem
    const testMediaItem = MediaItem(
      id: 'test',
      title: 'Media Session Test',
      artist: 'From Fed to Chain',
      album: 'Testing',
      duration: Duration(minutes: 1),
    );

    mediaItem.add(testMediaItem);

    // Update playback state
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: AudioProcessingState.ready,
      playing: false,
      updatePosition: Duration.zero,
      bufferedPosition: Duration.zero,
      speed: 1.0,
    ));

    if (kDebugMode) {
      print('✅ Media session test completed');
      print('🎵 Check your lock screen for media controls');
    }
  }

  /// Broadcast current state to system
  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;

    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: {
            ProcessingState.idle: AudioProcessingState.idle,
            ProcessingState.loading: AudioProcessingState.loading,
            ProcessingState.buffering: AudioProcessingState.buffering,
            ProcessingState.ready: AudioProcessingState.ready,
            ProcessingState.completed: AudioProcessingState.completed,
          }[_player.processingState] ??
          AudioProcessingState.idle,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: 0,
    ));
  }

  @override
  Future<void> onTaskRemoved() async {
    // Handle task removal (app swiped away)
    if (kDebugMode) {
      print('🎵 BackgroundAudioHandler: App task removed');
    }
    await stop();
    await super.onTaskRemoved();
  }

  void dispose() {
    if (kDebugMode) {
      print('🎵 BackgroundAudioHandler: Disposing...');
    }
    _player.dispose();
  }
}
