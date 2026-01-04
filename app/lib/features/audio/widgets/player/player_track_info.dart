import 'package:flutter/material.dart';
import 'package:from_fed_to_chain_app/core/theme/app_theme.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';

class PlayerTrackInfo extends StatelessWidget {
  final AudioFile currentAudio;

  const PlayerTrackInfo({
    super.key,
    required this.currentAudio,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppTheme.safeHorizontalPadding,
      child: Column(
        children: [
          // Track title
          Text(
            currentAudio.displayTitle,
            style: AppTheme.headlineMedium,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: AppTheme.spacingS),

          // Track details
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                currentAudio.categoryEmoji,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Text(
                AppTheme.getCategoryDisplayName(currentAudio.category),
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.getCategoryColor(currentAudio.category),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Text(
                currentAudio.languageFlag,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Text(
                AppTheme.getLanguageDisplayName(currentAudio.language),
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.getLanguageColor(currentAudio.language),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
