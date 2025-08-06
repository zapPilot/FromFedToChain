import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
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
