import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../themes/app_theme.dart';
import '../../services/auth/auth_service.dart';
import '../../services/navigation_service.dart';

/// Minimal authentication screen with Apple and Google sign-in options
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    ));
  }

  void _startAnimations() {
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleAppleSignIn() async {
    final authService = context.read<AuthService>();
    final success = await authService.signInWithApple();
    
    if (success && mounted) {
      NavigationService.handleAuthSuccess(context);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final authService = context.read<AuthService>();
    final success = await authService.signInWithGoogle();
    
    if (success && mounted) {
      NavigationService.handleAuthSuccess(context);
    }
  }

  void _skipAuth() {
    NavigationService.handleAuthSkip(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Consumer<AuthService>(
          builder: (context, authService, child) {
            return Padding(
              padding: AppTheme.safePadding,
              child: Column(
                children: [
                  // Skip button (top right)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: authService.isLoading ? null : _skipAuth,
                        child: Text(
                          'Skip for now',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.onSurfaceColor.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Main content
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Column(
                              children: [
                                const Spacer(flex: 2),

                                // App logo/branding
                                _buildLogo(),

                                const SizedBox(height: AppTheme.spacingXL),

                                // Welcome text
                                _buildWelcomeText(),

                                const Spacer(flex: 3),

                                // Auth buttons
                                _buildAuthButtons(authService),

                                const SizedBox(height: AppTheme.spacingL),

                                // Error message
                                if (authService.errorMessage != null)
                                  _buildErrorMessage(authService.errorMessage!),

                                const Spacer(),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.podcasts_rounded,
          size: 50,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      children: [
        Text(
          'Welcome to',
          style: AppTheme.headlineMedium.copyWith(
            color: AppTheme.onSurfaceColor.withOpacity(0.8),
            fontWeight: FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: AppTheme.spacingXS),
        
        Text(
          'From Fed to Chain',
          style: AppTheme.headlineLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: AppTheme.spacingL),
        
        Text(
          'Sign in to sync your progress across devices and access personalized features.',
          style: AppTheme.bodyLarge.copyWith(
            color: AppTheme.onSurfaceColor.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAuthButtons(AuthService authService) {
    return Column(
      children: [
        // Apple Sign In Button
        _buildSignInButton(
          onPressed: authService.isLoading ? null : _handleAppleSignIn,
          icon: Icons.apple,
          text: 'Continue with Apple',
          backgroundColor: Colors.black,
          textColor: Colors.white,
          isLoading: authService.isLoading,
        ),
        
        const SizedBox(height: AppTheme.spacingM),
        
        // Google Sign In Button
        _buildSignInButton(
          onPressed: authService.isLoading ? null : _handleGoogleSignIn,
          icon: Icons.g_mobiledata_rounded,
          text: 'Continue with Google',
          backgroundColor: Colors.white,
          textColor: Colors.black87,
          borderColor: AppTheme.cardColor,
          isLoading: authService.isLoading,
        ),
        
        const SizedBox(height: AppTheme.spacingL),
        
        // Terms and privacy
        _buildTermsText(),
      ],
    );
  }

  Widget _buildSignInButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String text,
    required Color backgroundColor,
    required Color textColor,
    Color? borderColor,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 2,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            side: borderColor != null 
                ? BorderSide(color: borderColor, width: 1)
                : BorderSide.none,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 24,
                    color: textColor,
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Text(
                    text,
                    style: AppTheme.titleMedium.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTermsText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
      child: Text(
        'By continuing, you agree to our Terms of Service and Privacy Policy.',
        style: AppTheme.bodySmall.copyWith(
          color: AppTheme.onSurfaceColor.withOpacity(0.6),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      margin: const EdgeInsets.only(top: AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: AppTheme.errorColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 20,
            color: AppTheme.errorColor,
          ),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(
            child: Text(
              message,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.errorColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}