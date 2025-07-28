import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:audio_service/audio_service.dart' as audio_service_pkg;
import 'screens/splash_screen.dart';
import 'services/audio_service.dart';
import 'services/background_audio_handler.dart';
import 'services/content_service.dart';
import 'services/auth_service.dart';
import 'services/language_service.dart';
import 'themes/app_theme.dart';
import 'package:mcp_toolkit/mcp_toolkit.dart';

Future<void> main() async {
  // Flutter initialize
  WidgetsFlutterBinding.ensureInitialized();

  // load .env
  await dotenv.load(fileName: '.env');

  // initialize MCP Toolkit
  MCPToolkitBinding.instance
    ..initialize()
    ..initializeFlutterToolkit();

  // Initialize audio service for background playback
  print('🚀 Initializing audio service...');

  BackgroundAudioHandler? audioHandler;
  try {
    final handler = await audio_service_pkg.AudioService.init(
      builder: () => BackgroundAudioHandler(),
      config: audio_service_pkg.AudioServiceConfig(
        androidNotificationChannelId:
            'com.example.from_fed_to_chain_audio.channel.audio',
        androidNotificationChannelName: 'From Fed to Chain Audio',
        androidNotificationOngoing: true,
        androidNotificationIcon: 'drawable/ic_notification',
        androidShowNotificationBadge: true,
        androidStopForegroundOnPause: false, // Keep service alive when paused
      ),
    );

    audioHandler = handler;

    print('✅ Audio service initialized successfully');
  } catch (e) {
    print('❌ Audio service initialization failed: $e');
    // Continue without background audio support
  }

  // use runZonedGuarded to capture exceptions
  runZonedGuarded(
    () => runApp(FromFedToChainApp(audioHandler: audioHandler)),
    (error, stack) => MCPToolkitBinding.instance.handleZoneError(error, stack),
  );
}

class FromFedToChainApp extends StatelessWidget {
  final BackgroundAudioHandler? audioHandler;

  const FromFedToChainApp({super.key, this.audioHandler});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageService()),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProxyProvider<LanguageService, ContentService>(
          create: (context) => ContentService(context.read<LanguageService>()),
          update: (context, languageService, contentService) =>
              contentService ?? ContentService(languageService),
        ),
        ChangeNotifierProxyProvider<ContentService, AudioService>(
          create: (context) =>
              AudioService(audioHandler, context.read<ContentService>()),
          update: (context, contentService, audioService) =>
              audioService ?? AudioService(audioHandler, contentService),
        ),
      ],
      child: MaterialApp(
        title: 'From Fed to Chain Learning',
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
