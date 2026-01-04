import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:audio_service/audio_service.dart';

import 'package:from_fed_to_chain_app/core/services/services.dart';
import 'package:from_fed_to_chain_app/core/theme/theme.dart';
import 'package:from_fed_to_chain_app/features/audio/services/services.dart';
import 'package:from_fed_to_chain_app/features/content/services/services.dart';
import 'package:from_fed_to_chain_app/core/navigation/navigation_export.dart';
import 'package:from_fed_to_chain_app/features/app/index.dart';
import 'package:from_fed_to_chain_app/features/auth/index.dart';

/// Global navigator key for deep linking and navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Main application entry point
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LoggerService.initialize(enableLogging: kDebugMode);
  final log = LoggerService.getLogger('Main');

  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
    log.info('✅ Environment variables loaded successfully');
  } catch (e) {
    log.warning('⚠️ Warning: Could not load .env file: $e');
    log.info('📋 App will use default configuration');
  }

  // Configure system UI
  await _configureSystemUI();

  // Initialize deep linking service
  try {
    await DeepLinkService.initialize(navigatorKey);
    log.info('✅ Deep linking service initialized successfully');
  } catch (e) {
    log.warning('⚠️ Warning: Failed to initialize deep linking: $e');
    log.info('📱 App will continue without deep linking support');
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
    log.info('✅ Background audio service initialized successfully');
  } catch (e) {
    log.severe('❌ Failed to initialize background audio service: $e');
    log.info('📱 App will use local audio player without background support');
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

  final log = LoggerService.getLogger('SystemUI');
  log.info('✅ System UI configured for dark theme');
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

        // Content service (manages episodes and filters)
        ChangeNotifierProvider(
          create: (_) => ContentService(),
        ),

        // Playlist service (manages active queue)
        ChangeNotifierProvider(
          create: (_) => PlaylistService(),
        ),

        // Audio service (manages playbook)
        ChangeNotifierProvider(
          create: (context) {
            final contentService = context.read<ContentService>();
            final playlistService = context.read<PlaylistService>();
            return AudioPlayerService(
                audioHandler, contentService, playlistService);
          },
        ),
      ],
      child: Consumer<ContentService>(
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
