import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:uni_links/uni_links.dart';

import '../screens/player_screen.dart';
import '../models/audio_content.dart';
import 'content_service.dart';

/// Service to handle deep links and app navigation from external sources
class DeepLinkService {
  static StreamSubscription<String?>? _linkStreamSubscription;
  static GlobalKey<NavigatorState>? _navigatorKey;
  
  /// Initialize deep link handling
  /// [navigatorKey] should be the global navigator key from MaterialApp
  static Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    _navigatorKey = navigatorKey;
    
    try {
      // Handle initial link when app is launched from closed state
      final initialLink = await getInitialLink();
      if (initialLink != null) {
        developer.log('Initial deep link received: $initialLink', name: 'DeepLinkService');
        await _handleDeepLink(initialLink);
      }
    } catch (e) {
      developer.log('Error getting initial link: $e', name: 'DeepLinkService');
    }
    
    // Handle links when app is already running
    _linkStreamSubscription = linkStream.listen(
      (String? link) {
        if (link != null) {
          developer.log('Deep link received: $link', name: 'DeepLinkService');
          _handleDeepLink(link);
        }
      },
      onError: (err) {
        developer.log('Deep link stream error: $err', name: 'DeepLinkService');
      },
    );
  }
  
  /// Handle incoming deep links
  static Future<void> _handleDeepLink(String link) async {
    try {
      final uri = Uri.parse(link);
      developer.log('Parsing deep link URI: $uri', name: 'DeepLinkService');
      
      // Handle our custom scheme: fromfedtochain://
      if (uri.scheme == 'fromfedtochain') {
        await _handleCustomSchemeLink(uri);
      }
      // Handle universal links: https://fromfedtochain.com/
      else if (uri.scheme == 'https' && uri.host == 'fromfedtochain.com') {
        await _handleUniversalLink(uri);
      }
      else {
        developer.log('Unhandled deep link scheme: ${uri.scheme}', name: 'DeepLinkService');
      }
    } catch (e) {
      developer.log('Error handling deep link: $e', name: 'DeepLinkService');
    }
  }
  
  /// Handle custom scheme links: fromfedtochain://audio/content-id
  static Future<void> _handleCustomSchemeLink(Uri uri) async {
    if (uri.pathSegments.isEmpty) {
      // Navigate to home screen if no specific path
      _navigateToHome();
      return;
    }
    
    final firstSegment = uri.pathSegments[0];
    
    switch (firstSegment) {
      case 'audio':
        if (uri.pathSegments.length > 1) {
          final audioId = uri.pathSegments[1];
          await _navigateToAudio(audioId);
        } else {
          developer.log('Audio deep link missing content ID', name: 'DeepLinkService');
          _navigateToHome();
        }
        break;
      case 'home':
        _navigateToHome();
        break;
      default:
        developer.log('Unknown deep link path: $firstSegment', name: 'DeepLinkService');
        _navigateToHome();
    }
  }
  
  /// Handle universal links: https://fromfedtochain.com/audio/content-id
  static Future<void> _handleUniversalLink(Uri uri) async {
    // Universal links use the same path structure as custom scheme
    await _handleCustomSchemeLink(uri);
  }
  
  /// Navigate to specific audio content
  static Future<void> _navigateToAudio(String contentId) async {
    if (_navigatorKey?.currentContext == null) {
      developer.log('Navigator context not available', name: 'DeepLinkService');
      return;
    }
    
    try {
      // Load the content to verify it exists
      final content = await ContentService.getContentById(contentId);
      if (content == null) {
        developer.log('Content not found for ID: $contentId', name: 'DeepLinkService');
        _showContentNotFoundDialog(contentId);
        return;
      }
      
      // Navigate to player screen - the screen will handle loading the content
      _navigatorKey!.currentState!.push(
        MaterialPageRoute(
          builder: (context) => const PlayerScreen(),
        ),
      );
      
      developer.log('Navigated to audio content: $contentId', name: 'DeepLinkService');
    } catch (e) {
      developer.log('Error navigating to audio content: $e', name: 'DeepLinkService');
      _showErrorDialog('Failed to load audio content');
    }
  }
  
  /// Navigate to home screen
  static void _navigateToHome() {
    if (_navigatorKey?.currentContext == null) {
      developer.log('Navigator context not available for home navigation', name: 'DeepLinkService');
      return;
    }
    
    // Pop all routes and go to home (if not already there)
    _navigatorKey!.currentState!.pushNamedAndRemoveUntil('/', (route) => false);
    developer.log('Navigated to home screen', name: 'DeepLinkService');
  }
  
  /// Show dialog when content is not found
  static void _showContentNotFoundDialog(String contentId) {
    if (_navigatorKey?.currentContext == null) return;
    
    showDialog(
      context: _navigatorKey!.currentContext!,
      builder: (context) => AlertDialog(
        title: const Text('Content Not Found'),
        content: Text('The audio content "$contentId" could not be found. It may have been removed or renamed.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToHome();
            },
            child: const Text('Go to Home'),
          ),
        ],
      ),
    );
  }
  
  /// Show generic error dialog
  static void _showErrorDialog(String message) {
    if (_navigatorKey?.currentContext == null) return;
    
    showDialog(
      context: _navigatorKey!.currentContext!,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  /// Generate deep link for sharing content
  static String generateContentLink(String contentId, {bool useCustomScheme = true}) {
    if (useCustomScheme) {
      return 'fromfedtochain://audio/$contentId';
    } else {
      return 'https://fromfedtochain.com/audio/$contentId';
    }
  }
  
  /// Dispose resources
  static void dispose() {
    _linkStreamSubscription?.cancel();
    _linkStreamSubscription = null;
    _navigatorKey = null;
    developer.log('DeepLinkService disposed', name: 'DeepLinkService');
  }
}