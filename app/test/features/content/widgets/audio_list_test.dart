import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:from_fed_to_chain_app/features/content/widgets/audio_list.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';

void main() {
  group('AudioList Widget Tests', () {
    final testAudioFile = AudioFile(
      id: 'test-1',
      title: 'Test Episode',
      language: 'zh-TW',
      category: 'daily-news',
      streamingUrl: 'https://test.com/audio.m3u8',
      path: 'audio/test.m3u8',
      lastModified: DateTime.now(),
      duration: const Duration(minutes: 10),
    );

    testWidgets('shows empty state when no episodes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AudioList(
              episodes: const [],
              onEpisodeTap: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('No episodes found'), findsOneWidget);
      expect(
          find.text('Try different filters or search terms'), findsOneWidget);
      expect(find.byIcon(Icons.headphones_outlined), findsOneWidget);
    });

    testWidgets('shows loading indicator when showLoadingMore is true',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AudioList(
              episodes: [testAudioFile],
              onEpisodeTap: (_) {},
              showLoadingMore: true,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Loading more episodes...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('calls onEpisodeTap when episode is tapped', (tester) async {
      AudioFile? tappedEpisode;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AudioList(
              episodes: [testAudioFile],
              onEpisodeTap: (episode) => tappedEpisode = episode,
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Test Episode'));
      await tester.pump();

      expect(tappedEpisode, testAudioFile);
    });

    testWidgets('calls onEpisodeLongPress when episode is long-pressed',
        (tester) async {
      AudioFile? longPressedEpisode;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AudioList(
              episodes: [testAudioFile],
              onEpisodeTap: (_) {},
              onEpisodeLongPress: (episode) => longPressedEpisode = episode,
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.longPress(find.text('Test Episode'));
      await tester.pump();

      expect(longPressedEpisode, testAudioFile);
    });
  });
}
