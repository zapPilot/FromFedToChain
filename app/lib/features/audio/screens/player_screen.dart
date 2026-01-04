import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:from_fed_to_chain_app/core/theme/app_theme.dart';
import 'package:from_fed_to_chain_app/features/audio/services/audio_player_service.dart';
import 'package:from_fed_to_chain_app/features/content/services/content_service.dart';
import 'package:from_fed_to_chain_app/features/content/services/playlist_service.dart';
import 'package:from_fed_to_chain_app/core/navigation/deep_link_service.dart';

import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';
import 'package:from_fed_to_chain_app/features/audio/widgets/player/player_artwork.dart';
import 'package:from_fed_to_chain_app/features/audio/widgets/player/player_header.dart';
import 'package:from_fed_to_chain_app/features/audio/widgets/player/player_track_info.dart';
import 'package:from_fed_to_chain_app/features/audio/widgets/player/player_progress_bar.dart';
import 'package:from_fed_to_chain_app/features/audio/widgets/player/player_main_controls.dart';
import 'package:from_fed_to_chain_app/features/audio/widgets/player/player_additional_controls.dart';
import 'package:from_fed_to_chain_app/features/audio/widgets/player/player_empty_state.dart';
import 'package:from_fed_to_chain_app/features/content/widgets/content_display.dart';

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
                ? _buildExpandedLayout(
                    context, currentAudio, audioService, contentService)
                : _buildCompactLayout(
                    context, currentAudio, audioService, contentService),
          );
        },
      ),
    );
  }

  /// Build compact layout (without content script)
  Widget _buildCompactLayout(BuildContext context, AudioFile currentAudio,
      AudioPlayerService audioService, ContentService contentService) {
    return Column(
      children: [
        // Header with back button and options
        PlayerHeader(
          currentAudio: currentAudio,
          onOptionsPressed: () => _showPlayerOptions(context, currentAudio),
        ),

        // Album art and visualizer
        Expanded(
          flex: 3,
          child: PlayerArtwork(
            audioFile: currentAudio,
            isPlaying: audioService.isPlaying,
            playbackState: audioService.playbackState,
          ),
        ),

        // Track info
        PlayerTrackInfo(currentAudio: currentAudio),

        // Content script display (collapsed)
        ContentDisplay(
          currentAudioFile: currentAudio,
          contentService: contentService,
          isExpanded: _showContentScript,
          onToggleExpanded: () {
            setState(() {
              _showContentScript = !_showContentScript;
            });
          },
        ),

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
          showContentScript: _showContentScript,
          onToggleContentScript: (value) {
            setState(() {
              _showContentScript = value;
            });
          },
          onShare: () =>
              _shareCurrentContent(context, audioService, contentService),
          onAddToPlaylist: () {
            final currentAudio = audioService.currentAudioFile;
            if (currentAudio != null) {
              context.read<PlaylistService>().addToPlaylist(currentAudio);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('Added "${currentAudio.displayTitle}" to playlist'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
        ),

        const SizedBox(height: AppTheme.spacingL),
      ],
    );
  }

  /// Build expanded layout (with content script)
  Widget _buildExpandedLayout(BuildContext context, AudioFile currentAudio,
      AudioPlayerService audioService, ContentService contentService) {
    return CustomScrollView(
      slivers: [
        // Fixed header
        SliverToBoxAdapter(
          child: PlayerHeader(
            currentAudio: currentAudio,
            onOptionsPressed: () => _showPlayerOptions(context, currentAudio),
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
            isExpanded: _showContentScript,
            onToggleExpanded: () {
              setState(() {
                _showContentScript = !_showContentScript;
              });
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
                showContentScript: _showContentScript,
                onToggleContentScript: (value) {
                  setState(() {
                    _showContentScript = value;
                  });
                },
                onShare: () =>
                    _shareCurrentContent(context, audioService, contentService),
                onAddToPlaylist: () {
                  final currentAudio = audioService.currentAudioFile;
                  if (currentAudio != null) {
                    context.read<PlaylistService>().addToPlaylist(currentAudio);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Added "${currentAudio.displayTitle}" to playlist'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),

              const SizedBox(height: AppTheme.spacingL),
            ],
          ),
        ),
      ],
    );
  }

  /// Share current content using social hook and deep linking
  Future<void> _shareCurrentContent(BuildContext context,
      AudioPlayerService audioService, ContentService contentService) async {
    final currentAudio = audioService.currentAudioFile;
    if (currentAudio == null) return;

    try {
      // Get content to access social_hook
      final content = await contentService.getContentForAudioFile(currentAudio);

      // Generate deep links with language parameter
      final deepLink = DeepLinkService.generateContentLink(currentAudio.id,
          language: currentAudio.language);
      final webLink = DeepLinkService.generateContentLink(currentAudio.id,
          language: currentAudio.language, useCustomScheme: false);

      String shareText;
      if (content?.socialHook != null &&
          content!.socialHook!.trim().isNotEmpty) {
        // Use social hook from content and append deep links
        shareText = '${content.socialHook!}\n\n'
            '🎧 Listen now: $deepLink';
      } else {
        // Fallback to default sharing message with links
        shareText =
            '🎧 Listening to "${currentAudio.displayTitle}" from From Fed to Chain\n\n'
            '${currentAudio.categoryEmoji} ${AppTheme.getCategoryDisplayName(currentAudio.category)} | '
            '${currentAudio.languageFlag} ${AppTheme.getLanguageDisplayName(currentAudio.language)}\n\n'
            '🎧 Listen: $deepLink\n'
            '🌐 Web: $webLink\n\n'
            '#FromFedToChain #Crypto #Podcast';
      }

      // Use share_plus to share directly with system share sheet
      final result = await Share.shareWithResult(
        shareText,
        subject: 'From Fed to Chain - ${currentAudio.displayTitle}',
      );

      // Show feedback based on share result
      if (context.mounted) {
        if (result.status == ShareResultStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Episode shared successfully! 🚀'),
              duration: Duration(seconds: 2),
            ),
          );
        } else if (result.status == ShareResultStatus.dismissed) {
          // User dismissed - no feedback needed
        } else {
          // Fallback: show text in dialog for manual copy
          await _showShareDialog(context, shareText);
        }
      }
    } catch (e) {
      // Show error if content loading fails or sharing fails
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share episode: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Show share dialog as fallback when system share fails
  Future<void> _showShareDialog(BuildContext context, String shareText) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.share),
            SizedBox(width: 8),
            Text('Share Episode'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Copy this text to share:'),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                shareText,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () async {
              // Copy to clipboard using share_plus
              await Share.share(shareText);
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Share text ready!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            icon: const Icon(Icons.share),
            label: const Text('Share'),
          ),
        ],
      ),
    );
  }

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
      builder: (context) => _buildPlayerOptionsSheet(currentAudio),
    );
  }

  /// Build player options bottom sheet
  Widget _buildPlayerOptionsSheet(AudioFile currentAudio) {
    return Padding(
      padding: AppTheme.safePadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.onSurfaceColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const SizedBox(height: AppTheme.spacingL),

          // Audio details
          const Text(
            'Audio Details',
            style: AppTheme.headlineSmall,
          ),

          const SizedBox(height: AppTheme.spacingM),

          Text(
            currentAudio.displayTitle,
            style: AppTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppTheme.spacingM),
        ],
      ),
    );
  }
}
