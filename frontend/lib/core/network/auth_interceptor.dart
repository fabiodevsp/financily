import 'package:dio/dio.dart';

import '../../features/auth/data/models/token_pair.dart';
import 'api_config.dart';
import 'token_storage.dart';

/// Injeta `Authorization: Bearer <token>` em requisições autenticadas e
/// tenta renovar a sessão uma vez via `/auth/refresh` quando a API
/// responde 401.
///
/// [onSessionExpired] é chamado quando o refresh também falha — usado
/// pelo [AuthController] para forçar logout e o router redirecionar
/// para `/login`.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenStorage, {required this.onSessionExpired})
      : _refreshDio = Dio(BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: ApiConfig.connectTimeout,
          receiveTimeout: ApiConfig.receiveTimeout,
        ));

  final TokenStorage _tokenStorage;
  final Dio _refreshDio;
  final Future<void> Function() onSessionExpired;

  static const _publicPaths = ['/api/v1/auth/login', '/api/v1/auth/register', '/api/v1/auth/refresh'];

  bool _isRefreshing = false;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (!_publicPaths.any((path) => options.path.contains(path))) {
      final token = await _tokenStorage.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final isUnauthorized = err.response?.statusCode == 401;
    final isPublicPath = _publicPaths.any((path) => err.requestOptions.path.contains(path));

    if (!isUnauthorized || isPublicPath || _isRefreshing) {
      handler.next(err);
      return;
    }

    _isRefreshing = true;
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) throw err;

      final response = await _refreshDio.post<Map<String, dynamic>>(
        '/api/v1/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final tokens = TokenPair.fromJson(response.data!);
      await _tokenStorage.saveTokens(tokens);

      final retryOptions = err.requestOptions;
      retryOptions.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
      final retryResponse = await _refreshDio.fetch(retryOptions);
      handler.resolve(retryResponse);
    } catch (_) {
      await _tokenStorage.clear();
      await onSessionExpired();
      handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }
}
