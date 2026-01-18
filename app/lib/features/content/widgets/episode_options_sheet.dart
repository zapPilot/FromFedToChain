import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:from_fed_to_chain_app/core/theme/app_theme.dart';
import 'package:from_fed_to_chain_app/features/audio/services/audio_player_service.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';
import 'package:from_fed_to_chain_app/features/content/services/content_service.dart';
import 'package:from_fed_to_chain_app/features/content/services/playlist_service.dart';

class EpisodeOptionsSheet extends StatefulWidget {
  final AudioFile episode;

  const EpisodeOptionsSheet({
    super.key,
    required this.episode,
  });

  @override
  State<EpisodeOptionsSheet> createState() => _EpisodeOptionsSheetState();
}

class _EpisodeOptionsSheetState extends State<EpisodeOptionsSheet> {
  late AudioFile _selectedEpisode;
  List<AudioFile> _availableVersions = [];

  @override
  void initState() {
    super.initState();
    _selectedEpisode = widget.episode;

    // Load available versions after build to access provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVersions();
    });
  }

  void _loadVersions() {
    if (!mounted) return;
    final contentService = context.read<ContentService>();
    final versions = contentService.getEpisodeVersions(widget.episode.id);

    setState(() {
      _availableVersions = versions;

      // Ensure selected episode is one of the versions if possible (reference equality)
      // or at least matches ID and language
      final match = versions
          .where((e) =>
              e.id == _selectedEpisode.id &&
              e.language == _selectedEpisode.language)
          .firstOrNull;

      if (match != null) {
        _selectedEpisode = match;
      } else if (versions.isNotEmpty) {
        // Fallback if current episode somehow isn't in the list (shouldn't happen if loaded from same service)
        if (versions.contains(widget.episode)) {
          _selectedEpisode = widget.episode;
        } else {
          _selectedEpisode = versions.first;
        }
      } else {
        // No versions found in service? Keep original.
        _availableVersions = [widget.episode];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppTheme.safePadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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

          // Episode info
          Text(
            _selectedEpisode.displayTitle,
            style: AppTheme.titleLarge,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: AppTheme.spacingS),

          // Metadata row with Language Selector
          Row(
            children: [
              Text(
                '${_selectedEpisode.categoryEmoji} ${_selectedEpisode.category}',
                style: AppTheme.bodySmall,
              ),
              const SizedBox(width: 8),
              Text('•', style: AppTheme.bodySmall),
              const SizedBox(width: 8),
              if (_availableVersions.length > 1)
                DropdownButton<AudioFile>(
                  value: _selectedEpisode,
                  isDense: true,
                  underline: const SizedBox(), // Remove underline
                  icon: const Icon(Icons.arrow_drop_down, size: 20),
                  items: _availableVersions.map((version) {
                    return DropdownMenuItem<AudioFile>(
                      value: version,
                      child: Text(
                        '${version.languageFlag} ${version.language}',
                        style: AppTheme.bodySmall,
                      ),
                    );
                  }).toList(),
                  onChanged: (AudioFile? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedEpisode = newValue;
                      });
                    }
                  },
                )
              else
                Text(
                  '${_selectedEpisode.languageFlag} ${_selectedEpisode.language}',
                  style: AppTheme.bodySmall,
                ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingL),

          // Actions
          ListTile(
            leading: const Icon(Icons.play_arrow),
            title: const Text('Play'),
            onTap: () {
              Navigator.pop(context);
              _playEpisode(context, _selectedEpisode);
            },
          ),

          ListTile(
            leading: const Icon(Icons.favorite_border),
            title: const Text('Add to Favorites'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement favorites
            },
          ),

          ListTile(
            leading: const Icon(Icons.playlist_add),
            title: const Text('Add to Playlist'),
            onTap: () {
              Navigator.pop(context);
              context.read<PlaylistService>().addToPlaylist(_selectedEpisode);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Added "${_selectedEpisode.displayTitle}" to playlist'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement sharing
            },
          ),

          const SizedBox(height: AppTheme.spacingM),
        ],
      ),
    );
  }

  Future<void> _playEpisode(BuildContext context, AudioFile episode) async {
    try {
      await context.read<AudioPlayerService>().playAudio(episode);
    } catch (e) {
      if (!context.mounted) return;

      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot play audio: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }
}
