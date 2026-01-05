import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:from_fed_to_chain_app/core/theme/app_theme.dart';
import 'package:from_fed_to_chain_app/features/audio/services/audio_player_service.dart';
import 'package:from_fed_to_chain_app/features/content/services/content_service.dart';
import 'package:from_fed_to_chain_app/core/navigation/deep_link_service.dart';

class ShareHelper {
  /// Share current content using social hook and deep linking
  static Future<void> shareCurrentContent(BuildContext context,
      AudioPlayerService audioService, ContentService contentService) async {
    final currentAudio = audioService.currentAudioFile;
    if (currentAudio == null) return;

    try {
      // Get content to access social_hook
      final content = await contentService.getContentForAudioFile(currentAudio);

      // Generate deep links with language parameter
      final deepLink = DeepLinkService.generateContentLink(currentAudio.id,
          language: currentAudio.language);
      final webLink = DeepLinkService.generateContentLink(currentAudio.id,
          language: currentAudio.language, useCustomScheme: false);

      String shareText;
      if (content?.socialHook != null &&
          content!.socialHook!.trim().isNotEmpty) {
        // Use social hook from content and append deep links
        shareText = '${content.socialHook!}\n\n'
            '🎧 Listen now: $deepLink';
      } else {
        // Fallback to default sharing message with links
        shareText =
            '🎧 Listening to "${currentAudio.displayTitle}" from From Fed to Chain\n\n'
            '${currentAudio.categoryEmoji} ${AppTheme.getCategoryDisplayName(currentAudio.category)} | '
            '${currentAudio.languageFlag} ${AppTheme.getLanguageDisplayName(currentAudio.language)}\n\n'
            '🎧 Listen: $deepLink\n'
            '🌐 Web: $webLink\n\n'
            '#FromFedToChain #Crypto #Podcast';
      }

      // Use share_plus to share directly with system share sheet
      final result = await Share.shareWithResult(
        shareText,
        subject: 'From Fed to Chain - ${currentAudio.displayTitle}',
      );

      // Show feedback based on share result
      if (context.mounted) {
        if (result.status == ShareResultStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Episode shared successfully! 🚀'),
              duration: Duration(seconds: 2),
            ),
          );
        } else if (result.status == ShareResultStatus.dismissed) {
          // User dismissed - no feedback needed
        } else {
          // Fallback: show text in dialog for manual copy
          await _showShareDialog(context, shareText);
        }
      }
    } catch (e) {
      // Show error if content loading fails or sharing fails
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share episode: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Show share dialog as fallback when system share fails
  static Future<void> _showShareDialog(
      BuildContext context, String shareText) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.share),
            SizedBox(width: 8),
            Text('Share Episode'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Copy this text to share:'),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                shareText,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () async {
              // Copy to clipboard using share_plus
              await Share.share(shareText);
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Share text ready!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            icon: const Icon(Icons.share),
            label: const Text('Share'),
          ),
        ],
      ),
    );
  }
}
