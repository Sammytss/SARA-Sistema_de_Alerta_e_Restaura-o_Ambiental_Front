import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../security/secure_store.dart';
import 'auth_interceptor.dart';

/// Cliente HTTP central baseado em Dio.
/// Quando [secureStore] é fornecido, adiciona AuthInterceptor
/// que injeta JWT em cada requisição e faz refresh automático em 401.
class ApiClient {
  late final Dio dio;

  ApiClient({SecureStore? secureStore}) {
    dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    if (secureStore != null) {
      dio.interceptors.add(
        AuthInterceptor(secureStore: secureStore, dio: dio),
      );
    }

    if (AppConfig.isDev) {
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (o) => debugPrint('[API] $o'),
      ));
    }
  }
}
