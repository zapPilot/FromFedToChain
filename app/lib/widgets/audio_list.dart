import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../themes/app_theme.dart';
import '../models/audio_file.dart';
import 'audio_item_card.dart';

/// List widget for displaying audio episodes with animations
class AudioList extends StatelessWidget {
  final List<AudioFile> episodes;
  final Function(AudioFile) onEpisodeTap;
  final Function(AudioFile)? onEpisodeLongPress;
  final ScrollController? scrollController;
  final bool showLoadingMore;
  final VoidCallback? onLoadMore;

  const AudioList({
    super.key,
    required this.episodes,
    required this.onEpisodeTap,
    this.onEpisodeLongPress,
    this.scrollController,
    this.showLoadingMore = false,
    this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    if (episodes.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      itemCount: episodes.length + (showLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Loading more indicator
        if (showLoadingMore && index == episodes.length) {
          return _buildLoadingMoreIndicator();
        }

        final episode = episodes[index];

        return AnimationConfiguration.staggeredList(
          position: index,
          duration: AppTheme.animationMedium,
          child: SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
                child: AudioItemCard(
                  audioFile: episode,
                  onTap: () => onEpisodeTap(episode),
                  onLongPress: onEpisodeLongPress != null
                      ? () => onEpisodeLongPress!(episode)
                      : null,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build empty state widget
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.headphones_outlined,
            size: 80,
            color: AppTheme.onSurfaceColor.withOpacity(0.3),
          ),
          const SizedBox(height: AppTheme.spacingL),
          Text(
            'No episodes found',
            style: AppTheme.headlineMedium.copyWith(
              color: AppTheme.onSurfaceColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'Try different filters or search terms',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.onSurfaceColor.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build loading more indicator
  Widget _buildLoadingMoreIndicator() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Center(
        child: Column(
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              'Loading more episodes...',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.onSurfaceColor.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
