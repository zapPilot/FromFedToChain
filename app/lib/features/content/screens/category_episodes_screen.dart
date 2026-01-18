import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:from_fed_to_chain_app/core/theme/app_theme.dart';
import 'package:from_fed_to_chain_app/core/config/api_config.dart';
import 'package:from_fed_to_chain_app/features/content/services/content_service.dart';
import 'package:from_fed_to_chain_app/features/audio/services/audio_player_service.dart';
import 'package:from_fed_to_chain_app/features/audio/screens/player_screen.dart';
import 'package:from_fed_to_chain_app/features/content/widgets/audio_list.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';
import 'package:from_fed_to_chain_app/features/content/widgets/episode_options_sheet.dart';

class CategoryEpisodesScreen extends StatefulWidget {
  final String category;
  final String language;

  const CategoryEpisodesScreen({
    super.key,
    required this.category,
    required this.language,
  });

  @override
  State<CategoryEpisodesScreen> createState() => _CategoryEpisodesScreenState();
}

class _CategoryEpisodesScreenState extends State<CategoryEpisodesScreen> {
  bool _showUnfinishedOnly = false;

  @override
  Widget build(BuildContext context) {
    final categoryService = context.watch<ContentService>();
    final audioService = context.watch<AudioPlayerService>();

    // Get episodes for this category and language
    final allEpisodes = categoryService.getEpisodesByLanguageAndCategory(
      widget.language,
      widget.category,
    );

    // Apply local filter
    final displayedEpisodes = _showUnfinishedOnly
        ? allEpisodes
            .where((e) => categoryService.isEpisodeUnfinished(e.id))
            .toList()
        : allEpisodes;

    final categoryName = ApiConfig.getCategoryDisplayName(widget.category);
    final categoryEmoji = AppTheme.getCategoryEmoji(widget.category);

    return Scaffold(
      appBar: AppBar(
        title: Text('$categoryEmoji $categoryName'),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Toggle
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: !_showUnfinishedOnly,
                  onSelected: (selected) {
                    if (selected) setState(() => _showUnfinishedOnly = false);
                  },
                ),
                const SizedBox(width: AppTheme.spacingS),
                FilterChip(
                  label: const Text('Unfinished'),
                  selected: _showUnfinishedOnly,
                  onSelected: (selected) {
                    if (selected) setState(() => _showUnfinishedOnly = true);
                  },
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: AudioList(
              episodes: displayedEpisodes,
              onEpisodeTap: (episode) => _navigateToEpisode(episode),
              onPlayTap: (episode) => _playEpisode(episode, audioService),
              onEpisodeLongPress: (episode) =>
                  _showEpisodeOptions(context, episode),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToEpisode(AudioFile episode) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          contentId: episode.id,
          preferredLanguage: episode.language,
        ),
      ),
    );
  }

  Future<void> _playEpisode(
      AudioFile episode, AudioPlayerService audioService) async {
    try {
      await audioService.playAudio(episode);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot play audio: ${e.toString()}')),
      );
    }
  }

  void _showEpisodeOptions(BuildContext context, AudioFile episode) {
    showModalBottomSheet(
      context: context,
      builder: (context) => EpisodeOptionsSheet(episode: episode),
    );
  }
}
