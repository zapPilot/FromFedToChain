import 'package:flutter/material.dart';
import '../themes/app_theme.dart';
import '../models/audio_file.dart';
import '../services/audio_service.dart';

/// Compact audio player widget shown at bottom of home screen
class MiniPlayer extends StatelessWidget {
  final AudioFile audioFile;
  final PlaybackState playbackState;
  final VoidCallback onTap;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const MiniPlayer({
    super.key,
    required this.audioFile,
    required this.playbackState,
    required this.onTap,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingM),
      decoration: AppTheme.glassMorphismDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Row(
              children: [
                // Album art / Icon
                _buildAlbumArt(),

                const SizedBox(width: AppTheme.spacingM),

                // Track info
                Expanded(
                  child: _buildTrackInfo(),
                ),

                // Controls
                _buildControls(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build album art or category icon
  Widget _buildAlbumArt() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        _getCategoryIcon(audioFile.category),
        color: AppTheme.onPrimaryColor,
        size: 24,
      ),
    );
  }

  /// Build track information section
  Widget _buildTrackInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Track title
        Text(
          audioFile.displayTitle,
          style: AppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: AppTheme.spacingXS),

        // Track details with playback state
        Row(
          children: [
            // Category and language
            Text(
              '${audioFile.categoryEmoji} ${audioFile.category}',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.getCategoryColor(audioFile.category),
              ),
            ),

            const SizedBox(width: AppTheme.spacingS),

            Text(
              '•',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.onSurfaceColor.withOpacity(0.5),
              ),
            ),

            const SizedBox(width: AppTheme.spacingS),

            Text(
              '${audioFile.languageFlag} ${audioFile.language}',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.getLanguageColor(audioFile.language),
              ),
            ),

            const Spacer(),

            // Playback state indicator
            _buildPlaybackStateIndicator(),
          ],
        ),
      ],
    );
  }

  /// Build playback state indicator
  Widget _buildPlaybackStateIndicator() {
    Color indicatorColor;
    IconData indicatorIcon;

    switch (playbackState) {
      case PlaybackState.playing:
        indicatorColor = AppTheme.playingColor;
        indicatorIcon = Icons.graphic_eq;
        break;
      case PlaybackState.paused:
        indicatorColor = AppTheme.pausedColor;
        indicatorIcon = Icons.pause_circle_outline;
        break;
      case PlaybackState.loading:
        indicatorColor = AppTheme.loadingColor;
        indicatorIcon = Icons.hourglass_empty;
        break;
      case PlaybackState.error:
        indicatorColor = AppTheme.errorStateColor;
        indicatorIcon = Icons.error_outline;
        break;
      default:
        indicatorColor = AppTheme.onSurfaceColor.withOpacity(0.5);
        indicatorIcon = Icons.stop_circle;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          indicatorIcon,
          size: 12,
          color: indicatorColor,
        ),
        const SizedBox(width: AppTheme.spacingXS),
        Text(
          _getPlaybackStateText(playbackState),
          style: AppTheme.bodySmall.copyWith(
            color: indicatorColor,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  /// Build control buttons
  Widget _buildControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Previous button
        _buildControlButton(
          icon: Icons.skip_previous,
          onPressed: onPrevious,
          size: 32,
        ),

        const SizedBox(width: AppTheme.spacingS),

        // Play/Pause button
        _buildControlButton(
          icon: _getPlayPauseIcon(),
          onPressed: onPlayPause,
          size: 40,
          isPrimary: true,
        ),

        const SizedBox(width: AppTheme.spacingS),

        // Next button
        _buildControlButton(
          icon: Icons.skip_next,
          onPressed: onNext,
          size: 32,
        ),
      ],
    );
  }

  /// Build individual control button
  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required double size,
    bool isPrimary = false,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: IconButton(
        onPressed: playbackState == PlaybackState.loading && isPrimary
            ? null
            : onPressed,
        icon: playbackState == PlaybackState.loading && isPrimary
            ? SizedBox(
                width: size * 0.6,
                height: size * 0.6,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.onPrimaryColor,
                  ),
                ),
              )
            : Icon(
                icon,
                size: size * 0.6,
              ),
        style: IconButton.styleFrom(
          backgroundColor: isPrimary
              ? AppTheme.primaryColor
              : AppTheme.cardColor.withOpacity(0.5),
          foregroundColor:
              isPrimary ? AppTheme.onPrimaryColor : AppTheme.onSurfaceColor,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(size / 2),
          ),
        ),
      ),
    );
  }

  /// Get appropriate play/pause icon
  IconData _getPlayPauseIcon() {
    switch (playbackState) {
      case PlaybackState.playing:
        return Icons.pause;
      case PlaybackState.paused:
      case PlaybackState.stopped:
        return Icons.play_arrow;
      case PlaybackState.loading:
        return Icons.play_arrow; // Will be replaced by loading indicator
      case PlaybackState.error:
        return Icons.refresh;
    }
  }

  /// Get category icon
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'daily-news':
        return Icons.newspaper;
      case 'ethereum':
        return Icons.currency_bitcoin;
      case 'macro':
        return Icons.trending_up;
      case 'startup':
        return Icons.rocket_launch;
      case 'ai':
        return Icons.smart_toy;
      case 'defi':
        return Icons.account_balance;
      default:
        return Icons.headphones;
    }
  }

  /// Get playback state text for display
  String _getPlaybackStateText(PlaybackState state) {
    switch (state) {
      case PlaybackState.playing:
        return 'Playing';
      case PlaybackState.paused:
        return 'Paused';
      case PlaybackState.loading:
        return 'Loading';
      case PlaybackState.error:
        return 'Error';
      case PlaybackState.stopped:
        return 'Stopped';
    }
  }
}
