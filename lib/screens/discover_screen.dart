import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/content_service.dart';
import '../themes/app_theme.dart';
import '../widgets/animated_background.dart';
import '../widgets/course_card.dart';
import '../widgets/author_card.dart';
import '../widgets/category_chip.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContentService>().loadContent();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
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
                  
                  // Search Bar
                  _buildSearchBar(),
                  
                  // Content
                  Expanded(
                    child: _buildContent(),
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
            'Discover',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              // TODO: Implement filter
            },
            icon: const Icon(Icons.tune),
            color: AppTheme.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.textTertiary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
            context.read<ContentService>().setSearchQuery(value);
          },
          decoration: InputDecoration(
            hintText: 'Search courses, authors...',
            prefixIcon: Icon(
              Icons.search,
              color: AppTheme.textTertiary.withOpacity(0.7),
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: AppTheme.textTertiary.withOpacity(0.7),
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                      context.read<ContentService>().setSearchQuery('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            hintStyle: TextStyle(
              color: AppTheme.textTertiary.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
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
                  'Error Loading Content',
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

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Categories
              _buildCategoriesSection(contentService),
              
              const SizedBox(height: 24),
              
              // Featured Authors
              _buildFeaturedAuthorsSection(),
              
              const SizedBox(height: 24),
              
              // All Courses
              _buildAllCoursesSection(contentService),
              
              const SizedBox(height: 100), // Extra space for mini player
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoriesSection(ContentService contentService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categories',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              CategoryChip(
                label: 'All',
                isSelected: contentService.selectedCategory == null,
                onTap: () => contentService.setCategoryFilter(null),
              ),
              ...contentService.availableCategories.map((category) =>
                CategoryChip(
                  label: _getCategoryDisplayName(category),
                  isSelected: contentService.selectedCategory == category,
                  onTap: () => contentService.setCategoryFilter(category),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedAuthorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Featured Authors',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 1, // Show only David Chang
            itemBuilder: (context, index) {
              return const Padding(
                padding: EdgeInsets.only(right: 12),
                child: AuthorCard(
                  authorName: 'David Chang',
                  authorBio: 'Crypto and macro economics educator',
                  subscriberCount: 1000,
                  isSubscribed: false,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAllCoursesSection(ContentService contentService) {
    final audioFiles = contentService.audioFiles;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'All Courses',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        if (audioFiles.isEmpty)
          Container(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.music_off,
                    size: 48,
                    color: AppTheme.textTertiary.withOpacity(0.7),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No courses found',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
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
                  onTap: () {
                    // TODO: Navigate to course detail
                  },
                ),
              );
            },
          ),
      ],
    );
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'daily-news':
        return 'Daily News';
      case 'ethereum':
        return 'Ethereum';
      case 'macro':
        return 'Macro';
      case 'startup':
        return 'Startup';
      case 'ai':
        return 'AI';
      case 'defi':
        return 'DeFi';
      default:
        return category.toUpperCase();
    }
  }
}