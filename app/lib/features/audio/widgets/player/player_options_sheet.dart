import 'package:flutter/material.dart';
import 'package:from_fed_to_chain_app/core/theme/app_theme.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';

class PlayerOptionsSheet extends StatelessWidget {
  final AudioFile currentAudio;

  const PlayerOptionsSheet({
    super.key,
    required this.currentAudio,
  });

  @override
  Widget build(BuildContext context) {
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
