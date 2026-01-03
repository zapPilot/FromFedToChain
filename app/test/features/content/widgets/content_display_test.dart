import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:from_fed_to_chain_app/features/content/widgets/content_display.dart';
import 'package:from_fed_to_chain_app/features/content/services/content_service.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_content.dart';

import '../../../test_utils.dart';
@GenerateMocks([ContentService])
import 'content_display_test.mocks.dart';

void main() {
  group('ContentDisplay', () {
    late MockContentService mockContentService;
    late AudioFile testAudioFile;
    late AudioContent testAudioContent;

    setUp(() {
      mockContentService = MockContentService();
      testAudioFile = TestUtils.createSampleAudioFile(id: '1');
      testAudioContent = AudioContent(
        id: '1',
        title: 'Title',
        language: 'en-US',
        category: 'defi',
        date: DateTime.now(),
        status: 'published',
        description: 'This is the transcript.',
        references: const ['Ref 1', 'Ref 2'],
        updatedAt: DateTime.now(),
      );
    });

    testWidgets('renders header correctly collapsed', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ContentDisplay(
            currentAudioFile: testAudioFile,
            contentService: mockContentService,
            isExpanded: false,
          ),
        ),
      ));

      expect(find.text('Content Script'), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
      expect(find.text('This is the transcript.'), findsNothing);
    });

    testWidgets('loads and renders content when expanded', (tester) async {
      when(mockContentService.getContentForAudioFile(any))
          .thenAnswer((_) async => testAudioContent);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ContentDisplay(
            currentAudioFile: testAudioFile,
            contentService: mockContentService,
            isExpanded: true,
          ),
        ),
      ));

      // Initial loading state might be fast, but we can check if it settles
      expect(
          find.byType(CircularProgressIndicator),
          findsAtLeastNWidgets(
              1)); // Loading inside expanded area + potential header spinner

      await tester.pumpAndSettle();

      expect(find.text('This is the transcript.'), findsOneWidget);
      expect(find.byIcon(Icons.expand_less), findsOneWidget);

      verify(mockContentService.getContentForAudioFile(any)).called(1);
    });

    testWidgets('shows no content message if description empty',
        (tester) async {
      final contentNoDesc = AudioContent(
          id: '1',
          title: 'T',
          language: 'en',
          category: 'cat',
          date: DateTime.now(),
          status: 'pub',
          updatedAt: DateTime.now(),
          description: '',
          references: const []);

      when(mockContentService.getContentForAudioFile(any))
          .thenAnswer((_) async => contentNoDesc);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ContentDisplay(
            currentAudioFile: testAudioFile,
            contentService: mockContentService,
            isExpanded: true,
          ),
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.text('Content text not available for this episode.'),
          findsOneWidget);
    });

    testWidgets('shows error and retry button', (tester) async {
      when(mockContentService.getContentForAudioFile(any))
          .thenThrow(Exception('Network Error'));

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ContentDisplay(
            currentAudioFile: testAudioFile,
            contentService: mockContentService,
            isExpanded: true,
          ),
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.textContaining('Failed to load content'),
          findsNWidgets(2)); // Title and error message
      expect(find.text('Retry'), findsOneWidget);

      // Retry
      when(mockContentService.getContentForAudioFile(any))
          .thenAnswer((_) async => testAudioContent);

      await tester.tap(find.text('Retry'));
      await tester.pump(const Duration(milliseconds: 100)); // Start loading
      await tester.pumpAndSettle();

      expect(find.text('This is the transcript.'), findsOneWidget);
    });

    testWidgets('shows references dialog', (tester) async {
      when(mockContentService.getContentForAudioFile(any))
          .thenAnswer((_) async => testAudioContent);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ContentDisplay(
            currentAudioFile: testAudioFile,
            contentService: mockContentService,
            isExpanded: true,
          ),
        ),
      ));

      await tester.pumpAndSettle();

      final refButton = find.text('References (2)');
      expect(refButton, findsOneWidget);

      await tester.tap(refButton);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Ref 1'), findsOneWidget);
      expect(find.text('Ref 2'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('reloads content when audio file changes', (tester) async {
      when(mockContentService.getContentForAudioFile(any))
          .thenAnswer((_) async => testAudioContent);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ContentDisplay(
            currentAudioFile: testAudioFile,
            contentService: mockContentService,
            isExpanded: true,
          ),
        ),
      ));

      await tester.pumpAndSettle();
      verify(mockContentService.getContentForAudioFile(testAudioFile))
          .called(1); // Explicit match

      final newAudioFile = testAudioFile.copyWith(id: '2', title: 'Ep 2');
      when(mockContentService.getContentForAudioFile(any))
          .thenAnswer((_) async => testAudioContent);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ContentDisplay(
            currentAudioFile: newAudioFile,
            contentService: mockContentService,
            isExpanded: true,
          ),
        ),
      ));

      await tester.pumpAndSettle();

      // Verify called with new file
      verify(mockContentService.getContentForAudioFile(
          argThat(predicate<AudioFile>((f) => f.id == '2')))).called(1);
    });
  });
}
