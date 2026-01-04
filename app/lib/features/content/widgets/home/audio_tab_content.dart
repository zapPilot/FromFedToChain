import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';
import 'package:from_fed_to_chain_app/features/content/widgets/audio_list.dart';

class AudioTabContent extends StatelessWidget {
  final List<AudioFile> episodes;
  final ScrollController scrollController;
  final Function(AudioFile) onPlay;
  final Function(AudioFile) onOptions;
  final Widget? emptyState;

  const AudioTabContent({
    super.key,
    required this.episodes,
    required this.scrollController,
    required this.onPlay,
    required this.onOptions,
    this.emptyState,
  });

  @override
  Widget build(BuildContext context) {
    if (episodes.isEmpty && emptyState != null) {
      return emptyState!;
    }

    return AnimationLimiter(
      child: AudioList(
        episodes: episodes,
        onEpisodeTap: onPlay,
        onEpisodeLongPress: onOptions,
        scrollController: scrollController,
      ),
    );
  }
}
