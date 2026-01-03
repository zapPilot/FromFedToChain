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
      when(mockContentService.getAudioFileById(any))
          .thenAnswer((_) async => null); // Prevent loading error

      await pumpApp(tester);

      await DeepLinkService.initialize(navigatorKey, appLinks: mockAppLinks);

      // Allow navigation and build
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(PlayerScreen), findsOneWidget);
    });

    testWidgets('handles universal initial link', (tester) async {
      when(mockAppLinks.getInitialLink()).thenAnswer(
          (_) async => Uri.parse('https://fromfedtochain.com/audio/ep-uni'));
      // getInitialLinkString might be used by AppLinks internals or custom logic, mocking just in case if needed, but not used in DeepLinkService
      when(mockContentService.getAudioFileById(any))
          .thenAnswer((_) async => null);

      await pumpApp(tester);

      await DeepLinkService.initialize(navigatorKey, appLinks: mockAppLinks);

      // Allow navigation and build
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(PlayerScreen), findsOneWidget);
    });

    testWidgets('handles invalid scheme initial link gracefully',
        (tester) async {
      when(mockAppLinks.getInitialLink())
          .thenAnswer((_) async => Uri.parse('unknown://something'));

      await pumpApp(tester);

      await DeepLinkService.initialize(navigatorKey, appLinks: mockAppLinks);

      await tester.pump();

      expect(find.text('Home'), findsOneWidget);
      expect(find.byType(PlayerScreen), findsNothing);
    });
  });
}
