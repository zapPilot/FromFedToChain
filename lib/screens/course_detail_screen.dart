import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/audio_file.dart';
import '../models/audio_content.dart';
import '../services/audio_service.dart';
import '../services/content_service.dart';
import '../services/language_service.dart';
import '../themes/app_theme.dart';
import '../widgets/animated_background.dart';
import '../widgets/category_chip.dart';

class CourseDetailScreen extends StatefulWidget {
  final AudioFile audioFile;
  final AudioContent? content;

  const CourseDetailScreen({
    super.key,
    required this.audioFile,
    this.content,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final ScrollController _scrollController = ScrollController();
  bool _isHeaderCollapsed = false;
  AudioContent? _loadedContent;
  bool _isLoadingContent = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _scrollController.addListener(_onScroll);
    _animationController.forward();
    
    // Load content when screen initializes
    _loadContent();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    const double collapseOffset = 100.0;
    final bool shouldCollapse = _scrollController.offset > collapseOffset;
    
    if (shouldCollapse != _isHeaderCollapsed) {
      setState(() {
        _isHeaderCollapsed = shouldCollapse;
      });
    }
  }

  Future<void> _loadContent() async {
    if (_isLoadingContent) return;
    
    setState(() {
      _isLoadingContent = true;
    });
    
    try {
      final contentService = context.read<ContentService>();
      final content = await contentService.getContentWithFetch(
        widget.audioFile.id,
        widget.audioFile.language,
        widget.audioFile.category,
      );
      
      if (content != null && mounted) {
        setState(() {
          _loadedContent = content;
          _isLoadingContent = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoadingContent = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingContent = false;
        });
      }
    }
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
            CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Custom app bar
                _buildSliverAppBar(),
                
                // Course content
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _buildCourseContent(),
                    ),
                  ),
                ),
              ],
            ),
            
            // Audio player overlay
            _buildAudioPlayerOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300.0,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.surface.withOpacity(0.9),
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios,
          color: Colors.white,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.share,
            color: Colors.white,
          ),
          onPressed: _shareContent,
        ),
        IconButton(
          icon: Icon(
            Icons.favorite_border,
            color: Colors.white,
          ),
          onPressed: _toggleFavorite,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: AnimatedOpacity(
          opacity: _isHeaderCollapsed ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Text(
            _loadedContent?.title ?? widget.content?.title ?? widget.audioFile.id,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient background
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.categoryGradient(widget.audioFile.category),
              ),
            ),
            
            // Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            
            // Course info
            Positioned(
              bottom: 60,
              left: 20,
              right: 20,
              child: AnimatedOpacity(
                opacity: _isHeaderCollapsed ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.audioFile.categoryDisplayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Title
                    Text(
                      _loadedContent?.title ?? widget.content?.title ?? widget.audioFile.id,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Author and date
                    Row(
                      children: [
                        Text(
                          _loadedContent?.author ?? widget.content?.author ?? 'David Chang',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.audioFile.displayDate,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Play button
          _buildPlayButton(),
          
          const SizedBox(height: 24),
          
          // Course info
          _buildCourseInfo(),
          
          const SizedBox(height: 24),
          
          // Language selection
          _buildLanguageSection(),
          
          const SizedBox(height: 24),
          
          // Loading state
          if (_isLoadingContent) ...[
            _buildSectionTitle('Loading Content...'),
            const SizedBox(height: 12),
            const Center(
              child: CircularProgressIndicator(),
            ),
            const SizedBox(height: 24),
          ],
          
          // Description
          if (_loadedContent?.content != null || widget.content?.content != null) ...[
            _buildSectionTitle('Description'),
            const SizedBox(height: 12),
            _buildDescription(),
            const SizedBox(height: 24),
          ],
          
          // References
          if (_loadedContent?.references.isNotEmpty == true || widget.content?.references.isNotEmpty == true) ...[
            _buildSectionTitle('References'),
            const SizedBox(height: 12),
            _buildReferences(),
            const SizedBox(height: 24),
          ],
          
          // Social hook
          if (_loadedContent?.socialHook != null || widget.content?.socialHook != null) ...[
            _buildSectionTitle('Social Hook'),
            const SizedBox(height: 12),
            _buildSocialHook(),
            const SizedBox(height: 24),
          ],
          
          // Extra space for bottom player
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildPlayButton() {
    return Consumer<AudioService>(
      builder: (context, audioService, child) {
        final isCurrentFile = audioService.currentAudioFile?.id == widget.audioFile.id;
        final isPlaying = isCurrentFile && audioService.isPlaying;
        final isLoading = isCurrentFile && audioService.isLoading;
        
        return Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppTheme.purplePrimary.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () {
                if (isPlaying) {
                  audioService.pause();
                } else if (isCurrentFile && audioService.isPaused) {
                  audioService.resume();
                } else {
                  audioService.playAudio(widget.audioFile);
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else
                    Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 24,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    isPlaying ? 'Pause' : 'Play Episode',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCourseInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textTertiary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildInfoRow('Language', widget.audioFile.languageDisplayName),
          const SizedBox(height: 12),
          _buildInfoRow('Category', widget.audioFile.categoryDisplayName),
          const SizedBox(height: 12),
          if (widget.audioFile.duration != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow('Duration', widget.audioFile.durationFormatted),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textTertiary,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildDescription() {
    final content = _loadedContent?.content ?? widget.content?.content;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        content ?? 'No content available',
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 16,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildReferences() {
    final references = _loadedContent?.references ?? widget.content?.references ?? [];
    
    return Column(
      children: references.map((reference) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surface.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.link,
                color: AppTheme.textTertiary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  reference,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSocialHook() {
    final socialHook = _loadedContent?.socialHook ?? widget.content?.socialHook;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accent.withOpacity(0.1),
            AppTheme.accent.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.accent.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.share,
            color: AppTheme.accent,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              socialHook ?? 'No social hook available',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPlayerOverlay() {
    return Consumer<AudioService>(
      builder: (context, audioService, child) {
        final isCurrentFile = audioService.currentAudioFile?.id == widget.audioFile.id;
        
        if (!isCurrentFile || audioService.isIdle) {
          return const SizedBox.shrink();
        }
        
        return Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface.withOpacity(0.95),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress bar
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    ),
                    child: Slider(
                      value: audioService.progress,
                      onChanged: (value) {
                        final position = Duration(
                          milliseconds: (value * audioService.totalDuration.inMilliseconds).toInt(),
                        );
                        audioService.seekTo(position);
                      },
                      activeColor: AppTheme.purplePrimary,
                      inactiveColor: AppTheme.textTertiary.withOpacity(0.3),
                    ),
                  ),
                  
                  // Time indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        audioService.formattedCurrentPosition,
                        style: TextStyle(
                          color: AppTheme.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        audioService.formattedTotalDuration,
                        style: TextStyle(
                          color: AppTheme.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.replay_10),
                        color: AppTheme.textSecondary,
                        onPressed: () => audioService.skipBackward(const Duration(seconds: 10)),
                      ),
                      
                      // Play/Pause button
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: IconButton(
                          icon: Icon(
                            audioService.isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: () {
                            if (audioService.isPlaying) {
                              audioService.pause();
                            } else {
                              audioService.resume();
                            }
                          },
                        ),
                      ),
                      
                      IconButton(
                        icon: const Icon(Icons.forward_30),
                        color: AppTheme.textSecondary,
                        onPressed: () => audioService.skipForward(const Duration(seconds: 30)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageSection() {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Available Languages'),
            const SizedBox(height: 12),
            
            // Current language indicator
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.purplePrimary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.language,
                    color: AppTheme.purplePrimary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Language',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textTertiary,
                        ),
                      ),
                      Text(
                        '${languageService.getLanguageFlag(languageService.currentLanguage)} ${languageService.getLanguageDisplayName(languageService.currentLanguage)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _showLanguageSelectionModal,
                    child: Text(
                      'Change',
                      style: TextStyle(
                        color: AppTheme.purplePrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Available languages chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: languageService.availableLanguages.map((language) {
                  final isSelected = language['code'] == languageService.currentLanguage;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: CategoryChip(
                      label: '${language['flag']} ${language['name']}',
                      isSelected: isSelected,
                      onTap: () => _changeLanguage(language['code']!),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLanguageSelectionModal() {
    final languageService = context.read<LanguageService>();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textTertiary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Select Language',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            
            // Language list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: languageService.availableLanguages.length,
                itemBuilder: (context, index) {
                  final language = languageService.availableLanguages[index];
                  final isSelected = language['code'] == languageService.currentLanguage;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.of(context).pop();
                          _changeLanguage(language['code']!);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected 
                              ? AppTheme.purplePrimary.withOpacity(0.1)
                              : AppTheme.background.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected 
                                ? AppTheme.purplePrimary
                                : AppTheme.textTertiary.withOpacity(0.2),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                language['flag'] ?? '🌐',
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      language['name'] ?? '',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: AppTheme.textPrimary,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                      ),
                                    ),
                                    Text(
                                      language['code'] ?? '',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppTheme.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: AppTheme.purplePrimary,
                                  size: 24,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeLanguage(String languageCode) async {
    try {
      final languageService = context.read<LanguageService>();
      await languageService.setLanguage(languageCode);
      
      // Refresh content for new language
      _loadContent();
      
      // Show feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Language changed to ${languageService.getLanguageDisplayName(languageCode)}'),
            backgroundColor: AppTheme.purplePrimary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error changing language: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _shareContent() {
    // TODO: Implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing feature coming soon!')),
    );
  }

  void _toggleFavorite() {
    // TODO: Implement favorites functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Favorites feature coming soon!')),
    );
  }
}