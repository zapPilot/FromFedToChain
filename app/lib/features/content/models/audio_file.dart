import 'package:equatable/equatable.dart';
import 'package:from_fed_to_chain_app/core/config/api_config.dart';
import 'package:from_fed_to_chain_app/core/utils/duration_utils.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_content.dart';

/// Represents a streamable audio file with metadata and URL information
class AudioFile extends Equatable {
  final String id;
  final String title;
  final String language;
  final String category;
  final String streamingUrl;
  final String path;
  final Duration? duration;
  final int? fileSizeBytes;
  final DateTime lastModified;
  final AudioContent? metadata;

  const AudioFile({
    required this.id,
    required this.title,
    required this.language,
    required this.category,
    required this.streamingUrl,
    required this.path,
    this.duration,
    this.fileSizeBytes,
    required this.lastModified,
    this.metadata,
  });

  /// Create AudioFile from streaming API response
  factory AudioFile.fromApiResponse(Map<String, dynamic> json) {
    // Use ID directly from API response - it contains the proper slug format
    final id = json['id'] as String;
    final path = json['path'] as String;

    // Use language and category directly from API response
    final language = json['language'] as String? ?? 'unknown';
    final category = json['category'] as String? ?? 'unknown';

    return AudioFile(
      id: id,
      title: json['title'] as String? ?? _generateTitleFromId(id),
      language: language,
      category: category,
      streamingUrl: json['streaming_url'] as String,
      path: path,
      duration: json['duration'] != null
          ? Duration(seconds: json['duration'] as int)
          : null,
      fileSizeBytes: json['size'] as int?,
      lastModified: json['last_modified'] != null
          ? DateTime.parse(json['last_modified'] as String)
          : DateTime.now(),
    );
  }

  /// Create AudioFile from content metadata and streaming path
  factory AudioFile.fromContent(AudioContent content, String streamingPath) {
    return AudioFile(
      id: content.id,
      title: content.title,
      language: content.language,
      category: content.category,
      streamingUrl: _buildStreamingUrl(streamingPath),
      path: streamingPath,
      duration: content.duration,
      lastModified: content.updatedAt,
      metadata: content,
    );
  }

  /// Generate a readable title from ID
  static String _generateTitleFromId(String id) {
    return id
        .replaceAll('-', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? word[0].toUpperCase() + word.substring(1).toLowerCase()
            : word)
        .join(' ');
  }

  /// Build streaming URL from path
  static String _buildStreamingUrl(String path) {
    // This would use ApiConfig.getStreamUrl(path) in real implementation
    return 'https://signed-url.davidtnfsh.workers.dev/proxy/$path';
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'language': language,
      'category': category,
      'streaming_url': streamingUrl,
      'path': path,
      'duration': duration?.inSeconds,
      'size': fileSizeBytes,
      'last_modified': lastModified.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  AudioFile copyWith({
    String? id,
    String? title,
    String? language,
    String? category,
    String? streamingUrl,
    String? path,
    Duration? duration,
    int? fileSizeBytes,
    DateTime? lastModified,
    AudioContent? metadata,
  }) {
    return AudioFile(
      id: id ?? this.id,
      title: title ?? this.title,
      language: language ?? this.language,
      category: category ?? this.category,
      streamingUrl: streamingUrl ?? this.streamingUrl,
      path: path ?? this.path,
      duration: duration ?? this.duration,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      lastModified: lastModified ?? this.lastModified,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Display title (fallback logic)
  String get displayTitle {
    if (title.trim().isEmpty) {
      return _generateTitleFromId(id);
    }
    return title;
  }

  /// Source URL for audio playback (alias for [streamingUrl]).
  ///
  /// This is the primary URL used by the player to stream content.
  String get sourceUrl => streamingUrl;

  /// Check if this is an HLS/M3U8 stream.
  ///
  /// Returns `true` if the path ends with `.m3u8`.
  bool get isHlsStream => path.endsWith('.m3u8');

  /// Check if this is a direct audio file (wav, mp3, m4a).
  ///
  /// Returns `true` if the path ends with a supported audio extension.
  bool get isDirectAudio =>
      path.endsWith('.wav') || path.endsWith('.mp3') || path.endsWith('.m4a');

  /// Formatted file size string (e.g., "1.5 MB").
  ///
  /// Returns "Unknown" if [fileSizeBytes] is null.
  String get formattedFileSize {
    if (fileSizeBytes == null) return 'Unknown';

    const suffixes = ['B', 'KB', 'MB', 'GB'];
    double size = fileSizeBytes!.toDouble();
    int suffixIndex = 0;

    while (size >= 1024 && suffixIndex < suffixes.length - 1) {
      size /= 1024;
      suffixIndex++;
    }

    // Don't show decimal for bytes, show decimal for KB and above
    String formattedSize = suffixIndex == 0 && size % 1 == 0
        ? size.toStringAsFixed(0)
        : size.toStringAsFixed(1);
    return '$formattedSize ${suffixes[suffixIndex]}';
  }

  /// Formatted duration string (e.g., "05:30").
  ///
  /// Returns "--:--" if [duration] is null.
  String get formattedDuration {
    if (duration == null) return '--:--';
    return DurationUtils.formatDuration(duration!);
  }

  /// Get category emoji icon.
  ///
  /// Delegates to [ApiConfig.getCategoryEmoji].
  String get categoryEmoji => ApiConfig.getCategoryEmoji(category);

  /// Get language flag emoji.
  ///
  /// Delegates to [ApiConfig.getLanguageFlag].
  String get languageFlag => ApiConfig.getLanguageFlag(language);

  /// Parse publish date from ID (format: YYYY-MM-DD-title).
  ///
  /// Returns the publish date if parseable from [id], otherwise falls back to [lastModified].
  DateTime get publishDate {
    try {
      // ID format: "2025-07-05-blockchain-private-equity-tokenization"
      // Extract first 10 characters: "2025-07-05"
      if (id.length >= 10) {
        final datePart = id.substring(0, 10);
        // Check if it matches YYYY-MM-DD pattern
        if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(datePart)) {
          return DateTime.parse(datePart);
        }
      }
    } catch (e) {
      // If parsing fails, fall back to lastModified
    }
    return lastModified;
  }

  @override
  List<Object?> get props => [
        id,
        title,
        language,
        category,
        streamingUrl,
        path,
        duration,
        fileSizeBytes,
        lastModified,
      ];

  @override
  String toString() {
    return 'AudioFile(id: $id, title: $title, language: $language, category: $category, url: $streamingUrl)';
  }
}
