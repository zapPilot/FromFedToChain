import 'package:flutter/material.dart';
import 'package:from_fed_to_chain_app/core/theme/app_theme.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';

class PlayerHeader extends StatelessWidget {
  final AudioFile currentAudio;
  final VoidCallback onOptionsPressed;

  const PlayerHeader({
    super.key,
    required this.currentAudio,
    required this.onOptionsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppTheme.safeHorizontalPadding,
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.keyboard_arrow_down),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.cardColor.withValues(alpha: 0.5),
              foregroundColor: AppTheme.onSurfaceColor,
            ),
          ),

          // Track source info
          Expanded(
            child: Column(
              children: [
                Text(
                  'NOW PLAYING',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.onSurfaceColor.withValues(alpha: 0.6),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Text(
                  'From Fed to Chain',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // More options button
          IconButton(
            onPressed: onOptionsPressed,
            icon: const Icon(Icons.more_vert),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.cardColor.withValues(alpha: 0.5),
              foregroundColor: AppTheme.onSurfaceColor,
            ),
          ),
        ],
      ),
    );
  }
}
