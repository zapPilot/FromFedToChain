class User {
  final String id;
  final String email;
  final String name;
  final String? displayName;
  final String? profileImage;
  final String? bio;
  final List<String> subscribedAuthors;
  final List<String> favoritesCourses;
  final List<String> completedCourses;
  final Map<String, double> courseProgress; // courseId -> progress (0.0 to 1.0)
  final List<String> interests; // ['crypto', 'macro', 'startup']
  final String preferredLanguage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastActiveAt;
  final bool isEmailVerified;
  final bool isPremium;
  final int totalListeningTime; // in seconds
  final int coursesCompleted;
  final int commentsCount;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.displayName,
    this.profileImage,
    this.bio,
    required this.subscribedAuthors,
    required this.favoritesCourses,
    required this.completedCourses,
    required this.courseProgress,
    required this.interests,
    required this.preferredLanguage,
    required this.createdAt,
    required this.updatedAt,
    this.lastActiveAt,
    this.isEmailVerified = false,
    this.isPremium = false,
    this.totalListeningTime = 0,
    this.coursesCompleted = 0,
    this.commentsCount = 0,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      displayName: json['display_name'],
      profileImage: json['profile_image'],
      bio: json['bio'],
      subscribedAuthors: List<String>.from(json['subscribed_authors'] ?? []),
      favoritesCourses: List<String>.from(json['favorites_courses'] ?? []),
      completedCourses: List<String>.from(json['completed_courses'] ?? []),
      courseProgress: Map<String, double>.from(json['course_progress'] ?? {}),
      interests: List<String>.from(json['interests'] ?? []),
      preferredLanguage: json['preferred_language'] ?? 'en-US',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      lastActiveAt: json['last_active_at'] != null 
          ? DateTime.parse(json['last_active_at'])
          : null,
      isEmailVerified: json['is_email_verified'] ?? false,
      isPremium: json['is_premium'] ?? false,
      totalListeningTime: json['total_listening_time'] ?? 0,
      coursesCompleted: json['courses_completed'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'display_name': displayName,
      'profile_image': profileImage,
      'bio': bio,
      'subscribed_authors': subscribedAuthors,
      'favorites_courses': favoritesCourses,
      'completed_courses': completedCourses,
      'course_progress': courseProgress,
      'interests': interests,
      'preferred_language': preferredLanguage,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_active_at': lastActiveAt?.toIso8601String(),
      'is_email_verified': isEmailVerified,
      'is_premium': isPremium,
      'total_listening_time': totalListeningTime,
      'courses_completed': coursesCompleted,
      'comments_count': commentsCount,
    };
  }

  // Helper methods
  String get effectiveDisplayName => displayName ?? name;
  
  String get initials {
    final words = effectiveDisplayName.split(' ');
    if (words.length >= 2) {
      return (words[0][0] + words[1][0]).toUpperCase();
    } else {
      return effectiveDisplayName.length >= 2 
          ? effectiveDisplayName.substring(0, 2).toUpperCase()
          : effectiveDisplayName.toUpperCase();
    }
  }

  String get memberSince {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays < 30) {
      return 'Member since ${difference.inDays} days ago';
    } else if (difference.inDays < 365) {
      return 'Member since ${difference.inDays ~/ 30} months ago';
    } else {
      return 'Member since ${createdAt.year}';
    }
  }

  String get listeningTimeText {
    if (totalListeningTime < 3600) {
      final minutes = totalListeningTime ~/ 60;
      return '${minutes}min';
    } else {
      final hours = totalListeningTime ~/ 3600;
      return '${hours}h';
    }
  }

  String get interestsText {
    return interests.map((interest) {
      switch (interest) {
        case 'daily-news':
          return 'Daily News';
        case 'ethereum':
          return 'Ethereum';
        case 'macro':
          return 'Macro';
        case 'startup':
          return 'Startup';
        default:
          return interest.toUpperCase();
      }
    }).join(', ');
  }

  String get preferredLanguageText {
    switch (preferredLanguage) {
      case 'zh-TW':
        return '繁體中文';
      case 'en-US':
        return 'English';
      case 'ja-JP':
        return '日本語';
      default:
        return preferredLanguage;
    }
  }

  bool get hasProfileImage => profileImage != null && profileImage!.isNotEmpty;
  bool get hasBio => bio != null && bio!.isNotEmpty;
  bool get hasSubscriptions => subscribedAuthors.isNotEmpty;
  bool get hasFavorites => favoritesCourses.isNotEmpty;
  bool get hasCompletedCourses => completedCourses.isNotEmpty;
  
  bool isSubscribedTo(String authorId) => subscribedAuthors.contains(authorId);
  bool isFavorite(String courseId) => favoritesCourses.contains(courseId);
  bool isCompleted(String courseId) => completedCourses.contains(courseId);
  
  double getCourseProgress(String courseId) => courseProgress[courseId] ?? 0.0;
  
  String getCourseProgressText(String courseId) {
    final progress = getCourseProgress(courseId);
    if (progress == 0.0) return 'Not started';
    if (progress == 1.0) return 'Completed';
    return '${(progress * 100).round()}% complete';
  }
}