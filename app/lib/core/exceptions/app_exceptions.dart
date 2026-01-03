/// Base exception for all app-specific errors
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException(this.message, {this.code, this.originalError});

  @override
  String toString() =>
      'AppException: $message ${code != null ? '[$code]' : ''}';
}

/// Exception related to streaming API operations
class StreamingApiException extends AppException {
  StreamingApiException(super.message, {super.code, super.originalError});
}

/// Exception related to network issues
class NetworkException extends AppException {
  NetworkException(super.message, {super.originalError});
}

/// Exception related to general API issues
class ApiException extends AppException {
  ApiException(super.message, {int? statusCode})
      : super(code: statusCode?.toString());
}

/// Exception when an operation times out
class TimeoutException extends AppException {
  TimeoutException(super.message);
}

/// Exception for unknown errors
class UnknownException extends AppException {
  UnknownException(super.message, {super.originalError});
}

/// Exception for cache related operations
class CacheException extends AppException {
  CacheException(super.message, {super.originalError});
}
