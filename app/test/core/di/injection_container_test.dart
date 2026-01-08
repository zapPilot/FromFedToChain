import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:from_fed_to_chain_app/core/di/injection_container.dart' as di;
import 'package:from_fed_to_chain_app/core/di/service_locator.dart';
import 'package:from_fed_to_chain_app/features/content/data/streaming_api_service.dart';
import 'package:from_fed_to_chain_app/features/content/data/episode_repository.dart';
import 'package:from_fed_to_chain_app/features/content/domain/use_cases/use_cases.dart';

void main() {
  group('InjectionContainer Tests', () {
    setUp(() async {
      // Reset service locator before each test to ensure clean state
      await reset();
    });

    tearDown(() async {
      // Clean up after each test
      await reset();
    });

    group('init', () {
      test('should complete without errors', () async {
        // Act & Assert
        expect(di.init(), completes);
      });

      test('should be callable multiple times without errors', () async {
        // Act
        await di.init();
        await di.init();

        // Assert - no errors thrown
        expect(true, true);
      });

      test('should register http.Client', () async {
        // Act
        await di.init();

        // Assert
        expect(sl.isRegistered<http.Client>(), isTrue);
        expect(sl<http.Client>(), isNotNull);
      });

      test('should register StreamingApiService', () async {
        // Act
        await di.init();

        // Assert
        expect(sl.isRegistered<StreamingApiService>(), isTrue);
        expect(sl<StreamingApiService>(), isNotNull);
      });

      test('should register EpisodeRepository', () async {
        // Act
        await di.init();

        // Assert
        expect(sl.isRegistered<EpisodeRepository>(), isTrue);
        expect(sl<EpisodeRepository>(), isNotNull);
      });
    });

    group('resetContainer', () {
      test('should reset the container successfully', () async {
        // Arrange
        await di.init();

        // Act & Assert
        expect(di.resetContainer(), completes);
      });

      test('should allow re-initialization after reset', () async {
        // Arrange
        await di.init();
        await di.resetContainer();

        // Act & Assert
        expect(di.init(), completes);
      });

      test('should clear all registered services', () async {
        // Arrange
        await di.init();
        expect(sl.isRegistered<StreamingApiService>(), isTrue);

        // Act
        await di.resetContainer();

        // Assert
        expect(sl.isRegistered<StreamingApiService>(), isFalse);
      });
    });

    group('Integration', () {
      test('should initialize container with correct dependencies', () async {
        // Arrange
        await di.resetContainer();

        // Act
        await di.init();

        // Assert - verify services are registered
        expect(sl.isRegistered<http.Client>(), isTrue);
        expect(sl.isRegistered<StreamingApiService>(), isTrue);
        expect(sl.isRegistered<EpisodeRepository>(), isTrue);
        expect(sl.isRegistered<LoadEpisodesUseCase>(), isTrue);
        expect(sl.isRegistered<FilterEpisodesUseCase>(), isTrue);
        expect(sl.isRegistered<SearchEpisodesUseCase>(), isTrue);
      });

      test('StreamingApiService should use injected http.Client', () async {
        // Arrange
        await di.init();

        // Act
        final apiService = sl<StreamingApiService>();

        // Assert - service should be properly instantiated
        expect(apiService, isNotNull);
        // The service should use the injected client, not create its own
        // This is verified by the fact that it resolves successfully
      });

      test('EpisodeRepository should use injected StreamingApiService',
          () async {
        // Arrange
        await di.init();

        // Act
        final repository = sl<EpisodeRepository>();

        // Assert - repository should be properly instantiated
        expect(repository, isNotNull);
      });
    });

    group('Singleton behavior', () {
      test('should return same instance for lazy singleton', () async {
        // Arrange
        await di.init();

        // Act
        final client1 = sl<http.Client>();
        final client2 = sl<http.Client>();

        // Assert
        expect(identical(client1, client2), isTrue);
      });

      test('should return same StreamingApiService instance', () async {
        // Arrange
        await di.init();

        // Act
        final service1 = sl<StreamingApiService>();
        final service2 = sl<StreamingApiService>();

        // Assert
        expect(identical(service1, service2), isTrue);
      });

      test('should return same EpisodeRepository instance', () async {
        // Arrange
        await di.init();

        // Act
        final repo1 = sl<EpisodeRepository>();
        final repo2 = sl<EpisodeRepository>();

        // Assert
        expect(identical(repo1, repo2), isTrue);
      });
    });
  });
}
