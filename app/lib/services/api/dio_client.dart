import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../config/api_config.dart';

/// Creates and configures a Dio instance for API communication.
Dio createDioClient() {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.streamingBaseUrl,
      connectTimeout: ApiConfig.apiTimeout,
      receiveTimeout: ApiConfig.apiTimeout,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'User-Agent': 'FromFedToChain/1.0.0 (Flutter)',
      },
    ),
  );

  // Add logging interceptor in debug mode
  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (o) => debugPrint(o.toString()),
      ),
    );
  }

  return dio;
}
