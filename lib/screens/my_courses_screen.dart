import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/content_service.dart';
import '../themes/app_theme.dart';
import '../widgets/animated_background.dart';
import '../widgets/course_card.dart';

class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContentService>().loadContent();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: Stack(
          children: [
            // Animated background
            const AnimatedBackground(),
            
            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Header
                  _buildHeader(),
                  
                  // Tab Bar
                  _buildTabBar(),
                  
                  // Content
                  Expanded(
                    child: _buildTabContent(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Text(
            'My Courses',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // TODO: Add learning stats
          _buildStatsChip(),
        ],
      ),
    );
  }

  Widget _buildStatsChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.purplePrimary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.school,
            size: 16,
            color: AppTheme.purplePrimary,
          ),
          const SizedBox(width: 4),
          Text(
            'Learning',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.purplePrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.textTertiary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(8),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        tabs: const [
          Tab(text: 'In Progress'),
          Tab(text: 'Completed'),
          Tab(text: 'Favorites'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return Consumer<ContentService>(
      builder: (context, contentService, child) {
        if (contentService.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppTheme.purplePrimary,
            ),
          );
        }

        if (contentService.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppTheme.error.withOpacity(0.7),
                ),
                const SizedBox(height: 16),
                Text(
                  'Error Loading Courses',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  contentService.error!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: contentService.loadContent,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return TabBarView(
          controller: _tabController,
          children: [
            _buildInProgressTab(contentService),
            _buildCompletedTab(contentService),
            _buildFavoritesTab(contentService),
          ],
        );
      },
    );
  }

  Widget _buildInProgressTab(ContentService contentService) {
    final audioFiles = contentService.audioFiles;
    
    return _buildCourseList(
      audioFiles: audioFiles,
      contentService: contentService,
      emptyMessage: 'No courses in progress',
      emptySubtitle: 'Start learning to see your progress here',
      emptyIcon: Icons.play_circle_outline,
    );
  }

  Widget _buildCompletedTab(ContentService contentService) {
    // TODO: Filter completed courses
    return _buildCourseList(
      audioFiles: [],
      contentService: contentService,
      emptyMessage: 'No completed courses',
      emptySubtitle: 'Complete courses to see them here',
      emptyIcon: Icons.check_circle_outline,
    );
  }

  Widget _buildFavoritesTab(ContentService contentService) {
    // TODO: Filter favorite courses
    return _buildCourseList(
      audioFiles: [],
      contentService: contentService,
      emptyMessage: 'No favorite courses',
      emptySubtitle: 'Heart courses to save them here',
      emptyIcon: Icons.favorite_outline,
    );
  }

  Widget _buildCourseList({
    required List audioFiles,
    required ContentService contentService,
    required String emptyMessage,
    required String emptySubtitle,
    required IconData emptyIcon,
  }) {
    if (audioFiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              emptyIcon,
              size: 64,
              color: AppTheme.textTertiary.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              emptySubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // TODO: Navigate to discover tab
              },
              child: const Text('Discover Courses'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: audioFiles.length,
      itemBuilder: (context, index) {
        final audioFile = audioFiles[index];
        final content = contentService.getContent(
          audioFile.id,
          audioFile.language,
        );
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CourseCard(
            audioFile: audioFile,
            content: content,
            showProgress: true, // Show progress for my courses
            onTap: () {
              // TODO: Navigate to course detail
            },
          ),
        );
      },
    );
  }
}