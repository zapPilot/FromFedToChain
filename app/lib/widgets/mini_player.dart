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
    // Responsive spacing and sizing based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmall = screenWidth < 360;
    final margin = isVerySmall ? AppTheme.spacingXS : AppTheme.spacingS;
    final padding = isVerySmall ? AppTheme.spacingXS : AppTheme.spacingS;
    final spacing = isVerySmall ? AppTheme.spacingXS : AppTheme.spacingS;
    
    return Container(
      margin: EdgeInsets.all(margin),
      decoration: AppTheme.glassMorphismDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Row(
              children: [
                // Album art / Icon
                _buildAlbumArt(size: isVerySmall ? 36 : 44),

                SizedBox(width: spacing),

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
  Widget _buildAlbumArt({double size = 48}) {
    return Container(
      width: size,
      height: size,
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
        size: size * 0.5, // Scale icon with container size
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
            // Category and language in flexible container
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Category
                  Flexible(
                    child: Text(
                      '${audioFile.categoryEmoji} ${audioFile.category}',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.getCategoryColor(audioFile.category),
                      ),
                      overflow: TextOverflow.ellipsis,
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

                  // Language
                  Flexible(
                    child: Text(
                      '${audioFile.languageFlag} ${audioFile.language}',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.getLanguageColor(audioFile.language),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppTheme.spacingS),

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
    return LayoutBuilder(
      builder: (context, constraints) {
        // Ensure minimum 48px tap targets for accessibility compliance
        // while adapting to screen space and preventing overflow
        final screenWidth = MediaQuery.of(context).size.width;
        final isVerySmall = screenWidth < 360;
        final isSmall = screenWidth < 480;
        
        // Adjust sizes based on available space while maintaining minimum accessibility size
        final secondarySize = 48.0; // Minimum accessibility size
        final primarySize = isVerySmall ? 48.0 : (isSmall ? 50.0 : 52.0);
        final spacing = isVerySmall ? 2.0 : AppTheme.spacingXS;
        
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Previous button
            _buildControlButton(
              icon: Icons.skip_previous,
              onPressed: onPrevious,
              size: secondarySize,
              semanticLabel: 'Previous track',
            ),

            SizedBox(width: spacing),

            // Play/Pause button
            _buildControlButton(
              icon: _getPlayPauseIcon(),
              onPressed: onPlayPause,
              size: primarySize,
              isPrimary: true,
              semanticLabel: _getPlayPauseSemanticLabel(),
            ),

            SizedBox(width: spacing),

            // Next button
            _buildControlButton(
              icon: Icons.skip_next,
              onPressed: onNext,
              size: secondarySize,
              semanticLabel: 'Next track',
            ),
          ],
        );
      },
    );
  }

  /// Build individual control button
  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required double size,
    required String semanticLabel,
    bool isPrimary = false,
  }) {
    // Calculate icon size - smaller proportion for 48px+ buttons to maintain balance
    final iconSize = isPrimary 
        ? size * 0.5  // Larger primary button gets proportionally smaller icon
        : size * 0.45; // Secondary buttons get slightly smaller icons
    
    return SizedBox(
      width: size,
      height: size,
      child: IconButton(
        onPressed: playbackState == PlaybackState.loading && isPrimary
            ? null
            : onPressed,
        tooltip: semanticLabel,
        icon: playbackState == PlaybackState.loading && isPrimary
            ? SizedBox(
                width: iconSize,
                height: iconSize,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.onPrimaryColor,
                  ),
                ),
              )
            : Icon(
                icon,
                size: iconSize,
                semanticLabel: semanticLabel,
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

  /// Get semantic label for play/pause button based on current state
  String _getPlayPauseSemanticLabel() {
    switch (playbackState) {
      case PlaybackState.playing:
        return 'Pause';
      case PlaybackState.paused:
      case PlaybackState.stopped:
        return 'Play';
      case PlaybackState.loading:
        return 'Loading, please wait';
      case PlaybackState.error:
        return 'Retry playback';
    }
  }
}
