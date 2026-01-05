import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:fake_async/fake_async.dart';
import 'package:from_fed_to_chain_app/features/content/data/interceptors/interceptors.dart';

@GenerateMocks([ErrorInterceptorHandler, Dio])
import 'api_interceptors_test.mocks.dart';

void main() {
  group('RetryInterceptor', () {
    late RetryInterceptor retryInterceptor;
    late MockErrorInterceptorHandler mockHandler;
    late MockDio mockDio;

    setUp(() {
      mockDio = MockDio();
      retryInterceptor = RetryInterceptor(client: mockDio);
      mockHandler = MockErrorInterceptorHandler();
    });

    test('should NOT retry on client error (400)', () {
      final requestOptions = RequestOptions(path: '/test');
      final err = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 400,
        ),
        type: DioExceptionType.badResponse,
      );

      retryInterceptor.onError(err, mockHandler);

      verify(mockHandler.next(err)).called(1);
      verifyZeroInteractions(mockDio);
    });

    test('should retry on connection timeout', () {
      fakeAsync((async) {
        final requestOptions = RequestOptions(path: '/test');
        final err = DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.connectionTimeout,
        );

        // Setup success on retry
        when(mockDio.fetch(any)).thenAnswer(
          (_) async =>
              Response(requestOptions: requestOptions, statusCode: 200),
        );

        retryInterceptor.onError(err, mockHandler);

        // Advance time to trigger retry
        async.elapse(const Duration(seconds: 2));

        // Should have called fetch
        verify(mockDio.fetch(any)).called(1);
        // Should have resolved the request
        verify(mockHandler.resolve(any)).called(1);
      });
    });

    test('should pass error after max retries', () {
      fakeAsync((async) {
        final requestOptions =
            RequestOptions(path: '/test', extra: {'retryCount': 3});
        final err = DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.connectionTimeout,
        );

        retryInterceptor.onError(err, mockHandler);

        verify(mockHandler.next(err)).called(1);
        verifyZeroInteractions(mockDio);
      });
    });

    test('should continue to next(err) if retry fails', () {
      fakeAsync((async) {
        final requestOptions = RequestOptions(path: '/test');
        final err = DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.connectionTimeout,
        );

        // Setup failure on retry
        when(mockDio.fetch(any)).thenThrow(DioException(
            requestOptions: requestOptions,
            type: DioExceptionType.connectionTimeout));

        retryInterceptor.onError(err, mockHandler);

        // Advance time
        async.elapse(const Duration(seconds: 2));

        verify(mockDio.fetch(any)).called(1);
        verify(mockHandler.next(err)).called(1);
      });
    });
  });

  group('ErrorHandlingInterceptor', () {
    late ErrorHandlingInterceptor errorInterceptor;
    late MockErrorInterceptorHandler mockHandler;

    setUp(() {
      errorInterceptor = ErrorHandlingInterceptor();
      mockHandler = MockErrorInterceptorHandler();
    });

    void verifyErrorMessage(DioExceptionType type, String expectedMessage,
        {int? statusCode}) {
      final requestOptions = RequestOptions(path: '/test');
      final err = DioException(
        requestOptions: requestOptions,
        type: type,
        response: statusCode != null
            ? Response(requestOptions: requestOptions, statusCode: statusCode)
            : null,
      );

      errorInterceptor.onError(err, mockHandler);

      final captured = verify(mockHandler.next(captureAny)).captured;
      final newErr = captured.first as DioException;
      expect(newErr.message, expectedMessage);
    }

    test('should handle connection timeout', () {
      verifyErrorMessage(
        DioExceptionType.connectionTimeout,
        'Connection timeout. Please check your internet connection.',
      );
    });

    test('should handle receive timeout', () {
      verifyErrorMessage(
        DioExceptionType.receiveTimeout,
        'Request timeout. The server is taking too long to respond.',
      );
    });

    test('should handle connection error', () {
      verifyErrorMessage(
        DioExceptionType.connectionError,
        'Network error. Please check your internet connection.',
      );
    });

    test('should handle cancel', () {
      verifyErrorMessage(
        DioExceptionType.cancel,
        'Request was cancelled.',
      );
    });

    test('should handle 404', () {
      verifyErrorMessage(
        DioExceptionType.badResponse,
        'Content not found. The requested resource doesn\'t exist.',
        statusCode: 404,
      );
    });

    test('should handle 500', () {
      verifyErrorMessage(
        DioExceptionType.badResponse,
        'Server error. Please try again later.',
        statusCode: 500,
      );
    });

    test('should handle unknown error', () {
      final requestOptions = RequestOptions(path: '/test');
      final err = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.unknown,
        message: 'Something weird',
      );

      errorInterceptor.onError(err, mockHandler);

      final captured = verify(mockHandler.next(captureAny)).captured;
      final newErr = captured.first as DioException;
      expect(newErr.message, 'An unexpected error occurred: Something weird');
    });
  });
}
