import 'package:flutter/material.dart';

import 'package:from_fed_to_chain_app/core/theme/app_theme.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';
import 'package:from_fed_to_chain_app/core/config/api_config.dart';
import 'package:from_fed_to_chain_app/core/utils/date_formatter.dart';

/// A card widget that displays information about a single [AudioFile].
///
/// Shows artwork, title, metadata (category, language, date, duration),
/// and an optional play button. Handles tap and long-press interactions.
class AudioItemCard extends StatelessWidget {
  /// The audio file data to display.
  final AudioFile audioFile;

  /// Callback when the card is tapped.
  final VoidCallback onTap;

  /// Callback when the card is long-pressed.
  final VoidCallback? onLongPress;

  /// Whether to show the play/pause button on the right side.
  /// Defaults to true.
  final bool showPlayButton;

  /// Whether this episode is currently playing.
  /// Affects styling (e.g., adds a border or highlight).
  final bool isCurrentlyPlaying;

  /// Creates an [AudioItemCard].
  const AudioItemCard({
    super.key,
    required this.audioFile,
    required this.onTap,
    this.onLongPress,
    this.showPlayButton = true,
    this.isCurrentlyPlaying = false,
  });

  // Add unique keys for testing
  static const Key cardKey = Key('audio_item_card_inkwell');
  static const Key playButtonKey = Key('audio_item_card_play_button');

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppTheme.elevationS,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: cardKey,
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: isCurrentlyPlaying
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  )
                : null,
            child: Row(
              children: [
                // Episode artwork/icon
                _buildEpisodeArtwork(),

                const SizedBox(width: AppTheme.spacingM),

                // Episode information
                Expanded(
                  child: _buildEpisodeInfo(),
                ),

                // Play button or duration
                if (showPlayButton)
                  _buildActionButton()
                else
                  _buildDurationInfo(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build episode artwork or category icon
  Widget _buildEpisodeArtwork() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.getCategoryColor(audioFile.category),
            AppTheme.getCategoryColor(audioFile.category)
                .withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getCategoryColor(audioFile.category)
                .withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        AppTheme.getCategoryIcon(audioFile.category),
        color: Colors.white,
        size: 28,
      ),
    );
  }

  /// Build episode information section
  Widget _buildEpisodeInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Episode title
        Text(
          audioFile.displayTitle,
          style: AppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: AppTheme.spacingXS),

        // Category and language info - wrapped to prevent overflow
        Wrap(
          spacing: AppTheme.spacingS,
          runSpacing: AppTheme.spacingXS,
          children: [
            // Category chip
            _buildInfoChip(
              text:
                  '${audioFile.categoryEmoji} ${ApiConfig.getCategoryDisplayName(audioFile.category)}',
              color: AppTheme.getCategoryColor(audioFile.category),
            ),

            // Language chip
            _buildInfoChip(
              text:
                  '${audioFile.languageFlag} ${ApiConfig.getLanguageDisplayName(audioFile.language)}',
              color: AppTheme.getLanguageColor(audioFile.language),
            ),
          ],
        ),

        const SizedBox(height: AppTheme.spacingXS),

        // Additional metadata - scrollable to prevent overflow
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Date
              Text(
                DateFormatter.formatFriendlyDate(audioFile.publishDate),
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.onSurfaceColor.withValues(alpha: 0.6),
                ),
              ),

              if (audioFile.duration != null) ...[
                Text(
                  ' • ',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.onSurfaceColor.withValues(alpha: 0.4),
                  ),
                ),
                Text(
                  audioFile.formattedDuration,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.onSurfaceColor.withValues(alpha: 0.6),
                  ),
                ),
              ],

              if (audioFile.fileSizeBytes != null) ...[
                Text(
                  ' • ',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.onSurfaceColor.withValues(alpha: 0.4),
                  ),
                ),
                Text(
                  audioFile.formattedFileSize,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.onSurfaceColor.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Currently playing indicator
        if (isCurrentlyPlaying) ...[
          const SizedBox(height: AppTheme.spacingXS),
          Row(
            children: [
              const Icon(
                Icons.graphic_eq,
                size: 16,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: AppTheme.spacingXS),
              Text(
                'Now Playing',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Build info chip for category/language
  Widget _buildInfoChip({
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingS,
        vertical: AppTheme.spacingXS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: AppTheme.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
      ),
    );
  }

  /// Build action button (play/options)
  Widget _buildActionButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: playButtonKey,
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        child: Semantics(
          label: isCurrentlyPlaying ? 'Pause' : 'Play',
          button: true,
          child: Container(
            width: 48, // Minimum accessibility tap target size
            height: 48, // Minimum accessibility tap target size
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: Icon(
                isCurrentlyPlaying ? Icons.pause : Icons.play_arrow,
                color: AppTheme.primaryColor,
                size: 22, // Slightly larger icon for better proportion
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build duration information
  Widget _buildDurationInfo() {
    if (audioFile.duration == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          audioFile.formattedDuration,
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.onSurfaceColor.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        if (audioFile.isHlsStream) ...[
          const SizedBox(height: AppTheme.spacingXS),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingS,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
            ),
            child: Text(
              'HLS',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.successColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
