import 'package:flutter/material.dart';
import 'package:from_fed_to_chain_app/core/theme/app_theme.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';

import 'package:from_fed_to_chain_app/features/audio/services/player_state_notifier.dart';

class PlayerArtwork extends StatefulWidget {
  final AudioFile? audioFile;
  final bool isPlaying;
  final AppPlaybackState playbackState;

  const PlayerArtwork({
    super.key,
    required this.audioFile,
    required this.isPlaying,
    required this.playbackState,
  });

  @override
  State<PlayerArtwork> createState() => _PlayerArtworkState();
}

class _PlayerArtworkState extends State<PlayerArtwork>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _albumArtAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    _albumArtAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.audioFile == null) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Make album art responsive to available space
        final maxSize = constraints.maxHeight > 0
            ? (constraints.maxHeight * 0.6)
                .clamp(120.0, 280.0) // 60% of available height
            : 200.0; // Fallback size
        final iconSize = maxSize * 0.43;

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated album art
              RotationTransition(
                turns: widget.isPlaying
                    ? _albumArtAnimation
                    : const AlwaysStoppedAnimation(0.0),
                child: Container(
                  width: maxSize,
                  height: maxSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: maxSize * 0.1,
                        offset: Offset(0, maxSize * 0.035),
                      ),
                    ],
                  ),
                  child: Icon(
                    AppTheme.getCategoryIcon(widget.audioFile!.category),
                    size: iconSize,
                    color: AppTheme.onPrimaryColor,
                  ),
                ),
              ),

              SizedBox(height: (maxSize * 0.06).clamp(8.0, AppTheme.spacingL)),

              // Playback state indicator
              _buildAppPlaybackStateIndicator(widget.playbackState),
            ],
          ),
        );
      },
    );
  }

  /// Build playback state indicator
  Widget _buildAppPlaybackStateIndicator(AppPlaybackState state) {
    String stateText;
    Color stateColor;
    IconData stateIcon;

    switch (state) {
      case AppPlaybackState.playing:
        stateText = 'Playing';
        stateColor = AppTheme.playingColor;
        stateIcon = Icons.play_arrow;
        break;
      case AppPlaybackState.paused:
        stateText = 'Paused';
        stateColor = AppTheme.pausedColor;
        stateIcon = Icons.pause;
        break;
      case AppPlaybackState.loading:
        stateText = 'Loading...';
        stateColor = AppTheme.loadingColor;
        stateIcon = Icons.hourglass_empty;
        break;
      case AppPlaybackState.error:
        stateText = 'Error';
        stateColor = AppTheme.errorStateColor;
        stateIcon = Icons.error;
        break;
      default:
        stateText = 'Stopped';
        stateColor = AppTheme.onSurfaceColor.withValues(alpha: 0.6);
        stateIcon = Icons.stop;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      decoration: BoxDecoration(
        color: stateColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(
          color: stateColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            stateIcon,
            size: 16,
            color: stateColor,
          ),
          const SizedBox(width: AppTheme.spacingS),
          Text(
            stateText,
            style: AppTheme.bodySmall.copyWith(
              color: stateColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
