import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:from_fed_to_chain_app/core/theme/app_theme.dart';
import 'package:from_fed_to_chain_app/features/content/services/content_service.dart';
import 'package:from_fed_to_chain_app/features/audio/services/audio_player_service.dart';
import 'package:from_fed_to_chain_app/features/audio/services/player_state_notifier.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';
import 'package:from_fed_to_chain_app/features/content/widgets/home/home_mini_player.dart';
import 'package:from_fed_to_chain_app/features/content/widgets/episode_options_sheet.dart';
import 'package:from_fed_to_chain_app/features/content/widgets/home/audio_tab_content.dart';

import 'package:from_fed_to_chain_app/features/content/widgets/home/content_states.dart';
import 'package:from_fed_to_chain_app/features/content/screens/history_screen.dart';
import 'package:from_fed_to_chain_app/features/audio/screens/player_screen.dart';

/// Main home screen displaying episodes in Focus Mode
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Load content when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContentService>().loadAllEpisodes();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Focus Mode Header
            _buildFocusHeader(context),

            // Main content area
            Expanded(
              child: Consumer2<ContentService, AudioPlayerService>(
                builder: (context, contentService, audioService, child) {
                  return _buildFocusContent(
                      context, contentService, audioService);
                },
              ),
            ),

            // Mini player
            Selector<AudioPlayerService, AudioFile?>(
              selector: (context, service) => service.currentAudioFile,
              builder: (context, currentAudioFile, child) {
                if (currentAudioFile == null) return const SizedBox.shrink();

                return Selector<AudioPlayerService, AppPlaybackState>(
                  selector: (context, service) => service.playbackState,
                  builder: (context, playbackState, child) {
                    return const HomeMiniPlayer();
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Build Focus Mode Header with Language Selector and History
  Widget _buildFocusHeader(BuildContext context) {
    return Selector<ContentService, String>(
      selector: (context, service) => service.selectedLanguage,
      builder: (context, selectedLanguage, child) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: AppTheme.spacingS,
          ),
          child: Row(
            children: [
              const Text(
                'Queue',
                style: AppTheme.headlineMedium,
              ),
              const Spacer(),
              // Language Selector
              _buildLanguageSelector(context, selectedLanguage),
              const SizedBox(width: AppTheme.spacingM),
              // History Button
              IconButton(
                icon: const Icon(Icons.history),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const HistoryScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageSelector(BuildContext context, String currentLanguage) {
    final contentService = context.read<ContentService>();

    return PopupMenuButton<String>(
      initialValue: currentLanguage,
      onSelected: (String language) {
        contentService.setLanguage(language);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.onSurfaceColor.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Text(
              currentLanguage == 'zh-TW'
                  ? '🇹🇼'
                  : currentLanguage == 'en-US'
                      ? '🇺🇸'
                      : currentLanguage == 'ja-JP'
                          ? '🇯🇵'
                          : '🌐',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
      ),
      itemBuilder: (BuildContext context) {
        return [
          const PopupMenuItem(
            value: 'zh-TW',
            child: Text('🇹🇼 繁體中文'),
          ),
          const PopupMenuItem(
            value: 'en-US',
            child: Text('🇺🇸 English'),
          ),
          const PopupMenuItem(
            value: 'ja-JP',
            child: Text('🇯🇵 日本語'),
          ),
        ];
      },
    );
  }

  /// Build main content area for Focus Mode
  Widget _buildFocusContent(
    BuildContext context,
    ContentService contentService,
    AudioPlayerService audioService,
  ) {
    // Show loading state IF:
    // 1. It's currently loading AND we have NO data yet
    // 2. OR it's the first load (isLoading and allEpisodes empty)
    if (contentService.isLoading && contentService.allEpisodes.isEmpty) {
      return const ContentLoadingState();
    }

    if (contentService.hasError) {
      return ContentErrorState(
        errorMessage: contentService.errorMessage ?? 'Unknown error occurred',
        onRetry: () => contentService.refresh(),
      );
    }

    // Get Focus Queue (Unfinished + Unplayed) and sort by date descending
    final focusEpisodes = List<AudioFile>.from(
      contentService.getFocusQueue(contentService.selectedLanguage),
    )..sort((a, b) => b.publishDate.compareTo(a.publishDate));

    if (focusEpisodes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppTheme.spacingL),
            Text(
              'All Caught Up!',
              style: AppTheme.headlineSmall.copyWith(
                color: AppTheme.onSurfaceColor.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'No new episodes in ${contentService.selectedLanguage}',
              textAlign: TextAlign.center,
              style: AppTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return AudioTabContent(
      episodes: focusEpisodes,
      scrollController: _scrollController,
      onEpisodeTap: (episode) => _navigateToEpisode(context, episode),
      onPlay: (episode) => _playEpisode(episode, audioService),
      onOptions: (episode) => _showEpisodeOptions(episode),
    );
  }

  void _navigateToEpisode(BuildContext context, AudioFile episode) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          contentId: episode.id,
          preferredLanguage: episode.language,
        ),
      ),
    );
  }

  /// Play episode
  Future<void> _playEpisode(
      AudioFile episode, AudioPlayerService audioService) async {
    try {
      await audioService.playAudio(episode);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot play audio: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Show episode options
  void _showEpisodeOptions(AudioFile episode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusL),
        ),
      ),
      builder: (context) => EpisodeOptionsSheet(episode: episode),
    );
  }
}
