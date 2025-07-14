import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/content_service.dart';
import '../themes/app_theme.dart';

class FilterBar extends StatelessWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ContentService>(
      builder: (context, contentService, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              // Search bar
              _buildSearchBar(context, contentService),
              
              const SizedBox(height: 12),
              
              // Filter chips row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Language filters
                    _buildFilterChip(
                      context,
                      label: 'All Languages',
                      isSelected: contentService.selectedLanguage == null,
                      onTap: () => contentService.setLanguageFilter(null),
                    ),
                    
                    ...contentService.availableLanguages.map((language) =>
                      _buildFilterChip(
                        context,
                        label: _getLanguageDisplayName(language),
                        isSelected: contentService.selectedLanguage == language,
                        onTap: () => contentService.setLanguageFilter(language),
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Category filters
                    _buildFilterChip(
                      context,
                      label: 'All Categories',
                      isSelected: contentService.selectedCategory == null,
                      onTap: () => contentService.setCategoryFilter(null),
                    ),
                    
                    ...contentService.availableCategories.map((category) =>
                      _buildFilterChip(
                        context,
                        label: _getCategoryDisplayName(category),
                        isSelected: contentService.selectedCategory == category,
                        onTap: () => contentService.setCategoryFilter(category),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Clear filters button (only show if filters are active)
              if (contentService.selectedLanguage != null ||
                  contentService.selectedCategory != null ||
                  contentService.searchQuery.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: contentService.clearFilters,
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('Clear Filters'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.textTertiary,
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(BuildContext context, ContentService contentService) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.textTertiary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: TextField(
        onChanged: contentService.setSearchQuery,
        decoration: InputDecoration(
          hintText: 'Search audio content...',
          prefixIcon: Icon(
            Icons.search,
            color: AppTheme.textTertiary.withOpacity(0.7),
          ),
          suffixIcon: contentService.searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: AppTheme.textTertiary.withOpacity(0.7),
                  ),
                  onPressed: () => contentService.setSearchQuery(''),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          hintStyle: TextStyle(
            color: AppTheme.textTertiary.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected ? AppTheme.primaryGradient : null,
            color: isSelected ? null : AppTheme.surface.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : AppTheme.textTertiary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  String _getLanguageDisplayName(String language) {
    switch (language) {
      case 'zh-TW':
        return '繁體中文';
      case 'en-US':
        return 'English';
      case 'ja-JP':
        return '日本語';
      default:
        return language;
    }
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'daily-news':
        return 'Daily News';
      case 'ethereum':
        return 'Ethereum';
      case 'macro':
        return 'Macro';
      case 'startup':
        return 'Startup';
      default:
        return category.toUpperCase();
    }
  }
}