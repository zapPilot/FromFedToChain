import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:audio_service/audio_service.dart';

import 'themes/app_theme.dart';
import 'services/background_audio_handler.dart';
import 'services/audio_service.dart' as local_audio;
import 'services/content_facade_service.dart';
import 'services/deep_link_service.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/auth_screen.dart';
import 'services/auth/auth_service.dart';
import 'screens/auth/login_screen.dart';

/// Global navigator key for deep linking and navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Main application entry point
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
    if (kDebugMode) {
      print('✅ Environment variables loaded successfully');
    }
  } catch (e) {
    if (kDebugMode) {
      print('⚠️ Warning: Could not load .env file: $e');
      print('📋 App will use default configuration');
    }
  }

  // Configure system UI
  await _configureSystemUI();

  // Initialize deep linking service
  try {
    await DeepLinkService.initialize(navigatorKey);
    if (kDebugMode) {
      print('✅ Deep linking service initialized successfully');
    }
  } catch (e) {
    if (kDebugMode) {
      print('⚠️ Warning: Failed to initialize deep linking: $e');
      print('📱 App will continue without deep linking support');
    }
  }

  // Initialize audio service
  BackgroundAudioHandler? audioHandler;
  try {
    audioHandler = await AudioService.init(
      builder: () => BackgroundAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.fromfedtochain.audio',
        androidNotificationChannelName: 'From Fed to Chain Audio',
        androidNotificationChannelDescription:
            'Audio playbook controls for From Fed to Chain content',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        androidNotificationIcon: 'drawable/ic_notification',
        fastForwardInterval: Duration(seconds: 30),
        rewindInterval: Duration(seconds: 10),
      ),
    );
    if (kDebugMode) {
      print('✅ Background audio service initialized successfully');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Failed to initialize background audio service: $e');
      print('📱 App will use local audio player without background support');
    }
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

  if (kDebugMode) {
    print('✅ System UI configured for dark theme');
  }
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
        // Auth service (initialize first)
        ChangeNotifierProvider(
          create: (_) => AuthService()..initialize(),
        ),

        // Content service (manages episodes and playlists) - using new modular architecture
        ChangeNotifierProvider(
          create: (_) => ContentFacadeService(),
        ),

        // Audio service (manages playbook)
        ChangeNotifierProvider(
          create: (context) {
            final contentService = context.read<ContentFacadeService>();
            return local_audio.AudioService(audioHandler, contentService);
          },
        ),
      ],
      child: Consumer<ContentFacadeService>(
        builder: (context, contentService, child) {
          return MaterialApp(
            // App configuration
            title: 'From Fed to Chain',
            debugShowCheckedModeBanner: false,
            navigatorKey: navigatorKey,

            // Theme
            theme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,

            // Start with authentication check
            home: Consumer<AuthService>(
              builder: (context, authService, child) {
                if (authService.isAuthenticated) {
                  return const MainNavigationScreen();
                } else {
                  return const LoginScreen();
                }
              },
            ),

            // App-wide configuration
            builder: (context, child) {
              return MediaQuery(
                // Ensure text scaling doesn't break layout
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(MediaQuery.of(context)
                      .textScaler
                      .scale(1.0)
                      .clamp(0.8, 1.2)),
                ),
                child: child!,
              );
            },

            // Route generation for navigation
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case '/':
                  return MaterialPageRoute(
                    builder: (_) => const SplashScreen(),
                  );
                case '/onboarding':
                  return MaterialPageRoute(
                    builder: (_) => const OnboardingScreen(),
                  );
                case '/auth':
                  return MaterialPageRoute(
                    builder: (_) => const AuthScreen(),
                  );
                case '/login':
                  return MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  );
                case '/home':
                  return MaterialPageRoute(
                    builder: (_) => const MainNavigationScreen(),
                  );
                default:
                  return MaterialPageRoute(
                    builder: (_) => const SplashScreen(),
                  );
              }
            },
          );
        },
      ),
    );
  }
}
