import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/audio_file.dart';
import '../models/audio_content.dart';
import '../services/audio_service.dart';
import '../themes/app_theme.dart';

class CourseCard extends StatelessWidget {
  final AudioFile audioFile;
  final AudioContent? content;
  final VoidCallback? onTap;
  final bool isHorizontal;
  final bool isVertical;
  final bool showProgress;

  const CourseCard({
    super.key,
    required this.audioFile,
    this.content,
    this.onTap,
    this.isHorizontal = false,
    this.isVertical = false,
    this.showProgress = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.textTertiary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: isHorizontal
            ? _buildHorizontalLayout(context)
            : isVertical
                ? _buildVerticalLayout(context)
                : _buildDefaultLayout(context),
      ),
    );
  }

  Widget _buildHorizontalLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildCourseImage(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitle(context),
                const SizedBox(height: 4),
                _buildSubtitle(context),
                const SizedBox(height: 8),
                if (showProgress) _buildProgressBar(),
                const SizedBox(height: 8),
                _buildPlayButton(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCourseImage(),
          const SizedBox(height: 12),
          _buildTitle(context),
          const SizedBox(height: 4),
          _buildSubtitle(context),
          const SizedBox(height: 8),
          if (showProgress) _buildProgressBar(),
          const SizedBox(height: 8),
          _buildPlayButton(context),
        ],
      ),
    );
  }

  Widget _buildDefaultLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildCourseImage(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitle(context),
                const SizedBox(height: 4),
                _buildSubtitle(context),
                const SizedBox(height: 8),
                if (showProgress) _buildProgressBar(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildPlayButton(context),
                    const Spacer(),
                    _buildDuration(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseImage() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.play_arrow,
            color: Colors.white.withOpacity(0.8),
            size: 24,
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getCategoryIcon(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Text(
      content?.title ?? audioFile.id,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    return Text(
      '${audioFile.categoryDisplayName} • ${audioFile.languageDisplayName}',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: AppTheme.textTertiary,
      ),
    );
  }

  Widget _buildProgressBar() {
    // Mock progress for now
    final progress = 0.3; // 30% progress
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: AppTheme.textTertiary.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(progress * 100).toInt()}% complete',
          style: const TextStyle(
            color: AppTheme.textTertiary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildPlayButton(BuildContext context) {
    return Consumer<AudioService>(
      builder: (context, audioService, child) {
        final isCurrentlyPlaying = audioService.currentAudioFile?.id == audioFile.id;
        final isPlaying = audioService.isPlaying;
        
        return GestureDetector(
          onTap: () {
            if (isCurrentlyPlaying && isPlaying) {
              audioService.pause();
            } else {
              audioService.playAudio(audioFile);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.purplePrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.purplePrimary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isCurrentlyPlaying && isPlaying 
                      ? Icons.pause 
                      : Icons.play_arrow,
                  color: AppTheme.purplePrimary,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  isCurrentlyPlaying && isPlaying ? 'Pause' : 'Play',
                  style: TextStyle(
                    color: AppTheme.purplePrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDuration() {
    // Mock duration for now
    return Text(
      '15:30',
      style: const TextStyle(
        color: AppTheme.textTertiary,
        fontSize: 12,
      ),
    );
  }

  String _getCategoryIcon() {
    switch (audioFile.category) {
      case 'daily-news':
        return '📰';
      case 'ethereum':
        return '⚡';
      case 'macro':
        return '📊';
      case 'startup':
        return '🚀';
      default:
        return '🎵';
    }
  }
}