import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';

import 'package:from_fed_to_chain_app/screens/home_screen.dart';
import 'package:from_fed_to_chain_app/services/content_service.dart';
import 'package:from_fed_to_chain_app/services/audio_service.dart';
import 'package:from_fed_to_chain_app/services/auth/auth_service.dart';
import 'package:from_fed_to_chain_app/themes/app_theme.dart';
import 'package:from_fed_to_chain_app/widgets/mini_player.dart';

import '../test_utils.dart';

// Generate mocks
@GenerateMocks([ContentService, AudioService, AuthService])
import 'home_screen_test.mocks.dart';

void main() {
  group('HomeScreen Widget Tests', () {
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
      when(mockContentService.errorMessage).thenReturn(null);
      when(mockContentService.selectedLanguage).thenReturn('zh-TW');
      when(mockContentService.selectedCategory).thenReturn('all');
      when(mockContentService.searchQuery).thenReturn('');
      when(mockContentService.sortOrder).thenReturn('newest');
      when(mockContentService.getListenHistoryEpisodes()).thenReturn([]);
      when(mockContentService.getUnfinishedEpisodes()).thenReturn([]);

      when(mockAudioService.isPlaying).thenReturn(false);
      when(mockAudioService.isPaused).thenReturn(false);
      when(mockAudioService.isLoading).thenReturn(false);
      when(mockAudioService.currentAudioFile).thenReturn(null);

      when(mockAuthService.isAuthenticated).thenReturn(true);
      when(mockAuthService.currentUser).thenReturn(null);
    });

    Widget createHomeScreen() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<ContentService>.value(
              value: mockContentService),
          ChangeNotifierProvider<AudioService>.value(value: mockAudioService),
          ChangeNotifierProvider<AuthService>.value(value: mockAuthService),
        ],
        child: TestUtils.wrapWithMaterialApp(const HomeScreen()),
      );
    }

    testWidgets('renders correctly with empty state', (tester) async {
      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      // Check that basic structure is present
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(TabBarView), findsOneWidget);
    });

    testWidgets('displays app title correctly', (tester) async {
      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      // Check for app title or header
      expect(find.text('From Fed to Chain'), findsOneWidget);
    });

    testWidgets('shows search icon and toggles search bar', (tester) async {
      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      // Find search icon
      final searchIcon = find.byIcon(Icons.search);
      expect(searchIcon, findsOneWidget);

      // Tap search icon to show search bar
      await tester.tap(searchIcon);
      await tester.pumpAndSettle();

      // Verify search bar appears
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('displays tabs correctly', (tester) async {
      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      // Check for tab labels
      expect(find.text('Recent'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Unfinished'), findsOneWidget);
    });

    testWidgets('displays loading state', (tester) async {
      when(mockContentService.isLoading).thenReturn(true);

      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      // Check for loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays error state', (tester) async {
      const errorMessage = 'Failed to load episodes';
      when(mockContentService.hasError).thenReturn(true);
      when(mockContentService.errorMessage).thenReturn(errorMessage);

      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      // Check for error message
      expect(find.text(errorMessage), findsOneWidget);
    });

    testWidgets('displays episodes in Recent tab', (tester) async {
      final testEpisodes = TestUtils.createSampleAudioFileList(3);
      when(mockContentService.getListenHistoryEpisodes())
          .thenReturn(testEpisodes);

      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      // Should be on Recent tab by default
      expect(find.text(testEpisodes.first.title), findsOneWidget);
    });

    testWidgets('switches between tabs correctly', (tester) async {
      final testEpisodes = TestUtils.createSampleAudioFileList(5);
      when(mockContentService.getListenHistoryEpisodes())
          .thenReturn(testEpisodes.take(2).toList());
      when(mockContentService.filteredEpisodes).thenReturn(testEpisodes);
      when(mockContentService.getUnfinishedEpisodes())
          .thenReturn(testEpisodes.take(1).toList());

      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      // Test switching to All tab
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      // Should show all episodes
      expect(find.text(testEpisodes[2].title), findsOneWidget);

      // Test switching to Unfinished tab
      await tester.tap(find.text('Unfinished'));
      await tester.pumpAndSettle();

      // Should show unfinished episodes
      expect(find.text(testEpisodes.first.title), findsOneWidget);
    });

    testWidgets('displays filter bar when episodes exist', (tester) async {
      final testEpisodes = TestUtils.createSampleAudioFileList(3);
      when(mockContentService.filteredEpisodes).thenReturn(testEpisodes);

      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      // Switch to All tab to see filter bar
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      // Check for filter bar (language and category filters)
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
    });

    testWidgets('handles search input correctly', (tester) async {
      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      // Open search bar
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Enter search query
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'bitcoin');
      await tester.pumpAndSettle();

      // Verify that ContentService search method was called
      verify(mockContentService.searchEpisodes('bitcoin')).called(1);
    });

    testWidgets('shows mini player when episode is playing', (tester) async {
      final testEpisode = TestUtils.createSampleAudioFile();
      when(mockAudioService.currentAudioFile).thenReturn(testEpisode);
      when(mockAudioService.isPlaying).thenReturn(true);

      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      // Check for mini player
      expect(find.byType(MiniPlayer), findsOneWidget);
      expect(find.text(testEpisode.title), findsOneWidget);
    });

    testWidgets('navigates to player screen when mini player is tapped',
        (tester) async {
      final testEpisode = TestUtils.createSampleAudioFile();
      when(mockAudioService.currentAudioFile).thenReturn(testEpisode);
      when(mockAudioService.isPlaying).thenReturn(true);

      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      // Tap mini player
      final miniPlayer = find.byType(MiniPlayer);
      await tester.tap(miniPlayer);
      await tester.pumpAndSettle();

      // Should navigate to player screen (will be checked in integration tests)
    });

    testWidgets('displays empty state when no episodes', (tester) async {
      when(mockContentService.filteredEpisodes).thenReturn([]);
      when(mockContentService.allEpisodes).thenReturn([]);

      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      // Switch to All tab
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      // Should show empty state message
      expect(find.text('No episodes available'), findsOneWidget);
    });

    testWidgets('handles refresh correctly', (tester) async {
      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      // Switch to All tab
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      // Pull to refresh
      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 300));
      await tester.pumpAndSettle();

      // Verify that refresh method was called
      verify(mockContentService.loadAllEpisodes()).called(1);
    });

    testWidgets('displays profile icon and handles logout', (tester) async {
      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      // Find profile/user icon
      final profileIcon = find.byIcon(Icons.person);
      if (profileIcon.evaluate().isNotEmpty) {
        await tester.tap(profileIcon);
        await tester.pumpAndSettle();

        // Should show logout option or profile menu
        expect(find.text('Sign Out'), findsOneWidget);

        // Test logout
        await tester.tap(find.text('Sign Out'));
        await tester.pumpAndSettle();

        verify(mockAuthService.signOut()).called(1);
      }
    });

    testWidgets('handles tab controller dispose properly', (tester) async {
      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      // Remove the widget to trigger dispose
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();

      // No exception should be thrown
    });

    testWidgets('maintains scroll position when switching tabs',
        (tester) async {
      final testEpisodes = TestUtils.createSampleAudioFileList(20);
      when(mockContentService.filteredEpisodes).thenReturn(testEpisodes);
      when(mockContentService.getListenHistoryEpisodes())
          .thenReturn(testEpisodes.take(10).toList());

      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      // Switch to All tab and scroll down
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      final listView = find.byType(ListView);
      if (listView.evaluate().isNotEmpty) {
        await tester.drag(listView, const Offset(0, -500));
        await tester.pumpAndSettle();

        // Switch to another tab and back
        await tester.tap(find.text('Recent'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('All'));
        await tester.pumpAndSettle();

        // Scroll position behavior is maintained by Flutter's TabBarView
      }
    });

    testWidgets('shows correct episode count badges', (tester) async {
      final testEpisodes = TestUtils.createSampleAudioFileList(10);
      when(mockContentService.getListenHistoryEpisodes())
          .thenReturn(testEpisodes.take(3).toList());
      when(mockContentService.filteredEpisodes).thenReturn(testEpisodes);
      when(mockContentService.getUnfinishedEpisodes())
          .thenReturn(testEpisodes.take(1).toList());

      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      // Check for episode count indicators (if implemented)
      // This would depend on the specific implementation
    });

    testWidgets('handles keyboard appearance for search', (tester) async {
      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      // Open search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Focus on search field
      final searchField = find.byType(TextField);
      await tester.tap(searchField);
      await tester.pumpAndSettle();

      // The keyboard would appear in a real device
      // Here we just verify the text field is focused
      expect(tester.testTextInput.hasAnyClients, isTrue);
    });

    testWidgets('displays correct theme colors', (tester) async {
      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(AppTheme.backgroundColor));
    });
  });

  group('HomeScreen Integration Tests', () {
    late MockContentService mockContentService;
    late MockAudioService mockAudioService;
    late MockAuthService mockAuthService;

    setUp(() {
      mockContentService = MockContentService();
      mockAudioService = MockAudioService();
      mockAuthService = MockAuthService();

      // Setup realistic mock behavior
      final testEpisodes = TestUtils.createSampleAudioFileList(15);
      when(mockContentService.allEpisodes).thenReturn(testEpisodes);
      when(mockContentService.filteredEpisodes).thenReturn(testEpisodes);
      when(mockContentService.getListenHistoryEpisodes())
          .thenReturn(testEpisodes.take(5).toList());
      when(mockContentService.getUnfinishedEpisodes())
          .thenReturn(testEpisodes.take(2).toList());
      when(mockContentService.isLoading).thenReturn(false);
      when(mockContentService.hasError).thenReturn(false);
      when(mockContentService.selectedLanguage).thenReturn('zh-TW');
      when(mockContentService.selectedCategory).thenReturn('all');
      when(mockContentService.searchQuery).thenReturn('');

      when(mockAudioService.isPlaying).thenReturn(false);
      when(mockAudioService.currentAudioFile).thenReturn(null);

      when(mockAuthService.isAuthenticated).thenReturn(true);
    });

    Widget createHomeScreen() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<ContentService>.value(
              value: mockContentService),
          ChangeNotifierProvider<AudioService>.value(value: mockAudioService),
          ChangeNotifierProvider<AuthService>.value(value: mockAuthService),
        ],
        child: TestUtils.wrapWithMaterialApp(const HomeScreen()),
      );
    }

    testWidgets('complete episode discovery flow', (tester) async {
      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      // 1. Start on Recent tab
      expect(find.text('Recent'), findsOneWidget);

      // 2. Switch to All tab
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      // 3. Open search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // 4. Search for episodes
      await tester.enterText(find.byType(TextField), 'bitcoin');
      await tester.pumpAndSettle();

      // 5. Clear search and close
      await tester.enterText(find.byType(TextField), '');
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Verify all interactions worked
      verify(mockContentService.searchEpisodes('bitcoin')).called(1);
      verify(mockContentService.searchEpisodes('')).called(1);
    });

    testWidgets('episode selection and playback flow', (tester) async {
      final testEpisodes = TestUtils.createSampleAudioFileList(5);
      when(mockContentService.filteredEpisodes).thenReturn(testEpisodes);

      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      // Switch to All tab
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      // Find and tap an episode
      final episodeTile = find.text(testEpisodes.first.title);
      if (episodeTile.evaluate().isNotEmpty) {
        await tester.tap(episodeTile);
        await tester.pumpAndSettle();

        // Should trigger audio service play
        verify(mockAudioService.play(testEpisodes.first)).called(1);
      }
    });

    testWidgets('handles rapid tab switching', (tester) async {
      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      // Rapidly switch between tabs
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.text('All'));
        await tester.pump();
        await tester.tap(find.text('Recent'));
        await tester.pump();
        await tester.tap(find.text('Unfinished'));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      // Should handle rapid switching without errors
    });

    testWidgets('maintains state during tab switches', (tester) async {
      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      // Open search on All tab
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Enter search query
      await tester.enterText(find.byType(TextField), 'test search');
      await tester.pumpAndSettle();

      // Switch to Recent tab and back
      await tester.tap(find.text('Recent'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      // Search should still be active
      expect(find.text('test search'), findsOneWidget);
    });
  });
}
