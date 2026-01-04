import 'package:flutter_test/flutter_test.dart';

import 'package:from_fed_to_chain_app/core/exceptions/app_exceptions.dart';

void main() {
  group('AppException Tests', () {
    test('AppException toString without code', () {
      final exception = StreamingApiException('Test message');
      expect(exception.toString(), contains('Test message'));
    });

    test('AppException toString with code', () {
      final exception = StreamingApiException('Test message', code: 'ERR001');
      expect(exception.toString(), contains('[ERR001]'));
    });

    test('AppException with originalError', () {
      final original = Exception('Original');
      final exception =
          StreamingApiException('Wrapped error', originalError: original);
      expect(exception.originalError, original);
    });
  });

  group('StreamingApiException Tests', () {
    test('should create with message', () {
      final exception = StreamingApiException('Streaming error');
      expect(exception.message, 'Streaming error');
    });

    test('should create with code', () {
      final exception = StreamingApiException('Error', code: 'STREAM_001');
      expect(exception.code, 'STREAM_001');
    });

    test('should create with originalError', () {
      final error = Exception('Original');
      final exception = StreamingApiException('Error', originalError: error);
      expect(exception.originalError, isNotNull);
    });
  });

  group('NetworkException Tests', () {
    test('should create with message', () {
      final exception = NetworkException('Network error');
      expect(exception.message, 'Network error');
    });

    test('should create with originalError', () {
      final error = Exception('Socket error');
      final exception =
          NetworkException('Network failed', originalError: error);
      expect(exception.originalError, error);
    });
  });

  group('ApiException Tests', () {
    test('should create with message', () {
      final exception = ApiException('API error');
      expect(exception.message, 'API error');
      expect(exception.code, isNull);
    });

    test('should create with statusCode as code', () {
      final exception = ApiException('API error', statusCode: 404);
      expect(exception.code, '404');
    });

    test('should create with 500 statusCode', () {
      final exception = ApiException('Server error', statusCode: 500);
      expect(exception.code, '500');
    });
  });

  group('TimeoutException Tests', () {
    test('should create with message', () {
      final exception = TimeoutException('Request timed out');
      expect(exception.message, 'Request timed out');
    });

    test('should have no code', () {
      final exception = TimeoutException('Timeout');
      expect(exception.code, isNull);
    });
  });

  group('UnknownException Tests', () {
    test('should create with message', () {
      final exception = UnknownException('Unknown error');
      expect(exception.message, 'Unknown error');
    });

    test('should create with originalError', () {
      final error = Exception('Root cause');
      final exception = UnknownException('Unknown', originalError: error);
      expect(exception.originalError, error);
    });
  });

  group('CacheException Tests', () {
    test('should create with message', () {
      final exception = CacheException('Cache error');
      expect(exception.message, 'Cache error');
    });

    test('should create with originalError', () {
      final error = Exception('Disk error');
      final exception = CacheException('Cache failed', originalError: error);
      expect(exception.originalError, error);
    });
  });

  group('Exception Inheritance', () {
    test('all exceptions should extend AppException', () {
      expect(StreamingApiException('test'), isA<AppException>());
      expect(NetworkException('test'), isA<AppException>());
      expect(ApiException('test'), isA<AppException>());
      expect(TimeoutException('test'), isA<AppException>());
      expect(UnknownException('test'), isA<AppException>());
      expect(CacheException('test'), isA<AppException>());
    });

    test('all exceptions should implement Exception', () {
      expect(StreamingApiException('test'), isA<Exception>());
      expect(NetworkException('test'), isA<Exception>());
      expect(ApiException('test'), isA<Exception>());
    });
  });
}
