import 'dart:io';

class AudioFile {
  final String id;
  final String language;
  final String category;
  final String filePath;
  final String fileName;
  final int sizeInBytes;
  final DateTime created;
  final Duration? duration;

  AudioFile({
    required this.id,
    required this.language,
    required this.category,
    required this.filePath,
    required this.fileName,
    required this.sizeInBytes,
    required this.created,
    this.duration,
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
    return File(filePath).existsSync();
  }
}