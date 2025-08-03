import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:audio_service/audio_service.dart';

import 'themes/app_theme.dart';
import 'services/background_audio_handler.dart';
import 'services/audio_service.dart' as local_audio;
import 'services/content_service.dart';
import 'screens/home_screen.dart';

/// Main application entry point
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
    print('✅ Environment variables loaded successfully');
  } catch (e) {
    print('⚠️ Warning: Could not load .env file: $e');
    print('📋 App will use default configuration');
  }

  // Configure system UI
  await _configureSystemUI();

  // Initialize audio service
  BackgroundAudioHandler? audioHandler;
  try {
    audioHandler = await AudioService.init(
      builder: () => BackgroundAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.fromfedtochain.audio',
        androidNotificationChannelName: 'From Fed to Chain Audio',
        androidNotificationChannelDescription:
            'Audio playback controls for From Fed to Chain content',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        androidNotificationIcon: 'drawable/ic_notification',
        fastForwardInterval: Duration(seconds: 30),
        rewindInterval: Duration(seconds: 10),
      ),
    );
    print('✅ Background audio service initialized successfully');
  } catch (e) {
    print('❌ Failed to initialize background audio service: $e');
    print('📱 App will use local audio player without background support');
    audioHandler = null;
  }

  runApp(FromFedToChainApp(audioHandler: audioHandler));
}

/// Configure system UI overlay and status bar
Future<void> _configureSystemUI() async {
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppTheme.backgroundColor,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  print('✅ System UI configured for dark theme');
}

/// Main application widget with provider setup
class FromFedToChainApp extends StatelessWidget {
  final BackgroundAudioHandler? audioHandler;

  const FromFedToChainApp({
    super.key,
    required this.audioHandler,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Content service (manages episodes and playlists)
        ChangeNotifierProvider(
          create: (_) => ContentService(),
        ),

        // Audio service (manages playback)
        ChangeNotifierProvider(
          create: (context) {
            final contentService = context.read<ContentService>();
            return local_audio.AudioService(audioHandler, contentService);
          },
        ),
      ],
      child: Consumer<ContentService>(
        builder: (context, contentService, child) {
          return MaterialApp(
            // App configuration
            title: 'From Fed to Chain',
            debugShowCheckedModeBanner: false,

            // Theme
            theme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,

            // Home screen
            home: const HomeScreen(),

            // App-wide configuration
            builder: (context, child) {
              return MediaQuery(
                // Ensure text scaling doesn't break layout
                data: MediaQuery.of(context).copyWith(
                  textScaleFactor:
                      MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2),
                ),
                child: child!,
              );
            },

            // Route generation (for future navigation)
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case '/':
                  return MaterialPageRoute(
                    builder: (_) => const HomeScreen(),
                  );
                default:
                  return MaterialPageRoute(
                    builder: (_) => const HomeScreen(),
                  );
              }
            },
          );
        },
      ),
    );
  }
}

/// Splash screen widget shown during app initialization
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));

    _animationController.forward();

    // Auto-navigate after animation
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App logo placeholder
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.headphones,
                        size: 60,
                        color: AppTheme.onPrimaryColor,
                      ),
                    ),

                    const SizedBox(height: AppTheme.spacingXL),

                    // App title
                    const Text(
                      'From Fed to Chain',
                      style: AppTheme.headlineLarge,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppTheme.spacingS),

                    // Subtitle
                    Text(
                      'Crypto & Macro Economics Audio',
                      style: AppTheme.bodyLarge.copyWith(
                        color: AppTheme.onSurfaceColor.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppTheme.spacingXXL),

                    // Loading indicator
                    const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Error boundary widget for handling uncaught exceptions
class ErrorBoundary extends StatelessWidget {
  final Widget child;
  final String? error;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
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
                  error!,
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.onSurfaceColor.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingXL),
                ElevatedButton(
                  onPressed: () {
                    // Restart app
                    SystemNavigator.pop();
                  },
                  child: const Text('Restart App'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return child;
  }
}
// Test commit
