import 'package:dio/dio.dart';
import 'package:from_fed_to_chain_app/core/services/logger_service.dart';

/// Retry interceptor for handling temporary failures.
///
/// Automatically retries requests that fail due to network issues
/// or certain HTTP status codes (502, 503, 504).
class RetryInterceptor extends Interceptor {
  static final _log = LoggerService.getLogger('RetryInterceptor');

  /// Maximum number of retry attempts.
  static const int maxRetries = 3;

  /// Base delay between retry attempts (multiplied by attempt number).
  static const Duration retryDelay = Duration(seconds: 1);

  final Dio? _client;

  /// Creates a [RetryInterceptor].
  ///
  /// Optionally accepts a [client] for making retry requests.
  /// If not provided, a new Dio instance is created for retries.
  RetryInterceptor({Dio? client}) : _client = client;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_shouldRetry(err) &&
        (err.requestOptions.extra['retryCount'] ?? 0) < maxRetries) {
      final retryCount = (err.requestOptions.extra['retryCount'] ?? 0) + 1;
      err.requestOptions.extra['retryCount'] = retryCount;

      _log.warning('Retrying request (attempt $retryCount/$maxRetries)');

      await Future.delayed(retryDelay * retryCount);

      try {
        final client = _client ?? Dio();
        final response = await client.fetch(err.requestOptions);
        handler.resolve(response);
        return;
      } catch (e) {
        // Continue to original error handling
      }
    }

    handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    // Retry on network errors and certain HTTP status codes
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.response?.statusCode != null &&
            [502, 503, 504].contains(err.response!.statusCode));
  }
}
