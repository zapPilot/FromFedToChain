import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:from_fed_to_chain_app/features/audio/services/audio_player_service.dart';
import 'package:from_fed_to_chain_app/features/audio/widgets/player/player_track_info.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';
import 'package:from_fed_to_chain_app/features/content/services/content_service.dart';

import 'player_track_info_test.mocks.dart';

@GenerateMocks([ContentService, AudioPlayerService])
void main() {
  late MockContentService mockContentService;
  late MockAudioPlayerService mockAudioPlayerService;

  setUp(() {
    mockContentService = MockContentService();
    mockAudioPlayerService = MockAudioPlayerService();
  });

  Widget createWidgetUnderTest(AudioFile currentAudio) {
    return MaterialApp(
      home: Scaffold(
        body: MultiProvider(
          providers: [
            ChangeNotifierProvider<ContentService>.value(
                value: mockContentService),
            ChangeNotifierProvider<AudioPlayerService>.value(
                value: mockAudioPlayerService),
          ],
          child: PlayerTrackInfo(currentAudio: currentAudio),
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
    streamingUrl: 'url2',
    path: 'path2',
  );

  Future<void> pumpTrackInfo(
    WidgetTester tester,
    AudioFile currentAudio,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest(currentAudio));
    await tester.pumpAndSettle();
  }

  testWidgets('PlayerTrackInfo displays title and category',
      (WidgetTester tester) async {
    when(mockContentService.getEpisodeVersions(any)).thenReturn([testAudio]);

    await pumpTrackInfo(tester, testAudio);

    expect(find.text('Test Episode'), findsOneWidget);
    expect(find.text('Daily News'), findsOneWidget);
    expect(find.text('繁體中文'), findsOneWidget);
    expect(find.text('🇹🇼'), findsOneWidget);
  });

  testWidgets('PlayerTrackInfo shows dropdown when multiple versions available',
      (WidgetTester tester) async {
    when(mockContentService.getEpisodeVersions('test-ep'))
        .thenReturn([testAudio, testAudioEN]);

    await pumpTrackInfo(tester, testAudio);

    expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);

    await tester.tap(find.text('🇹🇼 繁體中文'));
    await tester.pumpAndSettle();

    expect(find.text('🇺🇸 English'), findsOneWidget);
  });

  testWidgets('PlayerTrackInfo calls playAudio when language changed',
      (WidgetTester tester) async {
    when(mockContentService.getEpisodeVersions('test-ep'))
        .thenReturn([testAudio, testAudioEN]);

    await pumpTrackInfo(tester, testAudio);

    await tester.tap(find.text('🇹🇼 繁體中文'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('🇺🇸 English').last);
    await tester.pumpAndSettle();

    verify(mockAudioPlayerService.playAudio(testAudioEN)).called(1);
  });
}
