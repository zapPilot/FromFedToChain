class Episode {
  final String id;
  final String courseId;
  final String title;
  final String? description;
  final String audioUrl;
  final int duration; // in seconds
  final int episodeNumber;
  final DateTime publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;
  final String? transcript;
  final String? notes;
  final bool isPreview; // Free preview episode
  final String status; // 'published', 'draft', 'processing'

  Episode({
    required this.id,
    required this.courseId,
    required this.title,
    this.description,
    required this.audioUrl,
    required this.duration,
    required this.episodeNumber,
    required this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.tags,
    this.transcript,
    this.notes,
    this.isPreview = false,
    required this.status,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['id'] ?? '',
      courseId: json['course_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      audioUrl: json['audio_url'] ?? '',
      duration: json['duration'] ?? 0,
      episodeNumber: json['episode_number'] ?? 0,
      publishedAt: DateTime.parse(json['published_at'] ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      tags: List<String>.from(json['tags'] ?? []),
      transcript: json['transcript'],
      notes: json['notes'],
      isPreview: json['is_preview'] ?? false,
      status: json['status'] ?? 'published',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'title': title,
      'description': description,
      'audio_url': audioUrl,
      'duration': duration,
      'episode_number': episodeNumber,
      'published_at': publishedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'tags': tags,
      'transcript': transcript,
      'notes': notes,
      'is_preview': isPreview,
      'status': status,
    };
  }

  // Helper methods
  String get formattedDuration {
    if (duration < 3600) {
      final minutes = duration ~/ 60;
      final seconds = duration % 60;
      return '${minutes}:${seconds.toString().padLeft(2, '0')}';
    } else {
      final hours = duration ~/ 3600;
      final minutes = (duration % 3600) ~/ 60;
      final seconds = duration % 60;
      return '${hours}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  String get episodeNumberText => 'Episode $episodeNumber';
  
  String get publishedDateText {
    final now = DateTime.now();
    final difference = now.difference(publishedAt);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays ~/ 7} weeks ago';
    } else {
      return '${publishedAt.year}-${publishedAt.month.toString().padLeft(2, '0')}-${publishedAt.day.toString().padLeft(2, '0')}';
    }
  }

  bool get isPublished => status == 'published';
  bool get hasTranscript => transcript != null && transcript!.isNotEmpty;
  bool get hasNotes => notes != null && notes!.isNotEmpty;
  bool get hasDescription => description != null && description!.isNotEmpty;
}