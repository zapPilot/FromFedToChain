import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';

import 'package:from_fed_to_chain_app/features/audio/services/audio_player_service.dart';
import 'package:from_fed_to_chain_app/features/audio/services/player_state_notifier.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';
import 'package:from_fed_to_chain_app/features/content/screens/home_screen.dart';
import 'package:from_fed_to_chain_app/features/content/services/content_service.dart';

import 'home_screen_test.mocks.dart';

@GenerateMocks([ContentService, AudioPlayerService])
void main() {
  late MockContentService mockContentService;
  late MockAudioPlayerService mockAudioPlayerService;

  setUp(() {
    mockContentService = MockContentService();
    mockAudioPlayerService = MockAudioPlayerService();

    // Default mock behavior
    when(mockContentService.isLoading).thenReturn(false);
    when(mockContentService.hasError).thenReturn(false);
    when(mockContentService.allEpisodes).thenReturn([]);
    when(mockContentService.selectedLanguage).thenReturn('zh-TW');
    when(mockAudioPlayerService.currentAudioFile).thenReturn(null);
    when(mockAudioPlayerService.playbackState)
        .thenReturn(AppPlaybackState.stopped);
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<ContentService>.value(
              value: mockContentService),
          ChangeNotifierProvider<AudioPlayerService>.value(
              value: mockAudioPlayerService),
        ],
        child: const HomeScreen(),
      ),
    );
  }

  AudioFile createEpisode({
    required String id,
    required String title,
    required String language,
    required String category,
    required String streamingUrl,
    required String path,
  }) {
    return AudioFile(
      id: id,
      title: title,
      language: language,
      category: category,
      streamingUrl: streamingUrl,
      path: path,
      lastModified: DateTime.now(),
    );
  }

  Future<void> pumpHomeScreen(
    WidgetTester tester, {
    bool settle = true,
  }) async {
    await tester.pumpWidget(createWidgetUnderTest());
    if (settle) {
      await tester.pumpAndSettle();
      return;
    }
    await tester.pump();
  }

  testWidgets('HomeScreen displays All Caught Up when queue is empty',
      (WidgetTester tester) async {
    when(mockContentService.getFocusQueue('zh-TW')).thenReturn([]);

    await pumpHomeScreen(tester);

    expect(find.text('All Caught Up!'), findsOneWidget);
    expect(find.text('No new episodes in zh-TW'), findsOneWidget);
  });

  testWidgets('HomeScreen displays episodes in Focus Queue',
      (WidgetTester tester) async {
    final episodes = [
      createEpisode(
        id: 'ep1',
        title: 'Focus Episode 1',
        language: 'zh-TW',
        category: 'daily-news',
        streamingUrl: 'url1',
        path: 'path1',
      ),
    ];

    when(mockContentService.getFocusQueue('zh-TW')).thenReturn(episodes);
    when(mockContentService.allEpisodes).thenReturn(episodes);

    await pumpHomeScreen(tester);

    expect(find.text('Focus Episode 1'), findsOneWidget);
    expect(find.text('Queue'), findsOneWidget);
  });

  testWidgets('HomeScreen shows loading state', (WidgetTester tester) async {
    when(mockContentService.isLoading).thenReturn(true);
    when(mockContentService.allEpisodes).thenReturn([]);

    await pumpHomeScreen(tester, settle: false);

    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });
}
