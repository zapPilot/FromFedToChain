import 'package:flutter/material.dart';
import 'package:from_fed_to_chain_app/core/theme/app_theme.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';

/// A compact audio player widget typically displayed at the bottom of the screen.
///
/// Shows the current [audioFile] info and playback controls.
/// This widget is stateless and relies on callbacks for interaction,
/// making it decoupled from specific state management (like AudioService).
class MiniPlayer extends StatelessWidget {
  /// The currently playing audio file.
  final AudioFile audioFile;

  /// Whether audio is currently playing.
  final bool isPlaying;

  /// Whether playback is paused.
  final bool isPaused;

  /// Whether the player is in a loading state.
  final bool isLoading;

  /// Whether an error state exists.
  final bool hasError;

  /// Text to display describing the current state (e.g., 'Playing', 'Paused').
  final String stateText;

  /// Callback when the player area is tapped (e.g., to open full player).
  final VoidCallback onTap;

  /// Callback for the play/pause button.
  final VoidCallback onPlayPause;

  /// Callback for the next track button.
  final VoidCallback onNext;

  /// Callback for the previous track button.
  final VoidCallback onPrevious;

  /// Creates a [MiniPlayer].
  const MiniPlayer({
    super.key,
    required this.audioFile,
    required this.isPlaying,
    required this.isPaused,
    required this.isLoading,
    required this.hasError,
    required this.stateText,
    required this.onTap,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final layoutValues = _resolveLayoutValues(screenWidth);

    return Container(
      margin: EdgeInsets.all(layoutValues.margin),
      decoration: AppTheme.glassMorphismDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          child: Padding(
            padding: EdgeInsets.all(layoutValues.padding),
            child: Row(
              children: [
                // Album art / Icon
                _buildAlbumArt(size: layoutValues.albumArtSize),

                SizedBox(width: layoutValues.spacing),

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
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        AppTheme.getCategoryIcon(audioFile.category),
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
                      color: AppTheme.onSurfaceColor.withValues(alpha: 0.5),
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

    if (hasError) {
      indicatorColor = AppTheme.errorStateColor;
      indicatorIcon = Icons.error_outline;
    } else if (isLoading) {
      indicatorColor = AppTheme.loadingColor;
      indicatorIcon = Icons.hourglass_empty;
    } else if (isPlaying) {
      indicatorColor = AppTheme.playingColor;
      indicatorIcon = Icons.graphic_eq;
    } else if (isPaused) {
      indicatorColor = AppTheme.pausedColor;
      indicatorIcon = Icons.pause_circle_outline;
    } else {
      indicatorColor = AppTheme.onSurfaceColor.withValues(alpha: 0.5);
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
          stateText,
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
      builder: (context, _) {
        final screenWidth = MediaQuery.of(context).size.width;
        final controlsLayout = _resolveControlsLayout(screenWidth);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Previous button
            _buildControlButton(
              icon: Icons.skip_previous,
              onPressed: onPrevious,
              size: controlsLayout.secondarySize,
              semanticLabel: 'Previous track',
            ),

            SizedBox(width: controlsLayout.spacing),

            // Play/Pause button
            _buildControlButton(
              icon: _getPlayPauseIcon(),
              onPressed: onPlayPause,
              size: controlsLayout.primarySize,
              isPrimary: true,
              semanticLabel: _getPlayPauseSemanticLabel(),
            ),

            SizedBox(width: controlsLayout.spacing),

            // Next button
            _buildControlButton(
              icon: Icons.skip_next,
              onPressed: onNext,
              size: controlsLayout.secondarySize,
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
        ? size * 0.5 // Larger primary button gets proportionally smaller icon
        : size * 0.45; // Secondary buttons get slightly smaller icons

    return SizedBox(
      width: size,
      height: size,
      child: IconButton(
        onPressed: isLoading && isPrimary ? null : onPressed,
        tooltip: semanticLabel,
        icon: isLoading && isPrimary
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
              : AppTheme.cardColor.withValues(alpha: 0.5),
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
    if (hasError) {
      return Icons.refresh;
    } else if (isPlaying) {
      return Icons.pause;
    } else {
      return Icons.play_arrow; // For paused, stopped, loading states
    }
  }

  /// Get semantic label for play/pause button based on current state
  String _getPlayPauseSemanticLabel() {
    if (hasError) {
      return 'Retry playback';
    } else if (isLoading) {
      return 'Loading, please wait';
    } else if (isPlaying) {
      return 'Pause';
    } else {
      return 'Play'; // For paused, stopped states
    }
  }

  _MiniPlayerLayoutValues _resolveLayoutValues(double screenWidth) {
    final isVerySmall = screenWidth < 360;
    if (isVerySmall) {
      return const _MiniPlayerLayoutValues(
        margin: AppTheme.spacingXS,
        padding: AppTheme.spacingXS,
        spacing: AppTheme.spacingXS,
        albumArtSize: 36,
      );
    }

    return const _MiniPlayerLayoutValues(
      margin: AppTheme.spacingS,
      padding: AppTheme.spacingS,
      spacing: AppTheme.spacingS,
      albumArtSize: 44,
    );
  }

  _MiniPlayerControlsLayout _resolveControlsLayout(double screenWidth) {
    const secondarySize = 48.0;
    if (screenWidth < 360) {
      return const _MiniPlayerControlsLayout(
        secondarySize: secondarySize,
        primarySize: 48.0,
        spacing: 2.0,
      );
    }

    if (screenWidth < 480) {
      return const _MiniPlayerControlsLayout(
        secondarySize: secondarySize,
        primarySize: 50.0,
        spacing: AppTheme.spacingXS,
      );
    }

    return const _MiniPlayerControlsLayout(
      secondarySize: secondarySize,
      primarySize: 52.0,
      spacing: AppTheme.spacingXS,
    );
  }
}

class _MiniPlayerLayoutValues {
  final double margin;
  final double padding;
  final double spacing;
  final double albumArtSize;

  const _MiniPlayerLayoutValues({
    required this.margin,
    required this.padding,
    required this.spacing,
    required this.albumArtSize,
  });
}

class _MiniPlayerControlsLayout {
  final double secondarySize;
  final double primarySize;
  final double spacing;

  const _MiniPlayerControlsLayout({
    required this.secondarySize,
    required this.primarySize,
    required this.spacing,
  });
}
