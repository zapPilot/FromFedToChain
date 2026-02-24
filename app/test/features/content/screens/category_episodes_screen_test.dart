import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:from_fed_to_chain_app/features/audio/services/audio_player_service.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';
import 'package:from_fed_to_chain_app/features/content/screens/category_episodes_screen.dart';
import 'package:from_fed_to_chain_app/features/content/services/content_service.dart';

import 'home_screen_test.mocks.dart';

void main() {
  late MockContentService mockContentService;
  late MockAudioPlayerService mockAudioPlayerService;

  setUp(() {
    mockContentService = MockContentService();
    mockAudioPlayerService = MockAudioPlayerService();
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
        child: const CategoryEpisodesScreen(
          category: 'daily-news',
          language: 'zh-TW',
        ),
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

  Future<void> pumpCategoryScreen(WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();
  }

  testWidgets('CategoryEpisodesScreen displays filtered episodes',
      (WidgetTester tester) async {
    final episodes = [
      createEpisode(
        id: 'ep1',
        title: 'Daily News 1',
        language: 'zh-TW',
        category: 'daily-news',
        streamingUrl: 'url1',
        path: 'path1',
      ),
    ];

    when(mockContentService.getEpisodesByLanguageAndCategory(
            'zh-TW', 'daily-news'))
        .thenReturn(episodes);
    when(mockContentService.isEpisodeUnfinished(any)).thenReturn(false);

    await pumpCategoryScreen(tester);

    expect(find.text('Daily News 1'), findsOneWidget);
    expect(find.textContaining('Daily News'), findsWidgets);
  });

  testWidgets('CategoryEpisodesScreen filter unfinished works',
      (WidgetTester tester) async {
    final episodes = [
      createEpisode(
        id: 'ep1',
        title: 'Finished Ep',
        language: 'zh-TW',
        category: 'daily-news',
        streamingUrl: 'url1',
        path: 'path1',
      ),
      createEpisode(
        id: 'ep2',
        title: 'Unfinished Ep',
        language: 'zh-TW',
        category: 'daily-news',
        streamingUrl: 'url2',
        path: 'path2',
      ),
    ];

    when(mockContentService.getEpisodesByLanguageAndCategory(
            'zh-TW', 'daily-news'))
        .thenReturn(episodes);
    when(mockContentService.isEpisodeUnfinished('ep1')).thenReturn(false);
    when(mockContentService.isEpisodeUnfinished('ep2')).thenReturn(true);

    await pumpCategoryScreen(tester);

    expect(find.text('Finished Ep'), findsOneWidget);
    expect(find.text('Unfinished Ep'), findsOneWidget);

    await tester.tap(find.text('Unfinished'));
    await tester.pumpAndSettle();

    expect(find.text('Finished Ep'), findsNothing);
    expect(find.text('Unfinished Ep'), findsOneWidget);
  });
}
