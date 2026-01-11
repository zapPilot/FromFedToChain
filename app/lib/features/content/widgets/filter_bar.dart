import 'package:flutter/material.dart';
import 'package:from_fed_to_chain_app/core/theme/app_theme.dart';
import 'package:from_fed_to_chain_app/core/config/api_config.dart';

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
        _buildFilterSection(
          title: 'Language',
          items: ApiConfig.supportedLanguages,
          selectedItem: selectedLanguage,
          onSelected: onLanguageChanged,
          labelBuilder: (lang) =>
              '${ApiConfig.getLanguageFlag(lang)} ${ApiConfig.getLanguageDisplayName(lang)}',
          colorBuilder: (lang) => AppTheme.getLanguageColor(lang),
        ),

        const SizedBox(height: AppTheme.spacingS),

        // Category filter
        _buildFilterSection(
          title: 'Category',
          items: ['all', ...ApiConfig.supportedCategories],
          selectedItem: selectedCategory,
          onSelected: onCategoryChanged,
          labelBuilder: (cat) {
            if (cat == 'all') return 'All';
            return '${ApiConfig.getCategoryEmoji(cat)} ${ApiConfig.getCategoryDisplayName(cat)}';
          },
          colorBuilder: (cat) => cat == 'all'
              ? AppTheme.onSurfaceColor.withValues(alpha: 0.6)
              : AppTheme.getCategoryColor(cat),
        ),
      ],
    );
  }

  /// Build a generic filter section with a title and horizontal scrollable chips
  Widget _buildFilterSection({
    required String title,
    required List<String> items,
    required String selectedItem,
    required ValueChanged<String> onSelected,
    required String Function(String) labelBuilder,
    required Color Function(String) colorBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.onSurfaceColor.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppTheme.spacingS),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(right: AppTheme.spacingS),
                child: _buildFilterChip(
                  label: labelBuilder(item),
                  value: item,
                  isSelected: selectedItem == item,
                  onTap: () => onSelected(item),
                  color: colorBuilder(item),
                ),
              );
            }).toList(),
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
            color:
                isSelected ? color : AppTheme.cardColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            border: Border.all(
              color: isSelected
                  ? color
                  : AppTheme.onSurfaceColor.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
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
}
