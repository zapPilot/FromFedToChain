import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../themes/app_theme.dart';
import '../services/content_facade_service.dart';
import '../services/audio_service.dart';
import '../models/audio_file.dart';
import '../widgets/filter_bar.dart';
import '../widgets/audio_list.dart';
import '../widgets/mini_player.dart';
import '../widgets/search_bar.dart';
import 'player_screen.dart';

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
      context.read<ContentFacadeService>().loadAllEpisodes();
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
            // Content-related UI (only rebuilds when ContentFacadeService changes)
            Selector<ContentFacadeService, ContentServiceState>(
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
                final contentService = context.read<ContentFacadeService>();
                return Column(
                  children: [
                    // App header with search toggle
                    _buildAppHeader(context, contentService),

                    // Search bar (animated)
                    if (_showSearchBar) _buildSearchBar(context, contentService),

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
              child: Consumer2<ContentFacadeService, AudioService>(
                builder: (context, contentService, audioService, child) {
                  return _buildMainContent(context, contentService, audioService);
                },
              ),
            ),

            // Mini player (only rebuilds when AudioService changes)
            Selector<AudioService, AudioFile?>(
              selector: (context, service) => service.currentAudioFile,
              builder: (context, currentAudioFile, child) {
                if (currentAudioFile == null) return const SizedBox.shrink();

                return Selector<AudioService, PlaybackState>(
                  selector: (context, service) => service.playbackState,
                  builder: (context, playbackState, child) {
                    final audioService = context.read<AudioService>();
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
  Widget _buildAppHeader(
      BuildContext context, ContentFacadeService contentService) {
    return Container(
      padding: AppTheme.safeHorizontalPadding,
      child: Row(
        children: [
          // App title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'From Fed to Chain',
                  style: AppTheme.headlineMedium,
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Consumer<ContentFacadeService>(
                  builder: (context, service, child) {
                    final stats = service.getStatistics();
                    final totalEpisodes = stats['totalEpisodes'] as int;
                    final filteredEpisodes = stats['filteredEpisodes'] as int;

                    return Text(
                      filteredEpisodes == totalEpisodes
                          ? '$totalEpisodes episodes'
                          : '$filteredEpisodes of $totalEpisodes episodes',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.onSurfaceColor.withOpacity(0.6),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Search toggle button
          IconButton(
            onPressed: () {
              setState(() {
                _showSearchBar = !_showSearchBar;
              });
            },
            icon: Icon(
              _showSearchBar ? Icons.close : Icons.search,
              color: AppTheme.onSurfaceColor,
            ),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.cardColor.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
            ),
          ),

          const SizedBox(width: AppTheme.spacingS),

          // Refresh button
          IconButton(
            onPressed: contentService.isLoading
                ? null
                : () => contentService.refresh(),
            icon: contentService.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryColor,
                      ),
                    ),
                  )
                : const Icon(Icons.refresh),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.cardColor.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build animated search bar
  Widget _buildSearchBar(
      BuildContext context, ContentFacadeService contentService) {
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
  Widget _buildFilterBar(
      BuildContext context, ContentFacadeService contentService) {
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
    ContentFacadeService contentService,
    AudioService audioService,
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
            unselectedLabelColor: AppTheme.onSurfaceColor.withOpacity(0.6),
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
      ContentFacadeService contentService, AudioService audioService) {
    final recentEpisodes = contentService.filteredEpisodes.take(20).toList();

    return AnimationLimiter(
      child: AudioList(
        episodes: recentEpisodes,
        onEpisodeTap: (episode) => _playEpisode(episode, audioService),
        onEpisodeLongPress: (episode) => _showEpisodeOptions(episode),
        scrollController: _scrollController,
      ),
    );
  }

  /// Build all episodes tab
  Widget _buildAllTab(
      ContentFacadeService contentService, AudioService audioService) {
    return AnimationLimiter(
      child: AudioList(
        episodes: contentService.filteredEpisodes,
        onEpisodeTap: (episode) => _playEpisode(episode, audioService),
        onEpisodeLongPress: (episode) => _showEpisodeOptions(episode),
        scrollController: _scrollController,
      ),
    );
  }

  /// Build unfinished episodes tab
  Widget _buildUnfinishedTab(
      ContentFacadeService contentService, AudioService audioService) {
    final unfinishedEpisodes = contentService.getUnfinishedEpisodes();

    if (unfinishedEpisodes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pending_actions,
              size: 80,
              color: AppTheme.onSurfaceColor.withOpacity(0.3),
            ),
            const SizedBox(height: AppTheme.spacingL),
            Text(
              'No Unfinished Episodes',
              style: AppTheme.headlineSmall.copyWith(
                color: AppTheme.onSurfaceColor.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'Episodes you\'ve started listening to will appear here',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.onSurfaceColor.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return AnimationLimiter(
      child: AudioList(
        episodes: unfinishedEpisodes,
        onEpisodeTap: (episode) => _playEpisode(episode, audioService),
        onEpisodeLongPress: (episode) => _showEpisodeOptions(episode),
        scrollController: _scrollController,
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
  Widget _buildErrorState(ContentFacadeService contentService) {
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
                color: AppTheme.onSurfaceColor.withOpacity(0.7),
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
  Widget _buildEmptyState(ContentFacadeService contentService) {
    return Center(
      child: Padding(
        padding: AppTheme.safePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.headphones_outlined,
              size: 80,
              color: AppTheme.onSurfaceColor.withOpacity(0.3),
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
                color: AppTheme.onSurfaceColor.withOpacity(0.7),
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
  Widget _buildMiniPlayer(BuildContext context, AudioService audioService) {
    return MiniPlayer(
      audioFile: audioService.currentAudioFile!,
      isPlaying: audioService.isPlaying,
      isPaused: audioService.isPaused,
      isLoading: audioService.isLoading,
      hasError: audioService.hasError,
      stateText: _getStateText(audioService),
      onTap: () => _navigateToPlayer(context),
      onPlayPause: () => audioService.togglePlayPause(),
      onNext: () => audioService.skipToNextEpisode(),
      onPrevious: () => audioService.skipToPreviousEpisode(),
    );
  }

  /// Helper method to get state text from AudioService
  String _getStateText(AudioService audioService) {
    if (audioService.hasError) {
      return 'Error';
    } else if (audioService.isLoading) {
      return 'Loading';
    } else if (audioService.isPlaying) {
      return 'Playing';
    } else if (audioService.isPaused) {
      return 'Paused';
    } else {
      return 'Stopped';
    }
  }

  /// Play episode
  void _playEpisode(AudioFile episode, AudioService audioService) {
    audioService.playAudio(episode);
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
      builder: (context) => _buildEpisodeOptionsSheet(episode),
    );
  }

  /// Build episode options bottom sheet
  Widget _buildEpisodeOptionsSheet(AudioFile episode) {
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
                color: AppTheme.onSurfaceColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const SizedBox(height: AppTheme.spacingL),

          // Episode info
          Text(
            episode.displayTitle,
            style: AppTheme.titleLarge,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: AppTheme.spacingS),

          Text(
            '${episode.categoryEmoji} ${episode.category} • ${episode.languageFlag} ${episode.language}',
            style: AppTheme.bodySmall,
          ),

          const SizedBox(height: AppTheme.spacingL),

          // Actions
          ListTile(
            leading: const Icon(Icons.play_arrow),
            title: const Text('Play'),
            onTap: () {
              Navigator.pop(context);
              _playEpisode(episode, context.read<AudioService>());
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
              context
                  .read<ContentFacadeService>()
                  .addToCurrentPlaylist(episode);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Added "${episode.displayTitle}" to playlist'),
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

  /// Build sort selector dropdown
  Widget _buildSortSelector(
      BuildContext context, ContentFacadeService contentService) {
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
            color: AppTheme.onSurfaceColor.withOpacity(0.6),
          ),
          const SizedBox(width: AppTheme.spacingS),
          Text(
            'Sort by:',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.onSurfaceColor.withOpacity(0.6),
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
                  color: AppTheme.onSurfaceColor.withOpacity(0.6),
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

  /// Navigate to full player screen
  void _navigateToPlayer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PlayerScreen(),
      ),
    );
  }
}
