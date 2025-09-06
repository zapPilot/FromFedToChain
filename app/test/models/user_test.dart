import 'package:flutter_test/flutter_test.dart';
import 'package:from_fed_to_chain_app/models/user.dart';

void main() {
  group('User Model Tests', () {
    group('User Creation', () {
      test('should create user with all parameters', () {
        final user = User(
          id: 'test-user-id',
          email: 'test@example.com',
          name: 'Test User',
          photoUrl: 'https://example.com/photo.jpg',
          provider: AuthProvider.google,
        );

        expect(user.id, equals('test-user-id'));
        expect(user.email, equals('test@example.com'));
        expect(user.name, equals('Test User'));
        expect(user.photoUrl, equals('https://example.com/photo.jpg'));
        expect(user.provider, equals(AuthProvider.google));
      });

      test('should create user without photoUrl', () {
        final user = User(
          id: 'test-user-id',
          email: 'test@example.com',
          name: 'Test User',
          provider: AuthProvider.apple,
        );

        expect(user.id, equals('test-user-id'));
        expect(user.email, equals('test@example.com'));
        expect(user.name, equals('Test User'));
        expect(user.photoUrl, isNull);
        expect(user.provider, equals(AuthProvider.apple));
      });
    });

    group('Factory Constructors', () {
      test('should create user from Google with all data', () {
        final user = User.fromGoogle(
          id: 'google-123',
          email: 'google@example.com',
          displayName: 'Google User',
          photoUrl: 'https://lh3.googleusercontent.com/photo.jpg',
        );

        expect(user.id, equals('google-123'));
        expect(user.email, equals('google@example.com'));
        expect(user.name, equals('Google User'));
        expect(user.photoUrl,
            equals('https://lh3.googleusercontent.com/photo.jpg'));
        expect(user.provider, equals(AuthProvider.google));
      });

      test('should create user from Google without photoUrl', () {
        final user = User.fromGoogle(
          id: 'google-123',
          email: 'google@example.com',
          displayName: 'Google User',
        );

        expect(user.id, equals('google-123'));
        expect(user.email, equals('google@example.com'));
        expect(user.name, equals('Google User'));
        expect(user.photoUrl, isNull);
        expect(user.provider, equals(AuthProvider.google));
      });

      test('should create user from Apple with full name', () {
        final user = User.fromApple(
          id: 'apple-456',
          email: 'apple@example.com',
          fullName: 'Apple User',
        );

        expect(user.id, equals('apple-456'));
        expect(user.email, equals('apple@example.com'));
        expect(user.name, equals('Apple User'));
        expect(user.photoUrl, isNull);
        expect(user.provider, equals(AuthProvider.apple));
      });

      test(
          'should create user from Apple without full name and use email prefix',
          () {
        final user = User.fromApple(
          id: 'apple-789',
          email: 'testuser@privaterelay.appleid.com',
        );

        expect(user.id, equals('apple-789'));
        expect(user.email, equals('testuser@privaterelay.appleid.com'));
        expect(user.name, equals('testuser'));
        expect(user.photoUrl, isNull);
        expect(user.provider, equals(AuthProvider.apple));
      });
    });

    group('JSON Serialization', () {
      test('should convert to JSON correctly', () {
        final user = User(
          id: 'test-123',
          email: 'test@example.com',
          name: 'Test User',
          photoUrl: 'https://example.com/photo.jpg',
          provider: AuthProvider.google,
        );

        final json = user.toJson();

        expect(json['id'], equals('test-123'));
        expect(json['email'], equals('test@example.com'));
        expect(json['name'], equals('Test User'));
        expect(json['photoUrl'], equals('https://example.com/photo.jpg'));
        expect(json['provider'], equals('AuthProvider.google'));
      });

      test('should convert to JSON correctly with null photoUrl', () {
        final user = User(
          id: 'test-456',
          email: 'test@example.com',
          name: 'Test User',
          provider: AuthProvider.apple,
        );

        final json = user.toJson();

        expect(json['id'], equals('test-456'));
        expect(json['email'], equals('test@example.com'));
        expect(json['name'], equals('Test User'));
        expect(json['photoUrl'], isNull);
        expect(json['provider'], equals('AuthProvider.apple'));
      });

      test('should create from JSON correctly', () {
        final json = {
          'id': 'json-123',
          'email': 'json@example.com',
          'name': 'JSON User',
          'photoUrl': 'https://example.com/json.jpg',
          'provider': 'AuthProvider.google',
        };

        final user = User.fromJson(json);

        expect(user.id, equals('json-123'));
        expect(user.email, equals('json@example.com'));
        expect(user.name, equals('JSON User'));
        expect(user.photoUrl, equals('https://example.com/json.jpg'));
        expect(user.provider, equals(AuthProvider.google));
      });

      test('should create from JSON correctly with null photoUrl', () {
        final json = {
          'id': 'json-456',
          'email': 'json@example.com',
          'name': 'JSON User',
          'photoUrl': null,
          'provider': 'AuthProvider.apple',
        };

        final user = User.fromJson(json);

        expect(user.id, equals('json-456'));
        expect(user.email, equals('json@example.com'));
        expect(user.name, equals('JSON User'));
        expect(user.photoUrl, isNull);
        expect(user.provider, equals(AuthProvider.apple));
      });

      test(
          'should create from JSON with unknown provider and default to Google',
          () {
        final json = {
          'id': 'json-789',
          'email': 'json@example.com',
          'name': 'JSON User',
          'photoUrl': null,
          'provider': 'AuthProvider.unknown',
        };

        final user = User.fromJson(json);

        expect(user.id, equals('json-789'));
        expect(user.email, equals('json@example.com'));
        expect(user.name, equals('JSON User'));
        expect(user.photoUrl, isNull);
        expect(user.provider, equals(AuthProvider.google)); // Default fallback
      });
    });

    group('Equatable', () {
      test('should compare users correctly', () {
        final user1 = User(
          id: 'test-123',
          email: 'test@example.com',
          name: 'Test User',
          photoUrl: 'https://example.com/photo.jpg',
          provider: AuthProvider.google,
        );

        final user2 = User(
          id: 'test-123',
          email: 'test@example.com',
          name: 'Test User',
          photoUrl: 'https://example.com/photo.jpg',
          provider: AuthProvider.google,
        );

        final user3 = User(
          id: 'test-456',
          email: 'test@example.com',
          name: 'Test User',
          photoUrl: 'https://example.com/photo.jpg',
          provider: AuthProvider.google,
        );

        // Same content should be equal
        expect(user1, equals(user2));

        // Different content should not be equal
        expect(user1, isNot(equals(user3)));
      });

      test('should have same hash code for equal users', () {
        final user1 = User(
          id: 'test-123',
          email: 'test@example.com',
          name: 'Test User',
          provider: AuthProvider.google,
        );

        final user2 = User(
          id: 'test-123',
          email: 'test@example.com',
          name: 'Test User',
          provider: AuthProvider.google,
        );

        expect(user1.hashCode, equals(user2.hashCode));
      });
    });

    group('Edge Cases', () {
      test('should handle empty email for Apple user name generation', () {
        final user = User.fromApple(
          id: 'apple-empty',
          email: '',
        );

        expect(user.id, equals('apple-empty'));
        expect(user.email, equals(''));
        expect(user.name, equals(''));
        expect(user.provider, equals(AuthProvider.apple));
      });

      test('should handle email without @ symbol for Apple user', () {
        final user = User.fromApple(
          id: 'apple-no-at',
          email: 'invalidemailformat',
        );

        expect(user.id, equals('apple-no-at'));
        expect(user.email, equals('invalidemailformat'));
        expect(user.name,
            equals('invalidemailformat')); // Should use entire string
        expect(user.provider, equals(AuthProvider.apple));
      });

      test('should handle complex email formats for Apple user', () {
        final user = User.fromApple(
          id: 'apple-complex',
          email: 'user.name+test@subdomain.domain.com',
        );

        expect(user.id, equals('apple-complex'));
        expect(user.email, equals('user.name+test@subdomain.domain.com'));
        expect(user.name, equals('user.name+test'));
        expect(user.provider, equals(AuthProvider.apple));
      });

      test('should handle JSON serialization roundtrip', () {
        final originalUser = User.fromGoogle(
          id: 'roundtrip-test',
          email: 'roundtrip@example.com',
          displayName: 'Roundtrip User',
          photoUrl: 'https://example.com/roundtrip.jpg',
        );

        final json = originalUser.toJson();
        final reconstructedUser = User.fromJson(json);

        expect(reconstructedUser, equals(originalUser));
      });
    });

    group('Provider String Representations', () {
      test('should handle provider toString correctly', () {
        final googleUser = User.fromGoogle(
          id: 'google-test',
          email: 'google@example.com',
          displayName: 'Google Test',
        );

        final appleUser = User.fromApple(
          id: 'apple-test',
          email: 'apple@example.com',
        );

        expect(googleUser.provider.toString(), equals('AuthProvider.google'));
        expect(appleUser.provider.toString(), equals('AuthProvider.apple'));
      });
    });
  });

  group('AuthProvider Enum Tests', () {
    test('should have correct enum values', () {
      expect(AuthProvider.values.length, equals(2));
      expect(AuthProvider.values, contains(AuthProvider.google));
      expect(AuthProvider.values, contains(AuthProvider.apple));
    });

    test('should convert to string correctly', () {
      expect(AuthProvider.google.toString(), equals('AuthProvider.google'));
      expect(AuthProvider.apple.toString(), equals('AuthProvider.apple'));
    });

    test('should have correct index values', () {
      expect(AuthProvider.google.index, equals(0));
      expect(AuthProvider.apple.index, equals(1));
    });
  });
}
