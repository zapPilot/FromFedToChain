import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:from_fed_to_chain_app/models/audio_file.dart';
import 'package:from_fed_to_chain_app/services/audio_player_service.dart';
import 'package:from_fed_to_chain_app/services/player_state_notifier.dart';
import 'package:from_fed_to_chain_app/themes/app_theme.dart';
import 'package:from_fed_to_chain_app/config/api_config.dart';
import 'package:from_fed_to_chain_app/widgets/mini_player.dart';
import '../test_utils.dart';

/// Widget test utilities specifically for audio control widgets
class WidgetTestUtils {
  // Mock callback tracking
  static int tapCount = 0;
  static int longPressCount = 0;
  static String lastSearchText = '';
  static String lastSelectedLanguage = '';
  static String lastSelectedCategory = '';
  static double lastSelectedSpeed = 1.0;
  static bool lastPlayPauseState = false;

  /// Reset all callback counters
  static void resetCallbacks() {
    tapCount = 0;
    longPressCount = 0;
    lastSearchText = '';
    lastSelectedLanguage = '';
    lastSelectedCategory = '';
    lastSelectedSpeed = 1.0;
    lastPlayPauseState = false;
  }

  /// Mock callbacks
  static void mockTap() => tapCount++;
  static void mockLongPress() => longPressCount++;
  static void mockPlayPause() => lastPlayPauseState = !lastPlayPauseState;
  static void mockNext() => tapCount++;
  static void mockPrevious() => tapCount++;
  static void mockSkipForward() => tapCount++;
  static void mockSkipBackward() => tapCount++;
  static void mockSearchChanged(String text) => lastSearchText = text;
  static void mockLanguageChanged(String language) =>
      lastSelectedLanguage = language;
  static void mockCategoryChanged(String category) =>
      lastSelectedCategory = category;
  static void mockSpeedChanged(double speed) => lastSelectedSpeed = speed;

  /// Create comprehensive test AudioFile with realistic metadata
  static AudioFile createTestAudioFile({
    String id = 'test-audio-file-001',
    String title = 'Test Audio: Bitcoin Market Analysis',
    String language = 'en-US',
    String category = 'daily-news',
    Duration? duration,
    int? fileSizeBytes,
    DateTime? lastModified,
    String? streamingUrl,
  }) {
    return AudioFile(
      id: id,
      title: title,
      language: language,
      category: category,
      streamingUrl: streamingUrl ?? 'https://example.com/audio/$id.m3u8',
      path: 'audio/$language/$category/$id.m3u8',
      duration: duration ?? const Duration(minutes: 15, seconds: 30),
      fileSizeBytes:
          fileSizeBytes ?? (15 * 60 * 320 * 1024) ~/ 8, // 15min @ 320kbps
      lastModified:
          lastModified ?? DateTime.now().subtract(const Duration(days: 2)),
    );
  }

  /// Create test AudioFile with different categories
  static AudioFile createTestAudioFileWithCategory(String category) {
    final categoryTitles = {
      'daily-news': 'Today\'s Crypto News Roundup',
      'ethereum': 'Ethereum Network Updates',
      'macro': 'Global Economic Outlook',
      'startup': 'DeFi Startup Spotlight',
      'ai': 'AI in Blockchain Technology',
      'defi': 'DeFi Protocol Deep Dive',
    };

    return createTestAudioFile(
      id: 'test-$category-001',
      title: categoryTitles[category] ?? 'Test Audio',
      category: category,
      duration: Duration(minutes: 10 + category.length), // Varied durations
    );
  }

  /// Create test AudioFile with different languages
  static AudioFile createTestAudioFileWithLanguage(String language) {
    final languageTitles = {
      'en-US': 'English Audio Content',
      'ja-JP': 'Japanese Audio Content',
      'zh-TW': 'Traditional Chinese Audio Content',
    };

    return createTestAudioFile(
      id: 'test-$language-001',
      title: languageTitles[language] ?? 'Test Audio',
      language: language,
    );
  }

  /// Create list of test AudioFiles with varied metadata
  static List<AudioFile> createTestAudioFileList({
    int count = 5,
    bool mixedLanguages = true,
    bool mixedCategories = true,
  }) {
    final audioFiles = <AudioFile>[];

    for (int i = 0; i < count; i++) {
      final language = mixedLanguages
          ? ApiConfig
              .supportedLanguages[i % ApiConfig.supportedLanguages.length]
          : 'en-US';

      final category = mixedCategories
          ? ApiConfig
              .supportedCategories[i % ApiConfig.supportedCategories.length]
          : 'daily-news';

      audioFiles.add(createTestAudioFile(
        id: 'test-audio-$i',
        title: 'Test Audio Episode ${i + 1}',
        language: language,
        category: category,
        duration: Duration(minutes: 5 + (i * 3)),
        lastModified: DateTime.now().subtract(Duration(days: i)),
      ));
    }

    return audioFiles;
  }

  /// Create widget wrapper with theme for testing
  static Widget createTestWrapper(Widget child) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(child: child),
      ),
    );
  }

  /// Create widget wrapper with minimal setup
  static Widget createMinimalWrapper(Widget child) {
    return MaterialApp(
      home: Material(child: child),
    );
  }

  /// Pump widget with theme wrapper
  static Future<void> pumpWidgetWithTheme(
    WidgetTester tester,
    Widget widget,
  ) async {
    await tester.pumpWidget(createTestWrapper(widget));
  }

  /// Pump widget with minimal wrapper
  static Future<void> pumpWidgetMinimal(
    WidgetTester tester,
    Widget widget,
  ) async {
    await tester.pumpWidget(createMinimalWrapper(widget));
  }

  /// Test interaction helpers
  static Future<void> tapAndSettle(
    WidgetTester tester,
    Finder finder,
  ) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  static Future<void> longPressAndSettle(
    WidgetTester tester,
    Finder finder,
  ) async {
    await tester.longPress(finder);
    await tester.pumpAndSettle();
  }

  static Future<void> enterTextAndSettle(
    WidgetTester tester,
    Finder finder,
    String text,
  ) async {
    await tester.enterText(finder, text);
    await tester.pumpAndSettle();
  }

  static Future<void> dragAndSettle(
    WidgetTester tester,
    Finder finder,
    Offset offset,
  ) async {
    await tester.drag(finder, offset);
    await tester.pumpAndSettle();
  }

  /// Find widgets by semantic labels
  static Finder findBySemanticsLabel(String label) {
    return find.bySemanticsLabel(label);
  }

  /// Find widgets by tooltip
  static Finder findByTooltip(String tooltip) {
    return find.byTooltip(tooltip);
  }

  /// Verify widget accessibility
  static Future<void> verifyAccessibility(WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  }

  /// Test different playback states
  static List<AppPlaybackState> getAllPlaybackStates() {
    return AppPlaybackState.values;
  }

  /// Test different audio control sizes
  static List<dynamic> getAllAudioControlSizes() {
    // Using dynamic to avoid enum import issues in tests
    return ['small', 'medium', 'large'];
  }

  /// Test completion percentages for progress indicators
  static List<double> getTestCompletionPercentages() {
    return [0.0, 0.25, 0.5, 0.75, 1.0];
  }

  /// Test speed options for playback speed selector
  static List<double> getTestSpeedOptions() {
    return [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
  }

  /// Create test error scenarios
  static Map<String, dynamic> createTestErrorScenario({
    String type = 'network',
    String message = 'Test error message',
    String code = 'TEST_ERROR',
  }) {
    return {
      'type': type,
      'message': message,
      'code': code,
    };
  }

  /// Verify theme consistency
  static void verifyThemeColors(WidgetTester tester) {
    expect(AppTheme.primaryColor, isNotNull);
    expect(AppTheme.backgroundColor, isNotNull);
    expect(AppTheme.onSurfaceColor, isNotNull);
    expect(AppTheme.cardColor, isNotNull);
  }

  /// Test language and category combinations
  static List<Map<String, String>> getLanguageCategoryCombinations() {
    final combinations = <Map<String, String>>[];

    for (final language in ApiConfig.supportedLanguages) {
      for (final category in ApiConfig.supportedCategories) {
        combinations.add({
          'language': language,
          'category': category,
        });
      }
    }

    return combinations;
  }

  /// Create test widget with specific size constraints
  static Widget constrainWidget(Widget child, {double? width, double? height}) {
    return SizedBox(
      width: width,
      height: height,
      child: child,
    );
  }

  /// Test different screen sizes
  static List<Size> getTestScreenSizes() {
    return [
      const Size(320, 568), // iPhone 5
      const Size(375, 667), // iPhone 6/7/8
      const Size(414, 896), // iPhone XR/11
      const Size(768, 1024), // iPad
      const Size(1024, 768), // iPad landscape
    ];
  }

  /// Set device size for testing
  static void setDeviceSize(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
  }

  /// Reset device size
  static void resetDeviceSize(WidgetTester tester) {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }

  /// Custom matchers for audio widget testing
  static Matcher hasPlayIcon() => _HasPlayIcon();
  static Matcher hasPauseIcon() => _HasPauseIcon();
  static Matcher hasLoadingIndicator() => _HasLoadingIndicator();
  static Matcher hasErrorIcon() => _HasErrorIcon();
  static Matcher hasProgressIndicator() => _HasProgressIndicator();
  static Matcher hasCorrectAccessibilityLabels() =>
      _HasCorrectAccessibilityLabels();
  static Matcher hasGradientDecoration() => _HasGradientDecoration();
  static Matcher hasBoxShadow() => _HasBoxShadow();
  static Matcher hasSelectedStyling() => _HasSelectedStyling();

  /// Verify audio control button states
  static void verifyPlayPauseButton({
    required WidgetTester tester,
    required bool shouldShowPlay,
    required bool shouldBeEnabled,
  }) {
    if (shouldShowPlay) {
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    } else {
      expect(find.byIcon(Icons.pause), findsOneWidget);
    }

    final buttonFinder = find.byType(IconButton);
    expect(buttonFinder, findsWidgets);

    final IconButton button = tester.widget(buttonFinder.first);
    expect(button.onPressed != null, shouldBeEnabled);
  }

  /// Verify filter chip selection state
  static void verifyFilterChip({
    required WidgetTester tester,
    required String label,
    required bool shouldBeSelected,
  }) {
    final chipFinder = find.text(label);
    expect(chipFinder, findsOneWidget);

    // Check if the chip container has selected styling
    final containerFinder = find.ancestor(
      of: chipFinder,
      matching: find.byType(Container),
    );

    if (containerFinder.evaluate().isNotEmpty) {
      final Container container = tester.widget(containerFinder.first);
      final decoration = container.decoration as BoxDecoration?;

      if (shouldBeSelected && decoration != null) {
        expect(decoration.color, isNot(equals(Colors.transparent)));
      }
    }
  }

  /// Verify audio item card states
  static void verifyAudioItemCard({
    required WidgetTester tester,
    required AudioFile audioFile,
    required bool shouldShowPlayButton,
    required bool shouldShowCurrentlyPlaying,
  }) {
    // Verify title
    expect(find.text(audioFile.displayTitle), findsOneWidget);

    // Verify category display (using display name, not raw category)
    final categoryDisplayName = _getCategoryDisplayName(audioFile.category);
    expect(find.textContaining(categoryDisplayName), findsOneWidget);

    // Verify language display (using display name, not language code)
    final languageDisplayName = _getLanguageDisplayName(audioFile.language);
    expect(find.textContaining(languageDisplayName), findsOneWidget);

    // Verify play button or duration
    if (shouldShowPlayButton) {
      final playIcon = find.byIcon(Icons.play_arrow);
      final pauseIcon = find.byIcon(Icons.pause);
      expect(playIcon.evaluate().isNotEmpty || pauseIcon.evaluate().isNotEmpty,
          true);
    }

    // Verify currently playing indicator
    if (shouldShowCurrentlyPlaying) {
      expect(find.text('Now Playing'), findsOneWidget);
      expect(find.byIcon(Icons.graphic_eq), findsOneWidget);
    }
  }

  /// Verify search bar functionality
  static void verifySearchBarFunction({
    required WidgetTester tester,
    required String searchText,
    required bool shouldShowClearButton,
  }) {
    // Verify search text is displayed
    if (searchText.isNotEmpty) {
      expect(find.text(searchText), findsOneWidget);
    }

    // Verify clear button visibility
    if (shouldShowClearButton) {
      expect(find.byIcon(Icons.clear), findsOneWidget);
    } else {
      expect(find.byIcon(Icons.clear), findsNothing);
    }

    // Verify search icon is always present
    expect(find.byIcon(Icons.search), findsOneWidget);
  }

  /// Verify playback speed selector state
  static void verifyPlaybackSpeedSelector({
    required WidgetTester tester,
    required double currentSpeed,
    required List<double> expectedSpeeds,
  }) {
    // Verify current speed display
    expect(find.text('${currentSpeed.toStringAsFixed(2)}x'), findsOneWidget);

    // Verify all speed options are present
    for (final speed in expectedSpeeds) {
      expect(find.text('${speed}x'), findsOneWidget);
    }

    // Verify slider is present
    expect(find.byType(Slider), findsOneWidget);

    // Verify section titles
    expect(find.text('Playback Speed'), findsOneWidget);
    expect(find.text('Custom Speed'), findsOneWidget);
  }

  /// Verify mini player state
  static void verifyMiniPlayerState({
    required WidgetTester tester,
    required AudioFile audioFile,
    required AppPlaybackState playbackState,
    required bool shouldShowCorrectIcon,
  }) {
    // Verify audio file information
    expect(find.text(audioFile.displayTitle), findsOneWidget);
    expect(find.textContaining(audioFile.category), findsOneWidget);
    expect(find.textContaining(audioFile.language), findsOneWidget);

    // Verify playback state icon
    if (shouldShowCorrectIcon) {
      switch (playbackState) {
        case AppPlaybackState.playing:
          expect(find.byIcon(Icons.pause), findsOneWidget);
          break;
        case AppPlaybackState.paused:
          expect(find.byIcon(Icons.play_arrow), findsOneWidget);
          break;
        case AppPlaybackState.loading:
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
          break;
        case AppPlaybackState.error:
          expect(find.byIcon(Icons.refresh), findsOneWidget);
          break;
        default:
          expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      }
    }

    // Verify control buttons
    expect(find.byIcon(Icons.skip_previous), findsOneWidget);
    expect(find.byIcon(Icons.skip_next), findsOneWidget);
  }

  /// Test widget with different themes
  static Future<void> testWithDifferentThemes(
    WidgetTester tester,
    Widget Function() widgetBuilder,
  ) async {
    // Test with dark theme (default)
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(body: widgetBuilder()),
      ),
    );

    expect(tester.takeException(), isNull);
    await tester.pump();

    // Test with system theme
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        darkTheme: AppTheme.darkTheme,
        home: Scaffold(body: widgetBuilder()),
      ),
    );

    expect(tester.takeException(), isNull);
  }

  /// Create test data for multiple audio files with different states
  static List<Map<String, dynamic>> createTestScenarios() {
    return [
      {
        'audioFile': createTestAudioFile(),
        'playbackState': AppPlaybackState.paused,
        'isPlaying': false,
        'isLoading': false,
        'hasError': false,
      },
      {
        'audioFile': createTestAudioFileWithCategory('ethereum'),
        'playbackState': AppPlaybackState.playing,
        'isPlaying': true,
        'isLoading': false,
        'hasError': false,
      },
      {
        'audioFile': createTestAudioFileWithLanguage('ja-JP'),
        'playbackState': AppPlaybackState.loading,
        'isPlaying': false,
        'isLoading': true,
        'hasError': false,
      },
      {
        'audioFile': createTestAudioFileWithCategory('ai'),
        'playbackState': AppPlaybackState.error,
        'isPlaying': false,
        'isLoading': false,
        'hasError': true,
      },
    ];
  }

  /// Verify widget handles all test scenarios correctly
  static Future<void> verifyAllTestScenarios(
    WidgetTester tester,
    Widget Function(Map<String, dynamic>) widgetBuilder,
  ) async {
    final scenarios = createTestScenarios();

    for (final scenario in scenarios) {
      await tester.pumpWidget(
        createTestWrapper(widgetBuilder(scenario)),
      );

      // Each scenario should render without errors
      expect(tester.takeException(), isNull);
      await tester.pump();
    }
  }

  /// Performance testing helper
  static Future<Duration> measureWidgetBuildTime(
    WidgetTester tester,
    Widget Function() widgetBuilder,
  ) async {
    final stopwatch = Stopwatch()..start();

    await tester.pumpWidget(createTestWrapper(widgetBuilder()));
    await tester.pumpAndSettle();

    stopwatch.stop();
    return stopwatch.elapsed;
  }

  /// Memory usage testing helper (simplified)
  static Future<void> testMemoryUsage(
    WidgetTester tester,
    Widget Function() widgetBuilder, {
    int iterations = 10,
  }) async {
    // Repeatedly build and dispose widgets to test for memory leaks
    for (int i = 0; i < iterations; i++) {
      await tester.pumpWidget(createTestWrapper(widgetBuilder()));
      await tester.pump();

      // Clear the widget
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pump();
    }

    // Should not have any lingering state or memory leaks
    expect(tester.takeException(), isNull);
  }

  /// Stress test widget with rapid interactions
  static Future<void> stressTestWidget(
    WidgetTester tester,
    Widget widget,
    VoidCallback testInteraction, {
    int iterations = 50,
  }) async {
    await tester.pumpWidget(createTestWrapper(widget));

    // Rapidly perform the same interaction
    for (int i = 0; i < iterations; i++) {
      testInteraction();
      await tester.pump(const Duration(milliseconds: 16)); // 60fps
    }

    // Should handle stress without errors
    expect(tester.takeException(), isNull);
  }

  /// Helper method to get category display name (matches ApiConfig)
  static String _getCategoryDisplayName(String category) {
    const categoryNames = {
      'daily-news': 'Daily News',
      'ethereum': 'Ethereum',
      'macro': 'Macro Economics',
      'startup': 'Startup',
      'ai': 'AI & Technology',
      'defi': 'DeFi',
    };
    return categoryNames[category] ?? category;
  }

  /// Helper method to get language display name (matches ApiConfig)
  static String _getLanguageDisplayName(String language) {
    const languageNames = {
      'zh-TW': '中文',
      'en-US': 'English',
      'ja-JP': '日本語',
    };
    return languageNames[language] ?? language;
  }

  /// Create MiniPlayer widget using new boolean API
  /// Helper method for test migration after MiniPlayer API refactor
  static MiniPlayer createMiniPlayer({
    required AudioFile audioFile,
    required AppPlaybackState playbackState,
    VoidCallback? onTap,
    VoidCallback? onPlayPause,
    VoidCallback? onNext,
    VoidCallback? onPrevious,
  }) {
    final params =
        TestUtils.convertPlaybackStateToMiniPlayerParams(playbackState);

    return MiniPlayer(
      audioFile: audioFile,
      isPlaying: params['isPlaying'],
      isPaused: params['isPaused'],
      isLoading: params['isLoading'],
      hasError: params['hasError'],
      stateText: params['stateText'],
      onTap: onTap ?? mockTap,
      onPlayPause: onPlayPause ?? mockPlayPause,
      onNext: onNext ?? mockNext,
      onPrevious: onPrevious ?? mockPrevious,
    );
  }
}

/// Custom matcher for play icon
class _HasPlayIcon extends Matcher {
  @override
  bool matches(covariant Object? item, Map<dynamic, dynamic> matchState) {
    return find.byIcon(Icons.play_arrow).evaluate().isNotEmpty;
  }

  @override
  Description describe(Description description) {
    return description.add('has play icon');
  }
}

/// Custom matcher for pause icon
class _HasPauseIcon extends Matcher {
  @override
  bool matches(covariant Object? item, Map<dynamic, dynamic> matchState) {
    return find.byIcon(Icons.pause).evaluate().isNotEmpty;
  }

  @override
  Description describe(Description description) {
    return description.add('has pause icon');
  }
}

/// Custom matcher for loading indicator
class _HasLoadingIndicator extends Matcher {
  @override
  bool matches(covariant Object? item, Map<dynamic, dynamic> matchState) {
    return find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
  }

  @override
  Description describe(Description description) {
    return description.add('has loading indicator');
  }
}

/// Custom matcher for error icon
class _HasErrorIcon extends Matcher {
  @override
  bool matches(covariant Object? item, Map<dynamic, dynamic> matchState) {
    return find.byIcon(Icons.refresh).evaluate().isNotEmpty ||
        find.byIcon(Icons.error_outline).evaluate().isNotEmpty;
  }

  @override
  Description describe(Description description) {
    return description.add('has error icon');
  }
}

/// Custom matcher for progress indicator
class _HasProgressIndicator extends Matcher {
  @override
  bool matches(covariant Object? item, Map<dynamic, dynamic> matchState) {
    return find.byType(LinearProgressIndicator).evaluate().isNotEmpty ||
        find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
  }

  @override
  Description describe(Description description) {
    return description.add('has progress indicator');
  }
}

/// Custom matcher for accessibility labels
class _HasCorrectAccessibilityLabels extends Matcher {
  @override
  bool matches(covariant Object? item, Map<dynamic, dynamic> matchState) {
    // Check if semantic labels exist for interactive elements
    final tooltips = find.byType(Tooltip);
    final buttons = find.byType(IconButton);

    return tooltips.evaluate().isNotEmpty || buttons.evaluate().isNotEmpty;
  }

  @override
  Description describe(Description description) {
    return description.add('has correct accessibility labels');
  }
}

/// Custom matcher for gradient decoration
class _HasGradientDecoration extends Matcher {
  @override
  bool matches(covariant Object? item, Map<dynamic, dynamic> matchState) {
    final containers = find.byType(Container);
    for (int i = 0; i < containers.evaluate().length; i++) {
      final container = TestWidgetInspector.getCurrentWidgetTester()
          ?.widget<Container>(containers.at(i));
      final decoration = container?.decoration as BoxDecoration?;

      if (decoration?.gradient != null) {
        return true;
      }
    }
    return false;
  }

  @override
  Description describe(Description description) {
    return description.add('has gradient decoration');
  }
}

/// Custom matcher for box shadow
class _HasBoxShadow extends Matcher {
  @override
  bool matches(covariant Object? item, Map<dynamic, dynamic> matchState) {
    final containers = find.byType(Container);
    for (int i = 0; i < containers.evaluate().length; i++) {
      final container = TestWidgetInspector.getCurrentWidgetTester()
          ?.widget<Container>(containers.at(i));
      final decoration = container?.decoration as BoxDecoration?;

      if (decoration?.boxShadow != null && decoration!.boxShadow!.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  @override
  Description describe(Description description) {
    return description.add('has box shadow');
  }
}

/// Custom matcher for selected styling
class _HasSelectedStyling extends Matcher {
  @override
  bool matches(covariant Object? item, Map<dynamic, dynamic> matchState) {
    final animatedContainers = find.byType(AnimatedContainer);
    for (int i = 0; i < animatedContainers.evaluate().length; i++) {
      final container = TestWidgetInspector.getCurrentWidgetTester()
          ?.widget<AnimatedContainer>(animatedContainers.at(i));
      final decoration = container?.decoration as BoxDecoration?;

      // Check for selected styling (primary color background)
      if (decoration?.color == AppTheme.primaryColor) {
        return true;
      }
    }
    return false;
  }

  @override
  Description describe(Description description) {
    return description.add('has selected styling');
  }
}

/// Helper class for test widget inspection
class TestWidgetInspector {
  static WidgetTester? _currentTester;

  static void setCurrentTester(WidgetTester tester) {
    _currentTester = tester;
  }

  static WidgetTester? getCurrentWidgetTester() {
    return _currentTester;
  }

  static void clearCurrentTester() {
    _currentTester = null;
  }
}
