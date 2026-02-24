import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:from_fed_to_chain_app/features/audio/services/audio_player_service.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';
import 'package:from_fed_to_chain_app/features/content/services/content_service.dart';
import 'package:from_fed_to_chain_app/features/content/services/playlist_service.dart';
import 'package:from_fed_to_chain_app/features/content/widgets/episode_options_sheet.dart';

import 'episode_options_sheet_test.mocks.dart';

@GenerateMocks([ContentService, AudioPlayerService, PlaylistService])
void main() {
  late MockContentService mockContentService;
  late MockAudioPlayerService mockAudioPlayerService;
  late MockPlaylistService mockPlaylistService;

  setUp(() {
    mockContentService = MockContentService();
    mockAudioPlayerService = MockAudioPlayerService();
    mockPlaylistService = MockPlaylistService();
  });

  Widget createWidgetUnderTest(AudioFile episode) {
    return MaterialApp(
      home: Scaffold(
        body: MultiProvider(
          providers: [
            ChangeNotifierProvider<ContentService>.value(
                value: mockContentService),
            ChangeNotifierProvider<AudioPlayerService>.value(
                value: mockAudioPlayerService),
            ChangeNotifierProvider<PlaylistService>.value(
                value: mockPlaylistService),
          ],
          child: EpisodeOptionsSheet(episode: episode),
        ),
      ),
    );
  }

  final testAudio = AudioFile(
    id: 'test-ep',
    title: 'Test Episode',
    language: 'zh-TW',
    category: 'daily-news',
    streamingUrl: 'url1',
    path: 'path1',
    lastModified: DateTime.now(),
  );

  final testAudioEN = testAudio.copyWith(
    language: 'en-US',
    title: 'Test Episode EN',
  );

  Future<void> pumpOptionsSheet(
    WidgetTester tester,
    AudioFile episode,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest(episode));
    await tester.pump();
  }

  testWidgets('EpisodeOptionsSheet displays episode info',
      (WidgetTester tester) async {
    when(mockContentService.getEpisodeVersions('test-ep'))
        .thenReturn([testAudio]);

    await pumpOptionsSheet(tester, testAudio);

    expect(find.text('Test Episode'), findsOneWidget);
    expect(find.text('🇹🇼 zh-TW'), findsOneWidget);
  });

  testWidgets('EpisodeOptionsSheet updates selected language version',
      (WidgetTester tester) async {
    when(mockContentService.getEpisodeVersions('test-ep'))
        .thenReturn([testAudio, testAudioEN]);

    await pumpOptionsSheet(tester, testAudio);

    expect(find.text('Test Episode'), findsOneWidget);

    await tester.tap(find.text('🇹🇼 zh-TW'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('🇺🇸 en-US').last);
    await tester.pumpAndSettle();

    expect(find.text('Test Episode EN'), findsOneWidget);
    expect(find.text('🇺🇸 en-US'), findsOneWidget);
  });

  testWidgets('EpisodeOptionsSheet calls playAudio when Play tapped',
      (WidgetTester tester) async {
    when(mockContentService.getEpisodeVersions('test-ep'))
        .thenReturn([testAudio]);

    await pumpOptionsSheet(tester, testAudio);

    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();

    verify(mockAudioPlayerService.playAudio(testAudio)).called(1);
  });
}
