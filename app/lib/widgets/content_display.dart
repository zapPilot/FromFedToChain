import 'package:flutter/material.dart';
import '../models/audio_file.dart';
import '../models/audio_content.dart';
import '../services/content_service.dart';

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
        oldWidget.currentAudioFile?.language != widget.currentAudioFile?.language) {
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
      final content = await widget.contentService.getContentForAudioFile(widget.currentAudioFile!);
      
      if (mounted) {
        setState(() {
          _currentContent = content;
          _isLoading = false;
          _error = content == null ? 'Content not available' : null;
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
                  if (_currentContent != null)
                    Text(
                      _currentContent!.displayTitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else if (widget.currentAudioFile != null)
                    Text(
                      widget.currentAudioFile!.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadContent,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentContent == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No script available for this episode',
            style: TextStyle(
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Metadata row
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _buildMetadataChip(
              icon: Icons.language,
              label: _currentContent!.languageFlag,
            ),
            _buildMetadataChip(
              icon: Icons.category,
              label: '${_currentContent!.categoryEmoji} ${_currentContent!.category}',
            ),
            _buildMetadataChip(
              icon: Icons.calendar_today,
              label: _currentContent!.formattedDate,
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Content text
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
            _currentContent!.description ?? 'No content available',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.6,
              fontSize: 16,
            ),
          ),
        ),
        
        // References if available
        if (_currentContent!.references.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'References',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          ...(_currentContent!.references.map((ref) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: Theme.of(context).textTheme.bodySmall),
                Expanded(
                  child: SelectableText(
                    ref,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          ))),
        ],
      ],
    );
  }

  Widget _buildMetadataChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}