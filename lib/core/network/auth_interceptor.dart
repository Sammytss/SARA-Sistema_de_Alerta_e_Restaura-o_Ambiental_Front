import 'package:dio/dio.dart';
import '../security/secure_store.dart';

/// Interceptor Dio que injeta o accessToken em cada requisição
/// e faz refresh transparente quando recebe 401.
///
/// Usa um Dio separado (sem interceptors) para o refresh,
/// evitando loop infinito. A flag `__auth_retry` no `extra`
/// previne segunda tentativa de refresh se o retry também falhar.
class AuthInterceptor extends Interceptor {
  final SecureStore _secureStore;
  final Dio _dio;
  bool _isRefreshing = false;

  AuthInterceptor({required SecureStore secureStore, required Dio dio})
      : _secureStore = secureStore,
        _dio = dio;

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    if (_isAuthPath(options.path)) return handler.next(options);

    final token = await _secureStore.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final isRetry = err.requestOptions.extra['__auth_retry'] == true;
    if (err.response?.statusCode != 401 ||
        _isAuthPath(err.requestOptions.path) ||
        isRetry ||
        _isRefreshing) {
      return handler.next(err);
    }

    final refreshToken = await _secureStore.getRefreshToken();
    if (refreshToken == null) return handler.next(err);

    _isRefreshing = true;
    try {
      // Dio limpo sem interceptors para evitar loop de retry
      final refreshDio = Dio(BaseOptions(baseUrl: _dio.options.baseUrl));
      final response = await refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final newToken = response.data!['accessToken'] as String;
      await _secureStore.setAccessToken(newToken);

      // Re-tenta a requisição original com o novo token
      final retryOptions = err.requestOptions
        ..headers['Authorization'] = 'Bearer $newToken'
        ..extra['__auth_retry'] = true;
      final retryResponse = await _dio.fetch(retryOptions);
      handler.resolve(retryResponse);
    } catch (_) {
      // Refresh falhou — 401 propaga; repositório/UI tratam
      handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }

  bool _isAuthPath(String path) => path.startsWith('/auth/');
}
