import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'dio_client.dart';
import 'token_storage.dart';

/// Notifica interessados (ex.: [AuthController]) quando o
/// [AuthInterceptor] não conseguiu renovar a sessão via refresh token.
///
/// Existe para evitar dependência circular entre `core/network` (onde o
/// Dio é montado) e `features/auth` (que reage ao logout forçado).
class SessionExpiredNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(ref.watch(secureStorageProvider));
});

final sessionExpiredProvider = Provider<SessionExpiredNotifier>((ref) {
  return SessionExpiredNotifier();
});

final dioProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  final sessionExpired = ref.watch(sessionExpiredProvider);
  return createDio(tokenStorage, onSessionExpired: () async {
    sessionExpired.notify();
  });
});
