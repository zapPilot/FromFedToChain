import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'services/content_service.dart';
import 'services/audio_service.dart';
import 'services/auth_service.dart';
import 'providers/content_provider.dart';
import 'providers/audio_provider.dart';
import 'providers/auth_provider.dart';
import 'themes/app_theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final contentService = ContentService();
  final audioService = AudioPlayerService();
  final authService = AuthService();

  // Initialize auth service
  await authService.initialize();

  runApp(MyApp(
    contentService: contentService,
    audioService: audioService,
    authService: authService,
  ));
}

class MyApp extends StatelessWidget {
  final ContentService contentService;
  final AudioPlayerService audioService;
  final AuthService authService;

  const MyApp({
    super.key,
    required this.contentService,
    required this.audioService,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService),
        ),
        ChangeNotifierProvider(
          create: (_) => ContentProvider(contentService),
        ),
        ChangeNotifierProvider(
          create: (_) => AudioProvider(audioService),
        ),
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
