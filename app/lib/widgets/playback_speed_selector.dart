import 'package:flutter/material.dart';
import '../themes/app_theme.dart';

/// Playback speed selection widget
class PlaybackSpeedSelector extends StatelessWidget {
  final double currentSpeed;
  final ValueChanged<double> onSpeedChanged;

  const PlaybackSpeedSelector({
    super.key,
    required this.currentSpeed,
    required this.onSpeedChanged,
  });

  static const List<double> _speedOptions = [
    0.5,
    0.75,
    1.0,
    1.25,
    1.5,
    1.75,
    2.0,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
          child: Text(
            'Playback Speed',
            style: AppTheme.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(height: AppTheme.spacingM),

        // Speed options
        Wrap(
          spacing: AppTheme.spacingS,
          runSpacing: AppTheme.spacingS,
          children: _speedOptions.map((speed) {
            final isSelected = (speed - currentSpeed).abs() < 0.01;

            return _buildSpeedOption(
              speed: speed,
              isSelected: isSelected,
              onTap: () => onSpeedChanged(speed),
            );
          }).toList(),
        ),

        const SizedBox(height: AppTheme.spacingL),

        // Custom speed slider
        _buildCustomSpeedSlider(context),
      ],
    );
  }

  /// Build individual speed option chip
  Widget _buildSpeedOption({
    required double speed,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        child: Semantics(
          label: 'Playback speed ${speed}x${isSelected ? ', selected' : ''}',
          button: true,
          selected: isSelected,
          child: Container(
            // Ensure minimum 48px height for accessibility compliance
            constraints: const BoxConstraints(minHeight: 48.0),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingM,
              vertical: AppTheme.spacingM, // Increased from spacingS
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryColor
                  : AppTheme.cardColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              border: isSelected
                  ? null
                  : Border.all(
                      color: AppTheme.onSurfaceColor.withOpacity(0.2),
                      width: 1,
                    ),
            ),
            child: Text(
              '${speed}x',
              style: AppTheme.bodyMedium.copyWith(
                color: isSelected
                    ? AppTheme.onPrimaryColor
                    : AppTheme.onSurfaceColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build custom speed slider for fine-tuning
  Widget _buildCustomSpeedSlider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Custom Speed',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.onSurfaceColor.withOpacity(0.7),
            ),
          ),

          const SizedBox(height: AppTheme.spacingS),

          Row(
            children: [
              Text(
                '0.5x',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.onSurfaceColor.withOpacity(0.6),
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4.0,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8.0,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 16.0,
                    ),
                    activeTrackColor: AppTheme.primaryColor,
                    inactiveTrackColor: AppTheme.cardColor,
                    thumbColor: AppTheme.primaryColor,
                    overlayColor: AppTheme.primaryColor.withOpacity(0.2),
                  ),
                  child: Slider(
                    value: currentSpeed,
                    min: 0.5,
                    max: 2.0,
                    divisions: 30, // 0.05 increments
                    onChanged: onSpeedChanged,
                  ),
                ),
              ),
              Text(
                '2.0x',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.onSurfaceColor.withOpacity(0.6),
                ),
              ),
            ],
          ),

          // Current speed display
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingM,
                vertical: AppTheme.spacingS,
              ),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                '${currentSpeed.toStringAsFixed(2)}x',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
