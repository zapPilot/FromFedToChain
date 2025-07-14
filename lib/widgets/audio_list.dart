import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/content_service.dart';
import '../services/audio_service.dart';
import '../models/audio_file.dart';
import '../models/audio_content.dart';
import '../themes/app_theme.dart';
import 'audio_item_card.dart';

class AudioList extends StatelessWidget {
  const AudioList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ContentService>(
      builder: (context, contentService, child) {
        if (contentService.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppTheme.purplePrimary,
            ),
          );
        }

        if (contentService.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppTheme.error.withOpacity(0.7),
                ),
                const SizedBox(height: 16),
                Text(
                  'Error Loading Content',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  contentService.error!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: contentService.loadContent,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final audioFiles = contentService.audioFiles;
        
        if (audioFiles.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.music_off,
                  size: 64,
                  color: AppTheme.textTertiary.withOpacity(0.7),
                ),
                const SizedBox(height: 16),
                Text(
                  'No Audio Files Found',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try adjusting your filters or check if audio files exist',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: contentService.clearFilters,
                  child: const Text('Clear Filters'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: audioFiles.length,
          itemBuilder: (context, index) {
            final audioFile = audioFiles[index];
            final content = contentService.getContent(
              audioFile.id,
              audioFile.language,
            );
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AudioItemCard(
                audioFile: audioFile,
                content: content,
                onPlay: () => _playAudio(context, audioFile),
              ),
            );
          },
        );
      },
    );
  }

  void _playAudio(BuildContext context, AudioFile audioFile) {
    final audioService = context.read<AudioService>();
    audioService.playAudio(audioFile);
  }
}