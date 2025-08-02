import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../themes/app_theme.dart';
import '../services/audio_service.dart';
import '../services/content_service.dart';
import '../models/audio_file.dart';
import '../widgets/audio_controls.dart';
import '../widgets/playback_speed_selector.dart';
import '../widgets/content_display.dart';

/// Full-screen audio player with enhanced controls
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
                ? _buildExpandedLayout(context, currentAudio, audioService, contentService)
                : _buildCompactLayout(context, currentAudio, audioService, contentService),
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
  Widget _buildAdditionalControls(AudioService audioService) {
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
                  audioService.setAutoplayEnabled(!audioService.autoplayEnabled);
                },
                icon: Icon(
                  audioService.autoplayEnabled ? Icons.skip_next : Icons.playlist_play,
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
                onPressed: () {
                  // TODO: Implement sharing
                },
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
        _buildAdditionalControls(audioService),

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
              _buildAdditionalControls(audioService),

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
