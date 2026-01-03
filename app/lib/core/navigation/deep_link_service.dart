import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:from_fed_to_chain_app/core/services/logger_service.dart';
import 'package:from_fed_to_chain_app/features/audio/screens/player_screen.dart';

/// Service to handle deep links and app navigation from external sources
class DeepLinkService {
  static StreamSubscription<Uri>? _linkStreamSubscription;
  static GlobalKey<NavigatorState>? _navigatorKey;
  static AppLinks? _appLinks;
  static final _log = LoggerService.getLogger('DeepLinkService');

  /// Initialize deep link handling
  /// [navigatorKey] should be the global navigator key from MaterialApp
  /// [appLinks] optional instance for testing
  static Future<void> initialize(GlobalKey<NavigatorState> navigatorKey,
      {AppLinks? appLinks}) async {
    _navigatorKey = navigatorKey;
    _appLinks = appLinks ?? AppLinks();

    try {
      // Handle initial link when app is launched from closed state
      final initialLink = await _appLinks!.getInitialLink();
      if (initialLink != null) {
        _log.info('Initial deep link received: $initialLink');
        await _handleDeepLink(initialLink.toString());
      }
    } catch (e) {
      _log.warning('Error getting initial link: $e');
    }

    // Handle links when app is already running
    _linkStreamSubscription = _appLinks!.uriLinkStream.listen(
      (Uri uri) {
        _log.info('Deep link received: $uri');
        _handleDeepLink(uri.toString());
      },
      onError: (err) {
        _log.severe('Deep link stream error: $err');
      },
    );
  }

  /// Handle incoming deep links
  static Future<void> _handleDeepLink(String link) async {
    try {
      final uri = Uri.parse(link);
      _log.info('Parsing deep link URI: $uri');

      // Handle our custom scheme: fromfedtochain://
      if (uri.scheme == 'fromfedtochain') {
        await _handleCustomSchemeLink(uri);
      }
      // Handle universal links: https://fromfedtochain.com/
      else if (uri.scheme == 'https' && uri.host == 'fromfedtochain.com') {
        await _handleUniversalLink(uri);
      } else {
        _log.warning('Unhandled deep link scheme: ${uri.scheme}');
      }
    } catch (e) {
      _log.severe('Error handling deep link: $e');
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
          _log.warning('Audio deep link missing content ID');
          _navigateToHome();
        }
        break;
      case 'home':
      case '': // Handle empty host case
        _navigateToHome();
        break;
      default:
        _log.warning('Unknown deep link route type: $routeType');
        _navigateToHome();
    }
  }

  /// Handle universal links: https://fromfedtochain.com/audio/content-id
  static Future<void> _handleUniversalLink(Uri uri) async {
    // Transform universal link path to custom scheme format
    // https://fromfedtochain.com/audio/id -> fromfedtochain://audio/id
    // Universal link path segments: ['audio', 'id']
    // Custom scheme: host='audio', path=['id']

    if (uri.pathSegments.isNotEmpty) {
      final routeType = uri.pathSegments[0];
      // Create new URI with routeType as host, and remaining segments as path
      final newPath = uri.pathSegments.skip(1).join('/');
      final newUri = Uri.parse('fromfedtochain://$routeType/$newPath');

      _log.info('Transformed universal link to: $newUri');
      await _handleCustomSchemeLink(newUri);
    } else {
      _navigateToHome();
    }
  }

  /// Navigate to specific audio content
  static Future<void> _navigateToAudio(String contentId) async {
    if (_navigatorKey?.currentContext == null) {
      _log.warning('Navigator context not available');
      return;
    }

    try {
      // Navigate directly to player screen - let PlayerScreen handle content verification and loading
      _navigatorKey!.currentState!.push(
        MaterialPageRoute(
          builder: (context) => PlayerScreen(contentId: contentId),
        ),
      );

      _log.info('Navigated to PlayerScreen with contentId: "$contentId"');
    } catch (e) {
      _log.severe('Error navigating to audio content: $e');
      _showErrorDialog('Failed to load audio content');
    }
  }

  /// Navigate to home screen
  static void _navigateToHome() {
    if (_navigatorKey?.currentContext == null) {
      _log.warning('Navigator context not available for home navigation');
      return;
    }

    // Pop all routes and go to home (if not already there)
    _navigatorKey!.currentState!.pushNamedAndRemoveUntil('/', (route) => false);
    _log.info('Navigated to home screen');
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
    _appLinks = null;
    _log.info('DeepLinkService disposed');
  }
}
