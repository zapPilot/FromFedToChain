import 'package:flutter/material.dart';
import 'package:from_fed_to_chain_app/core/theme/app_theme.dart';
import 'package:from_fed_to_chain_app/features/audio/services/audio_player_service.dart';

class PlayerProgressBar extends StatelessWidget {
  final AudioPlayerService audioService;
  final ValueChanged<Duration> onSeek;

  const PlayerProgressBar({
    super.key,
    required this.audioService,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppTheme.safeHorizontalPadding,
      child: Column(
        children: [
          // Progress slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4.0,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 8.0,
              ),
              overlayShape: const RoundSliderOverlayShape(
                overlayRadius: 16.0,
              ),
            ),
            child: Slider(
              value: audioService.progress,
              onChanged: (value) {
                final position = Duration(
                  milliseconds:
                      (value * audioService.totalDuration.inMilliseconds)
                          .round(),
                );
                onSeek(position);
              },
              activeColor: AppTheme.primaryColor,
              inactiveColor: AppTheme.cardColor,
            ),
          ),

          // Time labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                audioService.formattedCurrentPosition,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.onSurfaceColor.withValues(alpha: 0.7),
                ),
              ),
              Text(
                audioService.formattedTotalDuration,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.onSurfaceColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
