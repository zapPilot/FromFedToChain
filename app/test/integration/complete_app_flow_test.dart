import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';

import 'package:from_fed_to_chain_app/services/content_service.dart';
import 'package:from_fed_to_chain_app/services/audio_service.dart';
import 'package:from_fed_to_chain_app/services/auth/auth_service.dart';
import 'package:from_fed_to_chain_app/services/background_audio_handler.dart';
import 'package:from_fed_to_chain_app/screens/main_navigation_screen.dart';
import 'package:from_fed_to_chain_app/screens/home_screen.dart';
import 'package:from_fed_to_chain_app/widgets/audio_list.dart';
import 'package:from_fed_to_chain_app/widgets/filter_bar.dart';

import '../test_utils.dart';

// Generate mocks
@GenerateMocks(
    [ContentService, AudioService, AuthService, BackgroundAudioHandler])
import 'complete_app_flow_test.mocks.dart';

void main() {
  group('Complete App Flow Integration Tests', () {
    late MockContentService mockContentService;
    late MockAudioService mockAudioService;
    late MockAuthService mockAuthService;

    setUp(() {
      mockContentService = MockContentService();
      mockAudioService = MockAudioService();
      mockAuthService = MockAuthService();

      // Setup default authenticated state
      when(mockAuthService.isAuthenticated).thenReturn(true);
      when(mockAuthService.currentUser).thenReturn(null);

      // Setup default content service
      final testEpisodes = TestUtils.createSampleAudioFileList(15);
      when(mockContentService.allEpisodes).thenReturn(testEpisodes);
      when(mockContentService.filteredEpisodes).thenReturn(testEpisodes);
      when(mockContentService.selectedLanguage).thenReturn('zh-TW');
      when(mockContentService.selectedCategory).thenReturn('all');
      when(mockContentService.searchQuery).thenReturn('');
      when(mockContentService.sortOrder).thenReturn('newest');
      when(mockContentService.isLoading).thenReturn(false);
      when(mockContentService.hasError).thenReturn(false);

      // Setup default audio service
      when(mockAudioService.currentAudioFile).thenReturn(null);
      when(mockAudioService.isPlaying).thenReturn(false);
      when(mockAudioService.isPaused).thenReturn(false);
      when(mockAudioService.isLoading).thenReturn(false);
      when(mockAudioService.currentPosition).thenReturn(Duration.zero);
      when(mockAudioService.totalDuration).thenReturn(Duration.zero);
      when(mockAudioService.playbackSpeed).thenReturn(1.0);
    });

    Widget createApp() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>.value(value: mockAuthService),
          ChangeNotifierProvider<ContentService>.value(
              value: mockContentService),
          ChangeNotifierProvider<AudioService>.value(value: mockAudioService),
        ],
        child: MaterialApp(
          home: const MainNavigationScreen(),
          theme: ThemeData.dark(),
        ),
      );
    }

    testWidgets('App starts and shows home screen', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      // App should start on Home screen
      expect(find.byType(MainNavigationScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsOneWidget);

      // Should show Recent tab by default
      expect(find.text('Recent'), findsOneWidget);
    });

    testWidgets('Can navigate between tabs', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      // Switch to All tab
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      expect(find.byType(AudioList), findsOneWidget);
      expect(find.byType(FilterBar), findsOneWidget);
    });

    testWidgets('Audio list displays episodes', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      // Switch to All tab to see episode list
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      // Should show episodes from filteredEpisodes
      expect(find.byType(AudioList), findsOneWidget);
    });

    testWidgets('Content service provides episode data', (tester) async {
      final testEpisodes = TestUtils.createSampleAudioFileList(5);
      when(mockContentService.filteredEpisodes).thenReturn(testEpisodes);

      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      // Verify content service is being used
      verify(mockContentService.filteredEpisodes).called(greaterThan(0));
    });

    testWidgets('Audio service provides playback state', (tester) async {
      when(mockAudioService.isPlaying).thenReturn(false);
      when(mockAudioService.currentAudioFile).thenReturn(null);

      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      // Verify audio service is being used
      verify(mockAudioService.isPlaying).called(greaterThan(0));
    });

    testWidgets('App handles different language selections', (tester) async {
      when(mockContentService.selectedLanguage).thenReturn('en-US');

      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      // Verify language setting is read
      verify(mockContentService.selectedLanguage).called(greaterThan(0));
    });

    testWidgets('App handles different category selections', (tester) async {
      when(mockContentService.selectedCategory).thenReturn('daily-news');

      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      // Verify category setting is read
      verify(mockContentService.selectedCategory).called(greaterThan(0));
    });

    testWidgets('App handles loading states', (tester) async {
      when(mockContentService.isLoading).thenReturn(true);

      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      // App should handle loading state
      expect(find.byType(MainNavigationScreen), findsOneWidget);
    });

    testWidgets('App handles error states', (tester) async {
      when(mockContentService.hasError).thenReturn(true);

      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      // App should still render with error state
      expect(find.byType(MainNavigationScreen), findsOneWidget);
    });

    testWidgets('Audio playback states are handled', (tester) async {
      final testEpisode = TestUtils.createSampleAudioFile();
      when(mockAudioService.currentAudioFile).thenReturn(testEpisode);
      when(mockAudioService.isPlaying).thenReturn(true);

      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      // App should handle playing state
      verify(mockAudioService.currentAudioFile).called(greaterThan(0));
      verify(mockAudioService.isPlaying).called(greaterThan(0));
    });
  });
}
