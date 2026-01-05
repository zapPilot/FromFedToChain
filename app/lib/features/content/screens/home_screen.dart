import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:from_fed_to_chain_app/core/theme/app_theme.dart';
import 'package:from_fed_to_chain_app/features/content/services/content_service.dart';
import 'package:from_fed_to_chain_app/features/audio/services/audio_player_service.dart';
import 'package:from_fed_to_chain_app/features/audio/services/player_state_notifier.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';
import 'package:from_fed_to_chain_app/features/content/widgets/filter_bar.dart';

import 'package:from_fed_to_chain_app/features/content/widgets/search_bar.dart';
import 'package:from_fed_to_chain_app/features/content/widgets/home/home_header.dart';
import 'package:from_fed_to_chain_app/features/content/widgets/home/home_mini_player.dart';
import 'package:from_fed_to_chain_app/features/content/widgets/episode_options_sheet.dart';
import 'package:from_fed_to_chain_app/features/content/widgets/home/audio_tab_content.dart';
import 'package:from_fed_to_chain_app/features/content/models/content_service_state.dart';
import 'package:from_fed_to_chain_app/features/content/widgets/home/sort_selector.dart';
import 'package:from_fed_to_chain_app/features/content/widgets/home/content_states.dart';

/// Main home screen displaying episodes with filtering and search
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _showSearchBar = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load content when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContentService>().loadAllEpisodes();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Content-related UI (only rebuilds when ContentService changes)
            Selector<ContentService, ContentServiceState>(
              selector: (context, service) => ContentServiceState(
                allEpisodes: service.allEpisodes,
                filteredEpisodes: service.filteredEpisodes,
                isLoading: service.isLoading,
                hasError: service.hasError,
                errorMessage: service.errorMessage,
                selectedLanguage: service.selectedLanguage,
                selectedCategory: service.selectedCategory,
                searchQuery: service.searchQuery,
              ),
              builder: (context, state, child) {
                final contentService = context.read<ContentService>();
                return Column(
                  children: [
                    // App header with search toggle
                    _buildAppHeader(context, contentService),

                    // Search bar (animated)
                    if (_showSearchBar)
                      _buildSearchBar(context, contentService),

                    // Filter bar
                    _buildFilterBar(context, contentService),

                    // Sort selector
                    // Sort selector
                    SortSelector(
                      sortOrder: contentService.sortOrder,
                      onSortChanged: (newValue) {
                        contentService.setSortOrder(newValue);
                      },
                    ),
                  ],
                );
              },
            ),

            // Main content area (needs both services for episode interaction)
            Expanded(
              child: Consumer2<ContentService, AudioPlayerService>(
                builder: (context, contentService, audioService, child) {
                  return _buildMainContent(
                      context, contentService, audioService);
                },
              ),
            ),

            // Mini player (only rebuilds when AudioPlayerService changes)
            Selector<AudioPlayerService, AudioFile?>(
              selector: (context, service) => service.currentAudioFile,
              builder: (context, currentAudioFile, child) {
                if (currentAudioFile == null) return const SizedBox.shrink();

                return Selector<AudioPlayerService, AppPlaybackState>(
                  selector: (context, service) => service.playbackState,
                  builder: (context, playbackState, child) {
                    final audioService = context.read<AudioPlayerService>();
                    return _buildMiniPlayer(context, audioService);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Build app header with title and search toggle
  Widget _buildAppHeader(BuildContext context, ContentService contentService) {
    return HomeHeader(
      onSearchToggle: () {
        setState(() {
          _showSearchBar = !_showSearchBar;
        });
      },
      isSearchVisible: _showSearchBar,
    );
  }

  /// Build animated search bar
  Widget _buildSearchBar(BuildContext context, ContentService contentService) {
    return AnimatedContainer(
      duration: AppTheme.animationMedium,
      curve: Curves.easeInOut,
      height: _showSearchBar ? 60 : 0,
      child: Padding(
        padding: AppTheme.safeHorizontalPadding,
        child: SearchBarWidget(
          onSearchChanged: (query) {
            contentService.setSearchQuery(query);
          },
          hintText: 'Search episodes...',
        ),
      ),
    );
  }

  /// Build filter bar with language and category selection
  Widget _buildFilterBar(BuildContext context, ContentService contentService) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      child: FilterBar(
        selectedLanguage: contentService.selectedLanguage,
        selectedCategory: contentService.selectedCategory,
        onLanguageChanged: (language) {
          contentService.setLanguage(language);
        },
        onCategoryChanged: (category) {
          contentService.setCategory(category);
        },
      ),
    );
  }

  /// Build main content area with tabs
  Widget _buildMainContent(
    BuildContext context,
    ContentService contentService,
    AudioPlayerService audioService,
  ) {
    if (contentService.isLoading && contentService.allEpisodes.isEmpty) {
      return const ContentLoadingState();
    }

    if (contentService.hasError) {
      return ContentErrorState(
        errorMessage: contentService.errorMessage ?? 'Unknown error occurred',
        onRetry: () => contentService.refresh(),
      );
    }

    if (contentService.filteredEpisodes.isEmpty) {
      return ContentEmptyState(
        searchQuery: contentService.searchQuery,
        onClearFilters: () => contentService.setSearchQuery(''),
        onRefresh: () => contentService.refresh(),
      );
    }

    return Column(
      children: [
        // Tab bar
        Container(
          margin: AppTheme.safeHorizontalPadding,
          decoration: AppTheme.cardDecoration,
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Recent'),
              Tab(text: 'All'),
              Tab(text: 'Unfinished'),
            ],
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor:
                AppTheme.onSurfaceColor.withValues(alpha: 0.6),
            indicatorColor: AppTheme.primaryColor,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
          ),
        ),

        const SizedBox(height: AppTheme.spacingS),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRecentTab(contentService, audioService),
              _buildAllTab(contentService, audioService),
              _buildUnfinishedTab(contentService, audioService),
            ],
          ),
        ),
      ],
    );
  }

  /// Build recent episodes tab
  Widget _buildRecentTab(
      ContentService contentService, AudioPlayerService audioService) {
    final recentEpisodes = contentService.filteredEpisodes.take(20).toList();

    return AudioTabContent(
      episodes: recentEpisodes,
      scrollController: _scrollController,
      onPlay: (episode) => _playEpisode(episode, audioService),
      onOptions: (episode) => _showEpisodeOptions(episode),
    );
  }

  /// Build all episodes tab
  Widget _buildAllTab(
      ContentService contentService, AudioPlayerService audioService) {
    return AudioTabContent(
      episodes: contentService.filteredEpisodes,
      scrollController: _scrollController,
      onPlay: (episode) => _playEpisode(episode, audioService),
      onOptions: (episode) => _showEpisodeOptions(episode),
    );
  }

  /// Build unfinished episodes tab
  Widget _buildUnfinishedTab(
      ContentService contentService, AudioPlayerService audioService) {
    final unfinishedEpisodes = contentService.getUnfinishedEpisodes();

    return AudioTabContent(
      episodes: unfinishedEpisodes,
      scrollController: _scrollController,
      onPlay: (episode) => _playEpisode(episode, audioService),
      onOptions: (episode) => _showEpisodeOptions(episode),
      emptyState: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pending_actions,
              size: 80,
              color: AppTheme.onSurfaceColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppTheme.spacingL),
            Text(
              'No Unfinished Episodes',
              style: AppTheme.headlineSmall.copyWith(
                color: AppTheme.onSurfaceColor.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'Episodes you\'ve started listening to will appear here',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.onSurfaceColor.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build mini player
  Widget _buildMiniPlayer(
      BuildContext context, AudioPlayerService audioService) {
    return const HomeMiniPlayer();
  }

  /// Play episode
  Future<void> _playEpisode(
      AudioFile episode, AudioPlayerService audioService) async {
    try {
      await audioService.playAudio(episode);
    } catch (e) {
      if (!mounted) return;

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
