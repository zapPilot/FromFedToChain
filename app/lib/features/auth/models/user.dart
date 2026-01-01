class AppUser {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String provider; // 'apple' or 'google'
  final DateTime createdAt;
  final DateTime lastLoginAt;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.provider,
    required this.createdAt,
    required this.lastLoginAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'provider': provider,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      photoUrl: json['photoUrl'],
      provider: json['provider'],
      createdAt: DateTime.parse(json['createdAt']),
      lastLoginAt: DateTime.parse(json['lastLoginAt']),
    );
  }

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    String? provider,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      provider: provider ?? this.provider,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}
