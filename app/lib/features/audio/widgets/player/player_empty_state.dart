import 'package:flutter/material.dart';
import 'package:from_fed_to_chain_app/core/theme/app_theme.dart';

class PlayerEmptyState extends StatelessWidget {
  const PlayerEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_off,
            size: 80,
            color: AppTheme.onSurfaceColor.withValues(alpha: 0.3),
          ),
          const SizedBox(height: AppTheme.spacingL),
          const Text(
            'No audio playing',
            style: AppTheme.headlineMedium,
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            'Select an episode to start listening',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.onSurfaceColor.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: AppTheme.spacingXL),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Browse Episodes'),
          ),
        ],
      ),
    );
  }
}
