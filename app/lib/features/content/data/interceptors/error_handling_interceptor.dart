import 'package:dio/dio.dart';
import 'package:from_fed_to_chain_app/core/services/logger_service.dart';

/// Error handling interceptor for consistent error responses.
///
/// Transforms Dio errors into user-friendly error messages
/// based on the type of error or HTTP status code.
class ErrorHandlingInterceptor extends Interceptor {
  static final _log = LoggerService.getLogger('ErrorHandlingInterceptor');

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    String errorMessage;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
        errorMessage =
            'Connection timeout. Please check your internet connection.';
        break;
      case DioExceptionType.receiveTimeout:
        errorMessage =
            'Request timeout. The server is taking too long to respond.';
        break;
      case DioExceptionType.connectionError:
        errorMessage = 'Network error. Please check your internet connection.';
        break;
      case DioExceptionType.badResponse:
        errorMessage = _handleHttpError(err.response?.statusCode);
        break;
      case DioExceptionType.cancel:
        errorMessage = 'Request was cancelled.';
        break;
      default:
        errorMessage = 'An unexpected error occurred: ${err.message}';
        break;
    }

    _log.severe(errorMessage);

    // Create a new DioException with user-friendly message
    final newError = DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: errorMessage,
      message: errorMessage,
    );

    handler.next(newError);
  }

  String _handleHttpError(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request. Please check your input.';
      case 401:
        return 'Unauthorized. Please log in again.';
      case 403:
        return 'Access forbidden. You don\'t have permission to access this resource.';
      case 404:
        return 'Content not found. The requested resource doesn\'t exist.';
      case 429:
        return 'Too many requests. Please wait before trying again.';
      case 500:
        return 'Server error. Please try again later.';
      case 502:
        return 'Bad gateway. The server is temporarily unavailable.';
      case 503:
        return 'Service unavailable. Please try again later.';
      case 504:
        return 'Gateway timeout. The server is taking too long to respond.';
      default:
        return 'HTTP error $statusCode occurred.';
    }
  }
}
