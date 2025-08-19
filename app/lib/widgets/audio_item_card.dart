import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../themes/app_theme.dart';
import '../models/audio_file.dart';
import '../config/api_config.dart';

/// Card widget for displaying individual audio episode information
class AudioItemCard extends StatelessWidget {
  final AudioFile audioFile;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool showPlayButton;
  final bool isCurrentlyPlaying;

  const AudioItemCard({
    super.key,
    required this.audioFile,
    required this.onTap,
    this.onLongPress,
    this.showPlayButton = true,
    this.isCurrentlyPlaying = false,
  });

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
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: isCurrentlyPlaying
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.5),
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
            AppTheme.getCategoryColor(audioFile.category).withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.getCategoryColor(audioFile.category).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        _getCategoryIcon(audioFile.category),
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
                _formatDate(audioFile.publishDate),
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.onSurfaceColor.withOpacity(0.6),
                ),
              ),

              if (audioFile.duration != null) ...[
                Text(
                  ' • ',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.onSurfaceColor.withOpacity(0.4),
                  ),
                ),
                Text(
                  audioFile.formattedDuration,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.onSurfaceColor.withOpacity(0.6),
                  ),
                ),
              ],

              if (audioFile.fileSizeBytes != null) ...[
                Text(
                  ' • ',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.onSurfaceColor.withOpacity(0.4),
                  ),
                ),
                Text(
                  audioFile.formattedFileSize,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.onSurfaceColor.withOpacity(0.6),
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
              Icon(
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
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        border: Border.all(
          color: color.withOpacity(0.3),
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
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(
          isCurrentlyPlaying ? Icons.pause : Icons.play_arrow,
          color: AppTheme.primaryColor,
          size: 20,
        ),
        padding: EdgeInsets.zero,
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
            color: AppTheme.onSurfaceColor.withOpacity(0.7),
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
              color: AppTheme.successColor.withOpacity(0.15),
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

  /// Get category icon
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'daily-news':
        return Icons.newspaper;
      case 'ethereum':
        return Icons.currency_bitcoin;
      case 'macro':
        return Icons.trending_up;
      case 'startup':
        return Icons.rocket_launch;
      case 'ai':
        return Icons.smart_toy;
      case 'defi':
        return Icons.account_balance;
      default:
        return Icons.headphones;
    }
  }

  /// Format date for display with localization
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else {
      // Use localized date format for older dates (without time)
      return DateFormat.yMMMd().format(date);
    }
  }
}
