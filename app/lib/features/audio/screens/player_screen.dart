import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:from_fed_to_chain_app/core/theme/app_theme.dart';
import 'package:from_fed_to_chain_app/features/audio/services/audio_player_service.dart';
import 'package:from_fed_to_chain_app/features/content/services/content_service.dart';

import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';
import 'package:from_fed_to_chain_app/features/audio/widgets/player/player_empty_state.dart';
import 'package:from_fed_to_chain_app/features/audio/widgets/player/compact_player_layout.dart';
import 'package:from_fed_to_chain_app/features/audio/widgets/player/expanded_player_layout.dart';
import 'package:from_fed_to_chain_app/features/audio/widgets/player/player_options_sheet.dart';

/// Full-screen audio player with enhanced controls
class PlayerScreen extends StatefulWidget {
  final String? contentId;

  const PlayerScreen({super.key, this.contentId});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  bool _showContentScript = false;

  @override
  void initState() {
    super.initState();

    // Auto-load and play content if contentId is provided (for deep linking)
    if (widget.contentId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadAndPlayContent(widget.contentId!);
      });
    }
  }

  /// Load and automatically play content by ID (for deep linking)
  Future<void> _loadAndPlayContent(String contentId) async {
    try {
      final contentService = context.read<ContentService>();
      final audioService = context.read<AudioPlayerService>();

      // Get the AudioFile by contentId
      final audioFile = await contentService.getAudioFileById(contentId);

      if (audioFile != null) {
        // Add to listen history
        await contentService.addToListenHistory(audioFile);

        // Start playing the audio
        await audioService.playAudio(audioFile);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Now playing: ${audioFile.displayTitle}'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Episode not found: $contentId'),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load episode: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Consumer2<AudioPlayerService, ContentService>(
        builder: (context, audioService, contentService, child) {
          final currentAudio = audioService.currentAudioFile;

          if (currentAudio == null) {
            return const PlayerEmptyState();
          }

          return SafeArea(
            child: _showContentScript
                ? ExpandedPlayerLayout(
                    currentAudio: currentAudio,
                    audioService: audioService,
                    contentService: contentService,
                    showContentScript: _showContentScript,
                    onToggleContentScript: (value) {
                      setState(() {
                        _showContentScript = value;
                      });
                    },
                    onOptionsPressed: () =>
                        _showPlayerOptions(context, currentAudio),
                  )
                : CompactPlayerLayout(
                    currentAudio: currentAudio,
                    audioService: audioService,
                    contentService: contentService,
                    showContentScript: _showContentScript,
                    onToggleContentScript: (value) {
                      setState(() {
                        _showContentScript = value;
                      });
                    },
                    onOptionsPressed: () =>
                        _showPlayerOptions(context, currentAudio),
                  ),
          );
        },
      ),
    );
  }

  /// Build compact layout (without content script)
  /// Show player options bottom sheet
  void _showPlayerOptions(BuildContext context, AudioFile currentAudio) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusL),
        ),
      ),
      builder: (context) => PlayerOptionsSheet(currentAudio: currentAudio),
    );
  }
}
