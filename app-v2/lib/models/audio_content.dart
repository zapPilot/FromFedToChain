import 'package:equatable/equatable.dart';

/// Represents audio content metadata from the content management system
class AudioContent extends Equatable {
  final String id;
  final String title;
  final String language;
  final String category;
  final DateTime date;
  final String status;
  final String? description;
  final List<String> references;
  final String? socialHook;
  final String? streamingUrl;
  final Duration? duration;
  final DateTime updatedAt;

  const AudioContent({
    required this.id,
    required this.title,
    required this.language,
    required this.category,
    required this.date,
    required this.status,
    this.description,
    this.references = const [],
    this.socialHook,
    this.streamingUrl,
    this.duration,
    required this.updatedAt,
  });

  /// Create AudioContent from JSON (API response)
  factory AudioContent.fromJson(Map<String, dynamic> json) {
    return AudioContent(
      id: (json['id'] ?? '') as String,
      title: (json['title'] ?? 'Untitled') as String,
      language: (json['language'] ?? 'unknown') as String,
      category: (json['category'] ?? 'unknown') as String,
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : DateTime.now(),
      status: (json['status'] ?? 'draft') as String,
      description: json['content'] as String?,
      references: (json['references'] as List?)
              ?.map((ref) => ref.toString())
              .toList() ??
          [],
      socialHook: json['social_hook'] as String?,
      streamingUrl: json['streaming_url'] as String?,
      duration: json['duration'] != null
          ? Duration(seconds: json['duration'] as int)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'language': language,
      'category': category,
      'date': date.toUtc().toIso8601String(),
      'status': status,
      'content': description,
      'references': references,
      'social_hook': socialHook,
      'streaming_url': streamingUrl,
      'duration': duration?.inSeconds,
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  AudioContent copyWith({
    String? id,
    String? title,
    String? language,
    String? category,
    DateTime? date,
    String? status,
    String? description,
    List<String>? references,
    String? socialHook,
    String? streamingUrl,
    Duration? duration,
    DateTime? updatedAt,
  }) {
    return AudioContent(
      id: id ?? this.id,
      title: title ?? this.title,
      language: language ?? this.language,
      category: category ?? this.category,
      date: date ?? this.date,
      status: status ?? this.status,
      description: description ?? this.description,
      references: references ?? this.references,
      socialHook: socialHook ?? this.socialHook,
      streamingUrl: streamingUrl ?? this.streamingUrl,
      duration: duration ?? this.duration,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Display title (fallback to ID if title is empty)
  String get displayTitle {
    if (title.trim().isEmpty) {
      return id.replaceAll('-', ' ').toUpperCase();
    }
    return title;
  }

  /// Formatted date string
  String get formattedDate {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Check if content has audio available
  /// Audio is available from 'wav' status onwards in the pipeline
  /// Pipeline: draft → reviewed → translated → wav → m3u8 → cloudflare → content → social
  bool get hasAudio {
    switch (status) {
      case 'wav':
      case 'm3u8':
      case 'cloudflare':
      case 'content':
      case 'social':
        return true;
      default:
        return false;
    }
  }

  /// Get category emoji
  String get categoryEmoji {
    switch (category) {
      case 'daily-news':
        return '📰';
      case 'ethereum':
        return '⚡';
      case 'macro':
        return '📊';
      case 'startup':
        return '🚀';
      case 'ai':
        return '🤖';
      case 'defi':
        return '💎';
      default:
        return '🎧';
    }
  }

  /// Get language flag emoji
  String get languageFlag {
    switch (language) {
      case 'zh-TW':
        return '🇹🇼';
      case 'en-US':
        return '🇺🇸';
      case 'ja-JP':
        return '🇯🇵';
      default:
        return '🌐';
    }
  }

  @override
  List<Object?> get props => [
        id,
        title,
        language,
        category,
        date,
        status,
        description,
        references,
        socialHook,
        streamingUrl,
        duration,
        updatedAt,
      ];

  @override
  String toString() {
    return 'AudioContent(id: $id, title: $title, language: $language, category: $category)';
  }
}
