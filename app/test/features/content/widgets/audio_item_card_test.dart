import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:from_fed_to_chain_app/features/content/widgets/audio_item_card.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';

import '../../../test_utils.dart';

void main() {
  group('AudioItemCard', () {
    late AudioFile testAudioFile;

    setUp(() {
      testAudioFile = TestUtils.createSampleAudioFile(
        id: '1',
        title: 'Test Episode',
        duration: const Duration(minutes: 5),
        category: 'daily-news',
        language: 'en-US',
      );
    });

    testWidgets('renders correctly with default props', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AudioItemCard(
            audioFile: testAudioFile,
            onTap: (_) {},
          ),
        ),
      ));

      expect(find.text('Test Episode'), findsOneWidget);
    });

    testWidgets('displays "Now Playing" when isCurrentlyPlaying is true',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: AudioItemCard(
            audioFile: testAudioFile,
            onTap: (_) {},
            isCurrentlyPlaying: true,
          ),
        ),
      ));

      expect(find.text('Now Playing'), findsOneWidget);
    });

    testWidgets('hides play button when showPlayButton is false',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AudioItemCard(
            audioFile: testAudioFile,
            onTap: (_) {},
            showPlayButton: false,
          ),
        ),
      ));

      expect(find.byKey(AudioItemCard.playButtonKey), findsNothing);
    });
    testWidgets('triggers onTap callback', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AudioItemCard(
            audioFile: testAudioFile,
            onTap: (_) => tapped = true,
          ),
        ),
      ));

      await tester.tap(find.byKey(AudioItemCard.cardKey));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('triggers play button callback', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AudioItemCard(
            audioFile: testAudioFile,
            onTap: (_) {},
            onPlayTap: (_) => tapped = true,
          ),
        ),
      ));

      await tester.tap(find.byKey(AudioItemCard.playButtonKey));
      await tester.pump();

      expect(tapped, isTrue); // Play button also triggers the main onTap
    });

    testWidgets('formats dates correctly', (tester) async {
      // Create files with different dates relative to "Today"
      // Note: Test depends on "now", which is tricky. relying on _formatDate Logic.
      // We can't mock DateTime.now in widgettest easily without a wrapper.
      // But we can check if it displays "Today" for a file created just now.

      final todayFile =
          testAudioFile.copyWith(lastModified: DateTime.now(), id: 'today-id');

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AudioItemCard(
            audioFile: todayFile,
            onTap: (_) {},
          ),
        ),
      ));

      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('shows HLS badge if isHlsStream and play button hidden',
        (tester) async {
      // Only shows when showPlayButton is false
      final hlsFile = testAudioFile.copyWith(path: 'stream.m3u8');

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AudioItemCard(
            audioFile: hlsFile,
            onTap: (_) {},
            showPlayButton: false,
          ),
        ),
      ));

      expect(find.text('HLS'), findsOneWidget);
    });
  });
}
