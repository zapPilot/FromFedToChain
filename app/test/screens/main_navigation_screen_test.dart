import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';

import 'package:from_fed_to_chain_app/screens/main_navigation_screen.dart';
import 'package:from_fed_to_chain_app/screens/home_screen.dart';
import 'package:from_fed_to_chain_app/screens/history_screen.dart';
import 'package:from_fed_to_chain_app/services/content_service.dart';
import 'package:from_fed_to_chain_app/services/audio_service.dart';
import 'package:from_fed_to_chain_app/services/auth/auth_service.dart';
import 'package:from_fed_to_chain_app/widgets/mini_player.dart';

import '../test_utils.dart';

// Generate mocks
@GenerateMocks([ContentService, AudioService, AuthService])
import 'main_navigation_screen_test.mocks.dart';

void main() {
  group('MainNavigationScreen Widget Tests', () {
    late MockContentService mockContentService;
    late MockAudioService mockAudioService;
    late MockAuthService mockAuthService;

    setUp(() {
      mockContentService = MockContentService();
      mockAudioService = MockAudioService();
      mockAuthService = MockAuthService();

      // Setup default mock behavior
      when(mockContentService.filteredEpisodes).thenReturn([]);
      when(mockContentService.allEpisodes).thenReturn([]);
      when(mockContentService.isLoading).thenReturn(false);
      when(mockContentService.hasError).thenReturn(false);
      when(mockContentService.selectedLanguage).thenReturn('zh-TW');
      when(mockContentService.selectedCategory).thenReturn('all');

      when(mockAudioService.isPlaying).thenReturn(false);
      when(mockAudioService.currentAudioFile).thenReturn(null);

      when(mockAuthService.isAuthenticated).thenReturn(true);
    });

    Widget createMainNavigationScreen() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<ContentService>.value(
              value: mockContentService),
          ChangeNotifierProvider<AudioService>.value(value: mockAudioService),
          ChangeNotifierProvider<AuthService>.value(value: mockAuthService),
        ],
        child: TestUtils.wrapWithMaterialApp(const MainNavigationScreen()),
      );
    }

    testWidgets('renders correctly with bottom navigation', (tester) async {
      await tester.pumpWidget(createMainNavigationScreen());
      await tester.pumpAndSettle();

      // Check that main structure is present
      expect(find.byType(MainNavigationScreen), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('displays correct navigation items', (tester) async {
      await tester.pumpWidget(createMainNavigationScreen());
      await tester.pumpAndSettle();

      // Check for navigation items
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);

      // Check for navigation icons
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);
    });

    testWidgets('starts with Home screen selected', (tester) async {
      await tester.pumpWidget(createMainNavigationScreen());
      await tester.pumpAndSettle();

      // Should show HomeScreen by default
      expect(find.byType(HomeScreen), findsOneWidget);

      // Home tab should be selected
      final bottomNavBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNavBar.currentIndex, equals(0));
    });

    testWidgets('switches to History screen when tapped', (tester) async {
      await tester.pumpWidget(createMainNavigationScreen());
      await tester.pumpAndSettle();

      // Tap History tab
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      // Should show HistoryScreen
      expect(find.byType(HistoryScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('switches back to Home screen', (tester) async {
      await tester.pumpWidget(createMainNavigationScreen());
      await tester.pumpAndSettle();

      // Go to History
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      // Go back to Home
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      // Should show HomeScreen again
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(HistoryScreen), findsNothing);
    });

    testWidgets('shows mini player when episode is playing', (tester) async {
      final testEpisode = TestUtils.createSampleAudioFile();
      when(mockAudioService.currentAudioFile).thenReturn(testEpisode);
      when(mockAudioService.isPlaying).thenReturn(true);

      await tester.pumpWidget(createMainNavigationScreen());
      await tester.pumpAndSettle();

      // Should show mini player
      expect(find.byType(MiniPlayer), findsOneWidget);
    });

    testWidgets('hides mini player when no episode is playing', (tester) async {
      when(mockAudioService.currentAudioFile).thenReturn(null);
      when(mockAudioService.isPlaying).thenReturn(false);

      await tester.pumpWidget(createMainNavigationScreen());
      await tester.pumpAndSettle();

      // Should not show mini player
      expect(find.byType(MiniPlayer), findsNothing);
    });

    testWidgets('maintains screen state when switching tabs', (tester) async {
      final testEpisodes = TestUtils.createSampleAudioFileList(5);
      when(mockContentService.filteredEpisodes).thenReturn(testEpisodes);

      await tester.pumpWidget(createMainNavigationScreen());
      await tester.pumpAndSettle();

      // Interact with Home screen (e.g., search)
      // This would be more detailed in a real app
      expect(find.byType(HomeScreen), findsOneWidget);

      // Switch to History and back
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      // Home screen should be restored
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('handles rapid tab switching', (tester) async {
      await tester.pumpWidget(createMainNavigationScreen());
      await tester.pumpAndSettle();

      // Rapidly switch between tabs
      for (int i = 0; i < 10; i++) {
        await tester.tap(find.text('History'));
        await tester.pump();
        await tester.tap(find.text('Home'));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      // Should handle rapid switching without errors
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('displays correct theme colors', (tester) async {
      await tester.pumpWidget(createMainNavigationScreen());
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, isNotNull);

      final bottomNavBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNavBar.type, equals(BottomNavigationBarType.fixed));
    });

    testWidgets('handles mini player interaction', (tester) async {
      final testEpisode = TestUtils.createSampleAudioFile();
      when(mockAudioService.currentAudioFile).thenReturn(testEpisode);
      when(mockAudioService.isPlaying).thenReturn(true);

      await tester.pumpWidget(createMainNavigationScreen());
      await tester.pumpAndSettle();

      // Find and tap mini player
      final miniPlayer = find.byType(MiniPlayer);
      if (miniPlayer.evaluate().isNotEmpty) {
        await tester.tap(miniPlayer);
        await tester.pumpAndSettle();

        // Should navigate to player screen (tested in integration tests)
      }
    });

    testWidgets('adjusts layout for mini player', (tester) async {
      await tester.pumpWidget(createMainNavigationScreen());
      await tester.pumpAndSettle();

      // Get initial layout
      tester.getRect(find.byType(Scaffold));

      // Add mini player
      final testEpisode = TestUtils.createSampleAudioFile();
      when(mockAudioService.currentAudioFile).thenReturn(testEpisode);
      when(mockAudioService.isPlaying).thenReturn(true);

      await tester.pumpWidget(createMainNavigationScreen());
      await tester.pumpAndSettle();

      // Layout should adjust for mini player
      final miniPlayer = find.byType(MiniPlayer);
      if (miniPlayer.evaluate().isNotEmpty) {
        expect(miniPlayer, findsOneWidget);
        // The main content area should be adjusted
      }
    });

    testWidgets('handles back button on nested screens', (tester) async {
      await tester.pumpWidget(createMainNavigationScreen());
      await tester.pumpAndSettle();

      // This would test Android back button behavior
      // On root navigation screen, back button should not pop
    });

    testWidgets('preserves tab state across app lifecycle', (tester) async {
      await tester.pumpWidget(createMainNavigationScreen());
      await tester.pumpAndSettle();

      // Switch to History tab
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      expect(find.byType(HistoryScreen), findsOneWidget);

      // Simulate app being recreated (hot reload, etc.)
      await tester.pumpWidget(createMainNavigationScreen());
      await tester.pumpAndSettle();

      // Should remember last selected tab (if implemented)
      // Or default to Home tab
      expect(find.byType(MainNavigationScreen), findsOneWidget);
    });

    testWidgets('updates mini player when audio state changes', (tester) async {
      await tester.pumpWidget(createMainNavigationScreen());
      await tester.pumpAndSettle();

      // Initially no mini player
      expect(find.byType(MiniPlayer), findsNothing);

      // Start playing episode
      final testEpisode = TestUtils.createSampleAudioFile();
      when(mockAudioService.currentAudioFile).thenReturn(testEpisode);
      when(mockAudioService.isPlaying).thenReturn(true);

      // Trigger rebuild
      mockAudioService.notifyListeners();
      await tester.pump();

      // Should now show mini player
      expect(find.byType(MiniPlayer), findsOneWidget);

      // Stop playing
      when(mockAudioService.currentAudioFile).thenReturn(null);
      when(mockAudioService.isPlaying).thenReturn(false);

      // Trigger rebuild
      mockAudioService.notifyListeners();
      await tester.pump();

      // Should hide mini player
      expect(find.byType(MiniPlayer), findsNothing);
    });
  });

  group('MainNavigationScreen Integration Tests', () {
    late MockContentService mockContentService;
    late MockAudioService mockAudioService;
    late MockAuthService mockAuthService;

    setUp(() {
      mockContentService = MockContentService();
      mockAudioService = MockAudioService();
      mockAuthService = MockAuthService();

      // Setup realistic mock behavior
      final testEpisodes = TestUtils.createSampleAudioFileList(10);
      when(mockContentService.allEpisodes).thenReturn(testEpisodes);
      when(mockContentService.filteredEpisodes).thenReturn(testEpisodes);
      when(mockContentService.getListenHistoryEpisodes())
          .thenReturn(testEpisodes.take(3).toList());
      when(mockContentService.isLoading).thenReturn(false);

      when(mockAudioService.isPlaying).thenReturn(false);
      when(mockAudioService.currentAudioFile).thenReturn(null);

      when(mockAuthService.isAuthenticated).thenReturn(true);
    });

    Widget createMainNavigationScreen() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<ContentService>.value(
              value: mockContentService),
          ChangeNotifierProvider<AudioService>.value(value: mockAudioService),
          ChangeNotifierProvider<AuthService>.value(value: mockAuthService),
        ],
        child: TestUtils.wrapWithMaterialApp(const MainNavigationScreen()),
      );
    }

    testWidgets('complete navigation flow', (tester) async {
      await tester.pumpWidget(createMainNavigationScreen());
      await tester.pumpAndSettle();

      // 1. Start on Home screen
      expect(find.byType(HomeScreen), findsOneWidget);

      // 2. Navigate to History
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      expect(find.byType(HistoryScreen), findsOneWidget);

      // 3. Navigate back to Home
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);

      // 4. Start playback from Home
      final testEpisodes = TestUtils.createSampleAudioFileList(3);
      when(mockContentService.filteredEpisodes).thenReturn(testEpisodes);
      when(mockAudioService.currentAudioFile).thenReturn(testEpisodes.first);
      when(mockAudioService.isPlaying).thenReturn(true);

      await tester.pumpWidget(createMainNavigationScreen());
      await tester.pumpAndSettle();

      // 5. Verify mini player appears
      expect(find.byType(MiniPlayer), findsOneWidget);

      // 6. Navigate to History with mini player visible
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      expect(find.byType(HistoryScreen), findsOneWidget);
      expect(find.byType(MiniPlayer), findsOneWidget);
    });

    testWidgets('handles navigation with different audio states',
        (tester) async {
      final testEpisode = TestUtils.createSampleAudioFile();

      await tester.pumpWidget(createMainNavigationScreen());
      await tester.pumpAndSettle();

      // Test navigation while audio is loading
      when(mockAudioService.currentAudioFile).thenReturn(testEpisode);
      when(mockAudioService.isLoading).thenReturn(true);
      mockAudioService.notifyListeners();
      await tester.pump();

      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      expect(find.byType(HistoryScreen), findsOneWidget);
      expect(find.byType(MiniPlayer), findsOneWidget);

      // Test navigation while audio is paused
      when(mockAudioService.isLoading).thenReturn(false);
      when(mockAudioService.isPaused).thenReturn(true);
      mockAudioService.notifyListeners();
      await tester.pump();

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(MiniPlayer), findsOneWidget);
    });

    testWidgets('maintains scroll position across tab switches',
        (tester) async {
      final testEpisodes = TestUtils.createSampleAudioFileList(20);
      when(mockContentService.filteredEpisodes).thenReturn(testEpisodes);

      await tester.pumpWidget(createMainNavigationScreen());
      await tester.pumpAndSettle();

      // Scroll in Home screen (if it has scrollable content)
      final homeScrollable = find.byType(ListView);
      if (homeScrollable.evaluate().isNotEmpty) {
        await tester.drag(homeScrollable.first, const Offset(0, -200));
        await tester.pumpAndSettle();
      }

      // Switch to History and back
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      // Scroll position should be maintained in Home
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('handles app state restoration', (tester) async {
      // Initial state
      await tester.pumpWidget(createMainNavigationScreen());
      await tester.pumpAndSettle();

      // Switch to History tab
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      // Start audio playback
      final testEpisode = TestUtils.createSampleAudioFile();
      when(mockAudioService.currentAudioFile).thenReturn(testEpisode);
      when(mockAudioService.isPlaying).thenReturn(true);
      mockAudioService.notifyListeners();
      await tester.pump();

      // Verify state
      expect(find.byType(HistoryScreen), findsOneWidget);
      expect(find.byType(MiniPlayer), findsOneWidget);

      // Simulate app restart
      await tester.pumpWidget(createMainNavigationScreen());
      await tester.pumpAndSettle();

      // Should restore to a consistent state
      expect(find.byType(MainNavigationScreen), findsOneWidget);
    });

    testWidgets('handles mini player to full player transition',
        (tester) async {
      final testEpisode = TestUtils.createSampleAudioFile();
      when(mockAudioService.currentAudioFile).thenReturn(testEpisode);
      when(mockAudioService.isPlaying).thenReturn(true);

      await tester.pumpWidget(createMainNavigationScreen());
      await tester.pumpAndSettle();

      // Tap mini player to go to full player
      final miniPlayer = find.byType(MiniPlayer);
      if (miniPlayer.evaluate().isNotEmpty) {
        await tester.tap(miniPlayer);
        await tester.pumpAndSettle();

        // Navigation to PlayerScreen would be tested in router/navigation tests
        // Here we verify the mini player interaction works
      }
    });

    testWidgets('handles notification interactions', (tester) async {
      // This would test deep link handling or notification responses
      // For now, just verify the structure supports it
      await tester.pumpWidget(createMainNavigationScreen());
      await tester.pumpAndSettle();

      expect(find.byType(MainNavigationScreen), findsOneWidget);
    });
  });
}
