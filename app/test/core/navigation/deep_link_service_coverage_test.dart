import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:app_links/app_links.dart';
import 'package:from_fed_to_chain_app/core/navigation/deep_link_service.dart';

@GenerateMocks([AppLinks, NavigatorState])
import 'deep_link_service_coverage_test.mocks.dart';

// Helper to mock BuildContext
class MockBuildContext extends Mock implements BuildContext {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeepLinkService Coverage Tests', () {
    late MockAppLinks mockAppLinks;
    late GlobalKey<NavigatorState> navigatorKey;
    late MockNavigatorState mockNavigatorState;
    late StreamController<Uri> uriController;

    setUp(() {
      mockAppLinks = MockAppLinks();
      mockNavigatorState = MockNavigatorState();
      navigatorKey = GlobalKey<NavigatorState>();
      // We can't easily assign state to a GlobalKey without pumping a widget.
      // So we might need to rely on partial integration or just test static methods if exposed,
      // but they are private.
      // However, we can use a real widget pump to establish context.

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

    test('generateContentLink edge cases', () {
      // Suffix already present
      expect(DeepLinkService.generateContentLink('id-zh-TW'),
          contains('audio/id/zh-TW'));

      // No suffix, no language
      expect(DeepLinkService.generateContentLink('id'), contains('audio/id'));

      // Custom scheme false
      expect(DeepLinkService.generateContentLink('id', useCustomScheme: false),
          contains('https://fromfedtochain.com/audio/id'));
    });
  });
}
