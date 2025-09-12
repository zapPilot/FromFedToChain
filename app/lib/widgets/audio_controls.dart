import 'package:flutter/material.dart';
import '../themes/app_theme.dart';

/// Control size variants for different contexts
enum AudioControlsSize {
  small,
  medium,
  large,
}

/// Comprehensive audio playback controls widget
class AudioControls extends StatelessWidget {
  final bool isPlaying;
  final bool isLoading;
  final bool hasError;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onSkipForward;
  final VoidCallback onSkipBackward;
  final AudioControlsSize size;

  const AudioControls({
    super.key,
    required this.isPlaying,
    required this.isLoading,
    required this.hasError,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrevious,
    required this.onSkipForward,
    required this.onSkipBackward,
    this.size = AudioControlsSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    final buttonSizes = _getButtonSizes();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Previous episode
        _buildControlButton(
          icon: Icons.skip_previous,
          onPressed: onPrevious,
          size: buttonSizes.secondary,
          tooltip: 'Previous episode',
        ),

        // Skip backward
        _buildControlButton(
          icon: Icons.replay_10,
          onPressed: onSkipBackward,
          size: buttonSizes.secondary,
          tooltip: 'Skip back 10s',
        ),

        // Main play/pause button
        _buildMainPlayButton(buttonSizes.primary),

        // Skip forward
        _buildControlButton(
          icon: Icons.forward_30,
          onPressed: onSkipForward,
          size: buttonSizes.secondary,
          tooltip: 'Skip forward 30s',
        ),

        // Next episode
        _buildControlButton(
          icon: Icons.skip_next,
          onPressed: onNext,
          size: buttonSizes.secondary,
          tooltip: 'Next episode',
        ),
      ],
    );
  }

  /// Build main play/pause button with loading state
  Widget _buildMainPlayButton(double buttonSize) {
    return Container(
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: hasError ? onPlayPause : (isLoading ? null : onPlayPause),
          borderRadius: BorderRadius.circular(buttonSize / 2),
          child: Semantics(
            label: hasError
                ? 'Retry playback'
                : (isLoading ? 'Loading' : (isPlaying ? 'Pause' : 'Play')),
            button: true,
            child: Center(
              child: _buildMainButtonContent(buttonSize),
            ),
          ),
        ),
      ),
    );
  }

  /// Build main button content (play/pause/loading/error)
  Widget _buildMainButtonContent(double buttonSize) {
    final iconSize = buttonSize * 0.4;

    if (isLoading) {
      return SizedBox(
        width: iconSize,
        height: iconSize,
        child: const CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(
            AppTheme.onPrimaryColor,
          ),
        ),
      );
    }

    if (hasError) {
      return Icon(
        Icons.refresh,
        size: iconSize,
        color: AppTheme.onPrimaryColor,
      );
    }

    return Icon(
      isPlaying ? Icons.pause : Icons.play_arrow,
      size: iconSize,
      color: AppTheme.onPrimaryColor,
    );
  }

  /// Build secondary control button
  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required double size,
    required String tooltip,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: Semantics(
        label: tooltip, // Add semantic label for accessibility
        button: true,
        child: IconButton(
          onPressed: onPressed,
          tooltip: tooltip, // IconButton's built-in tooltip
          icon: Icon(
            icon,
            size: size * 0.5,
            semanticLabel: tooltip, // Add semantic label to icon
          ),
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.cardColor.withOpacity(0.6),
            foregroundColor: AppTheme.onSurfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(size / 2),
            ),
          ),
        ),
      ),
    );
  }

  /// Get button sizes based on control size variant
  _ButtonSizes _getButtonSizes() {
    switch (size) {
      case AudioControlsSize.small:
        return _ButtonSizes(
            primary: 48, secondary: 48); // Increased to meet accessibility
      case AudioControlsSize.medium:
        return _ButtonSizes(primary: 64, secondary: 48);
      case AudioControlsSize.large:
        return _ButtonSizes(primary: 80, secondary: 56);
    }
  }
}

/// Button size configuration
class _ButtonSizes {
  final double primary;
  final double secondary;

  const _ButtonSizes({
    required this.primary,
    required this.secondary,
  });
}
