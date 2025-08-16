import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:uni_links/uni_links.dart';

import '../screens/player_screen.dart';

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
        developer.log('Initial deep link received: $initialLink',
            name: 'DeepLinkService');
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
      developer.log('DeepLinkService: Parsing deep link URI: $uri',
          name: 'DeepLinkService');

      // Handle our custom scheme: fromfedtochain://
      if (uri.scheme == 'fromfedtochain') {
        await _handleCustomSchemeLink(uri);
      }
      // Handle universal links: https://fromfedtochain.com/
      else if (uri.scheme == 'https' && uri.host == 'fromfedtochain.com') {
        await _handleUniversalLink(uri);
      } else {
        developer.log('Unhandled deep link scheme: ${uri.scheme}',
            name: 'DeepLinkService');
      }
    } catch (e) {
      developer.log('Error handling deep link: $e', name: 'DeepLinkService');
    }
  }

  /// Handle custom scheme links: fromfedtochain://audio/content-id
  static Future<void> _handleCustomSchemeLink(Uri uri) async {
    // For custom scheme URLs like fromfedtochain://audio/content-id:
    // - uri.host contains "audio" (the route type)
    // - uri.pathSegments contains ["content-id"] (the parameters)
    final routeType = uri.host;

    switch (routeType) {
      case 'audio':
        if (uri.pathSegments.isNotEmpty) {
          final episodeId = uri.pathSegments[0]; // Base episode ID
          final language =
              uri.pathSegments.length > 1 ? uri.pathSegments[1] : null;

          // Construct full content ID with language if provided
          final fullContentId =
              language != null ? '$episodeId-$language' : episodeId;

          await _navigateToAudio(fullContentId);
        } else {
          developer.log('Audio deep link missing content ID',
              name: 'DeepLinkService');
          _navigateToHome();
        }
        break;
      case 'home':
      case '': // Handle empty host case
        _navigateToHome();
        break;
      default:
        developer.log('Unknown deep link route type: $routeType',
            name: 'DeepLinkService');
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
      // Navigate directly to player screen - let PlayerScreen handle content verification and loading
      _navigatorKey!.currentState!.push(
        MaterialPageRoute(
          builder: (context) => PlayerScreen(contentId: contentId),
        ),
      );

      developer.log(
          'DeepLinkService: Navigated to PlayerScreen with contentId: "$contentId"',
          name: 'DeepLinkService');
    } catch (e) {
      developer.log('Error navigating to audio content: $e',
          name: 'DeepLinkService');
      _showErrorDialog('Failed to load audio content');
    }
  }

  /// Navigate to home screen
  static void _navigateToHome() {
    if (_navigatorKey?.currentContext == null) {
      developer.log('Navigator context not available for home navigation',
          name: 'DeepLinkService');
      return;
    }

    // Pop all routes and go to home (if not already there)
    _navigatorKey!.currentState!.pushNamedAndRemoveUntil('/', (route) => false);
    developer.log('Navigated to home screen', name: 'DeepLinkService');
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

  /// Generate deep link for sharing content with language support
  /// [contentId] can be either full ID (episode-id-language) or base episode ID
  /// [language] optional explicit language parameter
  static String generateContentLink(String contentId,
      {String? language, bool useCustomScheme = true}) {
    String episodeId;
    String? linkLanguage;

    // Check if contentId already contains language suffix
    final languageSuffixes = ['zh-TW', 'en-US', 'ja-JP'];
    final matchedSuffix = languageSuffixes.firstWhere(
      (suffix) => contentId.endsWith('-$suffix'),
      orElse: () => '',
    );

    if (matchedSuffix.isNotEmpty) {
      // Split existing contentId with language
      episodeId =
          contentId.substring(0, contentId.length - matchedSuffix.length - 1);
      linkLanguage = matchedSuffix;
    } else {
      // Use contentId as-is and explicit language parameter
      episodeId = contentId;
      linkLanguage = language;
    }

    // Construct URL
    final basePath = linkLanguage != null
        ? 'audio/$episodeId/$linkLanguage'
        : 'audio/$episodeId';

    if (useCustomScheme) {
      return 'fromfedtochain://$basePath';
    } else {
      return 'https://fromfedtochain.com/$basePath';
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
