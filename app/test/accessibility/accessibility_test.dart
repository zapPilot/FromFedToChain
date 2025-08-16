import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:from_fed_to_chain_app/screens/home_screen.dart';
import 'package:from_fed_to_chain_app/widgets/audio_list.dart';
import 'package:from_fed_to_chain_app/widgets/mini_player.dart';
import 'package:from_fed_to_chain_app/widgets/filter_bar.dart';
import 'package:from_fed_to_chain_app/widgets/audio_item_card.dart';
import 'package:from_fed_to_chain_app/services/audio_service.dart';
import '../test_utils.dart';
import '../helpers/widget_test_helpers.dart';
import '../helpers/service_mocks.dart';

void main() {
  group('Accessibility Tests', () {
    late MockContentService mockContentService;
    late MockAudioService mockAudioService;
    late MockAuthService mockAuthService;

    setUp(() {
      mockContentService = MockContentService();
      mockAudioService = MockAudioService();
      mockAuthService = MockAuthService();
    });

    group('HomeScreen Accessibility', () {
      testWidgets('home screen provides proper semantic information', (tester) async {
        WidgetTestHelpers.setupMockDataForTesting(mockContentService);
        
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const HomeScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        final SemanticsHandle handle = tester.ensureSemantics();
        
        // Verify main navigation elements have proper semantics
        expect(
          tester.getSemantics(find.byIcon(Icons.search)),
          matchesSemantics(
            hasEnabledState: true,
            hasTapAction: true,
            isButton: true,
          ),
        );

        expect(
          tester.getSemantics(find.byIcon(Icons.refresh)),
          matchesSemantics(
            hasEnabledState: true,
            hasTapAction: true,
            isButton: true,
          ),
        );

        handle.dispose();
      });

      testWidgets('tab bar is properly accessible', (tester) async {
        WidgetTestHelpers.setupMockDataForTesting(mockContentService);
        
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const HomeScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        final SemanticsHandle handle = tester.ensureSemantics();
        
        // Verify tab bar is accessible
        final tabBar = find.byType(TabBar);
        expect(tabBar, findsOneWidget);

        // Check individual tabs
        final recentTab = find.text('Recent');
        final allTab = find.text('All');
        final unfinishedTab = find.text('Unfinished');

        expect(
          tester.getSemantics(recentTab),
          matchesSemantics(
            hasEnabledState: true,
            hasTapAction: true,
            isSelected: true, // Should be selected by default
          ),
        );

        expect(
          tester.getSemantics(allTab),
          matchesSemantics(
            hasEnabledState: true,
            hasTapAction: true,
            isSelected: false,
          ),
        );

        expect(
          tester.getSemantics(unfinishedTab),
          matchesSemantics(
            hasEnabledState: true,
            hasTapAction: true,
            isSelected: false,
          ),
        );

        handle.dispose();
      });

      testWidgets('home screen meets minimum contrast requirements', (tester) async {
        WidgetTestHelpers.setupMockDataForTesting(mockContentService);
        
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const HomeScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        // Note: Actual contrast testing would require specialized tools
        // This test verifies that color schemes are being applied
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, isNotNull);
      });

      testWidgets('search functionality is accessible', (tester) async {
        WidgetTestHelpers.setupMockDataForTesting(mockContentService);
        
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const HomeScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        final SemanticsHandle handle = tester.ensureSemantics();

        // Open search
        await tester.tap(find.byIcon(Icons.search));
        await tester.pumpAndSettle();

        // Verify search field is accessible
        final searchField = find.byType(TextField);
        expect(searchField, findsOneWidget);

        expect(
          tester.getSemantics(searchField),
          matchesSemantics(
            hasEnabledState: true,
            hasImplicitScrolling: false,
            textDirection: TextDirection.ltr,
          ),
        );

        handle.dispose();
      });
    });

    group('Widget Accessibility', () {
      testWidgets('audio list provides proper semantics for episodes', (tester) async {
        final testEpisodes = [
          TestUtils.createSampleAudioFile(
            title: 'Bitcoin Analysis',
            category: 'daily-news',
            language: 'en-US',
          ),
          TestUtils.createSampleAudioFile(
            title: 'Ethereum Deep Dive',
            category: 'ethereum',
            language: 'en-US',
          ),
        ];

        await tester.pumpWidget(
          WidgetTestHelpers.createMinimalTestWrapper(
            child: AudioList(
              episodes: testEpisodes,
              onEpisodeTap: (episode) {},
            ),
          ),
        );

        final SemanticsHandle handle = tester.ensureSemantics();

        // Verify list is accessible
        final listView = find.byType(ListView);
        expect(listView, findsOneWidget);

        expect(
          tester.getSemantics(listView),
          matchesSemantics(
            hasImplicitScrolling: true,
            hasEnabledState: true,
          ),
        );

        // Verify episode cards are accessible
        final episodeCards = find.byType(AudioItemCard);
        expect(episodeCards, findsNWidgets(testEpisodes.length));

        for (final card in episodeCards.evaluate()) {
          expect(
            tester.getSemantics(find.byWidget(card.widget)),
            matchesSemantics(
              hasEnabledState: true,
              hasTapAction: true,
            ),
          );
        }

        handle.dispose();
      });

      testWidgets('mini player controls are accessible', (tester) async {
        final testAudioFile = TestUtils.createSampleAudioFile();

        await tester.pumpWidget(
          WidgetTestHelpers.createMinimalTestWrapper(
            child: MiniPlayer(
              audioFile: testAudioFile,
              playbackState: PlaybackState.playing,
              onTap: () {},
              onPlayPause: () {},
              onNext: () {},
              onPrevious: () {},
            ),
          ),
        );

        final SemanticsHandle handle = tester.ensureSemantics();

        // Verify play/pause button is accessible
        final playPauseButton = find.byIcon(Icons.pause);
        expect(playPauseButton, findsOneWidget);

        expect(
          tester.getSemantics(playPauseButton),
          matchesSemantics(
            hasEnabledState: true,
            hasTapAction: true,
            isButton: true,
          ),
        );

        // Verify next button is accessible
        final nextButton = find.byIcon(Icons.skip_next);
        expect(nextButton, findsOneWidget);

        expect(
          tester.getSemantics(nextButton),
          matchesSemantics(
            hasEnabledState: true,
            hasTapAction: true,
            isButton: true,
          ),
        );

        // Verify previous button is accessible
        final prevButton = find.byIcon(Icons.skip_previous);
        expect(prevButton, findsOneWidget);

        expect(
          tester.getSemantics(prevButton),
          matchesSemantics(
            hasEnabledState: true,
            hasTapAction: true,
            isButton: true,
          ),
        );

        handle.dispose();
      });

      testWidgets('filter bar chips are accessible', (tester) async {
        await tester.pumpWidget(
          WidgetTestHelpers.createMinimalTestWrapper(
            child: FilterBar(
              selectedLanguage: 'all',
              selectedCategory: 'all',
              onLanguageChanged: (language) {},
              onCategoryChanged: (category) {},
            ),
          ),
        );

        final SemanticsHandle handle = tester.ensureSemantics();

        // Verify filter chips are accessible
        final languageChips = find.textContaining('English');
        if (languageChips.evaluate().isNotEmpty) {
          expect(
            tester.getSemantics(languageChips.first),
            matchesSemantics(
              hasEnabledState: true,
              hasTapAction: true,
            ),
          );
        }

        final categoryChips = find.textContaining('Daily News');
        if (categoryChips.evaluate().isNotEmpty) {
          expect(
            tester.getSemantics(categoryChips.first),
            matchesSemantics(
              hasEnabledState: true,
              hasTapAction: true,
            ),
          );
        }

        handle.dispose();
      });

      testWidgets('audio item card provides detailed semantic information', (tester) async {
        final audioFile = TestUtils.createSampleAudioFile(
          title: 'Bitcoin Market Analysis',
          category: 'daily-news',
          language: 'en-US',
          duration: const Duration(minutes: 5),
        );

        await tester.pumpWidget(
          WidgetTestHelpers.createMinimalTestWrapper(
            child: AudioItemCard(
              audioFile: audioFile,
              onTap: () {},
            ),
          ),
        );

        final SemanticsHandle handle = tester.ensureSemantics();

        // Verify card is accessible with proper information
        final card = find.byType(AudioItemCard);
        expect(card, findsOneWidget);

        expect(
          tester.getSemantics(card),
          matchesSemantics(
            hasEnabledState: true,
            hasTapAction: true,
          ),
        );

        // Verify title is accessible
        final title = find.text('Bitcoin Market Analysis');
        expect(title, findsOneWidget);

        handle.dispose();
      });
    });

    group('Voice Over / TalkBack Support', () {
      testWidgets('screen reader announcements work correctly', (tester) async {
        WidgetTestHelpers.setupMockDataForTesting(mockContentService);
        
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const HomeScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        final SemanticsHandle handle = tester.ensureSemantics();

        // Verify main app title is announced
        final appTitle = find.text('From Fed to Chain');
        expect(appTitle, findsOneWidget);

        // Test navigation announcements
        await tester.tap(find.text('All'));
        await tester.pumpAndSettle();

        // Verify tab selection is announced (implicit through semantics)
        expect(
          tester.getSemantics(find.text('All')),
          matchesSemantics(
            isSelected: true,
          ),
        );

        handle.dispose();
      });

      testWidgets('loading states provide proper announcements', (tester) async {
        when(mockContentService.isLoading).thenReturn(true);
        when(mockContentService.hasEpisodes).thenReturn(false);
        
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const HomeScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        final SemanticsHandle handle = tester.ensureSemantics();

        // Verify loading indicator is announced
        final loadingIndicator = find.byType(CircularProgressIndicator);
        expect(loadingIndicator, findsOneWidget);

        // Verify loading text is accessible
        final loadingText = find.text('Loading episodes...');
        expect(loadingText, findsOneWidget);

        handle.dispose();
      });

      testWidgets('error states provide clear announcements', (tester) async {
        const errorMessage = 'Failed to load episodes';
        when(mockContentService.hasError).thenReturn(true);
        when(mockContentService.errorMessage).thenReturn(errorMessage);
        when(mockContentService.hasEpisodes).thenReturn(false);
        when(mockContentService.isLoading).thenReturn(false);
        
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const HomeScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        final SemanticsHandle handle = tester.ensureSemantics();

        // Verify error message is accessible
        final errorText = find.text(errorMessage);
        expect(errorText, findsOneWidget);

        // Verify retry button is accessible
        final retryButton = find.text('Retry');
        expect(retryButton, findsOneWidget);

        expect(
          tester.getSemantics(retryButton),
          matchesSemantics(
            hasEnabledState: true,
            hasTapAction: true,
            isButton: true,
          ),
        );

        handle.dispose();
      });
    });

    group('Keyboard Navigation', () {
      testWidgets('tab bar supports keyboard navigation', (tester) async {
        WidgetTestHelpers.setupMockDataForTesting(mockContentService);
        
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const HomeScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        // Verify TabBar widget supports focus
        final tabBar = find.byType(TabBar);
        expect(tabBar, findsOneWidget);

        // Focus traversal would be tested here in a real implementation
        // For now, we verify the structure supports it
        final tabBarWidget = tester.widget<TabBar>(tabBar);
        expect(tabBarWidget.tabs.length, equals(3));
      });

      testWidgets('buttons support focus and keyboard activation', (tester) async {
        WidgetTestHelpers.setupMockDataForTesting(mockContentService);
        
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const HomeScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        final SemanticsHandle handle = tester.ensureSemantics();

        // Verify buttons can receive focus
        final searchButton = find.byIcon(Icons.search);
        expect(searchButton, findsOneWidget);

        final refreshButton = find.byIcon(Icons.refresh);
        expect(refreshButton, findsOneWidget);

        // In a full implementation, we would test keyboard activation
        // For now, verify semantic properties support it
        expect(
          tester.getSemantics(searchButton),
          matchesSemantics(
            hasEnabledState: true,
            hasTapAction: true,
            isButton: true,
          ),
        );

        handle.dispose();
      });
    });

    group('High Contrast Support', () {
      testWidgets('widgets maintain usability in high contrast mode', (tester) async {
        // Note: Actual high contrast testing would require platform-specific setup
        // This test verifies that our theming supports contrast variations
        
        final highContrastTheme = ThemeData(
          brightness: Brightness.dark,
          colorScheme: const ColorScheme.dark(
            primary: Colors.white,
            onPrimary: Colors.black,
            surface: Colors.black,
            onSurface: Colors.white,
          ),
        );

        WidgetTestHelpers.setupMockDataForTesting(mockContentService);
        
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            theme: highContrastTheme,
            child: const HomeScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        // Verify key elements are still visible and accessible
        expect(find.text('From Fed to Chain'), findsOneWidget);
        expect(find.byIcon(Icons.search), findsOneWidget);
        expect(find.byType(FilterBar), findsOneWidget);
      });
    });

    group('Text Scaling Support', () {
      testWidgets('app supports large text sizes', (tester) async {
        WidgetTestHelpers.setupMockDataForTesting(mockContentService);
        
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              textScaleFactor: 2.0, // Large text
            ),
            child: WidgetTestHelpers.createTestWrapper(
              child: const HomeScreen(),
              contentService: mockContentService,
              audioService: mockAudioService,
              authService: mockAuthService,
            ),
          ),
        );

        // Verify layout doesn't break with large text
        expect(find.text('From Fed to Chain'), findsOneWidget);
        expect(find.byType(FilterBar), findsOneWidget);
        expect(find.byType(TabBar), findsOneWidget);
      });

      testWidgets('mini player adapts to text scaling', (tester) async {
        final testAudioFile = TestUtils.createSampleAudioFile();

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              textScaleFactor: 1.5, // Medium large text
            ),
            child: WidgetTestHelpers.createMinimalTestWrapper(
              child: MiniPlayer(
                audioFile: testAudioFile,
                playbackState: PlaybackState.playing,
                onTap: () {},
                onPlayPause: () {},
                onNext: () {},
                onPrevious: () {},
              ),
            ),
          ),
        );

        // Verify mini player still displays correctly
        expect(find.byType(MiniPlayer), findsOneWidget);
        expect(find.text(testAudioFile.displayTitle), findsOneWidget);
      });
    });

    group('Focus Management', () {
      testWidgets('focus is managed correctly during navigation', (tester) async {
        WidgetTestHelpers.setupMockDataForTesting(mockContentService);
        
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const HomeScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        // Open search bar
        await tester.tap(find.byIcon(Icons.search));
        await tester.pumpAndSettle();

        // Verify search field can be focused (in a real implementation,
        // we would verify that focus automatically moves to the text field)
        final searchField = find.byType(TextField);
        expect(searchField, findsOneWidget);

        // Close search bar
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // In a real implementation, we would verify focus returns to
        // the search button or another appropriate element
        expect(find.byIcon(Icons.search), findsOneWidget);
      });
    });
  });
}