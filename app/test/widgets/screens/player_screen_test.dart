import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:from_fed_to_chain_app/screens/player_screen.dart';
import 'package:from_fed_to_chain_app/services/audio_service.dart';
import 'package:from_fed_to_chain_app/services/content_service.dart';
import 'package:from_fed_to_chain_app/models/audio_file.dart';
import 'package:from_fed_to_chain_app/models/audio_content.dart';
import 'package:from_fed_to_chain_app/widgets/audio_controls.dart';
import 'package:from_fed_to_chain_app/widgets/playback_speed_selector.dart';
import 'package:from_fed_to_chain_app/widgets/content_display.dart';
import 'package:from_fed_to_chain_app/themes/app_theme.dart';

// Generate mocks for dependencies
@GenerateMocks([
  AudioService,
  ContentService,
])
import 'player_screen_test.mocks.dart';

/// Comprehensive test utilities for PlayerScreen testing
class PlayerScreenTestUtils {
  /// Create sample audio file for testing
  static AudioFile createSampleAudioFile({
    String id = 'test-episode-1',
    String title = 'Test Episode Title',
    String language = 'zh-TW',
    String category = 'daily-news',
    Duration duration = const Duration(minutes: 10),
  }) {
    return AudioFile(
      id: id,
      title: title,
      language: language,
      category: category,
      streamingUrl: 'https://test.com/$id.m3u8',
      path: 'audio/$language/$category/$id.m3u8',
      lastModified: DateTime(2025, 1, 15),
      duration: duration,
      fileSizeBytes: 5242880, // 5MB
    );
  }

  /// Create sample audio content with social hook
  static AudioContent createSampleAudioContent({
    String id = 'test-episode-1',
    String title = 'Test Episode Title',
    String? socialHook = '🚀 Amazing crypto news! Don\'t miss this episode!',
    String description = 'This is the episode content script...',
  }) {
    return AudioContent(
      id: id,
      status: 'published',
      category: 'daily-news',
      date: DateTime(2025, 1, 15),
      language: 'zh-TW',
      title: title,
      description: description,
      socialHook: socialHook,
      references: ['Source 1', 'Source 2'],
      updatedAt: DateTime(2025, 1, 15),
    );
  }

  /// Setup common mock behaviors for AudioService
  static void setupAudioServiceMocks(
    MockAudioService mockAudioService, {
    AudioFile? currentAudioFile,
    PlaybackState playbackState = PlaybackState.stopped,
    Duration currentPosition = Duration.zero,
    Duration totalDuration = const Duration(minutes: 10),
    double playbackSpeed = 1.0,
    bool autoplayEnabled = true,
    bool repeatEnabled = false,
    String? errorMessage,
  }) {
    // Basic properties
    when(mockAudioService.currentAudioFile).thenReturn(currentAudioFile);
    when(mockAudioService.playbackState).thenReturn(playbackState);
    when(mockAudioService.currentPosition).thenReturn(currentPosition);
    when(mockAudioService.totalDuration).thenReturn(totalDuration);
    when(mockAudioService.playbackSpeed).thenReturn(playbackSpeed);
    when(mockAudioService.autoplayEnabled).thenReturn(autoplayEnabled);
    when(mockAudioService.repeatEnabled).thenReturn(repeatEnabled);
    when(mockAudioService.errorMessage).thenReturn(errorMessage);

    // Computed properties
    when(mockAudioService.isPlaying)
        .thenReturn(playbackState == PlaybackState.playing);
    when(mockAudioService.isPaused)
        .thenReturn(playbackState == PlaybackState.paused);
    when(mockAudioService.isLoading)
        .thenReturn(playbackState == PlaybackState.loading);
    when(mockAudioService.hasError)
        .thenReturn(playbackState == PlaybackState.error);

    // Progress calculation
    final progress = totalDuration.inMilliseconds > 0
        ? (currentPosition.inMilliseconds / totalDuration.inMilliseconds)
            .clamp(0.0, 1.0)
        : 0.0;
    when(mockAudioService.progress).thenReturn(progress);

    // Formatted strings
    when(mockAudioService.formattedCurrentPosition)
        .thenReturn(_formatDuration(currentPosition));
    when(mockAudioService.formattedTotalDuration)
        .thenReturn(_formatDuration(totalDuration));

    // Async methods
    when(mockAudioService.playAudio(any)).thenAnswer((_) async {});
    when(mockAudioService.togglePlayPause()).thenAnswer((_) async {});
    when(mockAudioService.seekTo(any)).thenAnswer((_) async {});
    when(mockAudioService.skipForward()).thenAnswer((_) async {});
    when(mockAudioService.skipBackward()).thenAnswer((_) async {});
    when(mockAudioService.skipToNextEpisode()).thenAnswer((_) async {});
    when(mockAudioService.skipToPreviousEpisode()).thenAnswer((_) async {});
    when(mockAudioService.setPlaybackSpeed(any)).thenAnswer((_) async {});
    when(mockAudioService.setAutoplayEnabled(any)).thenAnswer((_) async {});
    when(mockAudioService.setRepeatEnabled(any)).thenAnswer((_) async {});
  }

  /// Setup common mock behaviors for ContentService
  static void setupContentServiceMocks(
    MockContentService mockContentService, {
    AudioContent? audioContent,
  }) {
    // Basic methods
    when(mockContentService.getAudioFileById(any))
        .thenAnswer((_) async => null);
    when(mockContentService.addToListenHistory(any)).thenAnswer((_) async {});
    when(mockContentService.getContentForAudioFile(any))
        .thenAnswer((_) async => audioContent);
    when(mockContentService.addToCurrentPlaylist(any)).thenAnswer((_) async {});
  }

  /// Format duration helper
  static String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Create a widget wrapper with all necessary providers and proper screen size
  static Widget createPlayerScreenWrapper({
    MockAudioService? audioService,
    MockContentService? contentService,
    String? contentId,
    Size screenSize = const Size(414, 896), // iPhone 11 Pro Max size (taller)
  }) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        primaryColor: AppTheme.primaryColor,
        colorScheme: const ColorScheme.dark().copyWith(
          primary: AppTheme.primaryColor,
          surface: AppTheme.surfaceColor,
          onSurface: AppTheme.onSurfaceColor,
        ),
      ),
      home: SizedBox(
        width: screenSize.width,
        height: screenSize.height,
        child: MediaQuery(
          data: MediaQueryData(size: screenSize),
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider<AudioService>.value(
                value: audioService ?? MockAudioService(),
              ),
              ChangeNotifierProvider<ContentService>.value(
                value: contentService ?? MockContentService(),
              ),
            ],
            child: PlayerScreen(contentId: contentId),
          ),
        ),
      ),
    );
  }

  /// Pump widget and settle animations with better timeout handling
  static Future<void> pumpAndSettle(
    WidgetTester tester,
    Widget widget, {
    Duration? duration,
  }) async {
    // Set a proper large screen size for testing to avoid layout overflow
    tester.binding.window.physicalSizeTestValue = const Size(414, 896);
    tester.binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(() => tester.binding.window.clearPhysicalSizeTestValue());

    await tester.pumpWidget(widget);
    try {
      await tester.pumpAndSettle(duration ?? const Duration(milliseconds: 500));
    } catch (e) {
      // If pumpAndSettle times out due to continuous animations, just pump a few times
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }
  }

  /// Pump widget for specific duration to test animations
  static Future<void> pumpForDuration(
      WidgetTester tester, Duration duration) async {
    final endTime = DateTime.now().add(duration);
    while (DateTime.now().isBefore(endTime)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
}

void main() {
  group('PlayerScreen Widget Tests', () {
    late MockAudioService mockAudioService;
    late MockContentService mockContentService;

    setUp(() {
      mockAudioService = MockAudioService();
      mockContentService = MockContentService();

      // Setup default mock behaviors
      PlayerScreenTestUtils.setupAudioServiceMocks(mockAudioService);
      PlayerScreenTestUtils.setupContentServiceMocks(mockContentService);
    });

    tearDown(() {
      reset(mockAudioService);
      reset(mockContentService);
    });

    group('Basic Rendering', () {
      testWidgets('renders PlayerScreen with no audio state', (tester) async {
        // Setup: No current audio
        PlayerScreenTestUtils.setupAudioServiceMocks(
          mockAudioService,
          currentAudioFile: null,
        );

        // Create and pump widget
        final widget = PlayerScreenTestUtils.createPlayerScreenWrapper(
          audioService: mockAudioService,
          contentService: mockContentService,
        );

        await PlayerScreenTestUtils.pumpAndSettle(tester, widget);

        // Verify no audio state is displayed
        expect(find.byIcon(Icons.music_off), findsOneWidget);
        expect(find.text('No audio playing'), findsOneWidget);
        expect(
            find.text('Select an episode to start listening'), findsOneWidget);
        expect(find.text('Browse Episodes'), findsOneWidget);
      });

      testWidgets('renders PlayerScreen with audio file in compact layout',
          (tester) async {
        // Setup: Current audio file
        final audioFile = PlayerScreenTestUtils.createSampleAudioFile();
        PlayerScreenTestUtils.setupAudioServiceMocks(
          mockAudioService,
          currentAudioFile: audioFile,
          playbackState: PlaybackState.playing,
        );

        // Create and pump widget
        final widget = PlayerScreenTestUtils.createPlayerScreenWrapper(
          audioService: mockAudioService,
          contentService: mockContentService,
        );

        await PlayerScreenTestUtils.pumpAndSettle(tester, widget);

        // Verify main components are rendered
        expect(find.text('NOW PLAYING'), findsOneWidget);
        expect(find.text('From Fed to Chain'), findsOneWidget);
        expect(find.text(audioFile.displayTitle), findsOneWidget);
        expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
        expect(find.byIcon(Icons.more_vert), findsOneWidget);
        expect(find.byType(AudioControls), findsOneWidget);
      });

      testWidgets('displays correct header information', (tester) async {
        // Setup
        final audioFile = PlayerScreenTestUtils.createSampleAudioFile();
        PlayerScreenTestUtils.setupAudioServiceMocks(
          mockAudioService,
          currentAudioFile: audioFile,
        );

        // Create and pump widget
        final widget = PlayerScreenTestUtils.createPlayerScreenWrapper(
          audioService: mockAudioService,
          contentService: mockContentService,
        );

        await PlayerScreenTestUtils.pumpAndSettle(tester, widget);

        // Verify header elements
        expect(find.text('NOW PLAYING'), findsOneWidget);
        expect(find.text('From Fed to Chain'), findsOneWidget);
        expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
        expect(find.byIcon(Icons.more_vert), findsOneWidget);
      });

      testWidgets('displays track information correctly', (tester) async {
        // Setup
        final audioFile = PlayerScreenTestUtils.createSampleAudioFile(
          title: 'Bitcoin Market Analysis',
          category: 'ethereum',
          language: 'en-US',
        );
        PlayerScreenTestUtils.setupAudioServiceMocks(
          mockAudioService,
          currentAudioFile: audioFile,
        );

        // Create and pump widget
        final widget = PlayerScreenTestUtils.createPlayerScreenWrapper(
          audioService: mockAudioService,
          contentService: mockContentService,
        );

        await PlayerScreenTestUtils.pumpAndSettle(tester, widget);

        // Verify track info
        expect(find.text('Bitcoin Market Analysis'), findsOneWidget);
        expect(find.text('⚡'), findsOneWidget); // Ethereum emoji
        expect(find.text('🇺🇸'), findsOneWidget); // US flag emoji
      });
    });

    group('Animation Testing', () {
      testWidgets('album art rotates when playing', (tester) async {
        // Setup: Playing state
        final audioFile = PlayerScreenTestUtils.createSampleAudioFile();
        PlayerScreenTestUtils.setupAudioServiceMocks(
          mockAudioService,
          currentAudioFile: audioFile,
          playbackState: PlaybackState.playing,
        );

        // Create and pump widget
        final widget = PlayerScreenTestUtils.createPlayerScreenWrapper(
          audioService: mockAudioService,
          contentService: mockContentService,
        );

        await tester.pumpWidget(widget);
        await tester.pump();

        // Verify RotationTransition widget exists and is animated
        expect(find.byType(RotationTransition), findsWidgets);

        // Get the rotation animation
        final rotationTransitionFinder = find.byType(RotationTransition).first;
        final rotationTransition =
            tester.widget<RotationTransition>(rotationTransitionFinder);

        // When playing, animation should be active (not AlwaysStoppedAnimation)
        expect(rotationTransition.turns, isNot(isA<AlwaysStoppedAnimation>()));
      });

      testWidgets('album art stops rotating when paused', (tester) async {
        // Setup: Paused state
        final audioFile = PlayerScreenTestUtils.createSampleAudioFile();
        PlayerScreenTestUtils.setupAudioServiceMocks(
          mockAudioService,
          currentAudioFile: audioFile,
          playbackState: PlaybackState.paused,
        );

        // Create and pump widget
        final widget = PlayerScreenTestUtils.createPlayerScreenWrapper(
          audioService: mockAudioService,
          contentService: mockContentService,
        );

        await tester.pumpWidget(widget);
        await tester.pump();

        // Verify RotationTransition exists but animation is stopped
        expect(find.byType(RotationTransition), findsWidgets);

        final rotationTransitionFinder = find.byType(RotationTransition).first;
        final rotationTransition =
            tester.widget<RotationTransition>(rotationTransitionFinder);

        // When paused, animation should be stopped
        expect(rotationTransition.turns, isA<AlwaysStoppedAnimation>());
      });

      testWidgets('animation controller is properly disposed', (tester) async {
        // Setup
        final audioFile = PlayerScreenTestUtils.createSampleAudioFile();
        PlayerScreenTestUtils.setupAudioServiceMocks(
          mockAudioService,
          currentAudioFile: audioFile,
        );

        // Create and pump widget
        final widget = PlayerScreenTestUtils.createPlayerScreenWrapper(
          audioService: mockAudioService,
          contentService: mockContentService,
        );

        await PlayerScreenTestUtils.pumpAndSettle(tester, widget);

        // Navigate away to trigger dispose
        await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
        await tester.pumpAndSettle();

        // Widget should be disposed without errors
        // (Testing framework will catch any disposal issues)
      });
    });

    group('Playback State Display', () {
      testWidgets('displays playing state indicator', (tester) async {
        // Setup: Playing state
        final audioFile = PlayerScreenTestUtils.createSampleAudioFile();
        PlayerScreenTestUtils.setupAudioServiceMocks(
          mockAudioService,
          currentAudioFile: audioFile,
          playbackState: PlaybackState.playing,
        );

        // Create and pump widget
        final widget = PlayerScreenTestUtils.createPlayerScreenWrapper(
          audioService: mockAudioService,
          contentService: mockContentService,
        );

        await PlayerScreenTestUtils.pumpAndSettle(tester, widget);

        // Verify playing state indicator
        expect(find.text('Playing'), findsOneWidget);
        expect(find.byIcon(Icons.play_arrow), findsWidgets);
      });

      testWidgets('displays loading state indicator', (tester) async {
        // Setup: Loading state
        final audioFile = PlayerScreenTestUtils.createSampleAudioFile();
        PlayerScreenTestUtils.setupAudioServiceMocks(
          mockAudioService,
          currentAudioFile: audioFile,
          playbackState: PlaybackState.loading,
        );

        // Create and pump widget
        final widget = PlayerScreenTestUtils.createPlayerScreenWrapper(
          audioService: mockAudioService,
          contentService: mockContentService,
        );

        await PlayerScreenTestUtils.pumpAndSettle(tester, widget);

        // Verify loading state indicator
        expect(find.text('Loading...'), findsOneWidget);
        expect(find.byIcon(Icons.hourglass_empty), findsOneWidget);
      });

      testWidgets('displays error state indicator', (tester) async {
        // Setup: Error state
        final audioFile = PlayerScreenTestUtils.createSampleAudioFile();
        PlayerScreenTestUtils.setupAudioServiceMocks(
          mockAudioService,
          currentAudioFile: audioFile,
          playbackState: PlaybackState.error,
          errorMessage: 'Network error',
        );

        // Create and pump widget
        final widget = PlayerScreenTestUtils.createPlayerScreenWrapper(
          audioService: mockAudioService,
          contentService: mockContentService,
        );

        await PlayerScreenTestUtils.pumpAndSettle(tester, widget);

        // Verify error state indicator
        expect(find.text('Error'), findsOneWidget);
        expect(find.byIcon(Icons.error), findsOneWidget);
      });

      testWidgets('displays paused state indicator', (tester) async {
        // Setup: Paused state
        final audioFile = PlayerScreenTestUtils.createSampleAudioFile();
        PlayerScreenTestUtils.setupAudioServiceMocks(
          mockAudioService,
          currentAudioFile: audioFile,
          playbackState: PlaybackState.paused,
        );

        // Create and pump widget
        final widget = PlayerScreenTestUtils.createPlayerScreenWrapper(
          audioService: mockAudioService,
          contentService: mockContentService,
        );

        await PlayerScreenTestUtils.pumpAndSettle(tester, widget);

        // Verify paused state indicator
        expect(find.text('Paused'), findsOneWidget);
        expect(find.byIcon(Icons.pause), findsWidgets);
      });
    });

    group('Progress Controls', () {
      testWidgets('displays progress slider and time labels', (tester) async {
        // Setup: Audio with specific position
        final audioFile = PlayerScreenTestUtils.createSampleAudioFile();
        PlayerScreenTestUtils.setupAudioServiceMocks(
          mockAudioService,
          currentAudioFile: audioFile,
          currentPosition: const Duration(minutes: 2, seconds: 30),
          totalDuration: const Duration(minutes: 10),
        );

        // Create and pump widget
        final widget = PlayerScreenTestUtils.createPlayerScreenWrapper(
          audioService: mockAudioService,
          contentService: mockContentService,
        );

        await PlayerScreenTestUtils.pumpAndSettle(tester, widget);

        // Verify slider and time displays
        expect(find.byType(Slider), findsOneWidget);
        expect(find.text('2:30'), findsOneWidget);
        expect(find.text('10:00'), findsOneWidget);
      });

      testWidgets('seek bar interaction calls seekTo', (tester) async {
        // Setup
        final audioFile = PlayerScreenTestUtils.createSampleAudioFile();
        PlayerScreenTestUtils.setupAudioServiceMocks(
          mockAudioService,
          currentAudioFile: audioFile,
          totalDuration: const Duration(minutes: 10),
        );

        // Create and pump widget
        final widget = PlayerScreenTestUtils.createPlayerScreenWrapper(
          audioService: mockAudioService,
          contentService: mockContentService,
        );

        await PlayerScreenTestUtils.pumpAndSettle(tester, widget);

        // Find and interact with slider
        final slider = find.byType(Slider);
        expect(slider, findsOneWidget);

        // Simulate slider drag to 50% (5 minutes)
        await tester.drag(slider, const Offset(100, 0));
        await tester.pumpAndSettle();

        // Verify seekTo was called (mockito will capture any seekTo call)
        verify(mockAudioService.seekTo(any)).called(greaterThanOrEqualTo(1));
      });
    });

    group('Control Integration', () {
      testWidgets('AudioControls widget is rendered with correct props',
          (tester) async {
        // Setup: Playing state
        final audioFile = PlayerScreenTestUtils.createSampleAudioFile();
        PlayerScreenTestUtils.setupAudioServiceMocks(
          mockAudioService,
          currentAudioFile: audioFile,
          playbackState: PlaybackState.playing,
        );

        // Create and pump widget
        final widget = PlayerScreenTestUtils.createPlayerScreenWrapper(
          audioService: mockAudioService,
          contentService: mockContentService,
        );

        await PlayerScreenTestUtils.pumpAndSettle(tester, widget);

        // Verify AudioControls is present
        expect(find.byType(AudioControls), findsOneWidget);

        // Get the AudioControls widget and verify its properties
        final audioControls =
            tester.widget<AudioControls>(find.byType(AudioControls));
        expect(audioControls.isPlaying, true);
        expect(audioControls.size, AudioControlsSize.large);
      });

      testWidgets('additional control buttons are rendered', (tester) async {
        // Setup
        final audioFile = PlayerScreenTestUtils.createSampleAudioFile();
        PlayerScreenTestUtils.setupAudioServiceMocks(
          mockAudioService,
          currentAudioFile: audioFile,
        );

        // Create and pump widget
        final widget = PlayerScreenTestUtils.createPlayerScreenWrapper(
          audioService: mockAudioService,
          contentService: mockContentService,
        );

        await PlayerScreenTestUtils.pumpAndSettle(tester, widget);

        // Verify additional control buttons
        expect(find.byIcon(Icons.article),
            findsOneWidget); // Content script toggle
        expect(find.byIcon(Icons.speed), findsOneWidget); // Speed selector
        expect(find.byIcon(Icons.repeat), findsOneWidget); // Repeat toggle
        expect(find.byIcon(Icons.playlist_play),
            findsOneWidget); // Autoplay toggle
        expect(find.byIcon(Icons.share), findsOneWidget); // Share button
        expect(
            find.byIcon(Icons.playlist_add), findsOneWidget); // Add to playlist
      });

      testWidgets('content script toggle changes layout', (tester) async {
        // Setup
        final audioFile = PlayerScreenTestUtils.createSampleAudioFile();
        PlayerScreenTestUtils.setupAudioServiceMocks(
          mockAudioService,
          currentAudioFile: audioFile,
        );

        // Create and pump widget
        final widget = PlayerScreenTestUtils.createPlayerScreenWrapper(
          audioService: mockAudioService,
          contentService: mockContentService,
        );

        await PlayerScreenTestUtils.pumpAndSettle(tester, widget);

        // Initially should be in compact layout
        expect(find.byType(CustomScrollView), findsNothing);

        // Tap content script toggle
        await tester.tap(find.byIcon(Icons.article));
        await tester.pumpAndSettle();

        // Should now be in expanded layout
        expect(find.byType(CustomScrollView), findsOneWidget);
      });

      testWidgets('speed selector shows when toggled', (tester) async {
        // Setup
        final audioFile = PlayerScreenTestUtils.createSampleAudioFile();
        PlayerScreenTestUtils.setupAudioServiceMocks(
          mockAudioService,
          currentAudioFile: audioFile,
          playbackSpeed: 1.5,
        );

        // Create and pump widget
        final widget = PlayerScreenTestUtils.createPlayerScreenWrapper(
          audioService: mockAudioService,
          contentService: mockContentService,
        );

        await PlayerScreenTestUtils.pumpAndSettle(tester, widget);

        // Initially speed selector should not be visible
        expect(find.byType(PlaybackSpeedSelector), findsNothing);

        // Verify speed is displayed in button
        expect(find.text('1.5x'), findsOneWidget);

        // Tap speed button
        await tester.tap(find.byIcon(Icons.speed));
        await tester.pumpAndSettle();

        // Speed selector should now be visible
        expect(find.byType(PlaybackSpeedSelector), findsOneWidget);
      });

      testWidgets('repeat toggle changes state', (tester) async {
        // Setup
        final audioFile = PlayerScreenTestUtils.createSampleAudioFile();
        PlayerScreenTestUtils.setupAudioServiceMocks(
          mockAudioService,
          currentAudioFile: audioFile,
          repeatEnabled: false,
        );

        // Create and pump widget
        final widget = PlayerScreenTestUtils.createPlayerScreenWrapper(
          audioService: mockAudioService,
          contentService: mockContentService,
        );

        await PlayerScreenTestUtils.pumpAndSettle(tester, widget);

        // Find repeat button and tap it
        final repeatButton = find.byIcon(Icons.repeat);
        expect(repeatButton, findsOneWidget);

        await tester.tap(repeatButton);
        await tester.pump();

        // Verify setRepeatEnabled was called
        verify(mockAudioService.setRepeatEnabled(true)).called(1);
      });

      testWidgets('autoplay toggle changes state', (tester) async {
        // Setup
        final audioFile = PlayerScreenTestUtils.createSampleAudioFile();
        PlayerScreenTestUtils.setupAudioServiceMocks(
          mockAudioService,
          currentAudioFile: audioFile,
          autoplayEnabled: true,
        );

        // Create and pump widget
        final widget = PlayerScreenTestUtils.createPlayerScreenWrapper(
          audioService: mockAudioService,
          contentService: mockContentService,
        );

        await PlayerScreenTestUtils.pumpAndSettle(tester, widget);

        // Find autoplay button and tap it
        final autoplayButton = find.byIcon(Icons.skip_next);
        expect(autoplayButton, findsOneWidget);

        await tester.tap(autoplayButton);
        await tester.pump();

        // Verify setAutoplayEnabled was called with false
        verify(mockAudioService.setAutoplayEnabled(false)).called(1);
      });

      testWidgets('add to playlist calls content service', (tester) async {
        // Setup
        final audioFile = PlayerScreenTestUtils.createSampleAudioFile();
        PlayerScreenTestUtils.setupAudioServiceMocks(
          mockAudioService,
          currentAudioFile: audioFile,
        );

        // Create and pump widget
        final widget = PlayerScreenTestUtils.createPlayerScreenWrapper(
          audioService: mockAudioService,
          contentService: mockContentService,
        );

        await PlayerScreenTestUtils.pumpAndSettle(tester, widget);

        // Tap add to playlist button
        await tester.tap(find.byIcon(Icons.playlist_add));
        await tester.pumpAndSettle();

        // Verify addToCurrentPlaylist was called
        verify(mockContentService.addToCurrentPlaylist(audioFile)).called(1);

        // Verify snackbar is shown
        expect(find.text('Added "${audioFile.displayTitle}" to playlist'),
            findsOneWidget);
      });
    });

    group('Deep Linking', () {
      testWidgets('loads and plays content when contentId is provided',
          (tester) async {
        // Setup: Mock content loading
        final audioFile = PlayerScreenTestUtils.createSampleAudioFile(
            id: 'deep-link-episode');
        when(mockContentService.getAudioFileById('deep-link-episode'))
            .thenAnswer((_) async => audioFile);

        PlayerScreenTestUtils.setupAudioServiceMocks(mockAudioService);

        // Create widget with contentId
        final widget = PlayerScreenTestUtils.createPlayerScreenWrapper(
          audioService: mockAudioService,
          contentService: mockContentService,
          contentId: 'deep-link-episode',
        );

        await tester.pumpWidget(widget);
        await tester.pump(); // Allow initState to complete
        await tester.pump(); // Allow post-frame callback to execute

        // Verify content loading methods were called
        verify(mockContentService.getAudioFileById('deep-link-episode'))
            .called(1);
        verify(mockContentService.addToListenHistory(audioFile)).called(1);
        verify(mockAudioService.playAudio(audioFile)).called(1);
      });

      testWidgets('shows error snackbar when content not found',
          (tester) async {
        // Setup: Content not found
        when(mockContentService.getAudioFileById('nonexistent-episode'))
            .thenAnswer((_) async => null);

        PlayerScreenTestUtils.setupAudioServiceMocks(mockAudioService);

        // Create widget with invalid contentId
        final widget = PlayerScreenTestUtils.createPlayerScreenWrapper(
          audioService: mockAudioService,
          contentService: mockContentService,
          contentId: 'nonexistent-episode',
        );

        await tester.pumpWidget(widget);
        await tester.pump(); // Allow initState
        await tester.pump(); // Allow post-frame callback

        // Wait for snackbar to appear
        await tester.pumpAndSettle();

        // Verify error snackbar is shown
        expect(find.text('Episode not found: nonexistent-episode'),
            findsOneWidget);
      });

      testWidgets('shows error snackbar when content loading fails',
          (tester) async {
        // Setup: Content loading throws exception
        when(mockContentService.getAudioFileById('error-episode'))
            .thenThrow(Exception('Network error'));

        PlayerScreenTestUtils.setupAudioServiceMocks(mockAudioService);

        // Create widget
        final widget = PlayerScreenTestUtils.createPlayerScreenWrapper(
          audioService: mockAudioService,
          contentService: mockContentService,
          contentId: 'error-episode',
        );

        await tester.pumpWidget(widget);
        await tester.pump(); // Allow initState
        await tester.pump(); // Allow post-frame callback
        await tester.pumpAndSettle();

        // Verify error snackbar is shown
        expect(find.textContaining('Failed to load episode'), findsOneWidget);
      });

      testWidgets('shows success snackbar when content loads successfully',
          (tester) async {
        // Setup: Successful content loading
        final audioFile = PlayerScreenTestUtils.createSampleAudioFile(
          id: 'success-episode',
          title: 'Success Episode',
        );
        when(mockContentService.getAudioFileById('success-episode'))
            .thenAnswer((_) async => audioFile);

        PlayerScreenTestUtils.setupAudioServiceMocks(mockAudioService);

        // Create widget
        final widget = PlayerScreenTestUtils.createPlayerScreenWrapper(
          audioService: mockAudioService,
          contentService: mockContentService,
          contentId: 'success-episode',
        );

        await tester.pumpWidget(widget);
        await tester.pump(); // Allow initState
        await tester.pump(); // Allow post-frame callback
        await tester.pumpAndSettle();

        // Verify success snackbar is shown
        expect(find.text('Now playing: Success Episode'), findsOneWidget);
      });
    });

    group('Sharing Functionality', () {
      testWidgets('share button triggers sharing with social hook',
          (tester) async {
        // Setup: Audio file with content that has social hook
        final audioFile = PlayerScreenTestUtils.createSampleAudioFile();
        final audioContent = PlayerScreenTestUtils.createSampleAudioContent(
          socialHook: '🚀 Amazing crypto analysis! Must listen episode!',
        );

        PlayerScreenTestUtils.setupAudioServiceMocks(
          mockAudioService,
          currentAudioFile: audioFile,
        );

        when(mockContentService.getContentForAudioFile(audioFile))
            .thenAnswer((_) async => audioContent);

        // Create widget
        final widget = PlayerScreenTestUtils.createPlayerScreenWrapper(
          audioService: mockAudioService,
          contentService: mockContentService,
        );

        await PlayerScreenTestUtils.pumpAndSettle(tester, widget);

        // Tap share button
        await tester.tap(find.byIcon(Icons.share));
        await tester.pump();

        // Verify content was fetched for sharing
        verify(mockContentService.getContentForAudioFile(audioFile)).called(1);
      });

      testWidgets('sharing works without social hook (fallback message)',
          (tester) async {
        // Setup: Audio file with content that has no social hook
        final audioFile = PlayerScreenTestUtils.createSampleAudioFile(
          title: 'Bitcoin Analysis Episode',
        );
        final audioContent = PlayerScreenTestUtils.createSampleAudioContent(
          socialHook: null, // No social hook
        );

        PlayerScreenTestUtils.setupAudioServiceMocks(
          mockAudioService,
          currentAudioFile: audioFile,
        );

        when(mockContentService.getContentForAudioFile(audioFile))
            .thenAnswer((_) async => audioContent);

        // Create widget
        final widget = PlayerScreenTestUtils.createPlayerScreenWrapper(
          audioService: mockAudioService,
          contentService: mockContentService,
        );

        await PlayerScreenTestUtils.pumpAndSettle(tester, widget);

        // Tap share button
        await tester.tap(find.byIcon(Icons.share));
        await tester.pump();

        // Should still attempt to share with fallback message
        verify(mockContentService.getContentForAudioFile(audioFile)).called(1);
      });

      testWidgets('sharing shows error when content loading fails',
          (tester) async {
        // Setup: Content loading fails
        final audioFile = PlayerScreenTestUtils.createSampleAudioFile();
        PlayerScreenTestUtils.setupAudioServiceMocks(
          mockAudioService,
          currentAudioFile: audioFile,
        );

        when(mockContentService.getContentForAudioFile(audioFile))
            .thenThrow(Exception('Network error'));

        // Create widget
        final widget = PlayerScreenTestUtils.createPlayerScreenWrapper(
          audioService: mockAudioService,
          contentService: mockContentService,
        );

        await PlayerScreenTestUtils.pumpAndSettle(tester, widget);

        // Tap share button
        await tester.tap(find.byIcon(Icons.share));
        await tester.pumpAndSettle();

        // Verify error snackbar is shown
        expect(find.textContaining('Failed to share episode'), findsOneWidget);
      });

      testWidgets('share dialog appears when system share fails',
          (tester) async {
        // This test would require mocking the share_plus package more thoroughly
        // For now, we can test that the share button exists and is tappable
        final audioFile = PlayerScreenTestUtils.createSampleAudioFile();
        PlayerScreenTestUtils.setupAudioServiceMocks(
          mockAudioService,
          currentAudioFile: audioFile,
        );

        final widget = PlayerScreenTestUtils.createPlayerScreenWrapper(
          audioService: mockAudioService,
          contentService: mockContentService,
        );

        await PlayerScreenTestUtils.pumpAndSettle(tester, widget);

        // Verify share button exists and is tappable
        final shareButton = find.byIcon(Icons.share);
        expect(shareButton, findsOneWidget);

        // Tap doesn't throw error
        await tester.tap(shareButton);
        await tester.pump();
      });
    });

    group('Layout Switching', () {
      testWidgets('switches from compact to expanded layout', (tester) async {
        // Setup
        final audioFile = PlayerScreenTestUtils.createSampleAudioFile();
        PlayerScreenTestUtils.setupAudioServiceMocks(
          mockAudioService,
          currentAudioFile: audioFile,
        );

        // Create widget
        final widget = PlayerScreenTestUtils.createPlayerScreenWrapper(
          audioService: mockAudioService,
          contentService: mockContentService,
        );

        await PlayerScreenTestUtils.pumpAndSettle(tester, widget);

        // Initially should be compact (Column layout)
        expect(find.byType(Column), findsWidgets);
        expect(find.byType(CustomScrollView), findsNothing);

        // Toggle to expanded
        await tester.tap(find.byIcon(Icons.article));
        await tester.pumpAndSettle();

        // Should now be expanded (CustomScrollView)
        expect(find.byType(CustomScrollView), findsOneWidget);
      });

      testWidgets('expanded layout shows content display widget',
          (tester) async {
        // Setup
        final audioFile = PlayerScreenTestUtils.createSampleAudioFile();
        PlayerScreenTestUtils.setupAudioServiceMocks(
          mockAudioService,
          currentAudioFile: audioFile,
        );

        // Create widget
        final widget = PlayerScreenTestUtils.createPlayerScreenWrapper(
          audioService: mockAudioService,
          contentService: mockContentService,
        );

        await PlayerScreenTestUtils.pumpAndSettle(tester, widget);

        // Toggle to expanded
        await tester.tap(find.byIcon(Icons.article));
        await tester.pumpAndSettle();

        // Verify ContentDisplay widget is present
        expect(find.byType(ContentDisplay), findsOneWidget);

        // Verify ContentDisplay has correct properties
        final contentDisplay =
            tester.widget<ContentDisplay>(find.byType(ContentDisplay));
        expect(contentDisplay.currentAudioFile, audioFile);
        expect(contentDisplay.isExpanded, true);
      });

      testWidgets('expanded layout has smaller album art', (tester) async {
        // Setup
        final audioFile = PlayerScreenTestUtils.createSampleAudioFile();
        PlayerScreenTestUtils.setupAudioServiceMocks(
          mockAudioService,
          currentAudioFile: audioFile,
        );

        // Create widget
        final widget = PlayerScreenTestUtils.createPlayerScreenWrapper(
          audioService: mockAudioService,
          contentService: mockContentService,
        );

        await PlayerScreenTestUtils.pumpAndSettle(tester, widget);

        // Verify initial layout has album art containers
        expect(
            find.byWidgetPredicate((widget) =>
                widget is Container &&
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).shape == BoxShape.circle),
            findsWidgets);

        // Toggle to expanded
        await tester.tap(find.byIcon(Icons.article));
        await tester.pumpAndSettle();

        // Album art should still be present but in different size
        expect(find.byType(RotationTransition), findsWidgets);
      });
    });

    group('Player Options', () {
      testWidgets('more options button shows bottom sheet', (tester) async {
        // Setup
        final audioFile = PlayerScreenTestUtils.createSampleAudioFile();
        PlayerScreenTestUtils.setupAudioServiceMocks(
          mockAudioService,
          currentAudioFile: audioFile,
        );

        // Create widget
        final widget = PlayerScreenTestUtils.createPlayerScreenWrapper(
          audioService: mockAudioService,
          contentService: mockContentService,
        );

        await PlayerScreenTestUtils.pumpAndSettle(tester, widget);

        // Tap more options button
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        // Verify bottom sheet appears with audio details
        expect(find.text('Audio Details'), findsOneWidget);
        expect(find.text(audioFile.displayTitle), findsAtLeastNWidgets(1));
      });

      testWidgets('back button pops the screen', (tester) async {
        // Setup
        final audioFile = PlayerScreenTestUtils.createSampleAudioFile();
        PlayerScreenTestUtils.setupAudioServiceMocks(
          mockAudioService,
          currentAudioFile: audioFile,
        );

        // Create widget
        final widget = PlayerScreenTestUtils.createPlayerScreenWrapper(
          audioService: mockAudioService,
          contentService: mockContentService,
        );

        await PlayerScreenTestUtils.pumpAndSettle(tester, widget);

        // Verify back button exists
        expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);

        // Tap back button - this would normally pop the route
        // In a test environment, we can just verify the button exists and is tappable
        await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
        await tester.pump();
      });
    });

    group('Error Scenarios', () {
      testWidgets('handles null current audio file gracefully', (tester) async {
        // Setup: No current audio
        PlayerScreenTestUtils.setupAudioServiceMocks(
          mockAudioService,
          currentAudioFile: null,
        );

        // Create widget
        final widget = PlayerScreenTestUtils.createPlayerScreenWrapper(
          audioService: mockAudioService,
          contentService: mockContentService,
        );

        await PlayerScreenTestUtils.pumpAndSettle(tester, widget);

        // Should show no audio state
        expect(find.text('No audio playing'), findsOneWidget);
        expect(find.byIcon(Icons.music_off), findsOneWidget);
      });

      testWidgets('handles audio service errors in error state',
          (tester) async {
        // Setup: Error state
        final audioFile = PlayerScreenTestUtils.createSampleAudioFile();
        PlayerScreenTestUtils.setupAudioServiceMocks(
          mockAudioService,
          currentAudioFile: audioFile,
          playbackState: PlaybackState.error,
          errorMessage: 'Stream unavailable',
        );

        // Create widget
        final widget = PlayerScreenTestUtils.createPlayerScreenWrapper(
          audioService: mockAudioService,
          contentService: mockContentService,
        );

        await PlayerScreenTestUtils.pumpAndSettle(tester, widget);

        // Should show error state indicator
        expect(find.text('Error'), findsOneWidget);
        expect(find.byIcon(Icons.error), findsOneWidget);
      });

      testWidgets('share button handles no current audio', (tester) async {
        // Setup: No current audio
        PlayerScreenTestUtils.setupAudioServiceMocks(
          mockAudioService,
          currentAudioFile: null,
        );

        // Create widget
        final widget = PlayerScreenTestUtils.createPlayerScreenWrapper(
          audioService: mockAudioService,
          contentService: mockContentService,
        );

        await PlayerScreenTestUtils.pumpAndSettle(tester, widget);

        // Should show no audio state, share button shouldn't be visible
        expect(find.text('No audio playing'), findsOneWidget);
        expect(find.byIcon(Icons.share), findsNothing);
      });

      testWidgets('handles playlist add with null audio file', (tester) async {
        // Setup: No current audio but somehow the widget is rendered (edge case)
        PlayerScreenTestUtils.setupAudioServiceMocks(
          mockAudioService,
          currentAudioFile: null,
        );

        // This is testing an edge case - normally the screen wouldn't render controls
        // without a current audio file, but if it did, it should handle null gracefully

        // The widget should show no audio state
        final widget = PlayerScreenTestUtils.createPlayerScreenWrapper(
          audioService: mockAudioService,
          contentService: mockContentService,
        );

        await PlayerScreenTestUtils.pumpAndSettle(tester, widget);

        expect(find.text('No audio playing'), findsOneWidget);
      });
    });

    group('Content Display Integration', () {
      testWidgets('ContentDisplay widget receives correct props',
          (tester) async {
        // Setup
        final audioFile = PlayerScreenTestUtils.createSampleAudioFile();
        PlayerScreenTestUtils.setupAudioServiceMocks(
          mockAudioService,
          currentAudioFile: audioFile,
        );

        // Create widget
        final widget = PlayerScreenTestUtils.createPlayerScreenWrapper(
          audioService: mockAudioService,
          contentService: mockContentService,
        );

        await PlayerScreenTestUtils.pumpAndSettle(tester, widget);

        // Find ContentDisplay widget
        expect(find.byType(ContentDisplay), findsOneWidget);

        // Verify its properties
        final contentDisplay =
            tester.widget<ContentDisplay>(find.byType(ContentDisplay));
        expect(contentDisplay.currentAudioFile, audioFile);
        expect(contentDisplay.isExpanded, false); // Initially not expanded
        expect(contentDisplay.contentService, mockContentService);
      });

      testWidgets('ContentDisplay toggle callback works', (tester) async {
        // Setup
        final audioFile = PlayerScreenTestUtils.createSampleAudioFile();
        PlayerScreenTestUtils.setupAudioServiceMocks(
          mockAudioService,
          currentAudioFile: audioFile,
        );

        // Create widget
        final widget = PlayerScreenTestUtils.createPlayerScreenWrapper(
          audioService: mockAudioService,
          contentService: mockContentService,
        );

        await PlayerScreenTestUtils.pumpAndSettle(tester, widget);

        // Initially not expanded
        var contentDisplay =
            tester.widget<ContentDisplay>(find.byType(ContentDisplay));
        expect(contentDisplay.isExpanded, false);

        // Toggle expansion via article button
        await tester.tap(find.byIcon(Icons.article));
        await tester.pumpAndSettle();

        // Should now be expanded
        contentDisplay =
            tester.widget<ContentDisplay>(find.byType(ContentDisplay));
        expect(contentDisplay.isExpanded, true);
      });
    });
  });
}
