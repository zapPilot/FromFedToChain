import 'package:flutter/foundation.dart';

import '../models/audio_file.dart';
import 'audio_progress_tracker.dart';
import 'content_facade_service.dart';
import 'player_controller.dart';

/// Handles episode navigation logic and autoplay/repeat functionality
///
/// This service manages the business logic for moving between episodes,
/// including autoplay when episodes complete and repeat functionality.
/// It coordinates between the PlayerController and ContentFacadeService
/// to provide seamless episode navigation.
class PlaybackNavigationService {
  final ContentFacadeService? _contentService;
  final PlayerController _playerController;
  final AudioProgressTracker _progressTracker;

  // Navigation settings
  bool _autoplayEnabled = true;
  bool _repeatEnabled = false;

  PlaybackNavigationService(
    this._contentService,
    this._playerController,
    this._progressTracker,
  );

  // Getters for current settings
  bool get autoplayEnabled => _autoplayEnabled;
  bool get repeatEnabled => _repeatEnabled;

  /// Set autoplay preference
  void setAutoplayEnabled(bool enabled) {
    if (_autoplayEnabled != enabled) {
      _autoplayEnabled = enabled;
      if (kDebugMode) {
        print('🔄 PlaybackNavigationService: Autoplay ${enabled ? 'enabled' : 'disabled'}');
      }
    }
  }

  /// Set repeat preference
  void setRepeatEnabled(bool enabled) {
    if (_repeatEnabled != enabled) {
      _repeatEnabled = enabled;
      if (kDebugMode) {
        print('🔄 PlaybackNavigationService: Repeat ${enabled ? 'enabled' : 'disabled'}');
      }
    }
  }

  /// Toggle autoplay setting
  void toggleAutoplay() {
    setAutoplayEnabled(!_autoplayEnabled);
  }

  /// Toggle repeat setting
  void toggleRepeat() {
    setRepeatEnabled(!_repeatEnabled);
  }

  /// Skip to the next episode and return the episode that started playing
  Future<AudioFile?> skipToNext(AudioFile currentEpisode) async {
    if (_contentService == null) {
      if (kDebugMode) {
        print('❌ PlaybackNavigationService: Cannot skip to next - no content service');
      }
      return null;
    }

    try {
      final nextEpisode = _contentService!.getNextEpisode(currentEpisode);
      if (nextEpisode != null) {
        if (kDebugMode) {
          print('⏭️ PlaybackNavigationService: Skipping to next episode: ${nextEpisode.id}');
        }
        final resumePosition = _progressTracker.calculateResumePosition(
          nextEpisode.id,
          nextEpisode.duration ?? Duration.zero,
        );
        await _playerController.play(
          nextEpisode,
          initialPosition:
              resumePosition > Duration.zero ? resumePosition : null,
        );
        return nextEpisode;
      }

      if (kDebugMode) {
        print('📝 PlaybackNavigationService: No next episode available');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ PlaybackNavigationService: Failed to skip to next episode: $e');
      }
      // Don't rethrow - navigation errors shouldn't crash the app
    }

    return null;
  }

  /// Skip to the previous episode and return the episode that started playing
  Future<AudioFile?> skipToPrevious(AudioFile currentEpisode) async {
    if (_contentService == null) {
      if (kDebugMode) {
        print('❌ PlaybackNavigationService: Cannot skip to previous - no content service');
      }
      return null;
    }

    try {
      final previousEpisode = _contentService!.getPreviousEpisode(currentEpisode);
      if (previousEpisode != null) {
        if (kDebugMode) {
          print('⏮️ PlaybackNavigationService: Skipping to previous episode: ${previousEpisode.id}');
        }
        final resumePosition = _progressTracker.calculateResumePosition(
          previousEpisode.id,
          previousEpisode.duration ?? Duration.zero,
        );
        await _playerController.play(
          previousEpisode,
          initialPosition:
              resumePosition > Duration.zero ? resumePosition : null,
        );
        return previousEpisode;
      }

      if (kDebugMode) {
        print('📝 PlaybackNavigationService: No previous episode available');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ PlaybackNavigationService: Failed to skip to previous episode: $e');
      }
      // Don't rethrow - navigation errors shouldn't crash the app
    }

    return null;
  }

  /// Handle episode completion (repeat, autoplay, or stop) and return the episode that started playing
  ///
  /// This method implements the complex logic for what happens when an episode
  /// finishes playing. Repeat mode takes precedence over autoplay.
  Future<AudioFile?> handleEpisodeCompletion(AudioFile completedEpisode) async {
    if (kDebugMode) {
      print('🎵 PlaybackNavigationService: Episode completed. Repeat: $_repeatEnabled, Autoplay: $_autoplayEnabled');
    }

    // Repeat mode takes precedence over autoplay
    if (_repeatEnabled) {
      if (kDebugMode) {
        print('🔁 PlaybackNavigationService: Repeating current episode');
      }
      try {
        // Small delay to ensure smooth transition
        await Future.delayed(const Duration(milliseconds: 500));
        await _playerController.play(
          completedEpisode,
          initialPosition: Duration.zero,
        );
        if (kDebugMode) {
          print('✅ PlaybackNavigationService: Repeat completed successfully');
        }
        return completedEpisode;
      } catch (e) {
        if (kDebugMode) {
          print('❌ PlaybackNavigationService: Repeat failed: $e');
        }
        // Don't rethrow - let the error be handled by PlayerController
        return null;
      }
    }

    // If autoplay is disabled, stop here
    if (!_autoplayEnabled) {
      if (kDebugMode) {
        print('📝 PlaybackNavigationService: Autoplay disabled, stopping playback');
      }
      return null;
    }

    // Check if content service is available for autoplay
    if (_contentService == null) {
      if (kDebugMode) {
        print('❌ PlaybackNavigationService: ContentService not available for autoplay');
      }
      return null;
    }

    // Try to play the next episode
    try {
      final nextEpisode = _contentService!.getNextEpisode(completedEpisode);
      if (nextEpisode != null) {
        if (kDebugMode) {
          print('⏭️ PlaybackNavigationService: Autoplay starting next episode: ${nextEpisode.id}');
        }

        // Small delay to ensure smooth transition
        await Future.delayed(const Duration(milliseconds: 500));

        final resumePosition = _progressTracker.calculateResumePosition(
          nextEpisode.id,
          nextEpisode.duration ?? Duration.zero,
        );

        await _playerController.play(
          nextEpisode,
          initialPosition:
              resumePosition > Duration.zero ? resumePosition : null,
        );
        if (kDebugMode) {
          print('✅ PlaybackNavigationService: Autoplay completed successfully');
        }
        return nextEpisode;
      }

      if (kDebugMode) {
        print('📝 PlaybackNavigationService: No next episode available for autoplay');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ PlaybackNavigationService: Autoplay failed: $e');
      }
      // Don't rethrow - autoplay failures shouldn't crash the app
    }

    return null;
  }

  /// Check if there is a next episode available
  bool hasNextEpisode(AudioFile currentEpisode) {
    if (_contentService == null) return false;
    return _contentService!.getNextEpisode(currentEpisode) != null;
  }

  /// Check if there is a previous episode available
  bool hasPreviousEpisode(AudioFile currentEpisode) {
    if (_contentService == null) return false;
    return _contentService!.getPreviousEpisode(currentEpisode) != null;
  }

  /// Get the next episode without playing it
  AudioFile? getNextEpisode(AudioFile currentEpisode) {
    if (_contentService == null) return null;
    return _contentService!.getNextEpisode(currentEpisode);
  }

  /// Get the previous episode without playing it
  AudioFile? getPreviousEpisode(AudioFile currentEpisode) {
    if (_contentService == null) return null;
    return _contentService!.getPreviousEpisode(currentEpisode);
  }

  /// Enable autoplay (alias for setAutoplayEnabled)
  void enableAutoplay(bool enabled) {
    setAutoplayEnabled(enabled);
  }
}