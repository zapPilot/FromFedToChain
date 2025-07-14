class Author {
  final String id;
  final String name;
  final String bio;
  final String? profileImage;
  final String? backgroundImage;
  final int subscriberCount;
  final List<String> expertise; // ['crypto', 'macro', 'startup']
  final List<String> languages; // ['zh-TW', 'en-US', 'ja-JP']
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isVerified;
  final String? website;
  final String? twitter;
  final String? linkedin;

  Author({
    required this.id,
    required this.name,
    required this.bio,
    this.profileImage,
    this.backgroundImage,
    required this.subscriberCount,
    required this.expertise,
    required this.languages,
    required this.createdAt,
    required this.updatedAt,
    this.isVerified = false,
    this.website,
    this.twitter,
    this.linkedin,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      bio: json['bio'] ?? '',
      profileImage: json['profile_image'],
      backgroundImage: json['background_image'],
      subscriberCount: json['subscriber_count'] ?? 0,
      expertise: List<String>.from(json['expertise'] ?? []),
      languages: List<String>.from(json['languages'] ?? []),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      isVerified: json['is_verified'] ?? false,
      website: json['website'],
      twitter: json['twitter'],
      linkedin: json['linkedin'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bio': bio,
      'profile_image': profileImage,
      'background_image': backgroundImage,
      'subscriber_count': subscriberCount,
      'expertise': expertise,
      'languages': languages,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_verified': isVerified,
      'website': website,
      'twitter': twitter,
      'linkedin': linkedin,
    };
  }

  // Helper methods
  String get displayName => name;
  
  String get expertiseText => expertise.join(', ');
  
  String get languagesText {
    return languages.map((lang) {
      switch (lang) {
        case 'zh-TW':
          return '繁體中文';
        case 'en-US':
          return 'English';
        case 'ja-JP':
          return '日本語';
        default:
          return lang;
      }
    }).join(', ');
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
}