import 'package:flutter_test/flutter_test.dart';
import 'package:from_fed_to_chain_app/features/auth/models/user.dart';

void main() {
  group('AppUser Model Tests', () {
    test('should create user with all parameters', () {
      final user = AppUser(
        id: 'test-user-id',
        email: 'test@example.com',
        name: 'Test User',
        photoUrl: 'https://example.com/photo.jpg',
        provider: 'google',
        createdAt: DateTime(2025, 1, 1),
        lastLoginAt: DateTime(2025, 1, 15),
      );

      expect(user.id, equals('test-user-id'));
      expect(user.email, equals('test@example.com'));
      expect(user.name, equals('Test User'));
      expect(user.photoUrl, equals('https://example.com/photo.jpg'));
      expect(user.provider, equals('google'));
      expect(user.createdAt, equals(DateTime(2025, 1, 1)));
      expect(user.lastLoginAt, equals(DateTime(2025, 1, 15)));
    });

    test('should serialize and deserialize correctly', () {
      final user = AppUser(
        id: 'test-user-id',
        email: 'test@example.com',
        name: 'Test User',
        photoUrl: null,
        provider: 'apple',
        createdAt: DateTime(2025, 1, 1),
        lastLoginAt: DateTime(2025, 1, 15),
      );

      final json = user.toJson();
      final restored = AppUser.fromJson(json);

      expect(restored.id, equals(user.id));
      expect(restored.email, equals(user.email));
      expect(restored.name, equals(user.name));
      expect(restored.photoUrl, equals(user.photoUrl));
      expect(restored.provider, equals(user.provider));
      expect(restored.createdAt, equals(user.createdAt));
      expect(restored.lastLoginAt, equals(user.lastLoginAt));
    });

    test('copyWith should override selected fields', () {
      final user = AppUser(
        id: 'test-user-id',
        email: 'test@example.com',
        name: 'Test User',
        photoUrl: null,
        provider: 'google',
        createdAt: DateTime(2025, 1, 1),
        lastLoginAt: DateTime(2025, 1, 15),
      );

      final updated = user.copyWith(
        name: 'Updated Name',
        photoUrl: 'https://example.com/photo.jpg',
      );

      expect(updated.id, equals(user.id));
      expect(updated.email, equals(user.email));
      expect(updated.name, equals('Updated Name'));
      expect(updated.photoUrl, equals('https://example.com/photo.jpg'));
      expect(updated.provider, equals(user.provider));
      expect(updated.createdAt, equals(user.createdAt));
      expect(updated.lastLoginAt, equals(user.lastLoginAt));
    });
  });
}
