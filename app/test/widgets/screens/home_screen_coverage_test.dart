import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:from_fed_to_chain_app/features/content/screens/home_screen.dart';
import 'package:from_fed_to_chain_app/features/content/services/content_service.dart';
import 'package:from_fed_to_chain_app/features/audio/services/audio_player_service.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';
import 'package:from_fed_to_chain_app/features/audio/services/player_state_notifier.dart';

@GenerateMocks([ContentService, AudioPlayerService])
import 'home_screen_coverage_test.mocks.dart';

void main() {
  group('HomeScreen Coverage Tests', () {
    late MockContentService mockContentService;
    late MockAudioPlayerService mockAudioService;
    late AudioFile testAudioFile;

    setUp(() {
      mockContentService = MockContentService();
      mockAudioService = MockAudioPlayerService();

      testAudioFile = AudioFile(
        id: 'test-1',
        title: 'Test Episode',
        language: 'zh-TW',
        category: 'daily-news',
        streamingUrl: 'url',
        path: 'path',
        lastModified: DateTime.now(),
        duration: const Duration(minutes: 10),
      );

      // Default mocks
      when(mockContentService.selectedLanguage).thenReturn('all');
      when(mockContentService.selectedCategory).thenReturn('all');
      when(mockContentService.searchQuery).thenReturn('');
      when(mockContentService.sortOrder).thenReturn('newest');
      when(mockContentService.isLoading).thenReturn(false);
      when(mockContentService.hasError).thenReturn(false);
      when(mockContentService.errorMessage).thenReturn(null);
      when(mockContentService.allEpisodes).thenReturn([testAudioFile]);
      when(mockContentService.filteredEpisodes).thenReturn([testAudioFile]);
      when(mockContentService.hasEpisodes).thenReturn(true);
      when(mockContentService.hasFilteredResults).thenReturn(true);
      when(mockContentService.getStatistics())
          .thenReturn({'totalEpisodes': 1, 'filteredEpisodes': 1});
      when(mockContentService.getUnfinishedEpisodes()).thenReturn([]);
      when(mockContentService.currentPlaylist).thenReturn(null);

      when(mockAudioService.currentAudioFile).thenReturn(null);
      when(mockAudioService.playbackState).thenReturn(AppPlaybackState.stopped);
      when(mockAudioService.isPlaying).thenReturn(false);
      when(mockAudioService.isPaused).thenReturn(false);
      when(mockAudioService.isLoading).thenReturn(false);
      when(mockAudioService.hasError).thenReturn(false);
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<ContentService>.value(
                value: mockContentService),
            ChangeNotifierProvider<AudioPlayerService>.value(
                value: mockAudioService),
          ],
          child: const HomeScreen(),
        ),
      );
    }

    test('ContentServiceState equality', () {
      final state1 = ContentServiceState(
        allEpisodes: [],
        filteredEpisodes: [],
        isLoading: false,
        hasError: false,
        errorMessage: null,
        selectedLanguage: 'en',
        selectedCategory: 'all',
        searchQuery: '',
      );

      final state2 = ContentServiceState(
        allEpisodes: [],
        filteredEpisodes: [],
        isLoading: false,
        hasError: false,
        errorMessage: null,
        selectedLanguage: 'en',
        selectedCategory: 'all',
        searchQuery: '',
      );

      expect(state1, equals(state2));
      expect(state1.hashCode, equals(state2.hashCode));

      final state3 = ContentServiceState(
        allEpisodes: [],
        filteredEpisodes: [],
        isLoading: true, // changed
        hasError: false,
        errorMessage: null,
        selectedLanguage: 'en',
        selectedCategory: 'all',
        searchQuery: '',
      );

      expect(state1, isNot(equals(state3)));
    });

    testWidgets('Play Episode handles errors', (tester) async {
      when(mockAudioService.playAudio(any))
          .thenThrow(Exception('Playback failed'));

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      await tester.tap(find.text('Test Episode'));
      await tester.pump(); // Trigger play
      await tester.pump(const Duration(milliseconds: 100)); // Show snackbar

      expect(find.textContaining('Cannot play audio'), findsOneWidget);
    });

    testWidgets('Episode Options Sheet actions', (tester) async {
      // Increase screen size to avoid overflow in bottom sheet
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      await tester.longPress(find.text('Test Episode'));
      await tester.pumpAndSettle();

      // Tap Play
      await tester.tap(find.text('Play'));
      await tester.pumpAndSettle();
      verify(mockAudioService.playAudio(testAudioFile)).called(1);

      // Re-open
      await tester.longPress(find.text('Test Episode'));
      await tester.pumpAndSettle();

      // Tap Add to Favorites (TODO placeholder)
      await tester.tap(find.text('Add to Favorites'));
      await tester.pumpAndSettle();
      // Verify nothing broke

      // Re-open
      await tester.longPress(find.text('Test Episode'));
      await tester.pumpAndSettle();

      // Tap Share (TODO placeholder)
      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();
      // Verify nothing broke
    });

    testWidgets('Sort Selector options', (tester) async {
      // Use large screen
      tester.view.physicalSize = const Size(1200, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());

      // Open dropdown
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      // Select Alphabetical
      await tester.tap(find.text('A-Z').last);
      await tester.pumpAndSettle();
      verify(mockContentService.setSortOrder('alphabetical')).called(1);
    });

    testWidgets('MiniPlayer Stopped state text', (tester) async {
      when(mockAudioService.currentAudioFile).thenReturn(testAudioFile);
      when(mockAudioService.isPlaying).thenReturn(false);
      when(mockAudioService.isPaused).thenReturn(false);
      when(mockAudioService.isLoading).thenReturn(false);
      when(mockAudioService.hasError).thenReturn(false);
      // This implies Stopped

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Stopped'), findsOneWidget);
    });
  });
}
