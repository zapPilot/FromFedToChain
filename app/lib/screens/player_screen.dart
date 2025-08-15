import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../themes/app_theme.dart';
import '../services/audio_service.dart';
import '../services/content_service.dart';
import '../services/deep_link_service.dart';
import '../models/audio_file.dart';
import '../widgets/audio_controls.dart';
import '../widgets/playback_speed_selector.dart';
import '../widgets/content_display.dart';

/// Full-screen audio player with enhanced controls
class PlayerScreen extends StatefulWidget {
  final String? contentId;
  
  const PlayerScreen({super.key, this.contentId});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _albumArtAnimation;
  bool _showSpeedSelector = false;
  bool _showContentScript = false;

  @override
  void initState() {
    super.initState();
    
    print('🎬 PlayerScreen: initState called with contentId: "${widget.contentId}"');
    print('🎬 PlayerScreen: Current time: ${DateTime.now()}');
    print('🎬 PlayerScreen: Widget instance: ${widget.toString()}');

    _animationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    _albumArtAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));

    // Start rotation animation
    _animationController.repeat();

    // Auto-load and play content if contentId is provided (for deep linking)
    if (widget.contentId != null) {
      print('🎬 PlayerScreen: ContentId provided, will auto-load: "${widget.contentId}"');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print('🎬 PlayerScreen: Post-frame callback executing for contentId: "${widget.contentId}"');
        _loadAndPlayContent(widget.contentId!);
      });
    } else {
      print('🎬 PlayerScreen: No contentId provided - this appears to be normal navigation');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Load and automatically play content by ID (for deep linking)
  Future<void> _loadAndPlayContent(String contentId) async {
    print('🎬 PlayerScreen: _loadAndPlayContent called with: "$contentId"');
    try {
      final contentService = context.read<ContentService>();
      final audioService = context.read<AudioService>();

      print('🎬 PlayerScreen: Getting AudioFile by contentId: "$contentId"');
      // Get the AudioFile by contentId
      final audioFile = await contentService.getAudioFileById(contentId);
      print('🎬 PlayerScreen: AudioFile result: ${audioFile?.id ?? 'null'}');
      
      if (audioFile != null) {
        // Add to listen history
        await contentService.addToListenHistory(audioFile);
        
        // Start playing the audio
        await audioService.playAudio(audioFile);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Now playing: ${audioFile.displayTitle}'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Episode not found: $contentId'),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load episode: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Consumer2<AudioService, ContentService>(
        builder: (context, audioService, contentService, child) {
          final currentAudio = audioService.currentAudioFile;

          if (currentAudio == null) {
            return _buildNoAudioState(context);
          }

          return SafeArea(
            child: _showContentScript
                ? _buildExpandedLayout(
                    context, currentAudio, audioService, contentService)
                : _buildCompactLayout(
                    context, currentAudio, audioService, contentService),
          );
        },
      ),
    );
  }

  /// Build header with navigation and options
  Widget _buildHeader(BuildContext context, AudioFile currentAudio) {
    return Padding(
      padding: AppTheme.safeHorizontalPadding,
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.keyboard_arrow_down),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.cardColor.withOpacity(0.5),
              foregroundColor: AppTheme.onSurfaceColor,
            ),
          ),

          // Track source info
          Expanded(
            child: Column(
              children: [
                Text(
                  'NOW PLAYING',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.onSurfaceColor.withOpacity(0.6),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Text(
                  'From Fed to Chain',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // More options button
          IconButton(
            onPressed: () => _showPlayerOptions(context, currentAudio),
            icon: const Icon(Icons.more_vert),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.cardColor.withOpacity(0.5),
              foregroundColor: AppTheme.onSurfaceColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Build album art section with animation
  Widget _buildAlbumArtSection(
      AudioFile currentAudio, AudioService audioService) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated album art
          RotationTransition(
            turns: audioService.isPlaying
                ? _albumArtAnimation
                : const AlwaysStoppedAnimation(0.0),
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                _getAudioIcon(currentAudio),
                size: 120,
                color: AppTheme.onPrimaryColor,
              ),
            ),
          ),

          const SizedBox(height: AppTheme.spacingL),

          // Playback state indicator
          _buildPlaybackStateIndicator(audioService),
        ],
      ),
    );
  }

  /// Build playback state indicator
  Widget _buildPlaybackStateIndicator(AudioService audioService) {
    String stateText;
    Color stateColor;
    IconData stateIcon;

    switch (audioService.playbackState) {
      case PlaybackState.playing:
        stateText = 'Playing';
        stateColor = AppTheme.playingColor;
        stateIcon = Icons.play_arrow;
        break;
      case PlaybackState.paused:
        stateText = 'Paused';
        stateColor = AppTheme.pausedColor;
        stateIcon = Icons.pause;
        break;
      case PlaybackState.loading:
        stateText = 'Loading...';
        stateColor = AppTheme.loadingColor;
        stateIcon = Icons.hourglass_empty;
        break;
      case PlaybackState.error:
        stateText = 'Error';
        stateColor = AppTheme.errorStateColor;
        stateIcon = Icons.error;
        break;
      default:
        stateText = 'Stopped';
        stateColor = AppTheme.onSurfaceColor.withOpacity(0.6);
        stateIcon = Icons.stop;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      decoration: BoxDecoration(
        color: stateColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(
          color: stateColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            stateIcon,
            size: 16,
            color: stateColor,
          ),
          const SizedBox(width: AppTheme.spacingS),
          Text(
            stateText,
            style: AppTheme.bodySmall.copyWith(
              color: stateColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Build track information
  Widget _buildTrackInfo(AudioFile currentAudio) {
    return Padding(
      padding: AppTheme.safeHorizontalPadding,
      child: Column(
        children: [
          // Track title
          Text(
            currentAudio.displayTitle,
            style: AppTheme.headlineMedium,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: AppTheme.spacingS),

          // Track details
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                currentAudio.categoryEmoji,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Text(
                AppTheme.getCategoryDisplayName(currentAudio.category),
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.getCategoryColor(currentAudio.category),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Text(
                currentAudio.languageFlag,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Text(
                AppTheme.getLanguageDisplayName(currentAudio.language),
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.getLanguageColor(currentAudio.language),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build progress section with seek bar
  Widget _buildProgressSection(AudioService audioService) {
    return Padding(
      padding: AppTheme.safeHorizontalPadding,
      child: Column(
        children: [
          // Progress slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4.0,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 8.0,
              ),
              overlayShape: const RoundSliderOverlayShape(
                overlayRadius: 16.0,
              ),
            ),
            child: Slider(
              value: audioService.progress,
              onChanged: (value) {
                final position = Duration(
                  milliseconds:
                      (value * audioService.totalDuration.inMilliseconds)
                          .round(),
                );
                audioService.seekTo(position);
              },
              activeColor: AppTheme.primaryColor,
              inactiveColor: AppTheme.cardColor,
            ),
          ),

          // Time labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                audioService.formattedCurrentPosition,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.onSurfaceColor.withOpacity(0.7),
                ),
              ),
              Text(
                audioService.formattedTotalDuration,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.onSurfaceColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build main playback controls
  Widget _buildMainControls(
      AudioService audioService, ContentService contentService) {
    return Padding(
      padding: AppTheme.safeHorizontalPadding,
      child: AudioControls(
        isPlaying: audioService.isPlaying,
        isLoading: audioService.isLoading,
        hasError: audioService.hasError,
        onPlayPause: () => audioService.togglePlayPause(),
        onNext: () => audioService.skipToNextEpisode(),
        onPrevious: () => audioService.skipToPreviousEpisode(),
        onSkipForward: () => audioService.skipForward(),
        onSkipBackward: () => audioService.skipBackward(),
        size: AudioControlsSize.large,
      ),
    );
  }

  /// Build additional controls
  Widget _buildAdditionalControls(
      AudioService audioService, ContentService contentService) {
    return Padding(
      padding: AppTheme.safeHorizontalPadding,
      child: Column(
        children: [
          // Speed selector (show when toggled)
          if (_showSpeedSelector) ...[
            PlaybackSpeedSelector(
              currentSpeed: audioService.playbackSpeed,
              onSpeedChanged: (speed) {
                audioService.setPlaybackSpeed(speed);
                setState(() {
                  _showSpeedSelector = false;
                });
              },
            ),
            const SizedBox(height: AppTheme.spacingM),
          ],

          // Control buttons row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Content script toggle
              IconButton(
                onPressed: () {
                  setState(() {
                    _showContentScript = !_showContentScript;
                  });
                },
                icon: const Icon(Icons.article),
                style: IconButton.styleFrom(
                  backgroundColor: _showContentScript
                      ? AppTheme.primaryColor.withOpacity(0.2)
                      : AppTheme.cardColor.withOpacity(0.5),
                  foregroundColor: _showContentScript
                      ? AppTheme.primaryColor
                      : AppTheme.onSurfaceColor,
                ),
              ),

              // Playback speed
              IconButton(
                onPressed: () {
                  setState(() {
                    _showSpeedSelector = !_showSpeedSelector;
                  });
                },
                icon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.speed),
                    const SizedBox(width: AppTheme.spacingXS),
                    Text(
                      '${audioService.playbackSpeed}x',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.onSurfaceColor,
                      ),
                    ),
                  ],
                ),
                style: IconButton.styleFrom(
                  backgroundColor: _showSpeedSelector
                      ? AppTheme.primaryColor.withOpacity(0.2)
                      : AppTheme.cardColor.withOpacity(0.5),
                  foregroundColor: _showSpeedSelector
                      ? AppTheme.primaryColor
                      : AppTheme.onSurfaceColor,
                ),
              ),

              // Repeat toggle
              IconButton(
                onPressed: () {
                  audioService.setRepeatEnabled(!audioService.repeatEnabled);
                },
                icon: Icon(
                  audioService.repeatEnabled ? Icons.repeat_one : Icons.repeat,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: audioService.repeatEnabled
                      ? AppTheme.primaryColor.withOpacity(0.2)
                      : AppTheme.cardColor.withOpacity(0.5),
                  foregroundColor: audioService.repeatEnabled
                      ? AppTheme.primaryColor
                      : AppTheme.onSurfaceColor,
                ),
              ),

              // Autoplay toggle
              IconButton(
                onPressed: () {
                  audioService
                      .setAutoplayEnabled(!audioService.autoplayEnabled);
                },
                icon: Icon(
                  audioService.autoplayEnabled
                      ? Icons.skip_next
                      : Icons.playlist_play,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: audioService.autoplayEnabled
                      ? AppTheme.primaryColor.withOpacity(0.2)
                      : AppTheme.cardColor.withOpacity(0.5),
                  foregroundColor: audioService.autoplayEnabled
                      ? AppTheme.primaryColor
                      : AppTheme.onSurfaceColor,
                ),
              ),

              // Share
              IconButton(
                onPressed: () =>
                    _shareCurrentContent(context, audioService, contentService),
                icon: const Icon(Icons.share),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.cardColor.withOpacity(0.5),
                  foregroundColor: AppTheme.onSurfaceColor,
                ),
              ),

              // Add to playlist
              IconButton(
                onPressed: () {
                  final currentAudio = audioService.currentAudioFile;
                  if (currentAudio != null) {
                    context
                        .read<ContentService>()
                        .addToCurrentPlaylist(currentAudio);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Added "${currentAudio.displayTitle}" to playlist'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.playlist_add),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.cardColor.withOpacity(0.5),
                  foregroundColor: AppTheme.onSurfaceColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build compact layout (without content script)
  Widget _buildCompactLayout(BuildContext context, AudioFile currentAudio,
      AudioService audioService, ContentService contentService) {
    return Column(
      children: [
        // Header with back button and options
        _buildHeader(context, currentAudio),

        // Album art and visualizer
        Expanded(
          flex: 3,
          child: _buildAlbumArtSection(currentAudio, audioService),
        ),

        // Track info
        _buildTrackInfo(currentAudio),

        // Content script display (collapsed)
        ContentDisplay(
          currentAudioFile: currentAudio,
          contentService: contentService,
          isExpanded: _showContentScript,
          onToggleExpanded: () {
            setState(() {
              _showContentScript = !_showContentScript;
            });
          },
        ),

        // Progress bar
        _buildProgressSection(audioService),

        // Main controls
        _buildMainControls(audioService, contentService),

        // Additional controls
        _buildAdditionalControls(audioService, contentService),

        const SizedBox(height: AppTheme.spacingL),
      ],
    );
  }

  /// Build expanded layout (with content script)
  Widget _buildExpandedLayout(BuildContext context, AudioFile currentAudio,
      AudioService audioService, ContentService contentService) {
    return CustomScrollView(
      slivers: [
        // Fixed header
        SliverToBoxAdapter(
          child: _buildHeader(context, currentAudio),
        ),

        // Compact album art
        SliverToBoxAdapter(
          child: SizedBox(
            height: 200,
            child: Center(
              child: RotationTransition(
                turns: audioService.isPlaying
                    ? _albumArtAnimation
                    : const AlwaysStoppedAnimation(0.0),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getAudioIcon(currentAudio),
                    size: 60,
                    color: AppTheme.onPrimaryColor,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Track info
        SliverToBoxAdapter(
          child: _buildTrackInfo(currentAudio),
        ),

        // Content script display (expanded)
        SliverToBoxAdapter(
          child: ContentDisplay(
            currentAudioFile: currentAudio,
            contentService: contentService,
            isExpanded: _showContentScript,
            onToggleExpanded: () {
              setState(() {
                _showContentScript = !_showContentScript;
              });
            },
          ),
        ),

        // Bottom controls (sticky)
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Progress bar
              _buildProgressSection(audioService),

              // Main controls
              _buildMainControls(audioService, contentService),

              // Additional controls
              _buildAdditionalControls(audioService, contentService),

              const SizedBox(height: AppTheme.spacingL),
            ],
          ),
        ),
      ],
    );
  }

  /// Build no audio state
  Widget _buildNoAudioState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_off,
            size: 80,
            color: AppTheme.onSurfaceColor.withOpacity(0.3),
          ),
          const SizedBox(height: AppTheme.spacingL),
          const Text(
            'No audio playing',
            style: AppTheme.headlineMedium,
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            'Select an episode to start listening',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.onSurfaceColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: AppTheme.spacingXL),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Browse Episodes'),
          ),
        ],
      ),
    );
  }

  /// Get appropriate icon for audio content
  IconData _getAudioIcon(AudioFile audioFile) {
    switch (audioFile.category) {
      case 'daily-news':
        return Icons.newspaper;
      case 'ethereum':
        return Icons.currency_bitcoin;
      case 'macro':
        return Icons.trending_up;
      case 'startup':
        return Icons.rocket_launch;
      case 'ai':
        return Icons.smart_toy;
      case 'defi':
        return Icons.account_balance;
      default:
        return Icons.headphones;
    }
  }

  /// Share current content using social hook and deep linking
  Future<void> _shareCurrentContent(BuildContext context,
      AudioService audioService, ContentService contentService) async {
    final currentAudio = audioService.currentAudioFile;
    if (currentAudio == null) return;

    try {
      // Get content to access social_hook
      final content = await contentService.getContentForAudioFile(currentAudio);

      // Generate deep links
      final deepLink = DeepLinkService.generateContentLink(currentAudio.id);
      final webLink = DeepLinkService.generateContentLink(currentAudio.id,
          useCustomScheme: false);

      String shareText;
      if (content?.socialHook != null &&
          content!.socialHook!.trim().isNotEmpty) {
        // Use social hook from content and append deep links
        shareText = '${content.socialHook!}\n\n'
            '🎧 Listen now: $deepLink\n'
            '🌐 Web: $webLink';
      } else {
        // Fallback to default sharing message with links
        shareText =
            '🎧 Listening to "${currentAudio.displayTitle}" from From Fed to Chain\n\n'
            '${currentAudio.categoryEmoji} ${AppTheme.getCategoryDisplayName(currentAudio.category)} | '
            '${currentAudio.languageFlag} ${AppTheme.getLanguageDisplayName(currentAudio.language)}\n\n'
            '🎧 Listen: $deepLink\n'
            '🌐 Web: $webLink\n\n'
            '#FromFedToChain #Crypto #Podcast';
      }

      // Use share_plus to share directly with system share sheet
      final result = await Share.shareWithResult(
        shareText,
        subject: 'From Fed to Chain - ${currentAudio.displayTitle}',
      );

      // Show feedback based on share result
      if (context.mounted) {
        if (result.status == ShareResultStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Episode shared successfully! 🚀'),
              duration: Duration(seconds: 2),
            ),
          );
        } else if (result.status == ShareResultStatus.dismissed) {
          // User dismissed - no feedback needed
        } else {
          // Fallback: show text in dialog for manual copy
          await _showShareDialog(context, shareText);
        }
      }
    } catch (e) {
      // Show error if content loading fails or sharing fails
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share episode: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Show share dialog as fallback when system share fails
  Future<void> _showShareDialog(BuildContext context, String shareText) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.share),
            SizedBox(width: 8),
            Text('Share Episode'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Copy this text to share:'),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                shareText,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () async {
              // Copy to clipboard using share_plus
              await Share.share(shareText);
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Share text ready!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            icon: const Icon(Icons.share),
            label: const Text('Share'),
          ),
        ],
      ),
    );
  }

  /// Show player options bottom sheet
  void _showPlayerOptions(BuildContext context, AudioFile currentAudio) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusL),
        ),
      ),
      builder: (context) => _buildPlayerOptionsSheet(currentAudio),
    );
  }

  /// Build player options bottom sheet
  Widget _buildPlayerOptionsSheet(AudioFile currentAudio) {
    return Padding(
      padding: AppTheme.safePadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.onSurfaceColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const SizedBox(height: AppTheme.spacingL),

          // Audio details
          Text(
            'Audio Details',
            style: AppTheme.headlineSmall,
          ),

          const SizedBox(height: AppTheme.spacingM),

          Text(
            currentAudio.displayTitle,
            style: AppTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppTheme.spacingM),
        ],
      ),
    );
  }
}
