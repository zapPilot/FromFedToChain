class UserProgress {
  final String id;
  final String userId;
  final String courseId;
  final String? currentEpisodeId;
  final int currentPosition; // Current position in seconds
  final double progressPercentage; // 0.0 to 1.0
  final DateTime lastAccessedAt;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int totalTimeSpent; // in seconds
  final List<String> completedEpisodes;
  final bool isCompleted;

  UserProgress({
    required this.id,
    required this.userId,
    required this.courseId,
    this.currentEpisodeId,
    required this.currentPosition,
    required this.progressPercentage,
    required this.lastAccessedAt,
    required this.startedAt,
    this.completedAt,
    required this.totalTimeSpent,
    required this.completedEpisodes,
    required this.isCompleted,
  });

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      courseId: json['course_id'] ?? '',
      currentEpisodeId: json['current_episode_id'],
      currentPosition: json['current_position'] ?? 0,
      progressPercentage: (json['progress_percentage'] ?? 0.0).toDouble(),
      lastAccessedAt: DateTime.parse(json['last_accessed_at'] ?? DateTime.now().toIso8601String()),
      startedAt: DateTime.parse(json['started_at'] ?? DateTime.now().toIso8601String()),
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at'])
          : null,
      totalTimeSpent: json['total_time_spent'] ?? 0,
      completedEpisodes: List<String>.from(json['completed_episodes'] ?? []),
      isCompleted: json['is_completed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'course_id': courseId,
      'current_episode_id': currentEpisodeId,
      'current_position': currentPosition,
      'progress_percentage': progressPercentage,
      'last_accessed_at': lastAccessedAt.toIso8601String(),
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'total_time_spent': totalTimeSpent,
      'completed_episodes': completedEpisodes,
      'is_completed': isCompleted,
    };
  }

  // Helper methods
  String get progressText {
    if (isCompleted) return 'Completed';
    if (progressPercentage == 0.0) return 'Not started';
    return '${(progressPercentage * 100).round()}% complete';
  }

  String get timeSpentText {
    if (totalTimeSpent < 3600) {
      final minutes = totalTimeSpent ~/ 60;
      return '${minutes}min';
    } else {
      final hours = totalTimeSpent ~/ 3600;
      final minutes = (totalTimeSpent % 3600) ~/ 60;
      return '${hours}h ${minutes}min';
    }
  }

  String get lastAccessedText {
    final now = DateTime.now();
    final difference = now.difference(lastAccessedAt);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${lastAccessedAt.year}-${lastAccessedAt.month.toString().padLeft(2, '0')}-${lastAccessedAt.day.toString().padLeft(2, '0')}';
    }
  }

  bool get hasCurrentEpisode => currentEpisodeId != null;
  bool get hasStarted => progressPercentage > 0.0;
  bool get hasCompletedEpisodes => completedEpisodes.isNotEmpty;
  
  bool isEpisodeCompleted(String episodeId) => completedEpisodes.contains(episodeId);
  
  int get completedEpisodesCount => completedEpisodes.length;
}