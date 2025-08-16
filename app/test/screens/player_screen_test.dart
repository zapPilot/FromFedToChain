import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:from_fed_to_chain_app/screens/player_screen.dart';
import 'package:from_fed_to_chain_app/widgets/audio_controls.dart';
import 'package:from_fed_to_chain_app/widgets/playback_speed_selector.dart';
import 'package:from_fed_to_chain_app/widgets/content_display.dart';
import 'package:from_fed_to_chain_app/services/audio_service.dart';
import 'package:from_fed_to_chain_app/models/audio_file.dart';
import '../test_utils.dart';
import '../helpers/widget_test_helpers.dart';
import '../helpers/service_mocks.dart';
import '../helpers/service_mocks.mocks.dart';

void main() {
  group('PlayerScreen Tests', () {
    late MockContentService mockContentService;
    late MockAudioService mockAudioService;
    late MockAuthService mockAuthService;

    setUp(() {
      mockContentService = MockContentService();
      mockAudioService = MockAudioService();
      mockAuthService = MockAuthService();
    });

    group('Without Current Audio', () {
      testWidgets('displays no audio state when no audio is playing', (tester) async {
        when(mockAudioService.currentAudioFile).thenReturn(null);
        
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const PlayerScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        // Verify no audio state is displayed
        expect(find.text('No audio playing'), findsOneWidget);
        expect(find.text('Select an episode to start listening'), findsOneWidget);
        expect(find.byIcon(Icons.music_off), findsOneWidget);
        expect(find.text('Browse Episodes'), findsOneWidget);
      });

      testWidgets('browse episodes button navigates back', (tester) async {
        when(mockAudioService.currentAudioFile).thenReturn(null);
        
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapperWithNavigation(
            child: const PlayerScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        // Tap browse episodes button
        await tester.tap(find.text('Browse Episodes'));
        await tester.pumpAndSettle();

        // Navigation should be attempted (can't verify actual navigation in widget test)
        expect(find.text('Browse Episodes'), findsOneWidget);
      });
    });

    group('With Current Audio', () {
      late AudioFile testAudioFile;

      setUp(() {
        testAudioFile = TestUtils.createSampleAudioFile(
          id: 'test-episode',
          title: 'Test Bitcoin Analysis',
          category: 'daily-news',
          language: 'en-US',
        );
        when(mockAudioService.currentAudioFile).thenReturn(testAudioFile);
        when(mockAudioService.playbackState).thenReturn(PlaybackState.playing);
        when(mockAudioService.isPlaying).thenReturn(true);
        when(mockAudioService.currentPosition).thenReturn(const Duration(minutes: 2));
        when(mockAudioService.totalDuration).thenReturn(const Duration(minutes: 10));
        when(mockAudioService.progress).thenReturn(0.2);
        when(mockAudioService.playbackSpeed).thenReturn(1.0);
        when(mockAudioService.formattedCurrentPosition).thenReturn('2:00');
        when(mockAudioService.formattedTotalDuration).thenReturn('10:00');
        when(mockAudioService.isLoading).thenReturn(false);
        when(mockAudioService.hasError).thenReturn(false);
        when(mockAudioService.errorMessage).thenReturn(null);
      });

      testWidgets('displays header with correct elements', (tester) async {
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const PlayerScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        // Verify header elements
        expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
        
        // Verify episode title and metadata
        expect(find.text(testAudioFile.displayTitle), findsOneWidget);
        expect(find.text('Test Bitcoin Analysis'), findsOneWidget);
        
        // Verify audio controls are present
        expect(find.byType(AudioControls), findsOneWidget);
        
        // Verify playback speed selector
        expect(find.byType(PlaybackSpeedSelector), findsOneWidget);
        
        // Verify content display
        expect(find.byType(ContentDisplay), findsOneWidget);
      });
      
      testWidgets('displays audio controls with correct state', (tester) async {
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const PlayerScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );
        
        // Verify play/pause button shows pause (since it's playing)
        expect(find.byIcon(Icons.pause), findsOneWidget);
        
        // Verify skip buttons are present
        expect(find.byIcon(Icons.skip_previous), findsOneWidget);
        expect(find.byIcon(Icons.skip_next), findsOneWidget);
        
        // Verify progress indicators
        expect(find.text('2:00'), findsOneWidget);
        expect(find.text('10:00'), findsOneWidget);
      });
      
      testWidgets('handles play/pause button tap', (tester) async {
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const PlayerScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );
        
        // Tap play/pause button
        await tester.tap(find.byIcon(Icons.pause));
        await tester.pumpAndSettle();
        
        // Verify the audio service method was called
        verify(mockAudioService.togglePlayPause()).called(1);
      });
      
      testWidgets('displays playback speed options', (tester) async {
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const PlayerScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );
        
        // Verify current speed is displayed
        expect(find.text('1.0x'), findsOneWidget);
        expect(find.text('NOW PLAYING'), findsOneWidget);
        expect(find.text('From Fed to Chain'), findsOneWidget);
        expect(find.byIcon(Icons.more_vert), findsOneWidget);
      });

      testWidgets('displays album art with correct styling', (tester) async {
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const PlayerScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        // Verify album art container
        expect(find.byType(RotationTransition), findsAtLeastNWidgets(1));
        expect(find.byIcon(Icons.newspaper), findsOneWidget); // daily-news category icon
      });

      testWidgets('displays playback state indicator correctly', (tester) async {
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const PlayerScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        // Verify playback state indicator
        expect(find.text('Playing'), findsOneWidget);
        expect(find.byIcon(Icons.play_arrow), findsAtLeastNWidgets(1));
      });

      testWidgets('displays track information correctly', (tester) async {
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const PlayerScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        // Verify track title
        expect(find.text('Test Bitcoin Analysis'), findsOneWidget);
        
        // Verify category and language information
        expect(find.text('📰'), findsOneWidget); // daily-news emoji
        expect(find.text('🇺🇸'), findsOneWidget); // en-US flag
      });

      testWidgets('displays progress section with correct values', (tester) async {
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const PlayerScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        // Verify progress slider
        expect(find.byType(Slider), findsOneWidget);
        
        // Verify time labels
        expect(find.text('2:00'), findsOneWidget);
        expect(find.text('10:00'), findsOneWidget);
      });

      testWidgets('displays audio controls correctly', (tester) async {
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const PlayerScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        // Verify audio controls are present
        expect(find.byType(AudioControls), findsOneWidget);
      });

      testWidgets('displays additional control buttons', (tester) async {
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const PlayerScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        // Verify additional control buttons
        expect(find.byIcon(Icons.article), findsOneWidget); // Content script toggle
        expect(find.byIcon(Icons.speed), findsOneWidget); // Speed selector
        expect(find.byIcon(Icons.repeat), findsOneWidget); // Repeat toggle
        expect(find.byIcon(Icons.playlist_play), findsOneWidget); // Autoplay toggle
        expect(find.byIcon(Icons.share), findsOneWidget); // Share button
        expect(find.byIcon(Icons.playlist_add), findsOneWidget); // Add to playlist
      });

      testWidgets('handles back button correctly', (tester) async {
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapperWithNavigation(
            child: const PlayerScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        // Tap back button
        await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
        await tester.pumpAndSettle();

        // Navigation should be attempted
      });

      testWidgets('toggles content script correctly', (tester) async {
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const PlayerScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        // Initially content script should not be expanded
        expect(find.byType(ContentDisplay), findsOneWidget);

        // Tap content script toggle
        await tester.tap(find.byIcon(Icons.article));
        await tester.pumpAndSettle();

        // Content script should still be present but expanded state may change
        expect(find.byType(ContentDisplay), findsOneWidget);
      });

      testWidgets('shows speed selector when speed button is tapped', (tester) async {
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const PlayerScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        // Initially speed selector should not be visible
        expect(find.byType(PlaybackSpeedSelector), findsNothing);

        // Tap speed button
        await tester.tap(find.byIcon(Icons.speed));
        await tester.pumpAndSettle();

        // Speed selector should now be visible
        expect(find.byType(PlaybackSpeedSelector), findsOneWidget);
      });

      testWidgets('handles repeat toggle correctly', (tester) async {
        when(mockAudioService.repeatEnabled).thenReturn(false);
        
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const PlayerScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        // Tap repeat button
        await tester.tap(find.byIcon(Icons.repeat));
        await tester.pumpAndSettle();

        // Verify setRepeatEnabled was called
        verify(mockAudioService.setRepeatEnabled(true)).called(1);
      });

      testWidgets('handles autoplay toggle correctly', (tester) async {
        when(mockAudioService.autoplayEnabled).thenReturn(false);
        
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const PlayerScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        // Tap autoplay button
        await tester.tap(find.byIcon(Icons.playlist_play));
        await tester.pumpAndSettle();

        // Verify setAutoplayEnabled was called
        verify(mockAudioService.setAutoplayEnabled(true)).called(1);
      });

      testWidgets('handles share button correctly', (tester) async {
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const PlayerScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        // Tap share button
        await tester.tap(find.byIcon(Icons.share));
        await tester.pumpAndSettle();

        // Verify content loading was attempted for sharing
        verify(mockContentService.getContentForAudioFile(any)).called(1);
      });

      testWidgets('handles add to playlist correctly', (tester) async {
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const PlayerScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        // Tap add to playlist button
        await tester.tap(find.byIcon(Icons.playlist_add));
        await tester.pumpAndSettle();

        // Verify addToCurrentPlaylist was called
        verify(mockContentService.addToCurrentPlaylist(any)).called(1);
        
        // Verify snackbar is shown
        expect(find.byType(SnackBar), findsOneWidget);
      });

      testWidgets('handles progress slider changes', (tester) async {
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const PlayerScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        // Find and interact with slider
        final sliderFinder = find.byType(Slider);
        expect(sliderFinder, findsOneWidget);

        // Simulate slider drag
        await tester.tap(sliderFinder);
        await tester.pumpAndSettle();

        // Verify seekTo was called (would be called with calculated position)
        verify(mockAudioService.seekTo(any)).called(1);
      });

      testWidgets('shows player options when more button is tapped', (tester) async {
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const PlayerScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        // Tap more options button
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        // Verify bottom sheet is shown
        expect(find.text('Audio Details'), findsOneWidget);
        expect(find.text('Test Bitcoin Analysis'), findsAtLeastNWidgets(1));
      });

      testWidgets('displays different playback states correctly', (tester) async {
        // Test paused state
        when(mockAudioService.playbackState).thenReturn(PlaybackState.paused);
        when(mockAudioService.isPlaying).thenReturn(false);
        
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const PlayerScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        expect(find.text('Paused'), findsOneWidget);
        expect(find.byIcon(Icons.pause), findsAtLeastNWidgets(1));

        // Test loading state
        when(mockAudioService.playbackState).thenReturn(PlaybackState.loading);
        
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const PlayerScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        expect(find.text('Loading...'), findsOneWidget);
        expect(find.byIcon(Icons.hourglass_empty), findsOneWidget);

        // Test error state
        when(mockAudioService.playbackState).thenReturn(PlaybackState.error);
        
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const PlayerScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        expect(find.text('Error'), findsOneWidget);
        expect(find.byIcon(Icons.error), findsOneWidget);
      });

      testWidgets('displays correct category icons for different categories', (tester) async {
        final categories = {
          'daily-news': Icons.newspaper,
          'ethereum': Icons.currency_bitcoin,
          'macro': Icons.trending_up,
          'startup': Icons.rocket_launch,
          'ai': Icons.smart_toy,
          'defi': Icons.account_balance,
        };

        for (final entry in categories.entries) {
          final testAudio = TestUtils.createSampleAudioFile(
            category: entry.key,
          );
          when(mockAudioService.currentAudioFile).thenReturn(testAudio);
          
          await tester.pumpWidget(
            WidgetTestHelpers.createTestWrapper(
              child: const PlayerScreen(),
              contentService: mockContentService,
              audioService: mockAudioService,
              authService: mockAuthService,
            ),
          );

          expect(find.byIcon(entry.value), findsOneWidget);
        }
      });

      testWidgets('handles compact and expanded layout switching', (tester) async {
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const PlayerScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        // Initially should be in compact layout
        expect(find.byType(ContentDisplay), findsOneWidget);

        // Toggle to expanded layout
        await tester.tap(find.byIcon(Icons.article));
        await tester.pumpAndSettle();

        // Should still have ContentDisplay but in different configuration
        expect(find.byType(ContentDisplay), findsOneWidget);
      });

      testWidgets('supports accessibility features', (tester) async {
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const PlayerScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        await WidgetTestHelpers.verifyAccessibility(tester);

        // Verify important UI elements are accessible
        expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
        expect(find.byType(Slider), findsOneWidget);
        expect(find.byType(AudioControls), findsOneWidget);
      });

      testWidgets('handles different screen sizes correctly', (tester) async {
        await WidgetTestHelpers.testMultipleScreenSizes(
          tester,
          WidgetTestHelpers.createTestWrapper(
            child: const PlayerScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
          (tester, size) async {
            // Verify key elements are present regardless of screen size
            expect(find.text('NOW PLAYING'), findsOneWidget);
            expect(find.text('Test Bitcoin Analysis'), findsOneWidget);
            expect(find.byType(AudioControls), findsOneWidget);
          },
        );
      });

      testWidgets('applies correct theme styling', (tester) async {
        await WidgetTestHelpers.testBothThemes(
          tester,
          (theme) => WidgetTestHelpers.createTestWrapper(
            theme: theme,
            child: const PlayerScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
          (tester, theme) async {
            // Verify player screen renders correctly with both themes
            expect(find.text('NOW PLAYING'), findsOneWidget);
            expect(find.byType(Scaffold), findsOneWidget);
          },
        );
      });
    });

    group('Deep Link Support', () {
      testWidgets('loads and plays content when contentId is provided', (tester) async {
        const testContentId = 'test-episode-123';
        final testAudio = TestUtils.createSampleAudioFile(id: testContentId);
        
        // Set up mock to return audio file for the content ID
        when(mockContentService.getAudioFileById(testContentId))
            .thenAnswer((_) async => testAudio);
        when(mockAudioService.currentAudioFile).thenReturn(testAudio);
        
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const PlayerScreen(contentId: testContentId),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        // Wait for post-frame callback to execute
        await tester.pumpAndSettle();

        // Verify content loading and playback were attempted
        verify(mockContentService.getAudioFileById(testContentId)).called(1);
        verify(mockContentService.addToListenHistory(testAudio)).called(1);
        verify(mockAudioService.playAudio(testAudio)).called(1);
      });

      testWidgets('shows error when contentId is not found', (tester) async {
        const testContentId = 'non-existent-episode';
        
        // Set up mock to return null for non-existent content ID
        when(mockContentService.getAudioFileById(testContentId))
            .thenAnswer((_) async => null);
        
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const PlayerScreen(contentId: testContentId),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        // Wait for post-frame callback and error handling
        await tester.pumpAndSettle();

        // Verify error snackbar is shown
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.textContaining('Episode not found'), findsOneWidget);
      });

      testWidgets('handles content loading errors gracefully', (tester) async {
        const testContentId = 'error-episode';
        
        // Set up mock to throw error
        when(mockContentService.getAudioFileById(testContentId))
            .thenThrow(Exception('Network error'));
        
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const PlayerScreen(contentId: testContentId),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        // Wait for post-frame callback and error handling
        await tester.pumpAndSettle();

        // Verify error snackbar is shown
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.textContaining('Failed to load episode'), findsOneWidget);
      });
    });
    
    group('Error Handling', () {
      testWidgets('handles audio service errors gracefully', (tester) async {
        final testAudio = TestUtils.createSampleAudioFile();
        when(mockAudioService.hasError).thenReturn(true);
        when(mockAudioService.errorMessage).thenReturn('Failed to load audio');
        when(mockAudioService.currentAudioFile).thenReturn(testAudio);
        
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const PlayerScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );
        
        // Should still display the episode info but with error state
        expect(find.text(testAudio.displayTitle), findsOneWidget);
        expect(find.text('Failed to load audio'), findsOneWidget);
      });
    });
    
    group('Loading States', () {
      testWidgets('displays loading state correctly', (tester) async {
        final testAudio = TestUtils.createSampleAudioFile();
        when(mockAudioService.isLoading).thenReturn(true);
        when(mockAudioService.currentAudioFile).thenReturn(testAudio);
        when(mockAudioService.playbackState).thenReturn(PlaybackState.loading);
        
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const PlayerScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );
        
        // Should show loading indicators
        expect(find.byType(CircularProgressIndicator), findsWidgets);
      });
    });
    
    group('Navigation', () {
      testWidgets('back button works correctly', (tester) async {
        final testAudio = TestUtils.createSampleAudioFile();
        when(mockAudioService.currentAudioFile).thenReturn(testAudio);
        
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapperWithNavigation(
            child: const PlayerScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );
        
        // Tap back button
        await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
        await tester.pumpAndSettle();
        
        // Navigation should be triggered (can't verify actual navigation in widget test)
        expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
      });
    });
  });
}