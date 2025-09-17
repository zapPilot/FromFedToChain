import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../themes/app_theme.dart';
import '../services/content_facade_service.dart';
import '../services/auth/auth_service.dart';
import '../services/navigation_service.dart';
import '../screens/onboarding/onboarding_screen.dart';

/// Splash screen that displays app branding while initializing services
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _progressController;

  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<double> _progressAnimation;

  String _loadingText = 'Initializing...';
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Text animation controller
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Progress animation controller
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Logo scale animation
    _logoScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    // Logo opacity animation
    _logoOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    // Text opacity animation
    _textOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    ));

    // Progress animation
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    // Start logo animation immediately
    _logoController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      // Start text animation after a delay
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          _textController.forward();
        }
      });

      // Start progress animation
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          _progressController.forward();
        }
      });

      // Initialize content service
      setState(() => _loadingText = 'Loading content...');
      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        await context.read<ContentFacadeService>().loadAllEpisodes();
      }

      // Initialize audio service
      setState(() => _loadingText = 'Setting up audio...');
      await Future.delayed(const Duration(milliseconds: 500));

      // Simulate additional initialization
      setState(() => _loadingText = 'Almost ready...');
      await Future.delayed(const Duration(milliseconds: 700));

      // Determine which screen to show next
      if (mounted) {
        setState(() => _loadingText = 'Ready!');
        await Future.delayed(const Duration(milliseconds: 300));

        await _navigateToNextScreen();
      }
    } catch (error) {
      if (kDebugMode) {
        print('❌ Splash screen initialization error: $error');
      }

      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to initialize app';
          _loadingText = 'Error occurred';
        });
      }
    }
  }

  Future<void> _navigateToNextScreen() async {
    try {
      final authService = context.read<AuthService>();
      final nextScreen = await NavigationService.getInitialScreen(
        authService: authService,
      );

      if (mounted) {
        NavigationService.navigateAndClearStack(
          context,
          nextScreen,
          duration: const Duration(milliseconds: 600),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Navigation error: $e');
      }
      // Fallback to onboarding screen
      if (mounted) {
        NavigationService.navigateAndClearStack(
          context,
          const OnboardingScreen(),
        );
      }
    }
  }

  void _retryInitialization() {
    setState(() {
      _hasError = false;
      _errorMessage = null;
      _loadingText = 'Retrying...';
    });

    // Reset animations
    _logoController.reset();
    _textController.reset();
    _progressController.reset();

    // Restart initialization
    _logoController.forward();
    _initializeApp();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: AppTheme.safePadding,
          child: Column(
            children: [
              // Spacer to center content
              const Spacer(flex: 2),

              // Logo section
              AnimatedBuilder(
                animation: _logoController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _logoScaleAnimation.value,
                    child: Opacity(
                      opacity: _logoOpacityAnimation.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusXL),
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.podcasts_rounded,
                            size: 60,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: AppTheme.spacingL),

              // App name
              AnimatedBuilder(
                animation: _textController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _textOpacityAnimation.value,
                    child: Column(
                      children: [
                        Text(
                          'From Fed to Chain',
                          style: AppTheme.headlineMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppTheme.spacingXS),
                        Text(
                          'Chinese Crypto & Economics Explained',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.onSurfaceColor.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),

              const Spacer(flex: 3),

              // Loading section
              if (_hasError) _buildErrorSection() else _buildLoadingSection(),

              const SizedBox(height: AppTheme.spacingXXL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSection() {
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, child) {
        return Opacity(
          opacity: _textOpacityAnimation.value,
          child: Column(
            children: [
              // Loading text
              Text(
                _loadingText,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.onSurfaceColor.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppTheme.spacingM),

              // Progress indicator
              SizedBox(
                width: 200,
                child: AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return LinearProgressIndicator(
                      value: _progressAnimation.value,
                      backgroundColor: AppTheme.cardColor,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryColor,
                      ),
                      minHeight: 3,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorSection() {
    return Column(
      children: [
        Icon(
          Icons.error_outline_rounded,
          size: 48,
          color: AppTheme.errorColor,
        ),
        const SizedBox(height: AppTheme.spacingM),
        Text(
          _errorMessage ?? 'Something went wrong',
          style: AppTheme.bodyLarge.copyWith(
            color: AppTheme.errorColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacingL),
        ElevatedButton(
          onPressed: _retryInitialization,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.errorColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Retry'),
        ),
      ],
    );
  }
}
