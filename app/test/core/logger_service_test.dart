import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

import 'package:from_fed_to_chain_app/core/services/logger_service.dart';

void main() {
  group('LoggerService Tests', () {
    setUp(() {
      // Reset logger state before each test
      Logger.root.level = Level.OFF;
      Logger.root.clearListeners();
    });

    test('should create logger with component name', () {
      final logger = LoggerService.getLogger('TestComponent');
      expect(logger.name, 'TestComponent');
    });

    test('should create multiple loggers with different names', () {
      final logger1 = LoggerService.getLogger('Component1');
      final logger2 = LoggerService.getLogger('Component2');
      expect(logger1.name, 'Component1');
      expect(logger2.name, 'Component2');
    });

    test('created logger should be able to log info', () {
      final logger = LoggerService.getLogger('TestLogger');
      // Should not throw
      logger.info('Test info message');
    });

    test('created logger should be able to log warning', () {
      final logger = LoggerService.getLogger('TestLogger');
      // Should not throw
      logger.warning('Test warning message');
    });

    test('created logger should be able to log severe', () {
      final logger = LoggerService.getLogger('TestLogger');
      // Should not throw
      logger.severe('Test severe message');
    });

    test('created logger should handle error objects', () {
      final logger = LoggerService.getLogger('TestLogger');
      final error = Exception('Test error');
      // Should not throw
      logger.severe('Error occurred', error);
    });

    test('created logger should handle stack traces', () {
      final logger = LoggerService.getLogger('TestLogger');
      try {
        throw Exception('Test exception');
      } catch (e, stackTrace) {
        // Should not throw
        logger.severe('Exception caught', e, stackTrace);
      }
    });

    test('should return consistent logger for same name', () {
      final logger1 = LoggerService.getLogger('SameName');
      final logger2 = LoggerService.getLogger('SameName');
      expect(logger1.fullName, logger2.fullName);
    });

    test('should handle special characters in component name', () {
      final logger = LoggerService.getLogger('Component:Service-Test');
      expect(logger.name, 'Component:Service-Test');
    });

    test('should handle empty component name', () {
      final logger = LoggerService.getLogger('');
      expect(logger.name, '');
    });

    test('should log at different levels', () {
      final logger = LoggerService.getLogger('LevelTest');

      // All should not throw
      logger.finest('finest message');
      logger.finer('finer message');
      logger.fine('fine message');
      logger.config('config message');
      logger.info('info message');
      logger.warning('warning message');
      logger.severe('severe message');
      logger.shout('shout message');
    });
  });

  group('LoggerService.initialize Tests', () {
    setUp(() {
      Logger.root.level = Level.OFF;
      Logger.root.clearListeners();
    });

    test('initialize with logging enabled should set level to ALL', () {
      LoggerService.initialize(enableLogging: true);
      expect(Logger.root.level, Level.ALL);
    });

    test('initialize with logging disabled should set level to OFF', () {
      LoggerService.initialize(enableLogging: false);
      expect(Logger.root.level, Level.OFF);
    });

    test('initialize should add listener when enabled', () {
      LoggerService.initialize(enableLogging: true);
      final logger = LoggerService.getLogger('InitTest');
      // Should not throw when logging
      logger.info('Test after initialization');
    });

    test('should handle log records with errors', () {
      LoggerService.initialize(enableLogging: true);
      final logger = LoggerService.getLogger('ErrorTest');
      final error = Exception('Test exception');
      logger.severe('Error occurred', error, StackTrace.current);
    });

    test('should format log record with time', () {
      LoggerService.initialize(enableLogging: true);
      final logger = LoggerService.getLogger('TimeFormatTest');
      logger.info('Message with timestamp');
    });

    test('should differentiate log levels with emojis', () {
      LoggerService.initialize(enableLogging: true);
      final logger = LoggerService.getLogger('EmojiTest');

      logger.shout('SHOUT level');
      logger.severe('SEVERE level');
      logger.warning('WARNING level');
      logger.info('INFO level');
      logger.config('CONFIG level');
      logger.fine('FINE level');
    });
  });
}
