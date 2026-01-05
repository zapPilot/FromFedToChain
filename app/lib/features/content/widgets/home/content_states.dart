import 'package:flutter/material.dart';
import 'package:from_fed_to_chain_app/core/theme/app_theme.dart';

/// Loading state widget for content
class ContentLoadingState extends StatelessWidget {
  final String message;
  final String subMessage;

  const ContentLoadingState({
    super.key,
    this.message = 'Loading episodes...',
    this.subMessage = 'This may take a few moments',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
          const SizedBox(height: AppTheme.spacingL),
          Text(
            message,
            style: AppTheme.titleMedium,
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            subMessage,
            style: AppTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Error state widget for content
class ContentErrorState extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const ContentErrorState({
    super.key,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppTheme.safePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: AppTheme.spacingL),
            const Text(
              'Something went wrong',
              style: AppTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              errorMessage,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.onSurfaceColor.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXL),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state widget for content
class ContentEmptyState extends StatelessWidget {
  final String searchQuery;
  final VoidCallback onClearFilters;
  final VoidCallback onRefresh;

  const ContentEmptyState({
    super.key,
    required this.searchQuery,
    required this.onClearFilters,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppTheme.safePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.headphones_outlined,
              size: 80,
              color: AppTheme.onSurfaceColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppTheme.spacingL),
            const Text(
              'No episodes found',
              style: AppTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              searchQuery.isNotEmpty
                  ? 'Try different search terms or filters'
                  : 'Check your internet connection and try again',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.onSurfaceColor.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXL),
            if (searchQuery.isNotEmpty)
              TextButton(
                onPressed: onClearFilters,
                child: const Text('Clear filters'),
              )
            else
              ElevatedButton(
                onPressed: onRefresh,
                child: const Text('Refresh'),
              ),
          ],
        ),
      ),
    );
  }
}
