import 'package:flutter/material.dart';
import 'package:from_fed_to_chain_app/core/theme/app_theme.dart';
import 'package:from_fed_to_chain_app/features/audio/services/audio_player_service.dart';
import 'package:from_fed_to_chain_app/features/audio/widgets/playback_speed_selector.dart';

class PlayerAdditionalControls extends StatefulWidget {
  final AudioPlayerService audioService;
  final bool showContentScript;
  final ValueChanged<bool> onToggleContentScript;
  final VoidCallback onShare;
  final VoidCallback onAddToPlaylist;

  const PlayerAdditionalControls({
    super.key,
    required this.audioService,
    required this.showContentScript,
    required this.onToggleContentScript,
    required this.onShare,
    required this.onAddToPlaylist,
  });

  @override
  State<PlayerAdditionalControls> createState() =>
      _PlayerAdditionalControlsState();
}

class _PlayerAdditionalControlsState extends State<PlayerAdditionalControls> {
  bool _showSpeedSelector = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppTheme.safeHorizontalPadding,
      child: Column(
        children: [
          // Speed selector (show when toggled)
          if (_showSpeedSelector) ...[
            PlaybackSpeedSelector(
              currentSpeed: widget.audioService.playbackSpeed,
              onSpeedChanged: (speed) {
                widget.audioService.setPlaybackSpeed(speed);
                setState(() {
                  _showSpeedSelector = false;
                });
              },
            ),
            const SizedBox(height: AppTheme.spacingM),
          ],

          // Control buttons row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Content script toggle
              IconButton(
                onPressed: () {
                  widget.onToggleContentScript(!widget.showContentScript);
                },
                icon: const Icon(Icons.article),
                style: IconButton.styleFrom(
                  backgroundColor: widget.showContentScript
                      ? AppTheme.primaryColor.withValues(alpha: 0.2)
                      : AppTheme.cardColor.withValues(alpha: 0.5),
                  foregroundColor: widget.showContentScript
                      ? AppTheme.primaryColor
                      : AppTheme.onSurfaceColor,
                ),
              ),

              // Playback speed
              IconButton(
                onPressed: () {
                  setState(() {
                    _showSpeedSelector = !_showSpeedSelector;
                  });
                },
                icon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.speed),
                    const SizedBox(width: AppTheme.spacingXS),
                    Text(
                      '${widget.audioService.playbackSpeed}x',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.onSurfaceColor,
                      ),
                    ),
                  ],
                ),
                style: IconButton.styleFrom(
                  backgroundColor: _showSpeedSelector
                      ? AppTheme.primaryColor.withValues(alpha: 0.2)
                      : AppTheme.cardColor.withValues(alpha: 0.5),
                  foregroundColor: _showSpeedSelector
                      ? AppTheme.primaryColor
                      : AppTheme.onSurfaceColor,
                ),
              ),

              // Repeat toggle
              IconButton(
                onPressed: () {
                  widget.audioService
                      .setRepeatEnabled(!widget.audioService.repeatEnabled);
                },
                icon: Icon(
                  widget.audioService.repeatEnabled
                      ? Icons.repeat_one
                      : Icons.repeat,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: widget.audioService.repeatEnabled
                      ? AppTheme.primaryColor.withValues(alpha: 0.2)
                      : AppTheme.cardColor.withValues(alpha: 0.5),
                  foregroundColor: widget.audioService.repeatEnabled
                      ? AppTheme.primaryColor
                      : AppTheme.onSurfaceColor,
                ),
              ),

              // Autoplay toggle
              IconButton(
                onPressed: () {
                  widget.audioService
                      .setAutoplayEnabled(!widget.audioService.autoplayEnabled);
                },
                icon: Icon(
                  widget.audioService.autoplayEnabled
                      ? Icons.skip_next
                      : Icons.playlist_play,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: widget.audioService.autoplayEnabled
                      ? AppTheme.primaryColor.withValues(alpha: 0.2)
                      : AppTheme.cardColor.withValues(alpha: 0.5),
                  foregroundColor: widget.audioService.autoplayEnabled
                      ? AppTheme.primaryColor
                      : AppTheme.onSurfaceColor,
                ),
              ),

              // Share
              IconButton(
                onPressed: widget.onShare,
                icon: const Icon(Icons.share),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.cardColor.withValues(alpha: 0.5),
                  foregroundColor: AppTheme.onSurfaceColor,
                ),
              ),

              // Add to playlist
              IconButton(
                onPressed: widget.onAddToPlaylist,
                icon: const Icon(Icons.playlist_add),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.cardColor.withValues(alpha: 0.5),
                  foregroundColor: AppTheme.onSurfaceColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
