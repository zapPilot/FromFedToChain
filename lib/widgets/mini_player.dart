import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_service.dart';
import '../services/content_service.dart';
import '../themes/app_theme.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AudioService, ContentService>(
      builder: (context, audioService, contentService, child) {
        final audioFile = audioService.currentAudioFile;
        if (audioFile == null) return const SizedBox.shrink();

        final content = contentService.getContent(
          audioFile.id,
          audioFile.language,
        );

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.surface.withOpacity(0.95),
                AppTheme.surface,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress bar
              if (audioService.totalDuration.inSeconds > 0)
                Container(
                  height: 3,
                  child: LinearProgressIndicator(
                    value: audioService.progress,
                    backgroundColor: AppTheme.textTertiary.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.purplePrimary,
                    ),
                  ),
                ),

              // Player controls
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Album art / Icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.audiotrack,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Track info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              content?.title ?? audioFile.id,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  audioFile.languageDisplayName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppTheme.textTertiary,
                                      ),
                                ),
                                Text(
                                  ' • ',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppTheme.textTertiary,
                                      ),
                                ),
                                Text(
                                  audioFile.categoryDisplayName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppTheme.textTertiary,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Control buttons
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Skip backward
                          IconButton(
                            onPressed: audioService.skipBackward,
                            icon: const Icon(Icons.replay_10),
                            color: AppTheme.textSecondary,
                          ),

                          // Play/Pause
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppTheme.purplePrimary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              onPressed: audioService.togglePlayPause,
                              icon: Icon(
                                audioService.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),

                          // Skip forward
                          IconButton(
                            onPressed: audioService.skipForward,
                            icon: const Icon(Icons.forward_10),
                            color: AppTheme.textSecondary,
                          ),

                          // Autoplay toggle
                          IconButton(
                            onPressed: () => audioService.setAutoplayEnabled(
                                !audioService.autoplayEnabled),
                            icon: Icon(
                              audioService.autoplayEnabled
                                  ? Icons.playlist_play
                                  : Icons.playlist_play_outlined,
                              color: audioService.autoplayEnabled
                                  ? AppTheme.purplePrimary
                                  : AppTheme.textTertiary,
                            ),
                            tooltip: audioService.autoplayEnabled
                                ? 'Autoplay On'
                                : 'Autoplay Off',
                          ),

                          // Playback speed
                          PopupMenuButton<double>(
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppTheme.textTertiary.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '${audioService.playbackSpeed}x',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            itemBuilder: (context) => [
                              _buildSpeedMenuItem(0.5),
                              _buildSpeedMenuItem(0.75),
                              _buildSpeedMenuItem(1.0),
                              _buildSpeedMenuItem(1.25),
                              _buildSpeedMenuItem(1.5),
                              _buildSpeedMenuItem(2.0),
                            ],
                            onSelected: audioService.setPlaybackSpeed,
                            color: AppTheme.surface,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Time display and seek bar (expanded view)
              if (audioService.totalDuration.inSeconds > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      // Seek bar
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppTheme.purplePrimary,
                          inactiveTrackColor:
                              AppTheme.textTertiary.withOpacity(0.2),
                          thumbColor: AppTheme.purplePrimary,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6),
                          overlayShape:
                              const RoundSliderOverlayShape(overlayRadius: 12),
                          trackHeight: 3,
                        ),
                        child: Slider(
                          value: audioService.progress.clamp(0.0, 1.0),
                          onChanged: (value) {
                            final position = Duration(
                              milliseconds: (value *
                                      audioService.totalDuration.inMilliseconds)
                                  .round(),
                            );
                            audioService.seekTo(position);
                          },
                        ),
                      ),

                      // Time labels
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            audioService.formattedCurrentPosition,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textTertiary,
                                      fontSize: 10,
                                    ),
                          ),
                          Text(
                            audioService.formattedTotalDuration,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textTertiary,
                                      fontSize: 10,
                                    ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  PopupMenuItem<double> _buildSpeedMenuItem(double speed) {
    return PopupMenuItem<double>(
      value: speed,
      child: Text(
        '${speed}x',
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 14,
        ),
      ),
    );
  }
}
