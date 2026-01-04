import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Centralized logging service for the application.
///
/// Features:
/// - Unified configuration for all loggers
/// - Debug mode filtering
/// - Structured log output
/// - Error stack trace handling
class LoggerService {
  static bool _initialized = false;
  static final Logger _rootLogger = Logger.root;

  /// Initialize the logging service.
  ///
  /// [enableLogging] controls whether logs are output to console.
  /// Defaults to [kDebugMode].
  static void initialize({bool enableLogging = kDebugMode}) {
    if (_initialized) return;

    if (enableLogging) {
      Logger.root.level = Level.ALL;
      Logger.root.onRecord.listen(_onRecord);
      _rootLogger.info('📝 LoggerService initialized');
    } else {
      Logger.root.level = Level.OFF;
    }

    _initialized = true;
  }

  /// Create a logger for a specific component.
  static Logger getLogger(String componentName) {
    return Logger(componentName);
  }

  /// Handle log records
  static void _onRecord(LogRecord record) {
    // Format: [TIME] [LEVEL] [COMPONENT]: MESSAGE
    final time = record.time.toIso8601String().split('T')[1].substring(0, 8);
    final level = _getLevelEmoji(record.level);
    final component = record.loggerName.padRight(20);

    final message = '$time $level [$component] ${record.message}';

    debugPrint(message);

    if (record.error != null) {
      debugPrint('👉 Error: ${record.error}');
    }

    if (record.stackTrace != null) {
      debugPrint('📚 Stack: ${record.stackTrace}');
    }
  }

  /// Get emoji for log level
  static String _getLevelEmoji(Level level) {
    if (level == Level.SHOUT) return '‼️';
    if (level == Level.SEVERE) return '❌';
    if (level == Level.WARNING) return '⚠️';
    if (level == Level.INFO) return 'ℹ️';
    if (level == Level.CONFIG) return '🛠️';
    return '📝';
  }
}
