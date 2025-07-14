import 'user.dart';

class Comment {
  final String id;
  final String courseId;
  final String userId;
  final User? user; // Populated when needed
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int likeCount;
  final bool isLiked; // Whether current user liked this comment
  final bool isAuthorReply; // Whether this is a reply from the course author
  final String? parentId; // For simple replies (optional)
  final String? timestampReference; // Reference to specific time in audio (e.g., "15:30")
  final String status; // 'published', 'pending', 'hidden'

  Comment({
    required this.id,
    required this.courseId,
    required this.userId,
    this.user,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.likeCount,
    this.isLiked = false,
    this.isAuthorReply = false,
    this.parentId,
    this.timestampReference,
    required this.status,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? '',
      courseId: json['course_id'] ?? '',
      userId: json['user_id'] ?? '',
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      content: json['content'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      likeCount: json['like_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
      isAuthorReply: json['is_author_reply'] ?? false,
      parentId: json['parent_id'],
      timestampReference: json['timestamp_reference'],
      status: json['status'] ?? 'published',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'user_id': userId,
      'user': user?.toJson(),
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'like_count': likeCount,
      'is_liked': isLiked,
      'is_author_reply': isAuthorReply,
      'parent_id': parentId,
      'timestamp_reference': timestampReference,
      'status': status,
    };
  }

  // Helper methods
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays ~/ 7}w ago';
    } else {
      return '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
    }
  }

  String get likeCountText {
    if (likeCount == 0) return '';
    if (likeCount < 1000) {
      return likeCount.toString();
    } else if (likeCount < 1000000) {
      return '${(likeCount / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(likeCount / 1000000).toStringAsFixed(1)}M';
    }
  }

  bool get isReply => parentId != null;
  bool get hasTimestampReference => timestampReference != null && timestampReference!.isNotEmpty;
  bool get isPublished => status == 'published';
  bool get hasUser => user != null;
  
  String get displayContent {
    if (hasTimestampReference) {
      return '@$timestampReference $content';
    }
    return content;
  }
}