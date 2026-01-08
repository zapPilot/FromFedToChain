import 'package:get_it/get_it.dart';

/// Global service locator instance using GetIt.
///
/// Provides centralized dependency injection for the application.
/// Use this to register and retrieve service instances throughout the app.
final GetIt sl = GetIt.instance;

/// Register a singleton instance.
///
/// The instance will be created immediately and reused for all requests.
///
/// Example:
/// ```dart
/// registerSingleton<MyService>(MyService());
/// ```
void registerSingleton<T extends Object>(T instance) {
  sl.registerSingleton<T>(instance);
}

/// Register a lazy singleton factory.
///
/// The instance will be created on first request and reused thereafter.
///
/// Example:
/// ```dart
/// registerLazySingleton<MyService>(() => MyService());
/// ```
void registerLazySingleton<T extends Object>(T Function() factoryFunc) {
  sl.registerLazySingleton<T>(factoryFunc);
}

/// Register a factory function.
///
/// A new instance will be created for each request.
/// Use this for ChangeNotifier services that need fresh instances.
///
/// Example:
/// ```dart
/// registerFactory<MyService>(() => MyService());
/// ```
void registerFactory<T extends Object>(T Function() factoryFunc) {
  sl.registerFactory<T>(factoryFunc);
}

/// Check if a type is registered.
///
/// Returns `true` if the type has been registered, `false` otherwise.
bool isRegistered<T extends Object>() {
  return sl.isRegistered<T>();
}

/// Get an instance of a registered type.
///
/// Throws an error if the type is not registered.
///
/// Example:
/// ```dart
/// final service = get<MyService>();
/// ```
T get<T extends Object>() {
  return sl<T>();
}

/// Reset the service locator.
///
/// Disposes all registered instances and clears the container.
/// Primarily used for testing to ensure a clean state between tests.
Future<void> reset() async {
  await sl.reset();
}
