import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/content_service.dart';
import '../services/audio_service.dart';
import '../models/audio_file.dart';
import '../widgets/animated_background.dart';
import '../widgets/course_card.dart';
import '../widgets/author_card.dart';
import '../themes/app_theme.dart';
import 'course_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContentService>().loadContent();
    });
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
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.surface.withOpacity(0.3),
            Colors.transparent,
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          ShaderMask(
            shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
            child: Text(
              'Good ${_getGreeting()},',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ready to learn something new?',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          // Stats row
          Row(
            children: [
              _buildStatCard('12', 'Episodes', AppTheme.purplePrimary),
              const SizedBox(width: 16),
              _buildStatCard('5', 'Categories', AppTheme.bluePrimary),
              const SizedBox(width: 16),
              _buildStatCard('3', 'Languages', AppTheme.accent),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatCard(String number, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              number,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: AppTheme.textTertiary,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
              // Continue Learning
              _buildContinueLearningSection(contentService),
              
              const SizedBox(height: 32),
              
              // Featured Course
              _buildFeaturedCourseSection(contentService),
              
              const SizedBox(height: 32),
              
              // New Releases
              _buildNewReleasesSection(contentService),
              
              const SizedBox(height: 32),
              
              // Trending Authors
              _buildTrendingAuthorsSection(),
              
              const SizedBox(height: 100), // Extra space for mini player
            ],
          ),
        );
      },
    );
  }

  Widget _buildContinueLearningSection(ContentService contentService) {
    final audioFiles = contentService.audioFiles.take(2).toList();
    
    if (audioFiles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Continue Learning',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                // TODO: Navigate to My Courses
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: audioFiles.length,
            itemBuilder: (context, index) {
              final audioFile = audioFiles[index];
              final content = contentService.getContent(
                audioFile.id,
                audioFile.language,
              );
              
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 12),
                child: CourseCard(
                  audioFile: audioFile,
                  content: content,
                  isHorizontal: true,
                  showProgress: true,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CourseDetailScreen(
                          audioFile: audioFile,
                          content: content,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedCourseSection(ContentService contentService) {
    final audioFiles = contentService.audioFiles;
    
    if (audioFiles.isEmpty) {
      return const SizedBox.shrink();
    }

    final featuredCourse = audioFiles.first;
    final content = contentService.getContent(
      featuredCourse.id,
      featuredCourse.language,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Featured Course',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 220,
          decoration: BoxDecoration(
            gradient: AppTheme.featuredGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.purplePrimary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: AppTheme.purplePrimary.withOpacity(0.1),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background pattern
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.glassmorphismGradient,
                    ),
                  ),
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Featured badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'FEATURED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Title
                    Text(
                      content?.title ?? featuredCourse.id,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Subtitle
                    Text(
                      '${featuredCourse.categoryDisplayName} • ${featuredCourse.languageDisplayName}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Play button
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<AudioService>().playAudio(featuredCourse);
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Learning'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.purplePrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNewReleasesSection(ContentService contentService) {
    final audioFiles = contentService.audioFiles.take(5).toList();
    
    if (audioFiles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'New Releases',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                // TODO: Navigate to Discover
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: audioFiles.length,
            itemBuilder: (context, index) {
              final audioFile = audioFiles[index];
              final content = contentService.getContent(
                audioFile.id,
                audioFile.language,
              );
              
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 12),
                child: CourseCard(
                  audioFile: audioFile,
                  content: content,
                  isVertical: true,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CourseDetailScreen(
                          audioFile: audioFile,
                          content: content,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingAuthorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trending Authors',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3, // Mock data
            itemBuilder: (context, index) {
              return const Padding(
                padding: EdgeInsets.only(right: 12),
                child: AuthorCard(
                  authorName: 'Coming Soon',
                  authorBio: 'Author profiles will be available soon',
                  subscriberCount: 0,
                  isSubscribed: false,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'morning';
    } else if (hour < 17) {
      return 'afternoon';
    } else {
      return 'evening';
    }
  }
}