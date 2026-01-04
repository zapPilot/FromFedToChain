import 'package:flutter/material.dart';
import 'package:from_fed_to_chain_app/core/theme/app_theme.dart';
import 'package:from_fed_to_chain_app/features/audio/services/audio_player_service.dart';
import 'package:from_fed_to_chain_app/features/audio/widgets/audio_controls.dart';

class PlayerMainControls extends StatelessWidget {
  final AudioPlayerService audioService;

  const PlayerMainControls({
    super.key,
    required this.audioService,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppTheme.safeHorizontalPadding,
      child: AudioControls(
        isPlaying: audioService.isPlaying,
        isLoading: audioService.isLoading,
        hasError: audioService.hasError,
        onPlayPause: () => audioService.togglePlayPause(),
        onNext: () => audioService.skipToNextEpisode(),
        onPrevious: () => audioService.skipToPreviousEpisode(),
        onSkipForward: () => audioService.skipForward(),
        onSkipBackward: () => audioService.skipBackward(),
        size: AudioControlsSize.large,
      ),
    );
  }
}
