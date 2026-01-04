import 'package:equatable/equatable.dart';
import 'package:from_fed_to_chain_app/core/config/api_config.dart';

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
    this.duration,
    required this.updatedAt,
  });

  /// Create AudioContent from JSON (API response)
  factory AudioContent.fromJson(Map<String, dynamic> json) {
    return AudioContent(
      id: json['id'] as String,
      title: json['title'] as String,
      language: json['language'] as String,
      category: json['category'] as String,
      date: DateTime.parse(json['date'] as String),
      status: json['status'] as String,
      description: json['content'] as String?,
      references: (json['references'] as List?)
              ?.map((ref) => ref.toString())
              .toList() ??
          [],
      socialHook: json['social_hook'] as String?,
      duration: json['duration'] != null
          ? Duration(seconds: json['duration'] as int)
          : null,
      updatedAt: DateTime.parse(json['updated_at'] as String),
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
  String get categoryEmoji => ApiConfig.getCategoryEmoji(category);

  /// Get language flag emoji
  String get languageFlag => ApiConfig.getLanguageFlag(language);

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
        duration,
        updatedAt,
      ];

  @override
  String toString() {
    return 'AudioContent(id: $id, title: $title, language: $language, category: $category)';
  }
}
