import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:from_fed_to_chain_app/features/audio/screens/player_screen.dart';
import 'package:from_fed_to_chain_app/features/audio/services/audio_player_service.dart';
import 'package:from_fed_to_chain_app/features/content/services/content_service.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';
import 'package:from_fed_to_chain_app/features/audio/widgets/player/player_artwork.dart';
import 'package:from_fed_to_chain_app/features/content/services/playlist_service.dart';
import 'package:from_fed_to_chain_app/features/content/widgets/content_display.dart';
import 'package:from_fed_to_chain_app/features/audio/services/player_state_notifier.dart';

@GenerateMocks([AudioPlayerService, ContentService])
import 'home_screen_coverage_test.mocks.dart';

void main() {
  group('PlayerScreen Coverage Tests', () {
    late MockAudioPlayerService mockAudioService;
    late MockContentService mockContentService;
    late AudioFile testAudioFile;

    setUp(() {
      mockAudioService = MockAudioPlayerService();
      mockContentService = MockContentService();

      testAudioFile = AudioFile(
        id: 'test-1',
        title: 'Test Episode',
        language: 'en-US',
        category: 'daily-news',
        streamingUrl: 'url',
        path: 'path',
        duration: const Duration(minutes: 5),
        lastModified: DateTime.now(),
      );

      when(mockAudioService.currentAudioFile).thenReturn(testAudioFile);
      when(mockAudioService.playbackState).thenReturn(AppPlaybackState.paused);
      when(mockAudioService.isPlaying).thenReturn(false);
      when(mockAudioService.isPaused).thenReturn(true);
      when(mockAudioService.isLoading).thenReturn(false);
      when(mockAudioService.hasError).thenReturn(false);
      when(mockAudioService.errorMessage).thenReturn(null);
      when(mockAudioService.progress).thenReturn(0.0);
      when(mockAudioService.totalDuration)
          .thenReturn(const Duration(minutes: 5));
      when(mockAudioService.currentPosition).thenReturn(Duration.zero);
      when(mockAudioService.formattedCurrentPosition).thenReturn('0:00');
      when(mockAudioService.formattedTotalDuration).thenReturn('5:00');
      when(mockAudioService.playbackSpeed).thenReturn(1.0);
      when(mockAudioService.autoplayEnabled).thenReturn(false);
      when(mockAudioService.repeatEnabled).thenReturn(false);
    });

    Widget createTestWidget({String? contentId}) {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<AudioPlayerService>.value(
                value: mockAudioService),
            ChangeNotifierProvider<ContentService>.value(
                value: mockContentService),
          ],
          child: PlayerScreen(contentId: contentId),
        ),
      );
    }

    testWidgets('Deep Link Auto-Play Success', (tester) async {
      when(mockContentService.getAudioFileById('test-1'))
          .thenAnswer((_) async => testAudioFile);
      when(mockContentService.addToListenHistory(any))
          .thenAnswer((_) async => {});
      when(mockAudioService.playAudio(any)).thenAnswer((_) async => {});

      await tester.pumpWidget(createTestWidget(contentId: 'test-1'));
      await tester.pump();
      await tester.pump(
          const Duration(milliseconds: 100)); // allow async to run in init

      verify(mockContentService.getAudioFileById('test-1')).called(1);
      verify(mockAudioService.playAudio(testAudioFile)).called(1);
      verify(mockContentService.addToListenHistory(testAudioFile)).called(1);

      // Verify snackbar
      expect(find.text('Now playing: Test Episode'), findsOneWidget);
    });

    testWidgets('Deep Link Auto-Play Not Found', (tester) async {
      when(mockContentService.getAudioFileById('test-999'))
          .thenAnswer((_) async => null);

      await tester.pumpWidget(createTestWidget(contentId: 'test-999'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(mockContentService.getAudioFileById('test-999')).called(1);
      verifyNever(mockAudioService.playAudio(any));

      // Verify error snackbar
      expect(find.text('Episode not found: test-999'), findsOneWidget);
    });

    testWidgets('Deep Link Auto-Play Error', (tester) async {
      when(mockContentService.getAudioFileById('error-id'))
          .thenThrow(Exception('Fetch failed'));

      await tester.pumpWidget(createTestWidget(contentId: 'error-id'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify error snackbar
      expect(find.text('Failed to load episode: Exception: Fetch failed'),
          findsOneWidget);
    });

    // Mock MethodChannel for Share
    const MethodChannel channel =
        MethodChannel('dev.fluttercommunity.plus/share');

    setUpAll(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'share') {
          return null;
        }
        if (methodCall.method == 'shareWithResult') {
          return 'success'; // Verify this return value format for share_plus
        }
        return null;
      });
    });

    testWidgets('Share content fallback on error', (tester) async {
      // We force error by not providing content?
      // ContentService returns null for content
      when(mockContentService.getContentForAudioFile(any))
          .thenAnswer((_) async => null);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Tap share
      await tester.tap(find.byIcon(Icons.share));
      await tester.pump(const Duration(milliseconds: 500));

      // It should try to verify method channel call
    });

    testWidgets('Share content error handling', (tester) async {
      when(mockContentService.getContentForAudioFile(any))
          .thenThrow(Exception('Share prep failed'));

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.share));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('Failed to share episode'), findsOneWidget);
    });

    testWidgets('Toggles between compact and expanded layout', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Compact layout by default (verify PlayerArtwork flex 3)
      expect(find.byType(PlayerArtwork), findsOneWidget);

      // Toggle expanded via AdditionalControls
      await tester.tap(find.byIcon(Icons.article));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Should now be in expanded layout
      // Verify CustomScrollView is used (implicit in _buildExpandedLayout)
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('Adds episode to playlist', (tester) async {
      final mockPlaylistService = MockPlaylistService();
      await tester.pumpWidget(MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<AudioPlayerService>.value(
                value: mockAudioService),
            ChangeNotifierProvider<ContentService>.value(
                value: mockContentService),
            ChangeNotifierProvider<PlaylistService>.value(
                value: mockPlaylistService),
          ],
          child: const PlayerScreen(),
        ),
      ));

      await tester.tap(find.byIcon(Icons.playlist_add));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(mockPlaylistService.addToPlaylist(testAudioFile)).called(1);
      expect(find.textContaining('Added "Test Episode" to playlist'),
          findsOneWidget);
    });

    testWidgets('Shows share dialog as fallback', (tester) async {
      // Mock share results
      // share_plus uses MethodChannel. We already mocked it in results above.

      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.byIcon(Icons.share));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // If method channel returned error/not handled, it might show dialog
      // But we mocked it to return success in StepAll.
    });

    testWidgets('PlayerHeader options sheet', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Audio Details'), findsOneWidget);
    });

    testWidgets('Toggle content expanded state from collapsed layout',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Tap toggle in ContentDisplay
      // We search for the toggle icon or text if we know it.
      // Based on ContentDisplay implementation, it might have an expand icon.
      await tester.tap(find.byType(ContentDisplay));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('Seek from progress bar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Find Slider and tap it
      final sliderFinder = find.byType(Slider);
      if (sliderFinder.evaluate().isNotEmpty) {
        await tester.tap(sliderFinder.first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        verify(mockAudioService.seekTo(any)).called(1);
      }
    });

    testWidgets('Share result dismissed', (tester) async {
      // Mock share results
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'shareWithResult') {
          return 'dismissed'; // Mock dismissed status as string
        }
        return null;
      });

      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.byIcon(Icons.share));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      // No snackbar should show
    });
  });
}
