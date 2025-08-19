import 'package:flutter/material.dart';
import '../themes/app_theme.dart';
import '../config/api_config.dart';

/// Filter bar for selecting language and category
class FilterBar extends StatelessWidget {
  final String selectedLanguage;
  final String selectedCategory;
  final ValueChanged<String> onLanguageChanged;
  final ValueChanged<String> onCategoryChanged;

  const FilterBar({
    super.key,
    required this.selectedLanguage,
    required this.selectedCategory,
    required this.onLanguageChanged,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Language filter
        _buildLanguageFilter(),

        const SizedBox(height: AppTheme.spacingS),

        // Category filter
        _buildCategoryFilter(),
      ],
    );
  }

  /// Build language filter chips
  Widget _buildLanguageFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Language',
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.onSurfaceColor.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppTheme.spacingS),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Individual language options
              ...ApiConfig.supportedLanguages.map((language) {
                return Padding(
                  padding: const EdgeInsets.only(right: AppTheme.spacingS),
                  child: _buildFilterChip(
                    label: _getLanguageDisplay(language),
                    value: language,
                    isSelected: selectedLanguage == language,
                    onTap: () => onLanguageChanged(language),
                    color: AppTheme.getLanguageColor(language),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  /// Build category filter chips
  Widget _buildCategoryFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.onSurfaceColor.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppTheme.spacingS),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // All categories option
              _buildFilterChip(
                label: 'All',
                value: 'all',
                isSelected: selectedCategory == 'all',
                onTap: () => onCategoryChanged('all'),
                color: AppTheme.onSurfaceColor.withOpacity(0.6),
              ),

              const SizedBox(width: AppTheme.spacingS),

              // Individual category options
              ...ApiConfig.supportedCategories.map((category) {
                return Padding(
                  padding: const EdgeInsets.only(right: AppTheme.spacingS),
                  child: _buildFilterChip(
                    label: _getCategoryDisplay(category),
                    value: category,
                    isSelected: selectedCategory == category,
                    onTap: () => onCategoryChanged(category),
                    color: AppTheme.getCategoryColor(category),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  /// Build individual filter chip
  Widget _buildFilterChip({
    required String label,
    required String value,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        child: AnimatedContainer(
          duration: AppTheme.animationFast,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: AppTheme.spacingS,
          ),
          decoration: BoxDecoration(
            color: isSelected ? color : AppTheme.cardColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            border: Border.all(
              color:
                  isSelected ? color : AppTheme.onSurfaceColor.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: isSelected ? Colors.white : AppTheme.onSurfaceColor,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  /// Get language display text with flag
  String _getLanguageDisplay(String language) {
    final flag = _getLanguageFlag(language);
    final name = ApiConfig.getLanguageDisplayName(language);
    return '$flag $name';
  }

  /// Get category display text with emoji
  String _getCategoryDisplay(String category) {
    final emoji = _getCategoryEmoji(category);
    final name = ApiConfig.getCategoryDisplayName(category);
    return '$emoji $name';
  }

  /// Get language flag emoji
  String _getLanguageFlag(String language) {
    switch (language) {
      case 'zh-TW':
        return '🇹🇼';
      case 'en-US':
        return '🇺🇸';
      case 'ja-JP':
        return '🇯🇵';
      default:
        return '🌐';
    }
  }

  /// Get category emoji
  String _getCategoryEmoji(String category) {
    switch (category) {
      case 'daily-news':
        return '📰';
      case 'ethereum':
        return '⚡';
      case 'macro':
        return '📊';
      case 'startup':
        return '🚀';
      case 'ai':
        return '🤖';
      case 'defi':
        return '💎';
      default:
        return '🎧';
    }
  }
}
