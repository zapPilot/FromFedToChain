import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/audio_file.dart';
import '../models/audio_content.dart';
import '../services/audio_service.dart';
import '../themes/app_theme.dart';

class AudioItemCard extends StatelessWidget {
  final AudioFile audioFile;
  final AudioContent? content;
  final VoidCallback onPlay;

  const AudioItemCard({
    super.key,
    required this.audioFile,
    this.content,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioService>(
      builder: (context, audioService, child) {
        final isCurrentFile = audioService.currentAudioFile?.filePath == audioFile.filePath;
        final isPlaying = isCurrentFile && audioService.isPlaying;
        
        return Container(
          decoration: BoxDecoration(
            gradient: isCurrentFile 
                ? AppTheme.categoryGradient(audioFile.category)
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.surface.withOpacity(0.9),
                      AppTheme.surface.withOpacity(0.7),
                    ],
                  ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCurrentFile 
                  ? AppTheme.categoryGradient(audioFile.category).colors.first.withOpacity(0.5)
                  : AppTheme.textTertiary.withOpacity(0.1),
              width: isCurrentFile ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isCurrentFile 
                    ? AppTheme.categoryGradient(audioFile.category).colors.first.withOpacity(0.2)
                    : Colors.black.withOpacity(0.1),
                blurRadius: isCurrentFile ? 16 : 6,
                offset: const Offset(0, 4),
              ),
              if (isCurrentFile)
                BoxShadow(
                  color: AppTheme.categoryGradient(audioFile.category).colors.first.withOpacity(0.1),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onPlay,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Play button
                    _buildPlayButton(isPlaying, audioService.isLoading && isCurrentFile, audioFile.category),
                    
                    const SizedBox(width: 16),
                    
                    // Content info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            content?.title ?? audioFile.id,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: isCurrentFile ? AppTheme.textPrimary : AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          const SizedBox(height: 4),
                          
                          // Metadata row
                          Row(
                            children: [
                              // Language
                              _buildChip(
                                audioFile.languageDisplayName,
                                AppTheme.bluePrimary,
                              ),
                              
                              const SizedBox(width: 8),
                              
                              // Category
                              _buildChip(
                                audioFile.categoryDisplayName,
                                AppTheme.categoryGradient(audioFile.category).colors.first,
                              ),
                              
                              const Spacer(),
                              
                              // File size
                              Text(
                                audioFile.sizeFormatted,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textTertiary,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Date and duration
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 12,
                                color: AppTheme.textTertiary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                audioFile.displayDate,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textTertiary,
                                ),
                              ),
                              
                              if (audioFile.duration != null) ...[
                                const SizedBox(width: 16),
                                Icon(
                                  Icons.access_time,
                                  size: 12,
                                  color: AppTheme.textTertiary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  audioFile.durationFormatted,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textTertiary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          
                          // Progress bar for current file
                          if (isCurrentFile && audioService.totalDuration.inSeconds > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Column(
                                children: [
                                  LinearProgressIndicator(
                                    value: audioService.progress,
                                    backgroundColor: AppTheme.textTertiary.withOpacity(0.2),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.purplePrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        audioService.formattedCurrentPosition,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppTheme.textTertiary,
                                          fontSize: 10,
                                        ),
                                      ),
                                      Text(
                                        audioService.formattedTotalDuration,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                    ),
                    
                    // More actions button
                    IconButton(
                      onPressed: () => _showMoreActions(context),
                      icon: Icon(
                        Icons.more_vert,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayButton(bool isPlaying, bool isLoading, String category) {
    final gradient = AppTheme.categoryGradient(category);
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: gradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: isLoading
          ? const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            )
          : Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 28,
            ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showMoreActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textTertiary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              content?.title ?? audioFile.id,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            // Actions
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Show Details'),
              onTap: () {
                Navigator.pop(context);
                _showDetails(context);
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement share functionality
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(content?.title ?? audioFile.id),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('File Size', audioFile.sizeFormatted),
            _buildDetailRow('Language', audioFile.languageDisplayName),
            _buildDetailRow('Category', audioFile.categoryDisplayName),
            _buildDetailRow('Date', audioFile.displayDate),
            if (content != null) ...[
              _buildDetailRow('Status', content!.status),
              if (content!.references.isNotEmpty)
                _buildDetailRow('References', content!.references.join(', ')),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: AppTheme.textTertiary,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}