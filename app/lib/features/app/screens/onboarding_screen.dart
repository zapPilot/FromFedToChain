import 'package:flutter/material.dart';

import 'package:from_fed_to_chain_app/core/theme/app_theme.dart';
import 'package:from_fed_to_chain_app/core/navigation/navigation_service.dart';

/// Onboarding screen that introduces users to app features
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  static const int _totalPages = 3;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    if (mounted) {
      await NavigationService.completeOnboarding(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with skip button
            Padding(
              padding: AppTheme.safeHorizontalPadding,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button (only show after first page)
                  SizedBox(
                    width: 60,
                    child: _currentPage > 0
                        ? TextButton(
                            onPressed: _previousPage,
                            child: const Icon(
                              Icons.arrow_back_ios_rounded,
                              color: AppTheme.onSurfaceColor,
                            ),
                          )
                        : null,
                  ),

                  // Page indicator
                  Row(
                    children: List.generate(
                      _totalPages,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppTheme.primaryColor
                              : AppTheme.cardColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  // Skip button
                  SizedBox(
                    width: 60,
                    child: TextButton(
                      onPressed: _skipOnboarding,
                      child: Text(
                        'Skip',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.onSurfaceColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildPage1(),
                  _buildPage2(),
                  _buildPage3(),
                ],
              ),
            ),

            // Bottom navigation
            Padding(
              padding: AppTheme.safePadding,
              child: Row(
                children: [
                  // Progress indicator
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (_currentPage + 1) / _totalPages,
                      backgroundColor: AppTheme.cardColor,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryColor,
                      ),
                      minHeight: 4,
                    ),
                  ),

                  const SizedBox(width: AppTheme.spacingM),

                  // Next/Get Started button
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingL,
                        vertical: AppTheme.spacingM,
                      ),
                    ),
                    child: Text(
                      _currentPage == _totalPages - 1 ? 'Get Started' : 'Next',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage1() {
    return Padding(
      padding: AppTheme.safePadding,
      child: Column(
        children: [
          const Spacer(),

          // Illustration
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.1),
                  AppTheme.secondaryColor.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.headset_rounded,
                size: 80,
                color: AppTheme.primaryColor,
              ),
            ),
          ),

          const SizedBox(height: AppTheme.spacingXL),

          // Title
          const Text(
            'Stream Web3/Finance Content',
            style: AppTheme.headlineLarge,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppTheme.spacingL),

          // Description
          Text(
            'Listen to expertly curated explanations about cryptocurrency, economics, and blockchain technology in Chinese with English translations available.',
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.onSurfaceColor.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),

          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildPage2() {
    return Padding(
      padding: AppTheme.safePadding,
      child: Column(
        children: [
          const Spacer(),

          // Illustration
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.secondaryColor.withValues(alpha: 0.1),
                  AppTheme.primaryColor.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              border: Border.all(
                color: AppTheme.secondaryColor.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.category_rounded,
                size: 80,
                color: AppTheme.secondaryColor,
              ),
            ),
          ),

          const SizedBox(height: AppTheme.spacingXL),

          // Title
          const Text(
            'Organized by Topics',
            style: AppTheme.headlineLarge,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppTheme.spacingL),

          // Description
          Text(
            'Browse content organized by categories like DeFi, Ethereum, Macro Economics, Daily News, and Startup insights. Find exactly what interests you.',
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.onSurfaceColor.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),

          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildPage3() {
    return Padding(
      padding: AppTheme.safePadding,
      child: Column(
        children: [
          const Spacer(),

          // Illustration
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.warningColor.withValues(alpha: 0.1),
                  AppTheme.primaryColor.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              border: Border.all(
                color: AppTheme.warningColor.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.timeline_rounded,
                size: 80,
                color: AppTheme.warningColor,
              ),
            ),
          ),

          const SizedBox(height: AppTheme.spacingXL),

          // Title
          const Text(
            'Track Your Progress',
            style: AppTheme.headlineLarge,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppTheme.spacingL),

          // Description
          Text(
            'Keep track of your listening progress, create playlists, and resume where you left off. Your learning journey, organized and accessible.',
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.onSurfaceColor.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppTheme.spacingXL),

          // Features list
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            decoration: AppTheme.cardDecoration,
            child: Column(
              children: [
                _buildFeatureItem(
                  icon: Icons.offline_pin_rounded,
                  title: 'Offline Listening',
                  description: 'Download episodes for offline playback',
                ),
                const SizedBox(height: AppTheme.spacingM),
                _buildFeatureItem(
                  icon: Icons.speed_rounded,
                  title: 'Playback Speed',
                  description: 'Adjust speed from 0.5x to 2x',
                ),
                const SizedBox(height: AppTheme.spacingM),
                _buildFeatureItem(
                  icon: Icons.bookmark_rounded,
                  title: 'Bookmarks',
                  description: 'Save your favorite episodes',
                ),
              ],
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.titleMedium,
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: AppTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
