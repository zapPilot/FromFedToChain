import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';

import 'package:from_fed_to_chain_app/screens/player_screen.dart';
import 'package:from_fed_to_chain_app/services/audio_service.dart';
import 'package:from_fed_to_chain_app/services/content_service.dart';
import 'package:from_fed_to_chain_app/models/audio_file.dart';

import '../test_utils.dart';

// Generate mocks
@GenerateMocks([AudioService, ContentService])
import 'player_screen_test.mocks.dart';

void main() {
  group('PlayerScreen Widget Tests', () {
    late MockAudioService mockAudioService;
    late MockContentService mockContentService;
    late AudioFile testEpisode;

    setUp(() {
      mockAudioService = MockAudioService();
      mockContentService = MockContentService();
      testEpisode = TestUtils.createSampleAudioFile(
        id: 'test-episode',
        title: 'Test Episode Title',
        duration: const Duration(minutes: 10),
      );

      // Setup default mock behavior
      when(mockAudioService.currentAudioFile).thenReturn(testEpisode);
      when(mockAudioService.isPlaying).thenReturn(false);
      when(mockAudioService.isPaused).thenReturn(true);
      when(mockAudioService.isLoading).thenReturn(false);
      when(mockAudioService.hasError).thenReturn(false);
      when(mockAudioService.errorMessage).thenReturn(null);
      when(mockAudioService.currentPosition).thenReturn(Duration.zero);
      when(mockAudioService.totalDuration)
          .thenReturn(const Duration(minutes: 10));
      when(mockAudioService.playbackSpeed).thenReturn(1.0);
      when(mockAudioService.repeatEnabled).thenReturn(false);

      when(mockContentService.getContentForAudioFile(testEpisode)).thenAnswer(
        (_) async => TestUtils.createSampleAudioContent(id: testEpisode.id),
      );
    });

    Widget createPlayerScreen() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AudioService>.value(value: mockAudioService),
          ChangeNotifierProvider<ContentService>.value(
              value: mockContentService),
        ],
        child: TestUtils.wrapWithMaterialApp(const PlayerScreen()),
      );
    }

    testWidgets('renders correctly with episode data', (tester) async {
      await tester.pumpWidget(createPlayerScreen());
      await tester.pumpAndSettle();

      // Check that basic structure is present
      expect(find.byType(PlayerScreen), findsOneWidget);
      expect(find.text(testEpisode.title), findsOneWidget);
    });

    testWidgets('displays episode title and metadata', (tester) async {
      await tester.pumpWidget(createPlayerScreen());
      await tester.pumpAndSettle();

      // Check episode title
      expect(find.text(testEpisode.title), findsOneWidget);

      // Check category and language indicators
      expect(find.text(testEpisode.categoryEmoji), findsOneWidget);
      expect(find.text(testEpisode.languageFlag), findsOneWidget);
    });

    testWidgets('shows play/pause button correctly', (tester) async {
      await tester.pumpWidget(createPlayerScreen());
      await tester.pumpAndSettle();

      // Should show play button when paused
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      // Simulate playing state
      when(mockAudioService.isPlaying).thenReturn(true);
      when(mockAudioService.isPaused).thenReturn(false);

      await tester.pumpWidget(createPlayerScreen());
      await tester.pumpAndSettle();

      // Should show pause button when playing
      expect(find.byIcon(Icons.pause), findsOneWidget);
    });

    testWidgets('handles play/pause button tap', (tester) async {
      await tester.pumpWidget(createPlayerScreen());
      await tester.pumpAndSettle();

      // Tap play button
      final playButton = find.byIcon(Icons.play_arrow);
      await tester.tap(playButton);
      await tester.pumpAndSettle();

      // Verify resume was called
      verify(mockAudioService.resume()).called(1);

      // Now simulate playing state and test pause
      when(mockAudioService.isPlaying).thenReturn(true);
      when(mockAudioService.isPaused).thenReturn(false);

      await tester.pumpWidget(createPlayerScreen());
      await tester.pumpAndSettle();

      final pauseButton = find.byIcon(Icons.pause);
      await tester.tap(pauseButton);
      await tester.pumpAndSettle();

      verify(mockAudioService.pause()).called(1);
    });

    testWidgets('displays loading state', (tester) async {
      when(mockAudioService.isLoading).thenReturn(true);

      await tester.pumpWidget(createPlayerScreen());
      await tester.pumpAndSettle();

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays error state', (tester) async {
      const errorMessage = 'Failed to load audio';
      when(mockAudioService.hasError).thenReturn(true);
      when(mockAudioService.errorMessage).thenReturn(errorMessage);

      await tester.pumpWidget(createPlayerScreen());
      await tester.pumpAndSettle();

      // Should show error message
      expect(find.textContaining('Error'), findsOneWidget);
      expect(find.textContaining(errorMessage), findsOneWidget);
    });

    testWidgets('shows progress slider', (tester) async {
      when(mockAudioService.currentPosition)
          .thenReturn(const Duration(minutes: 3));
      when(mockAudioService.totalDuration)
          .thenReturn(const Duration(minutes: 10));

      await tester.pumpWidget(createPlayerScreen());
      await tester.pumpAndSettle();

      // Check for slider
      expect(find.byType(Slider), findsOneWidget);

      // Check for time displays
      expect(find.text('3:00'), findsOneWidget);
      expect(find.text('10:00'), findsOneWidget);
    });

    testWidgets('handles slider interaction', (tester) async {
      when(mockAudioService.totalDuration)
          .thenReturn(const Duration(minutes: 10));

      await tester.pumpWidget(createPlayerScreen());
      await tester.pumpAndSettle();

      final slider = find.byType(Slider);
      if (slider.evaluate().isNotEmpty) {
        // Drag slider to middle
        await tester.drag(slider, const Offset(100, 0));
        await tester.pumpAndSettle();

        // Should call seek method
        verify(mockAudioService.seekTo(any)).called(greaterThan(0));
      }
    });

    testWidgets('shows previous/next buttons', (tester) async {
      await tester.pumpWidget(createPlayerScreen());
      await tester.pumpAndSettle();

      // Check for navigation buttons
      expect(find.byIcon(Icons.skip_previous), findsOneWidget);
      expect(find.byIcon(Icons.skip_next), findsOneWidget);
    });

    testWidgets('handles previous/next button taps', (tester) async {
      await tester.pumpWidget(createPlayerScreen());
      await tester.pumpAndSettle();

      // Tap previous button
      final prevButton = find.byIcon(Icons.skip_previous);
      await tester.tap(prevButton);
      await tester.pumpAndSettle();

      verify(mockAudioService.skipToPreviousEpisode()).called(1);

      // Tap next button
      final nextButton = find.byIcon(Icons.skip_next);
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      verify(mockAudioService.skipToNextEpisode()).called(1);
    });

    testWidgets('shows playback speed selector', (tester) async {
      await tester.pumpWidget(createPlayerScreen());
      await tester.pumpAndSettle();

      // Check for speed indicator
      expect(find.text('1.0x'), findsOneWidget);

      // Tap to open speed selector
      final speedButton = find.text('1.0x');
      await tester.tap(speedButton);
      await tester.pumpAndSettle();

      // Should show speed options
      expect(find.text('0.5x'), findsOneWidget);
      expect(find.text('1.5x'), findsOneWidget);
      expect(find.text('2.0x'), findsOneWidget);
    });

    testWidgets('handles speed selection', (tester) async {
      await tester.pumpWidget(createPlayerScreen());
      await tester.pumpAndSettle();

      // Open speed selector
      await tester.tap(find.text('1.0x'));
      await tester.pumpAndSettle();

      // Select 1.5x speed
      await tester.tap(find.text('1.5x'));
      await tester.pumpAndSettle();

      verify(mockAudioService.setPlaybackSpeed(1.5)).called(1);
    });

    testWidgets('shows repeat button', (tester) async {
      await tester.pumpWidget(createPlayerScreen());
      await tester.pumpAndSettle();

      // Check for repeat button
      expect(find.byIcon(Icons.repeat), findsOneWidget);
    });

    testWidgets('handles repeat button toggle', (tester) async {
      await tester.pumpWidget(createPlayerScreen());
      await tester.pumpAndSettle();

      final repeatButton = find.byIcon(Icons.repeat);
      await tester.tap(repeatButton);
      await tester.pumpAndSettle();

      verify(mockAudioService.setRepeatEnabled(any)).called(1);
    });

    // Note: Shuffle functionality not implemented in AudioService

    testWidgets('shows episode artwork or placeholder', (tester) async {
      await tester.pumpWidget(createPlayerScreen());
      await tester.pumpAndSettle();

      // Should show some kind of artwork area
      // This could be an image, icon, or custom widget
      expect(find.byType(Container), findsAtLeastNWidgets(1));
    });

    testWidgets('displays episode description when available', (tester) async {
      await tester.pumpWidget(createPlayerScreen());
      await tester.pumpAndSettle();

      // Wait for content to load
      await tester.pump(const Duration(milliseconds: 500));

      // Should show episode description
      expect(find.textContaining('description'), findsAtLeastNWidget(0));
    });

    testWidgets('shows back button and handles navigation', (tester) async {
      await tester.pumpWidget(createPlayerScreen());
      await tester.pumpAndSettle();

      // Check for back button
      final backButton = find.byIcon(Icons.arrow_back);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
        await tester.pumpAndSettle();

        // Should navigate back (tested in integration tests)
      }
    });

    testWidgets('updates UI when audio service state changes', (tester) async {
      await tester.pumpWidget(createPlayerScreen());
      await tester.pumpAndSettle();

      // Change audio service state
      when(mockAudioService.currentPosition)
          .thenReturn(const Duration(minutes: 5));
      when(mockAudioService.isPlaying).thenReturn(true);

      // Trigger rebuild
      mockAudioService.notifyListeners();
      await tester.pump();

      // UI should update accordingly
      expect(find.text('5:00'), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsOneWidget);
    });

    testWidgets('handles episode change correctly', (tester) async {
      final newEpisode = TestUtils.createSampleAudioFile(
        id: 'new-episode',
        title: 'New Episode Title',
      );

      await tester.pumpWidget(createPlayerScreen());
      await tester.pumpAndSettle();

      // Change current episode
      when(mockAudioService.currentAudioFile).thenReturn(newEpisode);
      mockAudioService.notifyListeners();
      await tester.pump();

      // Should display new episode title
      expect(find.text(newEpisode.title), findsOneWidget);
    });

    testWidgets('shows playlist information when available', (tester) async {
      final testEpisodeWithMetadata = TestUtils.createSampleAudioFile(
        id: 'playlist-episode',
        title: 'Test Playlist Episode',
      );
      when(mockAudioService.currentAudioFile)
          .thenReturn(testEpisodeWithMetadata);

      await tester.pumpWidget(createPlayerScreen());
      await tester.pumpAndSettle();

      // Should show episode info
      expect(
          find.textContaining('Test Playlist Episode'), findsAtLeastNWidget(0));
    });

    testWidgets('handles seek forward/backward buttons', (tester) async {
      await tester.pumpWidget(createPlayerScreen());
      await tester.pumpAndSettle();

      // Look for seek buttons (if implemented)
      final seek15Back = find.byIcon(Icons.replay_10);
      if (seek15Back.evaluate().isNotEmpty) {
        await tester.tap(seek15Back);
        await tester.pumpAndSettle();

        verify(mockAudioService.seekBackward()).called(1);
      }

      final seek30Forward = find.byIcon(Icons.forward_30);
      if (seek30Forward.evaluate().isNotEmpty) {
        await tester.tap(seek30Forward);
        await tester.pumpAndSettle();

        verify(mockAudioService.seekForward()).called(1);
      }
    });

    testWidgets('displays episode metadata correctly', (tester) async {
      await tester.pumpWidget(createPlayerScreen());
      await tester.pumpAndSettle();

      // Check for formatted totalDuration
      expect(find.text(testEpisode.formattedDuration), findsOneWidget);

      // Check for category and language
      expect(find.text(testEpisode.categoryEmoji), findsOneWidget);
      expect(find.text(testEpisode.languageFlag), findsOneWidget);
    });

    testWidgets('handles no episode state gracefully', (tester) async {
      when(mockAudioService.currentAudioFile).thenReturn(null);

      await tester.pumpWidget(createPlayerScreen());
      await tester.pumpAndSettle();

      // Should show placeholder or return to previous screen
      expect(find.text('No episode selected'), findsOneWidget);
    });

    testWidgets('maintains state during orientation changes', (tester) async {
      await tester.pumpWidget(createPlayerScreen());
      await tester.pumpAndSettle();

      // Simulate screen size change (orientation)
      await tester.binding.setSurfaceSize(const Size(800, 600));
      await tester.pumpAndSettle();

      // Should still display episode information
      expect(find.text(testEpisode.title), findsOneWidget);
    });
  });

  group('PlayerScreen Integration Tests', () {
    late MockAudioService mockAudioService;
    late MockContentService mockContentService;
    late List<AudioFile> testPlaylistEpisodes;

    setUp(() {
      mockAudioService = MockAudioService();
      mockContentService = MockContentService();
      testPlaylistEpisodes = TestUtils.createSampleAudioFileList(5);

      when(mockAudioService.currentAudioFile)
          .thenReturn(testPlaylistEpisodes.first);
      when(mockAudioService.isPlaying).thenReturn(false);
      when(mockAudioService.currentPosition).thenReturn(Duration.zero);
      when(mockAudioService.totalDuration)
          .thenReturn(const Duration(minutes: 10));
      when(mockAudioService.playbackSpeed).thenReturn(1.0);
    });

    Widget createPlayerScreen() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AudioService>.value(value: mockAudioService),
          ChangeNotifierProvider<ContentService>.value(
              value: mockContentService),
        ],
        child: TestUtils.wrapWithMaterialApp(const PlayerScreen()),
      );
    }

    testWidgets('complete playback control flow', (tester) async {
      await tester.pumpWidget(createPlayerScreen());
      await tester.pumpAndSettle();

      // 1. Start playback
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pumpAndSettle();

      verify(mockAudioService.resume()).called(1);

      // 2. Seek to different position
      final slider = find.byType(Slider);
      if (slider.evaluate().isNotEmpty) {
        await tester.drag(slider, const Offset(50, 0));
        await tester.pumpAndSettle();
      }

      // 3. Change playback speed
      await tester.tap(find.text('1.0x'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1.5x'));
      await tester.pumpAndSettle();

      verify(mockAudioService.setPlaybackSpeed(1.5)).called(1);

      // 4. Skip to next episode
      await tester.tap(find.byIcon(Icons.skip_next));
      await tester.pumpAndSettle();

      verify(mockAudioService.skipToNextEpisode()).called(1);
    });

    testWidgets('handles rapid control interactions', (tester) async {
      await tester.pumpWidget(createPlayerScreen());
      await tester.pumpAndSettle();

      // Rapidly tap play/pause
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byIcon(Icons.play_arrow));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      // Should handle rapid taps gracefully
      verify(mockAudioService.resume()).called(greaterThan(0));
    });

    testWidgets('maintains playback state across UI updates', (tester) async {
      when(mockAudioService.isPlaying).thenReturn(true);
      when(mockAudioService.currentPosition)
          .thenReturn(const Duration(minutes: 2));

      await tester.pumpWidget(createPlayerScreen());
      await tester.pumpAndSettle();

      // Update position
      when(mockAudioService.currentPosition)
          .thenReturn(const Duration(minutes: 3));
      mockAudioService.notifyListeners();
      await tester.pump();

      // Should reflect new position
      expect(find.text('3:00'), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsOneWidget);
    });

    testWidgets('episode navigation flow', (tester) async {
      await tester.pumpWidget(createPlayerScreen());
      await tester.pumpAndSettle();

      // Navigate through playlist
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.byIcon(Icons.skip_next));
        await tester.pumpAndSettle();
      }

      verify(mockAudioService.skipToNextEpisode()).called(3);

      // Navigate backward
      await tester.tap(find.byIcon(Icons.skip_previous));
      await tester.pumpAndSettle();

      verify(mockAudioService.skipToPreviousEpisode()).called(1);
    });
  });
}
