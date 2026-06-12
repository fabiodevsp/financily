import 'package:dio/dio.dart';

import 'api_config.dart';
import 'auth_interceptor.dart';
import 'token_storage.dart';

Dio createDio(
  TokenStorage tokenStorage, {
  required Future<void> Function() onSessionExpired,
}) {
  final dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: ApiConfig.connectTimeout,
    receiveTimeout: ApiConfig.receiveTimeout,
  ));
  dio.interceptors.add(AuthInterceptor(tokenStorage, onSessionExpired: onSessionExpired));
  return dio;
}
