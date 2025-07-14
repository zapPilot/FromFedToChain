class AudioContent {
  final String id;
  final String title;
  final String category;
  final String language;
  final String date;
  final String? audioFile;
  final String? socialHook;
  final List<String> references;
  final String content;
  final String status;
  final DateTime updatedAt;

  AudioContent({
    required this.id,
    required this.title,
    required this.category,
    required this.language,
    required this.date,
    this.audioFile,
    this.socialHook,
    required this.references,
    required this.content,
    required this.status,
    required this.updatedAt,
  });

  factory AudioContent.fromJson(Map<String, dynamic> json) {
    return AudioContent(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      language: json['language'] ?? '',
      date: json['date'] ?? '',
      audioFile: json['audio_file'],
      socialHook: json['social_hook'],
      references: List<String>.from(json['references'] ?? []),
      content: json['content'] ?? '',
      status: json['status'] ?? '',
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'language': language,
      'date': date,
      'audio_file': audioFile,
      'social_hook': socialHook,
      'references': references,
      'content': content,
      'status': status,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper methods
  String get displayDate {
    final parsed = DateTime.tryParse(date);
    if (parsed != null) {
      return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
    }
    return date;
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

  bool get hasAudio => audioFile != null && audioFile!.isNotEmpty;
}