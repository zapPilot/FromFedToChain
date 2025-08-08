import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final AuthProvider provider;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    required this.provider,
  });

  factory User.fromGoogle({
    required String id,
    required String email,
    required String displayName,
    String? photoUrl,
  }) {
    return User(
      id: id,
      email: email,
      name: displayName,
      photoUrl: photoUrl,
      provider: AuthProvider.google,
    );
  }

  factory User.fromApple({
    required String id,
    required String email,
    String? fullName,
  }) {
    return User(
      id: id,
      email: email,
      name: fullName ?? email.split('@').first,
      provider: AuthProvider.apple,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'provider': provider.toString(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      photoUrl: json['photoUrl'],
      provider: AuthProvider.values.firstWhere(
        (p) => p.toString() == json['provider'],
        orElse: () => AuthProvider.google,
      ),
    );
  }

  @override
  List<Object?> get props => [id, email, name, photoUrl, provider];
}

enum AuthProvider {
  google,
  apple,
}