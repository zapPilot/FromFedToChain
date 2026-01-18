import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:from_fed_to_chain_app/core/theme/app_theme.dart';
import 'package:from_fed_to_chain_app/core/config/api_config.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';
import 'package:from_fed_to_chain_app/features/content/services/content_service.dart';
import 'package:from_fed_to_chain_app/features/audio/services/audio_player_service.dart';
import 'package:from_fed_to_chain_app/features/content/screens/category_episodes_screen.dart';

class PlayerTrackInfo extends StatefulWidget {
  final AudioFile currentAudio;

  const PlayerTrackInfo({
    super.key,
    required this.currentAudio,
  });

  @override
  State<PlayerTrackInfo> createState() => _PlayerTrackInfoState();
}

class _PlayerTrackInfoState extends State<PlayerTrackInfo> {
  final List<AudioFile> _availableVersions = [];

  Future<List<AudioFile>> _fetchVersions() async {
    if (_availableVersions.isNotEmpty &&
        _availableVersions.first.id == widget.currentAudio.id) {
      return _availableVersions;
    }

    try {
      final contentService = context.read<ContentService>();
      final versions =
          contentService.getEpisodeVersions(widget.currentAudio.id);
      _availableVersions.clear();
      _availableVersions.addAll(versions);
      return _availableVersions;
    } catch (_) {
      return [widget.currentAudio];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppTheme.safeHorizontalPadding,
      child: Column(
        children: [
          // Track title
          Text(
            widget.currentAudio.displayTitle,
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
              // Clickable Category Chip
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _navigateToCategory(context),
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingS,
                      vertical: 4, // touch target padding
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.getCategoryColor(
                              widget.currentAudio.category)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      border: Border.all(
                        color: AppTheme.getCategoryColor(
                                widget.currentAudio.category)
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          widget.currentAudio.categoryEmoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: AppTheme.spacingXS),
                        Text(
                          ApiConfig.getCategoryDisplayName(
                              widget.currentAudio.category),
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.getCategoryColor(
                                widget.currentAudio.category),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: AppTheme.spacingM),

              // Language Selector
              _buildLanguageSelector(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector(BuildContext context) {
    return FutureBuilder<List<AudioFile>>(
      future: _fetchVersions(),
      builder: (context, snapshot) {
        final versions = snapshot.data ?? [widget.currentAudio];

        if (versions.length <= 1) {
          return Row(
            children: [
              Text(
                widget.currentAudio.languageFlag,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: AppTheme.spacingXS),
              Text(
                ApiConfig.getLanguageDisplayName(widget.currentAudio.language),
                style: AppTheme.bodyMedium.copyWith(
                  color:
                      AppTheme.getLanguageColor(widget.currentAudio.language),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );
        }

        final color = AppTheme.getLanguageColor(widget.currentAudio.language);

        return Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusS),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<AudioFile>(
              value: versions.any((v) =>
                      v.id == widget.currentAudio.id &&
                      v.language == widget.currentAudio.language)
                  ? versions.firstWhere((v) =>
                      v.id == widget.currentAudio.id &&
                      v.language == widget.currentAudio.language)
                  : versions.first,
              isDense: true,
              icon: Icon(Icons.arrow_drop_down, size: 18, color: color),
              style: AppTheme.bodyMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
              dropdownColor: AppTheme.surfaceColor,
              items: versions.map((v) {
                return DropdownMenuItem<AudioFile>(
                  value: v,
                  child: Text(
                      '${v.languageFlag} ${ApiConfig.getLanguageDisplayName(v.language)}'),
                );
              }).toList(),
              onChanged: (AudioFile? newValue) {
                if (newValue != null &&
                    newValue.language != widget.currentAudio.language) {
                  context.read<AudioPlayerService>().playAudio(newValue);
                }
              },
            ),
          ),
        );
      },
    );
  }

  void _navigateToCategory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CategoryEpisodesScreen(
          category: widget.currentAudio.category,
          language: widget.currentAudio.language,
        ),
      ),
    );
  }
}
