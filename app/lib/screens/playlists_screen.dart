import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/audio_service.dart' as local_audio;
import '../widgets/audio_list.dart';
import '../themes/app_theme.dart';

class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Playlist'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<AuthService>(
        builder: (context, authService, child) {
          if (authService.myPlaylist.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.playlist_play,
                    size: 80,
                    color: AppTheme.onSurfaceColor.withOpacity(0.3),
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  Text(
                    'Your Playlist is Empty',
                    style: AppTheme.headlineSmall.copyWith(
                      color: AppTheme.onSurfaceColor.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    'Add episodes to your playlist to see them here.',
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
            episodes: authService.myPlaylist,
            onEpisodeTap: (episode) {
              context.read<local_audio.AudioService>().playAudio(episode);
            },
            onEpisodeLongPress: (episode) {
              // Optional: show options to remove from playlist
            },
          );
        },
      ),
    );
  }
}
