import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/main_screen.dart';
import 'services/audio_service.dart';
import 'services/content_service.dart';
import 'services/auth_service.dart';
import 'themes/app_theme.dart';

void main() {
  runApp(const FromFedToChainApp());
}

class FromFedToChainApp extends StatelessWidget {
  const FromFedToChainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => AudioService()),
        ChangeNotifierProvider(create: (_) => ContentService()),
      ],
      child: MaterialApp(
        title: 'From Fed to Chain Learning',
        theme: AppTheme.darkTheme,
        home: const MainScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}