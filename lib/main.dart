import 'dart:async';                    
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/main_screen.dart';
import 'services/audio_service.dart';
import 'services/content_service.dart';
import 'services/auth_service.dart';
import 'themes/app_theme.dart';
import 'package:mcp_toolkit/mcp_toolkit.dart';

Future<void> main() async {
  // Flutter initialize
  WidgetsFlutterBinding.ensureInitialized();

  // load .env
  await dotenv.load(fileName: ".env");

  // initialize MCP Toolkit
  MCPToolkitBinding.instance
    ..initialize()
    ..initializeFlutterToolkit();

  // use runZonedGuarded to capture exceptions
  runZonedGuarded(
    () => runApp(const FromFedToChainApp()),
    (error, stack) =>
        MCPToolkitBinding.instance.handleZoneError(error, stack),
  );
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