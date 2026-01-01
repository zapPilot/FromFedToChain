import 'package:flutter/material.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_content.dart';
import 'package:from_fed_to_chain_app/features/content/services/content_service.dart';

/// Widget for displaying content/script of currently playing audio
/// Useful for language learning to read along with audio
class ContentDisplay extends StatefulWidget {
  final AudioFile? currentAudioFile;
  final ContentService contentService;
  final bool isExpanded;
  final VoidCallback? onToggleExpanded;

  const ContentDisplay({
    super.key,
    required this.currentAudioFile,
    required this.contentService,
    this.isExpanded = false,
    this.onToggleExpanded,
  });

  @override
  State<ContentDisplay> createState() => _ContentDisplayState();
}

class _ContentDisplayState extends State<ContentDisplay> {
  AudioContent? _currentContent;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  @override
  void didUpdateWidget(ContentDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Load content when audio file changes
    if (oldWidget.currentAudioFile?.id != widget.currentAudioFile?.id ||
        oldWidget.currentAudioFile?.language !=
            widget.currentAudioFile?.language) {
      _loadContent();
    }
  }

  Future<void> _loadContent() async {
    if (widget.currentAudioFile == null) {
      setState(() {
        _currentContent = null;
        _isLoading = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rawResult = await widget.contentService
          .getContentForAudioFile(widget.currentAudioFile!);

      if (mounted) {
        setState(() {
          _currentContent = rawResult;
          _isLoading = false;
          _error = rawResult == null ? 'Content not available' : null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentContent = null;
          _isLoading = false;
          _error = 'Failed to load content: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentAudioFile == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          if (widget.isExpanded) _buildContent(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return InkWell(
      onTap: widget.onToggleExpanded,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.article_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Content Script',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  Text(
                    'Read along with the audio content',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                widget.isExpanded ? Icons.expand_less : Icons.expand_more,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          _buildContentBody(),
        ],
      ),
    );
  }

  Widget _buildContentBody() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'Failed to load content',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  _error!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadContent,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      );
    }

    if (_currentContent == null) {
      return Center(
        child: Column(
          children: [
            Icon(
              Icons.article_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No content available',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Content text
        if (_currentContent!.description != null &&
            _currentContent!.description!.trim().isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: SelectableText(
              _currentContent!.description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                    fontSize: 16,
                  ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Text(
              'Content text not available for this episode.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                    fontStyle: FontStyle.italic,
                  ),
              textAlign: TextAlign.center,
            ),
          ),

        const SizedBox(height: 16),

        // References section
        if (_currentContent!.references.isNotEmpty) ...[
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showReferences(context),
                  icon: const Icon(Icons.link),
                  label: Text(
                      'References (${_currentContent!.references.length})'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.secondaryContainer,
                    foregroundColor:
                        Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'No references available',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Show references in a dialog
  void _showReferences(BuildContext context) {
    if (_currentContent == null || _currentContent!.references.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.link),
            const SizedBox(width: 8),
            const Text('References'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _currentContent!.references.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final reference = _currentContent!.references[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: SelectableText(
                  reference,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                contentPadding: EdgeInsets.zero,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
