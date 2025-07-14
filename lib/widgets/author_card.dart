import 'package:flutter/material.dart';
import '../themes/app_theme.dart';

class AuthorCard extends StatelessWidget {
  final String authorName;
  final String authorBio;
  final int subscriberCount;
  final bool isSubscribed;
  final VoidCallback? onTap;
  final VoidCallback? onSubscribe;

  const AuthorCard({
    super.key,
    required this.authorName,
    required this.authorBio,
    required this.subscriberCount,
    required this.isSubscribed,
    this.onTap,
    this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.textTertiary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Author Avatar
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(authorName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authorName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatSubscriberCount(subscriberCount),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Author Bio
            Text(
              authorBio,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 12),
            
            // Subscribe Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSubscribe,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSubscribed 
                      ? AppTheme.surface 
                      : AppTheme.purplePrimary,
                  foregroundColor: isSubscribed 
                      ? AppTheme.textSecondary 
                      : Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isSubscribed 
                          ? AppTheme.textTertiary.withOpacity(0.3)
                          : AppTheme.purplePrimary,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isSubscribed ? Icons.check : Icons.add,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isSubscribed ? 'Subscribed' : 'Subscribe',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    
    final words = name.split(' ');
    if (words.length == 1) {
      return words[0][0].toUpperCase();
    }
    
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  String _formatSubscriberCount(int count) {
    if (count == 0) return 'No subscribers';
    if (count == 1) return '1 subscriber';
    
    if (count < 1000) {
      return '$count subscribers';
    } else if (count < 1000000) {
      final k = (count / 1000).toStringAsFixed(1);
      return '${k}K subscribers';
    } else {
      final m = (count / 1000000).toStringAsFixed(1);
      return '${m}M subscribers';
    }
  }
}