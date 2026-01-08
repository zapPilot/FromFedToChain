/// Dependency Injection barrel file.
///
/// Exports all DI-related modules for easy importing throughout the app.
library di;

/// ```dart
/// import 'package:from_fed_to_chain_app/core/di/di.dart' as di;
///
/// // Initialize DI container
/// await di.init();
///
/// // Get service instances
/// final service = di.sl<MyService>();
/// ```

export 'service_locator.dart';
export 'injection_container.dart';
