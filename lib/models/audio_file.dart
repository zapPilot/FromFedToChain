import 'package:flutter/foundation.dart';
import '../services/streaming_api_service.dart';

class AudioFile {
  final String id;
  final String language;
  final String category;
  final String filePath;
  final String fileName;
  final int sizeInBytes;
  final DateTime created;
  final Duration? duration;
  final String? streamingPath; // Path for streaming API
  final String? directSignedUrl; // Pre-signed URL from API response

  AudioFile({
    required this.id,
    required this.language,
    required this.category,
    required this.filePath,
    required this.fileName,
    required this.sizeInBytes,
    required this.created,
    this.duration,
    this.streamingPath,
    this.directSignedUrl,
  });

  factory AudioFile.fromFileInfo({
    required String id,
    required String language,
    required String category,
    required String filePath,
    required String fileName,
    required int sizeInBytes,
    required DateTime created,
    Duration? duration,
    String? streamingPath,
    String? directSignedUrl,
  }) {
    return AudioFile(
      id: id,
      language: language,
      category: category,
      filePath: filePath,
      fileName: fileName,
      sizeInBytes: sizeInBytes,
      created: created,
      duration: duration,
      streamingPath: streamingPath,
      directSignedUrl: directSignedUrl,
    );
  }

  /// Factory constructor for API response format
  /// Expected format: {"id": "episode-id", "path": "audio/zh-TW/startup/episode-id/playlist.m3u8", "signedUrl": "https://..."}
  factory AudioFile.fromApiResponse(
    Map<String, dynamic> json,
    String language,
    String category,
  ) {
    final id = json['id'] as String;
    final path = json['path'] as String;
    final signedUrl = json['signedUrl'] as String?; // Extract pre-signed URL
    
    // Parse date from ID (format: YYYY-MM-DD-title)
    DateTime createdDate = DateTime.now();
    try {
      final datePart = id.split('-').take(3).join('-');
      createdDate = DateTime.parse(datePart);
    } catch (e) {
      // If parsing fails, use current date
      print('Warning: Could not parse date from ID: $id');
    }
    
    return AudioFile(
      id: id,
      language: language,
      category: category,
      filePath: '', // Not used for streaming
      fileName: '$id.m3u8',
      sizeInBytes: 0, // Unknown for streaming files
      created: createdDate,
      duration: null, // Will be determined during playback
      streamingPath: path,
      directSignedUrl: signedUrl, // Use pre-signed URL if available
    );
  }

  // Helper methods
  String get sizeFormatted {
    if (sizeInBytes < 1024) {
      return '${sizeInBytes}B';
    } else if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }

  String get durationFormatted {
    if (duration == null) return 'Unknown';
    
    final minutes = duration!.inMinutes;
    final seconds = duration!.inSeconds.remainder(60);
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  String get displayDate {
    return '${created.year}-${created.month.toString().padLeft(2, '0')}-${created.day.toString().padLeft(2, '0')}';
  }

  String get categoryDisplayName {
    switch (category) {
      case 'daily-news':
        return 'Daily News';
      case 'ethereum':
        return 'Ethereum';
      case 'macro':
        return 'Macro';
      case 'startup':
        return 'Startup';
      case 'ai':
        return 'AI';
      case 'defi':
        return 'DeFi';
      default:
        return category.toUpperCase();
    }
  }

  String get languageDisplayName {
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

  bool get exists {
    // For web platform, we can't check file existence using File API
    if (kIsWeb) {
      // For streaming files, assume they exist if we have a streaming path
      return isStreamingFile || filePath.isNotEmpty;
    }
    
    // For mobile platforms, assume files exist (avoiding dart:io dependency)
    // In a full implementation, you would use conditional imports here
    return filePath.isNotEmpty;
  }

  /// Get the streaming URL for this audio file
  /// Uses pre-signed URL if available, otherwise constructs from path
  String? get streamingUrl {
    // Prefer pre-signed URL from API response (better performance)
    if (directSignedUrl != null && directSignedUrl!.isNotEmpty) {
      return directSignedUrl!;
    }
    
    // Fallback to constructing URL from path (backwards compatibility)
    if (streamingPath == null) return null;
    return StreamingApiService.getStreamingUrl(streamingPath!);
  }

  /// Check if this is a streaming file (from API) or local file
  bool get isStreamingFile {
    return (directSignedUrl != null && directSignedUrl!.isNotEmpty) ||
           (streamingPath != null && streamingPath!.isNotEmpty);
  }

  /// Check if using optimized pre-signed URL (better performance)
  bool get isUsingDirectSignedUrl {
    return directSignedUrl != null && directSignedUrl!.isNotEmpty;
  }

  /// Get the appropriate URL/path for audio playback
  String get playbackUrl {
    if (isStreamingFile) {
      return streamingUrl!;
    }
    return filePath;
  }
}