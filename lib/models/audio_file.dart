import 'package:flutter/foundation.dart';

class AudioFile {
  final String id;
  final String language;
  final String category;
  final String fileName;
  final int sizeInBytes;
  final DateTime created;
  final Duration? duration;
  final String sourceUrl; // The only URL needed for playback
  final String? title; // Optional localized title from content metadata
  final bool hasContent; // Whether content metadata is available

  AudioFile({
    required this.id,
    required this.language,
    required this.category,
    required this.fileName,
    required this.sizeInBytes,
    required this.created,
    this.duration,
    required this.sourceUrl,
    this.title,
    this.hasContent = false,
  });

  factory AudioFile.fromFileInfo({
    required String id,
    required String language,
    required String category,
    required String fileName,
    required int sizeInBytes,
    required DateTime created,
    Duration? duration,
    required String sourceUrl,
    String? title,
    bool hasContent = false,
  }) {
    return AudioFile(
      id: id,
      language: language,
      category: category,
      fileName: fileName,
      sizeInBytes: sizeInBytes,
      created: created,
      duration: duration,
      sourceUrl: sourceUrl,
      title: title,
      hasContent: hasContent,
    );
  }

  /// Factory constructor for API response format
  /// Expected format: {"id": "episode-id", "playlistUrl": "https://...", "title": "...", "hasContent": true}
  factory AudioFile.fromApiResponse(
    Map<String, dynamic> json,
    String language,
    String category,
  ) {
    final id = json['id'] as String;
    final playlistUrl = json['playlistUrl'] as String; // New API format uses 'playlistUrl'
    final title = json['title'] as String?; // Enhanced: localized title from content metadata
    final hasContent = json['hasContent'] as bool? ?? false; // Whether content metadata was found
    
    DateTime createdDate = DateTime.now();
    try {
      // Try to parse date from content metadata first, then fallback to ID parsing
      if (json['date'] != null) {
        createdDate = DateTime.parse(json['date'] as String);
      } else {
        final datePart = id.split('-').take(3).join('-');
        createdDate = DateTime.parse(datePart);
      }
    } catch (e) {
      print('Warning: Could not parse date from ID: $id');
    }
    
    return AudioFile(
      id: id,
      language: language,
      category: category,
      fileName: '$id.m3u8',
      sizeInBytes: 0,
      created: createdDate,
      duration: null,
      sourceUrl: playlistUrl,
      title: title,
      hasContent: hasContent,
    );
  }

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
    if (kIsWeb) {
      return sourceUrl.isNotEmpty;
    }
    return sourceUrl.isNotEmpty;
  }

  String get playbackUrl => sourceUrl;

  /// Get the display title - uses localized title if available, otherwise generates from ID
  String get displayTitle {
    if (title != null && title!.isNotEmpty) {
      return title!;
    }
    
    // Fallback: generate title from ID
    final parts = id.split('-');
    if (parts.length > 3) {
      // Skip date parts (first 3) and capitalize words
      return parts.skip(3).map((word) => 
        word[0].toUpperCase() + word.substring(1)
      ).join(' ');
    }
    return id; // Ultimate fallback to original ID
  }
}