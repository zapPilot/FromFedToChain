import 'package:http/http.dart' as http;
import 'package:from_fed_to_chain_app/core/di/service_locator.dart';
import 'package:from_fed_to_chain_app/features/content/data/streaming_api_service.dart';
import 'package:from_fed_to_chain_app/features/content/data/episode_repository.dart';
import 'package:from_fed_to_chain_app/features/content/data/episode_repository_impl.dart';
import 'package:from_fed_to_chain_app/features/content/domain/use_cases/use_cases.dart';

/// Initialize the dependency injection container.
///
/// Registers all services, repositories, and use cases for the application.
/// This should be called once during app startup before any services are used.
///
/// Example:
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await init();
///   runApp(MyApp());
/// }
/// ```
Future<void> init() async {
  // ========================================
  // External Dependencies
  // ========================================
  if (!sl.isRegistered<http.Client>()) {
    sl.registerLazySingleton<http.Client>(() => http.Client());
  }

  // ========================================
  // Data Layer - API Services
  // ========================================
  if (!sl.isRegistered<StreamingApiService>()) {
    sl.registerLazySingleton<StreamingApiService>(
      () => StreamingApiService(client: sl<http.Client>()),
    );
  }

  // ========================================
  // Data Layer - Repositories
  // ========================================
  if (!sl.isRegistered<EpisodeRepository>()) {
    sl.registerLazySingleton<EpisodeRepository>(
      () => EpisodeRepositoryImpl(apiService: sl<StreamingApiService>()),
    );
  }

  // ========================================
  // Domain Layer - Use Cases
  // ========================================
  if (!sl.isRegistered<LoadEpisodesUseCase>()) {
    sl.registerLazySingleton<LoadEpisodesUseCase>(
      () => LoadEpisodesUseCase(sl<EpisodeRepository>()),
    );
  }

  if (!sl.isRegistered<FilterEpisodesUseCase>()) {
    sl.registerLazySingleton<FilterEpisodesUseCase>(
      () => FilterEpisodesUseCase(),
    );
  }

  if (!sl.isRegistered<SearchEpisodesUseCase>()) {
    sl.registerLazySingleton<SearchEpisodesUseCase>(
      () => SearchEpisodesUseCase(sl<StreamingApiService>()),
    );
  }

  // ========================================
  // Service Layer - Services (Factories)
  // ========================================
  // Note: ChangeNotifier services are registered in main.dart with Provider
  // to maintain compatibility with the existing Provider setup.
  // As the refactoring progresses, we can optionally move them here using:
  // sl.registerFactory<ContentService>(() => ContentService(...));
}

/// Reset the dependency injection container.
///
/// Clears all registered instances and prepares for re-initialization.
/// Primarily used for testing to ensure a clean state between tests.
Future<void> resetContainer() async {
  await reset();
}
