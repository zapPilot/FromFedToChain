import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../themes/app_theme.dart';
import '../services/content_service.dart';
import '../services/audio_service.dart';
import '../models/audio_file.dart';
import '../widgets/audio_list.dart';
import '../widgets/mini_player.dart';
import 'player_screen.dart';

/// History screen displaying recently listened episodes
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<ContentService, AudioService>(
        builder: (context, contentService, audioService, child) {
          return SafeArea(
            child: Column(
              children: [
                // App header
                _buildAppHeader(context, contentService),

                // Main content area
                Expanded(
                  child: _buildHistoryContent(contentService, audioService),
                ),

                // Mini player (if audio is playing)
                if (audioService.currentAudioFile != null)
                  _buildMiniPlayer(context, audioService),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Build app header with title
  Widget _buildAppHeader(BuildContext context, ContentService contentService) {
    return Container(
      padding: AppTheme.safeHorizontalPadding,
      child: Row(
        children: [
          // App title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Listening History',
                  style: AppTheme.headlineMedium,
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Consumer<ContentService>(
                  builder: (context, service, child) {
                    final historyEpisodes = service.getListenHistoryEpisodes();
                    final count = historyEpisodes.length;

                    return Text(
                      count == 0
                          ? 'No episodes listened to yet'
                          : count == 1
                              ? '1 episode in history'
                              : '$count episodes in history',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.onSurfaceColor.withOpacity(0.6),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Clear history button
          Consumer<ContentService>(
            builder: (context, service, child) {
              final historyEpisodes = service.getListenHistoryEpisodes();
              if (historyEpisodes.isEmpty) return const SizedBox.shrink();

              return IconButton(
                onPressed: () => _showClearHistoryDialog(context, service),
                icon: const Icon(Icons.clear_all),
                tooltip: 'Clear History',
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.cardColor.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                ),
              );
            },
          ),

          const SizedBox(width: AppTheme.spacingS),

          // Refresh button
          IconButton(
            onPressed: contentService.isLoading
                ? null
                : () => contentService.refresh(),
            icon: contentService.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryColor,
                      ),
                    ),
                  )
                : const Icon(Icons.refresh),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.cardColor.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build history content
  Widget _buildHistoryContent(
      ContentService contentService, AudioService audioService) {
    if (contentService.isLoading && !contentService.hasEpisodes) {
      return _buildLoadingState();
    }

    final historyEpisodes = contentService.getListenHistoryEpisodes();

    if (historyEpisodes.isEmpty) {
      return _buildEmptyHistoryState();
    }

    return AnimationLimiter(
      child: AudioList(
        episodes: historyEpisodes,
        onEpisodeTap: (episode) => _playEpisode(episode, audioService),
        onEpisodeLongPress: (episode) => _showEpisodeOptions(episode),
        scrollController: _scrollController,
      ),
    );
  }

  /// Build loading state
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
          const SizedBox(height: AppTheme.spacingL),
          const Text(
            'Loading history...',
            style: AppTheme.titleMedium,
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'This may take a few moments',
            style: AppTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  /// Build empty history state
  Widget _buildEmptyHistoryState() {
    return Center(
      child: Padding(
        padding: AppTheme.safePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 80,
              color: AppTheme.onSurfaceColor.withOpacity(0.3),
            ),
            const SizedBox(height: AppTheme.spacingL),
            Text(
              'No Listening History',
              style: AppTheme.headlineSmall.copyWith(
                color: AppTheme.onSurfaceColor.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'Episodes you listen to will appear here',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.onSurfaceColor.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXL),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.home),
              label: const Text('Browse Episodes'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build mini player
  Widget _buildMiniPlayer(BuildContext context, AudioService audioService) {
    return MiniPlayer(
      audioFile: audioService.currentAudioFile!,
      playbackState: audioService.playbackState,
      onTap: () => _navigateToPlayer(context),
      onPlayPause: () => audioService.togglePlayPause(),
      onNext: () => audioService.skipToNextEpisode(),
      onPrevious: () => audioService.skipToPreviousEpisode(),
    );
  }

  /// Play episode
  void _playEpisode(AudioFile episode, AudioService audioService) {
    audioService.playAudio(episode);
  }

  /// Show episode options
  void _showEpisodeOptions(AudioFile episode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusL),
        ),
      ),
      builder: (context) => _buildEpisodeOptionsSheet(episode),
    );
  }

  /// Build episode options bottom sheet
  Widget _buildEpisodeOptionsSheet(AudioFile episode) {
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
                color: AppTheme.onSurfaceColor.withOpacity(0.3),
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
              _playEpisode(episode, context.read<AudioService>());
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
            leading: const Icon(Icons.remove_from_queue),
            title: const Text('Remove from History'),
            onTap: () {
              Navigator.pop(context);
              _removeFromHistory(context, episode);
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

  /// Remove episode from history
  void _removeFromHistory(BuildContext context, AudioFile episode) {
    context.read<ContentService>().removeFromListenHistory(episode.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed "${episode.displayTitle}" from history'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // TODO: Implement undo functionality
          },
        ),
      ),
    );
  }

  /// Show clear history confirmation dialog
  void _showClearHistoryDialog(
      BuildContext context, ContentService contentService) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          title: const Text('Clear Listening History'),
          content: const Text(
            'Are you sure you want to clear your entire listening history? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                contentService.clearListenHistory();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Listening history cleared'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
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
