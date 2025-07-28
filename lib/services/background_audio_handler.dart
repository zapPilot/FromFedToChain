import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/audio_file.dart';

class BackgroundAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final _player = AudioPlayer();

  // Episode navigation callbacks
  Function(AudioFile)? onSkipToNextEpisode;
  Function(AudioFile)? onSkipToPreviousEpisode;
  AudioFile? _currentAudioFile;

  BackgroundAudioHandler() {
    print('🎵 BackgroundAudioHandler: Initializing...');
    _init();
  }

  Future<void> _init() async {
    // Configure audio session for background playback and Control Center
    print('🎵 Configuring audio session for media notifications...');

    try {
      final session = await AudioSession.instance;
      // Use the music preset - it includes all necessary settings for media notifications
      await session.configure(const AudioSessionConfiguration.music());
      await session.setActive(true);

      // Handle audio interruptions for better iOS integration
      session.interruptionEventStream.listen((event) {
        if (event.begin) {
          print('🍎 Audio interruption began (phone call, etc.)');
          pause();
        } else {
          print('🍎 Audio interruption ended, resuming playback');
          if (event.type == AudioInterruptionType.pause) {
            play();
          }
        }
      });

      print('✅ Audio session configured for media notifications');
    } catch (e) {
      print('❌ Audio session configuration failed: $e');
    }

    // Listen to player events
    _player.playbackEventStream.listen(_broadcastState);
    _player.playerStateStream.listen((state) {
      print(
          '🔄 Player state changed: ${state.playing ? 'PLAYING' : 'PAUSED'} (${state.processingState})');
    });

    // Listen to duration changes to update MediaItem
    _player.durationStream.listen((duration) {
      final currentMediaItem = mediaItem.value;
      if (currentMediaItem != null &&
          duration != null &&
          currentMediaItem.duration != duration) {
        mediaItem.add(currentMediaItem.copyWith(duration: duration));
        print('🎵 MediaItem updated with duration: $duration');
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

    print('✅ BackgroundAudioHandler initialized with media session');
  }

  @override
  Future<void> play() async {
    print('▶️ BackgroundAudioHandler.play() called');
    try {
      await _player.play();
      print('✅ Player.play() completed successfully');
    } catch (e) {
      print('❌ Player.play() failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> pause() async {
    print('⏸️ BackgroundAudioHandler.pause() called');
    try {
      await _player.pause();
      print('✅ Player.pause() completed successfully');
    } catch (e) {
      print('❌ Player.pause() failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    print('⏹️ BackgroundAudioHandler.stop() called');
    try {
      await _player.stop();

      // Clear media item when stopped
      mediaItem.add(null);

      print('✅ Player.stop() completed successfully');
    } catch (e) {
      print('❌ Player.stop() failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> seek(Duration position) async {
    print('⏭️ BackgroundAudioHandler.seek() called: $position');
    try {
      await _player.seek(position);
      print('✅ Player.seek() completed successfully');
    } catch (e) {
      print('❌ Player.seek() failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> skipToNext() async {
    print('⏭️ BackgroundAudioHandler.skipToNext() called');

    // Try episode navigation first
    if (_currentAudioFile != null && onSkipToNextEpisode != null) {
      try {
        onSkipToNextEpisode!(_currentAudioFile!);
        print('✅ Episode navigation: skipToNext completed');
        return;
      } catch (e) {
        print('❌ Episode navigation failed, falling back to time skip: $e');
      }
    }

    // Fallback to time-based skip if episode navigation not available
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
  Future<void> skipToPrevious() async {
    print('⏮️ BackgroundAudioHandler.skipToPrevious() called');

    // Try episode navigation first
    if (_currentAudioFile != null && onSkipToPreviousEpisode != null) {
      try {
        onSkipToPreviousEpisode!(_currentAudioFile!);
        print('✅ Episode navigation: skipToPrevious completed');
        return;
      } catch (e) {
        print('❌ Episode navigation failed, falling back to time skip: $e');
      }
    }

    // Fallback to time-based skip if episode navigation not available
    final currentPosition = _player.position;
    final newPosition = currentPosition - const Duration(seconds: 10);

    if (newPosition > Duration.zero) {
      await seek(newPosition);
    } else {
      await seek(Duration.zero);
    }
  }

  Future<void> setAudioSource(String url,
      {String? title,
      String? artist,
      Duration? initialPosition,
      AudioFile? audioFile}) async {
    print('🎧 Setting audio source: $url');
    print(
        '🎧 Title: $title, Artist: $artist, InitialPosition: $initialPosition');

    try {
      // Track current audio file for episode navigation
      _currentAudioFile = audioFile;

      String resolvedUrl = url;

      // Resolve signed URLs if needed
      if (url.contains('davidtnfsh.workers.dev')) {
        resolvedUrl = await _resolveSignedUrl(url);
      }

      // Set MediaItem FIRST to ensure notification appears immediately
      mediaItem.add(MediaItem(
        id: url,
        title: title ?? 'Unknown Title',
        artist: artist ?? 'From Fed to Chain',
        album: 'Crypto & Macro Economics Learning',
        duration: null, // Will be updated when audio loads
        artUri: _getArtworkUri(
            audioFile), // Will be null for now to avoid Android issues
        extras: {
          'episode_id': audioFile?.id,
          'language': audioFile?.language,
          'category': audioFile?.category,
        },
      ));

      await _player.setAudioSource(
        AudioSource.uri(Uri.parse(resolvedUrl)),
        initialPosition: initialPosition,
      );

      // Update MediaItem with duration once audio loads
      if (_player.duration != null) {
        mediaItem.add(MediaItem(
          id: url,
          title: title ?? 'Unknown Title',
          artist: artist ?? 'From Fed to Chain',
          album: 'Crypto & Macro Economics Learning',
          duration: _player.duration,
          artUri: _getArtworkUri(
              audioFile), // Will be null for now to avoid Android issues
          extras: {
            'episode_id': audioFile?.id,
            'language': audioFile?.language,
            'category': audioFile?.category,
          },
        ));
      }

      print('✅ Audio source set successfully');
    } catch (e) {
      print('❌ Failed to set audio source: $e');
      rethrow;
    }
  }

  // Set episode navigation callbacks
  void setEpisodeNavigationCallbacks({
    Function(AudioFile)? onNext,
    Function(AudioFile)? onPrevious,
  }) {
    onSkipToNextEpisode = onNext;
    onSkipToPreviousEpisode = onPrevious;
    print('🎵 Episode navigation callbacks set');
  }

  // Get artwork URI based on episode category
  Uri? _getArtworkUri(AudioFile? audioFile) {
    // For now, return null to avoid Android asset URI issues
    // TODO: Replace with actual hosted artwork URLs or properly configured local assets
    return null;

    /* Future implementation with proper artwork:
    if (audioFile == null) {
      return Uri.parse('https://your-domain.com/images/episode_placeholder.png');
    }

    // Use category-specific artwork or default placeholder
    switch (audioFile.category) {
      case 'daily-news':
        return Uri.parse('https://your-domain.com/images/daily_news_artwork.png');
      case 'ethereum':
        return Uri.parse('https://your-domain.com/images/ethereum_artwork.png');
      case 'macro':
        return Uri.parse('https://your-domain.com/images/macro_artwork.png');
      case 'startup':
        return Uri.parse('https://your-domain.com/images/startup_artwork.png');
      default:
        return Uri.parse('https://your-domain.com/images/episode_placeholder.png');
    }
    */
  }

  // Resolve signed URL from Cloudflare worker response
  Future<String> _resolveSignedUrl(String workerUrl) async {
    if (kDebugMode) {
      print('🔗 Resolving signed URL from: $workerUrl');
    }

    try {
      final response = await http.get(Uri.parse(workerUrl));

      if (response.statusCode == 200) {
        // Check if response is JSON (signed URL response)
        if (response.headers['content-type']?.contains('application/json') ==
            true) {
          final jsonData = json.decode(response.body);
          final signedUrl = jsonData['url'] as String;

          if (kDebugMode) {
            print('🔗 Resolved signed URL: $signedUrl');
          }

          return signedUrl;
        } else {
          // If not JSON, assume it's the direct content
          if (kDebugMode) {
            print('🔗 Direct content, using original URL');
          }
          return workerUrl;
        }
      } else {
        throw Exception('Failed to resolve signed URL: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error resolving signed URL: $e');
      }
      throw Exception('Failed to resolve signed URL: $e');
    }
  }

  void _broadcastState(PlaybackEvent event) {
    final state = PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [
        0,
        1,
        2
      ], // Previous, Play/Pause, Next for optimal iOS Control Center
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: 0, // For episode queue position in iOS Control Center
    );

    playbackState.add(state);

    // Log state changes for debugging
    if (kDebugMode) {
      print(
          '📡 Broadcasting state: ${state.playing ? 'PLAYING' : 'PAUSED'} - ${state.processingState}');
      print(
          '📡 iOS Controls: Previous | ${state.playing ? 'Pause' : 'Play'} | Next | Stop');
    }
  }

  // Getters for convenience
  bool get isPlaying => _player.playing;
  bool get isPaused =>
      !_player.playing && _player.processingState == ProcessingState.ready;
  Duration get position => _player.position;
  Duration get duration => _player.duration ?? Duration.zero;
  double get speed => _player.speed;

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    print('🔧 Custom action called: $name with extras: $extras');

    switch (name) {
      case 'setSpeed':
        final speed = extras?['speed'] as double? ?? 1.0;
        await _player.setSpeed(speed);
        break;
      case 'skipForward':
        await skipToNext(); // Uses our 30-second skip
        break;
      case 'skipBackward':
        await skipToPrevious(); // Uses our 10-second skip
        break;
      default:
        print('❓ Unknown custom action: $name');
    }
  }

  @override
  Future<void> onTaskRemoved() async {
    print('📱 App task removed - stopping audio');
    await stop();
  }

  @override
  Future<void> onNotificationDeleted() async {
    print('🔔 Notification deleted - stopping audio');
    await stop();
  }
}
