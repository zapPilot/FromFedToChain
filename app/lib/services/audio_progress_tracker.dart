import 'package:flutter/foundation.dart';

import 'content_facade_service.dart';

/// Handles progress updates and episode completion tracking
///
/// This component manages the throttled progress updates to avoid excessive
/// calls to the content service while ensuring accurate progress tracking
/// for episode completion and resume functionality.
class AudioProgressTracker {
  final ContentFacadeService? _contentService;

  // Progress tracking throttling
  DateTime _lastProgressUpdate = DateTime(0);
  static const int _updateThrottleMs = 1000;

  AudioProgressTracker(this._contentService);

  /// Update progress for the current episode
  ///
  /// Progress updates are throttled to avoid excessive calls to the content service.
  /// Only updates if progress is significant (>= 1%) to avoid spam.
  void updateProgress(String episodeId, Duration position, Duration total) {
    if (_contentService == null) {
      return;
    }

    // Throttle progress updates to avoid excessive calls
    if (_shouldThrottleUpdate()) {
      return;
    }

    if (total.inMilliseconds <= 0) {
      return; // Avoid division by zero
    }

    final progress = _calculateProgress(position, total);

    // Only update if progress is significant (avoid spam)
    if (progress >= 0.01) {
      _contentService!.updateEpisodeCompletion(episodeId, progress);
      _lastProgressUpdate = DateTime.now();

      // Log progress every 10% for debugging
      if (kDebugMode && progress % 0.1 < 0.01) {
        print('📊 AudioProgressTracker: Episode $episodeId progress: ${(progress * 100).toInt()}%');
      }
    }
  }

  /// Mark an episode as completed
  ///
  /// This should be called when playback reaches the end of an episode
  /// to ensure proper completion tracking in the content service.
  Future<void> markEpisodeCompleted(String episodeId) async {
    if (_contentService == null) {
      if (kDebugMode) {
        print('⚠️ AudioProgressTracker: Cannot mark episode as finished - no content service');
      }
      return;
    }

    try {
      await _contentService!.markEpisodeAsFinished(episodeId);
      if (kDebugMode) {
        print('✅ AudioProgressTracker: Episode marked as finished: $episodeId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ AudioProgressTracker: Failed to mark episode as finished: $e');
      }
      // Don't rethrow - this shouldn't block other operations
    }
  }

  /// Save current playback progress for the episode
  ///
  /// This is useful for saving progress when the app is closing
  /// or when switching between episodes.
  void saveProgress(String episodeId, Duration position, Duration total) {
    if (_contentService == null || total.inMilliseconds <= 0) {
      return;
    }

    final progress = _calculateProgress(position, total);
    _contentService!.updateEpisodeCompletion(episodeId, progress);

    if (kDebugMode) {
      print('💾 AudioProgressTracker: Saved progress for $episodeId: ${(progress * 100).toInt()}%');
    }
  }

  /// Get the completion progress for an episode
  ///
  /// Returns the progress as a value between 0.0 and 1.0
  double getEpisodeProgress(String episodeId) {
    if (_contentService == null) {
      return 0.0;
    }

    return _contentService!.getEpisodeCompletion(episodeId);
  }

  /// Calculate the resume position for an episode based on saved progress
  ///
  /// Returns the position where playback should resume, or Duration.zero
  /// if no progress is saved or if the episode is near completion.
  Duration calculateResumePosition(String episodeId, Duration totalDuration) {
    if (_contentService == null || totalDuration.inMilliseconds <= 0) {
      return Duration.zero;
    }

    final progress = _contentService!.getEpisodeCompletion(episodeId);

    // If progress is very close to completion (>95%), start from beginning
    if (progress > 0.95) {
      return Duration.zero;
    }

    // If progress is very small (<5%), start from beginning
    if (progress < 0.05) {
      return Duration.zero;
    }

    final resumePosition = Duration(
      milliseconds: (totalDuration.inMilliseconds * progress).round(),
    );

    if (kDebugMode) {
      print('🔄 AudioProgressTracker: Resume position for $episodeId: ${resumePosition.inSeconds}s (${(progress * 100).toInt()}%)');
    }

    return resumePosition;
  }

  /// Check if progress update should be throttled
  bool _shouldThrottleUpdate() {
    final now = DateTime.now();
    return now.difference(_lastProgressUpdate).inMilliseconds < _updateThrottleMs;
  }

  /// Calculate progress as a value between 0.0 and 1.0
  double _calculateProgress(Duration position, Duration total) {
    if (total.inMilliseconds <= 0) {
      return 0.0;
    }

    final progress = position.inMilliseconds / total.inMilliseconds;
    return progress.clamp(0.0, 1.0);
  }

  /// Reset the throttling timer
  ///
  /// This can be useful for testing or when you want to force
  /// an immediate progress update.
  @visibleForTesting
  void resetThrottling() {
    _lastProgressUpdate = DateTime(0);
  }

  /// Get the last progress update timestamp
  ///
  /// Useful for testing throttling behavior.
  @visibleForTesting
  DateTime get lastUpdateTime => _lastProgressUpdate;
}