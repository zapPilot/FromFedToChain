import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:app_links/app_links.dart';
import 'package:provider/provider.dart';
import 'package:from_fed_to_chain_app/core/navigation/deep_link_service.dart';
import 'package:from_fed_to_chain_app/features/audio/screens/player_screen.dart';
import 'package:from_fed_to_chain_app/features/content/services/content_service.dart';
import 'package:from_fed_to_chain_app/features/audio/services/audio_player_service.dart';

@GenerateMocks([AppLinks, ContentService, AudioPlayerService])
import 'deep_link_service_test.mocks.dart';

void main() {
  Provider.debugCheckInvalidValueType = null;

  group('DeepLinkService Utility', () {
    test('generateContentLink generates correct links', () {
      // Basic scheme
      expect(
        DeepLinkService.generateContentLink('episode-1'),
        'fromfedtochain://audio/episode-1',
      );

      // With language
      expect(
        DeepLinkService.generateContentLink('episode-1', language: 'en-US'),
        'fromfedtochain://audio/episode-1/en-US',
      );

      // With ID that already has language
      expect(
        DeepLinkService.generateContentLink('episode-1-en-US'),
        'fromfedtochain://audio/episode-1/en-US',
      );

      // Universal link
      expect(
        DeepLinkService.generateContentLink('episode-1',
            useCustomScheme: false),
        'https://fromfedtochain.com/audio/episode-1',
      );
    });
  });

  group('DeepLinkService Navigation', () {
    late MockAppLinks mockAppLinks;
    late MockContentService mockContentService;
    late MockAudioPlayerService mockAudioService;
    late StreamController<Uri> uriController;
    late GlobalKey<NavigatorState> navigatorKey;

    setUp(() {
      mockAppLinks = MockAppLinks();
      mockContentService = MockContentService();
      mockAudioService = MockAudioPlayerService();
      uriController = StreamController<Uri>.broadcast();
      navigatorKey = GlobalKey<NavigatorState>();

      when(mockAppLinks.uriLinkStream).thenAnswer((_) => uriController.stream);
      when(mockAppLinks.getInitialLink()).thenAnswer((_) async => null);

      // Setup default mock responses for services used by PlayerScreen
      when(mockAudioService.currentAudioFile).thenReturn(null);
      when(mockContentService.getAudioFileById(any))
          .thenAnswer((_) async => null);
    });

    tearDown(() {
      uriController.close();
      DeepLinkService.dispose();
    });

    Future<void> pumpApp(WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ContentService>.value(value: mockContentService),
            Provider<AudioPlayerService>.value(value: mockAudioService),
          ],
          child: MaterialApp(
            navigatorKey: navigatorKey,
            home: const Scaffold(body: Text('Home')),
          ),
        ),
      );
    }

    testWidgets('initialize handles initial link', (tester) async {
      when(mockAppLinks.getInitialLink())
          .thenAnswer((_) async => Uri.parse('fromfedtochain://audio/ep-1'));

      await pumpApp(tester);

      await DeepLinkService.initialize(navigatorKey, appLinks: mockAppLinks);

      // Allow navigation and build
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(PlayerScreen), findsOneWidget);
    });

    testWidgets('handles universal initial link', (tester) async {
      when(mockAppLinks.getInitialLink()).thenAnswer(
          (_) async => Uri.parse('https://fromfedtochain.com/audio/ep-uni'));

      await pumpApp(tester);

      await DeepLinkService.initialize(navigatorKey, appLinks: mockAppLinks);

      // Allow navigation and build
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(PlayerScreen), findsOneWidget);
    });

    testWidgets('handles invalid scheme initial link gracefully',
        (tester) async {
      when(mockAppLinks.getInitialLink())
          .thenAnswer((_) async => Uri.parse('unknown://something'));

      await pumpApp(tester);

      await DeepLinkService.initialize(navigatorKey, appLinks: mockAppLinks);

      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.byType(PlayerScreen), findsNothing);
    });

    testWidgets('handles deep link from stream', (tester) async {
      await pumpApp(tester);
      await DeepLinkService.initialize(navigatorKey, appLinks: mockAppLinks);

      // Add a listener to ensure stream is active
      await tester.pump();

      // Emit a new URI
      uriController.add(Uri.parse('fromfedtochain://audio/stream-ep'));

      // Pump to process the stream event
      await tester.pump();
      // Pump again to ensure any async operations (Futures) complete
      await tester.pump();
      // Pump with duration to allow navigation animation to proceed
      await tester.pump(const Duration(seconds: 1));
      // One final pump to settle the frame
      await tester.pump();

      expect(find.byType(PlayerScreen), findsOneWidget);
    });

    testWidgets('handles home route', (tester) async {
      await pumpApp(tester);
      await DeepLinkService.initialize(navigatorKey, appLinks: mockAppLinks);

      // Navigate to player first to verify we pop back home
      navigatorKey.currentState?.push(MaterialPageRoute(
          builder: (_) => const Scaffold(body: Text('Player'))));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Player'), findsOneWidget);

      // Emit home URI
      uriController.add(Uri.parse('fromfedtochain://home'));

      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('handles missing content ID gracefully', (tester) async {
      await pumpApp(tester);
      await DeepLinkService.initialize(navigatorKey, appLinks: mockAppLinks);

      // Emit URI without ID
      uriController.add(Uri.parse('fromfedtochain://audio/'));

      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('handles universal link stream', (tester) async {
      await pumpApp(tester);
      await DeepLinkService.initialize(navigatorKey, appLinks: mockAppLinks);

      uriController
          .add(Uri.parse('https://fromfedtochain.com/audio/uni-stream'));

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(PlayerScreen), findsOneWidget);
    });
  });

  group('DeepLinkService - generateContentLink', () {
    test('generates custom scheme link', () {
      final link = DeepLinkService.generateContentLink('2025-01-01-btc');
      expect(link, 'fromfedtochain://audio/2025-01-01-btc');
    });

    test('generates web link when useCustomScheme is false', () {
      final link = DeepLinkService.generateContentLink('2025-01-01-btc',
          useCustomScheme: false);
      expect(link, 'https://fromfedtochain.com/audio/2025-01-01-btc');
    });

    test('includes language parameter in link', () {
      final link = DeepLinkService.generateContentLink('2025-01-01-btc',
          language: 'en-US');
      expect(link, 'fromfedtochain://audio/2025-01-01-btc/en-US');
    });

    test('extracts language from content ID suffix', () {
      final link = DeepLinkService.generateContentLink('2025-01-01-btc-zh-TW');
      expect(link, 'fromfedtochain://audio/2025-01-01-btc/zh-TW');
    });

    test('generates web link with language from suffix', () {
      final link = DeepLinkService.generateContentLink('2025-01-01-btc-ja-JP',
          useCustomScheme: false);
      expect(link, 'https://fromfedtochain.com/audio/2025-01-01-btc/ja-JP');
    });
  });

  group('DeepLinkService - dispose', () {
    test('disposes resources without error', () {
      // Just ensure dispose runs without crashing
      DeepLinkService.dispose();
      // After dispose, can still dispose again (no-op)
      DeepLinkService.dispose();
    });
  });
}
