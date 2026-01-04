import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:from_fed_to_chain_app/features/audio/services/audio_player_service.dart';
import 'package:from_fed_to_chain_app/features/audio/services/player_state_notifier.dart';
import 'package:from_fed_to_chain_app/features/audio/screens/player_screen.dart';
import 'package:from_fed_to_chain_app/features/audio/widgets/mini_player.dart';

class HomeMiniPlayer extends StatelessWidget {
  const HomeMiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<AudioPlayerService, AppPlaybackState>(
      selector: (context, service) => service.playbackState,
      builder: (context, playbackState, child) {
        final audioService = context.read<AudioPlayerService>();

        // Safety check - if we're here, currentAudioFile shouldn't be null
        // due to parent Selector, but good to be safe
        if (audioService.currentAudioFile == null) {
          return const SizedBox.shrink();
        }

        return MiniPlayer(
          audioFile: audioService.currentAudioFile!,
          isPlaying: audioService.isPlaying,
          isPaused: audioService.isPaused,
          isLoading: audioService.isLoading,
          hasError: audioService.hasError,
          stateText: _getStateText(audioService),
          onTap: () => _navigateToPlayer(context),
          onPlayPause: () => audioService.togglePlayPause(),
          onNext: () => audioService.skipToNextEpisode(),
          onPrevious: () => audioService.skipToPreviousEpisode(),
        );
      },
    );
  }

  /// Helper method to get state text from AudioPlayerService
  String _getStateText(AudioPlayerService audioService) {
    if (audioService.hasError) {
      return 'Error';
    } else if (audioService.isLoading) {
      return 'Loading';
    } else if (audioService.isPlaying) {
      return 'Playing';
    } else if (audioService.isPaused) {
      return 'Paused';
    } else {
      return 'Stopped';
    }
  }

  /// Navigate to full player screen
  void _navigateToPlayer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PlayerScreen(),
      ),
    );
  }
}
