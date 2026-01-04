import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:from_fed_to_chain_app/features/audio/screens/player_screen.dart';
import 'package:from_fed_to_chain_app/core/navigation/deep_link_service.dart';
import 'package:from_fed_to_chain_app/features/audio/services/audio_player_service.dart';
import 'package:from_fed_to_chain_app/features/content/services/content_service.dart';
import 'package:provider/provider.dart';

import 'package:from_fed_to_chain_app/features/audio/services/player_state_notifier.dart';
import '../../widgets/screens/home_screen_coverage_test.mocks.dart';
import 'deep_link_service_coverage_test.mocks.dart';

// Helper to mock BuildContext
class MockBuildContext extends Mock implements BuildContext {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeepLinkService Coverage Tests', () {
    late MockAppLinks mockAppLinks;
    late GlobalKey<NavigatorState> navigatorKey;
    late MockAudioPlayerService mockAudioService;
    late MockContentService mockContentService;
    late StreamController<Uri> uriController;

    setUp(() {
      mockAppLinks = MockAppLinks();
      mockAudioService = MockAudioPlayerService();
      mockContentService = MockContentService();
      navigatorKey = GlobalKey<NavigatorState>();

      // Basic stubs for AudioPlayerService
      when(mockAudioService.currentAudioFile).thenReturn(null);
      when(mockAudioService.playbackState).thenReturn(AppPlaybackState.paused);
      when(mockAudioService.isPlaying).thenReturn(false);
      when(mockAudioService.isPaused).thenReturn(false);
      when(mockAudioService.isLoading).thenReturn(false);
      when(mockAudioService.hasError).thenReturn(false);
      when(mockAudioService.playbackSpeed).thenReturn(1.0);
      when(mockAudioService.repeatEnabled).thenReturn(false);
      when(mockAudioService.autoplayEnabled).thenReturn(false);
      when(mockAudioService.currentPosition).thenReturn(Duration.zero);
      when(mockAudioService.totalDuration).thenReturn(Duration.zero);
      when(mockAudioService.addListener(any)).thenReturn(null);
      when(mockAudioService.removeListener(any)).thenReturn(null);

      uriController = StreamController<Uri>();
      when(mockAppLinks.uriLinkStream).thenAnswer((_) => uriController.stream);
      when(mockAppLinks.getInitialLink()).thenAnswer((_) async => null);
    });

    tearDown(() {
      uriController.close();
      DeepLinkService.dispose();
    });

    testWidgets('Initialization handles getInitialLink error', (tester) async {
      when(mockAppLinks.getInitialLink()).thenThrow(Exception('Init failed'));

      await DeepLinkService.initialize(navigatorKey, appLinks: mockAppLinks);
      // Should not throw
    });

    testWidgets('Stream processes valid link', (tester) async {
      await DeepLinkService.initialize(navigatorKey, appLinks: mockAppLinks);

      uriController.add(Uri.parse('fromfedtochain://audio/123'));
      await tester.pump();
      // Logs should show processing
    });

    testWidgets('Stream handles error', (tester) async {
      await DeepLinkService.initialize(navigatorKey, appLinks: mockAppLinks);

      uriController.addError(Exception('Stream error'));
      await tester.pump();
      // Should not crash
    });

    testWidgets('Initialization handles initial link', (tester) async {
      when(mockAppLinks.getInitialLink())
          .thenAnswer((_) async => Uri.parse('fromfedtochain://home'));

      await DeepLinkService.initialize(navigatorKey, appLinks: mockAppLinks);
      // Log info will verify processing
    });

    testWidgets('Navigation handles missing context', (tester) async {
      final validLink = Uri.parse('fromfedtochain://audio/123');

      // Initialize with a key that isn't attached
      final detachedKey = GlobalKey<NavigatorState>();
      await DeepLinkService.initialize(detachedKey, appLinks: mockAppLinks);

      uriController.add(validLink);
      await tester.pump();
      // Should verify log 'Navigator context not available' (implicitly by no crash)
    });

    testWidgets('Handle malformed/unhandled links', (tester) async {
      await DeepLinkService.initialize(navigatorKey, appLinks: mockAppLinks);

      // Unhandled scheme
      uriController.add(Uri.parse('unknown://scheme'));

      // Failed parsing (String) - actually internal helper takes String
      // But uriLinkStream provides Uri. So we can't easily pass malformed string via stream.
      // But handleDeepLink parses string.

      // Empty audio path
      uriController.add(Uri.parse('fromfedtochain://audio'));

      // Universal link without path
      uriController.add(Uri.parse('https://fromfedtochain.com/'));

      // Universal link unknown host
      uriController.add(Uri.parse('https://other.com/audio/123'));

      await tester.pump();
    });

    // To test navigation failure inside _navigateToAudio, we need a valid context but failing push.
    // This is hard with real widgets.
    // But we can test `generateContentLink` thoroughly.

    testWidgets('Full navigation flow to Audio with language', (tester) async {
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<AudioPlayerService>.value(
              value: mockAudioService),
          ChangeNotifierProvider<ContentService>.value(
              value: mockContentService),
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          onGenerateRoute: (settings) {
            if (settings.name == '/') {
              return MaterialPageRoute(builder: (_) => Container());
            }
            return null;
          },
        ),
      ));

      await DeepLinkService.initialize(navigatorKey, appLinks: mockAppLinks);

      uriController.add(Uri.parse('fromfedtochain://audio/ep-1/en-US'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(PlayerScreen), findsOneWidget);
    });

    testWidgets('Navigation to Home', (tester) async {
      await tester.pumpWidget(MaterialApp(
        navigatorKey: navigatorKey,
        routes: {
          '/': (_) => const Text('Home Page'),
        },
      ));

      await DeepLinkService.initialize(navigatorKey, appLinks: mockAppLinks);

      uriController.add(Uri.parse('fromfedtochain://home'));
      await tester.pumpAndSettle();

      expect(find.text('Home Page'), findsOneWidget);
    });

    testWidgets('Handles universal link transformation', (tester) async {
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<AudioPlayerService>.value(
              value: mockAudioService),
          ChangeNotifierProvider<ContentService>.value(
              value: mockContentService),
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          home: Container(),
        ),
      ));

      await DeepLinkService.initialize(navigatorKey, appLinks: mockAppLinks);

      uriController.add(Uri.parse('https://fromfedtochain.com/audio/ep-123'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(PlayerScreen), findsOneWidget);
    });

    testWidgets('Handles unknown route by navigating to home', (tester) async {
      await tester.pumpWidget(MaterialApp(
        navigatorKey: navigatorKey,
        routes: {
          '/': (_) => const Text('Home Page'),
        },
      ));

      await DeepLinkService.initialize(navigatorKey, appLinks: mockAppLinks);

      uriController.add(Uri.parse('fromfedtochain://unknown-route'));
      await tester.pumpAndSettle();

      expect(find.text('Home Page'), findsOneWidget);
    });

    test('generateContentLink variations', () {
      // Universal link
      expect(DeepLinkService.generateContentLink('id', useCustomScheme: false),
          'https://fromfedtochain.com/audio/id');

      // With existing suffix matches link generation
      expect(DeepLinkService.generateContentLink('my-ep-en-US'),
          'fromfedtochain://audio/my-ep/en-US');

      // Universal with suffix
      expect(
          DeepLinkService.generateContentLink('id-zh-TW',
              useCustomScheme: false),
          'https://fromfedtochain.com/audio/id/zh-TW');
    });

    test('generateContentLink variations additional coverage', () {
      // Language as parameter
      expect(DeepLinkService.generateContentLink('ep1', language: 'ja-JP'),
          'fromfedtochain://audio/ep1/ja-JP');

      // Mismatched language in ID suffix vs parameter (suffix in ID takes precedence)
      expect(
          DeepLinkService.generateContentLink('ep1-en-US', language: 'zh-TW'),
          'fromfedtochain://audio/ep1/en-US');
    });
  });
}
