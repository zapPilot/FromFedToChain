import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:from_fed_to_chain_app/core/theme/app_theme.dart';
import 'package:from_fed_to_chain_app/features/content/services/content_service.dart';

class HomeHeader extends StatelessWidget {
  final VoidCallback onSearchToggle;
  final bool isSearchVisible;

  const HomeHeader({
    super.key,
    required this.onSearchToggle,
    required this.isSearchVisible,
  });

  @override
  Widget build(BuildContext context) {
    // We access ContentService via Provider, assuming it's up in the tree
    final contentService = context.watch<ContentService>();

    return Container(
      padding: AppTheme.safeHorizontalPadding,
      child: Row(
        children: [
          // App title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'From Fed to Chain',
                  style: AppTheme.headlineMedium,
                ),
                const SizedBox(height: AppTheme.spacingXS),
                _buildStats(contentService),
              ],
            ),
          ),

          // Search toggle button
          IconButton(
            onPressed: onSearchToggle,
            icon: Icon(
              isSearchVisible ? Icons.close : Icons.search,
              color: AppTheme.onSurfaceColor,
            ),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.cardColor.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
            ),
          ),

          const SizedBox(width: AppTheme.spacingS),

          // Refresh button
          IconButton(
            onPressed: contentService.isLoading
                ? null
                : () => contentService.refresh(),
            icon: contentService.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryColor,
                      ),
                    ),
                  )
                : const Icon(Icons.refresh),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.cardColor.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(ContentService service) {
    final stats = service.getStatistics();
    final totalEpisodes = stats['totalEpisodes'] as int;
    final filteredEpisodes = stats['filteredEpisodes'] as int;

    return Text(
      filteredEpisodes == totalEpisodes
          ? '$totalEpisodes episodes'
          : '$filteredEpisodes of $totalEpisodes episodes',
      style: AppTheme.bodySmall.copyWith(
        color: AppTheme.onSurfaceColor.withValues(alpha: 0.6),
      ),
    );
  }
}
