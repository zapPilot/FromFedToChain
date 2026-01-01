import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/audio_content.dart';
import '../providers/audio_provider.dart';
import '../config/app_config.dart';

/// Simplified mini player widget shown at bottom of home screen
/// Displays currently playing audio with playback controls
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, _) {
        final currentContent = audioProvider.currentContent;

        // Don't show mini player if nothing is playing
        if (currentContent == null) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // TODO: Navigate to full-screen player
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Full-screen player coming soon'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Album art / Icon
                    _buildAlbumArt(currentContent),
                    const SizedBox(width: 12),

                    // Track info
                    Expanded(
                      child: _buildTrackInfo(context, currentContent),
                    ),

                    // Controls
                    _buildControls(context, audioProvider),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build album art or category icon
  Widget _buildAlbumArt(AudioContent content) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _getCategoryColor(content.category),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          AppConfig.getCategoryEmoji(content.category),
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }

  /// Build track information section
  Widget _buildTrackInfo(BuildContext context, AudioContent content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Track title
        Text(
          content.title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),

        // Track details
        Text(
          '${AppConfig.getLanguageFlag(content.language)} ${content.language} · ${AppConfig.getCategoryName(content.category)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// Build control buttons
  Widget _buildControls(BuildContext context, AudioProvider audioProvider) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Previous button
        IconButton(
          icon: const Icon(Icons.skip_previous),
          onPressed: audioProvider.hasPrevious
              ? () => audioProvider.previous()
              : null,
          tooltip: 'Previous track',
          iconSize: 24,
        ),

        // Play/Pause button
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              audioProvider.isPlaying ? Icons.pause : Icons.play_arrow,
            ),
            onPressed: () => audioProvider.togglePlayPause(),
            tooltip: audioProvider.isPlaying ? 'Pause' : 'Play',
            color: Theme.of(context).colorScheme.onPrimary,
            iconSize: 28,
          ),
        ),

        // Next button
        IconButton(
          icon: const Icon(Icons.skip_next),
          onPressed: audioProvider.hasNext ? () => audioProvider.next() : null,
          tooltip: 'Next track',
          iconSize: 24,
        ),
      ],
    );
  }

  /// Get category color
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'daily-news':
        return Colors.blue.shade700;
      case 'ethereum':
        return Colors.purple.shade700;
      case 'macro':
        return Colors.green.shade700;
      case 'startup':
        return Colors.orange.shade700;
      case 'ai':
        return Colors.cyan.shade700;
      case 'defi':
        return Colors.pink.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
}
