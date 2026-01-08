import 'package:flutter_test/flutter_test.dart';
import 'package:from_fed_to_chain_app/core/di/service_locator.dart';

// Test class for dependency injection testing
class TestService {
  final String name;
  TestService(this.name);
}

class AnotherTestService {
  final int value;
  AnotherTestService(this.value);
}

void main() {
  group('ServiceLocator Tests', () {
    setUp(() async {
      // Reset service locator before each test to ensure clean state
      await reset();
    });

    tearDown(() async {
      // Clean up after each test
      await reset();
    });

    group('registerSingleton', () {
      test('should register and retrieve a singleton instance', () {
        // Arrange
        final service = TestService('singleton');

        // Act
        registerSingleton<TestService>(service);
        final retrieved = get<TestService>();

        // Assert
        expect(retrieved, same(service));
        expect(retrieved.name, 'singleton');
      });

      test('should return the same instance on multiple calls', () {
        // Arrange
        final service = TestService('singleton');
        registerSingleton<TestService>(service);

        // Act
        final first = get<TestService>();
        final second = get<TestService>();

        // Assert
        expect(first, same(second));
      });
    });

    group('registerLazySingleton', () {
      test('should register and retrieve a lazy singleton instance', () {
        // Arrange
        var creationCount = 0;
        registerLazySingleton<TestService>(() {
          creationCount++;
          return TestService('lazy');
        });

        // Act
        final retrieved = get<TestService>();

        // Assert
        expect(retrieved.name, 'lazy');
        expect(creationCount, 1);
      });

      test('should create instance only once for multiple calls', () {
        // Arrange
        var creationCount = 0;
        registerLazySingleton<TestService>(() {
          creationCount++;
          return TestService('lazy');
        });

        // Act
        final first = get<TestService>();
        final second = get<TestService>();
        final third = get<TestService>();

        // Assert
        expect(first, same(second));
        expect(second, same(third));
        expect(creationCount, 1, reason: 'Factory should only be called once');
      });
    });

    group('registerFactory', () {
      test('should register and retrieve factory instances', () {
        // Arrange
        registerFactory<TestService>(() => TestService('factory'));

        // Act
        final retrieved = get<TestService>();

        // Assert
        expect(retrieved.name, 'factory');
      });

      test('should create new instance on each call', () {
        // Arrange
        var creationCount = 0;
        registerFactory<TestService>(() {
          creationCount++;
          return TestService('factory$creationCount');
        });

        // Act
        final first = get<TestService>();
        final second = get<TestService>();
        final third = get<TestService>();

        // Assert
        expect(first, isNot(same(second)));
        expect(second, isNot(same(third)));
        expect(first.name, 'factory1');
        expect(second.name, 'factory2');
        expect(third.name, 'factory3');
        expect(creationCount, 3);
      });
    });

    group('isRegistered', () {
      test('should return true for registered type', () {
        // Arrange
        registerSingleton<TestService>(TestService('test'));

        // Act & Assert
        expect(isRegistered<TestService>(), true);
      });

      test('should return false for unregistered type', () {
        // Act & Assert
        expect(isRegistered<TestService>(), false);
      });
    });

    group('Multiple Services', () {
      test('should register and retrieve multiple different services', () {
        // Arrange
        final testService = TestService('multi');
        final anotherService = AnotherTestService(42);

        // Act
        registerSingleton<TestService>(testService);
        registerSingleton<AnotherTestService>(anotherService);

        // Assert
        expect(get<TestService>(), same(testService));
        expect(get<AnotherTestService>(), same(anotherService));
        expect(get<TestService>().name, 'multi');
        expect(get<AnotherTestService>().value, 42);
      });
    });

    group('reset', () {
      test('should clear all registered instances', () async {
        // Arrange
        registerSingleton<TestService>(TestService('test'));
        expect(isRegistered<TestService>(), true);

        // Act
        await reset();

        // Assert
        expect(isRegistered<TestService>(), false);
      });

      test('should allow re-registration after reset', () async {
        // Arrange
        registerSingleton<TestService>(TestService('first'));
        await reset();

        // Act
        registerSingleton<TestService>(TestService('second'));
        final retrieved = get<TestService>();

        // Assert
        expect(retrieved.name, 'second');
      });
    });
  });
}
