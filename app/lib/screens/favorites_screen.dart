import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/audio_service.dart' as local_audio;
import '../widgets/audio_list.dart';
import '../themes/app_theme.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<AuthService>(
        builder: (context, authService, child) {
          if (authService.favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: AppTheme.onSurfaceColor.withOpacity(0.3),
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  Text(
                    'No Favorites Yet',
                    style: AppTheme.headlineSmall.copyWith(
                      color: AppTheme.onSurfaceColor.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    'Tap the heart on an episode to add it to your favorites.',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.onSurfaceColor.withOpacity(0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return AudioList(
            episodes: authService.favorites,
            onEpisodeTap: (episode) {
              context.read<local_audio.AudioService>().playAudio(episode);
            },
            onEpisodeLongPress: (episode) {
              // Optional: show options to remove from favorites
            },
          );
        },
      ),
    );
  }
}
