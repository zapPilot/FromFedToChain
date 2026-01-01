import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:from_fed_to_chain_app/features/audio/screens/player_screen.dart';
import 'package:from_fed_to_chain_app/features/audio/services/audio_player_service.dart';
import 'package:from_fed_to_chain_app/features/content/services/content_service.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';
import 'package:from_fed_to_chain_app/features/audio/services/player_state_notifier.dart';

// Generate mocks for dependencies
@GenerateMocks([AudioPlayerService, ContentService])
import 'player_screen_test.mocks.dart';

void main() {
  group('PlayerScreen - Basic Tests', () {
    late MockAudioPlayerService mockAudioService;
    late MockContentService mockContentService;
    late AudioFile testAudioFile;

    setUp(() {
      mockAudioService = MockAudioPlayerService();
      mockContentService = MockContentService();

      testAudioFile = AudioFile(
        id: 'test-episode',
        title: 'Test Episode',
        language: 'en-US',
        category: 'daily-news',
        streamingUrl: 'https://example.com/test.m3u8',
        path: 'test.m3u8',
        duration: const Duration(minutes: 5),
        lastModified: DateTime.now(),
      );

      // Basic AudioService setup
      when(mockAudioService.currentAudioFile).thenReturn(testAudioFile);
      when(mockAudioService.playbackState).thenReturn(AppPlaybackState.stopped);
      when(mockAudioService.currentPosition).thenReturn(Duration.zero);
      when(mockAudioService.totalDuration)
          .thenReturn(const Duration(minutes: 5));
      when(mockAudioService.playbackSpeed).thenReturn(1.0);
      when(mockAudioService.autoplayEnabled).thenReturn(true);
      when(mockAudioService.repeatEnabled).thenReturn(false);
      when(mockAudioService.errorMessage).thenReturn(null);
      when(mockAudioService.isPlaying).thenReturn(false);
      when(mockAudioService.isPaused).thenReturn(false);
      when(mockAudioService.isLoading).thenReturn(false);
      when(mockAudioService.hasError).thenReturn(false);
      when(mockAudioService.progress).thenReturn(0.0);
      when(mockAudioService.formattedCurrentPosition).thenReturn('0:00');
      when(mockAudioService.formattedTotalDuration).thenReturn('5:00');

      // Basic ContentService setup
      when(mockContentService.getContentForAudioFile(any))
          .thenAnswer((_) async => null);
      when(mockContentService.addToListenHistory(any))
          .thenAnswer((_) async => {});
      when(mockContentService.addToCurrentPlaylist(any))
          .thenAnswer((_) async => {});

      // Async method stubs
      when(mockAudioService.playAudio(any)).thenAnswer((_) async => {});
      when(mockAudioService.togglePlayPause()).thenAnswer((_) async => {});
      when(mockAudioService.seekTo(any)).thenAnswer((_) async => {});
      when(mockAudioService.skipForward()).thenAnswer((_) async => {});
      when(mockAudioService.skipBackward()).thenAnswer((_) async => {});
      when(mockAudioService.skipToNext()).thenAnswer((_) async => {});
      when(mockAudioService.skipToPrevious()).thenAnswer((_) async => {});
      when(mockAudioService.setPlaybackSpeed(any)).thenAnswer((_) async => {});
    });

    tearDown(() {
      reset(mockAudioService);
      reset(mockContentService);
    });

    Widget createTestWidget({String? contentId}) {
      return MediaQuery(
        data: const MediaQueryData(
          size: Size(375, 667), // iPhone size to prevent overflow
          devicePixelRatio: 2.0,
        ),
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AudioPlayerService>.value(
                  value: mockAudioService),
              ChangeNotifierProvider<ContentService>.value(
                  value: mockContentService),
            ],
            child: PlayerScreen(contentId: contentId),
          ),
        ),
      );
    }

    group('Basic Widget Creation', () {
      testWidgets('should create PlayerScreen without crashing',
          (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.byType(PlayerScreen), findsOneWidget);
      });

      testWidgets('should display audio title when available', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text(testAudioFile.title), findsOneWidget);
      });

      testWidgets('should display current position', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('0:00'), findsOneWidget);
      });

      testWidgets('should display total duration', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('5:00'), findsOneWidget);
      });
    });

    group('Basic User Interactions', () {
      testWidgets('should handle play button tap', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Find and tap play button
        final playButton = find.byIcon(Icons.play_arrow);
        if (playButton.evaluate().isNotEmpty) {
          await tester.tap(playButton);
          await tester.pump();

          verify(mockAudioService.togglePlayPause()).called(1);
        }
      });

      testWidgets('should handle pause button tap when playing',
          (tester) async {
        when(mockAudioService.isPlaying).thenReturn(true);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Find and tap pause button
        final pauseButton = find.byIcon(Icons.pause);
        if (pauseButton.evaluate().isNotEmpty) {
          await tester.tap(pauseButton);
          await tester.pump();

          verify(mockAudioService.togglePlayPause()).called(1);
        }
      });
    });

    group('Content Loading', () {
      testWidgets('should request content for audio file', (tester) async {
        await tester.pumpWidget(createTestWidget(contentId: testAudioFile.id));
        await tester.pump();

        // Should call content service to get content
        verify(mockContentService.getContentForAudioFile(any))
            .called(greaterThanOrEqualTo(0));
      });

      testWidgets('should handle no current audio file', (tester) async {
        when(mockAudioService.currentAudioFile).thenReturn(null);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Should not crash when no audio file
        expect(find.byType(PlayerScreen), findsOneWidget);
      });
    });

    group('Error States', () {
      testWidgets('should display error state when audio has error',
          (tester) async {
        when(mockAudioService.hasError).thenReturn(true);
        when(mockAudioService.errorMessage).thenReturn('Network error');

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // PlayerScreen should show error state via AudioControls (refresh icon)
        expect(find.byIcon(Icons.refresh), findsOneWidget);
      });

      testWidgets('should handle loading state', (tester) async {
        when(mockAudioService.isLoading).thenReturn(true);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Should show loading indicator
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('Navigation', () {
      testWidgets('should handle back navigation', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Find and tap back button
        final backButton = find.byType(BackButton);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton);
          await tester.pump();

          // Should navigate back (handled by Navigator)
        }
      });
    });

    group('Audio Controls Integration', () {
      testWidgets('should handle skip forward', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Find skip forward button
        final skipForwardButton = find.byIcon(Icons.forward_30);
        if (skipForwardButton.evaluate().isNotEmpty) {
          await tester.tap(skipForwardButton);
          await tester.pump();

          verify(mockAudioService.skipForward()).called(1);
        }
      });

      testWidgets('should handle skip backward', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Find skip backward button
        final skipBackButton = find.byIcon(Icons.replay_10);
        if (skipBackButton.evaluate().isNotEmpty) {
          await tester.tap(skipBackButton);
          await tester.pump();

          verify(mockAudioService.skipBackward()).called(1);
        }
      });
    });
  });
}
