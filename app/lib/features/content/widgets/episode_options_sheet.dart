import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:from_fed_to_chain_app/core/theme/app_theme.dart';
import 'package:from_fed_to_chain_app/features/audio/services/audio_player_service.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';
import 'package:from_fed_to_chain_app/features/content/services/content_service.dart';

class EpisodeOptionsSheet extends StatelessWidget {
  final AudioFile episode;

  const EpisodeOptionsSheet({
    super.key,
    required this.episode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppTheme.safePadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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

          // Episode info
          Text(
            episode.displayTitle,
            style: AppTheme.titleLarge,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: AppTheme.spacingS),

          Text(
            '${episode.categoryEmoji} ${episode.category} • ${episode.languageFlag} ${episode.language}',
            style: AppTheme.bodySmall,
          ),

          const SizedBox(height: AppTheme.spacingL),

          // Actions
          ListTile(
            leading: const Icon(Icons.play_arrow),
            title: const Text('Play'),
            onTap: () {
              Navigator.pop(context);
              _playEpisode(context, episode);
            },
          ),

          ListTile(
            leading: const Icon(Icons.favorite_border),
            title: const Text('Add to Favorites'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement favorites
            },
          ),

          ListTile(
            leading: const Icon(Icons.playlist_add),
            title: const Text('Add to Playlist'),
            onTap: () {
              Navigator.pop(context);
              context.read<ContentService>().addToCurrentPlaylist(episode);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Added "${episode.displayTitle}" to playlist'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement sharing
            },
          ),

          const SizedBox(height: AppTheme.spacingM),
        ],
      ),
    );
  }

  Future<void> _playEpisode(BuildContext context, AudioFile episode) async {
    try {
      await context.read<AudioPlayerService>().playAudio(episode);
    } catch (e) {
      if (!context.mounted) return;

      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot play audio: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }
}
