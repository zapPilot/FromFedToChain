import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:from_fed_to_chain_app/core/theme/app_theme.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';
import 'package:from_fed_to_chain_app/features/audio/services/audio_player_service.dart';
import 'package:from_fed_to_chain_app/features/content/services/content_service.dart';
import 'package:from_fed_to_chain_app/features/content/services/playlist_service.dart';
import 'package:from_fed_to_chain_app/features/audio/widgets/player/player_header.dart';
import 'package:from_fed_to_chain_app/features/audio/widgets/player/player_artwork.dart';
import 'package:from_fed_to_chain_app/features/audio/widgets/player/player_track_info.dart';
import 'package:from_fed_to_chain_app/features/content/widgets/content_display.dart';
import 'package:from_fed_to_chain_app/features/audio/widgets/player/player_progress_bar.dart';
import 'package:from_fed_to_chain_app/features/audio/widgets/player/player_main_controls.dart';
import 'package:from_fed_to_chain_app/features/audio/widgets/player/player_additional_controls.dart';
import 'package:from_fed_to_chain_app/features/audio/services/share_helper.dart';

class ExpandedPlayerLayout extends StatelessWidget {
  final AudioFile currentAudio;
  final AudioPlayerService audioService;
  final ContentService contentService;
  final bool showContentScript;
  final ValueChanged<bool> onToggleContentScript;
  final VoidCallback onOptionsPressed;

  const ExpandedPlayerLayout({
    super.key,
    required this.currentAudio,
    required this.audioService,
    required this.contentService,
    required this.showContentScript,
    required this.onToggleContentScript,
    required this.onOptionsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Fixed header
        SliverToBoxAdapter(
          child: PlayerHeader(
            currentAudio: currentAudio,
            onOptionsPressed: onOptionsPressed,
          ),
        ),

        // Compact album art
        SliverToBoxAdapter(
          child: SizedBox(
            height: 200,
            child: PlayerArtwork(
              audioFile: currentAudio,
              isPlaying: audioService.isPlaying,
              playbackState: audioService.playbackState,
            ),
          ),
        ),

        // Track info
        SliverToBoxAdapter(
          child: PlayerTrackInfo(currentAudio: currentAudio),
        ),

        // Content script display (expanded)
        SliverToBoxAdapter(
          child: ContentDisplay(
            currentAudioFile: currentAudio,
            contentService: contentService,
            isExpanded: showContentScript,
            onToggleExpanded: () {
              onToggleContentScript(!showContentScript);
            },
          ),
        ),

        // Bottom controls (sticky)
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Progress bar
              PlayerProgressBar(
                audioService: audioService,
                onSeek: (position) => audioService.seekTo(position),
              ),

              // Main controls
              PlayerMainControls(audioService: audioService),

              // Additional controls
              PlayerAdditionalControls(
                audioService: audioService,
                showContentScript: showContentScript,
                onToggleContentScript: onToggleContentScript,
                onShare: () => ShareHelper.shareCurrentContent(
                    context, audioService, contentService),
                onAddToPlaylist: () => _addToPlaylist(context),
              ),

              const SizedBox(height: AppTheme.spacingL),
            ],
          ),
        ),
      ],
    );
  }

  void _addToPlaylist(BuildContext context) {
    if (audioService.currentAudioFile != null) {
      context
          .read<PlaylistService>()
          .addToPlaylist(audioService.currentAudioFile!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Added "${audioService.currentAudioFile!.displayTitle}" to playlist'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
