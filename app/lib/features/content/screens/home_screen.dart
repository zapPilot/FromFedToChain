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

/// State class for content service to enable granular rebuilds
class ContentServiceState {
  final List<AudioFile> allEpisodes;
  final List<AudioFile> filteredEpisodes;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final String selectedLanguage;
  final String selectedCategory;
  final String searchQuery;

  const ContentServiceState({
    required this.allEpisodes,
    required this.filteredEpisodes,
    required this.isLoading,
    required this.hasError,
    required this.errorMessage,
    required this.selectedLanguage,
    required this.selectedCategory,
    required this.searchQuery,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContentServiceState &&
          runtimeType == other.runtimeType &&
          allEpisodes.length == other.allEpisodes.length &&
          filteredEpisodes.length == other.filteredEpisodes.length &&
          isLoading == other.isLoading &&
          hasError == other.hasError &&
          errorMessage == other.errorMessage &&
          selectedLanguage == other.selectedLanguage &&
          selectedCategory == other.selectedCategory &&
          searchQuery == other.searchQuery;

  @override
  int get hashCode =>
      allEpisodes.length.hashCode ^
      filteredEpisodes.length.hashCode ^
      isLoading.hashCode ^
      hasError.hashCode ^
      errorMessage.hashCode ^
      selectedLanguage.hashCode ^
      selectedCategory.hashCode ^
      searchQuery.hashCode;
}

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
                    _buildSortSelector(context, contentService),
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
      return _buildLoadingState();
    }

    if (contentService.hasError) {
      return _buildErrorState(contentService);
    }

    if (contentService.filteredEpisodes.isEmpty) {
      return _buildEmptyState(contentService);
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

  /// Build loading state
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
          const SizedBox(height: AppTheme.spacingL),
          const Text(
            'Loading episodes...',
            style: AppTheme.titleMedium,
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'This may take a few moments',
            style: AppTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState(ContentService contentService) {
    return Center(
      child: Padding(
        padding: AppTheme.safePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: AppTheme.spacingL),
            const Text(
              'Something went wrong',
              style: AppTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              contentService.errorMessage ?? 'Unknown error occurred',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.onSurfaceColor.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXL),
            ElevatedButton(
              onPressed: () => contentService.refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState(ContentService contentService) {
    return Center(
      child: Padding(
        padding: AppTheme.safePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.headphones_outlined,
              size: 80,
              color: AppTheme.onSurfaceColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppTheme.spacingL),
            const Text(
              'No episodes found',
              style: AppTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              contentService.searchQuery.isNotEmpty
                  ? 'Try different search terms or filters'
                  : 'Check your internet connection and try again',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.onSurfaceColor.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXL),
            if (contentService.searchQuery.isNotEmpty)
              TextButton(
                onPressed: () => contentService.setSearchQuery(''),
                child: const Text('Clear filters'),
              )
            else
              ElevatedButton(
                onPressed: () => contentService.refresh(),
                child: const Text('Refresh'),
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

  /// Build sort selector dropdown
  Widget _buildSortSelector(
      BuildContext context, ContentService contentService) {
    return Container(
      margin: AppTheme.safeHorizontalPadding,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      child: Row(
        children: [
          Icon(
            Icons.sort,
            size: 16,
            color: AppTheme.onSurfaceColor.withValues(alpha: 0.6),
          ),
          const SizedBox(width: AppTheme.spacingS),
          Text(
            'Sort by:',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.onSurfaceColor.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: contentService.sortOrder,
                isDense: true,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.onSurfaceColor,
                  fontWeight: FontWeight.w500,
                ),
                dropdownColor: AppTheme.surfaceColor,
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: AppTheme.onSurfaceColor.withValues(alpha: 0.6),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'newest',
                    child: Text('Newest First'),
                  ),
                  DropdownMenuItem(
                    value: 'oldest',
                    child: Text('Oldest First'),
                  ),
                  DropdownMenuItem(
                    value: 'alphabetical',
                    child: Text('A-Z'),
                  ),
                ],
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    contentService.setSortOrder(newValue);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
