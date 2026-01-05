import 'package:flutter/material.dart';
import 'package:from_fed_to_chain_app/core/theme/app_theme.dart';

class SortSelector extends StatelessWidget {
  final String sortOrder;
  final ValueChanged<String> onSortChanged;

  const SortSelector({
    super.key,
    required this.sortOrder,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: AppTheme.safeHorizontalPadding,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      child: Row(
        children: [
          Icon(
            Icons.sort,
            size: 16,
            color: AppTheme.onSurfaceColor.withValues(alpha: 0.6),
          ),
          const SizedBox(width: AppTheme.spacingS),
          Text(
            'Sort by:',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.onSurfaceColor.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: sortOrder,
                isDense: true,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.onSurfaceColor,
                  fontWeight: FontWeight.w500,
                ),
                dropdownColor: AppTheme.surfaceColor,
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: AppTheme.onSurfaceColor.withValues(alpha: 0.6),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'newest',
                    child: Text('Newest First'),
                  ),
                  DropdownMenuItem(
                    value: 'oldest',
                    child: Text('Oldest First'),
                  ),
                  DropdownMenuItem(
                    value: 'alphabetical',
                    child: Text('A-Z'),
                  ),
                ],
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    onSortChanged(newValue);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
