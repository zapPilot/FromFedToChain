import 'author.dart';
import 'episode.dart';

class Course {
  final String id;
  final String title;
  final String description;
  final String? coverImage;
  final String authorId;
  final Author? author; // Populated when needed
  final String category;
  final String language;
  final List<Episode> episodes;
  final int totalDuration; // in seconds
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;
  final int subscriberCount;
  final double rating;
  final int ratingCount;
  final String status; // 'published', 'draft', 'archived'
  final String? difficulty; // 'beginner', 'intermediate', 'advanced'
  final bool isFeatured;
  final bool isPremium;
  final String? price;

  Course({
    required this.id,
    required this.title,
    required this.description,
    this.coverImage,
    required this.authorId,
    this.author,
    required this.category,
    required this.language,
    required this.episodes,
    required this.totalDuration,
    required this.createdAt,
    required this.updatedAt,
    required this.tags,
    required this.subscriberCount,
    required this.rating,
    required this.ratingCount,
    required this.status,
    this.difficulty,
    this.isFeatured = false,
    this.isPremium = false,
    this.price,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      coverImage: json['cover_image'],
      authorId: json['author_id'] ?? '',
      author: json['author'] != null ? Author.fromJson(json['author']) : null,
      category: json['category'] ?? '',
      language: json['language'] ?? '',
      episodes: (json['episodes'] as List? ?? [])
          .map((episode) => Episode.fromJson(episode))
          .toList(),
      totalDuration: json['total_duration'] ?? 0,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      tags: List<String>.from(json['tags'] ?? []),
      subscriberCount: json['subscriber_count'] ?? 0,
      rating: (json['rating'] ?? 0.0).toDouble(),
      ratingCount: json['rating_count'] ?? 0,
      status: json['status'] ?? 'published',
      difficulty: json['difficulty'],
      isFeatured: json['is_featured'] ?? false,
      isPremium: json['is_premium'] ?? false,
      price: json['price'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'cover_image': coverImage,
      'author_id': authorId,
      'author': author?.toJson(),
      'category': category,
      'language': language,
      'episodes': episodes.map((episode) => episode.toJson()).toList(),
      'total_duration': totalDuration,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'tags': tags,
      'subscriber_count': subscriberCount,
      'rating': rating,
      'rating_count': ratingCount,
      'status': status,
      'difficulty': difficulty,
      'is_featured': isFeatured,
      'is_premium': isPremium,
      'price': price,
    };
  }

  // Helper methods
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

  String get formattedDuration {
    if (totalDuration < 3600) {
      final minutes = totalDuration ~/ 60;
      return '${minutes}min';
    } else {
      final hours = totalDuration ~/ 3600;
      final minutes = (totalDuration % 3600) ~/ 60;
      return '${hours}h ${minutes}min';
    }
  }

  String get episodeCountText {
    return '${episodes.length} episodes';
  }

  String get ratingText {
    if (ratingCount == 0) return 'No ratings';
    return '${rating.toStringAsFixed(1)} (${ratingCount})';
  }

  String get subscriberCountText {
    if (subscriberCount < 1000) {
      return subscriberCount.toString();
    } else if (subscriberCount < 1000000) {
      return '${(subscriberCount / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(subscriberCount / 1000000).toStringAsFixed(1)}M';
    }
  }

  String get difficultyDisplayName {
    switch (difficulty) {
      case 'beginner':
        return 'Beginner';
      case 'intermediate':
        return 'Intermediate';
      case 'advanced':
        return 'Advanced';
      default:
        return 'All levels';
    }
  }

  bool get isPublished => status == 'published';
  bool get hasCoverImage => coverImage != null && coverImage!.isNotEmpty;
  bool get hasAuthor => author != null;
  bool get hasEpisodes => episodes.isNotEmpty;
}