import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../themes/app_theme.dart';
import '../services/content_service.dart';
import '../services/audio_service.dart';
import '../models/audio_file.dart';
import '../widgets/filter_bar.dart';
import '../widgets/audio_list.dart';
import '../widgets/mini_player.dart';
import '../widgets/search_bar.dart';
import 'player_screen.dart';

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
      body: Consumer2<ContentService, AudioService>(
        builder: (context, contentService, audioService, child) {
          return SafeArea(
            child: Column(
              children: [
                // App header with search toggle
                _buildAppHeader(context, contentService),

                // Search bar (animated)
                if (_showSearchBar) _buildSearchBar(context, contentService),

                // Filter bar
                _buildFilterBar(context, contentService),

                // Main content area
                Expanded(
                  child:
                      _buildMainContent(context, contentService, audioService),
                ),

                // Mini player (if audio is playing)
                if (audioService.currentAudioFile != null)
                  _buildMiniPlayer(context, audioService),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Build app header with title and search toggle
  Widget _buildAppHeader(BuildContext context, ContentService contentService) {
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
                Consumer<ContentService>(
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
    AudioService audioService,
  ) {
    if (contentService.isLoading && !contentService.hasEpisodes) {
      return _buildLoadingState();
    }

    if (contentService.hasError) {
      return _buildErrorState(contentService);
    }

    if (!contentService.hasFilteredResults) {
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
              Tab(text: 'Favorites'),
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
              _buildFavoritesTab(contentService, audioService),
            ],
          ),
        ),
      ],
    );
  }

  /// Build recent episodes tab
  Widget _buildRecentTab(
      ContentService contentService, AudioService audioService) {
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
      ContentService contentService, AudioService audioService) {
    return AnimationLimiter(
      child: AudioList(
        episodes: contentService.filteredEpisodes,
        onEpisodeTap: (episode) => _playEpisode(episode, audioService),
        onEpisodeLongPress: (episode) => _showEpisodeOptions(episode),
        scrollController: _scrollController,
      ),
    );
  }

  /// Build favorites tab (placeholder)
  Widget _buildFavoritesTab(
      ContentService contentService, AudioService audioService) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: AppTheme.onSurfaceColor.withOpacity(0.3),
          ),
          const SizedBox(height: AppTheme.spacingL),
          Text(
            'No Favorites Yet',
            style: AppTheme.headlineSmall.copyWith(
              color: AppTheme.onSurfaceColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'Long press episodes to add them to favorites',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.onSurfaceColor.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
            Icon(
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
      playbackState: audioService.playbackState,
      onTap: () => _navigateToPlayer(context),
      onPlayPause: () => audioService.togglePlayPause(),
      onNext: () => audioService.skipToNextEpisode(),
      onPrevious: () => audioService.skipToPreviousEpisode(),
    );
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
              context.read<ContentService>().addToCurrentPlaylist(episode);
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

  /// Navigate to full player screen
  void _navigateToPlayer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PlayerScreen(),
      ),
    );
  }
}
